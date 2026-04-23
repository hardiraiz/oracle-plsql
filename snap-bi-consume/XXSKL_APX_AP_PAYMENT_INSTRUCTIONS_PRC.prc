/* Formatted on 9/6/2025 4:16:23 PM (QP5 v5.362) */
CREATE OR REPLACE PROCEDURE XXSKL_APX_AP_PAYMENT_INSTRUCTIONS_PRC
IS
    /******************************************************************************
     NAME:       XXSKL_APX_AP_PAYMENT_INSTRUCTIONS_PRC
     PURPOSE:

     REVISIONS:
     Ver        Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
     1.0        13/06/2025  ANP           1. Created this procedure.
     ******************************************************************************/
    V_REPORT_NAME        XXSKL_FND_EXT_REPORTS.REPORT_NAME%TYPE
                             := 'Payment Instructions';
    V_COLUMN_DELIMITER   VARCHAR2 (1) := ';';
    V_ENCLOSED_BY        VARCHAR2 (1) := '"';
    T_EXT_REPORT         XXSKL_FND_EXT_REPORTS%ROWTYPE;
    V_LOG_ID             XXSKL_FND_EXT_REPORTS_LOG.LOG_ID%TYPE;
    V_FILE_DATA          BLOB;
    V_STATUS             VARCHAR2 (1);
    V_ERROR_MSG          VARCHAR2 (4000);
    E_EXCEPTION          EXCEPTION;
