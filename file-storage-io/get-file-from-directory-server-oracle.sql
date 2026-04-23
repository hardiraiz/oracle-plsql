-- ## 1. Create procedure to get file from server
CREATE OR REPLACE PROCEDURE get_file_from_server(
    p_file_path IN VARCHAR2,
    p_file_name IN VARCHAR2,
    p_mime_type IN VARCHAR2
) AS
    v_file      UTL_FILE.FILE_TYPE;
    v_buffer    RAW(32767);
    v_blob      BLOB;
    v_amount    BINARY_INTEGER := 32767;
BEGIN
    -- Inisialisasi BLOB temporary
    DBMS_LOB.CREATETEMPORARY(v_blob, TRUE);
    
    -- Buka file dari directory server
    v_file := UTL_FILE.FOPEN('MY_DIR', p_file_name, 'RB', 32767);
    
    -- Baca file chunk per chunk ke BLOB
    BEGIN
        LOOP
            UTL_FILE.GET_RAW(v_file, v_buffer, v_amount);
            DBMS_LOB.WRITEAPPEND(v_blob, UTL_RAW.LENGTH(v_buffer), v_buffer);
        END LOOP;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- End of file, normal
    END;
    
    UTL_FILE.FCLOSE(v_file);
    
    -- Set HTTP Header untuk download/view
    OWA_UTIL.MIME_HEADER(p_mime_type, FALSE);
    HTP.P('Content-Length: ' || DBMS_LOB.GETLENGTH(v_blob));
    HTP.P('Content-Disposition: inline; filename="' || p_file_name || '"');
    OWA_UTIL.HTTP_HEADER_CLOSE;
    
    -- Stream BLOB ke browser
    WPG_DOCLOAD.DOWNLOAD_FILE(v_blob);
    
    -- Bebaskan memori
    DBMS_LOB.FREETEMPORARY(v_blob);
    APEX_APPLICATION.STOP_APEX_ENGINE;

EXCEPTION
    WHEN OTHERS THEN
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
        RAISE;
END get_file_from_server;
/