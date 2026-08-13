# Panduan Implementasi Cache-Aside Oracle APEX & Redis (Format List)

Panduan ini mencakup dari penjelasan konsep dasar, setup infrastruktur, hingga implementasi PL/SQL yang mendukung struktur data tipe **List** (untuk pencarian) dan **String** (untuk detail produk) di Redis dengan menerapkan praktik **Lazy Loading (Limit, Offset, & Search)** dan **Precision Invalidation**.

## Introduction

### 1. Fisika Pengambilan Data (Mekanika Dasar)

Perbedaan utamanya terletak pada di mana data tersebut disimpan dan bagaimana sistem mengambilnya.

1. **Oracle Indexing (Berbasis Disk)**
* **Cara kerja:** Saat Anda menjalankan `SELECT * FROM products WHERE id = 1`, Oracle menggunakan indeks B-Tree. Indeks ini seperti daftar isi di bagian belakang buku yang tebal. Daftar isi ini memberi tahu Oracle di "halaman" (blok data fisik) mana pada *hard disk* data untuk ID 1 berada.
* **Hambatan (Bottleneck):** Meskipun menggunakan indeks, Oracle tetap harus pergi ke penyimpanan fisik (SSD atau HDD) untuk membaca blok data. Oracle juga harus mem-parsing SQL, mengalokasikan memori, mengecek hak akses, dan mengeksekusi *execution plan*. Semua ini memakan siklus CPU.
* **Kecepatan:** Cepat (dalam skala milidetik), tetapi sangat berat untuk server jika dilakukan ribuan kali dalam sedetik.


2. **Redis Caching (Berbasis Memori / RAM)**
* **Cara kerja:** Redis menyimpan data sepenuhnya di dalam RAM sebagai *key-value* (contoh: `product:1` -> `{JSON}`).
* **Keuntungan:** Tidak ada proses parsing SQL, tidak ada *execution plan*, dan sama sekali tidak ada I/O disk (baca *hard disk*). Redis hanya mencocokkan *key* di RAM dan langsung mengembalikan nilainya.
* **Kecepatan:** Sekejap mata (dalam skala mikrodetik) dan hampir tidak membebani CPU sama sekali.

### 2. Kapan Menggunakan Apa? (Skenario Skala)

Keputusan untuk menggunakan Redis sangat bergantung pada skala aplikasi Anda:

* **Skenario A: Aplikasi Internal / Skala Menengah (Tidak Butuh Redis)**
Jika aplikasi APEX Anda hanya digunakan oleh 50 karyawan dan server database sedang santai, jangan gunakan Redis.
* Indeks Oracle sudah lebih dari mampu untuk menangani ribuan permintaan per detik.
* Memaksakan Redis di skenario ini hanya akan menambah kerumitan arsitektur tanpa memberikan kecepatan ekstra yang bisa dirasakan oleh mata.


* **Skenario B: Aplikasi Publik / Lalu Lintas Tinggi (Redis Wajib Digunakan)**
Bayangkan situs *e-commerce* Anda sedang mengadakan *flash sale*. Sepuluh ribu (10.000) pengguna membuka halaman "Laptop Asus" (`product:55`) di detik yang bersamaan.
* **Tanpa Redis:** Oracle menerima 10.000 *query* secara bersamaan. CPU server Oracle akan melonjak 100% dan database bisa *hang* atau *crash*.
* **Dengan Redis:** Pengguna pertama memicu *query* Oracle (*Cache Miss*) dan menyimpan JSON-nya ke Redis. Sisa 9.999 pengguna akan mengambil data langsung dari RAM Redis (*Cache Hit*). Oracle duduk santai tanpa beban.

> **Aturan Emas Arsitektur:** Gunakan Indeks Oracle untuk membuat proses mencari data di dalam database menjadi cepat. Gunakan Redis untuk melindungi database agar ia tidak perlu mencari data yang sama berulang-ulang ketika lalu lintas sedang memuncak.

### 3. Ketahanan Data (Durability & ACID Compliance)

