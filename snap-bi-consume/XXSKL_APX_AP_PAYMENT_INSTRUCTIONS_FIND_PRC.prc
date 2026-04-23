/* Formatted on 9/23/2025 5:25:20 PM (QP5 v5.362) */
CREATE OR REPLACE PROCEDURE XXSKL_APX_AP_PAYMENT_INSTRUCTIONS_FIND_PRC (
    P_BANK_ACCOUNT_ID   IN NUMBER,
    P_START_DATE        IN VARCHAR2,
    P_END_DATE          IN VARCHAR2)
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
         WHERE REPORT_NAME = V_REPORT_NAME   --               AND STATUS = 'A'
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
        P_PARAMETER_VALUE1    => P_BANK_ACCOUNT_ID,
        P_PARAMETER_NAME2     => T_EXT_REPORT.PARAMETER_NAME2,
        P_PARAMETER_VALUE2    => P_START_DATE,
        P_PARAMETER_NAME3     => T_EXT_REPORT.PARAMETER_NAME3,
        P_PARAMETER_VALUE3    => P_END_DATE,
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
    
--    DBMS_OUTPUT.PUT_LINE('V_FILE_DATA   = '||TO_CHAR(V_FILE_DATA));
--
--        DELETE FROM
--            XXSKL_AP_PAYMENT_INSTRUCTIONS
--              WHERE     1 = 1
--                    AND HEADER_ID IS NULL
--                    AND (PAYMENT_SERVICE_REQUEST_ID) IN
--                            (SELECT T.COLUMN58
--                               FROM TABLE (LOB2TABLE.SEPARATEDCOLUMNS (
--                                               V_FILE_DATA,
--                                               CHR (
--                                                   10),
--                                               V_COLUMN_DELIMITER,
--                                               NULL,
--                                               V_ENCLOSED_BY)) T
--                              WHERE T.ROW_NO > 1);
--    
--        COMMIT;
--    
--        INSERT INTO XXSKL_AP_PAYMENT_INSTRUCTIONS (PAYMENT_PROCESS_REQUEST_NAME,
--                                                   PAYMENT_DATE,
--                                                   PAYMENT_DUE_DATE,
--                                                   PAYMENT_REFERENCE_NUMBER,
--                                                   PAPER_DOCUMENT_NUMBER,
--                                                   PAYMENT_CURRENCY_CODE,
--                                                   PAYMENT_AMOUNT,
--                                                   INTERNAL_BANK_ACCOUNT_NUM,
--                                                   INTERNAL_BANK_NAME,
--                                                   EXTERNAL_BANK_ACCOUNT_NUM,
--                                                   EXTERNAL_BANK_NAME,
--                                                   EXTERNAL_BANK_ACCOUNT_NAME,
--                                                   EXTERNAL_BANK_NUMBER,
--                                                   EXTERNAL_EFT_SWIFT_CODE,
--                                                   PAYEE_NAME,
--                                                   PAYEE_PARTY_NAME,
--                                                   PAYEE_ADDRESS1,
--                                                   PAYEE_CITY,
--                                                   PARTY_SITE_NAME,
--                                                   PAYEE_ADDRESS_CONCAT,
--                                                   PAYMENT_PROFILE_SYS_NAME,
--                                                   PAYMENT_PROFILE_ACCT_NAME,
--                                                   INT_BANK_NAME,
--                                                   INT_BANK_NUMBER,
--                                                   INT_BIC,
--                                                   INT_BANK_BRANCH_NAME,
--                                                   INT_BANK_BRANCH_NUMBER,
--                                                   INT_BANK_ACCOUNT_NAME,
--                                                   INT_BANK_ACCOUNT_NUMBER,
--                                                   INT_BANK_ACCOUNT_IBAN,
--                                                   INT_EFT_SWIFT_CODE,
--                                                   INVOICE_NUM,
--                                                   INVOICE_DATE,
--                                                   INVOICE_AMOUNT,
--                                                   PAYER_LEGAL_ENTITY_NAME,
--                                                   ORG_NAME,
--                                                   PAYEE_PARTY_NUMBER,
--                                                   PAYEE_SUPPLIER_NUMBER,
--                                                   EXTERNAL_BANK_ACCOUNT_ID,
--                                                   PAYMENT_PROFILE_ID,
--                                                   INTERNAL_BANK_ACCOUNT_ID,
--                                                   INT_BANK_BRANCH_PARTY_ID,
--                                                   EXT_BANK_BRANCH_PARTY_ID,
--                                                   INVOICING_LEGAL_ENTITY_ID,
--                                                   PAYMENT_ID,
--                                                   ORG_ID,
--                                                   LEGAL_ENTITY_ID,
--                                                   SET_OF_BOOKS_ID,
--                                                   EXT_PAYEE_ID,
--                                                   PAYER_PARTY_ID,
--                                                   PAYER_LOCATION_ID,
--                                                   PAYMENT_INSTRUCTION_ID,
--                                                   PAYEE_PARTY_ID,
--                                                   PARTY_SITE_ID,
--                                                   SUPPLIER_SITE_ID,
--                                                   INVOICE_ID,
--                                                   CHECK_ID,
--                                                   PAYMENT_SERVICE_REQUEST_ID,
--                                                   ATTRIBUTE_CATEGORY,
--                                                   ATTRIBUTE1,
--                                                   ATTRIBUTE2,
--                                                   ATTRIBUTE3,
--                                                   ATTRIBUTE4,
--                                                   ATTRIBUTE5,
--                                                   ATTRIBUTE6,
--                                                   ATTRIBUTE7,
--                                                   ATTRIBUTE8,
--                                                   ATTRIBUTE9,
--                                                   ATTRIBUTE10,
--                                                   ATTRIBUTE11,
--                                                   ATTRIBUTE12,
--                                                   ATTRIBUTE13,
--                                                   ATTRIBUTE14,
--                                                   ATTRIBUTE15,
--                                                   CREATED_BY,
--                                                   CREATION_DATE,
--                                                   LAST_UPDATE_LOGIN,
--                                                   LAST_UPDATED_BY,
--                                                   LAST_UPDATE_DATE,
--                                                   LAST_SYNC_DATE
--                                                   )
--            SELECT COLUMN1,
--                   TO_DATE (COLUMN2, 'YYYY-MM-DD HH24:MI:SS'),
--                   TO_DATE (COLUMN3, 'YYYY-MM-DD HH24:MI:SS'),
--                   COLUMN4,
--                   COLUMN5,
--                   COLUMN6,
--                   COLUMN7,
--                   COLUMN8,
--                   COLUMN9,
--                   COLUMN10,
--                   COLUMN11,
--                   COLUMN12,
--                   COLUMN13,
--                   COLUMN14,
--                   COLUMN15,
--                   COLUMN16,
--                   COLUMN17,
--                   COLUMN18,
--                   COLUMN19,
--                   COLUMN20,
--                   COLUMN21,
--                   COLUMN22,
--                   COLUMN23,
--                   COLUMN24,
--                   COLUMN25,
--                   COLUMN26,
--                   COLUMN27,
--                   COLUMN28,
--                   COLUMN29,
--                   COLUMN30,
--                   COLUMN31,
--                   COLUMN32,
--                   TO_DATE (COLUMN33, 'YYYY-MM-DD HH24:MI:SS'),
--                   COLUMN34,
--                   COLUMN35,
--                   COLUMN36,
--                   COLUMN37,
--                   COLUMN38,
--                   COLUMN39,
--                   COLUMN40,
--                   COLUMN41,
--                   COLUMN42,
--                   COLUMN43,
--                   COLUMN44,
--                   COLUMN45,
--                   COLUMN46,
--                   COLUMN47,
--                   COLUMN48,
--                   COLUMN49,
--                   COLUMN50,
--                   COLUMN51,
--                   COLUMN52,
--                   COLUMN53,
--                   COLUMN54,
--                   COLUMN55,
--                   COLUMN56,
--                   COLUMN57,
--                   COLUMN58,
--                   COLUMN59,
--                   COLUMN60,
--                   COLUMN61,
--                   COLUMN62,
--                   COLUMN63,
--                   COLUMN64,
--                   COLUMN65,
--                   COLUMN66,
--                   COLUMN67,
--                   COLUMN68,
--                   COLUMN69,
--                   COLUMN70,
--                   COLUMN71,
--                   COLUMN72,
--                   COLUMN73,
--                   COLUMN74,
--                   COLUMN75,
--                   TO_DATE (COLUMN76, 'YYYY-MM-DD HH24:MI:SS'),
--                   COLUMN77,
--                   COLUMN78,
--                   TO_DATE (COLUMN79, 'YYYY-MM-DD HH24:MI:SS'),
--                   SYSDATE
--              FROM TABLE (LOB2TABLE.SEPARATEDCOLUMNS (V_FILE_DATA,
--                                                      CHR (10),
--                                                      V_COLUMN_DELIMITER,
--                                                      NULL,
--                                                      V_ENCLOSED_BY))
--             WHERE     ROW_NO > 1
--                   AND NOT EXISTS
--                           (SELECT 1
--                              FROM XXSKL_AP_PAYMENT_INSTRUCTIONS XAPI
--                             WHERE     1 = 1
--                                   AND XAPI.PAYMENT_SERVICE_REQUEST_ID = COLUMN58
--                                   AND XAPI.HEADER_ID IS NOT NULL);

    MERGE INTO XXSKL_AP_PAYMENT_INSTRUCTIONS XAPI
         USING (SELECT COLUMN1
                           PAYMENT_PROCESS_REQUEST_NAME,
                       TO_DATE (COLUMN2, 'YYYY-MM-DD HH24:MI:SS')
                           PAYMENT_DATE,
                       TO_DATE (COLUMN3, 'YYYY-MM-DD HH24:MI:SS')
                           PAYMENT_DUE_DATE,
                       COLUMN4
                           PAYMENT_REFERENCE_NUMBER,
                       COLUMN5
                           PAPER_DOCUMENT_NUMBER,
                       COLUMN6
                           PAYMENT_CURRENCY_CODE,
                       COLUMN7
                           PAYMENT_AMOUNT,
                       COLUMN8
                           INTERNAL_BANK_ACCOUNT_NUM,
                       COLUMN9
                           INTERNAL_BANK_NAME,
                       COLUMN10
                           EXTERNAL_BANK_ACCOUNT_NUM,
                       COLUMN11
                           EXTERNAL_BANK_NAME,
                       COLUMN12
                           EXTERNAL_BANK_ACCOUNT_NAME,
                       COLUMN13
                           EXTERNAL_BANK_NUMBER,
                       COLUMN14
                           EXTERNAL_EFT_SWIFT_CODE,
                       COLUMN15
                           PAYEE_NAME,
                       COLUMN16
                           PAYEE_PARTY_NAME,
                       COLUMN17
                           PAYEE_ADDRESS1,
                       COLUMN18
                           PAYEE_CITY,
                       COLUMN19
                           PARTY_SITE_NAME,
                       COLUMN20
                           PAYEE_ADDRESS_CONCAT,
                       COLUMN21
                           PAYMENT_PROFILE_SYS_NAME,
                       COLUMN22
                           PAYMENT_PROFILE_ACCT_NAME,
                       COLUMN23
                           INT_BANK_NAME,
                       COLUMN24
                           INT_BANK_NUMBER,
                       COLUMN25
                           INT_BIC,
                       COLUMN26
                           INT_BANK_BRANCH_NAME,
                       COLUMN27
                           INT_BANK_BRANCH_NUMBER,
                       COLUMN28
                           INT_BANK_ACCOUNT_NAME,
                       COLUMN29
                           INT_BANK_ACCOUNT_NUMBER,
                       COLUMN30
                           INT_BANK_ACCOUNT_IBAN,
                       COLUMN31
                           INT_EFT_SWIFT_CODE,
                       COLUMN32
                           INVOICE_NUM,
                       TO_DATE (COLUMN33, 'YYYY-MM-DD HH24:MI:SS')
                           INVOICE_DATE,
                       COLUMN34
                           INVOICE_AMOUNT,
                       COLUMN35
                           PAYER_LEGAL_ENTITY_NAME,
                       COLUMN36
                           ORG_NAME,
                       COLUMN37
                           PAYEE_PARTY_NUMBER,
                       COLUMN38
                           PAYEE_SUPPLIER_NUMBER,
                       COLUMN39
                           EXTERNAL_BANK_ACCOUNT_ID,
                       COLUMN40
                           PAYMENT_PROFILE_ID,
                       COLUMN41
                           INTERNAL_BANK_ACCOUNT_ID,
                       COLUMN42
                           INT_BANK_BRANCH_PARTY_ID,
                       COLUMN43
                           EXT_BANK_BRANCH_PARTY_ID,
                       COLUMN44
                           INVOICING_LEGAL_ENTITY_ID,
                       COLUMN45
                           PAYMENT_ID,
                       COLUMN46
                           ORG_ID,
                       COLUMN47
                           LEGAL_ENTITY_ID,
                       COLUMN48
                           SET_OF_BOOKS_ID,
                       COLUMN49
                           EXT_PAYEE_ID,
                       COLUMN50
                           PAYER_PARTY_ID,
                       COLUMN51
                           PAYER_LOCATION_ID,
                       COLUMN52
                           PAYMENT_INSTRUCTION_ID,
                       COLUMN53
                           PAYEE_PARTY_ID,
                       COLUMN54
                           PARTY_SITE_ID,
                       COLUMN55
                           SUPPLIER_SITE_ID,
                       COLUMN56
                           INVOICE_ID,
                       COLUMN57
                           CHECK_ID,
                       COLUMN58
                           PAYMENT_SERVICE_REQUEST_ID,
                       COLUMN59
                           ATTRIBUTE_CATEGORY,
                       COLUMN60
                           ATTRIBUTE1,
                       COLUMN61
                           ATTRIBUTE2,
                       COLUMN62
                           ATTRIBUTE3,
                       COLUMN63
                           ATTRIBUTE4,
                       COLUMN64
                           ATTRIBUTE5,
                       COLUMN65
                           ATTRIBUTE6,
                       COLUMN66
                           ATTRIBUTE7,
                       COLUMN67
                           ATTRIBUTE8,
                       COLUMN68
                           ATTRIBUTE9,
                       COLUMN69
                           ATTRIBUTE10,
                       COLUMN70
                           ATTRIBUTE11,
                       COLUMN71
                           ATTRIBUTE12,
                       COLUMN72
                           ATTRIBUTE13,
                       COLUMN73
                           ATTRIBUTE14,
                       COLUMN74
                           ATTRIBUTE15,
                       COLUMN75
                           CREATED_BY,
                       TO_DATE (COLUMN76, 'YYYY-MM-DD HH24:MI:SS')
                           CREATION_DATE,
                       COLUMN77
                           LAST_UPDATE_LOGIN,
                       COLUMN78
                           LAST_UPDATED_BY,
                       TO_DATE (COLUMN79, 'YYYY-MM-DD HH24:MI:SS')
                           LAST_UPDATE_DATE,
                       SYSDATE
                           LAST_SYNC_DATE
                  FROM TABLE (LOB2TABLE.SEPARATEDCOLUMNS (V_FILE_DATA,
                                                          CHR (10),
                                                          V_COLUMN_DELIMITER,
                                                          NULL,
                                                          V_ENCLOSED_BY))
                 WHERE ROW_NO > 1) SRC
            ON (XAPI.PAYMENT_SERVICE_REQUEST_ID =
                SRC.PAYMENT_SERVICE_REQUEST_ID)
    WHEN MATCHED
    THEN
        UPDATE SET
            XAPI.PAYMENT_PROCESS_REQUEST_NAME =
                SRC.PAYMENT_PROCESS_REQUEST_NAME,
            XAPI.PAYMENT_DATE = SRC.PAYMENT_DATE,
            XAPI.PAYMENT_DUE_DATE = SRC.PAYMENT_DUE_DATE,
            XAPI.PAYMENT_REFERENCE_NUMBER = SRC.PAYMENT_REFERENCE_NUMBER,
            XAPI.PAPER_DOCUMENT_NUMBER = SRC.PAPER_DOCUMENT_NUMBER,
            XAPI.PAYMENT_CURRENCY_CODE = SRC.PAYMENT_CURRENCY_CODE,
            XAPI.PAYMENT_AMOUNT = SRC.PAYMENT_AMOUNT,
            XAPI.INTERNAL_BANK_ACCOUNT_NUM = SRC.INTERNAL_BANK_ACCOUNT_NUM,
            XAPI.INTERNAL_BANK_NAME = SRC.INTERNAL_BANK_NAME,
            XAPI.EXTERNAL_BANK_ACCOUNT_NUM = SRC.EXTERNAL_BANK_ACCOUNT_NUM,
            XAPI.EXTERNAL_BANK_NAME = SRC.EXTERNAL_BANK_NAME,
            XAPI.EXTERNAL_BANK_ACCOUNT_NAME = SRC.EXTERNAL_BANK_ACCOUNT_NAME,
            XAPI.EXTERNAL_BANK_NUMBER = SRC.EXTERNAL_BANK_NUMBER,
            XAPI.EXTERNAL_EFT_SWIFT_CODE = SRC.EXTERNAL_EFT_SWIFT_CODE,
            XAPI.PAYEE_NAME = SRC.PAYEE_NAME,
            XAPI.PAYEE_PARTY_NAME = SRC.PAYEE_PARTY_NAME,
            XAPI.PAYEE_ADDRESS1 = SRC.PAYEE_ADDRESS1,
            XAPI.PAYEE_CITY = SRC.PAYEE_CITY,
            XAPI.PARTY_SITE_NAME = SRC.PARTY_SITE_NAME,
            XAPI.PAYEE_ADDRESS_CONCAT = SRC.PAYEE_ADDRESS_CONCAT,
            XAPI.PAYMENT_PROFILE_SYS_NAME = SRC.PAYMENT_PROFILE_SYS_NAME,
            XAPI.PAYMENT_PROFILE_ACCT_NAME = SRC.PAYMENT_PROFILE_ACCT_NAME,
            XAPI.INT_BANK_NAME = SRC.INT_BANK_NAME,
            XAPI.INT_BANK_NUMBER = SRC.INT_BANK_NUMBER,
            XAPI.INT_BIC = SRC.INT_BIC,
            XAPI.INT_BANK_BRANCH_NAME = SRC.INT_BANK_BRANCH_NAME,
            XAPI.INT_BANK_BRANCH_NUMBER = SRC.INT_BANK_BRANCH_NUMBER,
            XAPI.INT_BANK_ACCOUNT_NAME = SRC.INT_BANK_ACCOUNT_NAME,
            XAPI.INT_BANK_ACCOUNT_NUMBER = SRC.INT_BANK_ACCOUNT_NUMBER,
            XAPI.INT_BANK_ACCOUNT_IBAN = SRC.INT_BANK_ACCOUNT_IBAN,
            XAPI.INT_EFT_SWIFT_CODE = SRC.INT_EFT_SWIFT_CODE,
            XAPI.INVOICE_NUM = SRC.INVOICE_NUM,
            XAPI.INVOICE_DATE = SRC.INVOICE_DATE,
            XAPI.INVOICE_AMOUNT = SRC.INVOICE_AMOUNT,
            XAPI.PAYER_LEGAL_ENTITY_NAME = SRC.PAYER_LEGAL_ENTITY_NAME,
            XAPI.ORG_NAME = SRC.ORG_NAME,
            XAPI.PAYEE_PARTY_NUMBER = SRC.PAYEE_PARTY_NUMBER,
            XAPI.PAYEE_SUPPLIER_NUMBER = SRC.PAYEE_SUPPLIER_NUMBER,
            XAPI.EXTERNAL_BANK_ACCOUNT_ID = SRC.EXTERNAL_BANK_ACCOUNT_ID,
            XAPI.PAYMENT_PROFILE_ID = SRC.PAYMENT_PROFILE_ID,
            XAPI.INTERNAL_BANK_ACCOUNT_ID = SRC.INTERNAL_BANK_ACCOUNT_ID,
            XAPI.INT_BANK_BRANCH_PARTY_ID = SRC.INT_BANK_BRANCH_PARTY_ID,
            XAPI.EXT_BANK_BRANCH_PARTY_ID = SRC.EXT_BANK_BRANCH_PARTY_ID,
            XAPI.INVOICING_LEGAL_ENTITY_ID = SRC.INVOICING_LEGAL_ENTITY_ID,
            XAPI.PAYMENT_ID = SRC.PAYMENT_ID,
            XAPI.ORG_ID = SRC.ORG_ID,
            XAPI.LEGAL_ENTITY_ID = SRC.LEGAL_ENTITY_ID,
            XAPI.SET_OF_BOOKS_ID = SRC.SET_OF_BOOKS_ID,
            XAPI.EXT_PAYEE_ID = SRC.EXT_PAYEE_ID,
            XAPI.PAYER_PARTY_ID = SRC.PAYER_PARTY_ID,
            XAPI.PAYER_LOCATION_ID = SRC.PAYER_LOCATION_ID,
            XAPI.PAYMENT_INSTRUCTION_ID = SRC.PAYMENT_INSTRUCTION_ID,
            XAPI.PAYEE_PARTY_ID = SRC.PAYEE_PARTY_ID,
            XAPI.PARTY_SITE_ID = SRC.PARTY_SITE_ID,
            XAPI.SUPPLIER_SITE_ID = SRC.SUPPLIER_SITE_ID,
            XAPI.INVOICE_ID = SRC.INVOICE_ID,
            XAPI.CHECK_ID = SRC.CHECK_ID,
            XAPI.ATTRIBUTE_CATEGORY = SRC.ATTRIBUTE_CATEGORY,
            XAPI.ATTRIBUTE1 = SRC.ATTRIBUTE1,
            XAPI.ATTRIBUTE2 = SRC.ATTRIBUTE2,
            XAPI.ATTRIBUTE3 = SRC.ATTRIBUTE3,
            XAPI.ATTRIBUTE4 = SRC.ATTRIBUTE4,
            XAPI.ATTRIBUTE5 = SRC.ATTRIBUTE5,
            XAPI.ATTRIBUTE6 = SRC.ATTRIBUTE6,
            XAPI.ATTRIBUTE7 = SRC.ATTRIBUTE7,
            XAPI.ATTRIBUTE8 = SRC.ATTRIBUTE8,
            XAPI.ATTRIBUTE9 = SRC.ATTRIBUTE9,
            XAPI.ATTRIBUTE10 = SRC.ATTRIBUTE10,
            XAPI.ATTRIBUTE11 = SRC.ATTRIBUTE11,
            XAPI.ATTRIBUTE12 = SRC.ATTRIBUTE12,
            XAPI.ATTRIBUTE13 = SRC.ATTRIBUTE13,
            XAPI.ATTRIBUTE14 = SRC.ATTRIBUTE14,
            XAPI.ATTRIBUTE15 = SRC.ATTRIBUTE15,
            XAPI.CREATED_BY = SRC.CREATED_BY,
            XAPI.CREATION_DATE = SRC.CREATION_DATE,
            XAPI.LAST_UPDATE_LOGIN = SRC.LAST_UPDATE_LOGIN,
            XAPI.LAST_UPDATED_BY = SRC.LAST_UPDATED_BY,
            XAPI.LAST_UPDATE_DATE = SRC.LAST_UPDATE_DATE,
            XAPI.LAST_SYNC_DATE = SRC.LAST_SYNC_DATE
                 WHERE XAPI.HEADER_ID IS NULL
    WHEN NOT MATCHED
    THEN
        INSERT     (PAYMENT_PROCESS_REQUEST_NAME,
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
            VALUES (SRC.PAYMENT_PROCESS_REQUEST_NAME,
                    SRC.PAYMENT_DATE,
                    SRC.PAYMENT_DUE_DATE,
                    SRC.PAYMENT_REFERENCE_NUMBER,
                    SRC.PAPER_DOCUMENT_NUMBER,
                    SRC.PAYMENT_CURRENCY_CODE,
                    SRC.PAYMENT_AMOUNT,
                    SRC.INTERNAL_BANK_ACCOUNT_NUM,
                    SRC.INTERNAL_BANK_NAME,
                    SRC.EXTERNAL_BANK_ACCOUNT_NUM,
                    SRC.EXTERNAL_BANK_NAME,
                    SRC.EXTERNAL_BANK_ACCOUNT_NAME,
                    SRC.EXTERNAL_BANK_NUMBER,
                    SRC.EXTERNAL_EFT_SWIFT_CODE,
                    SRC.PAYEE_NAME,
                    SRC.PAYEE_PARTY_NAME,
                    SRC.PAYEE_ADDRESS1,
                    SRC.PAYEE_CITY,
                    SRC.PARTY_SITE_NAME,
                    SRC.PAYEE_ADDRESS_CONCAT,
                    SRC.PAYMENT_PROFILE_SYS_NAME,
                    SRC.PAYMENT_PROFILE_ACCT_NAME,
                    SRC.INT_BANK_NAME,
                    SRC.INT_BANK_NUMBER,
                    SRC.INT_BIC,
                    SRC.INT_BANK_BRANCH_NAME,
                    SRC.INT_BANK_BRANCH_NUMBER,
                    SRC.INT_BANK_ACCOUNT_NAME,
                    SRC.INT_BANK_ACCOUNT_NUMBER,
                    SRC.INT_BANK_ACCOUNT_IBAN,
                    SRC.INT_EFT_SWIFT_CODE,
                    SRC.INVOICE_NUM,
                    SRC.INVOICE_DATE,
                    SRC.INVOICE_AMOUNT,
                    SRC.PAYER_LEGAL_ENTITY_NAME,
                    SRC.ORG_NAME,
                    SRC.PAYEE_PARTY_NUMBER,
                    SRC.PAYEE_SUPPLIER_NUMBER,
                    SRC.EXTERNAL_BANK_ACCOUNT_ID,
                    SRC.PAYMENT_PROFILE_ID,
                    SRC.INTERNAL_BANK_ACCOUNT_ID,
                    SRC.INT_BANK_BRANCH_PARTY_ID,
                    SRC.EXT_BANK_BRANCH_PARTY_ID,
                    SRC.INVOICING_LEGAL_ENTITY_ID,
                    SRC.PAYMENT_ID,
                    SRC.ORG_ID,
                    SRC.LEGAL_ENTITY_ID,
                    SRC.SET_OF_BOOKS_ID,
                    SRC.EXT_PAYEE_ID,
                    SRC.PAYER_PARTY_ID,
                    SRC.PAYER_LOCATION_ID,
                    SRC.PAYMENT_INSTRUCTION_ID,
                    SRC.PAYEE_PARTY_ID,
                    SRC.PARTY_SITE_ID,
                    SRC.SUPPLIER_SITE_ID,
                    SRC.INVOICE_ID,
                    SRC.CHECK_ID,
                    SRC.PAYMENT_SERVICE_REQUEST_ID,
                    SRC.ATTRIBUTE_CATEGORY,
                    SRC.ATTRIBUTE1,
                    SRC.ATTRIBUTE2,
                    SRC.ATTRIBUTE3,
                    SRC.ATTRIBUTE4,
                    SRC.ATTRIBUTE5,
                    SRC.ATTRIBUTE6,
                    SRC.ATTRIBUTE7,
                    SRC.ATTRIBUTE8,
                    SRC.ATTRIBUTE9,
                    SRC.ATTRIBUTE10,
                    SRC.ATTRIBUTE11,
                    SRC.ATTRIBUTE12,
                    SRC.ATTRIBUTE13,
                    SRC.ATTRIBUTE14,
                    SRC.ATTRIBUTE15,
                    SRC.CREATED_BY,
                    SRC.CREATION_DATE,
                    SRC.LAST_UPDATE_LOGIN,
                    SRC.LAST_UPDATED_BY,
                    SRC.LAST_UPDATE_DATE,
                    SRC.LAST_SYNC_DATE);

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
END XXSKL_APX_AP_PAYMENT_INSTRUCTIONS_FIND_PRC;
/