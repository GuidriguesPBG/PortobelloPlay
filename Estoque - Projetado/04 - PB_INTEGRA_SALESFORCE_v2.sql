CREATE OR REPLACE PACKAGE APPS.PB_INTEGRA_SALESFORCE
IS
   -- +=================================================================+
   -- |      Copyright (c) 2012 Portobello, Santa Catarina, Brasil      |
   -- |                       All rights reserved.                      |
   -- +=================================================================+
   -- | FILENAME                                                        |
   -- | PB_INTEGRA_SALESFORCE.pkg                                       |
   -- |                                                                 |
   -- | PURPOSE                                                         |
   -- |   Script de criacao da package PB_INTEGRA_SALESFORCE.           |
   -- |                                                                 |
   -- | DESCRIPTION                                                     |
   -- |   Objetivo deste objeto é concentrar as funções e procedimentos |
   -- | utilizados nas integrações com o Salesforce                     |
   -- |   pedido do software Ivop e o modulo Order Management da solucao|
   -- |   solucao Oracle release 11.5.10.                               |
   -- |                                                                 |
   -- | CREATED BY                                                      |
   -- |   Guilherme Rodrigues     REVISION 1.0          17/12/2021      |
   -- |   Guilherme Rodrigues     REVISION 1.1          17/03/2022      |
   -- |                                                                 |
   -- | UPDATED BY                                                      |
   -- |                                                                 |
   -- +=================================================================+

   -- Procedure para validar se quantidade informada referesse a caixa aberta ou fechada
   PROCEDURE p_gera_dados_cli_po (errbuf          OUT VARCHAR2,
                                  errcode         OUT VARCHAR2,
                                  p_completa   IN     NUMBER);


   PROCEDURE p_gera_dados_estoque_zero (errbuf          OUT VARCHAR2,
                                        errcode         OUT VARCHAR2,
                                        p_completa   IN     NUMBER);


   PROCEDURE p_gera_dados_estoque_prj (errbuf    OUT VARCHAR2,
                                       errcode   OUT VARCHAR2);
END PB_INTEGRA_SALESFORCE;
/

