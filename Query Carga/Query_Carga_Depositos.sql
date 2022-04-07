SELECT replace(A.DESCR,',','') AS Name,
'DEPT' || A.CODIGO AS ExternalId__c,
A.CODIGO AS ERP_ID,
A.CODIGO AS Warehouse__c,
A.STATE AS State__c,
A.CANAL AS Channel__c,
A.MARCA AS Brand__c,
'0125f000000uBh5AAE' As RecordTypeId__c
FROM (
select 1717 as codigo, 'P11: Planta Portobello 11' as descr ,'Santa Catarina' as state, 'Portobello' as marca,'1;2' as canal from dual union all 
select 1716 as codigo, 'PUC: Planta Única' as descr ,'Santa Catarina' as state, 'Portobello' as marca,'1;2;4' as canal from dual union all 
select 1719 as codigo, 'EET: Estoque Expedição Tijucas' as descr ,'Santa Catarina' as state, 'Portobello;Pointer' as marca,'1;2;4;23;25;101' as canal from dual union all 
select 1759 as codigo, 'PNT: Planta Pernambuco Pointer' as descr ,'Pernambuco' as state, 'Portobello;Pointer' as marca,'1;2;102' as canal from dual union all 
select 1761 as codigo, 'PPB: Planta Pernambuco Portobello' as descr ,'Pernambuco' as state, 'Portobello' as marca,'1;2' as canal from dual union all 
select 1819 as codigo, 'PMA: Planta Portobello Marechal Deodoro' as descr ,'Alagoas' as state, 'Portobello;Pointer' as marca,'1;102' as canal from dual union all 
select 1860 as codigo, 'EEM: Estoque Expedição Marechal Deodoro' as descr ,'Alagoas' as state, 'Portobello;Pointer' as marca,'1;2;4;102' as canal from dual union all 
select 1881 as codigo, 'PPE: Planta Pointer Pernambuco' as descr ,'Pernambuco' as state, 'Portobello;Pointer' as marca,'101;102;2' as canal from dual union all 
select 1940 as codigo, 'CDC: Cd Duque De Caxias' as descr ,'Rio de Janeiro' as state, 'Portobello' as marca,'1;4' as canal from dual union all 
select 1960 as codigo, 'CWB: Cd Curitiba' as descr ,'Paraná' as state, 'Portobello' as marca,'1;4;23' as canal from dual union all 
select 1980 as codigo, 'CSA: Cd Cabo De Santo Agostinho' as descr ,'Pernambuco' as state, 'Portobello' as marca,'1;4;23' as canal from dual union all 
select 1981 as codigo, 'CIT: Planta Itajaí - Tecadi' as descr ,'Santa Catarina' as state, 'Portobello' as marca,'1;2;4' as canal from dual union all 
select 1982 as codigo, 'EEA: Est Exp Portobello Alagoas' as descr ,'Alagoas' as state, 'Portobello;Pointer' as marca,'1;2;4;101;102' as canal from dual union all 
select 1986 as codigo, 'CFR: Cd Fortaleza' as descr ,'Ceará' as state, 'Portobello;Pointer' as marca,'1;101;102' as canal from dual union all 
select 2006 as codigo, 'CGO: Cd Goiania' as descr ,'Goiás' as state, 'Portobello;Pointer' as marca,'1;4;102' as canal from dual union all 
select 2066 as codigo, 'CPR: CD PETROLINA' as descr ,'Pernambuco' as state, 'Portobello;Pointer' as marca,'1;102' as canal from dual union all   
select 1900 as codigo, 'CJU: CD JUNDIAI' as descr ,'São Paulo' as state, 'Portobello' as marca,'1;23;4' as canal from dual 
) A
