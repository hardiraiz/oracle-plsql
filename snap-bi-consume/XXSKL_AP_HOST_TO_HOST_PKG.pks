/* Formatted on 10/10/2025 3:37:24 PM (QP5 v5.362) */
CREATE OR REPLACE PACKAGE XXSKL.XXSKL_AP_HOST_TO_HOST_PKG
AS
    FUNCTION PANIN_GET_ACCESS_TOKEN (P_TIMESTAMP IN VARCHAR2)
        RETURN VARCHAR2;

    PROCEDURE PANIN_TRANSFER_INQUIRY (
        P_PARTNER_REFERENCE        IN     VARCHAR2,
        P_BENEFICIARY_ACCOUNT      IN     VARCHAR2,
        P_PAYMENT_REFERENCE        IN     VARCHAR2,
        P_CHECK_ID                 IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID   IN     NUMBER,
        X_BENEFICIARY_NAME            OUT VARCHAR2,
        X_STATUS                      OUT VARCHAR2,
        X_ERROR_MSG                   OUT VARCHAR2);

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
        X_ERROR_MSG                   OUT VARCHAR2);

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
        X_PARTNER_REFERENCE           OUT VARCHAR2);


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
        X_PARTNER_REFERENCE           OUT VARCHAR2);

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
        X_PARTNER_REFERENCE                OUT VARCHAR2);

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
        X_PARTNER_REFERENCE                OUT VARCHAR2);

    FUNCTION BMRI_GET_ACCESS_TOKEN (P_TIMESTAMP IN VARCHAR2)
        RETURN VARCHAR2;

    PROCEDURE BMRI_ACCOUNT_INTERNAL_INQUIRY (
        P_BENEFICIARY_ACCOUNT   IN     VARCHAR2,
        X_BENEFICIARY_NAME         OUT VARCHAR2,
        X_STATUS                   OUT VARCHAR2,
        X_ERROR_MSG                OUT VARCHAR2);

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
        X_ERROR_MSG                 OUT VARCHAR2);

    PROCEDURE BMRI_ACCOUNT_BALANCE (P_BENEFICIARY_ACCOUNT   IN     VARCHAR2,
                                    X_AMOUNT                   OUT NUMBER,
                                    X_AVAILABLE_BALANCE        OUT NUMBER,
                                    X_LEDGER_BALANCE           OUT NUMBER,
                                    X_STATUS                   OUT VARCHAR2,
                                    X_ERROR_MSG                OUT VARCHAR2);

    PROCEDURE BMRI_TRANSACTION_INQUIRY (
        P_ORIG_EXTERNAL_ID         IN     VARCHAR2,
        P_ORIG_PARTNER_REFERENCE   IN     VARCHAR2,
        P_SERVICE_CODE             IN     VARCHAR2,
        P_PARTNER_REFERENCE        IN     VARCHAR2,
        P_PAYMENT_REFERENCE        IN     VARCHAR2,
        P_CHECK_ID                 IN     NUMBER,
        P_PAYMENT_INSTRUCTION_ID   IN     NUMBER,
        X_STATUS                      OUT VARCHAR2,
        X_ERROR_MSG                   OUT VARCHAR2);

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
        X_PARTNER_REFERENCE             OUT VARCHAR2);

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
        X_PARTNER_REFERENCE             OUT VARCHAR2);

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
        X_PARTNER_REFERENCE             OUT VARCHAR2);

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
        X_PARTNER_REFERENCE             OUT VARCHAR2);
END XXSKL_AP_HOST_TO_HOST_PKG;
/