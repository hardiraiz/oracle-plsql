/* Formatted on 9/4/2025 4:41:04 PM (QP5 v5.362) */
CREATE OR REPLACE PROCEDURE XXSKL_APX_AP_PAYMENT_INSTRUCTIONS_H2H_PRC (
    P_BANK_ACCOUNT_ID   IN     NUMBER,
    P_START_DATE        IN     VARCHAR2,
    P_END_DATE          IN     VARCHAR2,
    X_DATA                 OUT BLOB,
    X_STATUS               OUT VARCHAR2,
    X_ERR_MSG              OUT VARCHAR2)
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
            X_ERR_MSG := 'Register External Report not found.';
            X_STATUS := 'ERROR';
            RETURN;
    END;

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
        X_STATUS := 'ERROR';
        X_ERR_MSG := V_ERROR_MSG;
        RETURN;
    END IF;

    X_STATUS := 'SUCCESS';
    X_DATA := V_FILE_DATA;
EXCEPTION
    WHEN OTHERS
    THEN
        X_STATUS := 'ERROR';
        X_ERR_MSG :=
            'Error XXSKL_APX_AP_PAYMENT_INSTRUCTIONS_H2H_PRC = ' || SQLERRM;
END XXSKL_APX_AP_PAYMENT_INSTRUCTIONS_H2H_PRC;
/