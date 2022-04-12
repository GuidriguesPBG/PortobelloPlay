CREATE TABLE XXPB.TMP_PROJETADO_SALESFORCE
(
  DES_CD      VARCHAR2(10 BYTE),
  COD_ITEM    VARCHAR2(20 BYTE),
  LAST_UPDATE_DATE DATE,
  SHOP_P1     NUMBER,
  SHOP_P2     NUMBER,
  SHOP_P3     NUMBER,
  SHOP_P4     NUMBER,
  SHOP_P5     NUMBER,
  SHOP_P6     NUMBER,
  SHOP_P7     NUMBER,
  SHOP_P8     NUMBER,
  SHOP_P9     NUMBER,
  SHOP_P10    NUMBER,
  DES_CD_1    VARCHAR2(10 BYTE),
  COD_ITEM_1  VARCHAR2(20 BYTE),
  LAST_UPDATE_DATE_1 DATE,
  PTBL_P1     NUMBER,
  PTBL_P2     NUMBER,
  PTBL_P3     NUMBER,
  PTBL_P4     NUMBER,
  PTBL_P5     NUMBER,
  PTBL_P6     NUMBER,
  PTBL_P7     NUMBER,
  PTBL_P8     NUMBER,
  PTBL_P9     NUMBER,
  PTBL_P10    NUMBER
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


CREATE INDEX XXPB.IDX_ITEM_SALESFORCE ON XXPB.TMP_PROJETADO_SALESFORCE
(COD_ITEM)
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

GRANT ALTER, DELETE, INDEX, INSERT, SELECT, UPDATE, DEBUG, FLASHBACK ON XXPB.TMP_PROJETADO_SALESFORCE TO APPSR;

GRANT ALTER, DELETE, INDEX, INSERT, SELECT, UPDATE, DEBUG, FLASHBACK ON XXPB.TMP_PROJETADO_SALESFORCE TO APPS;