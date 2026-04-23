/* Formatted on 7/25/2025 1:57:30 PM (QP5 v5.362) */
CREATE OR REPLACE PACKAGE XXSKL.XXSKL_JAVA_PKG
AS
    FUNCTION BCA_SNAP_TOKEN (P_PRIVATE_KEY      IN VARCHAR2,
                             P_STRING_TO_SIGN   IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION BCA_SNAP_TOKEN_64 (P_PRIVATE_KEY      IN VARCHAR2,
                                P_STRING_TO_SIGN   IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION BCA_SNAP_SIGNATURE (P_CLIENT_SECRET   IN VARCHAR2,
                                 P_HTTP_METHOD     IN VARCHAR2,
                                 P_URL_X           IN VARCHAR2,
                                 P_TOKEN           IN VARCHAR2,
                                 P_TIMESTAMP       IN VARCHAR2,
                                 P_REQUEST_BODY    IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION BCA_SNAP_SIGNATURE64 (P_CLIENT_SECRET   IN VARCHAR2,
                                   P_HTTP_METHOD     IN VARCHAR2,
                                   P_URL_X           IN VARCHAR2,
                                   P_TOKEN           IN VARCHAR2,
                                   P_TIMESTAMP       IN VARCHAR2,
                                   P_REQUEST_BODY    IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION HASH256 (P_INPUT IN VARCHAR2)
        RETURN VARCHAR2;
END XXSKL_JAVA_PKG;
/