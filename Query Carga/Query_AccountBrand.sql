/* Formatted on 24/11/2021 10:11:27 (QP5 v5.215.12089.38647) */
SELECT 
       CAA.ACCOUNT_NUMBER as Account__c,
       AGC.DS_GRUPO_CREDITO as Brand__c,
       ACG.VL_LIMITE_CREDITO as TotalCreditLimit__c,
       acg.vl_saldo_limite as AvailableCreditLimit__c,
       ACG.DT_EXPIRACAO_CREDITO as ExpireDateLimitCredit__c,
       '' as ServiceLevel__c,
       '' as SalesSubChannerl__c,
       caa.attribute7 as OpenPallet__c,
       caa.attribute8 as PercOpenPallert__c,
       case when AGC.DS_GRUPO_CREDITO = 'POINTER' THEN 'EEA' ELSE 'EET' END as Warehouse__c,
       case when AGC.DS_GRUPO_CREDITO = 'POINTER' THEN 'EEA' ELSE 'EET' END as MainWarehouse__c,
       CAA.CUST_ACCOUNT_ID
  FROM AR_ANALISE_CRE_GRUPO_JB ACG
       INNER JOIN AR_ANALISE_CRE_CLIENTE_JB ACC
          ON     ACG.CD_GRUPO_CREDITO = ACC.CD_GRUPO_CREDITO
             AND ACG.ID_CENTRALIZADOR = ACC.ID_CENTRALIZADOR
       INNER JOIN HZ_CUST_ACCOUNTS_ALL CAA
          ON CAA.CUST_ACCOUNT_ID = ACC.ID_CUST_ACCOUNT
       INNER JOIN HZ_PARTIES HZP
          ON HZP.PARTY_ID = CAA.PARTY_ID
       INNER JOIN ar_grupo_credito_jb agC
          ON ACC.CD_GRUPO_CREDITO = AGC.CD_GRUPO_CREDITO
  JOIN HZ_CUST_ACCOUNTS HCA ON CAA.CUST_ACCOUNT_ID = HCA.CUST_ACCOUNT_ID -- industry / parentid 
  join HZ_CUST_ACCT_SITES_ALL HCASA ON HCA.CUST_ACCOUNT_ID = HCASA.CUST_ACCOUNT_ID 
 WHERE ACG.ID_MERCADO = 'MI' AND HZP.PARTY_NAME LIKE '%DESTRO CASA%' AND PRIMARY_FLAG = 'Y'     