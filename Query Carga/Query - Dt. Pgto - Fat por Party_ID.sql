                SELECT 
                MAX(raa.apply_date)                          dt_pagamento,
                MAX(aps.trx_date)                            dt_emissao_titulo
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
                  AND   acc.id_mercado                  = 'MI'
                  AND   HZP.PARTY_ID = p_party_id
                  AND   aps.due_date BETWEEN add_months(trunc(sysdate, 'month'), -24) and trunc(sysdate, 'month')
            order by aps.due_date desc