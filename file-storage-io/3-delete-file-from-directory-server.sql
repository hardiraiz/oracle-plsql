-- 
CREATE OR REPLACE PROCEDURE delete_file_from_server(
    p_file_name IN VARCHAR2
)
AS
    v_count NUMBER;
BEGIN
    -- Cek apakah file ada di log
    SELECT COUNT(*) INTO v_count
    FROM file_upload_log
    WHERE file_name_server = p_file_name;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 
            'File tidak ditemukan di log: [' || p_file_name || ']');
    END IF;

    -- Hapus file fisik dari directory Oracle
    UTL_FILE.FREMOVE('MY_DIR', p_file_name);

    -- Hapus record dari log
    DELETE FROM file_upload_log
    WHERE file_name_server = p_file_name;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004,
            'Gagal hapus file [' || p_file_name || ']: ' || SQLERRM);
END;
/