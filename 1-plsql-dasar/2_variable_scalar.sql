-- ===== A. TIPE DATA SCALAR =====
-- 1. Tipe data numerik
DECLARE
  v_number NUMBER(10,2) := 1234.56;  -- Maksimal 10 digit, 2 desimal
  v_integer PLS_INTEGER := 100;       -- Integer dengan performa lebih baik akan tetapi hanya untuk bilangan bulat
  v_float BINARY_FLOAT := 3.14;       -- Floating point 32-bit
  v_double BINARY_DOUBLE := 3.14159265358979;  -- Floating point 64-bit
BEGIN
  DBMS_OUTPUT.PUT_LINE('Number: ' || v_number);
  DBMS_OUTPUT.PUT_LINE('PLS_INTEGER: ' || v_integer);
  DBMS_OUTPUT.PUT_LINE('Float: ' || v_float);
  DBMS_OUTPUT.PUT_LINE('Double: ' || v_double);
END;

-- NOTE : 
-- a. Binary Float cocok untuk menangani data dari sensor, game enging atau perangkat IoT karena menggunakan format floating-point standar IEEE
-- b. Binary Float digunakan untuk perhitungan matematika yang tidak memerlukan presisi tinggi 
-- c. Binary Float digunakan dalam pemrosesan sinyal digital (DSP) atau geospasial (GIS)
-- d. Binary Float bisa menyimpan NaN, Infinity (-/+) sedangkan number tidak dapat menyimpan NaN
-- e. Binary Double lebih presisi dari Float, cocok untuk keuangan, simulasi ilmiah, machine learning, dan GIS
-- f. Jika butuh presisi tanpa error floating-point, gunakan NUMBER tetapi lebih lambat

-- 2. Tipe data karakter
DECLARE
  v_char CHAR(10) := 'A';                  -- Panjang tetap, sisanya diisi spasi
  v_varchar2 VARCHAR2(20) := 'Hello';      -- Panjang dinamis
  v_nchar NCHAR(5) := N'あいうえお';        -- Unicode karakter tetap
  v_nvarchar2 NVARCHAR2(20) := N'漢字';     -- Unicode karakter dinamis
BEGIN
  DBMS_OUTPUT.PUT_LINE('CHAR: ' || v_char);
  DBMS_OUTPUT.PUT_LINE('VARCHAR2: ' || v_varchar2);
  DBMS_OUTPUT.PUT_LINE('NCHAR: ' || v_nchar);
  DBMS_OUTPUT.PUT_LINE('NVARCHAR2: ' || v_nvarchar2);
END;

-- 3. Tipe data boolean
DECLARE
  v_bool BOOLEAN := TRUE;
BEGIN
  IF v_bool THEN
    DBMS_OUTPUT.PUT_LINE('Boolean is TRUE');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Boolean is FALSE');
  END IF;
END;

-- 4. Tipe data tanggal dan waktu
DECLARE
  v_date DATE := SYSDATE;  -- Menyimpan tanggal & waktu saat ini
  v_timestamp TIMESTAMP := SYSTIMESTAMP;  -- Presisi lebih tinggi
  v_interval INTERVAL DAY TO SECOND := INTERVAL '5' DAY;  -- Perbedaan waktu 5 hari
  v_interval_2 INTERVAL DAY(4) TO SECOND(2) := '24 02:05:21.012'; -- menyimpan selisih waktu dalam format hari, jam, menit, detik, dan milidetik.
  v_interval_3 INTERVAL YEAR(3) TO MONTH := '122-3'; --menyimpan selisih waktu dalam tahun dan bulan, output : 122 tahun 3 bulan
BEGIN
  DBMS_OUTPUT.PUT_LINE('Date: ' || TO_CHAR(v_date, 'DD-MON-YYYY HH24:MI:SS'));
  DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(v_timestamp, 'DD-MON-YYYY HH24:MI:SS.FF'));
  DBMS_OUTPUT.PUT_LINE('Interval: ' || v_interval);
  DBMS_OUTPUT.PUT_LINE('Interval 2: ' || v_interval_2);
  DBMS_OUTPUT.PUT_LINE('Interval 3: ' || v_interval_2);
END;

-- Contoh pengunaan interval dalam menghitung waktu habis kontrak
DECLARE
  start_date DATE := DATE '2023-01-15'; -- Tanggal mulai kontrak
  contract_duration INTERVAL YEAR TO MONTH := INTERVAL '2-6' YEAR TO MONTH; -- 2 tahun 6 bulan
  end_date DATE;
BEGIN
  end_date := start_date + contract_duration;
  DBMS_OUTPUT.PUT_LINE('Tanggal berakhir kontrak: ' || TO_CHAR(end_date, 'DD-MON-YYYY'));
END;

-- Contoh penggunaan interval dalam menghitung perkiraan 
-- waktu pengiriman dengan menambahkan 2 hari 5 jam 30 menit ke tanggal pemrosesan.
DECLARE
  order_time TIMESTAMP := SYSTIMESTAMP; -- Waktu pemrosesan pesanan
  delivery_duration INTERVAL DAY TO SECOND := INTERVAL '2 5:30:00' DAY TO SECOND; -- 2 hari 5 jam 30 menit
  estimated_arrival TIMESTAMP;
BEGIN
  estimated_arrival := order_time + delivery_duration;
  DBMS_OUTPUT.PUT_LINE('Pesanan diproses pada: ' || TO_CHAR(order_time, 'DD-MON-YYYY HH24:MI:SS'));
  DBMS_OUTPUT.PUT_LINE('Estimasi kedatangan: ' || TO_CHAR(estimated_arrival, 'DD-MON-YYYY HH24:MI:SS'));
END;

-- Contoh Perbandingan INTERVAL dalam Kondisi
DECLARE
  order_date DATE := DATE '2025-02-25';
  current_date DATE := SYSDATE;
BEGIN
  IF current_date - order_date > INTERVAL '7' DAY THEN
    DBMS_OUTPUT.PUT_LINE('Pesanan ini telah dikirim lebih dari 7 hari yang lalu.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Pesanan ini masih dalam batas 7 hari.');
  END IF;
END;