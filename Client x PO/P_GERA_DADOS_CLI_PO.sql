CREATE OR REPLACE PROCEDURE APPS.p_gera_dados_cli_po (completa IN INT, errbuf  IN  VARCHAR2,errcode IN  VARCHAR2) IS
    tmpVar NUMBER;
/******************************************************************************
   NAME:       p_gera_dados_cli_po
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        17/12/2021   Guilherme Rodrigues       1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     p_gera_dados_cli_po
      Sysdate:         17/12/2021
      Date and Time:   17/12/2021, 08:53:02, and 17/12/2021 08:53:02
      Username:        guilherme.rodrigues (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/

    CURSOR c_first_po (p_account_id IN NUMBER, p_empresa IN NUMBER) IS    
    -- Busca a primeira ordem do cliente (não considera os 2 anos)
    SELECT MIN(OHA.ORDERED_DATE) FIRST_DATE
      FROM OE_ORDER_HEADERS_ALL OHA
           INNER JOIN HZ_CUST_SITE_USES_ALL OC
              ON OHA.SHIP_TO_ORG_ID = OC.SITE_USE_ID
           INNER JOIN HZ_CUST_ACCT_SITES_ALL CO
              ON OC.CUST_ACCT_SITE_ID = CO.CUST_ACCT_SITE_ID
           INNER JOIN HZ_CUST_ACCOUNTS ACCO
              ON CO.CUST_ACCOUNT_ID = ACCO.CUST_ACCOUNT_ID
     WHERE OHA.CANCELLED_FLAG = 'N' 
     AND OHA.ORDER_CATEGORY_CODE = 'ORDER' 
     AND CO.STATUS = 'A'
     AND ACCO.STATUS = 'A'
     AND OC.SITE_USE_CODE = 'SHIP_TO'
     AND (
        (NVL(P_EMPRESA,0) = 1 AND OHA.SALES_CHANNEL_CODE IN('1','2','4','23','25'))
        OR
        (NVL(P_EMPRESA,0) <> 1 AND OHA.SALES_CHANNEL_CODE IN('101','102'))
        ) 
     AND ACCO.CUST_ACCOUNT_ID = p_account_id;
     
     
    CURSOR c_client (p_account_id IN NUMBER, p_empresa IN NUMBER) IS 
    -- Dados gerais do clientes e contabilização dos dados de quantidade de pedidos nos ultimos 24meses
    SELECT CO.GLOBAL_ATTRIBUTE8 TIPO_CONTRIBUINTE,
           --PA.PARTY_NUMBER,
           PA.PARTY_ID, 
           MAX(OHA.HEADER_ID) LAST_OV,
           COUNT(1) QTD_PEDIDO,
           TRUNC(SYSDATE - MIN(OHA.ORDERED_DATE)) QTD_DIAS       
      FROM OE_ORDER_HEADERS_ALL OHA
           INNER JOIN HZ_CUST_SITE_USES_ALL OC
              ON OHA.SHIP_TO_ORG_ID = OC.SITE_USE_ID
           INNER JOIN HZ_CUST_ACCT_SITES_ALL CO
              ON OC.CUST_ACCT_SITE_ID = CO.CUST_ACCT_SITE_ID
           INNER JOIN HZ_CUST_ACCOUNTS ACCO
              ON CO.CUST_ACCOUNT_ID = ACCO.CUST_ACCOUNT_ID
           INNER JOIN HZ_PARTIES PA ON ACCO.PARTY_ID = PA.PARTY_ID
           --INNER JOIN RA_TERMS COND ON OHA.PAYMENT_TERM_ID = COND.TERM_ID  
     WHERE OHA.CANCELLED_FLAG = 'N' 
     AND OHA.ORDER_CATEGORY_CODE = 'ORDER' 
     AND CO.STATUS = 'A'
     AND ACCO.STATUS = 'A'
     AND ACCO.CUST_ACCOUNT_ID = p_account_id
     AND OC.SITE_USE_CODE = 'SHIP_TO'
     --AND OHA.ORDERED_DATE >= ADD_MONTHS(sysdate,-24)
     AND (
        (NVL(P_EMPRESA,0) = 1 AND OHA.SALES_CHANNEL_CODE IN('1','2','4','23','25'))
        OR
        (NVL(P_EMPRESA,0) <> 1 AND OHA.SALES_CHANNEL_CODE IN('101','102'))
        ) 
     --057158859
    GROUP BY CO.GLOBAL_ATTRIBUTE8, ACCO.CUST_ACCOUNT_ID, PA.PARTY_ID, PA.PARTY_NAME;

    CURSOR c_last_po (p_header_id IN NUMBER) IS
    -- Busca os dados da ultima ordem
    SELECT OHA.ORDER_TYPE_ID, OHA.ORDER_NUMBER, OHA.PAYMENT_TERM_ID, OHA.SHIP_TO_ORG_ID, OHA.SALES_CHANNEL_CODE, OHA.SHIP_FROM_ORG_ID,
           COND.NAME, OHA.ORDERED_DATE
      FROM OE_ORDER_HEADERS_ALL OHA
           INNER JOIN RA_TERMS COND ON OHA.PAYMENT_TERM_ID = COND.TERM_ID  
     WHERE OHA.CANCELLED_FLAG = 'N' 
     AND OHA.ORDER_CATEGORY_CODE = 'ORDER' 
     AND OHA.HEADER_ID = p_header_id;
     --AND OHA.ORDERED_DATE >= ADD_MONTHS(sysdate,-24);
     
     
     CURSOR c_last_pay(p_party_id IN NUMBER, p_empresa IN NUMBER) is
                SELECT 
                MAX(raa.apply_date)                          dt_pagamento,
                MAX(aps.trx_date)                            dt_emissao
                  FROM hz_parties                     hzp,
                       hz_cust_accounts_all           caa,
                       ar_payment_schedules_all       aps2,
                       ar_receivable_applications_all raa,
                       ar_payment_schedules_all       aps,
                       ar_grupo_cre_marca_evt         gcm,
                       ar_analise_cre_cliente_jb      acc,
                       hz_cust_accounts_all           caa2,
                       hz_cust_site_uses_all          hcsua,
                       hz_cust_acct_sites_all         hcasa,
                       ra_customer_trx_all            racta,
                       hz_parties                     hzp2
                  WHERE hzp.party_id                    = caa.party_id
                  AND   caa.cust_account_id             = acc.id_cust_account
                  AND caa2.cust_account_id = acc.id_centralizador
                  AND hzp2.party_id = caa2.party_id
                  AND   aps2.class                      = 'PMT'
                  AND   aps2.payment_schedule_id        = raa.payment_schedule_id
                  AND   raa.status                      = 'APP'  -- APP signifca aplicado
                  AND   raa.display                     = 'Y'    -- indica que eh a ultima apliacacao
                  AND   raa.applied_payment_schedule_id = aps.payment_schedule_id
                  AND   hcsua.site_use_id               = aps.CUSTOMER_SITE_USE_ID
                  AND   hcasa.cust_acct_site_id         = hcsua.cust_acct_site_id
                  AND   racta.customer_trx_id           = aps.customer_trx_id
                  --Desconsidera transacoes que nao consome crédito
                  AND   not exists                     (SELECT 1
                                                        FROM   ar_param_analise_cre_transc_jb pact
                                                        WHERE  pact.id_mercado       = 'MI'
                                                        AND    pact.org_id           = aps.org_id
                                                        AND    pact.cust_trx_type_id = aps.cust_trx_type_id)
                  AND   aps.status                      = 'CL'    --"cl" significa titulo pago
                  AND   aps.org_id                    IN (SELECT org_id FROM ar_grupo_cre_organizacao_jb gco
                                                          WHERE gco.cd_grupo_credito = acc.cd_grupo_credito)
                  --Identifica o grupo de credito
                  AND   aps.gl_date_closed             <= (SYSDATE + 1) --forçar a utilização index
                  AND   aps.attribute9                  = gcm.cd_marca
                  AND   aps.customer_id                 = acc.id_cust_account
                  AND   gcm.cd_grupo_credito            = acc.cd_grupo_credito
                  AND   gcm.cd_grupo_credito            = p_empresa
                  AND   acc.id_mercado                  = 'MI'
                  AND   HZP.PARTY_ID = p_party_id
                  AND   aps.due_date BETWEEN add_months(trunc(sysdate, 'month'), -24) and trunc(sysdate, 'month')
            order by aps.due_date desc;
            
     
     v_tipo_contribuinte varchar2(200);
     v_qtd_pedido number;
     v_qtd_dias number;
     v_order_type number;
     v_order_number number;
     v_endereco number;
     v_channel number;
     --v_dt_payment date;
     
     v_last_order date;
     v_last_invoice date;
     v_last_payment date;
     v_first_order date;
     v_last_header_id number;
     v_default_payment number(15);
     v_warehouse varchar2(10);
     v_warehouse_descr varchar2(100);
     --v_descr_deposito varchar2(100);
     v_descr_payment varchar2(15);
     v_puchase_frequency varchar2(20);
     v_account_id NUMBER(15);
     v_party_id NUMBER(15);
       


     

BEGIN
    tmpVar := 0;
    
    IF NVL(completa,0) = 1 THEN 
        DELETE APPS.XXPB_HIST_PO_CLIENT;
        COMMIT;
    END IF;

    for p in (SELECT ACCO.CUST_ACCOUNT_ID
                  FROM OE_ORDER_HEADERS_ALL OHA
                       INNER JOIN HZ_CUST_SITE_USES_ALL OC
                          ON OHA.SHIP_TO_ORG_ID = OC.SITE_USE_ID
                       INNER JOIN HZ_CUST_ACCT_SITES_ALL CO
                          ON OC.CUST_ACCT_SITE_ID = CO.CUST_ACCT_SITE_ID
                       INNER JOIN HZ_CUST_ACCOUNTS ACCO
                          ON CO.CUST_ACCOUNT_ID = ACCO.CUST_ACCOUNT_ID
                 WHERE OHA.CANCELLED_FLAG = 'N'
                 AND   oha.booked_flag                       = 'Y'
                 AND OHA.ORDER_CATEGORY_CODE = 'ORDER' 
                 AND (NVL(completa,0) = 1 OR (NVL(completa,0) = 1 AND OHA.ORDERED_DATE >= ADD_MONTHS(sysdate,-24)))
                 AND OHA.SALES_CHANNEL_CODE IN('1','2','101','102','23','25')
                 AND ACCO.STATUS = 'A'
                 AND ACCO.SALES_CHANNEL_CODE IS NOT NULL
                 AND CO.GLOBAL_ATTRIBUTE3 IS NOT NULL
                 AND nvl(CO.LANGUAGE, 'PTB') IN ('PTB', 'US')
                 AND CO.STATUS = 'A'
                 AND CO.GLOBAL_ATTRIBUTE8 IS NOT NULL
                 --AND ACCO.ACCOUNT_NUMBER = '057158859'
                 --AND ROWNUM < 1001
                GROUP BY ACCO.CUST_ACCOUNT_ID) loop
                
            tmpVar := tmpVar + 1;            
            v_account_id := p.cust_account_id;
            
            DELETE APPS.XXPB_HIST_PO_CLIENT WHERE CUST_ACCOUNT_ID = v_account_id;
            COMMIT;


            v_party_id := 0;
            v_default_payment := 0;
            v_descr_payment := null;
            v_last_header_id := 0;
            v_last_order := null;
            v_last_invoice := null;
            v_last_payment := null;
            v_first_order := null;
            v_warehouse := null;
            v_warehouse_descr := null;            
            v_puchase_frequency := null;
            v_qtd_pedido := 0;
            v_qtd_dias := 0;
            --Bloco de dados da Portobello
            OPEN c_first_po(v_account_id, 1);
            FETCH c_first_po
            INTO v_first_order;
            CLOSE c_first_po;    
            if v_first_order is not null then 
                OPEN c_client(v_account_id,1);
                FETCH c_client
                INTO v_tipo_contribuinte,
                     v_party_id,
                     v_last_header_id,
                     v_qtd_pedido,
                     v_qtd_dias;
                CLOSE c_client;

                OPEN c_last_po(v_last_header_id);
                FETCH c_last_po
                INTO v_order_type, v_order_number, v_default_payment, v_endereco, v_channel, v_warehouse, v_descr_payment, v_last_order;
                CLOSE c_last_po;
                                  
                OPEN c_last_pay(v_party_id, 1);
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

               if v_qtd_dias > 365 then
                    IF v_qtd_pedido > 250 then
                        v_puchase_frequency := 'Daily';        
                    end if;
                    IF v_qtd_pedido between 36 and 250  then
                        v_puchase_frequency := 'Weekly';        
                    end if;
                    IF v_qtd_pedido between 19 and 35 then
                        v_puchase_frequency := 'Monthly';        
                    end if;
                    IF v_qtd_pedido between 7 and 18 then
                        v_puchase_frequency := 'BiMonthly';        
                    end if;
                    IF v_qtd_pedido between 3 and 6  then
                        v_puchase_frequency := 'Semester';        
                    end if;
                    IF v_qtd_pedido between 2 and 3 then
                        v_puchase_frequency := 'Yearly';        
                    end if;
                end if;

                if v_qtd_dias between 183 and 250 then
                    IF v_qtd_pedido > 125 then
                        v_puchase_frequency := 'Daily';        
                    end if;
                    IF v_qtd_pedido between 16 and 125  then
                        v_puchase_frequency := 'Weekly';        
                    end if;
                    IF v_qtd_pedido between 9 and 15 then
                        v_puchase_frequency := 'Monthly';        
                    end if;
                    IF v_qtd_pedido between 3 and 8 then
                        v_puchase_frequency := 'BiMonthly';        
                    end if;
                    IF v_qtd_pedido = 2 then
                        v_puchase_frequency := 'Semester';        
                    end if;
                    IF v_qtd_pedido = 1 then
                        v_puchase_frequency := 'Yearly';        
                    end if;
                end if;
                
                if v_qtd_dias < 183 then
                    IF v_qtd_pedido > 60 then
                        v_puchase_frequency := 'Daily';        
                    end if;
                    IF v_qtd_pedido between 7 and 59  then
                        v_puchase_frequency := 'Weekly';        
                    end if;
                    IF v_qtd_pedido between 4 and 6 then
                        v_puchase_frequency := 'Monthly';        
                    end if;
                    IF v_qtd_pedido between 2 and 3 then
                        v_puchase_frequency := 'Bimestral';        
                    end if;
                    IF v_qtd_pedido = 1 then
                        v_puchase_frequency := 'Semester';        
                    end if;
                end if;


                if v_warehouse not in('1717','1716','1759','1761','1819','1860','1881','1940','1960','1980','1981','1982','1719','1986','2006','2066','1900') then 
                    v_warehouse := '1719';                
                end if;
                
                v_warehouse_descr := CASE v_warehouse
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
              
                INSERT INTO APPS.XXPB_HIST_PO_CLIENT 
                (CREATED_DATE, LAST_UPDATE_DATE, CUST_ACCOUNT_ID, 
                PARTY_ID, DEFAULT_PAYMENT, DESCR_PAYMENT, 
                LAST_HEADER_ID, LAST_ORDER, LAST_INVOICE, LAST_PAYMENT, FIRST_ORDER, 
                WAREHOUSE, DESCR_WAREHOUSE, PURCHASE_FREQUENCY,
                QTD_OV, QTD_DAY, BRAND, STATUS) VALUES 
                (SYSDATE, SYSDATE, v_account_id, 
                v_party_id, v_default_payment, v_descr_payment, 
                v_last_header_id, v_last_order, v_last_invoice, v_last_payment, v_first_order,
                v_warehouse, v_warehouse_descr, v_puchase_frequency,
                v_qtd_pedido, v_qtd_dias, 'Portobello','A');
                COMMIT;

            end if;  

            v_party_id := 0;
            v_default_payment := 0;
            v_descr_payment := null;
            v_last_header_id := 0;
            v_last_order := null;
            v_last_invoice := null;
            v_last_payment := null;
            v_first_order := null;
            v_warehouse := null;
            v_warehouse_descr := null;
            v_puchase_frequency := null;
            v_qtd_pedido := 0;
            v_qtd_dias := 0;
            --Bloco de dados da Pointer
            OPEN c_first_po(v_account_id, 2);
            FETCH c_first_po
            INTO v_first_order;
            CLOSE c_first_po;    
            if v_first_order is not null then 
                OPEN c_client(v_account_id,2);
                FETCH c_client
                INTO v_tipo_contribuinte,
                     v_party_id,
                     v_last_header_id,
                     v_qtd_pedido,
                     v_qtd_dias;
                CLOSE c_client;

                OPEN c_last_po(v_last_header_id);
                FETCH c_last_po
                INTO v_order_type, v_order_number, v_default_payment, v_endereco, v_channel, v_warehouse, v_descr_payment, v_last_order;
                CLOSE c_last_po;
                                  
                OPEN c_last_pay(v_party_id, 2);
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

               if v_qtd_dias > 365 then
                    IF v_qtd_pedido > 250 then
                        v_puchase_frequency := 'Daily';        
                    end if;
                    IF v_qtd_pedido between 36 and 250  then
                        v_puchase_frequency := 'Weekly';        
                    end if;
                    IF v_qtd_pedido between 19 and 35 then
                        v_puchase_frequency := 'Monthly';        
                    end if;
                    IF v_qtd_pedido between 7 and 18 then
                        v_puchase_frequency := 'BiMonthly';        
                    end if;
                    IF v_qtd_pedido between 3 and 6  then
                        v_puchase_frequency := 'Semester';        
                    end if;
                    IF v_qtd_pedido between 2 and 3 then
                        v_puchase_frequency := 'Yearly';        
                    end if;
                end if;

                if v_qtd_dias between 183 and 250 then
                    IF v_qtd_pedido > 125 then
                        v_puchase_frequency := 'Daily';        
                    end if;
                    IF v_qtd_pedido between 16 and 125  then
                        v_puchase_frequency := 'Weekly';        
                    end if;
                    IF v_qtd_pedido between 9 and 15 then
                        v_puchase_frequency := 'Monthly';        
                    end if;
                    IF v_qtd_pedido between 3 and 8 then
                        v_puchase_frequency := 'BiMonthly';        
                    end if;
                    IF v_qtd_pedido = 2 then
                        v_puchase_frequency := 'Semester';        
                    end if;
                    IF v_qtd_pedido = 1 then
                        v_puchase_frequency := 'Yearly';        
                    end if;
                end if;
                
                if v_qtd_dias < 183 then
                    IF v_qtd_pedido > 60 then
                        v_puchase_frequency := 'Daily';        
                    end if;
                    IF v_qtd_pedido between 7 and 59  then
                        v_puchase_frequency := 'Weekly';        
                    end if;
                    IF v_qtd_pedido between 4 and 6 then
                        v_puchase_frequency := 'Monthly';        
                    end if;
                    IF v_qtd_pedido between 2 and 3 then
                        v_puchase_frequency := 'Bimestral';        
                    end if;
                    IF v_qtd_pedido = 1 then
                        v_puchase_frequency := 'Semester';        
                    end if;
                end if;


                if v_warehouse not in('1717','1716','1759','1761','1819','1860','1881','1940','1960','1980','1981','1982','1719','1986','2006','2066','1900') then  
                    v_warehouse := '1982';                
                end if;
                
                v_warehouse_descr := CASE v_warehouse
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
              
                INSERT INTO APPS.XXPB_HIST_PO_CLIENT 
                (CREATED_DATE, LAST_UPDATE_DATE, CUST_ACCOUNT_ID, 
                PARTY_ID, DEFAULT_PAYMENT, DESCR_PAYMENT, 
                LAST_HEADER_ID, LAST_ORDER, LAST_INVOICE, LAST_PAYMENT, FIRST_ORDER, 
                WAREHOUSE, DESCR_WAREHOUSE, PURCHASE_FREQUENCY,
                QTD_OV, QTD_DAY, BRAND, STATUS) VALUES 
                (SYSDATE, SYSDATE, v_account_id, 
                v_party_id, v_default_payment, v_descr_payment, 
                v_last_header_id, v_last_order, v_last_invoice, v_last_payment, v_first_order,
                v_warehouse, v_warehouse_descr, v_puchase_frequency,
                v_qtd_pedido, v_qtd_dias, 'Pointer', 'A');
                COMMIT;

            end if;              
            
        end loop;



    UPDATE APPS.XXPB_HIST_PO_CLIENT X
       SET STATUS = 'I'
     WHERE NOT EXISTS
              (  SELECT ACCO.CUST_ACCOUNT_ID
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
                        AND OHA.ORDERED_DATE >= ADD_MONTHS (SYSDATE, -24)
                        AND OHA.SALES_CHANNEL_CODE IN
                               ('1', '2', '101', '102', '23', '25')
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
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END p_gera_dados_cli_po;
/