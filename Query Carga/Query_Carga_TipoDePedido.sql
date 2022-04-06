exec mo_global.set_policy_context('S','42'); -- PB
--exec mo_global.set_policy_context('S','1839');  -- CBC

/* Formatted on 16/12/2021 09:35:06 (QP5 v5.215.12089.38647) */
  SELECT 'TPOV' || ORDER_TYPE_ID AS EXTERNALID__C,
         ORDER_TYPE_ID ERP_ID,
         replace(TRA.DESCR,',','') AS NAME,
         ORDER_TYPE_ID AS ORDERTYPE__C,
         '0125f000000uBh3AAE' AS RECORDTYPEID,
         DEP.ORGANIZATION_ID AS WAREHOUSE__C
    FROM oe_transaction_types_tl a,
         oe_transaction_types_all b,
         ar.ra_cust_trx_types_all c,
         RA_CUST_TRX_TYPES d,
         OE_WF_LINE_ASSIGN_V e,
         (  SELECT SUBSTR (a.NAME, 1, 3) Deposito, a.NAME, a.ORGANIZATION_ID
              FROM hr_organization_units a
          --WHERE a.NAME LIKE '%CWB%'
          ORDER BY ORGANIZATION_ID) DEP,
         (SELECT 6728 AS COD,
                 'Venda Normal Pointer (CPR - Petrolina) - MI' AS DESCR,
                 'CPR' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 6732 AS COD,
                 'Amostra Pointer (CPR - Petrolina) - MI' AS DESCR,
                 'CPR' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 1022 AS COD,
                 'Venda Normal Portobello - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 1141 AS COD,
                 'Apartamento Padrão Engenharia Portobello - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 3544 AS COD,
                 'Venda Desconto Marketing Revenda Portobello - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 3844 AS COD,
                 'Venda Programada Engenharia Portobello - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 4464 AS COD,
                 'Venda BNDES Engenharia Portobello - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 6387 AS COD,
                 'Venda Normal Pointer (EET - Tijucas) - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 4845 AS COD,
                 'Venda Normal Porcelanateria (CDC - Duque de Caxias) - MI'
                    AS DESCR,
                 'CDC' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5903 AS COD,
                 'Venda Normal Porcelanateria (CGO - Goiania) - MI' AS DESCR,
                 'CGO' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5080 AS COD,
                 'Venda Normal Porcelanateria (CSA - Cabo Sto. Agostinho) - MI'
                    AS DESCR,
                 'CSA' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 4947 AS COD,
                 'Venda Normal Porcelanateria (CWB - Curitiba) - MI' AS DESCR,
                 'CWB' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 4644 AS COD,
                 'Venda Normal Porcelanateria (CJU - Jundiaí) - MI' AS DESCR,
                 'CJU' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5813 AS COD,
                 'Venda Normal Pointer (CFR - Fortaleza) - MI' AS DESCR,
                 'CFR' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5830 AS COD,
                 'Amostra Pointer (CFR - Fortaleza) - MI' AS DESCR,
                 'CFR' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5138 AS COD,
                 'Apartamento Padrão Engenharia Pointer - MI' AS DESCR,
                 'EEA' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5163 AS COD,
                 'Venda Programada Engenharia Pointer (FMD - Marechal Deodoro) - MI'
                    AS DESCR,
                 'EEA' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 6242 AS COD,
                 'Venda Normal Porcelanateria (CTJ - Tijucas) - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5633 AS COD,
                 'Venda BNDES Engenharia Pointer - MI' AS DESCR,
                 'EEA' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5132 AS COD,
                 'Amostra Pointer (FMD - Marechal Deodoro) - MI' AS DESCR,
                 'EEA' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 4524 AS COD,
                 'Venda Normal Pointer (FMD - Marechal Deodoro) - MI' AS DESCR,
                 'EEA' AS COD_DEP
            FROM DUAL) TRA
   WHERE     a.language = 'PTB'
         AND a.transaction_type_id = b.transaction_type_id
         AND b.transaction_type_code = 'ORDER'
         AND b.end_date_active IS NULL
         AND b.cust_trx_type_id = c.cust_trx_type_id
         AND d.CUST_TRX_TYPE_ID = c.cust_trx_type_id
         AND e.ORDER_TYPE_ID = a.transaction_type_id
         AND e.END_DATE_ACTIVE IS NULL
         AND a.transaction_type_id NOT IN (1960, 1939, 1002)
         AND ORDER_TYPE_ID IN
                (6728,
                 6732,
                 1022,
                 1141,
                 3544,
                 3844,
                 4464,
                 6387,
                 4845,
                 5903,
                 5080,
                 4947,
                 4644,
                 5813,
                 5830,
                 5138,
                 5163,
                 6242,
                 5633,
                 5132,
                 4524)
         AND ORDER_TYPE_ID = TRA.COD
         AND TRA.COD_DEP = DEP.DEPOSITO(+)
