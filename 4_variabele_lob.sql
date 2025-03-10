-- ===== C. TIPE DATA LARGE OBJECT (LOB) =====
-- Tipe data LOB digunakan untuk menyimpan data dalam jumlah besar seperti teks, gambar, atau file biner

-- 1. BLOB (Binary Large Object), menyimpan data biner seperti gambar, video, atau file
-- a. Membuat tabel dengan kolom BLOB
CREATE TABLE images (
  id NUMBER PRIMARY KEY,
  name VARCHAR2(100),
  photo BLOB
)
/
-- b. Menambahkan data ke dalam BLOB (biasanya dari file)
DECLARE
  v_blob BLOB;
BEGIN
  -- Biasanya data dimasukkan dari aplikasi, bukan PL/SQL langsung.
  INSERT INTO images (id, name, photo) VALUES (1, 'Logo Oracle', EMPTY_BLOB())
  RETURNING photo INTO v_blob;
  
  COMMIT;
END;
/
-- c. Membaca data dari BLOB (hanya informasi ukuran dalam contoh ini)
DECLARE
  v_size NUMBER;
BEGIN
  SELECT DBMS_LOB.GETLENGTH(photo) INTO v_size FROM images WHERE id = 1;
  DBMS_OUTPUT.PUT_LINE('Ukuran BLOB: ' || v_size || ' bytes');
END;
/

-- 2. CLOB (Character Large Object), menyimpan teks dalam jumlah besar hingga 4 GB
-- a. Membuat tabel dengan kolom CLOB
CREATE TABLE articles (
  id NUMBER PRIMARY KEY,
  title VARCHAR2(100),
  content CLOB
);
-- b. Menambahkan data ke dalam CLOB
DECLARE
  v_content CLOB;
BEGIN
  v_content := 'Ini adalah artikel panjang yang disimpan dalam CLOB...';
  
  INSERT INTO articles (id, title, content)
  VALUES (1, 'Artikel tentang Oracle', v_content);
  
  COMMIT;
END;
/
-- c. Membaca data dari CLOB
DECLARE
  v_content CLOB;
BEGIN
  SELECT content INTO v_content FROM articles WHERE id = 1;
  DBMS_OUTPUT.PUT_LINE('Isi Artikel: ' || DBMS_LOB.SUBSTR(v_content, 100, 1)); -- Menampilkan 100 karakter pertama
END;
/

-- 3. NCLOB (National Character Large Object), seperti CLOB tetapi untuk Unicode
-- a. Membuat tabel dengan NCLOB
CREATE TABLE translations (
  id NUMBER PRIMARY KEY,
  language VARCHAR2(50),
  text_content NCLOB
)
/
-- b. Menambahkan data Unicode ke NCLOB
DECLARE
  v_text NCLOB;
BEGIN
  v_text := N'これは日本語のテキストです';  -- Teks dalam bahasa Jepang
  
  INSERT INTO translations (id, language, text_content)
  VALUES (1, 'Japanese', v_text);
  
  COMMIT;
END;
/
-- c. Membaca data dari NCLOB
DECLARE
  v_text NCLOB;
BEGIN
  SELECT text_content INTO v_text FROM translations WHERE id = 1;
  DBMS_OUTPUT.PUT_LINE('Isi NCLOB: ' || DBMS_LOB.SUBSTR(v_text, 50, 1));
END;
/

-- 4. BFILE (Binary File), menyimpan referensi ke file di sistem file luar database
-- Example Case : Sebuah perusahaan ingin menyimpan referensi ke dokumen PDF yang disimpan di sistem file server (bukan di database).
-- Setiap dokumen memiliki ID, nama file, dan path lokasi penyimpanannya di server.

-- Mengapa Menggunakan BFILE?
-- File besar tidak membebani database (hanya menyimpan referensi).
-- Database tetap ringan karena hanya menyimpan metadata file.
-- File bisa dikelola langsung di sistem operasi tanpa intervensi database.

-- 4.1 Membuat Directory di Oracle untuk Menyimpan File
-- Oracle membutuhkan direktori khusus yang dapat diakses oleh database untuk membaca file eksternal.
-- Hanya DBA yang bisa menjalankan perintah berikut:

-- Membuat direktori 'DOC_DIR' di lokasi sistem file server
CREATE OR REPLACE DIRECTORY DOC_DIR AS '/home/oracle/documents';
-- Memberikan izin akses ke direktori
GRANT READ ON DIRECTORY DOC_DIR TO PUBLIC;

-- 4.2 Membuat Tabel untuk Menyimpan Referensi File  
CREATE TABLE document_files (
  doc_id NUMBER PRIMARY KEY,
  doc_name VARCHAR2(255),
  doc_file BFILE
);

-- 4.3 Menambahkan Data Referensi File ke dalam Tabel
DECLARE
  v_bfile BFILE;
BEGIN
  -- Menyimpan referensi ke file 'invoice_2024.pdf' yang ada di direktori 'DOC_DIR'
  INSERT INTO document_files (doc_id, doc_name, doc_file)
  VALUES (1, 'Invoice 2024', BFILENAME('DOC_DIR', 'invoice_2024.pdf'));

  COMMIT;
END;

-- 4.4 Membaca Informasi File dari BFILE
DECLARE
  v_bfile BFILE;
  v_length NUMBER;
BEGIN
  -- Mengambil referensi file dari tabel
  SELECT doc_file INTO v_bfile FROM document_files WHERE doc_id = 1;

  -- Mengecek panjang file (ukuran dalam bytes)
  v_length := DBMS_LOB.GETLENGTH(v_bfile);

  -- Menampilkan ukuran file
  DBMS_OUTPUT.PUT_LINE('Ukuran file: ' || v_length || ' bytes');
END;
/

-- 4.5 Menghapus Referensi File
DELETE FROM document_files WHERE doc_id = 1;
COMMIT;
