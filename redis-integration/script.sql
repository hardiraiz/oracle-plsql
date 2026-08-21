BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host       => 'redis-server', 
        lower_port => 6379,
        upper_port => 6379,
        ace        => xs$ace_type(
            privilege_list => xs$name_list('connect'),
            principal_name => 'DEV', -- GANTI DENGAN SKEMA APEX ANDA
            principal_type => xs_acl.ptype_db
        )
    );
    COMMIT;
END;
/

DROP TABLE products;
CREATE TABLE products (
  product_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_name   VARCHAR2(100) NOT NULL,
  price          NUMBER(10,2) NOT NULL,
  stock_qty      NUMBER DEFAULT 0
);

INSERT INTO products (product_name, price, stock_qty) VALUES ('Laptop Pro 14', 18500000, 25);
INSERT INTO products (product_name, price, stock_qty) VALUES ('Wireless Mouse', 250000, 150);
INSERT INTO products (product_name, price, stock_qty) VALUES ('Mechanical Keyboard', 950000, 80);
COMMIT;
/

--------------------------------------------------------------------------------
-- PACKAGE SPECIFICATION
--------------------------------------------------------------------------------
DROP PACKAGE redis_utltcp_pkg;
CREATE OR REPLACE PACKAGE redis_utltcp_pkg AS

  -- Konfigurasi koneksi Redis (sesuaikan dengan environment Anda)
  g_redis_host      VARCHAR2(100) := 'redis-server';
  g_redis_port      PLS_INTEGER   := 6379;
  g_redis_password  VARCHAR2(100) := 'redis123';   -- kosongkan '' kalau Redis tanpa AUTH
  g_connect_timeout PLS_INTEGER   := 3;            -- batas waktu (detik)

  -- Exception kustom
  e_redis_error EXCEPTION;

  -- ==========================================
  -- Fungsi Dasar (Tipe Data String & Key)
  -- ==========================================
  FUNCTION get_cache(p_key VARCHAR2) RETURN VARCHAR2;
  PROCEDURE set_cache(p_key VARCHAR2, p_value VARCHAR2, p_ttl PLS_INTEGER DEFAULT 60);
  PROCEDURE delete_cache(p_key VARCHAR2);
  
  -- ==========================================
  -- Fungsi Baru (Tipe Data List)
  -- ==========================================
  PROCEDURE rpush_cache(p_key VARCHAR2, p_value VARCHAR2);
  FUNCTION lrange_cache(p_key VARCHAR2, p_start PLS_INTEGER DEFAULT 0, p_stop PLS_INTEGER DEFAULT -1) RETURN VARCHAR2;
  PROCEDURE expire_cache(p_key VARCHAR2, p_ttl PLS_INTEGER);

  -- ==========================================
  -- Utility & Testing
  -- ==========================================
  FUNCTION ping RETURN BOOLEAN;
  PROCEDURE test_connection;

END redis_utltcp_pkg;
/


