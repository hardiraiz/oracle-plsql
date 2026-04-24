-- ## 1. Create procedure to get file from server
create or replace PROCEDURE get_file_from_server(
    p_file_name  IN  VARCHAR2,
    p_file_blob  OUT BLOB,
    p_mime_type  OUT VARCHAR2,
    p_file_size  OUT NUMBER
)
AS
    v_file      UTL_FILE.FILE_TYPE;
    v_buffer    RAW(32767);
    v_amount    BINARY_INTEGER := 32767;
    v_pos       INTEGER := 1;
    v_temp_blob BLOB;
BEGIN
    -- Ambil mime_type dari log
    SELECT mime_type, file_size
    INTO   p_mime_type, p_file_size
    FROM   file_upload_log
    WHERE  file_name_server = p_file_name
    AND    ROWNUM = 1
    ORDER BY id DESC;

    -- Buka file dari directory Oracle
    v_file := UTL_FILE.FOPEN('MY_DIR', p_file_name, 'rb', 32767);

    DBMS_LOB.CREATETEMPORARY(v_temp_blob, TRUE);
    DBMS_LOB.OPEN(v_temp_blob, DBMS_LOB.LOB_READWRITE);

    -- Baca file chunk by chunk
    LOOP
        BEGIN
            UTL_FILE.GET_RAW(v_file, v_buffer, v_amount);
            DBMS_LOB.WRITEAPPEND(v_temp_blob, UTL_RAW.LENGTH(v_buffer), v_buffer);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN EXIT;
        END;
    END LOOP;

    UTL_FILE.FCLOSE(v_file);
    p_file_blob := v_temp_blob;

EXCEPTION
    WHEN OTHERS THEN
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
        RAISE;
END;
/

-- ## 2 Create Blank Page (Page Id: 3)
/*
    a. Add Page item P3_FILENAME, Type: Hidden, Value Protected: Disabled
    b. Add Before Header Proccess with PLSQL Syntax Bellow
*/
DECLARE
    v_blob      BLOB;
    v_mime      VARCHAR2(200);
    v_size      NUMBER;
    v_filename  VARCHAR2(500);
    v_filename_encoded VARCHAR2(500);
BEGIN
    v_filename := :P3_FILENAME;

    IF v_filename IS NULL THEN
        RETURN;
    END IF;

    -- Encode filename untuk handle spasi & karakter khusus
    -- v_filename_encoded := UTL_URL.ESCAPE(v_filename, TRUE, 'UTF-8');

    -- Baca file dari server
    get_file_from_server(
        p_file_name  => v_filename,
        p_file_blob  => v_blob,
        p_mime_type  => v_mime,
        p_file_size  => v_size
    );

    -- Pastikan BLOB tidak kosong
    IF v_blob IS NULL OR DBMS_LOB.GETLENGTH(v_blob) = 0 THEN
        HTP.P('Error: File kosong atau tidak ditemukan.');
        RETURN;
    END IF;

    -- Set HTTP header (urutan ini penting!)
    OWA_UTIL.MIME_HEADER(NVL(v_mime, 'application/octet-stream'), FALSE);
    HTP.P('Content-Length: ' || DBMS_LOB.GETLENGTH(v_blob));
    HTP.P('Content-Disposition: attachment; filename="' || v_filename || '"; filename*=UTF-8''' || v_filename);
    HTP.P('Cache-Control: no-store, no-cache, must-revalidate');
    HTP.P('Pragma: no-cache');
    OWA_UTIL.HTTP_HEADER_CLOSE;

    -- Kirim BLOB ke browser
    WPG_DOCLOAD.DOWNLOAD_FILE(v_blob);

    APEX_APPLICATION.STOP_APEX_ENGINE;

EXCEPTION
    WHEN APEX_APPLICATION.E_STOP_APEX_ENGINE THEN
        RAISE; -- wajib di-raise ulang, jangan ditangkap!
    WHEN OTHERS THEN
        APEX_ERROR.ADD_ERROR(
            p_message          => 'Gagal download: ' || SQLERRM,
            p_display_location => apex_error.c_inline_in_notification
        );
END;

-- ## 3. Create page interactive report or classic report with query bellow
SELECT
    id,
    file_name,
    file_size,
    mime_type,
    uploaded_by,
    uploaded_at,
    -- Kolom link download
    APEX_UTIL.PREPARE_URL(
        APEX_PAGE.GET_URL(
            p_page   => 3,                  -- adjust with page id target
            p_items  => 'P3_FILENAME',      -- adjust with page item to stored value
            p_values => file_name_server
        )
    ) AS download_url
FROM file_upload_log
ORDER BY id DESC;

-- ## 4. Adjust colom download url to
/*
    Identification -> Type : Link

    Link -> Target          -> Type : URL
                            -> URL  : #DOWNLOAD_URL#
         -> Link Text       -> download
         -> Link Attributes -> target="_blank"
*/

