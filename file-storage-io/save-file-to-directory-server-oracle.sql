-- ## 1. Buat directory folder di server Oracle ##
/*
    mkdir -p /home/oracle/opt/oracle/files
    chmod 755 /home/oracle/opt/oracle/files
*/

-- ## 2. Buat Directory di Database Oracle LOGIN SEBAGAI SYS ##
CREATE OR REPLACE DIRECTORY MY_DIR AS '/home/oracle/opt/oracle/files';
GRANT READ, WRITE ON DIRECTORY MY_DIR TO XTD;

-- ## 3. Cek apakah directory berhasil dibuat ##
SELECT * FROM all_directories WHERE directory_name = 'MY_DIR';

-- ## 4. Buat table untuk log upload file ##
CREATE TABLE file_upload_log (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    file_name   VARCHAR2(500),
    file_path   VARCHAR2(1000),
    file_size   NUMBER,
    mime_type   VARCHAR2(200),
    uploaded_by VARCHAR2(100),
    uploaded_at TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- ## 5. Buat page file uploader dengan process submit seperti dibawah
DECLARE
    v_blob      BLOB;
    v_filename  VARCHAR2(500);
    v_mime      VARCHAR2(200);
BEGIN
    -- Ambil file dari temporary storage APEX
    SELECT blob_content, filename, mime_type
    INTO   v_blob, v_filename, v_mime
    FROM   apex_application_temp_files
    WHERE  name = :P2_UPLOAD;
    
    -- Panggil procedure untuk simpan ke server
    save_file_to_server(
        p_file_name  => v_filename,
        p_mime_type  => v_mime,
        p_file_blob  => v_blob
    );
    
    -- Hapus dari temp storage APEX
    DELETE FROM apex_application_temp_files
    WHERE name = :P2_UPLOAD;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        APEX_ERROR.ADD_ERROR(
            p_message => 'File tidak ditemukan. Silakan pilih file terlebih dahulu.',
            p_display_location => apex_error.c_inline_in_notification
        );
    WHEN OTHERS THEN
        APEX_ERROR.ADD_ERROR(
            p_message => 'Gagal upload file: ' || SQLERRM,
            p_display_location => apex_error.c_inline_in_notification
        );
END;

-- ## 6. List file upload beserta path
SELECT * FROM file_upload_log;
