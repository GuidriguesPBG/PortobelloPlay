DROP TABLE APPS.XXPB_HIST_PO_CLIENT CASCADE CONSTRAINTS;

CREATE TABLE APPS.XXPB_HIST_PO_CLIENT
(
  CREATED_DATE        DATE,
  LAST_UPDATE_DATE    DATE,
  ACCOUNT_NUMBER      VARCHAR2(30 BYTE),
  CUST_ACCOUNT_ID     NUMBER(15),
  DEFAULT_PAYMENT     NUMBER(15),
  DESCR_PAYMENT       VARCHAR2(15 BYTE),
  LAST_HEADER_ID      NUMBER,
  LAST_ORDER          DATE,
  LAST_INVOICE        DATE,
  PURCHASE_FREQUENCY  VARCHAR2(20 BYTE),
  FIRST_ORDER         DATE,
  LAST_PAYMENT        DATE,
  PARTY_ID            NUMBER(15),
  QTD_OV              NUMBER,
  QTD_DAY             NUMBER,
  BRAND               VARCHAR2(20 BYTE),
  WAREHOUSE           VARCHAR2(10 BYTE),
  DESCR_WAREHOUSE     VARCHAR2(100 BYTE),
  STATUS              VARCHAR2(1 BYTE),
  PROCESSED           INTEGER,
  SALES_CHANNEL       VARCHAR2(5)
)
TABLESPACE APPS_TS_TX_DATA
RESULT_CACHE (MODE DEFAULT)
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


CREATE INDEX APPS.IDX_HIST_PO_CLIENT ON APPS.XXPB_HIST_PO_CLIENT
(PARTY_ID)
LOGGING
TABLESPACE APPS_TS_TX_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
NOPARALLEL;


CREATE INDEX APPS.IDX_SALESFORCE_PO_CLIENT_01 ON APPS.XXPB_HIST_PO_CLIENT
(ACCOUNT_NUMBER)
LOGGING
TABLESPACE APPS_TS_TX_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
NOPARALLEL;


CREATE INDEX APPS.XXPB_HIST_PO_CLIENT_IDX ON APPS.XXPB_HIST_PO_CLIENT
(LAST_UPDATE_DATE, PARTY_ID)
LOGGING
TABLESPACE APPS_TS_TX_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
NOPARALLEL;


CREATE OR REPLACE TRIGGER APPS.TRG_SALES_ATUALIZA_CLI
BEFORE UPDATE
ON APPS.XXPB_HIST_PO_CLIENT
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
WHEN (
NEW.STATUS <> OLD.STATUS
OR
NEW.PURCHASE_FREQUENCY <> OLD.PURCHASE_FREQUENCY
      )
DECLARE
tmpVar NUMBER;
/******************************************************************************
   NAME:       TRG_SALES_ATUALIZA_CLI
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        12/01/2022      guilherme.rodrigues       1. Created this trigger.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     TRG_SALES_ATUALIZA_CLI
      Sysdate:         12/01/2022
      Date and Time:   12/01/2022, 10:49:24, and 12/01/2022 10:49:24
      Username:        guilherme.rodrigues 
      Table Name:      XXPB_HIST_PO_CLIENT (set in the "New PL/SQL Object" dialog)
      Trigger Options:  (set in the "New PL/SQL Object" dialog)
******************************************************************************/
BEGIN
   :NEW.LAST_UPDATE_DATE := SYSDATE;

   EXCEPTION
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END TRG_SALES_ATUALIZA_CLI;
/
