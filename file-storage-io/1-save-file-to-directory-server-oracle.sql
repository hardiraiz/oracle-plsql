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
    id                  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    file_name           VARCHAR2(1000),
    file_name_server    VARCHAR2(1000),
    file_path           VARCHAR2(1000),
    file_size           NUMBER,
    mime_type           VARCHAR2(200),
    uploaded_by         VARCHAR2(100),
    uploaded_at         TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- ## 5. Buat page file uploader dengan process submit seperti dibawah
create or replace PROCEDURE save_file_to_server(
    p_file_name   IN VARCHAR2,
    p_mime_type   IN VARCHAR2,
    p_file_blob   IN BLOB
) AS
    v_file        UTL_FILE.FILE_TYPE;
    v_buffer      RAW(32767);
    v_amount      BINARY_INTEGER := 32767;
    v_pos         INTEGER := 1;
    v_blob_len    INTEGER;
    v_safe_name   VARCHAR2(500);
    v_timestamp   VARCHAR2(30);
BEGIN
    -- Tambahkan timestamp agar nama file unik
    v_timestamp := TO_CHAR(SYSTIMESTAMP, 'YYYYMMDD_HH24MISS_FF3');
    v_safe_name := v_timestamp || '_' || REGEXP_REPLACE(p_file_name, '[^A-Za-z0-9._-]', '_');

    v_blob_len := DBMS_LOB.GETLENGTH(p_file_blob);

    -- Buka file di server untuk ditulis
    v_file := UTL_FILE.FOPEN('MY_DIR', v_safe_name, 'WB', 32767);

    -- Tulis BLOB ke file secara bertahap (chunk)
    WHILE v_pos <= v_blob_len LOOP
        IF v_pos + v_amount - 1 > v_blob_len THEN
            v_amount := v_blob_len - v_pos + 1;
        END IF;

        DBMS_LOB.READ(p_file_blob, v_amount, v_pos, v_buffer);
        UTL_FILE.PUT_RAW(v_file, v_buffer, TRUE);

        v_pos := v_pos + v_amount;
        v_amount := 32767;
    END LOOP;

    UTL_FILE.FCLOSE(v_file);

    -- Simpan metadata ke log table
    INSERT INTO file_upload_log (file_name, file_name_server, file_path, file_size, mime_type, uploaded_by)
    VALUES (
        p_file_name,
        v_safe_name,
        '/home/oracle/opt/oracle/files/' || v_safe_name,
        v_blob_len,
        p_mime_type,
        NVL(V('APP_USER'), USER)
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
        ROLLBACK;
        RAISE;
END save_file_to_server;
/

-- ## 6. Buat page file uploader dengan process submit seperti dibawah
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

-- ## 7. List file upload beserta path
SELECT * FROM file_upload_log;
