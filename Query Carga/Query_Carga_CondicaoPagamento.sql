select 
replace(A.description,',','') as Name, 
'CPGT' || A.erp_id as External__c,
A.erp_id as erpID,
0 as Charges__c,
A.Medium_term as AverageTerm__c,
'0125f000000tXQ7AAM' as RECORDTYPEID
from (
SELECT 0 PAYMENT_CONDITION_ID,
            TRIM (A.DESCRIPTION) DESCRIPTION,
            DECODE (TRIM (A.DESCRIPTION), 'A VISTA', 0, B.PRAZO_MEDIO)
               MEDIUM_TERM,
            B.PARCELAS NUMBER_OF_PLOTS,
            A.TERM_ID ERP_ID,
            COUNT (a.term_id) erp_attribute1,
            NVL (C_01.DUE_DAYS, 0) PRAZO_01,
            NVL (C_01.RELATIVE_AMOUNT, 0) PERCE_01,
            NVL (C_02.DUE_DAYS, 0) PRAZO_02,
            NVL (C_02.RELATIVE_AMOUNT, 0) PERCE_02,
            NVL (C_03.DUE_DAYS, 0) PRAZO_03,
            NVL (C_03.RELATIVE_AMOUNT, 0) PERCE_03,
            NVL (C_04.DUE_DAYS, 0) PRAZO_04,
            NVL (C_04.RELATIVE_AMOUNT, 0) PERCE_04,
            NVL (C_05.DUE_DAYS, 0) PRAZO_05,
            NVL (C_05.RELATIVE_AMOUNT, 0) PERCE_05,
            NVL (C_06.DUE_DAYS, 0) PRAZO_06,
            NVL (C_06.RELATIVE_AMOUNT, 0) PERCE_06,
            NVL (C_07.DUE_DAYS, 0) PRAZO_07,
            NVL (C_07.RELATIVE_AMOUNT, 0) PERCE_07,
            NVL (C_08.DUE_DAYS, 0) PRAZO_08,
            NVL (C_08.RELATIVE_AMOUNT, 0) PERCE_08,
            NVL (C_09.DUE_DAYS, 0) PRAZO_09,
            NVL (C_09.RELATIVE_AMOUNT, 0) PERCE_09,
            NVL (C_10.DUE_DAYS, 0) PRAZO_10,
            NVL (C_10.RELATIVE_AMOUNT, 0) PERCE_10,
            NVL (C_11.DUE_DAYS, 0) PRAZO_11,
            NVL (C_11.RELATIVE_AMOUNT, 0) PERCE_11,
            NVL (C_12.DUE_DAYS, 0) PRAZO_12,
            NVL (C_12.RELATIVE_AMOUNT, 0) PERCE_12,
            42 COND_ORG_ID,
            A.ATTRIBUTE3 erp_attribute2 -- IND. COND. PBShop (Y, N)  -- ATTRIBUTE01 IVOP
                                       ,
            NVL (REGEXP_SUBSTR (A.ATTRIBUTE7, '^[0-9]+[0-9]+'), '000')
               erp_attribute3 -- MARCA (000, 001, 002)     -- ATTRIBUTE02 IVOP
                             ,
            CAST (NULL AS VARCHAR (240)) erp_attribute4    -- ATTRIBUTE03 IVOP
                                                       ,
            CAST (NULL AS VARCHAR (240)) erp_attribute5    -- ATTRIBUTE04 IVOP
                                                       ,
            CAST (NULL AS VARCHAR (240)) erp_attribute6    -- ATTRIBUTE05 IVOP
       FROM RA_TERMS A,
            (  SELECT TERM_ID,
                      TRUNC (AVG (DUE_DAYS)) PRAZO_MEDIO,
                      COUNT (*) PARCELAS
                 FROM RA_TERMS_LINES
             GROUP BY TERM_ID) B,
            RA_TERMS_LINES C_01,
            RA_TERMS_LINES C_02,
            RA_TERMS_LINES C_03,
            RA_TERMS_LINES C_04,
            RA_TERMS_LINES C_05,
            RA_TERMS_LINES C_06,
            RA_TERMS_LINES C_07,
            RA_TERMS_LINES C_08,
            RA_TERMS_LINES C_09,
            RA_TERMS_LINES C_10,
            RA_TERMS_LINES C_11,
            RA_TERMS_LINES C_12
      WHERE     A.TERM_ID = C_01.TERM_ID
            AND C_01.SEQUENCE_NUM(+) = 1
            AND C_01.DUE_DAYS IS NOT NULL
            AND A.TERM_ID = C_02.TERM_ID(+)
            AND C_02.SEQUENCE_NUM(+) = 2
            AND A.TERM_ID = C_03.TERM_ID(+)
            AND C_03.SEQUENCE_NUM(+) = 3
            AND A.TERM_ID = C_04.TERM_ID(+)
            AND C_04.SEQUENCE_NUM(+) = 4
            AND A.TERM_ID = C_05.TERM_ID(+)
            AND C_05.SEQUENCE_NUM(+) = 5
            AND A.TERM_ID = C_06.TERM_ID(+)
            AND C_06.SEQUENCE_NUM(+) = 6
            AND A.TERM_ID = C_07.TERM_ID(+)
            AND C_07.SEQUENCE_NUM(+) = 7
            AND A.TERM_ID = C_08.TERM_ID(+)
            AND C_08.SEQUENCE_NUM(+) = 8
            AND A.TERM_ID = C_09.TERM_ID(+)
            AND C_09.SEQUENCE_NUM(+) = 9
            AND A.TERM_ID = C_10.TERM_ID(+)
            AND C_10.SEQUENCE_NUM(+) = 10
            AND A.TERM_ID = C_11.TERM_ID(+)
            AND C_11.SEQUENCE_NUM(+) = 11
            AND A.TERM_ID = C_12.TERM_ID(+)
            AND C_12.SEQUENCE_NUM(+) = 12
            AND A.TERM_ID = B.TERM_ID
            --
            -- CHAMADO 41594 - Novas condiçõs não integram para o iVop - Adicionada Flag para definir o que deverá ser integrado. - Alexandre Oliveira
            AND A.ATTRIBUTE6 = 'Y'
            AND (A.END_DATE_ACTIVE >= SYSDATE OR A.END_DATE_ACTIVE IS NULL)
            AND A.START_DATE_ACTIVE <= SYSDATE
            --
            AND B.PRAZO_MEDIO > -1
   GROUP BY -- (Trim(A.DESCRIPTION) || ' - Prazo Médio:'|| B.PRAZO_MEDIO || ' Dias - Parcelas: ' || B.PARCELAS ) ,
           TRIM (A.DESCRIPTION),
            B.PRAZO_MEDIO,
            B.PARCELAS,
            A.TERM_ID,
            A.ATTRIBUTE3,
            A.ATTRIBUTE7,
            NVL (C_01.DUE_DAYS, 0),
            NVL (C_01.RELATIVE_AMOUNT, 0),
            NVL (C_02.DUE_DAYS, 0),
            NVL (C_02.RELATIVE_AMOUNT, 0),
            NVL (C_03.DUE_DAYS, 0),
            NVL (C_03.RELATIVE_AMOUNT, 0),
            NVL (C_04.DUE_DAYS, 0),
            NVL (C_04.RELATIVE_AMOUNT, 0),
            NVL (C_05.DUE_DAYS, 0),
            NVL (C_05.RELATIVE_AMOUNT, 0),
            NVL (C_06.DUE_DAYS, 0),
            NVL (C_06.RELATIVE_AMOUNT, 0),
            NVL (C_07.DUE_DAYS, 0),
            NVL (C_07.RELATIVE_AMOUNT, 0),
            NVL (C_08.DUE_DAYS, 0),
            NVL (C_08.RELATIVE_AMOUNT, 0),
            NVL (C_09.DUE_DAYS, 0),
            NVL (C_09.RELATIVE_AMOUNT, 0),
            NVL (C_10.DUE_DAYS, 0),
            NVL (C_10.RELATIVE_AMOUNT, 0),
            NVL (C_11.DUE_DAYS, 0),
            NVL (C_11.RELATIVE_AMOUNT, 0),
            NVL (C_12.DUE_DAYS, 0),
            NVL (C_12.RELATIVE_AMOUNT, 0)
   ORDER BY COUNT (A.term_id) DESC
   ) a 
   LEFT JOIN (
select 0 as prazo, 3.63 as desconto from dual union all 
select 1 as prazo, 3.57 as desconto from dual union all 
select 2 as prazo, 3.5 as desconto from dual union all 
select 3 as prazo, 3.44 as desconto from dual union all 
select 4 as prazo, 3.37 as desconto from dual union all 
select 5 as prazo, 3.31 as desconto from dual union all 
select 6 as prazo, 3.25 as desconto from dual union all 
select 7 as prazo, 3.18 as desconto from dual union all 
select 8 as prazo, 3.12 as desconto from dual union all 
select 9 as prazo, 3.05 as desconto from dual union all 
select 10 as prazo, 2.99 as desconto from dual union all 
select 11 as prazo, 2.93 as desconto from dual union all 
select 12 as prazo, 2.86 as desconto from dual union all 
select 13 as prazo, 2.8 as desconto from dual union all 
select 14 as prazo, 2.73 as desconto from dual union all 
select 15 as prazo, 2.67 as desconto from dual union all 
select 16 as prazo, 2.61 as desconto from dual union all 
select 17 as prazo, 2.54 as desconto from dual union all 
select 18 as prazo, 2.48 as desconto from dual union all 
select 19 as prazo, 2.41 as desconto from dual union all 
select 20 as prazo, 2.35 as desconto from dual union all 
select 21 as prazo, 2.28 as desconto from dual union all 
select 22 as prazo, 2.22 as desconto from dual union all 
select 23 as prazo, 2.15 as desconto from dual union all 
select 24 as prazo, 2.09 as desconto from dual union all 
select 25 as prazo, 2.03 as desconto from dual union all 
select 26 as prazo, 1.96 as desconto from dual union all 
select 27 as prazo, 1.9 as desconto from dual union all 
select 28 as prazo, 1.83 as desconto from dual union all 
select 29 as prazo, 1.77 as desconto from dual union all 
select 30 as prazo, 1.7 as desconto from dual union all 
select 31 as prazo, 1.64 as desconto from dual union all 
select 32 as prazo, 1.57 as desconto from dual union all 
select 33 as prazo, 1.51 as desconto from dual union all 
select 34 as prazo, 1.44 as desconto from dual union all 
select 35 as prazo, 1.38 as desconto from dual union all 
select 36 as prazo, 1.31 as desconto from dual union all 
select 37 as prazo, 1.25 as desconto from dual union all 
select 38 as prazo, 1.18 as desconto from dual union all 
select 39 as prazo, 1.12 as desconto from dual union all 
select 40 as prazo, 1.05 as desconto from dual union all 
select 41 as prazo, 0.99 as desconto from dual union all 
select 42 as prazo, 0.92 as desconto from dual union all 
select 43 as prazo, 0.85 as desconto from dual union all 
select 44 as prazo, 0.79 as desconto from dual union all 
select 45 as prazo, 0.72 as desconto from dual union all 
select 46 as prazo, 0.66 as desconto from dual union all 
select 47 as prazo, 0.59 as desconto from dual union all 
select 48 as prazo, 0.53 as desconto from dual union all 
select 49 as prazo, 0.46 as desconto from dual union all 
select 50 as prazo, 0.4 as desconto from dual union all 
select 51 as prazo, 0.33 as desconto from dual union all 
select 52 as prazo, 0.26 as desconto from dual union all 
select 53 as prazo, 0.2 as desconto from dual union all 
select 54 as prazo, 0.13 as desconto from dual union all 
select 55 as prazo, 0.07 as desconto from dual union all 
select 56 as prazo, 0 as desconto from dual union all 
select 57 as prazo, -0.07 as desconto from dual union all 
select 58 as prazo, -0.13 as desconto from dual union all 
select 59 as prazo, -0.2 as desconto from dual union all 
select 60 as prazo, -0.26 as desconto from dual union all 
select 61 as prazo, -0.33 as desconto from dual union all 
select 62 as prazo, -0.4 as desconto from dual union all 
select 63 as prazo, -0.46 as desconto from dual union all 
select 64 as prazo, -0.53 as desconto from dual union all 
select 65 as prazo, -0.6 as desconto from dual union all 
select 66 as prazo, -0.66 as desconto from dual union all 
select 67 as prazo, -0.73 as desconto from dual union all 
select 68 as prazo, -0.8 as desconto from dual union all 
select 69 as prazo, -0.86 as desconto from dual union all 
select 70 as prazo, -0.93 as desconto from dual union all 
select 71 as prazo, -1 as desconto from dual union all 
select 72 as prazo, -1.06 as desconto from dual union all 
select 73 as prazo, -1.13 as desconto from dual union all 
select 74 as prazo, -1.2 as desconto from dual union all 
select 75 as prazo, -1.26 as desconto from dual union all 
select 76 as prazo, -1.33 as desconto from dual union all 
select 77 as prazo, -1.4 as desconto from dual union all 
select 78 as prazo, -1.46 as desconto from dual union all 
select 79 as prazo, -1.53 as desconto from dual union all 
select 80 as prazo, -1.6 as desconto from dual union all 
select 81 as prazo, -1.66 as desconto from dual union all 
select 82 as prazo, -1.73 as desconto from dual union all 
select 83 as prazo, -1.8 as desconto from dual union all 
select 84 as prazo, -1.87 as desconto from dual union all 
select 85 as prazo, -1.93 as desconto from dual union all 
select 86 as prazo, -2 as desconto from dual union all 
select 87 as prazo, -2.07 as desconto from dual union all 
select 88 as prazo, -2.13 as desconto from dual union all 
select 89 as prazo, -2.2 as desconto from dual union all 
select 90 as prazo, -2.27 as desconto from dual union all 
select 91 as prazo, -2.34 as desconto from dual union all 
select 92 as prazo, -2.4 as desconto from dual union all 
select 93 as prazo, -2.47 as desconto from dual union all 
select 94 as prazo, -2.54 as desconto from dual union all 
select 95 as prazo, -2.61 as desconto from dual union all 
select 96 as prazo, -2.68 as desconto from dual union all 
select 97 as prazo, -2.74 as desconto from dual union all 
select 98 as prazo, -2.81 as desconto from dual union all 
select 99 as prazo, -2.88 as desconto from dual union all 
select 100 as prazo, -2.95 as desconto from dual union all 
select 101 as prazo, -3.01 as desconto from dual union all 
select 102 as prazo, -3.08 as desconto from dual union all 
select 103 as prazo, -3.15 as desconto from dual union all 
select 104 as prazo, -3.22 as desconto from dual union all 
select 105 as prazo, -3.29 as desconto from dual union all 
select 106 as prazo, -3.36 as desconto from dual union all 
select 107 as prazo, -3.42 as desconto from dual union all 
select 108 as prazo, -3.49 as desconto from dual union all 
select 109 as prazo, -3.56 as desconto from dual union all 
select 110 as prazo, -3.63 as desconto from dual union all 
select 111 as prazo, -3.7 as desconto from dual union all 
select 112 as prazo, -3.77 as desconto from dual union all 
select 113 as prazo, -3.83 as desconto from dual union all 
select 114 as prazo, -3.9 as desconto from dual union all 
select 115 as prazo, -3.97 as desconto from dual union all 
select 116 as prazo, -4.04 as desconto from dual union all 
select 117 as prazo, -4.11 as desconto from dual union all 
select 118 as prazo, -4.18 as desconto from dual union all 
select 119 as prazo, -4.25 as desconto from dual union all 
select 120 as prazo, -4.32 as desconto from dual union all 
select 121 as prazo, -4.38 as desconto from dual union all 
select 122 as prazo, -4.45 as desconto from dual union all 
select 123 as prazo, -4.52 as desconto from dual union all 
select 124 as prazo, -4.59 as desconto from dual union all 
select 125 as prazo, -4.66 as desconto from dual union all 
select 126 as prazo, -4.73 as desconto from dual union all 
select 127 as prazo, -4.8 as desconto from dual union all 
select 128 as prazo, -4.87 as desconto from dual union all 
select 129 as prazo, -4.94 as desconto from dual union all 
select 130 as prazo, -5.01 as desconto from dual union all 
select 131 as prazo, -5.08 as desconto from dual union all 
select 132 as prazo, -5.14 as desconto from dual union all 
select 133 as prazo, -5.21 as desconto from dual union all 
select 134 as prazo, -5.28 as desconto from dual union all 
select 135 as prazo, -5.35 as desconto from dual union all 
select 136 as prazo, -5.42 as desconto from dual union all 
select 137 as prazo, -5.49 as desconto from dual union all 
select 138 as prazo, -5.56 as desconto from dual union all 
select 139 as prazo, -5.63 as desconto from dual union all 
select 140 as prazo, -5.7 as desconto from dual union all 
select 141 as prazo, -5.77 as desconto from dual union all 
select 142 as prazo, -5.84 as desconto from dual union all 
select 143 as prazo, -5.91 as desconto from dual union all 
select 144 as prazo, -5.98 as desconto from dual union all 
select 145 as prazo, -6.05 as desconto from dual union all 
select 146 as prazo, -6.12 as desconto from dual union all 
select 147 as prazo, -6.19 as desconto from dual union all 
select 148 as prazo, -6.26 as desconto from dual union all 
select 149 as prazo, -6.33 as desconto from dual union all 
select 150 as prazo, -6.4 as desconto from dual union all 
select 151 as prazo, -6.47 as desconto from dual union all 
select 152 as prazo, -6.54 as desconto from dual union all 
select 153 as prazo, -6.61 as desconto from dual union all 
select 154 as prazo, -6.68 as desconto from dual union all 
select 155 as prazo, -6.75 as desconto from dual union all 
select 156 as prazo, -6.82 as desconto from dual union all 
select 157 as prazo, -6.89 as desconto from dual union all 
select 158 as prazo, -6.96 as desconto from dual union all 
select 159 as prazo, -7.04 as desconto from dual union all 
select 160 as prazo, -7.11 as desconto from dual union all 
select 161 as prazo, -7.18 as desconto from dual union all 
select 162 as prazo, -7.25 as desconto from dual union all 
select 163 as prazo, -7.32 as desconto from dual union all 
select 164 as prazo, -7.39 as desconto from dual union all 
select 165 as prazo, -7.46 as desconto from dual union all 
select 166 as prazo, -7.53 as desconto from dual union all 
select 167 as prazo, -7.6 as desconto from dual union all 
select 168 as prazo, -7.67 as desconto from dual union all 
select 169 as prazo, -7.74 as desconto from dual union all 
select 170 as prazo, -7.82 as desconto from dual union all 
select 171 as prazo, -7.89 as desconto from dual union all 
select 172 as prazo, -7.96 as desconto from dual union all 
select 173 as prazo, -8.03 as desconto from dual union all 
select 174 as prazo, -8.1 as desconto from dual union all 
select 175 as prazo, -8.17 as desconto from dual union all 
select 176 as prazo, -8.24 as desconto from dual union all 
select 177 as prazo, -8.31 as desconto from dual union all 
select 178 as prazo, -8.39 as desconto from dual union all 
select 179 as prazo, -8.46 as desconto from dual union all 
select 180 as prazo, -8.53 as desconto from dual 
   ) B ON A.Medium_term = B.PRAZO
   order by external__c