* **Oracle Database (Source of Truth):** Dirancang dengan prinsip **ACID**. Transaksi yang di-*commit* ditulis permanen ke *hard disk*. Oracle adalah sumber kebenaran utama.
* **Redis Caching (Ephemeral / Volatile):** Berjalan murni di atas RAM, sehingga data bersifat sementara. Jika *server* mati, *cache* hilang. Ini wajar, karena aplikasi hanya perlu mengambilnya kembali dari Oracle.

### 4. Biaya dan Kapasitas Infrastruktur (RAM vs Disk)

* **Kapasitas Oracle (Murah & Masif):** Menyimpan data 1 TB di SSD/HDD sangatlah murah.
* **Kapasitas Redis (Mahal & Terbatas):** RAM *server* sangat terbatas. Oleh karena itu, Redis hanya boleh digunakan untuk menyimpan **Hot Data** (data yang paling sering diakses saat ini). Anda **tidak boleh** melakukan *query all* (misal 1 juta baris) dan memindahkannya sekaligus ke Redis.

### 5. Tantangan Utama: Sinkronisasi & Data Usang (Stale Data)

Masalah terbesar dalam *caching* adalah memastikan data di Redis tetap sinkron dengan Oracle.

* **Masalah Harga Lama:** Harga di Oracle diubah, tetapi *cache* Redis masih menyimpan harga lama.
* **Solusi:** Gunakan **Database Trigger** untuk melakukan *Cache Invalidation* secara presisi. Hapus hanya `product:ID` yang harganya berubah.


* **Masalah Produk Baru (Stale List Data):** Anda menambahkan produk baru, tetapi halaman daftar produk tidak menampilkan produk tersebut karena masih membaca *cache* list lama (misal: `products:q_all:l_50:o_0`).
* **Solusi Best Practice:** **Jangan gunakan Trigger untuk List dinamis.** Jika Anda harus menghapus seluruh kombinasi parameter pencarian setiap kali ada produk baru, itu sangat tidak efisien. Solusi terbaiknya adalah **TTL (Time-To-Live)**. Berikan umur pada List (misal 5 menit). Produk baru mungkin tidak langsung terlihat selama maksimal 5 menit, namun ini adalah toleransi standar dalam arsitektur skala besar (dikenal sebagai *Eventual Consistency*).

---

## Tahap 0: Prerequisite

1. Telah memiliki container Oracle DB free:23.26.2.0 disini nama container Oracle DB saya manual-db
2. Telah memiliki docker network dengan nama `integration-net` dan telah terhubung dengan container manual-db

---

## Tahap 1: Setup Infrastruktur (Best Practice)

Buat direktori dan file `docker-compose.yml`:
```yaml
version: "3.9"

services:
redis:
    image: redis:7.4-alpine
    container_name: redis-server
    restart: unless-stopped
    ports:
    - "6379:6379"
    command: >
    redis-server
    --requirepass ${REDIS_PASSWORD:-changeme123}
    --maxmemory 512mb
    --maxmemory-policy allkeys-lru
    --appendonly yes
    --appendfsync everysec
    volumes:
    - redis-data:/data
    networks:
    - integration-net

redis-commander:
    image: rediscommander/redis-commander:latest
    container_name: redis-commander
    restart: unless-stopped
    environment:
    - REDIS_HOSTS=local:redis:6379:0:${REDIS_PASSWORD:-changeme123}
    ports:
    - "8081:8081"
    networks:
    - integration-net

networks:
integration-net:
    external: true

volumes:
redis-data:
    driver: local

```

Jalankan dengan `docker compose up -d`.

---

## Tahap 2: Konfigurasi Keamanan (Network ACL Oracle)

Sebagai user `SYS`, izinkan skema APEX Anda berkomunikasi keluar via TCP.

```sql
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host       => 'redis-server', -- Atau IP Host Docker
        ace        => xs$ace_type(
            privilege_list => xs$name_list('connect'),
            principal_name => 'DEV', -- GANTI DENGAN SKEMA APEX ANDA
            principal_type => xs_acl.ptype_db
        )
    );
  
    COMMIT;
END;
/

```

---