CREATE OR REPLACE PACKAGE BODY APPS.PB_INTEGRA_SALESFORCE
IS
   -- Procedure para compor os dados de estoque projetado
   PROCEDURE p_gera_dados_estoque_prj (errbuf    OUT VARCHAR2,
                                       errcode   OUT VARCHAR2)
   IS
   --
   /******************************************************************************
      NAME:       p_gera_dados_estoque_prj
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        17/03/2022   Guilherme Rodrigues       1. Created this procedure.

      NOTES:
         Object Name:     p_gera_dados_estoque_prj
         Sysdate:         17/03/2022
         Date and Time:   17/03/2022, 08:53:02, and 17/03/2022 08:53:02
         Username:        guilherme.rodrigues

   ******************************************************************************/


   BEGIN
      DELETE TMP_PROJETADO_SALESFORCE;

      COMMIT;

      INSERT INTO TMP_PROJETADO_SALESFORCE (DES_CD,
                                            COD_ITEM,
                                            LAST_UPDATE_DATE,
                                            SHOP_P1,
                                            SHOP_P2,
                                            SHOP_P3,
                                            SHOP_P4,
                                            SHOP_P5,
                                            SHOP_P6,
                                            SHOP_P7,
                                            SHOP_P8,
                                            SHOP_P9,
                                            SHOP_P10,
                                            DES_CD_1,
                                            COD_ITEM_1,
                                            LAST_UPDATE_DATE_1,
                                            PTBL_P1,
                                            PTBL_P2,
                                            PTBL_P3,
                                            PTBL_P4,
                                            PTBL_P5,
                                            PTBL_P6,
                                            PTBL_P7,
                                            PTBL_P8,
                                            PTBL_P9,
                                            PTBL_P10)
         SELECT PS.*, PB.*
           FROM    (SELECT *
                      FROM (  SELECT ID_PERIODO AS ID_PERIODO,
                                     DES_CD,
                                     COD_ITEM,
                                     CASE
                                        WHEN SUM (SALDO_TOTAL) < 0 THEN 0
                                        ELSE SUM (SALDO_TOTAL)
                                     END
                                        AS SALDO_TOTAL,
                                     --MAX (LAST_UPDATE_DATE) AS LAST_UPDATE_DATE
                     MAX (TO_DATE(TRUNC(LAST_UPDATE_DATE) || ' 23:59:59','DD/MM/YYYY HH24:MI:SS')) AS LAST_UPDATE_DATE
                                FROM apps.OM_SALDO_PRODUTO_ATP_JB_cd_V2
                               WHERE DES_CD IN
                                        (SELECT MEANING
                                           FROM FND_LOOKUP_VALUES
                                          WHERE     language = USERENV ('LANG')
                                                AND enabled_flag = 'Y'
                                                AND lookup_type =
                                                       'ONT_DEPOSITOS_SALES_PB')
                            GROUP BY ID_PERIODO, DES_CD, COD_ITEM) A PIVOT (SUM (
                                                                               SALDO_TOTAL) SALDO_TOTAL
                                                                     FOR ID_PERIODO
                                                                     IN  (1,
                                                                         2,
                                                                         3,
                                                                         4,
                                                                         5,
                                                                         6,
                                                                         7,
                                                                         8,
                                                                         9,
                                                                         10))) PS
                LEFT JOIN
                   (SELECT *
                      FROM (  SELECT A.ID_PERIODO,
                                     'EET' AS DES_CD,
                                     msi.segment1 AS COD_ITEM,
                                     CASE
                                        WHEN SUM (QT_SALDO) < 0 THEN 0
                                        ELSE SUM (QT_SALDO)
                                     END
                                        AS QT_SALDO,
                                     MAX (TO_DATE(TRUNC(A.LAST_UPDATE_DATE) || ' 23:59:59','DD/MM/YYYY HH24:MI:SS')) AS LAST_UPDATE_DATE
                                FROM apps.OM_SALDO_PRODUTO_ATP_JB a
                                     INNER JOIN mtl_system_items_b msi
                                        ON a.inventory_item_id =
                                              msi.inventory_item_id
                                     LEFT JOIN (SELECT *
                                                  FROM apps.OM_SALDO_PRODUTO_ATP_JB_CD_V2
                                                 WHERE NVL (vol_meta, 0) > 0) ab
                                        ON     msi.segment1 = ab.cod_item
                                           AND a.id_periodo = ab.id_periodo
                               WHERE msi.organization_id =
                                        pb_master_organization_id
                            GROUP BY A.ID_PERIODO, MSI.SEGMENT1) A PIVOT (SUM (
                                                                             QT_SALDO) QT_SALDO
                                                                   FOR ID_PERIODO
                                                                   IN  (1,
                                                                       2,
                                                                       3,
                                                                       4,
                                                                       5,
                                                                       6,
                                                                       7,
                                                                       8,
                                                                       9,
                                                                       10))) PB
                ON PS.COD_ITEM = PB.COD_ITEM AND PS.DES_CD = PB.DES_CD;

      COMMIT;


      BEGIN
         FOR X
            IN (SELECT MEANING AS COD_DEPOSITO
                  FROM FND_LOOKUP_VALUES
                 WHERE     language = USERENV ('LANG')
                       AND enabled_flag = 'Y'
                       AND lookup_type = 'ONT_DEPOSITOS_SALES_PB')
         LOOP
            INSERT INTO tmp_projetado_salesforce
               SELECT X.COD_DEPOSITO AS DES_CD,
                      A.COD_PRODUTO_ORA AS COD_ITEM,
                      SYSDATE,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0,
                      '',
                      '',
                      SYSDATE,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0
                 FROM tmp_prod_salesforce a
                WHERE NOT EXISTS
                             (SELECT 1
                                FROM tmp_projetado_salesforce
                               WHERE     cod_item = a.cod_produto_ora
                                     AND DES_CD = X.COD_DEPOSITO);

            COMMIT;
         END LOOP;
      END;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END p_gera_dados_estoque_prj;



   -- Procedure para validar se quantidade informada referesse a caixa aberta ou fechada
   PROCEDURE p_gera_dados_estoque_zero (errbuf          OUT VARCHAR2,
                                        errcode         OUT VARCHAR2,
                                        p_completa   IN     NUMBER)
   IS
      --
      /******************************************************************************
         NAME:       p_gera_dados_estoque_zero
         PURPOSE:

         REVISIONS:
         Ver        Date        Author           Description
         ---------  ----------  ---------------  ------------------------------------
         1.0        17/03/2022   Guilherme Rodrigues       1. Created this procedure.

         NOTES:
            Object Name:     p_gera_dados_estoque_zero
            Sysdate:         17/03/2022
            Date and Time:   17/03/2022, 08:53:02, and 17/03/2022 08:53:02
            Username:        guilherme.rodrigues

      ******************************************************************************/

      CURSOR C_DEPOSITO
      IS
         SELECT MEANING AS COD_DEPOSITO
           FROM FND_LOOKUP_VALUES
          WHERE     language = USERENV ('LANG')
                AND enabled_flag = 'Y'
                AND lookup_type = 'ONT_DEPOSITOS_SALES_PB';

      P_FULL   INT;
   BEGIN
      --P_FULL := 0;
      P_FULL := NVL (p_completa, 0);

      IF P_FULL = 1
      THEN
         EXECUTE IMMEDIATE 'TRUNCATE TABLE XXPB.XXPB_ESTOQUE_API_ZERO';

         COMMIT;

         -- 1 - XXPB_ESTOQUE_API_ZERO recebe a carga de estoque atual de XXPB_ESTOQUE_API (guardará o campo chave do Sales (DEPOSITO + TONALIDADE + PRODUTO)) - FLAG_STK = 1
         INSERT INTO XXPB.XXPB_ESTOQUE_API_ZERO (INVENTORY_ITEM_ID,
                                                 COD_DEPOSITO,
                                                 COD_TONALIDADE_CALIBRE,
                                                 COD_PRODUTO_ORA,
                                                 LAST_UPDATE_DATE,
                                                 FLAG_STK,
                                                 FLAG_EXC)
            SELECT INVENTORY_ITEM_ID,
                   COD_DEPOSITO,
                   COD_TONALIDADE_CALIBRE,
                   COD_PRODUTO_ORA,
                   LAST_UPDATE_DATE,
                   1,
                   0
              FROM XXPB.XXPB_ESTOQUE_API
             WHERE SALDO_DISPONIVEL > 0;

         COMMIT;

         FOR X IN C_DEPOSITO
         LOOP
            FOR y
               IN (SELECT INVENTORY_ITEM_ID,
                          X.COD_DEPOSITO,
                          '000000' AS COD_TONALIDADE_CALIBRE,
                          SEGMENT1 AS COD_PRODUTO_ORA,
                          SYSDATE AS LAST_UPDATE_DATE
                     FROM MTL_SYSTEM_ITEMS_B B
                    WHERE     ORGANIZATION_ID = pb_master_organization_id --AND SEGMENT1 = '26110E'
                          AND b.attribute9 IN ('AT', 'SC', 'SP')
                          AND NOT EXISTS
                                     (SELECT 1
                                        FROM XXPB_ESTOQUE_API_ZERO
                                       WHERE     COD_PRODUTO_ORA = B.SEGMENT1
                                             AND COD_DEPOSITO =
                                                    X.COD_DEPOSITO)
                   UNION ALL
                   SELECT INVENTORY_ITEM_ID,
                          X.COD_DEPOSITO,
                          '000000' AS COD_TONALIDADE_CALIBRE,
                          SEGMENT1 AS COD_PRODUTO_ORA,
                          SYSDATE AS LAST_UPDATE_DATE
                     FROM MTL_SYSTEM_ITEMS_B B
                    WHERE     ORGANIZATION_ID = pb_master_organization_id --AND SEGMENT1 = '26110E'
                          AND b.attribute9 IN ('IN', 'DE', 'SU')
                          AND b.segment1 IN (SELECT cod_produto_ora
                                               FROM xxpb_estoque_api
                                              WHERE saldo_disponivel > 0)
                          AND NOT EXISTS
                                     (SELECT 1
                                        FROM XXPB_ESTOQUE_API_ZERO
                                       WHERE     COD_PRODUTO_ORA = B.SEGMENT1
                                             AND COD_DEPOSITO =
                                                    X.COD_DEPOSITO))
            LOOP
               INSERT
                 INTO XXPB.XXPB_ESTOQUE_API_ZERO (INVENTORY_ITEM_ID,
                                                  COD_DEPOSITO,
                                                  COD_TONALIDADE_CALIBRE,
                                                  COD_PRODUTO_ORA,
                                                  LAST_UPDATE_DATE,
                                                  FLAG_STK,
                                                  FLAG_EXC)
               VALUES (y.inventory_item_id,
                       y.cod_deposito,
                       y.cod_tonalidade_calibre,
                       y.cod_produto_ora,
                       y.last_update_date,
                       0,
                       0);

               COMMIT;
            END LOOP;
         END LOOP;
      END IF;

      IF P_FULL = 0
      THEN
         --1 - XXPB_ESTOQUE_API_ZERO recebe atualização no campo LAST_UPDATE_DATE quando:
         --    A) Não houver registro correspondente em XXPB_ESTOQUE_API para a chave DEPOSITO + PRODUTO e FLAG_STK = 0 e
         --       houver corresponde a chave em registro com FLAG_STK = 1 e EXCLUIR = 1
         UPDATE XXPB.XXPB_ESTOQUE_API_ZERO X
            SET LAST_UPDATE_DATE = SYSDATE
          WHERE     FLAG_STK = 0
                AND NOT EXISTS
                           (SELECT 1
                              FROM XXPB_ESTOQUE_API
                             WHERE     COD_PRODUTO_ORA = X.COD_PRODUTO_ORA
                                   AND COD_DEPOSITO = X.COD_DEPOSITO
                                   AND SALDO_DISPONIVEL > 0)
                AND EXISTS
                       (SELECT 1
                          FROM XXPB_ESTOQUE_API_ZERO
                         WHERE     COD_PRODUTO_ORA = X.COD_PRODUTO_ORA
                               AND COD_DEPOSITO = X.COD_DEPOSITO
                               AND FLAG_STK = 1
                               AND FLAG_EXC = 0
                               AND NOT EXISTS
                                          (SELECT 1
                                             FROM XXPB_ESTOQUE_API
                                            WHERE     COD_PRODUTO_ORA =
                                                         X.COD_PRODUTO_ORA
                                                  AND COD_DEPOSITO =
                                                         X.COD_DEPOSITO
                                                  AND SALDO_DISPONIVEL > 0));

         COMMIT;

         --    B) chave do sales "not exists" na tabela XXPB_ESTOQUE_API e FLAG_STK = 1 e EXCLUIR = 0| Atualiza o campo EXCLUIR = 1
         UPDATE XXPB.XXPB_ESTOQUE_API_ZERO X
            SET LAST_UPDATE_DATE = SYSDATE, FLAG_EXC = 1
          WHERE     FLAG_STK = 1
                AND FLAG_EXC = 0
                AND NOT EXISTS
                           (SELECT 1
                              FROM XXPB_ESTOQUE_API
                             WHERE     COD_PRODUTO_ORA = X.COD_PRODUTO_ORA
                                   AND COD_DEPOSITO = X.COD_DEPOSITO
                                   AND COD_TONALIDADE_CALIBRE =
                                          X.COD_TONALIDADE_CALIBRE
                                   AND SALDO_DISPONIVEL > 0);

         COMMIT;

         -- 2 - XXPB_ESTOQUE_API_ZERO recebe a carga de estoque atual de XXPB_ESTOQUE_API (guardará o campo chave do Sales (DEPOSITO + TONALIDADE + PRODUTO)) - FLAG_STK = 1
         INSERT INTO XXPB.XXPB_ESTOQUE_API_ZERO (INVENTORY_ITEM_ID,
                                                 COD_DEPOSITO,
                                                 COD_TONALIDADE_CALIBRE,
                                                 COD_PRODUTO_ORA,
                                                 LAST_UPDATE_DATE,
                                                 FLAG_STK,
                                                 FLAG_EXC)
            SELECT INVENTORY_ITEM_ID,
                   COD_DEPOSITO,
                   COD_TONALIDADE_CALIBRE,
                   COD_PRODUTO_ORA,
                   LAST_UPDATE_DATE,
                   1,
                   0
              FROM XXPB.XXPB_ESTOQUE_API X
             WHERE     SALDO_DISPONIVEL > 0
                   AND NOT EXISTS
                              (SELECT 1
                                 FROM XXPB_ESTOQUE_API_ZERO
                                WHERE     COD_PRODUTO_ORA = X.COD_PRODUTO_ORA
                                      AND COD_DEPOSITO = X.COD_DEPOSITO
                                      AND COD_TONALIDADE_CALIBRE =
                                             X.COD_TONALIDADE_CALIBRE
                                      AND FLAG_STK = 1
                                      AND FLAG_EXC = 0);

         COMMIT;

         -- 3 - XXPB_ESTOQUE_API_ZERO recebe a carga da chave  DEPOSITO + TONALIDADE + PRODUTO | FLAG_STK = 0
         --  * Será adotado o SKU '000000'
         --  * Se não houver registro correspondente para a chave DEPOSITO + PRODUTO em XXPB_ESTOQUE_API
         FOR X IN C_DEPOSITO
         LOOP
            FOR y
               IN (SELECT INVENTORY_ITEM_ID,
                          X.COD_DEPOSITO,
                          '000000' AS COD_TONALIDADE_CALIBRE,
                          SEGMENT1 AS COD_PRODUTO_ORA,
                          SYSDATE AS LAST_UPDATE_DATE
                     FROM MTL_SYSTEM_ITEMS_B B
                    WHERE     ORGANIZATION_ID = pb_master_organization_id --AND SEGMENT1 = '26110E'
                          AND b.attribute9 IN ('AT', 'SC', 'SP')
                          AND NOT EXISTS
                                     (SELECT 1
                                        FROM XXPB_ESTOQUE_API_ZERO
                                       WHERE     COD_PRODUTO_ORA = B.SEGMENT1
                                             AND COD_DEPOSITO =
                                                    X.COD_DEPOSITO
                                             AND FLAG_EXC <> 1)
                   UNION ALL
                   SELECT INVENTORY_ITEM_ID,
                          X.COD_DEPOSITO,
                          '000000' AS COD_TONALIDADE_CALIBRE,
                          SEGMENT1 AS COD_PRODUTO_ORA,
                          SYSDATE AS LAST_UPDATE_DATE
                     FROM MTL_SYSTEM_ITEMS_B B
                    WHERE     ORGANIZATION_ID = pb_master_organization_id --AND SEGMENT1 = '26110E'
                          AND ( (    b.attribute9 IN ('IN', 'DE', 'SU')
                                 AND b.segment1 IN
                                        (SELECT cod_produto_ora
                                           FROM xxpb_estoque_api
                                          WHERE saldo_disponivel > 0)))
                          AND NOT EXISTS
                                     (SELECT 1
                                        FROM XXPB_ESTOQUE_API_ZERO
                                       WHERE     COD_PRODUTO_ORA = B.SEGMENT1
                                             AND COD_DEPOSITO =
                                                    X.COD_DEPOSITO
                                             AND FLAG_EXC <> 1))
            LOOP
               INSERT
                 INTO XXPB.XXPB_ESTOQUE_API_ZERO (INVENTORY_ITEM_ID,
                                                  COD_DEPOSITO,
                                                  COD_TONALIDADE_CALIBRE,
                                                  COD_PRODUTO_ORA,
                                                  LAST_UPDATE_DATE,
                                                  FLAG_STK,
                                                  FLAG_EXC)
               VALUES (y.inventory_item_id,
                       y.cod_deposito,
                       y.cod_tonalidade_calibre,
                       y.cod_produto_ora,
                       y.last_update_date,
                       0,
                       0);

               COMMIT;
            END LOOP;
         END LOOP;
      END IF;
   --    END LOOP;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END p_gera_dados_estoque_zero;


   -- Procedure para validar se quantidade informada referesse a caixa aberta ou fechada
   PROCEDURE p_gera_dados_cli_po (errbuf          OUT VARCHAR2,
                                  errcode         OUT VARCHAR2,
                                  p_completa   IN     NUMBER)
   IS
      --
      /******************************************************************************
         NAME:       p_gera_dados_cli_po
         PURPOSE:

         REVISIONS:
         Ver        Date        Author           Description
         ---------  ----------  ---------------  ------------------------------------
         1.0        17/12/2021   Guilherme Rodrigues       1. Created this procedure.

         NOTES:
            Object Name:     p_gera_dados_cli_po
            Sysdate:         17/12/2021
            Date and Time:   17/12/2021, 08:53:02, and 17/12/2021 08:53:02
            Username:        guilherme.rodrigues

      ******************************************************************************/

      CURSOR c_first_po (
         p_account_id   IN NUMBER,
         p_empresa      IN NUMBER)
      IS
         -- Busca a primeira ordem do cliente (não considera os 2 anos)
         SELECT MIN (OHA.ORDERED_DATE) FIRST_DATE
           FROM OE_ORDER_HEADERS_ALL OHA
                INNER JOIN HZ_CUST_SITE_USES_ALL OC
                   ON OHA.SHIP_TO_ORG_ID = OC.SITE_USE_ID
                INNER JOIN HZ_CUST_ACCT_SITES_ALL CO
                   ON OC.CUST_ACCT_SITE_ID = CO.CUST_ACCT_SITE_ID
                INNER JOIN HZ_CUST_ACCOUNTS ACCO
                   ON CO.CUST_ACCOUNT_ID = ACCO.CUST_ACCOUNT_ID
          WHERE     OHA.CANCELLED_FLAG = 'N'
                AND OHA.ORDER_CATEGORY_CODE = 'ORDER'
                AND CO.STATUS = 'A'
                AND ACCO.STATUS = 'A'
                AND OC.SITE_USE_CODE = 'SHIP_TO'
                AND (   (    NVL (P_EMPRESA, 0) = 1
                         AND OHA.SALES_CHANNEL_CODE IN
                                ('1', '2', '4', '23', '11', '25', '5', '7'))
                     OR (    NVL (P_EMPRESA, 0) <> 1
                         AND OHA.SALES_CHANNEL_CODE IN ('101', '102', '105')))
                AND ACCO.CUST_ACCOUNT_ID = p_account_id;


      CURSOR c_client (
         p_account_id   IN NUMBER,
         p_empresa      IN NUMBER)
      IS
           -- Dados gerais do clientes e contabilização dos dados de quantidade de pedidos nos ultimos 24meses
           SELECT CO.GLOBAL_ATTRIBUTE8 TIPO_CONTRIBUINTE,
                  --PA.PARTY_NUMBER,
                  PA.PARTY_ID,
                  MAX (OHA.HEADER_ID) LAST_OV
             FROM OE_ORDER_HEADERS_ALL OHA
                  INNER JOIN HZ_CUST_SITE_USES_ALL OC
                     ON OHA.SHIP_TO_ORG_ID = OC.SITE_USE_ID
                  INNER JOIN HZ_CUST_ACCT_SITES_ALL CO
                     ON OC.CUST_ACCT_SITE_ID = CO.CUST_ACCT_SITE_ID
                  INNER JOIN HZ_CUST_ACCOUNTS ACCO
                     ON CO.CUST_ACCOUNT_ID = ACCO.CUST_ACCOUNT_ID
                  INNER JOIN HZ_PARTIES PA
                     ON ACCO.PARTY_ID = PA.PARTY_ID
            --INNER JOIN RA_TERMS COND ON OHA.PAYMENT_TERM_ID = COND.TERM_ID
            WHERE     OHA.CANCELLED_FLAG = 'N'
                  AND OHA.ORDER_CATEGORY_CODE = 'ORDER'
                  AND CO.STATUS = 'A'
                  AND ACCO.STATUS = 'A'
                  AND ACCO.CUST_ACCOUNT_ID = p_account_id
                  AND OC.SITE_USE_CODE = 'SHIP_TO'
                  --AND OHA.ORDERED_DATE >= ADD_MONTHS(sysdate,-24)
                  AND (   (    NVL (P_EMPRESA, 0) = 1
                           AND OHA.SALES_CHANNEL_CODE IN
                                  ('1', '2', '4', '23', '11', '25', '5', '7'))
                       OR (    NVL (P_EMPRESA, 0) <> 1
                           AND OHA.SALES_CHANNEL_CODE IN ('101', '102', '105')))
         --057158859
         GROUP BY CO.GLOBAL_ATTRIBUTE8,
                  ACCO.CUST_ACCOUNT_ID,
                  PA.PARTY_ID,
                  PA.PARTY_NAME;

      CURSOR c_qtd (
         p_account_id   IN NUMBER,
         p_empresa      IN NUMBER)
      IS
         -- Dados gerais do clientes e contabilização dos dados de quantidade de pedidos nos ultimos 24meses
         SELECT COUNT (1) QTD_PEDIDO,
                TRUNC (SYSDATE - MIN (OHA.ORDERED_DATE)) QTD_DIAS
           FROM OE_ORDER_HEADERS_ALL OHA
                INNER JOIN HZ_CUST_SITE_USES_ALL OC
                   ON OHA.SHIP_TO_ORG_ID = OC.SITE_USE_ID
                INNER JOIN HZ_CUST_ACCT_SITES_ALL CO
                   ON OC.CUST_ACCT_SITE_ID = CO.CUST_ACCT_SITE_ID
                INNER JOIN HZ_CUST_ACCOUNTS ACCO
                   ON CO.CUST_ACCOUNT_ID = ACCO.CUST_ACCOUNT_ID
                INNER JOIN HZ_PARTIES PA
                   ON ACCO.PARTY_ID = PA.PARTY_ID
          --INNER JOIN RA_TERMS COND ON OHA.PAYMENT_TERM_ID = COND.TERM_ID
          WHERE     OHA.CANCELLED_FLAG = 'N'
                AND OHA.ORDER_CATEGORY_CODE = 'ORDER'
                AND CO.STATUS = 'A'
                AND ACCO.STATUS = 'A'
                AND ACCO.CUST_ACCOUNT_ID = p_account_id
                AND OC.SITE_USE_CODE = 'SHIP_TO'
                AND OHA.ORDERED_DATE >= ADD_MONTHS (SYSDATE, -24)
                AND (   (    NVL (P_EMPRESA, 0) = 1
                         AND OHA.SALES_CHANNEL_CODE IN
                                ('1', '2', '4', '23', '11', '25', '5', '7'))
                     OR (    NVL (P_EMPRESA, 0) <> 1
                         AND OHA.SALES_CHANNEL_CODE IN ('101', '102', '105')));


      CURSOR c_last_po (
         p_header_id IN NUMBER)
      IS
         -- Busca os dados da ultima ordem
         SELECT OHA.ORDER_TYPE_ID,
                OHA.ORDER_NUMBER,
                OHA.PAYMENT_TERM_ID,
                OHA.SHIP_TO_ORG_ID,
                OHA.SALES_CHANNEL_CODE,
                OHA.SHIP_FROM_ORG_ID,
                COND.NAME,
                OHA.ORDERED_DATE,
                SALES_CHANNEL_CODE,
                shipping_method_code,
                shipment_priority_code,
                T.carrier_id
           FROM OE_ORDER_HEADERS_ALL OHA
                INNER JOIN RA_TERMS COND
                   ON OHA.PAYMENT_TERM_ID = COND.TERM_ID
                LEFT JOIN WSH_CARRIER_SERVICES T
                   ON T.ship_method_code = shipping_method_code
          WHERE     OHA.CANCELLED_FLAG = 'N'
                AND OHA.ORDER_CATEGORY_CODE = 'ORDER'
                AND OHA.HEADER_ID = p_header_id;

      --AND OHA.ORDERED_DATE >= ADD_MONTHS(sysdate,-24);


      CURSOR c_last_pay (
         p_party_id   IN NUMBER,
         p_empresa    IN NUMBER)
      IS
           SELECT MAX (raa.apply_date) dt_pagamento,
                  MAX (aps.trx_date) dt_emissao
             FROM hz_parties hzp,
                  hz_cust_accounts_all caa,
                  ar_payment_schedules_all aps2,
                  ar_receivable_applications_all raa,
                  ar_payment_schedules_all aps,
                  ar_grupo_cre_marca_evt gcm,
                  ar_analise_cre_cliente_jb acc,
                  hz_cust_accounts_all caa2,
                  hz_cust_site_uses_all hcsua,
                  hz_cust_acct_sites_all hcasa,
                  ra_customer_trx_all racta,
                  hz_parties hzp2
            WHERE     hzp.party_id = caa.party_id
                  AND caa.cust_account_id = acc.id_cust_account
                  AND caa2.cust_account_id = acc.id_centralizador
                  AND hzp2.party_id = caa2.party_id
                  AND aps2.class = 'PMT'
                  AND aps2.payment_schedule_id = raa.payment_schedule_id
                  AND raa.status = 'APP'              -- APP signifca aplicado
                  AND raa.display = 'Y'   -- indica que eh a ultima apliacacao
                  AND raa.applied_payment_schedule_id = aps.payment_schedule_id
                  AND hcsua.site_use_id = aps.CUSTOMER_SITE_USE_ID
                  AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
                  AND racta.customer_trx_id = aps.customer_trx_id
                  --Desconsidera transacoes que nao consome crédito
                  AND NOT EXISTS
                             (SELECT 1
                                FROM ar_param_analise_cre_transc_jb pact
                               WHERE     pact.id_mercado = 'MI'
                                     AND pact.org_id = aps.org_id
                                     AND pact.cust_trx_type_id =
                                            aps.cust_trx_type_id)
                  AND aps.status = 'CL'           --"cl" significa titulo pago
                  AND aps.org_id IN
                         (SELECT org_id
                            FROM ar_grupo_cre_organizacao_jb gco
                           WHERE gco.cd_grupo_credito = acc.cd_grupo_credito)
                  --Identifica o grupo de credito
                  AND aps.gl_date_closed <= (SYSDATE + 1) --forçar a utilização index
                  AND aps.attribute9 = gcm.cd_marca
                  AND aps.customer_id = acc.id_cust_account
                  AND gcm.cd_grupo_credito = acc.cd_grupo_credito
                  AND gcm.cd_grupo_credito = p_empresa
                  AND acc.id_mercado = 'MI'
                  AND HZP.PARTY_ID = p_party_id
                  AND aps.due_date BETWEEN ADD_MONTHS (
                                              TRUNC (SYSDATE, 'month'),
                                              -24)
                                       AND TRUNC (SYSDATE, 'month')
         ORDER BY aps.due_date DESC;


      v_tipo_contribuinte        VARCHAR2 (200);
      v_qtd_pedido               NUMBER;
      v_qtd_dias                 NUMBER;
      v_order_type               NUMBER;
      v_order_number             NUMBER;
      v_endereco                 NUMBER;
      v_channel                  NUMBER;
      --v_dt_payment date;

      v_last_order               DATE;
      v_last_invoice             DATE;
      v_last_payment             DATE;
      v_first_order              DATE;
      v_last_header_id           NUMBER;
      v_default_payment          NUMBER (15);
      v_warehouse                VARCHAR2 (10);
      v_warehouse_descr          VARCHAR2 (100);
      --v_descr_deposito varchar2(100);
      v_descr_payment            VARCHAR2 (15);
      v_puchase_frequency        VARCHAR2 (20);
      v_account_id               NUMBER (15);
      v_party_id                 NUMBER (15);

      v_last_exec                DATE;
      v_last_channel             VARCHAR2 (30);
      v_shipping_method_code     VARCHAR2 (30);
      v_shipment_priority_code   VARCHAR2 (30);
      v_carrier_id               NUMBER (38);
   BEGIN
      --tmpVar := 0;

      IF NVL (p_completa, 0) = 1
      THEN
         DELETE APPS.XXPB_HIST_PO_CLIENT;

         COMMIT;
      END IF;


      SELECT MAX (created_date) - 15 / 1440
        INTO v_last_exec
        FROM apps.XXPB_HIST_PO_CLIENT;

      UPDATE APPS.XXPB_HIST_PO_CLIENT
         SET PROCESSED = 0;



      FOR p
         IN (  SELECT ACCO.CUST_ACCOUNT_ID
                 FROM OE_ORDER_HEADERS_ALL OHA
                      INNER JOIN HZ_CUST_SITE_USES_ALL OC
                         ON OHA.SHIP_TO_ORG_ID = OC.SITE_USE_ID
                      INNER JOIN HZ_CUST_ACCT_SITES_ALL CO
                         ON OC.CUST_ACCT_SITE_ID = CO.CUST_ACCT_SITE_ID
                      INNER JOIN HZ_CUST_ACCOUNTS ACCO
                         ON CO.CUST_ACCOUNT_ID = ACCO.CUST_ACCOUNT_ID
                WHERE     OHA.CANCELLED_FLAG = 'N'
                      AND oha.booked_flag = 'Y'
                      AND OHA.ORDER_CATEGORY_CODE = 'ORDER'
                      AND (   NVL (p_completa, 0) = 1
                           OR (    NVL (p_completa, 0) = 0
                               AND OHA.ORDERED_DATE >=
                                      NVL (v_last_exec, SYSDATE - 7)))
                      AND OHA.SALES_CHANNEL_CODE IN
                             ('1',
                              '2',
                              '101',
                              '102',
                              '105',
                              '23',
                              '11',
                              '25',
                              '5',
                              '7')
                      AND ACCO.STATUS = 'A'
                      AND ACCO.SALES_CHANNEL_CODE IS NOT NULL
                      AND CO.GLOBAL_ATTRIBUTE3 IS NOT NULL
                      AND NVL (CO.LANGUAGE, 'PTB') IN ('PTB', 'US')
                      AND CO.STATUS = 'A'
                      AND CO.GLOBAL_ATTRIBUTE8 IS NOT NULL
             --AND ACCO.ACCOUNT_NUMBER = '057158859'
             --AND ROWNUM < 1001
             GROUP BY ACCO.CUST_ACCOUNT_ID)
      LOOP
         --tmpVar := tmpVar + 1;
         v_account_id := p.cust_account_id;

         DELETE APPS.XXPB_HIST_PO_CLIENT
          WHERE CUST_ACCOUNT_ID = v_account_id;

         COMMIT;

         v_party_id := 0;
         v_default_payment := 0;
         v_descr_payment := NULL;
         v_last_header_id := 0;
         v_last_order := NULL;
         v_last_invoice := NULL;
         v_last_payment := NULL;
         v_first_order := NULL;
         v_warehouse := NULL;
         v_warehouse_descr := NULL;
         v_puchase_frequency := NULL;
         v_qtd_pedido := 0;
         v_qtd_dias := 0;
         v_last_channel := NULL;

         --Bloco de dados da Portobello
         OPEN c_first_po (v_account_id, 1);

         FETCH c_first_po INTO v_first_order;

         CLOSE c_first_po;

         IF v_first_order IS NOT NULL
         THEN
            OPEN c_client (v_account_id, 1);

            FETCH c_client
            INTO v_tipo_contribuinte, v_party_id, v_last_header_id;

            CLOSE c_client;

            OPEN c_qtd (v_account_id, 1);

            FETCH c_qtd
            INTO v_qtd_pedido, v_qtd_dias;

            CLOSE c_qtd;

            OPEN c_last_po (v_last_header_id);

            FETCH c_last_po
            INTO v_order_type,
                 v_order_number,
                 v_default_payment,
                 v_endereco,
                 v_channel,
                 v_warehouse,
                 v_descr_payment,
                 v_last_order,
                 v_last_channel,
                 v_shipping_method_code,
                 v_shipment_priority_code,
                 v_carrier_id;

            CLOSE c_last_po;

            OPEN c_last_pay (v_party_id, 1);

            FETCH c_last_pay
            INTO v_last_payment, v_last_invoice;

            CLOSE c_last_pay;

            --Cálculo de frequencia -- v_qtd_pedido / v_qtd_dias
            --Classificação    730 a 366 Dias           365 as 6 meses      Abaixo de 6 meses
            --Diaria           Acima de 250 Pedidos     Acima de 125        Acima e 60
            --Semanal          Entre 36 e 250 Pedidos   Entre 16 e 125      Entre 7 e 59
            --Mensal           Entre 19 e 35 Pedidos    Entre 9 e 15        Entre 4 e 6
            --Bimestral        Entre 7 e 18 Pedidos     Entre 3 e 8         Entre 2 e 3
            --Semestral        Entre 3 e 6 Pedidos      Igual a 2           Igual a 1
            --Anual            Entre 2 e 3 Pedidos      Igual a 1           -
            --Eventual         1 ou 0 Pedidos           -                   -


            v_puchase_frequency := 'Eventualy';

            IF v_qtd_dias > 365
            THEN
               IF v_qtd_pedido > 250
               THEN
                  v_puchase_frequency := 'Daily';
               END IF;

               IF v_qtd_pedido BETWEEN 36 AND 249
               THEN
                  v_puchase_frequency := 'Weekly';
               END IF;

               IF v_qtd_pedido BETWEEN 19 AND 35
               THEN
                  v_puchase_frequency := 'Monthly';
               END IF;

               IF v_qtd_pedido BETWEEN 7 AND 18
               THEN
                  v_puchase_frequency := 'BiMonthly';
               END IF;

               IF v_qtd_pedido BETWEEN 3 AND 6
               THEN
                  v_puchase_frequency := 'Semester';
               END IF;

               IF v_qtd_pedido BETWEEN 2 AND 3
               THEN
                  v_puchase_frequency := 'Yearly';
               END IF;
            END IF;

            IF v_qtd_dias BETWEEN 183 AND 365
            THEN
               IF v_qtd_pedido > 125
               THEN
                  v_puchase_frequency := 'Daily';
               END IF;

               IF v_qtd_pedido BETWEEN 16 AND 125
               THEN
                  v_puchase_frequency := 'Weekly';
               END IF;

               IF v_qtd_pedido BETWEEN 9 AND 15
               THEN
                  v_puchase_frequency := 'Monthly';
               END IF;

               IF v_qtd_pedido BETWEEN 3 AND 8
               THEN
                  v_puchase_frequency := 'BiMonthly';
               END IF;

               IF v_qtd_pedido = 2
               THEN
                  v_puchase_frequency := 'Semester';
               END IF;

               IF v_qtd_pedido = 1
               THEN
                  v_puchase_frequency := 'Yearly';
               END IF;
            END IF;

            IF v_qtd_dias < 183
            THEN
               IF v_qtd_pedido > 60
               THEN
                  v_puchase_frequency := 'Daily';
               END IF;

               IF v_qtd_pedido BETWEEN 7 AND 59
               THEN
                  v_puchase_frequency := 'Weekly';
               END IF;

               IF v_qtd_pedido BETWEEN 4 AND 6
               THEN
                  v_puchase_frequency := 'Monthly';
               END IF;

               IF v_qtd_pedido BETWEEN 2 AND 3
               THEN
                  v_puchase_frequency := 'BiMonthly';
               END IF;

               IF v_qtd_pedido = 1
               THEN
                  v_puchase_frequency := 'Semester';
               END IF;
            END IF;


            IF v_warehouse NOT IN
                  ('1717',
                   '1716',
                   '1759',
                   '1761',
                   '1819',
                   '1860',
                   '1881',
                   '1940',
                   '1960',
                   '1980',
                   '1981',
                   '1982',
                   '1719',
                   '1986',
                   '2006',
                   '2066',
                   '1900')
            THEN
               v_warehouse := '1719';
            END IF;

            v_warehouse_descr :=
               CASE v_warehouse
                  WHEN '1717' THEN 'P11'
                  WHEN '1716' THEN 'PUC'
                  WHEN '1719' THEN 'EET'
                  WHEN '1759' THEN 'PNT'
                  WHEN '1761' THEN 'PPB'
                  WHEN '1819' THEN 'PMA'
                  WHEN '1860' THEN 'EEM'
                  WHEN '1881' THEN 'PPE'
                  WHEN '1940' THEN 'CDC'
                  WHEN '1960' THEN 'CWB'
                  WHEN '1980' THEN 'CSA'
                  WHEN '1981' THEN 'CIT'
                  WHEN '1982' THEN 'EEA'
                  WHEN '1986' THEN 'CFR'
                  WHEN '2006' THEN 'CGO'
                  WHEN '2066' THEN 'CPR'
                  WHEN '1900' THEN 'CJU'
                  ELSE 'EET'
               END;

            INSERT INTO APPS.XXPB_HIST_PO_CLIENT (CREATED_DATE,
                                                  LAST_UPDATE_DATE,
                                                  CUST_ACCOUNT_ID,
                                                  PARTY_ID,
                                                  DEFAULT_PAYMENT,
                                                  DESCR_PAYMENT,
                                                  LAST_HEADER_ID,
                                                  LAST_ORDER,
                                                  LAST_INVOICE,
                                                  LAST_PAYMENT,
                                                  FIRST_ORDER,
                                                  WAREHOUSE,
                                                  DESCR_WAREHOUSE,
                                                  PURCHASE_FREQUENCY,
                                                  QTD_OV,
                                                  QTD_DAY,
                                                  BRAND,
                                                  STATUS,
                                                  PROCESSED,
                                                  SALES_CHANNEL,
                                                  SHIPPING_METHOD_CODE,
                                                  SHIPMENT_PRIORITY_CODE,
                                                  CARRIER_ID)
                 VALUES (SYSDATE,
                         SYSDATE,
                         v_account_id,
                         v_party_id,
                         v_default_payment,
                         v_descr_payment,
                         v_last_header_id,
                         v_last_order,
                         v_last_invoice,
                         v_last_payment,
                         v_first_order,
                         v_warehouse,
                         v_warehouse_descr,
                         v_puchase_frequency,
                         v_qtd_pedido,
                         v_qtd_dias,
                         'Portobello',
                         'A',
                         1,
                         v_last_channel,
                         v_shipping_method_code,
                         v_shipment_priority_code,
                         v_carrier_id);

            COMMIT;
         END IF;

         v_party_id := 0;
         v_default_payment := 0;
         v_descr_payment := NULL;
         v_last_header_id := 0;
         v_last_order := NULL;
         v_last_invoice := NULL;
         v_last_payment := NULL;
         v_first_order := NULL;
         v_warehouse := NULL;
         v_warehouse_descr := NULL;
         v_puchase_frequency := NULL;
         v_qtd_pedido := 0;
         v_qtd_dias := 0;
         v_last_channel := NULL;

         --Bloco de dados da Pointer
         OPEN c_first_po (v_account_id, 2);

         FETCH c_first_po INTO v_first_order;

         CLOSE c_first_po;

         IF v_first_order IS NOT NULL
         THEN
            OPEN c_client (v_account_id, 2);

            FETCH c_client
            INTO v_tipo_contribuinte, v_party_id, v_last_header_id;

            CLOSE c_client;

            OPEN c_qtd (v_account_id, 2);

            FETCH c_qtd
            INTO v_qtd_pedido, v_qtd_dias;

            CLOSE c_qtd;

            OPEN c_last_po (v_last_header_id);

            FETCH c_last_po
            INTO v_order_type,
                 v_order_number,
                 v_default_payment,
                 v_endereco,
                 v_channel,
                 v_warehouse,
                 v_descr_payment,
                 v_last_order,
                 v_last_channel,
                 v_shipping_method_code,
                 v_shipment_priority_code,
                 v_carrier_id;

            CLOSE c_last_po;

            OPEN c_last_pay (v_party_id, 2);

            FETCH c_last_pay
            INTO v_last_payment, v_last_invoice;

            CLOSE c_last_pay;

            --Cálculo de frequencia -- v_qtd_pedido / v_qtd_dias
            --Classificação    730 a 366 Dias           365 as 6 meses      Abaixo de 6 meses
            --Diaria           Acima de 250 Pedidos     Acima de 125        Acima e 60
            --Semanal          Entre 36 e 250 Pedidos   Entre 16 e 125      Entre 7 e 59
            --Mensal           Entre 19 e 35 Pedidos    Entre 9 e 15        Entre 4 e 6
            --Bimestral        Entre 7 e 18 Pedidos     Entre 3 e 8         Entre 2 e 3
            --Semestral        Entre 3 e 6 Pedidos      Igual a 2           Igual a 1
            --Anual            Entre 2 e 3 Pedidos      Igual a 1           -
            --Eventual         1 ou 0 Pedidos           -                   -


            v_puchase_frequency := 'Eventualy';

            IF v_qtd_dias > 365
            THEN
               IF v_qtd_pedido > 250
               THEN
                  v_puchase_frequency := 'Daily';
               END IF;

               IF v_qtd_pedido BETWEEN 36 AND 250
               THEN
                  v_puchase_frequency := 'Weekly';
               END IF;

               IF v_qtd_pedido BETWEEN 19 AND 35
               THEN
                  v_puchase_frequency := 'Monthly';
               END IF;

               IF v_qtd_pedido BETWEEN 7 AND 18
               THEN
                  v_puchase_frequency := 'BiMonthly';
               END IF;

               IF v_qtd_pedido BETWEEN 3 AND 6
               THEN
                  v_puchase_frequency := 'Semester';
               END IF;

               IF v_qtd_pedido BETWEEN 2 AND 3
               THEN
                  v_puchase_frequency := 'Yearly';
               END IF;
            END IF;

            IF v_qtd_dias BETWEEN 183 AND 365
            THEN
               IF v_qtd_pedido > 125
               THEN
                  v_puchase_frequency := 'Daily';
               END IF;

               IF v_qtd_pedido BETWEEN 16 AND 125
               THEN
                  v_puchase_frequency := 'Weekly';
               END IF;

               IF v_qtd_pedido BETWEEN 9 AND 15
               THEN
                  v_puchase_frequency := 'Monthly';
               END IF;

               IF v_qtd_pedido BETWEEN 3 AND 8
               THEN
                  v_puchase_frequency := 'BiMonthly';
               END IF;

               IF v_qtd_pedido = 2
               THEN
                  v_puchase_frequency := 'Semester';
               END IF;

               IF v_qtd_pedido = 1
               THEN
                  v_puchase_frequency := 'Yearly';
               END IF;
            END IF;

            IF v_qtd_dias < 183
            THEN
               IF v_qtd_pedido > 60
               THEN
                  v_puchase_frequency := 'Daily';
               END IF;

               IF v_qtd_pedido BETWEEN 7 AND 59
               THEN
                  v_puchase_frequency := 'Weekly';
               END IF;

               IF v_qtd_pedido BETWEEN 4 AND 6
               THEN
                  v_puchase_frequency := 'Monthly';
               END IF;

               IF v_qtd_pedido BETWEEN 2 AND 3
               THEN
                  v_puchase_frequency := 'BiMonthly';
               END IF;

               IF v_qtd_pedido = 1
               THEN
                  v_puchase_frequency := 'Semester';
               END IF;
            END IF;


            IF v_warehouse NOT IN
                  ('1717',
                   '1716',
                   '1759',
                   '1761',
                   '1819',
                   '1860',
                   '1881',
                   '1940',
                   '1960',
                   '1980',
                   '1981',
                   '1982',
                   '1719',
                   '1986',
                   '2006',
                   '2066',
                   '1900')
            THEN
               v_warehouse := '1982';
            END IF;

            v_warehouse_descr :=
               CASE v_warehouse
                  WHEN '1717' THEN 'P11'
                  WHEN '1716' THEN 'PUC'
                  WHEN '1719' THEN 'EET'
                  WHEN '1759' THEN 'PNT'
                  WHEN '1761' THEN 'PPB'
                  WHEN '1819' THEN 'PMA'
                  WHEN '1860' THEN 'EEM'
                  WHEN '1881' THEN 'PPE'
                  WHEN '1940' THEN 'CDC'
                  WHEN '1960' THEN 'CWB'
                  WHEN '1980' THEN 'CSA'
                  WHEN '1981' THEN 'CIT'
                  WHEN '1982' THEN 'EEA'
                  WHEN '1986' THEN 'CFR'
                  WHEN '2006' THEN 'CGO'
                  WHEN '2066' THEN 'CPR'
                  WHEN '1900' THEN 'CJU'
                  ELSE 'EEA'
               END;

            INSERT INTO APPS.XXPB_HIST_PO_CLIENT (CREATED_DATE,
                                                  LAST_UPDATE_DATE,
                                                  CUST_ACCOUNT_ID,
                                                  PARTY_ID,
                                                  DEFAULT_PAYMENT,
                                                  DESCR_PAYMENT,
                                                  LAST_HEADER_ID,
                                                  LAST_ORDER,
                                                  LAST_INVOICE,
                                                  LAST_PAYMENT,
                                                  FIRST_ORDER,
                                                  WAREHOUSE,
                                                  DESCR_WAREHOUSE,
                                                  PURCHASE_FREQUENCY,
                                                  QTD_OV,
                                                  QTD_DAY,
                                                  BRAND,
                                                  STATUS,
                                                  PROCESSED,
                                                  SALES_CHANNEL,
                                                  SHIPPING_METHOD_CODE,
                                                  SHIPMENT_PRIORITY_CODE,
                                                  CARRIER_ID)
                 VALUES (SYSDATE,
                         SYSDATE,
                         v_account_id,
                         v_party_id,
                         v_default_payment,
                         v_descr_payment,
                         v_last_header_id,
                         v_last_order,
                         v_last_invoice,
                         v_last_payment,
                         v_first_order,
                         v_warehouse,
                         v_warehouse_descr,
                         v_puchase_frequency,
                         v_qtd_pedido,
                         v_qtd_dias,
                         'Pointer',
                         'A',
                         1,
                         v_last_channel,
                         v_shipping_method_code,
                         v_shipment_priority_code,
                         v_carrier_id);

            COMMIT;
         END IF;
      END LOOP;

      UPDATE APPS.XXPB_HIST_PO_CLIENT
         SET QTD_DAY = TRUNC (SYSDATE - LAST_ORDER)
       WHERE NVL (PROCESSED, 0) = 0;

      UPDATE APPS.XXPB_HIST_PO_CLIENT X
         SET STATUS = 'I'
       WHERE     NVL (PROCESSED, 0) = 0
             AND NOT EXISTS
                        (  SELECT ACCO.CUST_ACCOUNT_ID
                             FROM OE_ORDER_HEADERS_ALL OHA
                                  INNER JOIN HZ_CUST_SITE_USES_ALL OC
                                     ON OHA.SHIP_TO_ORG_ID = OC.SITE_USE_ID
                                  INNER JOIN HZ_CUST_ACCT_SITES_ALL CO
                                     ON OC.CUST_ACCT_SITE_ID =
                                           CO.CUST_ACCT_SITE_ID
                                  INNER JOIN HZ_CUST_ACCOUNTS ACCO
                                     ON CO.CUST_ACCOUNT_ID =
                                           ACCO.CUST_ACCOUNT_ID
                            WHERE     OHA.CANCELLED_FLAG = 'N'
                                  AND oha.booked_flag = 'Y'
                                  AND OHA.ORDER_CATEGORY_CODE = 'ORDER'
                                  AND OHA.ORDERED_DATE >=
                                         ADD_MONTHS (SYSDATE, -24)
                                  AND OHA.SALES_CHANNEL_CODE IN
                                         ('1',
                                          '2',
                                          '101',
                                          '102',
                                          '105',
                                          '23',
                                          '11',
                                          '25',
                                          '5',
                                          '7')
                                  AND ACCO.STATUS = 'A'
                                  AND ACCO.SALES_CHANNEL_CODE IS NOT NULL
                                  AND CO.GLOBAL_ATTRIBUTE3 IS NOT NULL
                                  AND NVL (CO.LANGUAGE, 'PTB') IN ('PTB', 'US')
                                  AND CO.STATUS = 'A'
                                  AND CO.GLOBAL_ATTRIBUTE8 IS NOT NULL
                                  AND ACCO.CUST_ACCOUNT_ID = X.CUST_ACCOUNT_ID
                         GROUP BY ACCO.CUST_ACCOUNT_ID);

      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END p_gera_dados_cli_po;
END PB_INTEGRA_SALESFORCE;

GRANT EXECUTE ON APPS.PB_INTEGRA_SALESFORCE TO APPSR;