--------------------------------------------------------------------------------
-- PACKAGE BODY
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY redis_utltcp_pkg AS

  --------------------------------------------------------------------------
  -- FORWARD DECLARATIONS (Fungsi Internal)
  --------------------------------------------------------------------------
  FUNCTION redis_cmd_array(
    p1 VARCHAR2, p2 VARCHAR2 DEFAULT NULL, p3 VARCHAR2 DEFAULT NULL,
    p4 VARCHAR2 DEFAULT NULL, p5 VARCHAR2 DEFAULT NULL
  ) RETURN SYS.ODCIVARCHAR2LIST;
  PROCEDURE send_command(p_conn IN OUT NOCOPY UTL_TCP.connection, p_args SYS.ODCIVARCHAR2LIST);
  FUNCTION read_line(p_conn IN OUT NOCOPY UTL_TCP.connection) RETURN VARCHAR2;
  FUNCTION read_reply(p_conn IN OUT NOCOPY UTL_TCP.connection) RETURN VARCHAR2;
  FUNCTION open_conn RETURN UTL_TCP.connection;
  FUNCTION execute_command(p_args SYS.ODCIVARCHAR2LIST) RETURN VARCHAR2;

  --------------------------------------------------------------------------
  -- INTERNAL: Buka koneksi TCP + AUTH
  --------------------------------------------------------------------------
  FUNCTION open_conn RETURN UTL_TCP.connection IS
    l_conn UTL_TCP.connection;
    l_auth_reply VARCHAR2(200);
  BEGIN
    l_conn := UTL_TCP.open_connection(
      remote_host => g_redis_host,
      remote_port => g_redis_port,
      tx_timeout  => g_connect_timeout
    );

    IF g_redis_password IS NOT NULL THEN
      send_command(l_conn, redis_cmd_array('AUTH', g_redis_password));
      l_auth_reply := read_reply(l_conn);
      IF l_auth_reply LIKE 'ERR:%' THEN
        UTL_TCP.close_connection(l_conn);
        RAISE_APPLICATION_ERROR(-20010, 'Redis AUTH gagal: ' || l_auth_reply);
      END IF;
    END IF;

    RETURN l_conn;
  EXCEPTION
    WHEN UTL_TCP.transfer_timeout THEN
      RAISE_APPLICATION_ERROR(-20011, 'Timeout koneksi ke Redis (' || g_redis_host || ':' || g_redis_port || ')');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20012, 'Gagal koneksi ke Redis: ' || SQLERRM);
  END open_conn;

  --------------------------------------------------------------------------
  -- INTERNAL: Format argumen
  --------------------------------------------------------------------------
  FUNCTION redis_cmd_array(
    p1 VARCHAR2, p2 VARCHAR2 DEFAULT NULL, p3 VARCHAR2 DEFAULT NULL,
    p4 VARCHAR2 DEFAULT NULL, p5 VARCHAR2 DEFAULT NULL
  ) RETURN SYS.ODCIVARCHAR2LIST IS
    l_list SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
  BEGIN
    l_list.EXTEND; l_list(l_list.COUNT) := p1;
    IF p2 IS NOT NULL THEN l_list.EXTEND; l_list(l_list.COUNT) := p2; END IF;
    IF p3 IS NOT NULL THEN l_list.EXTEND; l_list(l_list.COUNT) := p3; END IF;
    IF p4 IS NOT NULL THEN l_list.EXTEND; l_list(l_list.COUNT) := p4; END IF;
    IF p5 IS NOT NULL THEN l_list.EXTEND; l_list(l_list.COUNT) := p5; END IF;
    RETURN l_list;
  END redis_cmd_array;

  --------------------------------------------------------------------------
  -- INTERNAL: Encode ke format RESP Redis
  --------------------------------------------------------------------------
  PROCEDURE send_command(p_conn IN OUT NOCOPY UTL_TCP.connection, p_args SYS.ODCIVARCHAR2LIST) IS
    l_buf VARCHAR2(32767);
    l_written PLS_INTEGER;
  BEGIN
    l_buf := '*' || p_args.COUNT || CHR(13) || CHR(10);
    FOR i IN 1 .. p_args.COUNT LOOP
      l_buf := l_buf || '$' || LENGTHB(p_args(i)) || CHR(13) || CHR(10)
                       || p_args(i) || CHR(13) || CHR(10);
    END LOOP;

    l_written := UTL_TCP.write_text(p_conn, l_buf);
    UTL_TCP.flush(p_conn);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20013, 'Gagal kirim command Redis: ' || SQLERRM);
  END send_command;

  --------------------------------------------------------------------------
  -- INTERNAL: Baca stream RESP
  --------------------------------------------------------------------------
  FUNCTION read_line(p_conn IN OUT NOCOPY UTL_TCP.connection) RETURN VARCHAR2 IS
  BEGIN
    RETURN UTL_TCP.get_line(p_conn, remove_crlf => TRUE);
  EXCEPTION
    WHEN UTL_TCP.end_of_input THEN
      RAISE_APPLICATION_ERROR(-20014, 'Koneksi Redis terputus saat membaca reply');
  END read_line;

  FUNCTION read_reply(p_conn IN OUT NOCOPY UTL_TCP.connection) RETURN VARCHAR2 IS
    l_raw_line  VARCHAR2(32767);
    l_type      CHAR(1);
    l_content   VARCHAR2(32767);
    l_bulk_len  PLS_INTEGER;
    l_result    VARCHAR2(32767);
    l_arr_count PLS_INTEGER;
  BEGIN
    l_raw_line := read_line(p_conn);
    IF l_raw_line IS NULL THEN RETURN 'ERR:Empty reply from Redis'; END IF;

    l_type    := SUBSTR(l_raw_line, 1, 1);
    l_content := SUBSTR(l_raw_line, 2);

    CASE l_type
      WHEN '+' THEN RETURN l_content;                         
      WHEN '-' THEN RETURN 'ERR:' || l_content;                
      WHEN ':' THEN RETURN l_content;                          
      WHEN '$' THEN
        l_bulk_len := TO_NUMBER(l_content);
        IF l_bulk_len = -1 THEN RETURN NULL; END IF;
        RETURN UTL_TCP.get_line(p_conn, remove_crlf => TRUE);
      WHEN '*' THEN
        l_arr_count := TO_NUMBER(l_content);
        IF l_arr_count = -1 OR l_arr_count = 0 THEN RETURN NULL; END IF;
        l_result := NULL;
        FOR i IN 1 .. l_arr_count LOOP
          DECLARE
            l_elem VARCHAR2(32767) := read_reply(p_conn);
          BEGIN
            l_result := l_result || CASE WHEN i > 1 THEN ',' END || l_elem;
          END;
        END LOOP;
        RETURN l_result;
      ELSE
        RETURN 'ERR:Unrecognized RESP type [' || l_type || '] line=' || l_raw_line;
    END CASE;
  EXCEPTION
    WHEN OTHERS THEN RETURN 'ERR:Parse exception - ' || SQLERRM;
  END read_reply;

  --------------------------------------------------------------------------
  -- INTERNAL: Eksekusi Command Utama
  --------------------------------------------------------------------------
  FUNCTION execute_command(p_args SYS.ODCIVARCHAR2LIST) RETURN VARCHAR2 IS
    l_conn        UTL_TCP.connection;
    l_reply       VARCHAR2(32767);
    l_conn_opened BOOLEAN := FALSE;
  BEGIN
    l_conn := open_conn();
    l_conn_opened := TRUE;

    send_command(l_conn, p_args);
    l_reply := read_reply(l_conn);

    UTL_TCP.close_connection(l_conn);
    l_conn_opened := FALSE;
    RETURN l_reply;
  EXCEPTION
    WHEN OTHERS THEN
      IF l_conn_opened THEN
        BEGIN UTL_TCP.close_connection(l_conn); EXCEPTION WHEN OTHERS THEN NULL; END;
      END IF;
      RAISE;
  END execute_command;

  -- =======================================================================
  -- IMPLEMENTASI PUBLIC: STRING
  -- =======================================================================
  FUNCTION get_cache(p_key VARCHAR2) RETURN VARCHAR2 IS
    l_reply VARCHAR2(32767);
  BEGIN
    l_reply := execute_command(redis_cmd_array('GET', p_key));
    IF l_reply LIKE 'ERR:%' THEN RETURN NULL; END IF;
    RETURN l_reply;
  EXCEPTION WHEN OTHERS THEN RETURN NULL;
  END get_cache;

  PROCEDURE set_cache(p_key VARCHAR2, p_value VARCHAR2, p_ttl PLS_INTEGER DEFAULT 60) IS
    l_reply VARCHAR2(32767);
  BEGIN
    l_reply := execute_command(redis_cmd_array('SETEX', p_key, TO_CHAR(p_ttl), p_value));
  END set_cache;

  PROCEDURE delete_cache(p_key VARCHAR2) IS
    l_reply VARCHAR2(32767);
  BEGIN
    l_reply := execute_command(redis_cmd_array('DEL', p_key));
  EXCEPTION WHEN OTHERS THEN NULL;
  END delete_cache;

  -- =======================================================================
  -- IMPLEMENTASI PUBLIC: LIST
  -- =======================================================================
  PROCEDURE rpush_cache(p_key VARCHAR2, p_value VARCHAR2) IS
    l_reply VARCHAR2(32767);
  BEGIN
    l_reply := execute_command(redis_cmd_array('RPUSH', p_key, p_value));
  END rpush_cache;

  FUNCTION lrange_cache(p_key VARCHAR2, p_start PLS_INTEGER DEFAULT 0, p_stop PLS_INTEGER DEFAULT -1) RETURN VARCHAR2 IS
    l_reply VARCHAR2(32767);
  BEGIN
    l_reply := execute_command(redis_cmd_array('LRANGE', p_key, TO_CHAR(p_start), TO_CHAR(p_stop)));
    IF l_reply LIKE 'ERR:%' THEN RETURN NULL; END IF;
    RETURN l_reply;
  EXCEPTION WHEN OTHERS THEN RETURN NULL;
  END lrange_cache;

  PROCEDURE expire_cache(p_key VARCHAR2, p_ttl PLS_INTEGER) IS
    l_reply VARCHAR2(32767);
  BEGIN
    l_reply := execute_command(redis_cmd_array('EXPIRE', p_key, TO_CHAR(p_ttl)));
  END expire_cache;

  -- =======================================================================
  -- IMPLEMENTASI PUBLIC: UTILITY
  -- =======================================================================
  FUNCTION ping RETURN BOOLEAN IS
    l_reply VARCHAR2(200);
  BEGIN
    l_reply := execute_command(redis_cmd_array('PING'));
    RETURN l_reply = 'PONG';
  EXCEPTION WHEN OTHERS THEN RETURN FALSE;
  END ping;

  PROCEDURE test_connection IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('PING -> ' || CASE WHEN ping THEN 'PONG (OK)' ELSE 'GAGAL' END);
  END test_connection;