## Tahap 3: DDL Tabel Master

Login sebagai `POC_USER`. Kita akan menggunakan tabel `products`.

```sql
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

```

---

## Tahap 4: Create Package PL/SQL

**Package Specification:**

```sql
CREATE OR REPLACE PACKAGE redis_utltcp_pkg AS

  -- Konfigurasi koneksi Redis (sesuaikan dengan environment Anda)
  g_redis_host      VARCHAR2(100) := 'redis-server';
  g_redis_port      PLS_INTEGER   := 6379;
  g_redis_password  VARCHAR2(100) := 'redis123';   -- kosongkan '' kalau Redis tanpa AUTH
  g_connect_timeout PLS_INTEGER   := 3;            -- batas waktu (detik)

  -- Exception kustom
  e_redis_error EXCEPTION;

  -- Fungsi Dasar (Tipe Data String & Key)
  FUNCTION get_cache(p_key VARCHAR2) RETURN VARCHAR2;
  PROCEDURE set_cache(p_key VARCHAR2, p_value VARCHAR2, p_ttl PLS_INTEGER DEFAULT 60);
  PROCEDURE delete_cache(p_key VARCHAR2);
  
  -- Fungsi Baru (Tipe Data List)
  PROCEDURE rpush_cache(p_key VARCHAR2, p_value VARCHAR2);
  FUNCTION lrange_cache(p_key VARCHAR2, p_start PLS_INTEGER DEFAULT 0, p_stop PLS_INTEGER DEFAULT -1) RETURN VARCHAR2;
  PROCEDURE expire_cache(p_key VARCHAR2, p_ttl PLS_INTEGER);

  -- Utility & Testing
  FUNCTION ping RETURN BOOLEAN;
  PROCEDURE test_connection;

END redis_utltcp_pkg;
/

```

**Package Body**

```sql
CREATE OR REPLACE PACKAGE BODY redis_utltcp_pkg AS

  -- FORWARD DECLARATIONS (Fungsi Internal)
  FUNCTION redis_cmd_array(
    p1 VARCHAR2, p2 VARCHAR2 DEFAULT NULL, p3 VARCHAR2 DEFAULT NULL,
    p4 VARCHAR2 DEFAULT NULL, p5 VARCHAR2 DEFAULT NULL
  ) RETURN SYS.ODCIVARCHAR2LIST;
  PROCEDURE send_command(p_conn IN OUT NOCOPY UTL_TCP.connection, p_args SYS.ODCIVARCHAR2LIST);
  FUNCTION read_line(p_conn IN OUT NOCOPY UTL_TCP.connection) RETURN VARCHAR2;
  FUNCTION read_reply(p_conn IN OUT NOCOPY UTL_TCP.connection) RETURN VARCHAR2;
  FUNCTION open_conn RETURN UTL_TCP.connection;
  FUNCTION execute_command(p_args SYS.ODCIVARCHAR2LIST) RETURN VARCHAR2;

  -- INTERNAL: Buka koneksi TCP + AUTH
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

  -- INTERNAL: Format argumen
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

  -- INTERNAL: Encode ke format RESP Redis
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

  -- INTERNAL: Baca stream RESP
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

  -- INTERNAL: Eksekusi Command Utama
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

  -- IMPLEMENTASI PUBLIC: STRING
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

  -- IMPLEMENTASI PUBLIC: LIST
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

  -- IMPLEMENTASI PUBLIC: UTILITY
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

```

---

## Tahap 5: Implementasi Fungsi Caching

Di sini kita membuat dua fungsi terpisah:

1. **Fungsi untuk List (Dinamis)**: Menggunakan TTL.
2. **Fungsi untuk Detail Object by ID**: Digunakan untuk melihat detail produk spesifik.

### 5.1 Fungsi Pencarian Dinamis (Format List)

