/* Formatted on 10/8/2025 1:22:43 PM (QP5 v5.362) */
CREATE TABLE XXSKL_AP_HOST_TO_HOST_LOG
(
    LOG_ID                    VARCHAR2 (300)
                                 DEFAULT TO_CHAR (CURRENT_TIMESTAMP, 'DDMMYYYYHH24MISSFF3'),
    BANK_NAME                 VARCHAR2 (300),
    URL                       VARCHAR2 (1000),
    ACCESS_TOKEN              VARCHAR2 (1000),
    CONTENT_TYPE              VARCHAR2 (1000),
    AUTHORIZATION             VARCHAR2 (1000),
    PARTNER_ID                VARCHAR2 (1000),
    TIME_STAMP                VARCHAR2 (1000),
    SIGNATURE                 VARCHAR2 (1000),
    EXTERNAL_ID               VARCHAR2 (1000),
    CHANNEL_ID                VARCHAR2 (1000),
    HEADER                    CLOB,
    REQUEST                   CLOB,
    RESPONSE                  CLOB,
    ATTRIBUTE_CATEGORY        VARCHAR2 (150),
    ATTRIBUTE1                VARCHAR2 (150),
    ATTRIBUTE2                VARCHAR2 (150),
    ATTRIBUTE3                VARCHAR2 (150),
    ATTRIBUTE4                VARCHAR2 (150),
    ATTRIBUTE5                VARCHAR2 (150),
    ATTRIBUTE6                VARCHAR2 (150),
    ATTRIBUTE7                VARCHAR2 (150),
    ATTRIBUTE8                VARCHAR2 (150),
    ATTRIBUTE9                VARCHAR2 (150),
    ATTRIBUTE10               VARCHAR2 (150),
    ATTRIBUTE11               VARCHAR2 (150),
    ATTRIBUTE12               VARCHAR2 (150),
    ATTRIBUTE13               VARCHAR2 (150),
    ATTRIBUTE14               VARCHAR2 (150),
    ATTRIBUTE15               VARCHAR2 (150),
    PARTNER_REFERENCE         VARCHAR2 (100),
    CUSTOMER_REFERENCE        VARCHAR2 (100),
    PAYMENT_REFERENCE         VARCHAR2 (100),
    CHECK_ID                  NUMBER,
    PAYMENT_INSTRUCTION_ID    NUMBER,
    IFACE_MODE                VARCHAR2 (30),
    IFACE_STATUS              VARCHAR2 (100),
    IFACE_MESSAGE             VARCHAR2 (4000),
    CREATED_BY                VARCHAR2 (100),
    CREATION_DATE             DATE DEFAULT SYSDATE,
    LAST_UPDATE_LOGIN         NUMBER,
    LAST_UPDATED_BY           VARCHAR2 (100),
    LAST_UPDATE_DATE          DATE DEFAULT SYSDATE
);

CREATE UNIQUE INDEX XXSKL_AP_HOST_TO_HOST_LOG_U1
    ON XXSKL_AP_HOST_TO_HOST_LOG (LOG_ID);

CREATE OR REPLACE EDITIONABLE TRIGGER XXSKL_AP_HOST_TO_HOST_LOG_TRG
    BEFORE INSERT OR UPDATE
    ON XXSKL_AP_HOST_TO_HOST_LOG
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
/******************************************************************************
   NAME:       XXSKL_AP_HOST_TO_HOST_LOG_TRG
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        07/04/2025   ANP              1. Created this trigger.
******************************************************************************/
BEGIN
    IF INSERTING
    THEN
        :NEW.CREATED_BY := NVL (V ('APP_USER'), USER);
        :NEW.CREATION_DATE := SYSDATE;
    ELSIF UPDATING
    THEN
        :NEW.LAST_UPDATED_BY := NVL (V ('APP_USER'), USER);
        :NEW.LAST_UPDATE_DATE := SYSDATE;
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        NULL;
END XXSKL_AP_HOST_TO_HOST_LOG_TRG;
/

ALTER TRIGGER XXSKL_AP_HOST_TO_HOST_LOG_TRG
    ENABLE;