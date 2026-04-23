/* Formatted on 10/13/2025 10:47:04 AM (QP5 v5.362) */
CREATE OR REPLACE PACKAGE BODY XXSKL.XXSKL_FND_JAVA_PKG
AS
    FUNCTION SNAP_TOKEN (P_PRIVATE_KEY      IN VARCHAR2,
                         P_STRING_TO_SIGN   IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSnapTokenJava.sign(java.lang.String, java.lang.String) return java.lang.String' ;

    FUNCTION SNAP_TOKEN_64 (P_PRIVATE_KEY      IN VARCHAR2,
                            P_STRING_TO_SIGN   IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSnapTokenJava64.sign(java.lang.String, java.lang.String) return java.lang.String' ;

    FUNCTION SNAP_SIGNATURE (P_CLIENT_SECRET   IN VARCHAR2,
                             P_HTTP_METHOD     IN VARCHAR2,
                             P_URL_X           IN VARCHAR2,
                             P_TOKEN           IN VARCHAR2,
                             P_TIMESTAMP       IN VARCHAR2,
                             P_REQUEST_BODY    IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSnapSignatureJava.sign(java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String) return java.lang.String' ;

    FUNCTION SNAP_SIGNATURE64 (P_CLIENT_SECRET   IN VARCHAR2,
                               P_HTTP_METHOD     IN VARCHAR2,
                               P_URL_X           IN VARCHAR2,
                               P_TOKEN           IN VARCHAR2,
                               P_TIMESTAMP       IN VARCHAR2,
                               P_REQUEST_BODY    IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSnapSignatureJava64.sign(java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String) return java.lang.String' ;

    FUNCTION HASH256 (P_INPUT IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSnapSignatureJava.hash256(java.lang.String) return java.lang.String' ;


    FUNCTION HASH256_HMAC (P_INPUT IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSignSHA512HMACStripChar.hash256(java.lang.String) return java.lang.String' ;

    FUNCTION SNAP_SIGNATURE_SHA512HMAC (P_CLIENT_SECRET   IN VARCHAR2,
                                        P_HTTP_METHOD     IN VARCHAR2,
                                        P_URL_X           IN VARCHAR2,
                                        P_TOKEN           IN VARCHAR2,
                                        P_REQUEST_BODY    IN VARCHAR2,
                                        P_TIMESTAMP       IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSignSHA512HMAC.sign(java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String) return java.lang.String' ;

    FUNCTION SNAP_SIGNATURE_SHA512HMAC_STC (P_CLIENT_SECRET   IN VARCHAR2,
                                            P_HTTP_METHOD     IN VARCHAR2,
                                            P_URL_X           IN VARCHAR2,
                                            P_TOKEN           IN VARCHAR2,
                                            P_REQUEST_BODY    IN VARCHAR2,
                                            P_TIMESTAMP       IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSignSHA512HMACStripChar.sign(java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String) return java.lang.String' ;

    FUNCTION SNAP_SIGNATURE_SHA512HMAC_PAN (P_CLIENT_SECRET   IN VARCHAR2,
                                            P_HTTP_METHOD     IN VARCHAR2,
                                            P_URL_X           IN VARCHAR2,
                                            P_TOKEN           IN VARCHAR2,
                                            P_REQUEST_BODY    IN VARCHAR2,
                                            P_TIMESTAMP       IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSignSHA512HMACStripCharPan.sign(java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String) return java.lang.String' ;

    FUNCTION HEX_ENCODE_256_REQUEST_BODY (P_REQUEST_BODY IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLHexEncode256RequestBody.sign(java.lang.String) return java.lang.String' ;
END XXSKL_FND_JAVA_PKG;
/