BEGIN
    BEGIN
        SELECT *
          INTO T_EXT_REPORT
          FROM XXSKL_FND_EXT_REPORTS
         WHERE REPORT_NAME = V_REPORT_NAME --               AND STATUS = 'A'
                                           AND REPORT_PATH IS NOT NULL;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE ('Register External Report not found.');
            RETURN;
    END;

    IF T_EXT_REPORT.ENABLE_LOG = 'Y'
    THEN
        XXSKL_FND_EXT_REPORT_SOAP_PKG.INSERT_UPDATE_LOG (
            P_LOG_ID        => V_LOG_ID,
            P_REPORT_NAME   => V_REPORT_NAME,
            P_STATUS        => 'RUNNING');
    END IF;

    XXSKL_FND_EXT_REPORT_SOAP_PKG.RUN_REPORT (
        P_REPORT_PATH         => T_EXT_REPORT.REPORT_PATH,
        P_PARAMETER_NAME1     => T_EXT_REPORT.PARAMETER_NAME1,
        P_PARAMETER_VALUE1    => T_EXT_REPORT.PARAMETER_VALUE1,
        P_PARAMETER_NAME2     => T_EXT_REPORT.PARAMETER_NAME2,
        P_PARAMETER_VALUE2    => T_EXT_REPORT.PARAMETER_VALUE2,
        P_PARAMETER_NAME3     => T_EXT_REPORT.PARAMETER_NAME3,
        P_PARAMETER_VALUE3    => T_EXT_REPORT.PARAMETER_VALUE3,
        P_PARAMETER_NAME4     => T_EXT_REPORT.PARAMETER_NAME4,
        P_PARAMETER_VALUE4    => T_EXT_REPORT.PARAMETER_VALUE4,
        P_PARAMETER_NAME5     => T_EXT_REPORT.PARAMETER_NAME5,
        P_PARAMETER_VALUE5    => T_EXT_REPORT.PARAMETER_VALUE5,
        P_PARAMETER_NAME6     => T_EXT_REPORT.PARAMETER_NAME6,
        P_PARAMETER_VALUE6    => T_EXT_REPORT.PARAMETER_VALUE6,
        P_PARAMETER_NAME7     => T_EXT_REPORT.PARAMETER_NAME7,
        P_PARAMETER_VALUE7    => T_EXT_REPORT.PARAMETER_VALUE7,
        P_PARAMETER_NAME8     => T_EXT_REPORT.PARAMETER_NAME8,
        P_PARAMETER_VALUE8    => T_EXT_REPORT.PARAMETER_VALUE8,
        P_PARAMETER_NAME9     => T_EXT_REPORT.PARAMETER_NAME9,
        P_PARAMETER_VALUE9    => T_EXT_REPORT.PARAMETER_VALUE9,
        P_PARAMETER_NAME10    => T_EXT_REPORT.PARAMETER_NAME10,
        P_PARAMETER_VALUE10   => T_EXT_REPORT.PARAMETER_VALUE10,
        R_FILE_DATA           => V_FILE_DATA,
        R_STATUS              => V_STATUS,
        R_ERROR_MSG           => V_ERROR_MSG);

    IF V_STATUS = 'E'
    THEN
        RAISE E_EXCEPTION;
    END IF;

    DELETE FROM
        XXSKL_AP_PAYMENT_INSTRUCTIONS
          WHERE     (PAYMENT_SERVICE_REQUEST_ID) IN
                        (SELECT T.COLUMN49
                           FROM TABLE (LOB2TABLE.SEPARATEDCOLUMNS (
                                           V_FILE_DATA,
                                           CHR (
                                               10),
                                           V_COLUMN_DELIMITER,
                                           NULL,
                                           V_ENCLOSED_BY)) T
                          WHERE T.ROW_NO > 1)
                AND IFACE_STATUS IS NOT NULL;

    COMMIT;

    INSERT INTO XXSKL_AP_PAYMENT_INSTRUCTIONS (PAYMENT_PROCESS_REQUEST_NAME,
                                               PAYMENT_DATE,
                                               PAYMENT_DUE_DATE,
                                               PAYMENT_REFERENCE_NUMBER,
                                               PAPER_DOCUMENT_NUMBER,
                                               PAYMENT_CURRENCY_CODE,
                                               PAYMENT_AMOUNT,
                                               INTERNAL_BANK_ACCOUNT_NUM,
                                               INTERNAL_BANK_NAME,
                                               EXTERNAL_BANK_ACCOUNT_NUM,
                                               EXTERNAL_BANK_NAME,
                                               EXTERNAL_BANK_ACCOUNT_NAME,
                                               EXTERNAL_BANK_NUMBER,
                                               EXTERNAL_EFT_SWIFT_CODE,
                                               PAYEE_NAME,
                                               PAYEE_PARTY_NAME,
                                               PAYEE_ADDRESS1,
                                               PAYEE_CITY,
                                               PARTY_SITE_NAME,
                                               PAYEE_ADDRESS_CONCAT,
                                               PAYMENT_PROFILE_SYS_NAME,
                                               PAYMENT_PROFILE_ACCT_NAME,
                                               INT_BANK_NAME,
                                               INT_BANK_NUMBER,
                                               INT_BIC,
                                               INT_BANK_BRANCH_NAME,
                                               INT_BANK_BRANCH_NUMBER,
                                               INT_BANK_ACCOUNT_NAME,
                                               INT_BANK_ACCOUNT_NUMBER,
                                               INT_BANK_ACCOUNT_IBAN,
                                               INT_EFT_SWIFT_CODE,
                                               INVOICE_NUM,
                                               INVOICE_DATE,
                                               INVOICE_AMOUNT,
                                               PAYER_LEGAL_ENTITY_NAME,
                                               ORG_NAME,
                                               PAYEE_PARTY_NUMBER,
                                               PAYEE_SUPPLIER_NUMBER,
                                               EXTERNAL_BANK_ACCOUNT_ID,
                                               PAYMENT_PROFILE_ID,
                                               INTERNAL_BANK_ACCOUNT_ID,
                                               INT_BANK_BRANCH_PARTY_ID,
                                               EXT_BANK_BRANCH_PARTY_ID,
                                               INVOICING_LEGAL_ENTITY_ID,
                                               PAYMENT_ID,
                                               ORG_ID,
                                               LEGAL_ENTITY_ID,
                                               SET_OF_BOOKS_ID,
                                               EXT_PAYEE_ID,
                                               PAYER_PARTY_ID,
                                               PAYER_LOCATION_ID,
                                               PAYMENT_INSTRUCTION_ID,
                                               PAYEE_PARTY_ID,
                                               PARTY_SITE_ID,
                                               SUPPLIER_SITE_ID,
                                               INVOICE_ID,
                                               CHECK_ID,
                                               PAYMENT_SERVICE_REQUEST_ID,
                                               ATTRIBUTE_CATEGORY,
                                               ATTRIBUTE1,
                                               ATTRIBUTE2,
                                               ATTRIBUTE3,
                                               ATTRIBUTE4,
                                               ATTRIBUTE5,
                                               ATTRIBUTE6,
                                               ATTRIBUTE7,
                                               ATTRIBUTE8,
                                               ATTRIBUTE9,
                                               ATTRIBUTE10,
                                               ATTRIBUTE11,
                                               ATTRIBUTE12,
                                               ATTRIBUTE13,
                                               ATTRIBUTE14,
                                               ATTRIBUTE15,
                                               CREATED_BY,
                                               CREATION_DATE,
                                               LAST_UPDATE_LOGIN,
                                               LAST_UPDATED_BY,
                                               LAST_UPDATE_DATE,
                                               LAST_SYNC_DATE)
        SELECT COLUMN1,
               TO_DATE (COLUMN2, 'YYYY-MM-DD HH24:MI:SS'),
               TO_DATE (COLUMN3, 'YYYY-MM-DD HH24:MI:SS'),
               COLUMN4,
               COLUMN5,
               COLUMN6,
               COLUMN7,
               COLUMN8,
               COLUMN9,
               COLUMN10,
               COLUMN11,
               COLUMN12,
               COLUMN13,
               COLUMN14,
               COLUMN15,
               COLUMN16,
               COLUMN17,
               COLUMN18,
               COLUMN19,
               COLUMN20,
               COLUMN21,
               COLUMN22,
               COLUMN23,
               COLUMN24,
               COLUMN25,
               COLUMN26,
               COLUMN27,
               COLUMN28,
               COLUMN29,
               COLUMN30,
               TO_DATE (COLUMN31, 'YYYY-MM-DD HH24:MI:SS'),
               COLUMN32,
               COLUMN33,
               COLUMN34,
               COLUMN35,
               COLUMN36,
               COLUMN37,
               COLUMN38,
               COLUMN39,
               COLUMN40,
               COLUMN41,
               COLUMN42,
               COLUMN43,
               COLUMN44,
               COLUMN45,
               COLUMN46,
               COLUMN47,
               COLUMN48,
               COLUMN49,
               COLUMN50,
               COLUMN51,
               COLUMN52,
               COLUMN53,
               COLUMN54,
               COLUMN55,
               COLUMN56,
               COLUMN57,
               COLUMN58,
               COLUMN59,
               COLUMN60,
               COLUMN61,
               COLUMN62,
               COLUMN63,
               COLUMN64,
               COLUMN65,
               COLUMN66,
               COLUMN67,
               COLUMN68,
               COLUMN69,
               COLUMN70,
               COLUMN71,
               COLUMN72,
               COLUMN73,
               COLUMN74,
               COLUMN75,
               TO_DATE (COLUMN76, 'YYYY-MM-DD HH24:MI:SS'),
               COLUMN77,
               COLUMN78,
               TO_DATE (COLUMN79, 'YYYY-MM-DD HH24:MI:SS'),
               SYSDATE
          FROM TABLE (LOB2TABLE.SEPARATEDCOLUMNS (V_FILE_DATA,
                                                  CHR (10),
                                                  V_COLUMN_DELIMITER,
                                                  NULL,
                                                  V_ENCLOSED_BY))
         WHERE ROW_NO > 1;

    IF T_EXT_REPORT.ENABLE_LOG = 'Y'
    THEN
        XXSKL_FND_EXT_REPORT_SOAP_PKG.INSERT_UPDATE_LOG (
            P_LOG_ID      => V_LOG_ID,
            P_ROW_COUNT   => SQL%ROWCOUNT,
            P_STATUS      => 'SUCCESS');
    END IF;

    COMMIT;
EXCEPTION
    WHEN E_EXCEPTION
    THEN
        IF T_EXT_REPORT.ENABLE_LOG = 'Y'
        THEN
            XXSKL_FND_EXT_REPORT_SOAP_PKG.INSERT_UPDATE_LOG (
                P_LOG_ID      => V_LOG_ID,
                P_STATUS      => 'ERROR',
                P_ERROR_MSG   => V_ERROR_MSG);
        END IF;
    WHEN OTHERS
    THEN
        V_ERROR_MSG := SUBSTR (SQLERRM, 1, 4000);

        IF T_EXT_REPORT.ENABLE_LOG = 'Y'
        THEN
            XXSKL_FND_EXT_REPORT_SOAP_PKG.INSERT_UPDATE_LOG (
                P_LOG_ID      => V_LOG_ID,
                P_STATUS      => 'ERROR',
                P_ERROR_MSG   => V_ERROR_MSG);
        END IF;

        ROLLBACK;
END XXSKL_APX_AP_PAYMENT_INSTRUCTIONS_PRC;
/