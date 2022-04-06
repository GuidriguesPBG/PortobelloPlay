--Carga mais completa
select * from (
select --b.inventory_item_id, 
b.segment1 as ProductCode, 
b.GLOBAL_ATTRIBUTE3 Source__c,
replace(b.description,',','') Name,
--select b.*,
--(SELECT listagg(SubStr(meaning, 1, 50), ' - ') WITHIN GROUP(ORDER BY SubStr(meaning, 1, 50))
(SELECT listagg(substr(canal.lookup_code, 1, 3), ';') WITHIN GROUP(ORDER BY substr(canal.lookup_code, 1, 3))
             from so_lookups canal, GMI_CANAL_PRODUTO_APO canal_prd
            where canal.lookup_code = canal_prd.cd_canal
              AND canal.lookup_type = 'SALES_CHANNEL'
              AND substr(canal.lookup_code, 1, 3) in ('1','2','101','102','23','25')
              and canal_prd.organization_id = pb_master_organization_id
              AND canal_prd.inventory_item_id = b.INVENTORY_ITEM_ID
              and canal_prd.IN_ATIVO = 'Y') SalesChannel__c,
trunc(C.PC_POR_CAIXA) as UnitsPerBox__c , 
trunc(C.PC_PALLETS) as Pallet__c, 
trunc(C.CAIXAS_POR_CAMADA) as BoxPerLayer__c, 
replace(round(C.M2_POR_PECA,4),',','.') as Mt2PerUnit__c, 
replace(round(C.M2_POR_CAMADA,4),',','.') as Mt2PerLayer__c,
ceil(pc_por_m2) UnMt2__c, 
trunc(camada_por_pallete) as LayersPerPallet__c , 
trunc(caixas_pallets) as BoxPerPallet__c, 
replace(round(m2_por_caixa,4),',','.') as Mt2PerBox__c, 
replace(round(m2_por_pallete,4),',','.') as Mt2PerPallet__c,
p.id_salesforce as id               
--select count(distinct inventory_item_id)
from mtl_system_items_b b
inner join CONSULTA_PRODUTO_PB_V c on c.cod_produto = b.segment1 and c.item_id = b.inventory_item_id
inner join tmp_prod_salesforce p on p.cod_produto_ora = b.segment1
where b.attribute9 in('AT','IN','SC','SP','SU','OP','SS')
and b.organization_id = 43
) where nvl(saleschannel__c,' ') <> ' '


select * from (
select --b.inventory_item_id, 
b.segment1 as ProductCode, 
b.GLOBAL_ATTRIBUTE3 Source__c,
replace(b.description,',','') Name,
--select b.*,
--(SELECT listagg(SubStr(meaning, 1, 50), ' - ') WITHIN GROUP(ORDER BY SubStr(meaning, 1, 50))
(SELECT listagg(substr(canal.lookup_code, 1, 3), ';') WITHIN GROUP(ORDER BY substr(canal.lookup_code, 1, 3))
             from so_lookups canal, GMI_CANAL_PRODUTO_APO canal_prd
            where canal.lookup_code = canal_prd.cd_canal
              AND canal.lookup_type = 'SALES_CHANNEL'
              AND substr(canal.lookup_code, 1, 3) in ('1','2','101','102','23','25')
              and canal_prd.organization_id = pb_master_organization_id
              AND canal_prd.inventory_item_id = b.INVENTORY_ITEM_ID
              and canal_prd.IN_ATIVO = 'Y') SalesChannel__c
--select count(distinct inventory_item_id)
from mtl_system_items_b b
where attribute9 in('AT','IN','SC','SP','SU','OP','SS')
and b.organization_id = 43
and exists (select cod_produto from CONSULTA_PRODUTO_PB_V where cod_produto = b.segment1 and item_id = b.inventory_item_id)
) where nvl(saleschannel__c,' ') <> ' '