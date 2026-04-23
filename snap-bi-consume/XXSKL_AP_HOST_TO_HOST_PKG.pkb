CREATE OR REPLACE PACKAGE BODY XXSKL.XXSKL_AP_HOST_TO_HOST_PKG
AS
    L_BANK_BMRI    VARCHAR2 (100) := 'BMRI';
    L_BANK_PANIN   VARCHAR2 (100) := 'PANIN';

    PROCEDURE IFACE_LOG (P_LOG      IN     XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE,
                         X_LOG_ID      OUT VARCHAR2,
                         X_STATUS      OUT VARCHAR2)
    IS
    BEGIN
        INSERT INTO XXSKL_AP_HOST_TO_HOST_LOG (BANK_NAME,
                                               URL,
                                               CONTENT_TYPE,
                                               AUTHORIZATION,
                                               PARTNER_ID,
                                               TIME_STAMP,
                                               SIGNATURE,
                                               EXTERNAL_ID,
                                               CHANNEL_ID,
                                               ACCESS_TOKEN,
                                               HEADER,
                                               REQUEST,
                                               RESPONSE,
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
                                               PARTNER_REFERENCE,
                                               CUSTOMER_REFERENCE,
                                               PAYMENT_REFERENCE,
                                               CHECK_ID,
                                               PAYMENT_INSTRUCTION_ID,
                                               IFACE_MODE,
                                               IFACE_STATUS,
                                               IFACE_MESSAGE,
                                               CREATED_BY,
                                               CREATION_DATE,
                                               LAST_UPDATE_LOGIN,
                                               LAST_UPDATED_BY,
                                               LAST_UPDATE_DATE)
             VALUES (P_LOG.BANK_NAME,
                     P_LOG.URL,
                     P_LOG.CONTENT_TYPE,
                     P_LOG.AUTHORIZATION,
                     P_LOG.PARTNER_ID,
                     P_LOG.TIME_STAMP,
                     P_LOG.SIGNATURE,
                     P_LOG.EXTERNAL_ID,
                     P_LOG.CHANNEL_ID,
                     P_LOG.ACCESS_TOKEN,
                     P_LOG.HEADER,
                     P_LOG.REQUEST,
                     P_LOG.RESPONSE,
                     P_LOG.ATTRIBUTE_CATEGORY,
                     P_LOG.ATTRIBUTE1,
                     P_LOG.ATTRIBUTE2,
                     P_LOG.ATTRIBUTE3,
                     P_LOG.ATTRIBUTE4,
                     P_LOG.ATTRIBUTE5,
                     P_LOG.ATTRIBUTE6,
                     P_LOG.ATTRIBUTE7,
                     P_LOG.ATTRIBUTE8,
                     P_LOG.ATTRIBUTE9,
                     P_LOG.ATTRIBUTE10,
                     P_LOG.ATTRIBUTE11,
                     P_LOG.ATTRIBUTE12,
                     P_LOG.ATTRIBUTE13,
                     P_LOG.ATTRIBUTE14,
                     P_LOG.ATTRIBUTE15,
                     P_LOG.PARTNER_REFERENCE,
                     P_LOG.CUSTOMER_REFERENCE,
                     P_LOG.PAYMENT_REFERENCE,
                     P_LOG.CHECK_ID,
                     P_LOG.PAYMENT_INSTRUCTION_ID,
                     P_LOG.IFACE_MODE,
                     P_LOG.IFACE_STATUS,
                     P_LOG.IFACE_MESSAGE,
                     P_LOG.CREATED_BY,
                     P_LOG.CREATION_DATE,
                     P_LOG.LAST_UPDATE_LOGIN,
                     P_LOG.LAST_UPDATED_BY,
                     P_LOG.LAST_UPDATE_DATE)
          RETURNING LOG_ID
               INTO X_LOG_ID;

        X_STATUS := 'SUCCESS';

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            X_LOG_ID := NULL;
            X_STATUS := 'ERROR';
    END IFACE_LOG;

    FUNCTION PANIN_GET_ACCESS_TOKEN (P_TIMESTAMP IN VARCHAR2)
        RETURN VARCHAR2
    AS
        L_TIMESTAMP          VARCHAR2 (200);
        L_EXTERNAL_ID        VARCHAR2 (100);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_HEADER             CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);
        L_CHANNEL_ID         VARCHAR2 (100);
        L_PARTNER_ID         VARCHAR2 (100);

        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        --        L_TIMESTAMP :=
        --               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
        --            || 'T'
        --            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_TIMESTAMP := P_TIMESTAMP;

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE1,
               WALLET_PATH,
               WALLET_PASSWORD,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_PANIN;

        L_CLEAN_KEY := REPLACE (L_PRIVATE_KEY, CHR (10), '');
        L_CLEAN_KEY := REPLACE (L_CLEAN_KEY, CHR (13), '');

        L_STRINGTOSIGN := L_CLIENT_ID || '|' || L_TIMESTAMP;

        --        DBMS_OUTPUT.PUT_LINE ('L_STRINGTOSIGN    => ' || L_STRINGTOSIGN);

        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_TOKEN_64 (
                P_PRIVATE_KEY      => L_CLEAN_KEY,
                P_STRING_TO_SIGN   => L_STRINGTOSIGN);

        --        DBMS_OUTPUT.PUT_LINE ('L_SIGNATURE    => ' || L_SIGNATURE);


        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'X-CLIENT-KEY';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := L_CLIENT_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_SIGNATURE;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_BODY := '{
    "grantType": "client_credentials"
}';

        --        DBMS_OUTPUT.PUT_LINE ('L_URL    => ' || L_URL);

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        --        DBMS_OUTPUT.PUT_LINE (
        --            'L_RESULT_CLOB    => ' || TO_CHAR (L_RESULT_CLOB));

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_TOKEN := APEX_JSON.GET_VARCHAR2 (P_PATH => 'accessToken');
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');


        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_PANIN;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '0000'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.HEADER := L_HEADER;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);

        RETURN L_TOKEN;
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_PANIN;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);
    END PANIN_GET_ACCESS_TOKEN;

    PROCEDURE PANIN_TRANSFER_INQUIRY (
        P_PARTNER_REFERENCE        IN     VARCHAR2,
        P_BENEFICIARY_ACCOUNT      IN     VARCHAR2,
        P_PAYMENT_REFERENCE        IN     VARCHAR2,
        P_CHECK_ID                 IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID   IN     NUMBER,
        X_BENEFICIARY_NAME            OUT VARCHAR2,
        X_STATUS                      OUT VARCHAR2,
        X_ERROR_MSG                   OUT VARCHAR2)
    IS
        L_TIMESTAMP          VARCHAR2 (200);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_HEADER             CLOB;
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_SECRET_KEY         VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);
        L_BEN_NAME           VARCHAR2 (4000);
        L_EXTERNAL_ID        VARCHAR2 (100);
        L_CHANNEL_ID         VARCHAR2 (100);
        L_PARTNER_ID         VARCHAR2 (100);


        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));

        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_TOKEN := PANIN_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE2,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_PANIN;

        L_BODY :=
               '{
    "partnerReferenceNo": "'
            || P_PARTNER_REFERENCE
            || '",
    "beneficiaryAccountNo": "'
            || P_BENEFICIARY_ACCOUNT
            || '"
}';
        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE_SHA512HMAC_PAN (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => REPLACE (L_PATH, 'paninsekar/', ''),
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_CLIENT_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');
        L_BEN_NAME :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'beneficiaryAccountName');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_PANIN;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '0000'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
            X_STATUS := 'SUCCESS';
            X_BENEFICIARY_NAME := L_BEN_NAME;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
        L_LOG.CHECK_ID := P_CHECK_ID;
        L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_PANIN;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
            L_LOG.CHECK_ID := P_CHECK_ID;
            L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END PANIN_TRANSFER_INQUIRY;

    PROCEDURE PANIN_INTERBANK_TRANSFER_INQUIRY (
        P_BENEFICIARY_BANK_CODE    IN     VARCHAR2,
        P_BENEFICIARY_ACCOUNT      IN     VARCHAR2,
        P_PARTNER_REFERENCE        IN     VARCHAR2,
        P_INQUIRY_SERVICE          IN     VARCHAR2,
        P_PURPOSE_CODE             IN     VARCHAR2,
        P_PAYMENT_REFERENCE        IN     VARCHAR2,
        P_CHECK_ID                 IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID   IN     NUMBER,
        X_BENEFICIARY_NAME            OUT VARCHAR2,
        X_STATUS                      OUT VARCHAR2,
        X_ERROR_MSG                   OUT VARCHAR2)
    IS
        L_TIMESTAMP          VARCHAR2 (200);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_HEADER             CLOB;
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_SECRET_KEY         VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);
        L_BEN_NAME           VARCHAR2 (4000);
        L_EXTERNAL_ID        VARCHAR2 (100);
        L_CHANNEL_ID         VARCHAR2 (100);
        L_PARTNER_ID         VARCHAR2 (100);


        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));

        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_TOKEN := PANIN_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE3,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_PANIN;

        L_BODY :=
               '{
    "beneficiaryBankCode": "'
            || P_BENEFICIARY_BANK_CODE
            || '",
    "beneficiaryAccountNo": "'
            || P_BENEFICIARY_ACCOUNT
            || '",
    "partnerReferenceNo": "'
            || P_PARTNER_REFERENCE
            || '",
    "additionalInfo": {
        "inquiryService": "'
            || P_INQUIRY_SERVICE
            || '"
    },
    "purposeCode": "'
            || P_PURPOSE_CODE
            || '"
}';
        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE_SHA512HMAC_PAN (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => REPLACE (L_PATH, 'paninsekar/', ''),
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_CLIENT_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');
        L_BEN_NAME :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'beneficiaryAccountName');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_PANIN;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '00'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
            X_STATUS := 'SUCCESS';
            X_BENEFICIARY_NAME := L_BEN_NAME;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
        L_LOG.CHECK_ID := P_CHECK_ID;
        L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_PANIN;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
            L_LOG.CHECK_ID := P_CHECK_ID;
            L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END PANIN_INTERBANK_TRANSFER_INQUIRY;

    PROCEDURE PANIN_INTRABANK_TRANSFER (
        P_BENEFICIARY_ACCOUNT      IN     VARCHAR2,
        P_BENEFICIARY_EMAIL        IN     VARCHAR2,
        P_AMOUNT                   IN     VARCHAR2,
        P_CURRENCY                 IN     VARCHAR2,
        P_REMARK                   IN     VARCHAR2,
        P_SOURCE_ACCOUNT_NO        IN     VARCHAR2,
        P_TRANSACTION_DATE         IN     VARCHAR2,
        P_ECONOMIC_ACTIVITY        IN     VARCHAR2,
        P_TRANSACTION_PURPOSE      IN     VARCHAR2,
        P_PARTNER_REFERENCE        IN     VARCHAR2,
        P_PAYMENT_REFERENCE        IN     VARCHAR2,
        P_CHECK_ID                 IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID   IN     NUMBER,
        X_STATUS                      OUT VARCHAR2,
        X_ERROR_MSG                   OUT VARCHAR2,
        X_EXTERNAL_ID                 OUT VARCHAR2,
        X_PARTNER_REFERENCE           OUT VARCHAR2)
    IS
        L_TIMESTAMP          VARCHAR2 (200);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_HEADER             CLOB;
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_SECRET_KEY         VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);
        L_EXTERNAL_ID        VARCHAR2 (100);
        L_CHANNEL_ID         VARCHAR2 (100);
        L_PARTNER_ID         VARCHAR2 (100);


        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));

        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_TOKEN := PANIN_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE4,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_PANIN;

        L_BODY :=
               '{
    "partnerReferenceNo": "'
            || P_PARTNER_REFERENCE
            || '",
    "amount": {
        "value": "'
            || P_AMOUNT
            || '",
        "currency": "'
            || P_CURRENCY
            || '"
    },
    "beneficiaryAccountNo": "'
            || P_BENEFICIARY_ACCOUNT
            || '",
    "beneficiaryEmail": "'
            || P_BENEFICIARY_EMAIL
            || '",
    "remark": "'
            || P_REMARK
            || '",
    "sourceAccountNo": "'
            || P_SOURCE_ACCOUNT_NO
            || '",
    "transactionDate": "'
            || P_TRANSACTION_DATE
            || '",
    "additionalInfo": {
        "economicActivity": "'
            || P_ECONOMIC_ACTIVITY
            || '",
        "transactionPurpose": "'
            || P_TRANSACTION_PURPOSE
            || '"
    }
}';
        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE_SHA512HMAC_PAN (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => REPLACE (L_PATH, 'paninsekar/', ''),
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_CLIENT_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_PANIN;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '0000'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
            X_STATUS := 'SUCCESS';
            X_EXTERNAL_ID := L_EXTERNAL_ID;
            X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
        L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
        L_LOG.CHECK_ID := P_CHECK_ID;
        L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_PANIN;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
            L_LOG.CHECK_ID := P_CHECK_ID;
            L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;


            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END PANIN_INTRABANK_TRANSFER;

    PROCEDURE PANIN_INTERBANK_TRANSFER (
        P_BENEFICIARY_ACCOUNT      IN     VARCHAR2,
        P_BENEFICIARY_BANK_CODE    IN     VARCHAR2,
        P_INQUIRY_SERVICE          IN     VARCHAR2,
        P_PURPOSE_CODE             IN     VARCHAR2,
        P_SOURCE_ACCOUNT           IN     VARCHAR2,
        P_AMOUNT                   IN     VARCHAR2,
        P_CURRENCY                 IN     VARCHAR2,
        P_PARTNER_REFERENCE        IN     VARCHAR2,
        P_PAYMENT_REFERENCE        IN     VARCHAR2,
        P_CHECK_ID                 IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID   IN     NUMBER,
        X_STATUS                      OUT VARCHAR2,
        X_ERROR_MSG                   OUT VARCHAR2,
        X_EXTERNAL_ID                 OUT VARCHAR2,
        X_PARTNER_REFERENCE           OUT VARCHAR2)
    IS
        L_TIMESTAMP          VARCHAR2 (200);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_EXTERNAL_ID        VARCHAR2 (100);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_HEADER             CLOB;
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_SECRET_KEY         VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);
        L_CHANNEL_ID         VARCHAR2 (100);
        L_PARTNER_ID         VARCHAR2 (100);


        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));

        L_TOKEN := PANIN_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE5,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_PANIN;

        L_BODY :=
               '{
    "partnerReferenceNo": "'
            || P_PARTNER_REFERENCE
            || '",
    "beneficiaryBankCode": "'
            || P_BENEFICIARY_BANK_CODE
            || '",
    "beneficiaryAccountNo": "'
            || P_BENEFICIARY_ACCOUNT
            || '",
    "additionalInfo": {
        "sourceAccountNo": "'
            || P_SOURCE_ACCOUNT
            || '",
        "inquiryService": "'
            || P_INQUIRY_SERVICE
            || '"
    },
    "amount": {
        "value": "'
            || P_AMOUNT
            || '",
        "currency": "'
            || P_CURRENCY
            || '"
    },
    "purposeCode": "'
            || P_PURPOSE_CODE
            || '"
}';
        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE_SHA512HMAC_PAN (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => REPLACE (L_PATH, 'paninsekar/', ''),
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_CLIENT_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID; --'sekar laut';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_PANIN;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';


        IF L_RESPONSE_CODE = '0000'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
            X_STATUS := 'SUCCESS';
            X_EXTERNAL_ID := L_EXTERNAL_ID;
            X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
        L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
        L_LOG.CHECK_ID := P_CHECK_ID;
        L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_PANIN;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
            L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
            L_LOG.CHECK_ID := P_CHECK_ID;
            L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END PANIN_INTERBANK_TRANSFER;

    PROCEDURE PANIN_SKN_INTERBANK_TRANSFER (
        P_BENEFICIARY_ACCOUNT           IN     VARCHAR2,
        P_BENEFICIARY_ACCOUNT_NAME      IN     VARCHAR2,
        P_BENEFICIARY_ACCOUNT_ADDRESS   IN     VARCHAR2,
        P_BENEFICIARY_BANK_CODE         IN     VARCHAR2,
        P_BENEFICIARY_CUSTOMER_TYPE     IN     VARCHAR2,
        P_AMOUNT                        IN     VARCHAR2,
        P_CURRENCY                      IN     VARCHAR2,
        P_REMARK                        IN     VARCHAR2,
        P_SOURCE_ACCOUNT                IN     VARCHAR2,
        P_TRANSACTION_DATE              IN     VARCHAR2,
        P_PARTNER_REFERENCE             IN     VARCHAR2,
        P_PAYMENT_REFERENCE             IN     VARCHAR2,
        P_CHECK_ID                      IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID        IN     NUMBER,
        X_STATUS                           OUT VARCHAR2,
        X_ERROR_MSG                        OUT VARCHAR2,
        X_EXTERNAL_ID                      OUT VARCHAR2,
        X_PARTNER_REFERENCE                OUT VARCHAR2)
    IS
        L_TIMESTAMP            VARCHAR2 (200);
        L_CLIENT_ID            VARCHAR2 (1000);
        L_EXTERNAL_ID          VARCHAR2 (100);
        L_PRIVATE_KEY          VARCHAR2 (4000);
        L_URL                  VARCHAR2 (4000);
        L_PATH                 VARCHAR2 (4000);
        L_WALLET_PATH          VARCHAR2 (4000);
        L_WALLET_PASSWORD      VARCHAR2 (4000);
        L_CLEAN_KEY            VARCHAR2 (4000);
        L_STRINGTOSIGN         VARCHAR2 (4000);
        L_SIGNATURE            VARCHAR2 (4000);
        L_HEADER               CLOB;
        L_BODY                 CLOB;
        L_RESULT_CLOB          CLOB;
        L_TOKEN                VARCHAR2 (4000);
        L_SECRET_KEY           VARCHAR2 (4000);
        L_RESPONSE_MESSAGE     VARCHAR2 (4000);
        L_RESPONSE_CODE        VARCHAR2 (4000);
        L_TRANSACTION_STATUS   VARCHAR2 (4000);
        L_CHANNEL_ID           VARCHAR2 (100);
        L_PARTNER_ID           VARCHAR2 (100);


        L_LOG                  XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID               VARCHAR2 (100);
        L_LOG_STATUS           VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));

        L_TOKEN := PANIN_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE6,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_PANIN;

        L_BODY :=
               '{
    "partnerReferenceNo": "'
            || P_PARTNER_REFERENCE
            || '",
    "amount": {
        "value": "'
            || P_AMOUNT
            || '",
        "currency": "'
            || P_CURRENCY
            || '"
    },
    "beneficiaryAccountName": "'
            || P_BENEFICIARY_ACCOUNT_NAME
            || '",
    "beneficiaryAccountNo": "'
            || P_BENEFICIARY_ACCOUNT
            || '",
    "beneficiaryAddress": "'
            || P_BENEFICIARY_ACCOUNT_ADDRESS
            || '",
    "beneficiaryBankCode": "'
            || P_BENEFICIARY_BANK_CODE
            || '",
    "beneficiaryCustomerType": "'
            || P_BENEFICIARY_CUSTOMER_TYPE
            || '",
    "remark": "'
            || P_REMARK
            || '",
    "sourceAccountNo": "'
            || P_SOURCE_ACCOUNT
            || '",
    "transactionDate": "'
            || P_TRANSACTION_DATE
            || '"
}';
        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE_SHA512HMAC_PAN (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => REPLACE (L_PATH, 'paninsekar/', ''),
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_CLIENT_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID; --'sekar laut';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');
        L_TRANSACTION_STATUS :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'transactionStatus');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_PANIN;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '0000'
        THEN
            IF L_TRANSACTION_STATUS = '00'
            THEN
                L_LOG.IFACE_STATUS := 'SUCCESS';
                X_STATUS := 'SUCCESS';
                X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
                X_EXTERNAL_ID := L_EXTERNAL_ID;
            ELSE
                L_LOG.IFACE_STATUS := 'PENDING';
                X_STATUS := 'PENDING';
                X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
                X_EXTERNAL_ID := L_EXTERNAL_ID;
            END IF;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
        L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
        L_LOG.CHECK_ID := P_CHECK_ID;
        L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;


        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_PANIN;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
            L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
            L_LOG.CHECK_ID := P_CHECK_ID;
            L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;


            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END PANIN_SKN_INTERBANK_TRANSFER;

    PROCEDURE PANIN_RTGS_INTERBANK_TRANSFER (
        P_BENEFICIARY_ACCOUNT           IN     VARCHAR2,
        P_BENEFICIARY_ACCOUNT_NAME      IN     VARCHAR2,
        P_BENEFICIARY_ACCOUNT_ADDRESS   IN     VARCHAR2,
        P_BENEFICIARY_BANK_CODE         IN     VARCHAR2,
        P_BENEFICIARY_CUSTOMER_TYPE     IN     VARCHAR2,
        P_AMOUNT                        IN     VARCHAR2,
        P_CURRENCY                      IN     VARCHAR2,
        P_REMARK                        IN     VARCHAR2,
        P_SOURCE_ACCOUNT                IN     VARCHAR2,
        P_TRANSACTION_DATE              IN     VARCHAR2,
        P_PARTNER_REFERENCE             IN     VARCHAR2,
        P_PAYMENT_REFERENCE             IN     VARCHAR2,
        P_CHECK_ID                      IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID        IN     NUMBER,
        X_STATUS                           OUT VARCHAR2,
        X_ERROR_MSG                        OUT VARCHAR2,
        X_EXTERNAL_ID                      OUT VARCHAR2,
        X_PARTNER_REFERENCE                OUT VARCHAR2)
    IS
        L_TIMESTAMP            VARCHAR2 (200);
        L_CLIENT_ID            VARCHAR2 (1000);
        L_EXTERNAL_ID          VARCHAR2 (100);
        L_PRIVATE_KEY          VARCHAR2 (4000);
        L_URL                  VARCHAR2 (4000);
        L_PATH                 VARCHAR2 (4000);
        L_WALLET_PATH          VARCHAR2 (4000);
        L_WALLET_PASSWORD      VARCHAR2 (4000);
        L_CLEAN_KEY            VARCHAR2 (4000);
        L_STRINGTOSIGN         VARCHAR2 (4000);
        L_SIGNATURE            VARCHAR2 (4000);
        L_HEADER               CLOB;
        L_BODY                 CLOB;
        L_RESULT_CLOB          CLOB;
        L_TOKEN                VARCHAR2 (4000);
        L_SECRET_KEY           VARCHAR2 (4000);
        L_RESPONSE_MESSAGE     VARCHAR2 (4000);
        L_RESPONSE_CODE        VARCHAR2 (4000);
        L_TRANSACTION_STATUS   VARCHAR2 (4000);
        L_CHANNEL_ID           VARCHAR2 (100);
        L_PARTNER_ID           VARCHAR2 (100);


        L_LOG                  XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID               VARCHAR2 (100);
        L_LOG_STATUS           VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));

        L_TOKEN := PANIN_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE7,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_PANIN;

        L_BODY :=
               '{
    "partnerReferenceNo": "'
            || P_PARTNER_REFERENCE
            || '",
    "amount": {
        "value": "'
            || P_AMOUNT
            || '",
        "currency": "'
            || P_CURRENCY
            || '"
    },
    "beneficiaryAccountName": "'
            || P_BENEFICIARY_ACCOUNT_NAME
            || '",
    "beneficiaryAccountNo": "'
            || P_BENEFICIARY_ACCOUNT
            || '",
    "beneficiaryAddress": "'
            || P_BENEFICIARY_ACCOUNT_ADDRESS
            || '",
    "beneficiaryBankCode": "'
            || P_BENEFICIARY_BANK_CODE
            || '",
    "beneficiaryCustomerType": "'
            || P_BENEFICIARY_CUSTOMER_TYPE
            || '",
    "remark": "'
            || P_REMARK
            || '",
    "sourceAccountNo": "'
            || P_SOURCE_ACCOUNT
            || '",
    "transactionDate": "'
            || P_TRANSACTION_DATE
            || '"
}';

        --        SELECT JSON_OBJECT (
        --                   KEY 'partnerReferenceNo' VALUE P_PARTNER_REFERENCE,
        --                   KEY 'amount' VALUE
        --                       JSON_OBJECT (KEY 'value' VALUE P_AMOUNT,
        --                                    KEY 'currency' VALUE P_CURRENCY
        --                                    ABSENT ON NULL
        --                                    RETURNING CLOB),
        --                   KEY 'beneficiaryAccountName' VALUE P_BENEFICIARY_ACCOUNT_NAME,
        --                   KEY 'beneficiaryAccountNo' VALUE P_BENEFICIARY_ACCOUNT,
        --                   KEY 'beneficiaryAddress' VALUE P_BENEFICIARY_ACCOUNT_ADDRESS,
        --                   KEY 'beneficiaryBankCode' VALUE P_BENEFICIARY_BANK_CODE,
        --                   KEY 'beneficiaryCustomerType' VALUE P_BENEFICIARY_CUSTOMER_TYPE,
        --                   KEY 'remark' VALUE P_REMARK,
        --                   KEY 'sourceAccountNo' VALUE P_SOURCE_ACCOUNT,
        --                   KEY 'transactionDate' VALUE P_TRANSACTION_DATE
        --                   ABSENT ON NULL
        --                   RETURNING CLOB)
        --          INTO L_BODY
        --          FROM DUAL;

        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE_SHA512HMAC_PAN (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => REPLACE (L_PATH, 'paninsekar/', ''),
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_CLIENT_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID; --'sekar laut';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');
        L_TRANSACTION_STATUS :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'transactionStatus');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_PANIN;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '0000'
        THEN
            IF L_TRANSACTION_STATUS = '00'
            THEN
                L_LOG.IFACE_STATUS := 'SUCCESS';
                X_STATUS := 'SUCCESS';
                X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
                X_EXTERNAL_ID := L_EXTERNAL_ID;
            ELSE
                L_LOG.IFACE_STATUS := 'PENDING';
                X_STATUS := 'PENDING';
                X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
                X_EXTERNAL_ID := L_EXTERNAL_ID;
            END IF;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
        L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
        L_LOG.CHECK_ID := P_CHECK_ID;
        L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;


        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_PANIN;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
            L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
            L_LOG.CHECK_ID := P_CHECK_ID;
            L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;


            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END PANIN_RTGS_INTERBANK_TRANSFER;

    FUNCTION BMRI_GET_ACCESS_TOKEN (P_TIMESTAMP IN VARCHAR2)
        RETURN VARCHAR2
    AS
        L_TIMESTAMP          VARCHAR2 (200);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_HEADER             CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);

        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP := P_TIMESTAMP;

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE1,
               WALLET_PATH,
               WALLET_PASSWORD
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_BMRI;

        L_CLEAN_KEY := REPLACE (L_PRIVATE_KEY, CHR (10), '');
        L_CLEAN_KEY := REPLACE (L_CLEAN_KEY, CHR (13), '');

        L_STRINGTOSIGN := L_CLIENT_ID || '|' || L_TIMESTAMP;

        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_TOKEN_64 (
                P_PRIVATE_KEY      => L_CLEAN_KEY,
                P_STRING_TO_SIGN   => L_STRINGTOSIGN);


        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'X-CLIENT-KEY';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := L_CLIENT_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_SIGNATURE;

        SELECT JSON_OBJECT (KEY 'grantType' VALUE 'client_credentials'
                            ABSENT ON NULL
                            RETURNING CLOB)
          INTO L_BODY
          FROM DUAL;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;


        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_TOKEN := APEX_JSON.GET_VARCHAR2 (P_PATH => 'accessToken');
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');


        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_BMRI;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '2007300'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.HEADER := L_HEADER;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);

        RETURN L_TOKEN;
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_BMRI;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);
    END BMRI_GET_ACCESS_TOKEN;

    PROCEDURE BMRI_ACCOUNT_INTERNAL_INQUIRY (
        P_BENEFICIARY_ACCOUNT   IN     VARCHAR2,
        X_BENEFICIARY_NAME         OUT VARCHAR2,
        X_STATUS                   OUT VARCHAR2,
        X_ERROR_MSG                OUT VARCHAR2)
    IS
        L_TIMESTAMP          VARCHAR2 (200);
        L_EXTERNAL_ID        VARCHAR2 (200);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_HEADER             CLOB;
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_SECRET_KEY         VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);
        L_BEN_NAME           VARCHAR2 (4000);
        L_CHANNEL_ID         VARCHAR2 (100);
        L_PARTNER_ID         VARCHAR2 (100);


        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));


        L_TOKEN := BMRI_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE4,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_BMRI;

        SELECT JSON_OBJECT (
                   KEY 'beneficiaryAccountNo' VALUE P_BENEFICIARY_ACCOUNT
                   ABSENT ON NULL
                   RETURNING CLOB)
          INTO L_BODY
          FROM DUAL;

        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE64 (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => '/' || L_PATH,
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_PARTNER_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');
        L_BEN_NAME :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'beneficiaryAccountName');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_BMRI;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '2001500'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
            X_STATUS := 'SUCCESS';
            X_BENEFICIARY_NAME := L_BEN_NAME;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_BMRI;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END BMRI_ACCOUNT_INTERNAL_INQUIRY;

    PROCEDURE BMRI_ACCOUNT_EXTERNAL_INQUIRY (
        P_BENEFICIARY_ACCOUNT    IN     VARCHAR2,
        P_BENEFICARY_BANK_CODE   IN     VARCHAR2,
        P_SWITCHER               IN     VARCHAR2,
        P_INQUIRY_TYPE           IN     VARCHAR2,
        P_CATEGORY_PURPOSE       IN     VARCHAR2,
        P_DEBTOR_ACCOUNT         IN     VARCHAR2,
        P_LOOKUP_TYPE            IN     VARCHAR2,
        P_ALIAS_TYPE             IN     VARCHAR2,
        P_ALIAS_VALUE            IN     VARCHAR2,
        X_BENEFICIARY_NAME          OUT VARCHAR2,
        X_STATUS                    OUT VARCHAR2,
        X_ERROR_MSG                 OUT VARCHAR2)
    IS
        L_TIMESTAMP          VARCHAR2 (200);
        L_EXTERNAL_ID        VARCHAR2 (200);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_HEADER             CLOB;
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_SECRET_KEY         VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);
        L_BEN_NAME           VARCHAR2 (4000);
        L_CHANNEL_ID         VARCHAR2 (100);
        L_PARTNER_ID         VARCHAR2 (100);


        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));


        L_TOKEN := BMRI_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE5,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_BMRI;

        SELECT JSON_OBJECT (
                   KEY 'beneficiaryAccountNo' VALUE P_BENEFICIARY_ACCOUNT,
                   KEY 'beneficiaryBankCode' VALUE P_BENEFICARY_BANK_CODE,
                   KEY 'additionalInfo' VALUE
                       JSON_OBJECT (
                           KEY 'switcher' VALUE P_SWITCHER,
                           KEY 'inquiryType' VALUE P_INQUIRY_TYPE,
                           KEY 'categoryPurpose' VALUE P_CATEGORY_PURPOSE,
                           KEY 'lookUpType' VALUE P_LOOKUP_TYPE,
                           KEY 'aliasType' VALUE P_ALIAS_TYPE,
                           KEY 'aliasValue' VALUE P_ALIAS_VALUE
                           ABSENT ON NULL
                           RETURNING CLOB)
                   ABSENT ON NULL
                   RETURNING CLOB)
          INTO L_BODY
          FROM DUAL;

        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE64 (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => '/' || L_PATH,
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_PARTNER_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');
        L_BEN_NAME :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'beneficiaryAccountName');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_BMRI;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '2001600'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
            X_STATUS := 'SUCCESS';
            X_BENEFICIARY_NAME := L_BEN_NAME;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_BMRI;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END BMRI_ACCOUNT_EXTERNAL_INQUIRY;


    PROCEDURE BMRI_ACCOUNT_BALANCE (P_BENEFICIARY_ACCOUNT   IN     VARCHAR2,
                                    X_AMOUNT                   OUT NUMBER,
                                    X_AVAILABLE_BALANCE        OUT NUMBER,
                                    X_LEDGER_BALANCE           OUT NUMBER,
                                    X_STATUS                   OUT VARCHAR2,
                                    X_ERROR_MSG                OUT VARCHAR2)
    IS
        L_TIMESTAMP          VARCHAR2 (200);
        L_EXTERNAL_ID        VARCHAR2 (200);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_HEADER             CLOB;
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_SECRET_KEY         VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);
        L_BEN_NAME           VARCHAR2 (4000);
        L_AMOUNT             NUMBER;
        L_AVAIL_AMOUNT       NUMBER;
        L_LEDGER_AMOUNT      NUMBER;
        L_CHANNEL_ID         VARCHAR2 (100);
        L_PARTNER_ID         VARCHAR2 (100);


        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));


        L_TOKEN := BMRI_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE2,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_BMRI;

        --        L_BODY := '{
        -- "accountNo": "' || P_BENEFICIARY_ACCOUNT || '"
        -- }';

        SELECT JSON_OBJECT (KEY 'accountNo' VALUE P_BENEFICIARY_ACCOUNT
                            ABSENT ON NULL
                            RETURNING CLOB)
          INTO L_BODY
          FROM DUAL;


        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE64 (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => '/' || L_PATH,
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_PARTNER_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');
        L_AMOUNT :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'accountInfos[1].amount.value');
        L_AVAIL_AMOUNT :=
            APEX_JSON.GET_VARCHAR2 (
                P_PATH   => 'accountInfos[1].availableBalance.value');
        L_LEDGER_AMOUNT :=
            APEX_JSON.GET_VARCHAR2 (
                P_PATH   => 'accountInfos[1].ledgerBalance.value');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_BMRI;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '2001100'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
            X_STATUS := 'SUCCESS';
            X_AMOUNT := L_AMOUNT;
            X_AVAILABLE_BALANCE := L_AVAIL_AMOUNT;
            X_LEDGER_BALANCE := L_LEDGER_AMOUNT;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_BMRI;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END BMRI_ACCOUNT_BALANCE;

    PROCEDURE BMRI_TRANSACTION_INQUIRY (
        P_ORIG_EXTERNAL_ID         IN     VARCHAR2,
        P_ORIG_PARTNER_REFERENCE   IN     VARCHAR2,
        P_SERVICE_CODE             IN     VARCHAR2,
        P_PARTNER_REFERENCE        IN     VARCHAR2,
        P_PAYMENT_REFERENCE        IN     VARCHAR2,
        P_CHECK_ID                 IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID   IN     NUMBER,
        X_STATUS                      OUT VARCHAR2,
        X_ERROR_MSG                   OUT VARCHAR2)
    IS
        L_TIMESTAMP          VARCHAR2 (200);
        L_EXTERNAL_ID        VARCHAR2 (200);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_HEADER             CLOB;
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_SECRET_KEY         VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);
        L_BEN_NAME           VARCHAR2 (4000);
        L_CHANNEL_ID         VARCHAR2 (100);
        L_PARTNER_ID         VARCHAR2 (100);


        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));


        L_TOKEN := BMRI_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE10,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_BMRI;

        --        L_BODY :=
        --               '{
        --"originalExternalId": "'
        --            || P_ORIG_EXTERNAL_ID
        --            || '",
        --"originalPartnerReferenceNo ":"'
        --            || P_ORIG_PARTNER_REFERENCE
        --            || '",
        --"serviceCode ":"'
        --            || P_SERVICE_CODE
        --            || '"
        --}';

        SELECT JSON_OBJECT (
                   KEY 'originalExternalID' VALUE P_ORIG_EXTERNAL_ID,
                   KEY 'originalPartnerReferenceNo' VALUE
                       P_ORIG_PARTNER_REFERENCE,
                   KEY 'serviceCode' VALUE P_SERVICE_CODE
                   ABSENT ON NULL
                   RETURNING CLOB)
          INTO L_BODY
          FROM DUAL;

        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE64 (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => '/' || L_PATH,
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_PARTNER_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_BMRI;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '2003600'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
            X_STATUS := 'SUCCESS';
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
        L_LOG.CHECK_ID := P_CHECK_ID;
        L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_BMRI;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
            L_LOG.CHECK_ID := P_CHECK_ID;
            L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END BMRI_TRANSACTION_INQUIRY;

    PROCEDURE BMRI_INTRABANK_TRANSFER (
        P_AMOUNT                     IN     VARCHAR2,
        P_CURRENCY                   IN     VARCHAR2,
        P_SOURCE_ACCOUNT_NO          IN     VARCHAR2,
        P_BENEFICIARY_ACCOUNT_NO     IN     VARCHAR2,
        P_REMARK                     IN     VARCHAR2,
        P_TRANSACTION_DATE           IN     VARCHAR2,
        P_BENEFICIARY_EMAIL          IN     VARCHAR2,
        P_ORIGINATOR_CUSTOMER_NO     IN     VARCHAR2,
        P_ORIGINATOR_CUSTOMER_NAME   IN     VARCHAR2,
        P_ORIGINATOR_BANK_CODE       IN     VARCHAR2,
        P_REPORT_CODE                IN     VARCHAR2,
        P_SENDER_INSTRUMENT          IN     VARCHAR2,
        P_SENDER_ACCOUNT_NO          IN     VARCHAR2,
        P_SENDER_COUNTRY             IN     VARCHAR2,
        P_SENDER_CUSTOMER_TYPE       IN     VARCHAR2,
        P_BEN_ACCOUNT_NAME           IN     VARCHAR2,
        P_BEN_INSTRUMENT             IN     VARCHAR2,
        P_BEN_CUSTOMER_TYPE          IN     VARCHAR2,
        P_PARTNER_REFERENCE          IN     VARCHAR2,
        P_PAYMENT_REFERENCE          IN     VARCHAR2,
        P_CHECK_ID                   IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID     IN     NUMBER,
        X_STATUS                        OUT VARCHAR2,
        X_ERROR_MSG                     OUT VARCHAR2,
        X_EXTERNAL_ID                   OUT VARCHAR2,
        X_PARTNER_REFERENCE             OUT VARCHAR2)
    IS
        L_TIMESTAMP          VARCHAR2 (200);
        L_EXTERNAL_ID        VARCHAR2 (200);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_HEADER             CLOB;
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_SECRET_KEY         VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);
        L_BEN_NAME           VARCHAR2 (4000);
        L_CHANNEL_ID         VARCHAR2 (100);
        L_PARTNER_ID         VARCHAR2 (100);


        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));


        L_TOKEN := BMRI_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE6,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_BMRI;

        SELECT JSON_OBJECT (
                   KEY 'partnerReferenceNo' VALUE P_PARTNER_REFERENCE,
                   KEY 'amount' VALUE
                       JSON_OBJECT (KEY 'value' VALUE P_AMOUNT,
                                    KEY 'currency' VALUE P_CURRENCY
                                    ABSENT ON NULL
                                    RETURNING CLOB),
                   KEY 'sourceAccountNo' VALUE P_SOURCE_ACCOUNT_NO,
                   KEY 'beneficiaryAccountNo' VALUE P_BENEFICIARY_ACCOUNT_NO,
                   KEY 'remark' VALUE P_REMARK,
                   KEY 'transactionDate' VALUE P_TRANSACTION_DATE,
                   KEY 'beneficiaryEmail' VALUE P_BENEFICIARY_EMAIL
                   ABSENT ON NULL
                   RETURNING CLOB)
          INTO L_BODY
          FROM DUAL;



        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE64 (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => '/' || L_PATH,
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_PARTNER_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;


        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_BMRI;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '2001700'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
            X_STATUS := 'SUCCESS';
            X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
            X_EXTERNAL_ID := L_EXTERNAL_ID;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
        L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
        L_LOG.CHECK_ID := P_CHECK_ID;
        L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_BMRI;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
            L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
            L_LOG.CHECK_ID := P_CHECK_ID;
            L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END BMRI_INTRABANK_TRANSFER;

    PROCEDURE BMRI_INTERBANK_TRANSFER (
        P_SOURCE_ACCOUNT_NO          IN     VARCHAR2,
        P_BENEFICIARY_ACCOUNT_NO     IN     VARCHAR2,
        P_BEN_ACCOUNT_NAME           IN     VARCHAR2,
        P_BEN_BANK_CODE              IN     VARCHAR2,
        P_BEN_BANK_NAME              IN     VARCHAR2,
        P_TRANSACTION_DATE           IN     VARCHAR2,
        P_BENEFICIARY_EMAIL          IN     VARCHAR2,
        P_BENEFICIARY_ADDRESS        IN     VARCHAR2,
        P_FEE_TYPE                   IN     VARCHAR2,
        P_AMOUNT                     IN     VARCHAR2,
        P_CURRENCY                   IN     VARCHAR2,
        P_ORIGINATOR_CUSTOMER_NO     IN     VARCHAR2,
        P_ORIGINATOR_CUSTOMER_NAME   IN     VARCHAR2,
        P_ORIGINATOR_BANK_CODE       IN     VARCHAR2,
        P_SWITCHER                   IN     VARCHAR2,
        P_CATEGORY_PURPOSE           IN     VARCHAR2,
        P_PAYMENT_DESCRIPTION        IN     VARCHAR2,
        P_NATIONAL_IDENTITY_NUMBER   IN     VARCHAR2,
        P_TRANSACTION_INDICATOR      IN     VARCHAR2,
        P_ALIAS_RESOLUTION           IN     VARCHAR2,
        P_ALIAS_TYPE                 IN     VARCHAR2,
        P_ALIAS_VALUE                IN     VARCHAR2,
        P_PARTNER_REFERENCE          IN     VARCHAR2,
        P_PAYMENT_REFERENCE          IN     VARCHAR2,
        P_CHECK_ID                   IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID     IN     NUMBER,
        X_STATUS                        OUT VARCHAR2,
        X_ERROR_MSG                     OUT VARCHAR2,
        X_EXTERNAL_ID                   OUT VARCHAR2,
        X_PARTNER_REFERENCE             OUT VARCHAR2)
    IS
        L_TIMESTAMP          VARCHAR2 (200);
        L_EXTERNAL_ID        VARCHAR2 (200);
        L_CLIENT_ID          VARCHAR2 (1000);
        L_PRIVATE_KEY        VARCHAR2 (4000);
        L_URL                VARCHAR2 (4000);
        L_PATH               VARCHAR2 (4000);
        L_WALLET_PATH        VARCHAR2 (4000);
        L_WALLET_PASSWORD    VARCHAR2 (4000);
        L_CLEAN_KEY          VARCHAR2 (4000);
        L_STRINGTOSIGN       VARCHAR2 (4000);
        L_SIGNATURE          VARCHAR2 (4000);
        L_HEADER             CLOB;
        L_BODY               CLOB;
        L_RESULT_CLOB        CLOB;
        L_TOKEN              VARCHAR2 (4000);
        L_SECRET_KEY         VARCHAR2 (4000);
        L_RESPONSE_MESSAGE   VARCHAR2 (4000);
        L_RESPONSE_CODE      VARCHAR2 (4000);
        L_BEN_NAME           VARCHAR2 (4000);
        L_CHANNEL_ID         VARCHAR2 (100);
        L_PARTNER_ID         VARCHAR2 (100);


        L_LOG                XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID             VARCHAR2 (100);
        L_LOG_STATUS         VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));

        L_TOKEN := BMRI_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE7,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_BMRI;

        SELECT JSON_OBJECT (
                   KEY 'partnerReferenceNo' VALUE P_PARTNER_REFERENCE,
                   KEY 'amount' VALUE
                       JSON_OBJECT (KEY 'value' VALUE P_AMOUNT,
                                    KEY 'currency' VALUE P_CURRENCY
                                    ABSENT ON NULL
                                    RETURNING CLOB),
                   KEY 'sourceAccountNo' VALUE P_SOURCE_ACCOUNT_NO,
                   KEY 'beneficiaryAccountNo' VALUE P_BENEFICIARY_ACCOUNT_NO,
                   KEY 'beneficiaryAccountName' VALUE P_BEN_ACCOUNT_NAME,
                   KEY 'beneficiaryBankName' VALUE P_BEN_BANK_NAME,
                   KEY 'beneficiaryBankCode' VALUE P_BEN_BANK_CODE,
                   KEY 'feeType' VALUE P_FEE_TYPE,
                   KEY 'transactionDate' VALUE P_TRANSACTION_DATE,
                   KEY 'additionalInfo' VALUE
                       JSON_OBJECT (
                           KEY 'switcher' VALUE P_SWITCHER,
                           KEY 'categoryPurpose' VALUE P_CATEGORY_PURPOSE,
                           KEY 'paymentDescription' VALUE
                               P_PAYMENT_DESCRIPTION,
                           KEY 'nationalIdentityNumber' VALUE
                               P_NATIONAL_IDENTITY_NUMBER,
                           KEY 'transactionIndicator' VALUE
                               P_TRANSACTION_INDICATOR,
                           KEY 'aliasResolution' VALUE P_ALIAS_RESOLUTION,
                           KEY 'aliasType' VALUE P_ALIAS_TYPE,
                           KEY 'aliasValue' VALUE P_ALIAS_VALUE
                           ABSENT ON NULL
                           RETURNING CLOB)
                   ABSENT ON NULL
                   RETURNING CLOB)
          INTO L_BODY
          FROM DUAL;

        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE64 (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => '/' || L_PATH,
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_PARTNER_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;

        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_BMRI;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '2001800'
        THEN
            L_LOG.IFACE_STATUS := 'SUCCESS';
            X_STATUS := 'SUCCESS';
            X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
            X_EXTERNAL_ID := L_EXTERNAL_ID;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
        L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
        L_LOG.CHECK_ID := P_CHECK_ID;
        L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_BMRI;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
            L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
            L_LOG.CHECK_ID := P_CHECK_ID;
            L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END BMRI_INTERBANK_TRANSFER;

    PROCEDURE BMRI_SKN_TRANSFER (
        P_SOURCE_ACCOUNT_NO          IN     VARCHAR2,
        P_BENEFICIARY_ACCOUNT_NO     IN     VARCHAR2,
        P_BEN_ACCOUNT_NAME           IN     VARCHAR2,
        P_BEN_BANK_CODE              IN     VARCHAR2,
        P_BEN_BANK_NAME              IN     VARCHAR2,
        P_AMOUNT                     IN     VARCHAR2,
        P_CURRENCY                   IN     VARCHAR2,
        P_TRANSACTION_DATE           IN     VARCHAR2,
        P_FEE_TYPE                   IN     VARCHAR2,
        P_REMARK                     IN     VARCHAR2,
        P_BEN_CUST_RESIDENCE         IN     VARCHAR2,
        P_BEN_CUST_TYPE              IN     VARCHAR2,
        P_SENDER_CUST_RESIDENCE      IN     VARCHAR2,
        P_SENDER_CUST_TYPE           IN     VARCHAR2,
        P_BENEFICIARY_EMAIL          IN     VARCHAR2,
        P_ORIGINATOR_CUSTOMER_NO     IN     VARCHAR2,
        P_ORIGINATOR_CUSTOMER_NAME   IN     VARCHAR2,
        P_ORIGINATOR_BANK_CODE       IN     VARCHAR2,
        P_PARTNER_REFERENCE          IN     VARCHAR2,
        P_PAYMENT_REFERENCE          IN     VARCHAR2,
        P_CHECK_ID                   IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID     IN     NUMBER,
        X_STATUS                        OUT VARCHAR2,
        X_ERROR_MSG                     OUT VARCHAR2,
        X_EXTERNAL_ID                   OUT VARCHAR2,
        X_PARTNER_REFERENCE             OUT VARCHAR2)
    IS
        L_TIMESTAMP            VARCHAR2 (200);
        L_EXTERNAL_ID          VARCHAR2 (200);
        L_CLIENT_ID            VARCHAR2 (1000);
        L_PRIVATE_KEY          VARCHAR2 (4000);
        L_URL                  VARCHAR2 (4000);
        L_PATH                 VARCHAR2 (4000);
        L_WALLET_PATH          VARCHAR2 (4000);
        L_WALLET_PASSWORD      VARCHAR2 (4000);
        L_CLEAN_KEY            VARCHAR2 (4000);
        L_STRINGTOSIGN         VARCHAR2 (4000);
        L_SIGNATURE            VARCHAR2 (4000);
        L_HEADER               CLOB;
        L_BODY                 CLOB;
        L_RESULT_CLOB          CLOB;
        L_TOKEN                VARCHAR2 (4000);
        L_SECRET_KEY           VARCHAR2 (4000);
        L_RESPONSE_MESSAGE     VARCHAR2 (4000);
        L_RESPONSE_CODE        VARCHAR2 (4000);
        L_TRANSACTION_STATUS   VARCHAR2 (4000);
        L_BEN_NAME             VARCHAR2 (4000);
        L_CHANNEL_ID           VARCHAR2 (100);
        L_PARTNER_ID           VARCHAR2 (100);


        L_LOG                  XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID               VARCHAR2 (100);
        L_LOG_STATUS           VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));


        L_TOKEN := BMRI_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE9,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_BMRI;

        SELECT JSON_OBJECT (
                   KEY 'sourceAccountNo' VALUE P_SOURCE_ACCOUNT_NO,
                   KEY 'beneficiaryAccountNo' VALUE P_BENEFICIARY_ACCOUNT_NO,
                   KEY 'beneficiaryAccountName' VALUE P_BEN_ACCOUNT_NAME,
                   KEY 'beneficiaryBankCode' VALUE P_BEN_BANK_CODE,
                   KEY 'beneficiaryBankName' VALUE P_BEN_BANK_NAME,
                   KEY 'amount' VALUE
                       JSON_OBJECT (KEY 'value' VALUE P_AMOUNT,
                                    KEY 'currency' VALUE P_CURRENCY
                                    ABSENT ON NULL
                                    RETURNING CLOB),
                   KEY 'transactionDate' VALUE P_TRANSACTION_DATE,
                   KEY 'feeType' VALUE P_FEE_TYPE,
                   KEY 'remark' VALUE P_REMARK,
                   KEY 'partnerReferenceNo' VALUE P_PARTNER_REFERENCE,
                   KEY 'beneficiaryCustomerResidence' VALUE
                       P_BEN_CUST_RESIDENCE,
                   KEY 'beneficiaryCustomerType' VALUE P_BEN_CUST_TYPE,
                   KEY 'senderCustomerResidence' VALUE
                       P_SENDER_CUST_RESIDENCE,
                   KEY 'senderCustomerType' VALUE P_SENDER_CUST_TYPE,
                   KEY 'beneficiaryEmail' VALUE P_BENEFICIARY_EMAIL
                   ABSENT ON NULL
                   RETURNING CLOB)
          INTO L_BODY
          FROM DUAL;

        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE64 (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => '/' || L_PATH,
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_PARTNER_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;


        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');
        L_TRANSACTION_STATUS :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'transactionStatus');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_BMRI;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '2002300'
        THEN
            IF L_TRANSACTION_STATUS = '00'
            THEN
                L_LOG.IFACE_STATUS := 'SUCCESS';
                X_STATUS := 'SUCCESS';
                X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
                X_EXTERNAL_ID := L_EXTERNAL_ID;
            ELSE
                L_LOG.IFACE_STATUS := 'PENDING';
                X_STATUS := 'PENDING';
                X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
                X_EXTERNAL_ID := L_EXTERNAL_ID;
            END IF;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
        L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
        L_LOG.CHECK_ID := P_CHECK_ID;
        L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_BMRI;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
            L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
            L_LOG.CHECK_ID := P_CHECK_ID;
            L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END BMRI_SKN_TRANSFER;

    PROCEDURE BMRI_RTGS_TRANSFER (
        P_SOURCE_ACCOUNT_NO          IN     VARCHAR2,
        P_BENEFICIARY_ACCOUNT_NO     IN     VARCHAR2,
        P_BEN_ACCOUNT_NAME           IN     VARCHAR2,
        P_BEN_BANK_CODE              IN     VARCHAR2,
        P_BEN_BANK_NAME              IN     VARCHAR2,
        P_AMOUNT                     IN     VARCHAR2,
        P_CURRENCY                   IN     VARCHAR2,
        P_TRANSACTION_DATE           IN     VARCHAR2,
        P_FEE_TYPE                   IN     VARCHAR2,
        P_REMARK                     IN     VARCHAR2,
        P_BEN_CUST_RESIDENCE         IN     VARCHAR2,
        P_BEN_CUST_TYPE              IN     VARCHAR2,
        P_SENDER_CUST_RESIDENCE      IN     VARCHAR2,
        P_SENDER_CUST_TYPE           IN     VARCHAR2,
        P_BENEFICIARY_EMAIL          IN     VARCHAR2,
        P_ORIGINATOR_CUSTOMER_NO     IN     VARCHAR2,
        P_ORIGINATOR_CUSTOMER_NAME   IN     VARCHAR2,
        P_ORIGINATOR_BANK_CODE       IN     VARCHAR2,
        P_PARTNER_REFERENCE          IN     VARCHAR2,
        P_PAYMENT_REFERENCE          IN     VARCHAR2,
        P_CHECK_ID                   IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID     IN     NUMBER,
        X_STATUS                        OUT VARCHAR2,
        X_ERROR_MSG                     OUT VARCHAR2,
        X_EXTERNAL_ID                   OUT VARCHAR2,
        X_PARTNER_REFERENCE             OUT VARCHAR2)
    IS
        L_TIMESTAMP            VARCHAR2 (200);
        L_EXTERNAL_ID          VARCHAR2 (200);
        L_CLIENT_ID            VARCHAR2 (1000);
        L_PRIVATE_KEY          VARCHAR2 (4000);
        L_URL                  VARCHAR2 (4000);
        L_PATH                 VARCHAR2 (4000);
        L_WALLET_PATH          VARCHAR2 (4000);
        L_WALLET_PASSWORD      VARCHAR2 (4000);
        L_CLEAN_KEY            VARCHAR2 (4000);
        L_STRINGTOSIGN         VARCHAR2 (4000);
        L_SIGNATURE            VARCHAR2 (4000);
        L_HEADER               CLOB;
        L_BODY                 CLOB;
        L_RESULT_CLOB          CLOB;
        L_TOKEN                VARCHAR2 (4000);
        L_SECRET_KEY           VARCHAR2 (4000);
        L_RESPONSE_MESSAGE     VARCHAR2 (4000);
        L_RESPONSE_CODE        VARCHAR2 (4000);
        L_TRANSACTION_STATUS   VARCHAR2 (4000);
        L_BEN_NAME             VARCHAR2 (4000);
        L_CHANNEL_ID           VARCHAR2 (100);
        L_PARTNER_ID           VARCHAR2 (100);


        L_LOG                  XXSKL_AP_HOST_TO_HOST_LOG%ROWTYPE;
        L_LOG_ID               VARCHAR2 (100);
        L_LOG_STATUS           VARCHAR2 (100);
    BEGIN
        L_TIMESTAMP :=
               TO_CHAR (SYSTIMESTAMP, 'rrrr-mm-dd')
            || 'T'
            || TO_CHAR (SYSTIMESTAMP, 'hh24:mi:ssTZR');

        L_EXTERNAL_ID :=
               TO_CHAR (SYSTIMESTAMP, 'rrrrmmddhh24miss')
            || TO_CHAR (SUBSTR (TO_CHAR (SYSTIMESTAMP, 'FF3'), 1, 1));


        L_TOKEN := BMRI_GET_ACCESS_TOKEN (P_TIMESTAMP => L_TIMESTAMP);

        SELECT CLIENT_ID,
               PRIVATE_KEY,
               URL,
               ATTRIBUTE8,
               WALLET_PATH,
               WALLET_PASSWORD,
               SECRET_KEY,
               CHANNEL_ID,
               PARTNER_ID
          INTO L_CLIENT_ID,
               L_PRIVATE_KEY,
               L_URL,
               L_PATH,
               L_WALLET_PATH,
               L_WALLET_PASSWORD,
               L_SECRET_KEY,
               L_CHANNEL_ID,
               L_PARTNER_ID
          FROM XXSKL_FND_BANK_HOST_TO_HOST_CRED
         WHERE 1 = 1 AND BANK_NAME = L_BANK_BMRI;

        SELECT JSON_OBJECT (
                   KEY 'sourceAccountNo' VALUE P_SOURCE_ACCOUNT_NO,
                   KEY 'beneficiaryAccountNo' VALUE P_BENEFICIARY_ACCOUNT_NO,
                   KEY 'beneficiaryAccountName' VALUE P_BEN_ACCOUNT_NAME,
                   KEY 'beneficiaryBankCode' VALUE P_BEN_BANK_CODE,
                   KEY 'beneficiaryBankName' VALUE P_BEN_BANK_NAME,
                   KEY 'amount' VALUE
                       JSON_OBJECT (KEY 'value' VALUE P_AMOUNT,
                                    KEY 'currency' VALUE P_CURRENCY
                                    ABSENT ON NULL
                                    RETURNING CLOB),
                   KEY 'partnerReferenceNo' VALUE P_PARTNER_REFERENCE,
                   KEY 'transactionDate' VALUE P_TRANSACTION_DATE,
                   KEY 'feeType' VALUE P_FEE_TYPE,
                   KEY 'remark' VALUE P_REMARK,
                   KEY 'beneficiaryCustomerResidence' VALUE
                       P_BEN_CUST_RESIDENCE,
                   KEY 'beneficiaryCustomerType' VALUE P_BEN_CUST_TYPE,
                   KEY 'senderCustomerResidence' VALUE
                       P_SENDER_CUST_RESIDENCE,
                   KEY 'senderCustomerType' VALUE P_SENDER_CUST_TYPE,
                   KEY 'beneficiaryEmail' VALUE P_BENEFICIARY_EMAIL
                   ABSENT ON NULL
                   RETURNING CLOB)
          INTO L_BODY
          FROM DUAL;

        L_SIGNATURE :=
            XXSKL_FND_JAVA_PKG.SNAP_SIGNATURE64 (
                P_CLIENT_SECRET   => L_SECRET_KEY,
                P_HTTP_METHOD     => 'POST',
                P_URL_X           => '/' || L_PATH,
                P_TOKEN           => L_TOKEN,
                P_REQUEST_BODY    => L_BODY,
                P_TIMESTAMP       => L_TIMESTAMP);

        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;

        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'application/json';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE := 'Bearer ' || L_TOKEN;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).NAME := 'X-PARTNER-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE := L_PARTNER_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).NAME := 'X-TIMESTAMP';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE := L_TIMESTAMP;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).NAME := 'X-SIGNATURE';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE := L_SIGNATURE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).NAME := 'X-EXTERNAL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE := L_EXTERNAL_ID;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).NAME := 'CHANNEL-ID';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE := L_CHANNEL_ID;

        FOR I IN 1 .. APEX_WEB_SERVICE.G_REQUEST_HEADERS.COUNT
        LOOP
            L_HEADER :=
                   L_HEADER
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).NAME
                || ': '
                || APEX_WEB_SERVICE.G_REQUEST_HEADERS (I).VALUE
                || CHR (10);
        END LOOP;


        L_RESULT_CLOB :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => L_URL || '/' || L_PATH,
                P_HTTP_METHOD   => 'POST',
                P_WALLET_PATH   => L_WALLET_PATH,
                P_WALLET_PWD    => L_WALLET_PASSWORD,
                P_BODY          => L_BODY);

        APEX_JSON.PARSE (TO_CHAR (L_RESULT_CLOB));
        L_RESPONSE_MESSAGE :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseMessage');
        L_RESPONSE_CODE := APEX_JSON.GET_VARCHAR2 (P_PATH => 'responseCode');
        L_TRANSACTION_STATUS :=
            APEX_JSON.GET_VARCHAR2 (P_PATH => 'transactionStatus');

        L_LOG.URL := L_URL || '/' || L_PATH;
        L_LOG.BANK_NAME := L_BANK_BMRI;
        L_LOG.ACCESS_TOKEN := L_TOKEN;
        L_LOG.REQUEST := L_BODY;
        L_LOG.RESPONSE := L_RESULT_CLOB;
        L_LOG.IFACE_MODE := 'POST';

        IF L_RESPONSE_CODE = '2002200'
        THEN
            IF L_TRANSACTION_STATUS = '00'
            THEN
                L_LOG.IFACE_STATUS := 'SUCCESS';
                X_STATUS := 'SUCCESS';
                X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
                X_EXTERNAL_ID := L_EXTERNAL_ID;
            ELSE
                L_LOG.IFACE_STATUS := 'PENDING';
                X_STATUS := 'PENDING';
                X_PARTNER_REFERENCE := P_PARTNER_REFERENCE;
                X_EXTERNAL_ID := L_EXTERNAL_ID;
            END IF;
        ELSE
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MESSAGE := L_RESPONSE_MESSAGE;
            X_STATUS := 'ERROR';
            X_ERROR_MSG := L_RESPONSE_MESSAGE;
        END IF;

        L_LOG.CONTENT_TYPE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
        L_LOG.AUTHORIZATION := APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
        L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
        L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
        L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
        L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
        L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
        L_LOG.HEADER := L_HEADER;

        L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
        L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
        L_LOG.CHECK_ID := P_CHECK_ID;
        L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

        IFACE_LOG (P_LOG      => L_LOG,
                   X_LOG_ID   => L_LOG_ID,
                   X_STATUS   => L_LOG_STATUS);
    EXCEPTION
        WHEN OTHERS
        THEN
            L_LOG.URL := L_URL || '/' || L_PATH;
            L_LOG.BANK_NAME := L_BANK_BMRI;
            L_LOG.ACCESS_TOKEN := L_TOKEN;
            L_LOG.REQUEST := L_BODY;
            L_LOG.RESPONSE := L_RESULT_CLOB;
            L_LOG.IFACE_STATUS := 'ERROR';
            L_LOG.IFACE_MODE := 'POST';
            L_LOG.IFACE_MESSAGE := SQLERRM;

            L_LOG.CONTENT_TYPE :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE;
            L_LOG.AUTHORIZATION :=
                APEX_WEB_SERVICE.G_REQUEST_HEADERS (2).VALUE;
            L_LOG.PARTNER_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (3).VALUE;
            L_LOG.TIME_STAMP := APEX_WEB_SERVICE.G_REQUEST_HEADERS (4).VALUE;
            L_LOG.SIGNATURE := APEX_WEB_SERVICE.G_REQUEST_HEADERS (5).VALUE;
            L_LOG.EXTERNAL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (6).VALUE;
            L_LOG.CHANNEL_ID := APEX_WEB_SERVICE.G_REQUEST_HEADERS (7).VALUE;
            L_LOG.HEADER := L_HEADER;

            L_LOG.PAYMENT_REFERENCE := P_PAYMENT_REFERENCE;
            L_LOG.PARTNER_REFERENCE := P_PARTNER_REFERENCE;
            L_LOG.CHECK_ID := P_CHECK_ID;
            L_LOG.PAYMENT_INSTRUCTION_ID := P_PAYMENT_INSTRUCTION_ID;

            IFACE_LOG (P_LOG      => L_LOG,
                       X_LOG_ID   => L_LOG_ID,
                       X_STATUS   => L_LOG_STATUS);

            X_STATUS := 'ERROR';
            X_ERROR_MSG := SQLERRM;
    END BMRI_RTGS_TRANSFER;
END XXSKL_AP_HOST_TO_HOST_PKG;
/