END redis_utltcp_pkg;
/

SET DEFINE OFF;

DROP FUNCTION get_products_filtered;
CREATE OR REPLACE FUNCTION get_products_filtered(
  p_search_name VARCHAR2 DEFAULT NULL,
  p_limit       NUMBER   DEFAULT 50,
  p_offset      NUMBER   DEFAULT 0
) RETURN CLOB IS
  l_cache_key    VARCHAR2(200);
  l_cached       VARCHAR2(32767);
  l_json_item    VARCHAR2(4000);
  l_result       CLOB;
  l_search_clean VARCHAR2(100);
BEGIN
  -- 1. Bersihkan parameter pencarian (ganti spasi dengan underscore)
  l_search_clean := NVL(LOWER(REPLACE(p_search_name, ' ', '_')), 'all');

  -- 2. Buat Cache Key Unik (Misal: products:q_laptop:l_50:o_0)
  l_cache_key := 'products:q_' || l_search_clean || ':l_' || p_limit || ':o_' || p_offset;

  -- 3. Coba baca List dari Redis
  l_cached := redis_utltcp_pkg.lrange_cache(l_cache_key, 0, -1);
  
  IF l_cached IS NOT NULL THEN
    DBMS_OUTPUT.PUT_LINE('Cache Hit: ' || l_cache_key);
    RETURN '[' || l_cached || ']';
  END IF;

  DBMS_OUTPUT.PUT_LINE('Cache Miss - Query Database (' || l_cache_key || ')');
  
  -- 4. Pastikan key bersih sebelum di-push ulang
  redis_utltcp_pkg.delete_cache(l_cache_key);
  l_result := '[';
  
  -- 5. Query Oracle dengan Limit, Offset, dan Kondisi Pencarian (Aman dari 1 juta row)
  FOR rec IN (
    SELECT * FROM products
    WHERE p_search_name IS NULL 
       OR LOWER(product_name) LIKE '%' || LOWER(p_search_name) || '%'
    ORDER BY product_id
    OFFSET p_offset ROWS FETCH NEXT p_limit ROWS ONLY
  ) LOOP
    l_json_item := '{"product_id":' || rec.product_id || 
                   ',"product_name":"' || rec.product_name || '"' ||
                   ',"price":' || rec.price || 
                   ',"stock_qty":' || rec.stock_qty || '}';
    
    redis_utltcp_pkg.rpush_cache(l_cache_key, l_json_item);
    
    IF l_result != '[' THEN l_result := l_result || ','; END IF;
    l_result := l_result || l_json_item;
  END LOOP;
  
  l_result := l_result || ']';

  -- 6. BEST PRACTICE: Beri TTL agar memori Redis tidak penuh oleh list usang (misal 5 menit)
  redis_utltcp_pkg.expire_cache(l_cache_key, 300);

  RETURN l_result;
