SELECT *
  FROM (SELECT REPLACE (
                  REPLACE (
                     REPLACE (
                        REPLACE ( 'STK' ||
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


/*CASE COD_DEPOSITO WHEN 'P11' THEN 'P11: Planta Portobello 11' 
WHEN 'PUC' THEN 'PUC: Planta Única'  
WHEN 'EET' THEN 'EET: Estoque Expedição Tijucas' 
WHEN 'PNT' THEN 'PNT: Planta Pernambuco Pointer'  
WHEN 'PPB' THEN 'PPB: Planta Pernambuco Portobello'  
WHEN 'PMA' THEN 'PMA: Planta Portobello Marechal Deodoro'  
WHEN 'EEM' THEN 'EEM: Estoque Expedição Marechal Deodoro'  
WHEN 'PPE' THEN 'PPE: Planta Pointer Pernambuco' 
WHEN 'CDC' THEN 'CDC: Cd Duque De Caxias'  
WHEN 'CWB' THEN 'CWB: Cd Curitiba'  
WHEN 'CSA' THEN 'CSA: Cd Cabo De Santo Agostinho'  
WHEN 'CIT' THEN 'CIT: Planta Itajaí - Tecadi'  
WHEN 'EEA' THEN 'EEA: Est Exp Portobello Alagoas'  
WHEN 'CFR' THEN 'CFR: Cd Fortaleza'  
WHEN 'CGO' THEN 'CGO: Cd Goiania'  
WHEN 'CPR' THEN 'CPR: CD PETROLINA' 
WHEN 'CJU' THEN 'CJU: CD JUNDIAI' ELSE 'EET: Estoque Expedição Tijucas' END AS DESCRICAODEPOSITO__C,*/
