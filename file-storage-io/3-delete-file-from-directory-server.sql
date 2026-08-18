-- ## 1. Create procedure
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

-- ## 2 Create Blank Page (Page Id: 5)
/*
    a. Add Page item P5_FILENAME, Type: Hidden, Value Protected: Disabled
    b. Add Before Header Proccess with PLSQL Syntax Bellow
*/
DECLARE
    v_filename  VARCHAR2(500);
    v_back_url  VARCHAR2(1000);
BEGIN
    v_filename := :P5_FILENAME;

    IF v_filename IS NULL THEN
        RETURN;
    END IF;

    -- Hapus file dari server dan log
    delete_file_from_server(p_file_name => v_filename);

    -- Redirect kembali ke halaman IR setelah delete berhasil
    -- Ganti angka 2 dengan nomor page IR Anda
    APEX_APPLICATION.G_UNRECOVERABLE_ERROR := FALSE;
    APEX_UTIL.REDIRECT_URL(
        APEX_PAGE.GET_URL(p_page => 4) -- sesuaikan nomor page IR
    );

EXCEPTION
    WHEN OTHERS THEN
        APEX_ERROR.ADD_ERROR(
            p_message          => 'Gagal hapus file: ' || SQLERRM,
            p_display_location => apex_error.c_inline_in_notification
        );
END;

-- ## 3. Adjust page interactive report or classic report with query to display list item
