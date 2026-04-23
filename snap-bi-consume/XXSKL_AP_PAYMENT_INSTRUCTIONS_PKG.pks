CREATE OR REPLACE PACKAGE XXSKL.XXSKL_AP_PAYMENT_INSTRUCTIONS_PKG
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
        R_ERROR_MSG      OUT VARCHAR2);

    FUNCTION GENERATE_PAYMENT_INSTRUCTION_NUMBER
        RETURN VARCHAR;

    FUNCTION GET_STATUS_PAID (P_HEADER_ID IN NUMBER)
        RETURN VARCHAR2;

    FUNCTION GET_BANK_BALANCE (P_HEADER_ID IN NUMBER)
        RETURN NUMBER;

    FUNCTION GET_TOTAL_AMOUNT (P_HEADER_ID IN NUMBER)
        RETURN NUMBER;

    FUNCTION GET_TOTAL_PAID_AMOUNT (P_HEADER_ID IN NUMBER)
        RETURN NUMBER;

    PROCEDURE DO_PAYMENT_INSTRUCTIONS_HEADERS (P_HEADER_ID   IN     NUMBER,
                                               R_STATUS         OUT VARCHAR2,
                                               R_ERROR_MSG      OUT VARCHAR2);

    PROCEDURE DO_PAYMENT_INSTRUCTIONS (P_HEADER_ID   IN     NUMBER,
                                       P_CHECK_ID    IN     NUMBER,
                                       R_STATUS         OUT VARCHAR2,
                                       R_ERROR_MSG      OUT VARCHAR2);
END XXSKL_AP_PAYMENT_INSTRUCTIONS_PKG;
/