END get_products_filtered;
/

DROP FUNCTION get_product_by_id;
CREATE OR REPLACE FUNCTION get_product_by_id(p_product_id NUMBER) RETURN CLOB IS
  l_cache_key VARCHAR2(100);
  l_cached    VARCHAR2(4000);
  l_json_item VARCHAR2(4000);
  rec         products%ROWTYPE;
BEGIN
  l_cache_key := 'product:' || p_product_id;

  -- 1. Cek Cache
  l_cached := redis_utltcp_pkg.get_cache(l_cache_key);
  IF l_cached IS NOT NULL THEN
    DBMS_OUTPUT.PUT_LINE('Cache Hit Object: ' || l_cache_key);
    RETURN l_cached;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Cache Miss Object: ' || l_cache_key);

  -- 2. Query Database (Cepat karena pakai PK)
  BEGIN
    SELECT * INTO rec FROM products WHERE product_id = p_product_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END;

  -- 3. Susun JSON
  l_json_item := '{"product_id":' || rec.product_id || 
                 ',"product_name":"' || rec.product_name || '"' ||
                 ',"price":' || rec.price || 
                 ',"stock_qty":' || rec.stock_qty || '}';

  -- 4. Simpan ke Redis (Bisa menggunakan TTL yang lebih lama, misal 1 jam)
  redis_utltcp_pkg.set_cache(l_cache_key, l_json_item, 3600);

  RETURN l_json_item;
