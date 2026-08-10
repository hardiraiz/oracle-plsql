CREATE TABLE karyawan_kompleks (
    -- 1. TIPE DATA KARAKTER / TEKS (STRING)
    id_karyawan         VARCHAR2(50),          -- Teks dengan panjang variabel
    kode_divisi         CHAR(3),               -- Teks dengan panjang tetap (pasti 3 karakter)
    nama_lengkap        NVARCHAR2(100),        -- Teks Unicode variabel (mendukung berbagai bahasa)
    inisial_negara      NCHAR(2),              -- Teks Unicode tetap
    riwayat_hidup       CLOB,                  -- Teks sangat panjang (dokumen/CV)

    -- 2. TIPE DATA ANGKA (NUMERIC)
    gaji_pokok          NUMBER(10, 2),         -- Angka desimal (maks 10 digit, 2 di belakang koma)
    faktor_pengali      FLOAT(63),             -- Angka pecahan dengan presisi biner
    nilai_efisiensi     BINARY_FLOAT,          -- Angka pecahan presisi tunggal (cepat)
    nilai_saham_opsi    BINARY_DOUBLE,         -- Angka pecahan presisi ganda (cepat)

    -- 3. TIPE DATA TANGGAL DAN WAKTU (DATE/TIME)
    tanggal_lahir       DATE,                           -- Tanggal dan waktu standar
    waktu_dibuat        TIMESTAMP(6),                   -- Waktu detail hingga pecahan detik
    waktu_absensi       TIMESTAMP WITH TIME ZONE,       -- Waktu detail dilengkapi zona waktu asal
    waktu_update_lokal  TIMESTAMP WITH LOCAL TIME ZONE, -- Waktu otomatis dikonversi ke zona waktu user

    -- 4. TIPE DATA BINER (BINARY / LOB)
    foto_profil         BLOB,                  -- Data biner besar (file gambar/pdf)
    sidik_jari_mentah   RAW(2000),             -- Data biner kecil mentah
    dokumen_kontrak     BFILE,                 -- Pointer ke file eksternal di luar database

    -- 5. TIPE DATA BARIS (ROWID)
    referensi_rowid     ROWID                  -- Menyimpan alamat fisik baris data lain
);