```sql
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
  -- 1. Bersihkan parameter pencarian
  l_search_clean := NVL(LOWER(REPLACE(p_search_name, ' ', '_')), 'all');

  -- 2. Buat Cache Key Unik
  l_cache_key := 'products:q_' || l_search_clean || ':l_' || p_limit || ':o_' || p_offset;

  -- 3. Coba baca List dari Redis
  l_cached := redis_utltcp_pkg.lrange_cache(l_cache_key, 0, -1);
  
  IF l_cached IS NOT NULL THEN
    DBMS_OUTPUT.PUT_LINE('Cache Hit: ' || l_cache_key);
    RETURN '[' || l_cached || ']';
  END IF;

  DBMS_OUTPUT.PUT_LINE('Cache Miss - Query Database (' || l_cache_key || ')');
  
  redis_utltcp_pkg.delete_cache(l_cache_key);
  l_result := '[';
  
  -- 4. Query Oracle dengan Limit, Offset, dan Kondisi Pencarian
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

  -- 5. Beri TTL 5 menit untuk mengatasi isu produk baru (Eventual Consistency)
  redis_utltcp_pkg.expire_cache(l_cache_key, 300);

  RETURN l_result;
END get_products_filtered;
/

```

### 5.2 Fungsi Detail by ID (Format String/Object)

Fungsi ini digunakan ketika *user* membuka halaman detail produk.

```sql
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

```

---

## Tahap 6: Strategi Invalidation Presisi (Trigger)

Kita **HANYA** membuat *Trigger* untuk menghapus *cache* tipe **Object by ID**. Untuk *cache* tipe pencarian list, kita biarkan TTL yang bekerja.

```sql
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

```

---

## Tahap 7: Pengujian Sistem

Aktifkan *output*:

```sql
SET SERVEROUTPUT ON SIZE UNLIMITED;

```

### Skenario 1: Pengujian Detail Product by ID

```sql
DECLARE l_result CLOB; BEGIN
  -- Eksekusi pertama (Miss)
  l_result := get_product_by_id(1);
  DBMS_OUTPUT.PUT_LINE(l_result);
  
  -- Eksekusi kedua (Hit)
  l_result := get_product_by_id(1);
END;
/

```

### Skenario 2: Pengujian Invalidation & Trigger

Jika ada perubahan harga pada produk ID 1, sistem harus segera menghapus *cache* produk tersebut agar pembeli berikutnya mendapatkan harga baru.

```sql
-- Update harga
UPDATE products SET price = 15000000 WHERE product_id = 1;
COMMIT;

-- Uji kembali (Harus Miss, karena Trigger sudah menghapus cache lama)
DECLARE l_result CLOB; BEGIN
  l_result := get_product_by_id(1);
END;
/

```

### Skenario 3: Simulasi Masalah Produk Baru (Stale Data pada List)

```sql
-- Tambah produk baru
INSERT INTO products (product_name, price, stock_qty) VALUES ('Gaming Headset', 750000, 50);
COMMIT;

-- Cari list semua produk
DECLARE l_result CLOB; BEGIN
  l_result := get_products_filtered();
END;
/

```

*Hasil:* Jika Anda baru saja menjalankan fungsi List sebelum `INSERT` dilakukan, produk baru tersebut **tidak akan muncul** di *output* JSON. Inilah yang disebut data usang sementara (*Eventual Consistency*). Anda harus menunggu maksimal 5 menit hingga TTL dari `products:q_all:l_50:o_0` habis, barulah produk tersebut akan muncul secara otomatis.

---

## Tahap 8: Pemanggilan Sebagai Data Source Region (Interactive / Classic Report)

Kita dapat menggunakan data di redis sebagai data source region seperti interactive report atau classic report dengan menggunakan query berikut:

```sql
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

```

---

## Tahap 9: Pertimbangan Lanjutan untuk Production

Agar sistem Anda benar-benar *Production-Ready*, pertimbangkan hal-hal berikut:

**REST Data Source (Alternatif APEX):** Karena `UTL_TCP` cukup *low-level*, banyak developer APEX lebih memilih menggunakan *middleware* (seperti Node.js atau Python Express) sebagai penjembatan. Oracle APEX memanggil Node.js via **APEX_WEB_SERVICE** (REST), lalu Node.js yang memelihara *Connection Pool* ke Redis.