END get_product_by_id;
/

DROP TRIGGER trg_products_cache_invalidate;
CREATE OR REPLACE TRIGGER trg_products_cache_invalidate
AFTER UPDATE OR DELETE ON products
FOR EACH ROW
BEGIN
  -- Hanya hapus cache produk yang diupdate/didelete
  -- Cache produk lain tidak akan terganggu
  redis_utltcp_pkg.delete_cache('product:' || :OLD.product_id);
EXCEPTION
  WHEN OTHERS THEN
    NULL; -- Fail-safe
END;
/

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE l_result CLOB; BEGIN
  -- Eksekusi pertama (Miss)
  l_result := get_product_by_id(1);
  DBMS_OUTPUT.PUT_LINE(l_result);
  
  -- Eksekusi kedua (Hit)
  l_result := get_product_by_id(1);
END;
/

UPDATE products SET price = 16000000 WHERE product_id = 1;
COMMIT;

-- Uji kembali (Harus Miss, karena Trigger sudah menghapus cache lama)
DECLARE l_result CLOB; BEGIN
  l_result := get_product_by_id(1);
  DBMS_OUTPUT.PUT_LINE(l_result);
END;
/

INSERT INTO products (product_name, price, stock_qty) VALUES ('Gaming Headset', 750000, 50);
COMMIT;

-- Cari list semua produk
DECLARE l_result CLOB; BEGIN
  l_result := get_products_filtered();
  DBMS_OUTPUT.PUT_LINE('HASIL JSON: ' || SUBSTR(l_result, 1, 1500) || '...');
END;
/

UPDATE products SET price = 16000000 WHERE product_id = 2;
COMMIT;

DECLARE l_result CLOB;
BEGIN
  l_result := get_products_filtered(p_search_name => 'Mouse', p_limit => 10, p_offset => 0);
  DBMS_OUTPUT.PUT_LINE('HASIL JSON: ' || SUBSTR(l_result, 1, 1500) || '...');
END;
/

SELECT j.product_id,
       j.product_name,
       j.price,
       j.stock_qty
FROM JSON_TABLE(
    get_all_products_list(),  -- Memanggil fungsi cache Redis Anda
    '$[*]'                    -- Membaca setiap elemen di dalam JSON Array
    COLUMNS (
        product_id   NUMBER        PATH '$.product_id',
        product_name VARCHAR2(100) PATH '$.product_name',
        price        NUMBER        PATH '$.price',
        stock_qty    NUMBER        PATH '$.stock_qty'
    )
) j;
/