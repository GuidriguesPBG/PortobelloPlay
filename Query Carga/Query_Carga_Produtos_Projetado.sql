CREATE TABLE APPS.TMP_PROD_SALESFORCE
(
  ID_SALESFORCE    VARCHAR2(20 BYTE),
  COD_PRODUTO_ORA  VARCHAR2(50 BYTE)
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


CREATE UNIQUE INDEX APPS.IDX_DEPARA ON APPS.TMP_PROD_SALESFORCE
(ID_SALESFORCE)
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


DROP TABLE APPS.TMP_PROJETADO_SALESFORCE CASCADE CONSTRAINTS;
CREATE TABLE APPS.TMP_PROJETADO_SALESFORCE

(
  DES_CD      VARCHAR2(10 BYTE),
  COD_ITEM    VARCHAR2(20 BYTE),
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


CREATE INDEX APPS.IDX_ITEM_SALESFORCE ON APPS.TMP_PROJETADO_SALESFORCE
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

GRANT ALTER, DELETE, INDEX, INSERT, SELECT, UPDATE, DEBUG, FLASHBACK ON APPS.TMP_PROJETADO_SALESFORCE TO APPSR;

execute dbms_stats.gather_table_stats(ownname => 'APPS', tabname => 'TMP_PROD_SALESFORCE', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE AUTO');

execute dbms_stats.gather_table_stats(ownname => 'APPS', tabname => 'TMP_PROJETADO_SALESFORCE', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE AUTO');


DELETE TMP_PROJETADO_SALESFORCE

INSERT INTO TMP_PROJETADO_SALESFORCE (DES_CD, COD_ITEM, SHOP_P1,SHOP_P2,SHOP_P3,SHOP_P4,SHOP_P5,SHOP_P6,SHOP_P7,SHOP_P8,SHOP_P9,SHOP_P10,DES_CD_1, COD_ITEM_1, PTBL_P1, PTBL_P2, PTBL_P3, PTBL_P4, PTBL_P5, PTBL_P6, PTBL_P7, PTBL_P8, PTBL_P9, PTBL_P10)
SELECT PS.*, PB.*
FROM (
SELECT * FROM (
select ID_PERIODO AS ID_PERIODO, DES_CD, COD_ITEM, CASE WHEN SUM(SALDO_TOTAL) < 0 THEN 0 ELSE SUM(SALDO_TOTAL) END AS SALDO_TOTAL 
from OM_SALDO_PRODUTO_ATP_JB_cd_V2 
where 1=1 --saldo_total > 0
--and cod_item = '26110E'
GROUP BY ID_PERIODO, DES_CD, COD_ITEM
) A PIVOT
(
    SUM(SALDO_TOTAL) SALDO_TOTAL
    FOR ID_PERIODO IN(1,2,3,4,5,6,7,8,9,10)
)
) PS LEFT JOIN (
SELECT * FROM (
     select A.ID_PERIODO, 'EET' AS DES_CD, msi.segment1 AS COD_ITEM,CASE WHEN SUM(QT_SALDO) < 0 THEN 0 ELSE SUM(QT_SALDO) END AS QT_SALDO 
      from apps.OM_SALDO_PRODUTO_ATP_JB a  
      inner join mtl_system_items_b msi on a.inventory_item_id = msi.inventory_item_id 
      left join (select * from apps.OM_SALDO_PRODUTO_ATP_JB_CD_V2 where nvl(vol_meta,0) > 0 ) ab on msi.segment1 = ab.cod_item and a.id_periodo = ab.id_periodo 
    where msi.organization_id = 43 
         --and msi.SEGMENT1 = '26110E' 
    GROUP BY A.ID_PERIODO, MSI.SEGMENT1 
) A PIVOT 
(
    SUM(QT_SALDO) QT_SALDO
    FOR ID_PERIODO IN(1,2,3,4,5,6,7,8,9,10)
)
) PB ON PS.COD_ITEM = PB.COD_ITEM AND PS.DES_CD = PB.DES_CD


SELECT
replace('PRJ' ||trim(STK.DES_CD) || trim(STK.COD_ITEM),',','') AS ExternalCode__c,
CASE DES_CD
                  WHEN 'P11' THEN '1717'
                  WHEN 'PUC' THEN '1716'
                  WHEN 'EET' THEN '1719'
                  WHEN 'PNT' THEN '1759'
                  WHEN 'PPB' THEN '1761'
                  WHEN 'PMA' THEN '1819'
                  WHEN 'EEM' THEN '1860'
                  WHEN 'PPE' THEN '1881'
                  WHEN 'CDC' THEN '1940'
                  WHEN 'CWB' THEN '1960'
                  WHEN 'CSA' THEN '1980'
                  WHEN 'CIT' THEN '1981'
                  WHEN 'EEA' THEN '1982'
                  WHEN 'CFR' THEN '1986'
                  WHEN 'CGO' THEN '2006'
                  WHEN 'CPR' THEN '2066'
                  WHEN 'CJU' THEN '1900'
                  ELSE '1719'
               END
                  AS WarehouseCode__c,
               CASE DES_CD
                  WHEN 'P11' THEN '1717'
                  WHEN 'PUC' THEN '1716'
                  WHEN 'EET' THEN '1719'
                  WHEN 'PNT' THEN '1759'
                  WHEN 'PPB' THEN '1761'
                  WHEN 'PMA' THEN '1819'
                  WHEN 'EEM' THEN '1860'
                  WHEN 'PPE' THEN '1881'
                  WHEN 'CDC' THEN '1940'
                  WHEN 'CWB' THEN '1960'
                  WHEN 'CSA' THEN '1980'
                  WHEN 'CIT' THEN '1981'
                  WHEN 'EEA' THEN '1982'
                  WHEN 'CFR' THEN '1986'
                  WHEN 'CGO' THEN '2006'
                  WHEN 'CPR' THEN '2066'
                  WHEN 'CJU' THEN '1900'
                  ELSE '1719'
               END
                  AS DESCRICAODEPOSITO__C,
replace(trim(STK.DES_CD) || '-' || trim(STK.COD_ITEM),',','') AS NAME,  
dp.id_salesforce AS PRODUCT__C,  
'0125f000000uyHmAAI' as RecordTypeID,
  (SELECT DESCRIPTION FROM fnd_lookup_values 
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 1 --Periodos Válidos para Decêndios
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period01Name__c,
REPLACE(NVL(STK.PTBL_P1,0),',','.') ProjectedBalance01__c,
REPLACE(STK.SHOP_P1,',','.') ProjectedBalance01PbShop__c,
  (SELECT DESCRIPTION FROM fnd_lookup_values 
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 2 --Periodos Válidos para Decêndios
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period02Name__c,
REPLACE(NVL(STK.PTBL_P2,0),',','.') ProjectedBalance02__c,
REPLACE(STK.SHOP_P2,',','.') ProjectedBalance02PbShop__c,
  (SELECT DESCRIPTION FROM fnd_lookup_values 
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 3 --Periodos Válidos para Decêndios
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period03Name__c,
REPLACE(NVL(STK.PTBL_P3,0),',','.') ProjectedBalance03__c,
REPLACE(STK.SHOP_P3,',','.') ProjectedBalance03PbShop__c,
  (SELECT DESCRIPTION FROM fnd_lookup_values 
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 4 --Periodos Válidos para Decêndios
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period04Name__c,
REPLACE(NVL(STK.PTBL_P4,0),',','.') ProjectedBalance04__c,
REPLACE(STK.SHOP_P4,',','.') ProjectedBalance04PbShop__c,
  (SELECT DESCRIPTION FROM fnd_lookup_values 
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 5 --Periodos Válidos para Decêndios
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period05Name__c,
REPLACE(NVL(STK.PTBL_P5,0),',','.') ProjectedBalance05__c,
REPLACE(STK.SHOP_P5,',','.') ProjectedBalance05PbShop__c,
  (SELECT DESCRIPTION FROM fnd_lookup_values 
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 6 --Periodos Válidos para Decêndios
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period06Name__c,
REPLACE(NVL(STK.PTBL_P6,0),',','.') ProjectedBalance06__c,
REPLACE(STK.SHOP_P6,',','.') ProjectedBalance06PbShop__c,
  (SELECT DESCRIPTION FROM fnd_lookup_values 
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 7 --Periodos Válidos para Decêndios
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period07Name__c,
REPLACE(NVL(STK.PTBL_P7,0),',','.') ProjectedBalance07__c,
REPLACE(STK.SHOP_P7,',','.') ProjectedBalance07PbShop__c,
  (SELECT DESCRIPTION FROM fnd_lookup_values 
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 8 --Periodos Válidos para Decêndios
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period08Name__c,
REPLACE(NVL(STK.PTBL_P8,0),',','.') ProjectedBalance08__c,
REPLACE(STK.SHOP_P8,',','.') ProjectedBalance08PbShop__c,
  (SELECT DESCRIPTION FROM fnd_lookup_values 
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 9 --Periodos Válidos para Decêndios
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period09Name__c,
REPLACE(NVL(STK.PTBL_P9,0),',','.') ProjectedBalance09__c,
REPLACE(STK.SHOP_P9,',','.') ProjectedBalance09PbShop__c,
  (SELECT DESCRIPTION FROM fnd_lookup_values 
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 10 --Periodos Válidos para Decêndios
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period10Name__c,
REPLACE(NVL(STK.PTBL_P10,0),',','.') ProjectedBalance10__c,
REPLACE(STK.SHOP_P10,',','.') ProjectedBalance10PbShop__c,
'P1' as TenDayPeriod1__c,
'P2' as TenDayPeriod2__c,
'P3' as TenDayPeriod3__c,
'P4' as TenDayPeriod4__c,
'P5' as TenDayPeriod5__c,
'P6' as TenDayPeriod6__c,
'P7' as TenDayPeriod7__c,
'P8' as TenDayPeriod8__c,
'P9' as TenDayPeriod9__c,
'P10' as TenDayPeriod10__c
FROM TMP_PROJETADO_SALESFORCE STK
INNER JOIN TMP_PROD_SALESFORCE dp
               ON stk.cod_item = dp.cod_produto_ora 
INNER JOIN (SELECT MEANING AS COD_DEPOSITO
                  FROM FND_LOOKUP_VALUES
                 WHERE     language = USERENV ('LANG')
                       AND enabled_flag = 'Y'
                       AND lookup_type = 'ONT_DEPOSITOS_SALES_PB'               ) DEP ON STK.DES_CD = DEP.COD_DEPOSITO



  (SELECT DESCRIPTION FROM fnd_lookup_values 
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 1 --Periodos Válidos para Decêndios
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))) AS 




SELECT * FROM (
select ID_PERIODO AS ID_PERIODO, DES_CD, COD_ITEM, CASE WHEN SUM(SALDO_TOTAL) <0 THEN 0 ELSE SUM(SALDO_TOTAL) END AS SALDO_TOTAL 
from OM_SALDO_PRODUTO_ATP_JB_cd_V2 
where 1=1 --saldo_total > 0
and cod_item = '26110E'
GROUP BY ID_PERIODO, DES_CD, COD_ITEM
) A PIVOT
(
    SUM(SALDO_TOTAL) SALDO_TOTAL
    FOR ID_PERIODO IN(1,2,3,4,5,6,7,8,9,10)
)



SELECT *
  FROM (SELECT REPLACE (
                  REPLACE (
                     REPLACE (
                        REPLACE ('STK' || 
                           TRIM (
                                 stk.cod_deposito
                              || '-'
                              || stk.cod_tonalidade_calibre
                              || '-'
                              || stk.cod_produto_ora),
                           ',',
                           ''),
                        CHR (10)),
                     CHR (13)),
                  CHR (9))
                  AS ExternalCode__c,
               CASE COD_DEPOSITO
                  WHEN 'P11' THEN '1717'
                  WHEN 'PUC' THEN '1716'
                  WHEN 'EET' THEN '1719'
                  WHEN 'PNT' THEN '1759'
                  WHEN 'PPB' THEN '1761'
                  WHEN 'PMA' THEN '1819'
                  WHEN 'EEM' THEN '1860'
                  WHEN 'PPE' THEN '1881'
                  WHEN 'CDC' THEN '1940'
                  WHEN 'CWB' THEN '1960'
                  WHEN 'CSA' THEN '1980'
                  WHEN 'CIT' THEN '1981'
                  WHEN 'EEA' THEN '1982'
                  WHEN 'CFR' THEN '1986'
                  WHEN 'CGO' THEN '2006'
                  WHEN 'CPR' THEN '2066'
                  WHEN 'CJU' THEN '1900'
                  ELSE '1719'
               END
                  AS WarehouseCode__c,
               CASE COD_DEPOSITO
                  WHEN 'P11' THEN '1717'
                  WHEN 'PUC' THEN '1716'
                  WHEN 'EET' THEN '1719'
                  WHEN 'PNT' THEN '1759'
                  WHEN 'PPB' THEN '1761'
                  WHEN 'PMA' THEN '1819'
                  WHEN 'EEM' THEN '1860'
                  WHEN 'PPE' THEN '1881'
                  WHEN 'CDC' THEN '1940'
                  WHEN 'CWB' THEN '1960'
                  WHEN 'CSA' THEN '1980'
                  WHEN 'CIT' THEN '1981'
                  WHEN 'EEA' THEN '1982'
                  WHEN 'CFR' THEN '1986'
                  WHEN 'CGO' THEN '2006'
                  WHEN 'CPR' THEN '2066'
                  WHEN 'CJU' THEN '1900'
                  ELSE '1719'
               END
                  AS DESCRICAODEPOSITO__C,
               TRIM (
                  REPLACE (
                     REPLACE (
                        REPLACE (REPLACE (COD_TONALIDADE_CALIBRE, CHR (10)),
                                 CHR (13)),
                        CHR (9)),
                     ',',
                     ''))
                  AS CODTONALIDADECALIBRE__C,
               TRIM (
                  REPLACE (
                     REPLACE (
                        REPLACE (
                           REPLACE (
                              COD_DEPOSITO || ' - ' || COD_TONALIDADE_CALIBRE,
                              CHR (10)),
                           CHR (13)),
                        CHR (9)),
                     ',',
                     ''))
                  AS NAME,
               dp.id_salesforce AS PRODUCT__C,
               REPLACE (TO_CHAR (SALDO_PBSHOP), ',', '.')
                  AS BALANCEPORTOBELLOSHOP__C,
               REPLACE (TO_CHAR (SALDO_DISPONIVEL), ',', '.') AS BALANCE__C,
               REPLACE (TO_CHAR (SALDO_EXPORTACAO), ',', '.')
                  AS EXPORTBALANCE__C,
               '0127j000000D3WfAAK' RecordTypeID,
               0 AS STOCKFRACTION__C                    -- Percentual de ponta
          FROM    apps.xxpb_estoque_api stk
               INNER JOIN
                  TMP_PROD_SALESFORCE dp
               ON stk.cod_produto_ora = dp.cod_produto_ora
         WHERE COD_DEPOSITO NOT IN ('ELA')--and stk.COD_PRODUTO_ORA <> '26110E'
       )
 WHERE (   balanceportobelloshop__c <> '0'
        OR balance__c <> '0'
        OR exportBalance__c <> '0')