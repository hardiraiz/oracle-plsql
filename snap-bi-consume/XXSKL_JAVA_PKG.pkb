/* Formatted on 7/25/2025 1:53:46 PM (QP5 v5.362) */
CREATE OR REPLACE PACKAGE BODY XXSKL.XXSKL_JAVA_PKG
AS
    FUNCTION BCA_SNAP_TOKEN (P_PRIVATE_KEY      IN VARCHAR2,
                             P_STRING_TO_SIGN   IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSnapTokenJava.sign(java.lang.String, java.lang.String) return java.lang.String' ;

    FUNCTION BCA_SNAP_TOKEN_64 (P_PRIVATE_KEY      IN VARCHAR2,
                                P_STRING_TO_SIGN   IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSnapTokenJava64.sign(java.lang.String, java.lang.String) return java.lang.String' ;

    FUNCTION BCA_SNAP_SIGNATURE (P_CLIENT_SECRET   IN VARCHAR2,
                                 P_HTTP_METHOD     IN VARCHAR2,
                                 P_URL_X           IN VARCHAR2,
                                 P_TOKEN           IN VARCHAR2,
                                 P_TIMESTAMP       IN VARCHAR2,
                                 P_REQUEST_BODY    IN VARCHAR2)
        RETURN VARCHAR2
    AS
        LANGUAGE JAVA
        NAME 'SKLSnapSignatureJava.sign(java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String) return java.lang.String' ;

    FUNCTION BCA_SNAP_SIGNATURE64 (P_CLIENT_SECRET   IN VARCHAR2,
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
END XXSKL_JAVA_PKG;
/