SELECT DISTINCT
            --(a.global_attribute5 || a.global_attribute6 || a.global_attribute7) document_number,
            SUBSTR (a.description, 1, 100) Name,
            --GREATEST (a.last_update_date, b.last_update_date) last_update_date,
            'TRPT' || b.carrier_id externalID__C,
            b.carrier_id erpID__C,
            --c.lookup_code WAREHOUSE__C,
            '0125f000000uBh4AAE' as recordtypeid
       FROM org_freight_vl a, wsh_carrier_services_v b,
       (SELECT lova.meaning, lova.lookup_code
                      FROM fnd_lookup_values lova
                     WHERE     lova.enabled_flag = 'Y'
                           AND TRUNC (SYSDATE) BETWEEN TRUNC (
                                                          NVL (
                                                             lova.start_date_active,
                                                             SYSDATE))
                                                   AND TRUNC (
                                                          NVL (
                                                             lova.end_date_active,
                                                             SYSDATE))
                           AND lova.language = 'PTB'
                           AND lova.lookup_type =
                                  'ONT_DEPOSITOS_TRANSPOR_IVOP_PB'
       ) c
      WHERE     a.party_id = b.carrier_id
            AND a.attribute1 IS NOT NULL
            AND (   a.global_attribute5
                 || a.global_attribute6
                 || a.global_attribute7)
                   IS NOT NULL
            AND TRUNC (NVL (a.disable_date, SYSDATE)) >= TRUNC (SYSDATE)
            AND b.enabled_flag = 'Y'
            AND b.mode_of_transport IN ('LTL', 'OCEAN') -- Somente Rodoviário e Marítimo
            AND a.organization_code = c.meaning;