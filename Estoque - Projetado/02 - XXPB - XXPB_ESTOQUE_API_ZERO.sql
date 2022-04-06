CREATE TABLE XXPB.XXPB_ESTOQUE_API_ZERO
(
  INVENTORY_ITEM_ID       NUMBER,
  COD_DEPOSITO            VARCHAR2(5 BYTE),
  COD_TONALIDADE_CALIBRE  VARCHAR2(20 BYTE),
  COD_PRODUTO_ORA         VARCHAR2(30 BYTE),
  LAST_UPDATE_DATE        DATE,
  FLAG_STK                INT,
  FLAG_EXC    			  INT     
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

create index XXPB.IDX_STK_ZERO_01 on XXPB.XXPB_ESTOQUE_API_ZERO("FLAG_STK");
create index XXPB.IDX_STK_ZERO_06 on XXPB.XXPB_ESTOQUE_API_ZERO("COD_PRODUTO_ORA","COD_DEPOSITO","COD_TONALIDADE_CALIBRE");
create index XXPB.IDX_STK_ZERO_07 on XXPB.XXPB_ESTOQUE_API_ZERO("COD_PRODUTO_ORA","COD_DEPOSITO");
create index XXPB.IDX_STK_ZERO_08 on XXPB.XXPB_ESTOQUE_API_ZERO("FLAG_STK","FLAG_EXC","COD_PRODUTO_ORA","COD_DEPOSITO");
create index XXPB.IDX_STK_ZERO_09 on XXPB.XXPB_ESTOQUE_API_ZERO("FLAG_STK","FLAG_EXC");
create index XXPB.IDX_STK_ZERO_10 on XXPB.XXPB_ESTOQUE_API_ZERO("FLAG_EXC");
create index XXPB.IDX_STK_ZERO_03 on XXPB.XXPB_ESTOQUE_API("COD_PRODUTO_ORA","SALDO_DISPONIVEL");
create index XXPB.IDX_STK_ZERO_04 on XXPB.XXPB_ESTOQUE_API("COD_PRODUTO_ORA","COD_DEPOSITO","SALDO_DISPONIVEL");
create index XXPB.IDX_STK_ZERO_05 on XXPB.XXPB_ESTOQUE_API("COD_PRODUTO_ORA","COD_DEPOSITO","SALDO_DISPONIVEL","COD_TONALIDADE_CALIBRE");
create index XXPB.IDX_STK_ZERO_11 on XXPB.XXPB_ESTOQUE_API("LAST_UPDATE_DATE");
create index XXPB.IDX_STK_ZERO_12 on XXPB.XXPB_ESTOQUE_API_ZERO("LAST_UPDATE_DATE");

execute dbms_stats.gather_table_stats(ownname => 'XXPB', tabname => 'XXPB_ESTOQUE_API_ZERO', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE AUTO');
execute dbms_stats.gather_table_stats(ownname => 'XXPB', tabname => 'XXPB_ESTOQUE_API', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE AUTO');
execute dbms_stats.gather_index_stats(ownname => 'XXPB', indname => 'IDX_STK_ZERO_08', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE);


CREATE OR REPLACE FORCE EDITIONING VIEW XXPB.XXPB_ESTOQUE_API_ZERO#
(
   INVENTORY_ITEM_ID,
   COD_DEPOSITO,
   COD_TONALIDADE_CALIBRE,
   COD_PRODUTO_ORA,
   LAST_UPDATE_DATE,
   FLAG_STK,
   FLAG_EXC 
)
AS
   SELECT INVENTORY_ITEM_ID INVENTORY_ITEM_ID,
          COD_DEPOSITO COD_DEPOSITO,
          COD_TONALIDADE_CALIBRE COD_TONALIDADE_CALIBRE,
          COD_PRODUTO_ORA COD_PRODUTO_ORA,
          LAST_UPDATE_DATE LAST_UPDATE_DATE,
		  FLAG_STK FLAG_STK,
		  FLAG_EXC FLAG_EXC
     FROM "XXPB"."XXPB_ESTOQUE_API_ZERO";