ORDER BY TO_NUMBER (REGEXP_SUBSTR (a.name, '^[0-9]+[0-9]+'))
  
  
  
  
  
  
  
  




  SELECT DISTINCT
         DEP.ORGANIZATION_ID AS WAREHOUSE__C
    FROM oe_transaction_types_tl a,
         oe_transaction_types_all b,
         ar.ra_cust_trx_types_all c,
         RA_CUST_TRX_TYPES d,
         OE_WF_LINE_ASSIGN_V e,
         (  SELECT SUBSTR (a.NAME, 1, 3) Deposito, a.NAME, a.ORGANIZATION_ID
              FROM hr_organization_units a
          --WHERE a.NAME LIKE '%CWB%'
          ORDER BY ORGANIZATION_ID) DEP,
         (SELECT 6728 AS COD,
                 'Venda Normal Pointer (CPR - Petrolina) - MI' AS DESCR,
                 'CPR' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 6732 AS COD,
                 'Amostra Pointer (CPR - Petrolina) - MI' AS DESCR,
                 'CPR' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 1022 AS COD,
                 'Venda Normal Portobello - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 1141 AS COD,
                 'Apartamento Padrão Engenharia Portobello - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 3544 AS COD,
                 'Venda Desconto Marketing Revenda Portobello - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 3844 AS COD,
                 'Venda Programada Engenharia Portobello - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 4464 AS COD,
                 'Venda BNDES Engenharia Portobello - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 6387 AS COD,
                 'Venda Normal Pointer (EET - Tijucas) - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 4845 AS COD,
                 'Venda Normal Porcelanateria (CDC - Duque de Caxias) - MI'
                    AS DESCR,
                 'CDC' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5903 AS COD,
                 'Venda Normal Porcelanateria (CGO - Goiania) - MI' AS DESCR,
                 'CGO' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5080 AS COD,
                 'Venda Normal Porcelanateria (CSA - Cabo Sto. Agostinho) - MI'
                    AS DESCR,
                 'CSA' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 4947 AS COD,
                 'Venda Normal Porcelanateria (CWB - Curitiba) - MI' AS DESCR,
                 'CWB' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 4644 AS COD,
                 'Venda Normal Porcelanateria (CJU - Jundiaí) - MI' AS DESCR,
                 'CJU' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5813 AS COD,
                 'Venda Normal Pointer (CFR - Fortaleza) - MI' AS DESCR,
                 'CFR' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5830 AS COD,
                 'Amostra Pointer (CFR - Fortaleza) - MI' AS DESCR,
                 'CFR' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5138 AS COD,
                 'Apartamento Padrão Engenharia Pointer - MI' AS DESCR,
                 'EEA' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5163 AS COD,
                 'Venda Programada Engenharia Pointer (FMD - Marechal Deodoro) - MI'
                    AS DESCR,
                 'EEA' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 6242 AS COD,
                 'Venda Normal Porcelanateria (CTJ - Tijucas) - MI' AS DESCR,
                 'EET' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5633 AS COD,
                 'Venda BNDES Engenharia Pointer - MI' AS DESCR,
                 'EEA' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 5132 AS COD,
                 'Amostra Pointer (FMD - Marechal Deodoro) - MI' AS DESCR,
                 'EEA' AS COD_DEP
            FROM DUAL
          UNION ALL
          SELECT 4524 AS COD,
                 'Venda Normal Pointer (FMD - Marechal Deodoro) - MI' AS DESCR,
                 'EEA' AS COD_DEP
            FROM DUAL) TRA
   WHERE     a.language = 'PTB'
         AND a.transaction_type_id = b.transaction_type_id
         AND b.transaction_type_code = 'ORDER'
         AND b.end_date_active IS NULL
         AND b.cust_trx_type_id = c.cust_trx_type_id
         AND d.CUST_TRX_TYPE_ID = c.cust_trx_type_id
         AND e.ORDER_TYPE_ID = a.transaction_type_id
         AND e.END_DATE_ACTIVE IS NULL
         AND a.transaction_type_id NOT IN (1960, 1939, 1002)
         AND ORDER_TYPE_ID IN
                (6728,
                 6732,
                 1022,
                 1141,
                 3544,
                 3844,
                 4464,
                 6387,
                 4845,
                 5903,
                 5080,
                 4947,
                 4644,
                 5813,
                 5830,
                 5138,
                 5163,
                 6242,
                 5633,
                 5132,
                 4524)
         AND ORDER_TYPE_ID = TRA.COD
         AND TRA.COD_DEP = DEP.DEPOSITO(+)
--ORDER BY TO_NUMBER (REGEXP_SUBSTR (a.name, '^[0-9]+[0-9]+'))