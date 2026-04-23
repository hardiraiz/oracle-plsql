/* Formatted on 10/13/2025 10:47:01 AM (QP5 v5.362) */
CREATE OR REPLACE PACKAGE XXSKL.XXSKL_FND_JAVA_PKG
AS
    FUNCTION SNAP_TOKEN (P_PRIVATE_KEY      IN VARCHAR2,
                         P_STRING_TO_SIGN   IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION SNAP_TOKEN_64 (P_PRIVATE_KEY      IN VARCHAR2,
                            P_STRING_TO_SIGN   IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION SNAP_SIGNATURE (P_CLIENT_SECRET   IN VARCHAR2,
                             P_HTTP_METHOD     IN VARCHAR2,
                             P_URL_X           IN VARCHAR2,
                             P_TOKEN           IN VARCHAR2,
                             P_TIMESTAMP       IN VARCHAR2,
                             P_REQUEST_BODY    IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION SNAP_SIGNATURE64 (P_CLIENT_SECRET   IN VARCHAR2,
                               P_HTTP_METHOD     IN VARCHAR2,
                               P_URL_X           IN VARCHAR2,
                               P_TOKEN           IN VARCHAR2,
                               P_TIMESTAMP       IN VARCHAR2,
                               P_REQUEST_BODY    IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION HASH256 (P_INPUT IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION HASH256_HMAC (P_INPUT IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION SNAP_SIGNATURE_SHA512HMAC (P_CLIENT_SECRET   IN VARCHAR2,
                                        P_HTTP_METHOD     IN VARCHAR2,
                                        P_URL_X           IN VARCHAR2,
                                        P_TOKEN           IN VARCHAR2,
                                        P_REQUEST_BODY    IN VARCHAR2,
                                        P_TIMESTAMP       IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION SNAP_SIGNATURE_SHA512HMAC_STC (P_CLIENT_SECRET   IN VARCHAR2,
                                            P_HTTP_METHOD     IN VARCHAR2,
                                            P_URL_X           IN VARCHAR2,
                                            P_TOKEN           IN VARCHAR2,
                                            P_REQUEST_BODY    IN VARCHAR2,
                                            P_TIMESTAMP       IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION SNAP_SIGNATURE_SHA512HMAC_PAN (P_CLIENT_SECRET   IN VARCHAR2,
                                            P_HTTP_METHOD     IN VARCHAR2,
                                            P_URL_X           IN VARCHAR2,
                                            P_TOKEN           IN VARCHAR2,
                                            P_REQUEST_BODY    IN VARCHAR2,
                                            P_TIMESTAMP       IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION HEX_ENCODE_256_REQUEST_BODY (P_REQUEST_BODY IN VARCHAR2)
        RETURN VARCHAR2;
END XXSKL_FND_JAVA_PKG;
/