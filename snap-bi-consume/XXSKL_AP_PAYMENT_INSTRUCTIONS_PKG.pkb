/* Formatted on 10/11/2025 10:09:09 AM (QP5 v5.362) */
CREATE OR REPLACE PACKAGE BODY XXSKL.XXSKL_AP_PAYMENT_INSTRUCTIONS_PKG
AS
    /******************************************************************************
       NAME:       XXSKL_AP_PAYMENT_INSTRUCTIONS_PKG

       REVISIONS:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        5/27/2025   ANP              1. Created this package.
    ******************************************************************************/

    PROCEDURE INSERT_HEADER_IFACE (
        P_HEADER      IN     XXSKL_AP_PAYMENT_HEADER_INSTRUCTIONS%ROWTYPE,
        R_HEADER_ID      OUT NUMBER,
        R_STATUS         OUT VARCHAR2,
        R_ERROR_MSG      OUT VARCHAR2)
    IS
    BEGIN
        INSERT INTO XXSKL_AP_PAYMENT_HEADER_INSTRUCTIONS (
                        HEADER_ID,
                        PAYMENT_INSTRUCTION_NUMBER,
                        INTERNAL_BANK_ACCOUNT_ID,
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
                        IFACE_MODE,
                        IFACE_STATUS,
                        IFACE_MESSAGE,
                        IFACE_ID,
                        GROUP_ID,
                        REQUEST_ID,
                        LOG_ID,
                        CREATED_BY,
                        CREATION_DATE,
                        LAST_UPDATE_LOGIN,
                        LAST_UPDATED_BY,
                        LAST_UPDATE_DATE,
                        LAST_SYNC_DATE)
             VALUES (P_HEADER.HEADER_ID,
                     P_HEADER.PAYMENT_INSTRUCTION_NUMBER,
                     P_HEADER.INTERNAL_BANK_ACCOUNT_ID,
                     P_HEADER.ATTRIBUTE_CATEGORY,
                     P_HEADER.ATTRIBUTE1,
                     P_HEADER.ATTRIBUTE2,
                     P_HEADER.ATTRIBUTE3,
                     P_HEADER.ATTRIBUTE4,
                     P_HEADER.ATTRIBUTE5,
                     P_HEADER.ATTRIBUTE6,
                     P_HEADER.ATTRIBUTE7,
                     P_HEADER.ATTRIBUTE8,
                     P_HEADER.ATTRIBUTE9,
                     P_HEADER.ATTRIBUTE10,
                     P_HEADER.ATTRIBUTE11,
                     P_HEADER.ATTRIBUTE12,
                     P_HEADER.ATTRIBUTE13,
                     P_HEADER.ATTRIBUTE14,
                     P_HEADER.ATTRIBUTE15,
                     P_HEADER.IFACE_MODE,
                     P_HEADER.IFACE_STATUS,
                     P_HEADER.IFACE_MESSAGE,
                     P_HEADER.IFACE_ID,
                     P_HEADER.GROUP_ID,
                     P_HEADER.REQUEST_ID,
                     P_HEADER.LOG_ID,
                     P_HEADER.CREATED_BY,
                     P_HEADER.CREATION_DATE,
                     P_HEADER.LAST_UPDATE_LOGIN,
                     P_HEADER.LAST_UPDATED_BY,
                     P_HEADER.LAST_UPDATE_DATE,
                     P_HEADER.LAST_SYNC_DATE)
          RETURNING HEADER_ID
               INTO R_HEADER_ID;

        R_STATUS := 'SUCCESS';
    EXCEPTION
        WHEN OTHERS
        THEN
            R_STATUS := 'ERROR';
            R_ERROR_MSG := 'Exception INSERT_HEADER_IFACE = ' || SQLERRM;
    END;

    FUNCTION GENERATE_PAYMENT_INSTRUCTION_NUMBER
        RETURN VARCHAR
    AS
        L_RETURN   VARCHAR2 (200);
    BEGIN
          SELECT    'PAY/'
                 || TO_CHAR (SYSDATE, 'YY/MM')
                 || '/'
                 || LPAD (COUNT (1) + 1, 6, '0')
            INTO L_RETURN
            FROM XXSKL_AP_PAYMENT_HEADER_INSTRUCTIONS
           WHERE     1 = 1
                 AND TO_CHAR (CREATION_DATE, 'YY/MM') =
                     TO_CHAR (SYSDATE, 'YY/MM')
        GROUP BY TO_CHAR (CREATION_DATE, 'YY/MM');

        RETURN L_RETURN;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            SELECT    'PAY/'
                   || TO_CHAR (SYSDATE, 'YY/MM')
                   || '/'
                   || LPAD (COUNT (1), 6, '0')
              INTO L_RETURN
              FROM DUAL;

            RETURN L_RETURN;
    END;

    FUNCTION GET_STATUS_PAID (P_HEADER_ID IN NUMBER)
        RETURN VARCHAR2
    AS
        L_PAID      NUMBER;
        L_COUNT     NUMBER;
        L_PROCESS   NUMBER;
    BEGIN
        SELECT COUNT (1)
          INTO L_PAID
          FROM XXSKL_AP_PAYMENT_INSTRUCTIONS
         WHERE 1 = 1 AND HEADER_ID = P_HEADER_ID AND IFACE_STATUS = 'PAID';

        SELECT COUNT (1)
          INTO L_COUNT
          FROM XXSKL_AP_PAYMENT_INSTRUCTIONS
         WHERE 1 = 1 AND HEADER_ID = P_HEADER_ID;

        SELECT COUNT (1)
          INTO L_PROCESS
          FROM XXSKL_AP_PAYMENT_INSTRUCTIONS
         WHERE 1 = 1 AND IFACE_STATUS IN ('PROCESS','PENDING')
           AND HEADER_ID = P_HEADER_ID;

        IF L_PAID = 0 AND L_PROCESS = 0
        THEN
            RETURN 'UNPAID';
        ELSIF L_PAID = L_COUNT
        THEN
            RETURN 'FULL PAID';
        ELSIF L_PAID <> 0 AND L_PAID <> L_COUNT AND L_PROCESS = 0
        THEN
            RETURN 'PARTIALLY PAID';
        ELSIF L_PROCESS <> 0
        THEN
            RETURN 'PROCESSING';
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 'UNPAID';
    END GET_STATUS_PAID;

    FUNCTION GET_BANK_BALANCE (P_HEADER_ID IN NUMBER)
        RETURN NUMBER
    AS
        L_BALANCE   NUMBER;
    BEGIN
        SELECT NVL (BANK_BALANCE, 0)
          INTO L_BALANCE
          FROM XXSKL_AP_PAYMENT_HEADER_INSTRUCTIONS
         WHERE 1 = 1 AND HEADER_ID = P_HEADER_ID;

        RETURN L_BALANCE;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END GET_BANK_BALANCE;

    FUNCTION GET_TOTAL_AMOUNT (P_HEADER_ID IN NUMBER)
        RETURN NUMBER
    AS
        L_TOTAL   NUMBER;
    BEGIN
        SELECT NVL (SUM (DISTINCT XAPI.PAYMENT_AMOUNT), 0)
          INTO L_TOTAL
          FROM XXSKL_AP_PAYMENT_HEADER_INSTRUCTIONS  XAPHI,
               XXSKL_AP_PAYMENT_INSTRUCTIONS         XAPI
         WHERE     1 = 1
               AND XAPHI.HEADER_ID = XAPI.HEADER_ID
               AND XAPHI.HEADER_ID = P_HEADER_ID;

        RETURN L_TOTAL;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END GET_TOTAL_AMOUNT;

    FUNCTION GET_TOTAL_PAID_AMOUNT (P_HEADER_ID IN NUMBER)
        RETURN NUMBER
    AS
        L_TOTAL   NUMBER;
    BEGIN
        SELECT NVL (SUM (DISTINCT XAPI.PAYMENT_AMOUNT), 0)
          INTO L_TOTAL
          FROM XXSKL_AP_PAYMENT_HEADER_INSTRUCTIONS  XAPHI,
               XXSKL_AP_PAYMENT_INSTRUCTIONS         XAPI
         WHERE     1 = 1
               AND XAPHI.HEADER_ID = XAPI.HEADER_ID
               AND XAPI.IFACE_STATUS = 'PAID'
               AND XAPHI.HEADER_ID = P_HEADER_ID;

        RETURN L_TOTAL;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END GET_TOTAL_PAID_AMOUNT;

    PROCEDURE DO_PAYMENT_INSTRUCTIONS_HEADERS (P_HEADER_ID   IN     NUMBER,
                                               R_STATUS         OUT VARCHAR2,
                                               R_ERROR_MSG      OUT VARCHAR2)
    IS
        L_BAL_AMOUNT          NUMBER;
        L_BAL_AVAIL_AMOUNT    NUMBER;
        L_BAL_LEDGER_AMOUNT   NUMBER;
        L_BAL_STATUS          VARCHAR2 (30);
        L_BAL_MSG             VARCHAR2 (4000);

        L_INQ_BEN_NAME        VARCHAR2 (100);
        L_INQ_INT_STATUS      VARCHAR2 (30);
        L_INQ_INT_MSG         VARCHAR2 (4000);
    BEGIN
        FOR R_PAY_HEADER
            IN (  SELECT XAPHI.HEADER_ID,
                         XAPI.INTERNAL_BANK_NAME,
                         XAPI.INTERNAL_BANK_ACCOUNT_NUM,
                         SUM (XAPI.PAYMENT_AMOUNT)     PAYMENT_AMOUNT
                    FROM XXSKL_AP_PAYMENT_HEADER_INSTRUCTIONS XAPHI,
                         XXSKL_AP_PAYMENT_INSTRUCTIONS       XAPI
                   WHERE     1 = 1
                         AND XAPHI.HEADER_ID = XAPI.HEADER_ID
                         AND XAPI.HEADER_ID = P_HEADER_ID
                         AND XAPHI.IFACE_STATUS = 'PROCESS'
                GROUP BY XAPHI.HEADER_ID,
                         XAPI.INTERNAL_BANK_NAME,
                         XAPI.INTERNAL_BANK_ACCOUNT_NUM)
        LOOP
            IF UPPER (R_PAY_HEADER.INTERNAL_BANK_NAME) = 'BANK MANDIRI'
            THEN
                XXSKL_AP_HOST_TO_HOST_PKG.BMRI_ACCOUNT_INTERNAL_INQUIRY (
                    P_BENEFICIARY_ACCOUNT   =>
                        R_PAY_HEADER.INTERNAL_BANK_ACCOUNT_NUM,
                    X_BENEFICIARY_NAME   => L_INQ_BEN_NAME,
                    X_STATUS             => L_INQ_INT_STATUS,
                    X_ERROR_MSG          => L_INQ_INT_MSG);

                IF L_INQ_INT_STATUS = 'SUCCESS'
                THEN
                    XXSKL_AP_HOST_TO_HOST_PKG.BMRI_ACCOUNT_BALANCE (
                        P_BENEFICIARY_ACCOUNT   =>
                            R_PAY_HEADER.INTERNAL_BANK_ACCOUNT_NUM,
                        X_AMOUNT              => L_BAL_AMOUNT,
                        X_AVAILABLE_BALANCE   => L_BAL_AVAIL_AMOUNT,
                        X_LEDGER_BALANCE      => L_BAL_LEDGER_AMOUNT,
                        X_STATUS              => L_BAL_STATUS,
                        X_ERROR_MSG           => L_BAL_MSG);
                END IF;

                IF L_BAL_STATUS = 'SUCCESS' AND L_INQ_INT_STATUS = 'SUCCESS'
                THEN
                    UPDATE XXSKL_AP_PAYMENT_HEADER_INSTRUCTIONS
                       SET BANK_BALANCE = L_BAL_AVAIL_AMOUNT
                     WHERE     1 = 1
                           AND HEADER_ID = R_PAY_HEADER.HEADER_ID
                           AND IFACE_STATUS = 'PROCESS';

                    R_STATUS := 'SUCCESS';
                ELSIF R_PAY_HEADER.PAYMENT_AMOUNT > L_BAL_AVAIL_AMOUNT
                THEN
                    UPDATE XXSKL_AP_PAYMENT_HEADER_INSTRUCTIONS
                       SET IFACE_MESSAGE = 'Insufficient balances',
                           IFACE_STATUS = 'ERROR'
                     WHERE     1 = 1
                           AND HEADER_ID = R_PAY_HEADER.HEADER_ID
                           AND IFACE_STATUS = 'PROCESS';

                    UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                       SET IFACE_MESSAGE = 'Insufficient balances',
                           IFACE_STATUS = 'ERROR'
                     WHERE     1 = 1
                           AND HEADER_ID = R_PAY_HEADER.HEADER_ID
                           AND IFACE_STATUS = 'PROCESS';

                    R_STATUS := 'ERROR';
                    R_ERROR_MSG := 'Insufficient balances';
                ELSE
                    UPDATE XXSKL_AP_PAYMENT_HEADER_INSTRUCTIONS
                       SET IFACE_MESSAGE =
                               L_INQ_INT_MSG || CHR (13) || L_BAL_MSG,
                           IFACE_STATUS = 'ERROR'
                     WHERE     1 = 1
                           AND HEADER_ID = R_PAY_HEADER.HEADER_ID
                           AND IFACE_STATUS = 'PROCESS';

                    UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                       SET IFACE_MESSAGE =
                               L_INQ_INT_MSG || CHR (13) || L_BAL_MSG,
                           IFACE_STATUS = 'ERROR'
                     WHERE     1 = 1
                           AND HEADER_ID = R_PAY_HEADER.HEADER_ID
                           AND IFACE_STATUS = 'PROCESS';

                    R_STATUS := 'ERROR';
                    R_ERROR_MSG := L_INQ_INT_MSG || CHR (13) || L_BAL_MSG;
                END IF;

                COMMIT;
            ELSIF UPPER (R_PAY_HEADER.INTERNAL_BANK_NAME) =
                  'BANK PAN INDONESIA'
            THEN
                R_STATUS := 'SUCCESS';
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            R_STATUS := 'ERROR';
            R_ERROR_MSG :=
                'Exception DO_PAYMENT_INSTRUCTIONS_HEADERS    = ' || SQLERRM;
    END DO_PAYMENT_INSTRUCTIONS_HEADERS;


    PROCEDURE DO_PAYMENT_INSTRUCTIONS (P_HEADER_ID   IN     NUMBER,
                                       P_CHECK_ID    IN     NUMBER,
                                       R_STATUS         OUT VARCHAR2,
                                       R_ERROR_MSG      OUT VARCHAR2)
    IS
        L_DO_PAY_STATUS              VARCHAR2 (100);
        L_DO_PAY_MSG                 VARCHAR2 (4000);
        L_DO_PAY_EXTERNAL_ID         VARCHAR2 (100);
        L_DO_PAY_PARTNER_REFERENCE   VARCHAR2 (100);

        L_DO_INQ_STATUS              VARCHAR2 (100);
        L_DO_INQ_BEN_NAME            VARCHAR2 (3000);
        L_DO_INQ_MSG                 VARCHAR2 (4000);

        L_BMRI_PARTNER_REF           VARCHAR2 (3000);
        L_PANIN_PARTNER_REF          VARCHAR2 (3000);

        L_PANIN_TRX_DATE             VARCHAR2 (100);
    BEGIN
        FOR R_PAY_INSTRUCTIONS
            IN (  SELECT PAYMENT_PROCESS_REQUEST_NAME,
                         PAYMENT_DATE,
                         PAPER_DOCUMENT_NUMBER,
                         PAYMENT_AMOUNT,
                         INTERNAL_BANK_ACCOUNT_NUM,
                         INTERNAL_BANK_NAME,
                         EXTERNAL_BANK_ACCOUNT_NUM,
                         EXTERNAL_BANK_ACCOUNT_NAME,
                         EXTERNAL_BANK_NAME,
                         EXTERNAL_BANK_NUMBER,
                         EXTERNAL_EFT_SWIFT_CODE,
                         PAYMENT_PROFILE_SYS_NAME,
                         PAYMENT_PROFILE_ACCT_NAME,
                         PAYEE_NAME,
                         INT_BANK_NUMBER,
                         INT_EFT_SWIFT_CODE,
                         CHECK_ID,
                         PAYMENT_INSTRUCTION_ID,
                         PAYMENT_CURRENCY_CODE
                    FROM XXSKL_AP_PAYMENT_INSTRUCTIONS
                   WHERE     1 = 1
                         AND HEADER_ID = NVL (P_HEADER_ID, HEADER_ID)
                         AND CHECK_ID = NVL (P_CHECK_ID, CHECK_ID)
                         AND IFACE_STATUS = 'PROCESS'
                GROUP BY PAYMENT_PROCESS_REQUEST_NAME,
                         PAYMENT_DATE,
                         PAPER_DOCUMENT_NUMBER,
                         PAYMENT_AMOUNT,
                         INTERNAL_BANK_ACCOUNT_NUM,
                         INTERNAL_BANK_NAME,
                         EXTERNAL_BANK_ACCOUNT_NUM,
                         EXTERNAL_BANK_ACCOUNT_NAME,
                         EXTERNAL_BANK_NAME,
                         EXTERNAL_BANK_NUMBER,
                         EXTERNAL_EFT_SWIFT_CODE,
                         PAYMENT_PROFILE_SYS_NAME,
                         PAYMENT_PROFILE_ACCT_NAME,
                         PAYEE_NAME,
                         INT_BANK_NUMBER,
                         INT_EFT_SWIFT_CODE,
                         CHECK_ID,
                         PAYMENT_INSTRUCTION_ID,
                         PAYMENT_CURRENCY_CODE)
        LOOP
            /*BMRI Host to Host*/
            IF UPPER (R_PAY_INSTRUCTIONS.INTERNAL_BANK_NAME) = 'BANK MANDIRI'
            THEN
                SELECT    NULL
                       || TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
                       || TO_CHAR (
                              SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1))    PARTNER_REF
                  INTO L_BMRI_PARTNER_REF
                  FROM DUAL;

                /*BMRI Host to Host Internal Inquiry Account*/
                IF UPPER (R_PAY_INSTRUCTIONS.PAYMENT_PROFILE_ACCT_NAME) =
                   'INTRABANK'
                THEN
                    XXSKL_AP_HOST_TO_HOST_PKG.BMRI_ACCOUNT_INTERNAL_INQUIRY (
                        P_BENEFICIARY_ACCOUNT   =>
                            R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                        X_BENEFICIARY_NAME   => L_DO_INQ_BEN_NAME,
                        X_STATUS             => L_DO_INQ_STATUS,
                        X_ERROR_MSG          => L_DO_INQ_MSG);

                    --                    DBMS_OUTPUT.PUT_LINE (
                    --                        'L_DO_INQ_STATUS   => ' || L_DO_INQ_STATUS);
                    --                    DBMS_OUTPUT.PUT_LINE (
                    --                        'L_DO_INQ_BEN_NAME   => ' || L_DO_INQ_BEN_NAME);
                    --                    DBMS_OUTPUT.PUT_LINE (
                    --                           'R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME   => '
                    --                        || R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME);


                    IF     L_DO_INQ_STATUS = 'SUCCESS'
                       AND (L_DO_INQ_BEN_NAME <>
                           R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME OR 
                           L_DO_INQ_BEN_NAME IS NULL OR 
                           R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME IS NULL)
                    THEN
                        UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                           SET INQUIRY_BENEFICIARY_NAME = L_DO_INQ_BEN_NAME,
                               IFACE_STATUS = 'ERROR',
                               IFACE_MESSAGE =
                                   'Bank Account Name with Supplier Master Oracle not match'
                         WHERE     1 = 1
                               AND IFACE_STATUS = 'PROCESS'
                               AND PAYMENT_INSTRUCTION_ID =
                                   R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID
                               AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID;

                        COMMIT;
                    ELSIF     L_DO_INQ_STATUS = 'SUCCESS'
                          AND L_DO_INQ_BEN_NAME =
                              R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME
                    THEN
                        UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                           SET INQUIRY_BENEFICIARY_NAME = L_DO_INQ_BEN_NAME
                         WHERE     1 = 1
                               AND IFACE_STATUS = 'PROCESS'
                               AND PAYMENT_INSTRUCTION_ID =
                                   R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID
                               AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID;

                        COMMIT;

                        /*BMRI Host to Host Intrabank Transfer*/
                        XXSKL_AP_HOST_TO_HOST_PKG.BMRI_INTRABANK_TRANSFER (
                            P_AMOUNT                 => R_PAY_INSTRUCTIONS.PAYMENT_AMOUNT,
                            P_CURRENCY               =>
                                R_PAY_INSTRUCTIONS.PAYMENT_CURRENCY_CODE,
                            P_SOURCE_ACCOUNT_NO      =>
                                R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                            P_BENEFICIARY_ACCOUNT_NO   =>
                                R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                            P_REMARK                 =>
                                   'SKL_'
                                || R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                            P_TRANSACTION_DATE       =>
                                REPLACE (
                                       TO_CHAR (
                                           R_PAY_INSTRUCTIONS.PAYMENT_DATE,
                                           'yyyy-mm-dd hh24:mi:ss')
                                    || SESSIONTIMEZONE,
                                    ' ',
                                    'T'),
                            P_BENEFICIARY_EMAIL      => NULL,
                            P_ORIGINATOR_CUSTOMER_NO   =>
                                R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                            P_ORIGINATOR_CUSTOMER_NAME   =>
                                R_PAY_INSTRUCTIONS.INTERNAL_BANK_NAME,
                            P_ORIGINATOR_BANK_CODE   =>
                                R_PAY_INSTRUCTIONS.INT_BANK_NUMBER,
                            P_REPORT_CODE            => NULL,
                            P_SENDER_INSTRUMENT      => NULL,
                            P_SENDER_ACCOUNT_NO      => NULL,
                            P_SENDER_COUNTRY         => NULL,
                            P_SENDER_CUSTOMER_TYPE   => NULL,
                            P_BEN_ACCOUNT_NAME       => NULL,
                            P_BEN_INSTRUMENT         => NULL,
                            P_BEN_CUSTOMER_TYPE      => NULL,
                            P_PARTNER_REFERENCE      => L_BMRI_PARTNER_REF,
                            P_PAYMENT_REFERENCE      =>
                                R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                            P_CHECK_ID               =>
                                R_PAY_INSTRUCTIONS.CHECK_ID,
                            P_PAYMENT_INSTRUCTION_ID   =>
                                R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID,
                            X_STATUS                 => L_DO_PAY_STATUS,
                            X_ERROR_MSG              => L_DO_PAY_MSG,
                            X_EXTERNAL_ID            => L_DO_PAY_EXTERNAL_ID,
                            X_PARTNER_REFERENCE      =>
                                L_DO_PAY_PARTNER_REFERENCE);
                    END IF;
                ELSE
                    /*BMRI Host to Host External Inquiry Account*/
                    IF UPPER (R_PAY_INSTRUCTIONS.PAYMENT_PROFILE_ACCT_NAME) =
                       'TRANSFER (BIFAST)'
                    THEN
                        XXSKL_AP_HOST_TO_HOST_PKG.BMRI_ACCOUNT_EXTERNAL_INQUIRY (
                            P_BENEFICIARY_ACCOUNT   =>
                                R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                            P_BENEFICARY_BANK_CODE   =>
                                R_PAY_INSTRUCTIONS.EXTERNAL_EFT_SWIFT_CODE,
                            P_SWITCHER           => 'BIFAST',
                            P_INQUIRY_TYPE       => '1',
                            P_CATEGORY_PURPOSE   => '99',
                            P_DEBTOR_ACCOUNT     => NULL,
                            P_LOOKUP_TYPE        => NULL,
                            P_ALIAS_TYPE         => NULL,
                            P_ALIAS_VALUE        => NULL,
                            X_BENEFICIARY_NAME   => L_DO_INQ_BEN_NAME,
                            X_STATUS             => L_DO_INQ_STATUS,
                            X_ERROR_MSG          => L_DO_INQ_MSG);
                    ELSE
                        XXSKL_AP_HOST_TO_HOST_PKG.BMRI_ACCOUNT_EXTERNAL_INQUIRY (
                            P_BENEFICIARY_ACCOUNT   =>
                                R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                            P_BENEFICARY_BANK_CODE   =>
                                R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NUMBER,
                            P_SWITCHER           => 'ATMB',
                            P_INQUIRY_TYPE       => NULL,
                            P_CATEGORY_PURPOSE   => NULL,
                            P_DEBTOR_ACCOUNT     => NULL,
                            P_LOOKUP_TYPE        => NULL,
                            P_ALIAS_TYPE         => NULL,
                            P_ALIAS_VALUE        => NULL,
                            X_BENEFICIARY_NAME   => L_DO_INQ_BEN_NAME,
                            X_STATUS             => L_DO_INQ_STATUS,
                            X_ERROR_MSG          => L_DO_INQ_MSG);
                    END IF;


                    IF     L_DO_INQ_STATUS = 'SUCCESS'
                       AND (L_DO_INQ_BEN_NAME <>
                           R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME OR 
                           L_DO_INQ_BEN_NAME IS NULL OR 
                           R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME IS NULL)
                    THEN
                        UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                           SET INQUIRY_BENEFICIARY_NAME = L_DO_INQ_BEN_NAME,
                               IFACE_STATUS = 'ERROR',
                               IFACE_MESSAGE =
                                   'Bank Account Name with Supplier Master Oracle not match'
                         WHERE     1 = 1
                               AND IFACE_STATUS = 'PROCESS'
                               AND PAYMENT_INSTRUCTION_ID =
                                   R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID
                               AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID;

                        COMMIT;
                    ELSIF     L_DO_INQ_STATUS = 'SUCCESS'
                          AND L_DO_INQ_BEN_NAME =
                              R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME
                    THEN
                        UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                           SET INQUIRY_BENEFICIARY_NAME = L_DO_INQ_BEN_NAME
                         WHERE     1 = 1
                               AND IFACE_STATUS = 'PROCESS'
                               AND PAYMENT_INSTRUCTION_ID =
                                   R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID
                               AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID;

                        COMMIT;

                        IF UPPER (
                               R_PAY_INSTRUCTIONS.PAYMENT_PROFILE_ACCT_NAME) =
                           'ONLINE'
                        THEN
                            /*BMRI Host to Host Interbank Transfer*/
                            XXSKL_AP_HOST_TO_HOST_PKG.BMRI_INTERBANK_TRANSFER (
                                P_SOURCE_ACCOUNT_NO          =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                                P_BENEFICIARY_ACCOUNT_NO     =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                                P_BEN_ACCOUNT_NAME           => L_DO_INQ_BEN_NAME,
                                P_BEN_BANK_CODE              =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NUMBER,
                                P_BEN_BANK_NAME              =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NAME,
                                P_TRANSACTION_DATE           =>
                                    REPLACE (
                                           TO_CHAR (
                                               R_PAY_INSTRUCTIONS.PAYMENT_DATE,
                                               'yyyy-mm-dd hh24:mi:ss')
                                        || SESSIONTIMEZONE,
                                        ' ',
                                        'T'),
                                P_BENEFICIARY_EMAIL          => NULL,
                                P_BENEFICIARY_ADDRESS        => NULL,
                                P_FEE_TYPE                   => 'OUR',
                                P_AMOUNT                     =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_AMOUNT,
                                P_CURRENCY                   =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_CURRENCY_CODE,
                                P_ORIGINATOR_CUSTOMER_NO     =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                                P_ORIGINATOR_CUSTOMER_NAME   =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_NAME,
                                P_ORIGINATOR_BANK_CODE       =>
                                    R_PAY_INSTRUCTIONS.INT_BANK_NUMBER,
                                P_SWITCHER                   => 'ATMB',
                                P_CATEGORY_PURPOSE           => NULL,
                                P_PAYMENT_DESCRIPTION        =>
                                       'SKL_'
                                    || R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_NATIONAL_IDENTITY_NUMBER   => NULL,
                                P_TRANSACTION_INDICATOR      => NULL,
                                P_ALIAS_RESOLUTION           => NULL,
                                P_ALIAS_TYPE                 => NULL,
                                P_ALIAS_VALUE                => NULL,
                                P_PARTNER_REFERENCE          =>
                                    L_BMRI_PARTNER_REF,
                                P_PAYMENT_REFERENCE          =>
                                    R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_CHECK_ID                   =>
                                    R_PAY_INSTRUCTIONS.CHECK_ID,
                                P_PAYMENT_INSTRUCTION_ID     =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID,
                                X_STATUS                     =>
                                    L_DO_PAY_STATUS,
                                X_ERROR_MSG                  => L_DO_PAY_MSG,
                                X_EXTERNAL_ID                =>
                                    L_DO_PAY_EXTERNAL_ID,
                                X_PARTNER_REFERENCE          =>
                                    L_DO_PAY_PARTNER_REFERENCE);
                        ELSIF UPPER (
                                  R_PAY_INSTRUCTIONS.PAYMENT_PROFILE_ACCT_NAME) =
                              'TRANSFER (BIFAST)'
                        THEN
                            /*BMRI Host to Host Interbank BIFAST Transfer*/
                            XXSKL_AP_HOST_TO_HOST_PKG.BMRI_INTERBANK_TRANSFER (
                                P_SOURCE_ACCOUNT_NO          =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                                P_BENEFICIARY_ACCOUNT_NO     =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                                P_BEN_ACCOUNT_NAME           => L_DO_INQ_BEN_NAME,
                                P_BEN_BANK_CODE              =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NUMBER,
                                P_BEN_BANK_NAME              =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NAME,
                                P_TRANSACTION_DATE           =>
                                    REPLACE (
                                           TO_CHAR (
                                               R_PAY_INSTRUCTIONS.PAYMENT_DATE,
                                               'yyyy-mm-dd hh24:mi:ss')
                                        || SESSIONTIMEZONE,
                                        ' ',
                                        'T'),
                                P_BENEFICIARY_EMAIL          => NULL,
                                P_BENEFICIARY_ADDRESS        => NULL,
                                P_FEE_TYPE                   => 'OUR',
                                P_AMOUNT                     =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_AMOUNT,
                                P_CURRENCY                   =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_CURRENCY_CODE,
                                P_ORIGINATOR_CUSTOMER_NO     =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                                P_ORIGINATOR_CUSTOMER_NAME   =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_NAME,
                                P_ORIGINATOR_BANK_CODE       =>
                                    R_PAY_INSTRUCTIONS.INT_BANK_NUMBER,
                                P_SWITCHER                   => 'BIFAST',
                                P_CATEGORY_PURPOSE           => '99',
                                P_PAYMENT_DESCRIPTION        =>
                                       'SKL_'
                                    || R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_NATIONAL_IDENTITY_NUMBER   => '-',
                                P_TRANSACTION_INDICATOR      => '1',
                                P_ALIAS_RESOLUTION           => NULL,
                                P_ALIAS_TYPE                 => NULL,
                                P_ALIAS_VALUE                => NULL,
                                P_PARTNER_REFERENCE          =>
                                    L_BMRI_PARTNER_REF,
                                P_PAYMENT_REFERENCE          =>
                                    R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_CHECK_ID                   =>
                                    R_PAY_INSTRUCTIONS.CHECK_ID,
                                P_PAYMENT_INSTRUCTION_ID     =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID,
                                X_STATUS                     =>
                                    L_DO_PAY_STATUS,
                                X_ERROR_MSG                  => L_DO_PAY_MSG,
                                X_EXTERNAL_ID                =>
                                    L_DO_PAY_EXTERNAL_ID,
                                X_PARTNER_REFERENCE          =>
                                    L_DO_PAY_PARTNER_REFERENCE);
                        ELSIF UPPER (
                                  R_PAY_INSTRUCTIONS.PAYMENT_PROFILE_ACCT_NAME) =
                              'SKNBI'
                        THEN
                            /*BMRI Host to Host Interbank SKN Transfer*/
                            XXSKL_AP_HOST_TO_HOST_PKG.BMRI_SKN_TRANSFER (
                                P_SOURCE_ACCOUNT_NO       =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                                P_BENEFICIARY_ACCOUNT_NO   =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                                P_BEN_ACCOUNT_NAME        => L_DO_INQ_BEN_NAME,
                                P_BEN_BANK_CODE           =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NUMBER,
                                P_BEN_BANK_NAME           =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NAME,
                                P_AMOUNT                  =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_AMOUNT,
                                P_CURRENCY                =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_CURRENCY_CODE,
                                P_TRANSACTION_DATE        =>
                                    REPLACE (
                                           TO_CHAR (
                                               R_PAY_INSTRUCTIONS.PAYMENT_DATE,
                                               'yyyy-mm-dd hh24:mi:ss')
                                        || SESSIONTIMEZONE,
                                        ' ',
                                        'T'),
                                P_FEE_TYPE                => 'OUR',
                                P_REMARK                  =>
                                       'SKL_'
                                    || R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_BEN_CUST_RESIDENCE      => '1',
                                P_BEN_CUST_TYPE           => '2',
                                P_SENDER_CUST_RESIDENCE   => NULL,
                                P_SENDER_CUST_TYPE        => NULL,
                                P_BENEFICIARY_EMAIL       => NULL,
                                P_ORIGINATOR_CUSTOMER_NO   =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                                P_ORIGINATOR_CUSTOMER_NAME   =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_NAME,
                                P_ORIGINATOR_BANK_CODE    =>
                                    R_PAY_INSTRUCTIONS.INT_BANK_NUMBER,
                                P_PARTNER_REFERENCE       =>
                                    L_BMRI_PARTNER_REF,
                                P_PAYMENT_REFERENCE       =>
                                    R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_CHECK_ID                =>
                                    R_PAY_INSTRUCTIONS.CHECK_ID,
                                P_PAYMENT_INSTRUCTION_ID   =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID,
                                X_STATUS                  => L_DO_PAY_STATUS,
                                X_ERROR_MSG               => L_DO_PAY_MSG,
                                X_EXTERNAL_ID             =>
                                    L_DO_PAY_EXTERNAL_ID,
                                X_PARTNER_REFERENCE       =>
                                    L_DO_PAY_PARTNER_REFERENCE);
                        ELSIF UPPER (
                                  R_PAY_INSTRUCTIONS.PAYMENT_PROFILE_ACCT_NAME) =
                              'RTGS'
                        THEN
                            /*BMRI Host to Host Interbank RTGS Transfer*/
                            XXSKL_AP_HOST_TO_HOST_PKG.BMRI_RTGS_TRANSFER (
                                P_SOURCE_ACCOUNT_NO       =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                                P_BENEFICIARY_ACCOUNT_NO   =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                                P_BEN_ACCOUNT_NAME        => L_DO_INQ_BEN_NAME,
                                P_BEN_BANK_CODE           =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NUMBER,
                                P_BEN_BANK_NAME           =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NAME,
                                P_AMOUNT                  =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_AMOUNT,
                                P_CURRENCY                =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_CURRENCY_CODE,
                                P_TRANSACTION_DATE        =>
                                    REPLACE (
                                           TO_CHAR (
                                               R_PAY_INSTRUCTIONS.PAYMENT_DATE,
                                               'yyyy-mm-dd hh24:mi:ss')
                                        || SESSIONTIMEZONE,
                                        ' ',
                                        'T'),
                                P_FEE_TYPE                => 'OUR',
                                P_REMARK                  =>
                                       'SKL_'
                                    || R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_BEN_CUST_RESIDENCE      => '1',
                                P_BEN_CUST_TYPE           => '2',
                                P_SENDER_CUST_RESIDENCE   => NULL,
                                P_SENDER_CUST_TYPE        => NULL,
                                P_BENEFICIARY_EMAIL       => NULL,
                                P_ORIGINATOR_CUSTOMER_NO   =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                                P_ORIGINATOR_CUSTOMER_NAME   =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_NAME,
                                P_ORIGINATOR_BANK_CODE    =>
                                    R_PAY_INSTRUCTIONS.INT_BANK_NUMBER,
                                P_PARTNER_REFERENCE       =>
                                    L_BMRI_PARTNER_REF,
                                P_PAYMENT_REFERENCE       =>
                                    R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_CHECK_ID                =>
                                    R_PAY_INSTRUCTIONS.CHECK_ID,
                                P_PAYMENT_INSTRUCTION_ID   =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID,
                                X_STATUS                  => L_DO_PAY_STATUS,
                                X_ERROR_MSG               => L_DO_PAY_MSG,
                                X_EXTERNAL_ID             =>
                                    L_DO_PAY_EXTERNAL_ID,
                                X_PARTNER_REFERENCE       =>
                                    L_DO_PAY_PARTNER_REFERENCE);
                        END IF;
                    END IF;
                END IF;
            /*PANIN Host to Host*/
            ELSIF UPPER (R_PAY_INSTRUCTIONS.INTERNAL_BANK_NAME) =
                  'BANK PAN INDONESIA'
            THEN
                L_PANIN_TRX_DATE :=
                       TO_CHAR (
                           TO_TIMESTAMP (R_PAY_INSTRUCTIONS.PAYMENT_DATE),
                           'rrrr-mm-dd')
                    || 'T'
                    || TO_CHAR (
                           TO_TIMESTAMP (R_PAY_INSTRUCTIONS.PAYMENT_DATE),
                           'hh24:mi:ss')
                    || '+07:00';
                    
                SELECT    'SKL'
                       || TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
                       || TO_CHAR (
                              SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1))    PARTNER_REF
                  INTO L_PANIN_PARTNER_REF
                  FROM DUAL;

                IF UPPER (R_PAY_INSTRUCTIONS.PAYMENT_PROFILE_ACCT_NAME) IN
                       ('INTRABANK')
                THEN
                    /*PANIN Host to Host Internal Inquiry Account*/
                    XXSKL_AP_HOST_TO_HOST_PKG.PANIN_TRANSFER_INQUIRY (
                        P_PARTNER_REFERENCE   =>
                            R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                        P_BENEFICIARY_ACCOUNT   =>
                            R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                        P_PAYMENT_REFERENCE   =>
                            R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                        P_CHECK_ID           => R_PAY_INSTRUCTIONS.CHECK_ID,
                        P_PAYMENT_INSTRUCTION_ID   =>
                            R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID,
                        X_STATUS             => L_DO_INQ_STATUS,
                        X_BENEFICIARY_NAME   => L_DO_INQ_BEN_NAME,
                        X_ERROR_MSG          => L_DO_INQ_MSG);

                    IF     L_DO_INQ_STATUS = 'SUCCESS'
                       AND (L_DO_INQ_BEN_NAME <>
                           R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME OR 
                           L_DO_INQ_BEN_NAME IS NULL OR 
                           R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME IS NULL)
                    THEN
                        UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                           SET INQUIRY_BENEFICIARY_NAME = L_DO_INQ_BEN_NAME,
                               IFACE_STATUS = 'ERROR',
                               IFACE_MESSAGE =
                                   'Bank Account Name with Supplier Master Oracle not match'
                         WHERE     1 = 1
                               AND IFACE_STATUS = 'PROCESS'
                               AND PAYMENT_INSTRUCTION_ID =
                                   R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID
                               AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID;

                        COMMIT;
                    ELSIF     L_DO_INQ_STATUS = 'SUCCESS'
                          AND L_DO_INQ_BEN_NAME =
                              R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME
                    THEN
                        UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                           SET INQUIRY_BENEFICIARY_NAME = L_DO_INQ_BEN_NAME
                         WHERE     1 = 1
                               AND IFACE_STATUS = 'PROCESS'
                               AND PAYMENT_INSTRUCTION_ID =
                                   R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID
                               AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID;

                        COMMIT;

                        /*ELSIF L_DO_INQ_STATUS = 'SUCCESS'
                        THEN
                            UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                               SET INQUIRY_BENEFICIARY_NAME = L_DO_INQ_BEN_NAME
                             WHERE     1 = 1
                                   AND IFACE_STATUS = 'PROCESS'
                                   AND PAYMENT_INSTRUCTION_ID =
                                       R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID
                                   AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID;

                            COMMIT;*/

                        /*PANIN Host to Host Internal Transfer*/
                        XXSKL_AP_HOST_TO_HOST_PKG.PANIN_INTRABANK_TRANSFER (
                            P_BENEFICIARY_ACCOUNT   =>  /*'885545454544454',*/
                                R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                            P_BENEFICIARY_EMAIL     => NULL,
                            P_AMOUNT                =>
                                R_PAY_INSTRUCTIONS.PAYMENT_AMOUNT,
                            P_CURRENCY              => 'IDR',
                            P_REMARK                =>
                                   'SKL_'
                                || R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                            P_SOURCE_ACCOUNT_NO     =>       /*'1001112211',*/
                                R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                            P_TRANSACTION_DATE      => L_PANIN_TRX_DATE,
                            P_ECONOMIC_ACTIVITY     => NULL,
                            --                                'Biaya Hidup Pihak Asing',
                            P_TRANSACTION_PURPOSE   => NULL,           --'01',
                            P_PARTNER_REFERENCE     =>
                                L_PANIN_PARTNER_REF, --R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                            P_PAYMENT_REFERENCE     =>
                                R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                            P_CHECK_ID              =>
                                R_PAY_INSTRUCTIONS.CHECK_ID,
                            P_PAYMENT_INSTRUCTION_ID   =>
                                R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID,
                            X_STATUS                => L_DO_PAY_STATUS,
                            X_ERROR_MSG             => L_DO_PAY_MSG,
                            X_EXTERNAL_ID           => L_DO_PAY_EXTERNAL_ID,
                            X_PARTNER_REFERENCE     =>
                                L_DO_PAY_PARTNER_REFERENCE);
                    END IF;
                ELSIF UPPER (R_PAY_INSTRUCTIONS.PAYMENT_PROFILE_ACCT_NAME) IN
                          ('ONLINE',
                           'TRANSFER (BIFAST)',
                           'RTGS',
                           'SKNBI')
                THEN
                    /*PANIN Host to Host External Inquiry*/
                    XXSKL_AP_HOST_TO_HOST_PKG.PANIN_INTERBANK_TRANSFER_INQUIRY (
                        P_BENEFICIARY_BANK_CODE    =>
                            R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NUMBER, --'151',          --'014',
                        P_BENEFICIARY_ACCOUNT      =>
                            R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM, --'888801000157508',
                        P_PARTNER_REFERENCE        =>
                            L_PANIN_PARTNER_REF, --R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                        P_INQUIRY_SERVICE          => '44',             --'1',
                        P_PURPOSE_CODE             => '02',
                        P_PAYMENT_REFERENCE        =>
                            R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                        P_CHECK_ID                 => R_PAY_INSTRUCTIONS.CHECK_ID,
                        P_PAYMENT_INSTRUCTION_ID   =>
                            R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID,
                        X_BENEFICIARY_NAME         => L_DO_INQ_BEN_NAME,
                        X_STATUS                   => L_DO_INQ_STATUS,
                        X_ERROR_MSG                => L_DO_INQ_MSG);

                    IF     L_DO_INQ_STATUS = 'SUCCESS'
                       AND (L_DO_INQ_BEN_NAME <>
                           R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME OR 
                           L_DO_INQ_BEN_NAME IS NULL OR 
                           R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME IS NULL)
                    THEN
                        UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                           SET INQUIRY_BENEFICIARY_NAME = L_DO_INQ_BEN_NAME,
                               IFACE_STATUS = 'ERROR',
                               IFACE_MESSAGE =
                                   'Bank Account Name with Supplier Master Oracle not match'
                         WHERE     1 = 1
                               AND IFACE_STATUS = 'PROCESS'
                               AND PAYMENT_INSTRUCTION_ID =
                                   R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID
                               AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID;

                        COMMIT;
                    ELSIF     L_DO_INQ_STATUS = 'SUCCESS'
                          AND L_DO_INQ_BEN_NAME =
                              R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NAME
                    THEN
                        UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                           SET INQUIRY_BENEFICIARY_NAME = L_DO_INQ_BEN_NAME
                         WHERE     1 = 1
                               AND IFACE_STATUS = 'PROCESS'
                               AND PAYMENT_INSTRUCTION_ID =
                                   R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID
                               AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID;

                        COMMIT;

                        /*IF L_DO_INQ_STATUS = 'SUCCESS'
                        THEN
                            UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                               SET INQUIRY_BENEFICIARY_NAME = L_DO_INQ_BEN_NAME
                             WHERE     1 = 1
                                   AND IFACE_STATUS = 'PROCESS'
                                   AND PAYMENT_INSTRUCTION_ID =
                                       R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID
                                   AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID;

                            COMMIT;*/

                        IF UPPER (
                               R_PAY_INSTRUCTIONS.PAYMENT_PROFILE_ACCT_NAME) IN
                               ('ONLINE', 'TRANSFER')
                        THEN
                            /*PANIN Host to Host External Transfer*/
                            XXSKL_AP_HOST_TO_HOST_PKG.PANIN_INTERBANK_TRANSFER (
                                P_BENEFICIARY_ACCOUNT   =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM, --'888801000157508',
                                P_BENEFICIARY_BANK_CODE   =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NUMBER, --'151',   --'014',
                                P_INQUIRY_SERVICE   => '44',            --'1',
                                P_PURPOSE_CODE      => '02',
                                P_SOURCE_ACCOUNT    =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                                P_AMOUNT            =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_AMOUNT,
                                P_CURRENCY          => 'IDR',
                                P_PARTNER_REFERENCE   =>
                                    L_PANIN_PARTNER_REF, --R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_PAYMENT_REFERENCE   =>
                                    R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_CHECK_ID          =>
                                    R_PAY_INSTRUCTIONS.CHECK_ID,
                                P_PAYMENT_INSTRUCTION_ID   =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID,
                                X_STATUS            => L_DO_PAY_STATUS,
                                X_ERROR_MSG         => L_DO_PAY_MSG,
                                X_EXTERNAL_ID       => L_DO_PAY_EXTERNAL_ID,
                                X_PARTNER_REFERENCE   =>
                                    L_DO_PAY_PARTNER_REFERENCE);
                        ELSIF UPPER (
                                  R_PAY_INSTRUCTIONS.PAYMENT_PROFILE_ACCT_NAME) =
                              'SKNBI'
                        THEN
                            /*PANIN Host to Host SKN External Transfer*/
                            XXSKL_AP_HOST_TO_HOST_PKG.PANIN_SKN_INTERBANK_TRANSFER (
                                P_BENEFICIARY_ACCOUNT           =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                                P_BENEFICIARY_ACCOUNT_NAME      =>
                                    L_DO_INQ_BEN_NAME, --R_PAY_INSTRUCTIONS.PAYEE_NAME,
                                P_BENEFICIARY_ACCOUNT_ADDRESS   => NULL,
                                P_BENEFICIARY_BANK_CODE         => R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NUMBER,
                                P_BENEFICIARY_CUSTOMER_TYPE     => '1',
                                P_AMOUNT                        =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_AMOUNT,
                                P_CURRENCY                      => 'IDR',
                                P_REMARK                        =>
                                       'SKL_'
                                    || R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_SOURCE_ACCOUNT                =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                                P_TRANSACTION_DATE              =>
                                    L_PANIN_TRX_DATE,
                                P_PARTNER_REFERENCE             =>
                                    L_PANIN_PARTNER_REF, --R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_PAYMENT_REFERENCE             =>
                                    R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_CHECK_ID                      =>
                                    R_PAY_INSTRUCTIONS.CHECK_ID,
                                P_PAYMENT_INSTRUCTION_ID        =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID,
                                X_STATUS                        =>
                                    L_DO_PAY_STATUS,
                                X_ERROR_MSG                     =>
                                    L_DO_PAY_MSG,
                                X_EXTERNAL_ID                   =>
                                    L_DO_PAY_EXTERNAL_ID,
                                X_PARTNER_REFERENCE             =>
                                    L_DO_PAY_PARTNER_REFERENCE);
                        ELSIF UPPER (
                                  R_PAY_INSTRUCTIONS.PAYMENT_PROFILE_ACCT_NAME) =
                              'RTGS'
                        THEN
                            /*PANIN Host to Host RTGS External Transfer*/
                            XXSKL_AP_HOST_TO_HOST_PKG.PANIN_RTGS_INTERBANK_TRANSFER (
                                P_BENEFICIARY_ACCOUNT           =>
                                    R_PAY_INSTRUCTIONS.EXTERNAL_BANK_ACCOUNT_NUM,
                                P_BENEFICIARY_ACCOUNT_NAME      =>
                                    L_DO_INQ_BEN_NAME, --R_PAY_INSTRUCTIONS.PAYEE_NAME,
                                P_BENEFICIARY_ACCOUNT_ADDRESS   => NULL,
                                P_BENEFICIARY_BANK_CODE         => R_PAY_INSTRUCTIONS.EXTERNAL_BANK_NUMBER,
                                P_BENEFICIARY_CUSTOMER_TYPE     => '1',
                                P_AMOUNT                        =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_AMOUNT,
                                P_CURRENCY                      => 'IDR',
                                P_REMARK                        =>
                                       'SKL_'
                                    || R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_SOURCE_ACCOUNT                =>
                                    R_PAY_INSTRUCTIONS.INTERNAL_BANK_ACCOUNT_NUM,
                                P_TRANSACTION_DATE              =>
                                    L_PANIN_TRX_DATE,
                                P_PARTNER_REFERENCE             =>
                                    L_PANIN_PARTNER_REF, --R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_PAYMENT_REFERENCE             =>
                                    R_PAY_INSTRUCTIONS.PAPER_DOCUMENT_NUMBER,
                                P_CHECK_ID                      =>
                                    R_PAY_INSTRUCTIONS.CHECK_ID,
                                P_PAYMENT_INSTRUCTION_ID        =>
                                    R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID,
                                X_STATUS                        =>
                                    L_DO_PAY_STATUS,
                                X_ERROR_MSG                     =>
                                    L_DO_PAY_MSG,
                                X_EXTERNAL_ID                   =>
                                    L_DO_PAY_EXTERNAL_ID,
                                X_PARTNER_REFERENCE             =>
                                    L_DO_PAY_PARTNER_REFERENCE);
                        END IF;
                    END IF;
                END IF;
            END IF;

            DBMS_OUTPUT.PUT_LINE ('L_DO_INQ_STATUS   => ' || L_DO_INQ_STATUS);
            DBMS_OUTPUT.PUT_LINE ('L_DO_PAY_STATUS   => ' || L_DO_PAY_STATUS);

            IF (L_DO_PAY_STATUS = 'SUCCESS' AND L_DO_INQ_STATUS = 'SUCCESS')
            THEN
                UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                   SET IFACE_STATUS = 'PAID',
                       IFACE_MESSAGE = NVL (L_DO_PAY_MSG, L_DO_INQ_MSG),
                       EXTERNAL_ID = L_DO_PAY_EXTERNAL_ID,
                       PARTNER_REFERENCE = L_DO_PAY_PARTNER_REFERENCE,
                       RELEASED_DATE = SYSDATE
                 WHERE     1 = 1
                       AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID
                       AND IFACE_STATUS = 'PROCESS'
                       AND PAYMENT_INSTRUCTION_ID =
                           R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID;

                R_STATUS := 'SUCCESS';
                
            ELSIF L_DO_PAY_STATUS = 'PENDING' THEN
            
                UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                   SET IFACE_STATUS = 'PENDING',
                      EXTERNAL_ID = L_DO_PAY_EXTERNAL_ID,
                       PARTNER_REFERENCE = L_DO_PAY_PARTNER_REFERENCE,
                       IFACE_MESSAGE =
                           NVL (IFACE_MESSAGE,
                                L_DO_PAY_MSG || CHR (13) || L_DO_INQ_MSG)
                 WHERE     1 = 1
                       AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID
                       AND IFACE_STATUS = 'PROCESS'
                       AND PAYMENT_INSTRUCTION_ID =
                           R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID;
                           
                R_STATUS := 'PENDING';
                R_ERROR_MSG := L_DO_PAY_MSG || CHR (13) || L_DO_INQ_MSG;
            ELSE
                UPDATE XXSKL_AP_PAYMENT_INSTRUCTIONS
                   SET IFACE_STATUS = 'ERROR',
                       IFACE_MESSAGE =
                           NVL (IFACE_MESSAGE,
                                L_DO_PAY_MSG || CHR (13) || L_DO_INQ_MSG)
                 WHERE     1 = 1
                       AND CHECK_ID = R_PAY_INSTRUCTIONS.CHECK_ID
                       AND IFACE_STATUS = 'PROCESS'
                       AND PAYMENT_INSTRUCTION_ID =
                           R_PAY_INSTRUCTIONS.PAYMENT_INSTRUCTION_ID;

                R_STATUS := 'ERROR';
                R_ERROR_MSG := L_DO_PAY_MSG || CHR (13) || L_DO_INQ_MSG;
            END IF;

            COMMIT;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            R_STATUS := 'ERROR';
            R_ERROR_MSG :=
                'Exception DO_PAYMENT_INSTRUCTIONS    = ' || SQLERRM;
    END DO_PAYMENT_INSTRUCTIONS;
END XXSKL_AP_PAYMENT_INSTRUCTIONS_PKG;
/