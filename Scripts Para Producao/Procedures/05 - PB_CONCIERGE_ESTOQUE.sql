CREATE OR REPLACE PROCEDURE APPS.PB_CONCIERGE_ESTOQUE (p_jsondata in blob) AS
/*
    Criado por: Guilherme A. Rodrigues 
    Em 02/09/2021
    Objetivo: API para gestão de dados de estoque do projeto Concierge

    Modelo de Requisição atual:
        {
            "tipo_retorno":0,
            "cod_produto":"",
            "fase_vida":"",
            "list_produto":[{"codigo":"26110C"},{"codigo":"26110E"},{"codigo":"25252C"},{"codigo":"12005E"}],
            "list_produtos_in":"26110C,26110E,25252C,12005E",
            "canal":0,
            "deposito":"EET"
        }

    Parametros de entrada Habilitados
    tipo_retorno
    cod_produto 
    fase_vida 
    list_produto 
    list_produtos_in 
    list_produtos_in2
    canal
    deposito
    com_estoque
    com_projetado

    Tipo 0 - Extração Completa (Dados de Cadastro \ Estoque \ Projetado)
    Tipo 1 - Listagem de Produtos (Estoque disponível somarizado)
    Tipo 2 - Listagem Dados de Cadastro
    Tipo 3 - Listagem Dados de Cadastro Resumido e Estoque
    Tipo 4 - Listagem Dados de Cadastro Resumido e Estoque Projetado
    Tipo 5 - Listagem Dados de Cadastro Resumido e Estoque e Estoque Projetado
    Tipo 6 - Similar a 1 - somente canal revenda
    Tipo 7 - ????
    Tipo 8 - Estoque Simples 
    Tipo 9 - Retorno Comercial Portobello
*/
  --    
    json_data clob;
    $IF dbms_db_version.ver_le_12 $THEN
        l_values json;
    $ELSE
        l_values  JSON_OBJECT_T;
    $END
    err_msg VARCHAR2(32000);
    i_intervalo_periodo_proj integer := 10;


  CURSOR C_PROJECAO(P_PROD VARCHAR2, P_CD VARCHAR2) IS
  SELECT a.id_periodo,
         a.ds_periodo,
         a.dt_final_periodo,
         a.item_um,
         a.qt_saldo_disponivel_pbshop,
         a.qt_saldo AS qt_saldo_disponivel,
         a.COD_CD,
         MAX (
            CASE
               WHEN UPPER (b.origem_item) = 'PLANTA TIJUCAS' THEN 1
               ELSE 0
            END)
            AS Tijucas,
         a.estoque_fabrica,
         a.last_update_date,
         dep.dep,
         a.vol_meta,
         a.vol_pedido
    FROM xxpb.OM_SALDO_PROD_MICROVIX_CD_V a
         LEFT JOIN CONSULTA_PRODUTO_PB_V B
            ON A.SEGMENT1 = B.COD_PRODUTO
         INNER JOIN (SELECT MP.ORGANIZATION_CODE || ' - ' || L.town_or_city DEP,
                            ORGANIZATION_CODE
                       FROM MTL_PARAMETERS MP,
                            HR_ORGANIZATION_UNITS_V O,
                            HR_LOCATIONS_V L
                      WHERE     L.location_id = O.location_id
                            AND O.ORGANIZATION_ID = MP.ORGANIZATION_ID) dep
            ON dep.ORGANIZATION_CODE = a.cod_cd
   WHERE     segment1 = P_PROD
         AND (a.cod_cd = P_CD OR NVL (P_CD, ' ') = ' ' OR P_CD = '' OR P_CD = 'TODOS')
         AND (a.cod_cd in ('EET','CWB', 'CSA', 'CJU', 'CDC', 'CGO'))
         AND NOT EXISTS
                    (SELECT lookup_code
                       FROM    FND_LOOKUP_VALUES_VL flok
                            JOIN
                               mtl_system_items_b ite
                            ON     flok.LOOKUP_CODE = ite.segment1
                               AND organization_id = pb_master_organization_id
                      WHERE     flok.lookup_type =
                                   'ONT_ATP_PRODUTOS_CALCULA_DMF'
                            AND flok.ENABLED_FLAG = 'Y'
                            AND lookup_code = a.segment1
                            AND TRUNC (SYSDATE) BETWEEN TRUNC (
                                                           NVL (
                                                              flok.start_date_active,
                                                              SYSDATE))
                                                    AND TRUNC (
                                                           NVL (
                                                              flok.end_date_active,
                                                              SYSDATE)))
GROUP BY a.id_periodo,
         a.ds_periodo,
         a.dt_final_periodo,
         a.item_um,
         a.qt_saldo_disponivel_pbshop,
         a.qt_saldo,
         a.COD_CD,
         a.estoque_fabrica,
         a.last_update_date, dep.dep, a.vol_meta, a.vol_pedido
ORDER BY id_periodo, estoque_fabrica;

  --

  CURSOR C_ESTOQUE(P_PROD VARCHAR2, P_CD VARCHAR2, P_CANAL INT, P_ESTOQUE_ZERADO INT) IS
  SELECT A.COD_DEPOSITO,
         A.DS_DEPOSITO DEP,
         A.COD_TONALIDADE_CALIBRE,
         A.COD_PRODUTO_ORA,
         A.SALDO_DISPONIVEL,
         A.SALDO_PBSHOP,
         A.SALDO_EXPORTACAO,
         A.LAST_UPDATE_DATE
    FROM XXPB_ESTOQUE_API A
   WHERE a.COD_PRODUTO_ORA = P_PROD
         AND (a.COD_DEPOSITO = P_CD OR NVL (P_CD, ' ') = ' ' OR P_CD = ''  OR P_CD = 'TODOS')
         AND ((NVL(P_CANAL,0) = 2 AND A.COD_DEPOSITO IN('EET','CIT')) OR NVL(P_CANAL,0) <> 2)
         AND (NVL(P_ESTOQUE_ZERADO,0) = 0 OR (P_ESTOQUE_ZERADO = 1 AND NVL(SALDO_DISPONIVEL,0) > 0 ))
ORDER BY a.cod_produto_ora, a.COD_DEPOSITO, a.COD_TONALIDADE_CALIBRE;                 
  --
  TYPE C_PROJECAO_AAT IS TABLE OF C_PROJECAO%ROWTYPE
        INDEX BY PLS_INTEGER;
  R_PROJECAO C_PROJECAO_AAT;
  --

  TYPE C_ESTOQUE_AAT IS TABLE OF C_ESTOQUE%ROWTYPE
        INDEX BY PLS_INTEGER;
  R_ESTOQUE C_ESTOQUE_AAT;

  v_projetado boolean;
  v_estoque   boolean;
  v_periodosATP varchar2(50);

    l_dest_offset         NUMBER := 1;
    l_src_offset          NUMBER := 1;
    l_lang_context        NUMBER := 0;
    l_warning             NUMBER;

  $IF  dbms_db_version.ver_le_12 $THEN
    l_root json;
    l_root6 json_list;
    l_list_pro json_list;
    l_list_saldo json_list;
    l_list_volume json_list;
    l_list_estoque json_list;
    l_list_com json_list;
    l_item json;
    l_lista_produtos json_list;
    l_root_c json;
    json_req json_list;
  $ELSE
    l_root JSON_OBJECT_T;
    l_root6 JSON_ARRAY_T;
    l_list_pro JSON_ARRAY_T;
    l_list_saldo JSON_ARRAY_T;
    l_list_volume JSON_ARRAY_T;
    l_list_estoque JSON_ARRAY_T;
    l_list_com JSON_ARRAY_T;
    l_item JSON_OBJECT_T;
    l_lista_produtos JSON_ARRAY_T;
    l_root_c JSON_OBJECT_T;
    json_req JSON_ARRAY_T;
  $END
  l_clob clob;
  l_cd_produto varchar2(200);
  l_list_produto varchar2(2000);
  l_fase_vida varchar2(2);
  l_id_cliente number;
  l_cnpj_cliente varchar2(20);
  l_id_vendedor number;
  l_id_lista number;
  l_deposito varchar2(10);
  l_tipo_retorno number;
  l_canal number;
  l_produtos_in varchar2(4000);
  l_produtos_in2 varchar2(4000);
  l_com_estoque int;
  l_com_projetado int;
  l_estoque_zerado int;
  l_tablen BINARY_INTEGER;
  l_tab DBMS_UTILITY.lname_array;
  l_tab2 DBMS_UTILITY.lname_array;
  l_cod_atual varchar2(20);

  p_page           number := 0;
  p_rows           number := 0;
  l_page           number := 0;
  l_rows           number := 0;
  l_total_regs number := 0;
  l_total_pages    number := 0;
  
  p_last_date varchar2(20);
  
  PROCEDURE defineTotalPages IS
  BEGIN
    if nvl(l_tipo_retorno,0) = 10 then
      SELECT COUNT(*) into l_total_regs
        FROM TMP_PROJETADO_SALESFORCE STK
        where (last_update_date >= to_date(p_last_date,'YYYY-MM-DD HH24:MI:SS') or p_last_date is null);    
    end if;
    
    if nvl(l_tipo_retorno,0) = 11 then
        SELECT COUNT(*) into l_total_regs
          FROM (SELECT LAST_UPDATE_DATE 
                 FROM    apps.xxpb_estoque_api stk
                  INNER JOIN (SELECT MEANING COD, LOOKUP_CODE ID FROM FND_LOOKUP_VALUES WHERE     language = USERENV ('LANG') AND enabled_flag = 'Y' AND lookup_type = 'ONT_DEPOSITOS_SALES_PB') DEP ON STK.COD_DEPOSITO = DEP.COD
                 WHERE
                    SALDO_PBSHOP> 0 OR SALDO_DISPONIVEL > 0 OR SALDO_EXPORTACAO > 0   
/*
				UNION ALL 
				SELECT LAST_UPDATE_DATE
				 FROM APPS.XXPB_ESTOQUE_API_ZERO STK
				  INNER JOIN (SELECT MEANING COD, LOOKUP_CODE ID FROM FND_LOOKUP_VALUES WHERE     language = USERENV ('LANG') AND enabled_flag = 'Y' AND lookup_type = 'ONT_DEPOSITOS_SALES_PB') DEP ON STK.COD_DEPOSITO = DEP.COD
				 WHERE    (FLAG_EXC = 1 and p_last_date is not null)
			     OR (    FLAG_STK = 0
                   AND NOT EXISTS
                              (SELECT 1
                                 FROM XXPB_ESTOQUE_API
                                WHERE     COD_PRODUTO_ORA =
                                             STK.COD_PRODUTO_ORA
                                      AND COD_DEPOSITO = STK.COD_DEPOSITO
                                      AND SALDO_DISPONIVEL > 0))
*/
				)
		WHERE last_update_date >= to_date(p_last_date,'YYYY-MM-DD HH24:MI:SS') or p_last_date is null;    
    end if;    

    if P_ROWS > 0 then
      l_page        := (P_PAGE * P_ROWS) - P_ROWS;
      l_total_pages := l_total_regs / P_ROWS;
    end if;

    if l_total_pages > round(l_total_pages) then
      l_total_pages := l_total_pages + 1;
    end if;
  END;



BEGIN

    l_cd_produto := null;
    l_list_produto := null;
    l_fase_vida := null;
    l_produtos_in := null;
    l_produtos_in2 := null;
    l_cod_atual := null;
    l_estoque_zerado := null;
    dbms_lob.createtemporary(json_data, FALSE, dbms_lob.CALL);
    dbms_lob.converttoclob(json_data, p_jsondata, dbms_lob.lobmaxsize, l_dest_offset, l_src_offset, nls_charset_id('WE8ISO8859P1'), l_lang_context, l_warning);

    htp.p('content-type: application/json;charset=UTF-8');

    $IF  dbms_db_version.ver_le_12 $THEN
      --Nó ROOT do Json
      l_root := json();
      l_root6 := json_list();
      --Nó Principal
      l_list_estoque := json_list();
      --Nó de saldo projetado
      --l_list_pro := json_list();
      --Nó de Saldo em Estoque
      --l_list_saldo := json_list();
    $ELSE
      --Nó ROOT do Json
      l_root := JSON_OBJECT_T();
      l_root6 := JSON_ARRAY_T();
      --Nó Principal
      l_list_estoque := JSON_ARRAY_T();
      --Nó de saldo projetado
      --l_list_pro := JSON_ARRAY_T();
      --Nó de Saldo em Estoque
      --l_list_saldo := JSON_ARRAY_T();
    $END

   --Abre o Curso com a leitura do JSON
     FOR r_requisicao IN (
           select distinct *
            from json_table(p_jsondata,'$'
                 columns(tipo_retorno number path '$.tipo_retorno'
                        ,numPage number path '$.numPage'
                        ,numRows number path '$.numRows'
						,last_date varchar2(20) path '$.last_date'
                        ,cod_produto   varchar2(30) path '$.cod_produto'
                        ,list_produtos_in varchar2(4000) path '$.list_produtos_in'
                        ,list_produtos_in2 varchar2(4000) path '$.list_produtos_in2'
                        ,fase_vida varchar2(50)  path '$.fase_vida'
                        ,id_cliente number path '$.id_cliente'
                        ,cnpj_cliente number path '$.cnpj_cliente'
                        ,id_vendedor number path '$.id_vendedor'
                        ,canal number path '$.canal'
                        ,deposito varchar(10) path '$.deposito'
                        ,com_estoque number path '$.com_estoque'
                        ,com_projetado number path '$.com_projetado'
                        ,estoque_zerado number path '$.estoque_zerado'
                        ,nested path '$.list_produtos[*]'
                        columns(codigo varchar2(20) path '$')
                        )
                 )
     ) LOOP
        l_tipo_retorno := r_requisicao.tipo_retorno;
        p_page := r_requisicao.numPage;
		p_last_date := r_requisicao.last_date;
        p_rows := r_requisicao.numRows;
        l_rows := r_requisicao.numRows;
        l_cd_produto := r_requisicao.cod_produto;
        l_list_produto := r_requisicao.codigo;
        l_fase_vida := r_requisicao.fase_vida;
        l_id_cliente := r_requisicao.id_cliente;
        l_cnpj_cliente := r_requisicao.cnpj_cliente;
        l_id_vendedor := r_requisicao.id_vendedor;
        l_canal := r_requisicao.canal;
        l_deposito := r_requisicao.deposito;
        l_estoque_zerado := r_requisicao.estoque_zerado;
        l_com_estoque := r_requisicao.com_estoque;
        l_com_projetado := r_requisicao.com_projetado;
        l_produtos_in := r_requisicao.list_produtos_in;
        l_produtos_in2 := r_requisicao.list_produtos_in2;
        v_periodosATP := '';

        if l_produtos_in IS NOT NULL then
            FOR RC IN (
              WITH L_LINE(STR) AS    
              (
                SELECT l_produtos_in
                FROM DUAL
              )
              SELECT REGEXP_SUBSTR(STR, '[^,]+', 1, LEVEL) SP_STR
              FROM L_LINE
              CONNECT BY LEVEL <= REGEXP_COUNT(STR, ',') + 1
            )
            LOOP
                l_tab(l_tab.COUNT) := RC.SP_STR;  
            END LOOP;
            -- select column_value from table(l_tab)
        end if;

        if l_produtos_in2 IS NOT NULL then
            FOR RC IN (
              WITH L_LINE(STR) AS    
              (
                SELECT l_produtos_in2
                FROM DUAL
              )
              SELECT REGEXP_SUBSTR(STR, '[^,]+', 1, LEVEL) SP_STR
              FROM L_LINE
              CONNECT BY LEVEL <= REGEXP_COUNT(STR, ',') + 1
            )
            LOOP
                l_tab2(l_tab2.COUNT) := RC.SP_STR;  
            END LOOP;
            -- select column_value from table(l_tab)
        end if;

        if nvl(l_deposito,' ')  = ' ' or l_deposito = '' then 
            l_deposito := 'EET';
        end if;
        
        
        
        if nvl(l_tipo_retorno,0) = 10 then
            $IF dbms_db_version.ver_le_12 $THEN
                l_item := new json();
            $ELSE
                l_item := new JSON_OBJECT_T();
            $END

             defineTotalPages();
             
             for prod in (
                      SELECT
                        LAST_UPDATE_DATE,
                        replace('PRJ' ||trim(STK.DES_CD) || trim(STK.COD_ITEM),',','') AS ExternalCode__c,
						DEP.ID AS WarehouseCode__c,
						DEP.ID AS DESCRICAODEPOSITO__C,
                        replace(trim(STK.DES_CD) || '-' || trim(STK.COD_ITEM),',','') AS NAME,  
                        stk.cod_item as COD_PRODUTO_ORA,  
                          (SELECT DESCRIPTION FROM fnd_lookup_values 
                          WHERE  language            = userenv('LANG')
                          AND    enabled_flag        = 'Y'
                          AND    security_group_id   = 0
                          AND    view_application_id = 660
                          AND    meaning             = 1 --Periodos Válidos para Decêndios
                          AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
                          AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                    AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period01Name__c,
                        REPLACE(NVL(STK.PTBL_P1,0),',','.') ProjectedBalance01__c,
                        REPLACE(STK.SHOP_P1,',','.') ProjectedBalance01PbShop__c,
                          (SELECT DESCRIPTION FROM fnd_lookup_values 
                          WHERE  language            = userenv('LANG')
                          AND    enabled_flag        = 'Y'
                          AND    security_group_id   = 0
                          AND    view_application_id = 660
                          AND    meaning             = 2 --Periodos Válidos para Decêndios
                          AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
                          AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                    AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period02Name__c,
                        REPLACE(NVL(STK.PTBL_P2,0),',','.') ProjectedBalance02__c,
                        REPLACE(STK.SHOP_P2,',','.') ProjectedBalance02PbShop__c,
                          (SELECT DESCRIPTION FROM fnd_lookup_values 
                          WHERE  language            = userenv('LANG')
                          AND    enabled_flag        = 'Y'
                          AND    security_group_id   = 0
                          AND    view_application_id = 660
                          AND    meaning             = 3 --Periodos Válidos para Decêndios
                          AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
                          AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                    AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period03Name__c,
                        REPLACE(NVL(STK.PTBL_P3,0),',','.') ProjectedBalance03__c,
                        REPLACE(STK.SHOP_P3,',','.') ProjectedBalance03PbShop__c,
                          (SELECT DESCRIPTION FROM fnd_lookup_values 
                          WHERE  language            = userenv('LANG')
                          AND    enabled_flag        = 'Y'
                          AND    security_group_id   = 0
                          AND    view_application_id = 660
                          AND    meaning             = 4 --Periodos Válidos para Decêndios
                          AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
                          AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                    AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period04Name__c,
                        REPLACE(NVL(STK.PTBL_P4,0),',','.') ProjectedBalance04__c,
                        REPLACE(STK.SHOP_P4,',','.') ProjectedBalance04PbShop__c,
                          (SELECT DESCRIPTION FROM fnd_lookup_values 
                          WHERE  language            = userenv('LANG')
                          AND    enabled_flag        = 'Y'
                          AND    security_group_id   = 0
                          AND    view_application_id = 660
                          AND    meaning             = 5 --Periodos Válidos para Decêndios
                          AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
                          AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                    AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period05Name__c,
                        REPLACE(NVL(STK.PTBL_P5,0),',','.') ProjectedBalance05__c,
                        REPLACE(STK.SHOP_P5,',','.') ProjectedBalance05PbShop__c,
                          (SELECT DESCRIPTION FROM fnd_lookup_values 
                          WHERE  language            = userenv('LANG')
                          AND    enabled_flag        = 'Y'
                          AND    security_group_id   = 0
                          AND    view_application_id = 660
                          AND    meaning             = 6 --Periodos Válidos para Decêndios
                          AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
                          AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                    AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period06Name__c,
                        REPLACE(NVL(STK.PTBL_P6,0),',','.') ProjectedBalance06__c,
                        REPLACE(STK.SHOP_P6,',','.') ProjectedBalance06PbShop__c,
                          (SELECT DESCRIPTION FROM fnd_lookup_values 
                          WHERE  language            = userenv('LANG')
                          AND    enabled_flag        = 'Y'
                          AND    security_group_id   = 0
                          AND    view_application_id = 660
                          AND    meaning             = 7 --Periodos Válidos para Decêndios
                          AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
                          AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                    AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period07Name__c,
                        REPLACE(NVL(STK.PTBL_P7,0),',','.') ProjectedBalance07__c,
                        REPLACE(STK.SHOP_P7,',','.') ProjectedBalance07PbShop__c,
                          (SELECT DESCRIPTION FROM fnd_lookup_values 
                          WHERE  language            = userenv('LANG')
                          AND    enabled_flag        = 'Y'
                          AND    security_group_id   = 0
                          AND    view_application_id = 660
                          AND    meaning             = 8 --Periodos Válidos para Decêndios
                          AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
                          AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                    AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period08Name__c,
                        REPLACE(NVL(STK.PTBL_P8,0),',','.') ProjectedBalance08__c,
                        REPLACE(STK.SHOP_P8,',','.') ProjectedBalance08PbShop__c,
                          (SELECT DESCRIPTION FROM fnd_lookup_values 
                          WHERE  language            = userenv('LANG')
                          AND    enabled_flag        = 'Y'
                          AND    security_group_id   = 0
                          AND    view_application_id = 660
                          AND    meaning             = 9 --Periodos Válidos para Decêndios
                          AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
                          AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                    AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period09Name__c,
                        REPLACE(NVL(STK.PTBL_P9,0),',','.') ProjectedBalance09__c,
                        REPLACE(STK.SHOP_P9,',','.') ProjectedBalance09PbShop__c,
                          (SELECT DESCRIPTION FROM fnd_lookup_values 
                          WHERE  language            = userenv('LANG')
                          AND    enabled_flag        = 'Y'
                          AND    security_group_id   = 0
                          AND    view_application_id = 660
                          AND    meaning             = 10 --Periodos Válidos para Decêndios
                          AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
                          AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                    AND Trunc(Nvl(end_date_active, SYSDATE))) AS Period10Name__c,
                        REPLACE(NVL(STK.PTBL_P10,0),',','.') ProjectedBalance10__c,
                        REPLACE(STK.SHOP_P10,',','.') ProjectedBalance10PbShop__c,
                        NVL(STK.BALANCE__C,0) BALANCE__C,
                        NVL(STK.EXPORTBALANCE__C,0) EXPORTBALANCE__C,
                        NVL(STK.BALANCEPORTOBELLOSHOP__C,0) BALANCEPORTOBELLOSHOP__C
                        FROM TMP_PROJETADO_SALESFORCE STK
						INNER JOIN (SELECT MEANING COD, LOOKUP_CODE ID FROM FND_LOOKUP_VALUES WHERE     language = USERENV ('LANG') AND enabled_flag = 'Y' AND lookup_type = 'ONT_DEPOSITOS_SALES_PB') DEP ON STK.DES_CD = DEP.COD
                        where (last_update_date >= to_date(p_last_date,'YYYY-MM-DD HH24:MI:SS') or p_last_date is null)
                        Order by LAST_UPDATE_DATE asc offset l_page rows fetch next l_rows rows only
                    )  loop
                        l_item.put('LAST_UPDATE_DATE', prod.LAST_UPDATE_DATE);
                        l_item.put('COD_PRODUTO_ORA', prod.COD_PRODUTO_ORA);
                        l_item.put('EXTERNALCODE__C', prod.EXTERNALCODE__C);
                        l_item.put('WAREHOUSECODE__C', prod.WAREHOUSECODE__C);
                        l_item.put('DESCRICAODEPOSITO__C', prod.DESCRICAODEPOSITO__C);
                        l_item.put('NAME', prod.NAME);

                        l_item.put('BALANCEPORTOBELLOSHOP__C', prod.BALANCEPORTOBELLOSHOP__C);
                        l_item.put('BALANCE__C', prod.BALANCE__C);
                        l_item.put('EXPORTBALANCE__C', prod.EXPORTBALANCE__C);

                        l_item.put('PERIOD01NAME__C', prod.PERIOD01NAME__C);
                        l_item.put('PROJECTEDBALANCE01__C', prod.PROJECTEDBALANCE01__C);
                        l_item.put('PROJECTEDBALANCE01PBSHOP__C', prod.PROJECTEDBALANCE01PBSHOP__C);

                        l_item.put('PERIOD02NAME__C', prod.PERIOD02NAME__C);
                        l_item.put('PROJECTEDBALANCE02__C', prod.PROJECTEDBALANCE02__C);
                        l_item.put('PROJECTEDBALANCE02PBSHOP__C', prod.PROJECTEDBALANCE02PBSHOP__C);

                        l_item.put('PERIOD03NAME__C', prod.PERIOD03NAME__C);
                        l_item.put('PROJECTEDBALANCE03__C', prod.PROJECTEDBALANCE03__C);
                        l_item.put('PROJECTEDBALANCE03PBSHOP__C', prod.PROJECTEDBALANCE03PBSHOP__C);

                        l_item.put('PERIOD04NAME__C', prod.PERIOD04NAME__C);
                        l_item.put('PROJECTEDBALANCE04__C', prod.PROJECTEDBALANCE04__C);
                        l_item.put('PROJECTEDBALANCE04PBSHOP__C', prod.PROJECTEDBALANCE04PBSHOP__C);

                        l_item.put('PERIOD05NAME__C', prod.PERIOD05NAME__C);
                        l_item.put('PROJECTEDBALANCE05__C', prod.PROJECTEDBALANCE05__C);
                        l_item.put('PROJECTEDBALANCE05PBSHOP__C', prod.PROJECTEDBALANCE05PBSHOP__C);

                        l_item.put('PERIOD06NAME__C', prod.PERIOD06NAME__C);
                        l_item.put('PROJECTEDBALANCE06__C', prod.PROJECTEDBALANCE06__C);
                        l_item.put('PROJECTEDBALANCE06PBSHOP__C', prod.PROJECTEDBALANCE06PBSHOP__C);

                        l_item.put('PERIOD07NAME__C', prod.PERIOD07NAME__C);
                        l_item.put('PROJECTEDBALANCE07__C', prod.PROJECTEDBALANCE07__C);
                        l_item.put('PROJECTEDBALANCE07PBSHOP__C', prod.PROJECTEDBALANCE07PBSHOP__C);

                        l_item.put('PERIOD08NAME__C', prod.PERIOD08NAME__C);
                        l_item.put('PROJECTEDBALANCE08__C', prod.PROJECTEDBALANCE08__C);
                        l_item.put('PROJECTEDBALANCE08PBSHOP__C', prod.PROJECTEDBALANCE08PBSHOP__C);

                        l_item.put('PERIOD09NAME__C', prod.PERIOD09NAME__C);
                        l_item.put('PROJECTEDBALANCE09__C', prod.PROJECTEDBALANCE09__C);
                        l_item.put('PROJECTEDBALANCE09PBSHOP__C', prod.PROJECTEDBALANCE09PBSHOP__C);

                        l_item.put('PERIOD10NAME__C', prod.PERIOD10NAME__C);
                        l_item.put('PROJECTEDBALANCE10__C', prod.PROJECTEDBALANCE10__C);
                        l_item.put('PROJECTEDBALANCE10PBSHOP__C', prod.PROJECTEDBALANCE10PBSHOP__C);

                        $IF dbms_db_version.ver_le_12 $THEN
                            l_list_estoque.append(l_item.to_json_value);
                        $ELSE
                            l_list_estoque.append(l_item/*.to_json_value*/);
                        $END
                end loop;


           l_root.put('tipo_retorno','Projetado Full Salesforce - Tipo 10');
           l_root.put('TotalPages', round(l_total_pages));
           l_root.put('TotalItems', l_total_regs);
           l_root.put('Page', P_PAGE);
           l_root.put('results',l_list_estoque);
        end if;        
        

        if nvl(l_tipo_retorno,0) = 11 then
            $IF dbms_db_version.ver_le_12 $THEN
                l_item := new json();
            $ELSE
                l_item := new JSON_OBJECT_T();
            $END

             defineTotalPages();

             for prod in (
							SELECT *
							  FROM (SELECT 0 AS TIPO, 0 AS FLAG_EXC,
										   LAST_UPDATE_DATE,
										   REPLACE (
											  REPLACE (
												 REPLACE (
													REPLACE (
														  'STK'
													   || TRIM (
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
										   DEP.ID AS WarehouseCode__c,
										   DEP.ID AS DESCRICAODEPOSITO__C,
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
										   stk.cod_produto_ora AS COD_PRODUTO_ORA,
										   REPLACE (TO_CHAR (SALDO_PBSHOP), ',', '.')
											  AS BALANCEPORTOBELLOSHOP__C,
										   REPLACE (TO_CHAR (SALDO_DISPONIVEL), ',', '.') AS BALANCE__C,
										   REPLACE (TO_CHAR (SALDO_EXPORTACAO), ',', '.') AS EXPORTBALANCE__C,
										   0 AS STOCKFRACTION__C                    -- Percentual de ponta
									  FROM apps.xxpb_estoque_api stk
									  INNER JOIN (SELECT MEANING COD, LOOKUP_CODE ID FROM FND_LOOKUP_VALUES WHERE     language = USERENV ('LANG') AND enabled_flag = 'Y' AND lookup_type = 'ONT_DEPOSITOS_SALES_PB') DEP ON STK.COD_DEPOSITO = DEP.COD
/*
									UNION ALL
									SELECT 1 AS TIPO, FLAG_EXC AS FLAG_EXC,
										   LAST_UPDATE_DATE,
										   REPLACE (
											  REPLACE (
												 REPLACE (
													REPLACE (
														  'STK'
													   || TRIM (
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
										   DEP.ID AS WarehouseCode__c,
										   DEP.ID AS DESCRICAODEPOSITO__C,
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
										   stk.cod_produto_ora AS COD_PRODUTO_ORA,
										   '0' AS BALANCEPORTOBELLOSHOP__C,
										   '0' AS BALANCE__C,
										   '0' AS EXPORTBALANCE__C,
										   0 AS STOCKFRACTION__C
									  FROM APPS.XXPB_ESTOQUE_API_ZERO STK
									  INNER JOIN (SELECT MEANING COD, LOOKUP_CODE ID FROM FND_LOOKUP_VALUES WHERE     language = USERENV ('LANG') AND enabled_flag = 'Y' AND lookup_type = 'ONT_DEPOSITOS_SALES_PB') DEP ON STK.COD_DEPOSITO = DEP.COD
									 WHERE    (FLAG_EXC = 1 and p_last_date is not null)
										   OR (    FLAG_STK = 0
											   AND NOT EXISTS
														  (SELECT 1
															 FROM XXPB_ESTOQUE_API
															WHERE     COD_PRODUTO_ORA =
																		 STK.COD_PRODUTO_ORA
																  AND COD_DEPOSITO = STK.COD_DEPOSITO
																  AND SALDO_DISPONIVEL > 0))
*/
                                                                  )
							 WHERE (   (   balanceportobelloshop__c <> '0'
										OR balance__c <> '0'
										OR exportBalance__c <> '0')
									OR tipo = 1)
							 and (last_update_date >= to_date(p_last_date,'YYYY-MM-DD HH24:MI:SS') or p_last_date is null)
                             Order by LAST_UPDATE_DATE asc offset l_page rows fetch next l_rows rows only
                                                                                     
                                    )  loop
                        l_item.put('LAST_UPDATE_DATE', prod.LAST_UPDATE_DATE);
                        l_item.put('COD_PRODUTO_ORA', prod.COD_PRODUTO_ORA);
                        l_item.put('EXTERNALCODE__C', prod.EXTERNALCODE__C);
                        l_item.put('WAREHOUSECODE__C', prod.WAREHOUSECODE__C);
                        l_item.put('DESCRICAODEPOSITO__C', prod.DESCRICAODEPOSITO__C);
                        l_item.put('CODTONALIDADECALIBRE__C', prod.CODTONALIDADECALIBRE__C);
                        l_item.put('NAME', prod.NAME);
                        l_item.put('BALANCEPORTOBELLOSHOP__C', prod.BALANCEPORTOBELLOSHOP__C);
                        l_item.put('BALANCE__C', prod.BALANCE__C);
                        l_item.put('EXPORTBALANCE__C', prod.EXPORTBALANCE__C);
                        l_item.put('STOCKFRACTION__C', prod.STOCKFRACTION__C);
						if prod.FLAG_EXC = 0 THEN 
							l_item.put('EXCLUDE', 'N');
						ELSE
							l_item.put('EXCLUDE', 'Y');
						END IF;
                        $IF dbms_db_version.ver_le_12 $THEN
                            l_list_estoque.append(l_item.to_json_value);
                        $ELSE
                            l_list_estoque.append(l_item/*.to_json_value*/);
                        $END
                end loop;

           l_root.put('tipo_retorno','Saldo em Estoque Full Salesforce - Tipo 11');
           l_root.put('TotalPages', round(l_total_pages));
           l_root.put('TotalItems', l_total_regs);
           l_root.put('Page', P_PAGE);
          l_root.put('results',l_list_estoque);
        end if;        


        if nvl(l_tipo_retorno,0) = 9 and l_cd_produto is not null then

          for prod in ( Select msi.segment1 
                          from mtl_system_items_b msi
                         where msi.organization_id = pb_master_organization_id
                           and msi.segment1 like l_cd_produto||'%')  loop

                 --Verificar se tem Projecao..
                 v_projetado := false;
                 open C_PROJECAO(prod.segment1, l_deposito);
                 fetch c_PROJECAO BULK COLLECT into r_PROJECAO;
                 if c_PROJECAO%rowcount = 0 then
                   v_projetado := false;
                 else
                   v_projetado := true;
                 end if;
                 close c_PROJECAO;

                 --Verificar se tem Estoque..
                 v_estoque := false;
                 open C_ESTOQUE(prod.segment1, null,l_canal, nvl(l_estoque_zerado,0));
                 fetch C_ESTOQUE BULK COLLECT into R_estoque;
                 if C_ESTOQUE%rowcount = 0 then
                   v_estoque := false;
                 else
                   v_estoque := true;
                 end if;
                 close C_ESTOQUE;
                 --

                $IF dbms_db_version.ver_le_12 $THEN
                    l_root_c := json();
                    l_list_saldo := new json_list();
                $ELSE
                    l_root_c := JSON_OBJECT_T();
                    l_list_saldo := new JSON_ARRAY_T();
                $END

                IF v_estoque THEN

                  FOR indx IN 1 .. r_ESTOQUE.COUNT LOOP


                    $IF dbms_db_version.ver_le_12 $THEN
                        l_item := new json();
                    $ELSE
                        l_item := new JSON_OBJECT_T();
                    $END

                    l_item.put('dataEstoque', R_estoque(indx).last_update_date);
                    l_item.put('cod_deposito', R_estoque(indx).DEP);
                    l_item.put('cod_tonalidade_calibre', R_estoque(indx).COD_TONALIDADE_CALIBRE);
                    l_item.put('saldo_disponivel', R_estoque(indx).SALDO_DISPONIVEL);
                    l_item.put('saldo_pbshop', R_estoque(indx).SALDO_PBSHOP);
                    l_item.put('saldo_porcelanateria', R_estoque(indx).SALDO_PBSHOP);

                    if R_estoque(indx).COD_DEPOSITO NOT IN ('CWB', 'CSA', 'CJU', 'CDC', 'CGO') then
                      l_item.put('saldo_engenharia', R_estoque(indx).SALDO_DISPONIVEL);
                      l_item.put('saldo_revenda', R_estoque(indx).SALDO_DISPONIVEL);
                      l_item.put('saldo_exportacao', R_estoque(indx).SALDO_EXPORTACAO);
                    else
                      l_item.put('saldo_engenharia', 0);
                      l_item.put('saldo_revenda', 0);
                      l_item.put('saldo_exportacao', 0);
                    end if;

                    $IF dbms_db_version.ver_le_12 $THEN
                        l_list_saldo.append(l_item.to_json_value);
                    $ELSE
                        l_list_saldo.append(l_item/*.to_json_value*/);
                    $END
                  END LOOP;
                  l_root_c.put('Estoque',l_list_saldo);

                END IF;          

                $IF dbms_db_version.ver_le_12 $THEN
                    l_list_pro := new json_list();
                $ELSE        
                    l_list_pro := new JSON_ARRAY_T();
                $END
                v_periodosATP := NULL;
                if v_projetado then
                     FOR indx IN 1 .. r_PROJECAO.COUNT LOOP
                       if nvl(R_PROJECAO(indx).TIJUCAS,0) = 0 or (nvl(R_PROJECAO(indx).TIJUCAS,0) = 1 AND R_PROJECAO(indx).ID_PERIODO <> 10) THEN 
                           if instr(' ' || v_periodosATP, '[' || R_PROJECAO(indx).ID_PERIODO || ']') <= 0 then
                               v_periodosATP := v_periodosATP || '[' || R_PROJECAO(indx).ID_PERIODO || ']';

                               $IF dbms_db_version.ver_le_12 $THEN
                                   l_item := new json();
                               $ELSE
                                   l_item := new JSON_OBJECT_T();
                               $END
                               l_item.put('dataProjetado',R_PROJECAO(indx).last_update_date);
                               l_item.put('cod_deposito', R_PROJECAO(indx).DEP);
                               l_item.put('estoque_fabrica', NVL(R_PROJECAO(indx).ESTOQUE_FABRICA,0));
                               l_item.put('descr_periodo', R_PROJECAO(indx).DS_PERIODO);
                               l_item.put('seq_ordenacao', R_PROJECAO(indx).ID_PERIODO); 
                               l_item.put('saldo_disponivel', R_PROJECAO(indx).QT_SALDO_DISPONIVEL);
                               l_item.put('saldo_pbshop', R_PROJECAO(indx).QT_SALDO_DISPONIVEL_PBSHOP);
                               l_item.put('saldo_engenharia', R_PROJECAO(indx).QT_SALDO_DISPONIVEL);
                               l_item.put('saldo_revenda', R_PROJECAO(indx).QT_SALDO_DISPONIVEL);
                               l_item.put('saldo_exportacao', R_PROJECAO(indx).QT_SALDO_DISPONIVEL);
                               l_item.put('saldo_porcelanateria', R_PROJECAO(indx).QT_SALDO_DISPONIVEL_PBSHOP);

                               $IF dbms_db_version.ver_le_12 $THEN
                                   l_list_pro.append(l_item.to_json_value);
                               $ELSE        
                                   l_list_pro.append(l_item/*.to_json_value*/);
                               $END
                           end if;
                       end if; 
                     END LOOP;
                     l_root_c.put('Projetado',l_list_pro);
                end if;     
                $IF dbms_db_version.ver_le_12 $THEN
                    l_list_estoque.append(l_root_c.to_json_value);
                $ELSE
                    l_list_estoque.append(l_root_c/*.to_json_value*/);
                $END

                l_root.put(prod.segment1,l_list_estoque);

                --l_list_com.put(prod.segment1,
                --l_list_volume := JSON_ARRAY_T();
                --l_list_volume.append(l_item/*.to_json_value*/);
                --l_root_c.put('Volume',l_list_volume);


          END LOOP;

/*         htp.p('Content-Type: application/json');
         owa_util.http_header_close;
         $IF dbms_db_version.ver_le_12 $THEN
             l_root.htp;
         $ELSE
             htp_print_clob(l_root.to_clob);
         $END    
*/
        end if;


        if nvl(l_tipo_retorno,0) = 8 and (l_produtos_in is not null or l_produtos_in2 is not null) then 
            for prod in (
                      SELECT A.COD_DEPOSITO,
                             A.DS_DEPOSITO DEP,
                             A.COD_TONALIDADE_CALIBRE,
                             A.COD_PRODUTO_ORA,
                             A.SALDO_DISPONIVEL,
                             A.SALDO_PBSHOP,
                             A.SALDO_EXPORTACAO,
                             A.LAST_UPDATE_DATE
                        FROM    XXPB_ESTOQUE_API A
                       WHERE  1 = 1 
                             AND (a.COD_PRODUTO_ORA IN (select column_value from table(l_tab)) or l_produtos_in is null)
                             AND ((NVL(l_canal,0) = 2 AND A.COD_DEPOSITO IN('EET','CIT')) OR NVL(l_canal,0) <> 2)
                    ORDER BY a.cod_produto_ora, a.COD_DEPOSITO, a.COD_TONALIDADE_CALIBRE
                    )  loop
                        $IF dbms_db_version.ver_le_12 $THEN
                            l_item := new json();
                        $ELSE
                            l_item := new JSON_OBJECT_T();
                        $END
                        l_item.put('Codigo', prod.COD_PRODUTO_ORA);
                        l_item.put('dataEstoque', prod.last_update_date);
                        l_item.put('cod_deposito', prod.DEP);
                        l_item.put('cod_tonalidade_calibre', prod.COD_TONALIDADE_CALIBRE);
                        l_item.put('saldo_disponivel', prod.SALDO_DISPONIVEL);
                        l_item.put('saldo_pbshop', prod.SALDO_PBSHOP);
                        l_item.put('saldo_porcelanateria', prod.SALDO_PBSHOP);
                        if prod.COD_DEPOSITO NOT IN ('CWB', 'CSA', 'CJU', 'CDC', 'CGO') then
                          l_item.put('saldo_engenharia', prod.SALDO_DISPONIVEL);
                          l_item.put('saldo_revenda', prod.SALDO_DISPONIVEL);
                          l_item.put('saldo_exportacao', prod.SALDO_EXPORTACAO);
                        else
                          l_item.put('saldo_engenharia', 0);
                          l_item.put('saldo_revenda', 0);
                          l_item.put('saldo_exportacao', 0);
                        end if;
                        $IF dbms_db_version.ver_le_12 $THEN
                            l_list_estoque.append(l_item.to_json_value);
                        $ELSE
                            l_list_estoque.append(l_item/*.to_json_value*/);
                        $END
                end loop;

            if l_produtos_in2 IS NOT NULL then
                for prod in (
                          SELECT A.COD_DEPOSITO,
                                 A.DS_DEPOSITO DEP,
                                 A.COD_TONALIDADE_CALIBRE,
                                 A.COD_PRODUTO_ORA,
                                 A.SALDO_DISPONIVEL,
                                 A.SALDO_PBSHOP,
                                 A.SALDO_EXPORTACAO,
                                 A.LAST_UPDATE_DATE
                            FROM    XXPB_ESTOQUE_API A
                           WHERE  1 = 1 
                                 AND a.COD_PRODUTO_ORA IN (select column_value from table(l_tab2))
                                 AND ((NVL(l_canal,0) = 2 AND A.COD_DEPOSITO IN('EET','CIT')) OR NVL(l_canal,0) <> 2)
                        ORDER BY a.cod_produto_ora, a.COD_DEPOSITO, a.COD_TONALIDADE_CALIBRE
                        )  loop

                            $IF dbms_db_version.ver_le_12 $THEN
                                l_item := new json();
                            $ELSE
                                l_item := new JSON_OBJECT_T();
                            $END
                            l_item.put('Codigo', prod.COD_PRODUTO_ORA);
                            l_item.put('dataEstoque', prod.last_update_date);
                            l_item.put('cod_deposito', prod.DEP);
                            l_item.put('cod_tonalidade_calibre', prod.COD_TONALIDADE_CALIBRE);
                            l_item.put('saldo_disponivel', prod.SALDO_DISPONIVEL);
                            l_item.put('saldo_pbshop', prod.SALDO_PBSHOP);
                            l_item.put('saldo_porcelanateria', prod.SALDO_PBSHOP);

                            if prod.COD_DEPOSITO NOT IN ('CWB', 'CSA', 'CJU', 'CDC', 'CGO') then
                              l_item.put('saldo_engenharia', prod.SALDO_DISPONIVEL);
                              l_item.put('saldo_revenda', prod.SALDO_DISPONIVEL);
                              l_item.put('saldo_exportacao', prod.SALDO_EXPORTACAO);
                            else
                              l_item.put('saldo_engenharia', 0);
                              l_item.put('saldo_revenda', 0);
                              l_item.put('saldo_exportacao', 0);
                            end if;
                            $IF dbms_db_version.ver_le_12 $THEN
                                l_list_estoque.append(l_item.to_json_value);
                            $ELSE
                                l_list_estoque.append(l_item/*.to_json_value*/);
                            $END
                    end loop;                    
            end if;
           l_root.put('Estoque Simples - Tipo 8',l_list_estoque);
/*           htp.p('Content-Type: application/json');
           owa_util.http_header_close;
           $IF dbms_db_version.ver_le_12 $THEN
               l_root.htp;
           $ELSE
               htp_print_clob(l_root.to_clob);
           $END  */  

        end if;

        if nvl(l_tipo_retorno,0) = 0 or nvl(l_tipo_retorno,0) = 2 or nvl(l_tipo_retorno,0) = 3 or nvl(l_tipo_retorno,0) = 4 or nvl(l_tipo_retorno,0) = 5 then 
           for prod in ( SELECT distinct REPLACE(IM.DS_LINK_IMAGEM, '{p_size}', '200x200') AS IMAGEM,
                                ITEM_ID,
                                MSI.COD_PRODUTO AS SEGMENT1,
                                REPLACE(REPLACE(PRODUTO,
                                                substr(formato,
                                                       TRIM(instr(formato, '-') + 2)),
                                                ''),
                                        ACABAMENTO_DE_BORDA,
                                        '') AS PRODUTO,
                                PRODUTO AS DS_COMERCIAL,
                                classificacao_fiscal,
                                substr(LINHA, TRIM(instr(LINHA, '-') + 2)) AS LINHA,
                                substr(TIPOLOGIA, TRIM(instr(TIPOLOGIA, '-') + 2)) AS TIPOLOGIA,
                                MATERIAL,
                                DS_COR AS COR,
                                substr(formato, instr(formato, '-') + 2) as FORMATO,
                                substr(formato, instr(formato_real, '-') + 2) FORMATO_REAL,
                                FASE_VIDA,
                                UNIDADE,
                                --peso_liquido, peso_bruto, peso_m2_por_caixa, peso_pc_Por_caixa, peso_m2_por_peca, peso_m2_por_pallete, m2_por_caixa, pc_por_caixa, m2_por_peca, pc_pallets, camada_por_pallete,
                                TO_NUMBER(REPLACE(peso_liquido, ',', '.')) AS PESO_LIQUIDO,
                                TO_NUMBER(REPLACE(peso_bruto, ',', '.')) AS peso_bruto,
                                TO_NUMBER(REPLACE(peso_m2_por_caixa, ',', '.')) as bruto_caixa,
                                TO_NUMBER(REPLACE(peso_pc_por_caixa, ',', '.')) as liquido_peca,
                                TO_NUMBER(REPLACE(peso_m2_por_peca, ',', '.')) as bruto_peca,
                                TO_NUMBER(REPLACE(peso_m2_por_pallete, ',', '.')) as bruto_pallet,
                                /*
                                peso_liquido AS PESO_LIQUIDO,
                                peso_bruto AS peso_bruto, 
                                peso_m2_por_caixa as bruto_caixa, 
                                peso_pc_por_caixa as liquido_peca, 
                                peso_m2_por_peca as bruto_peca, 
                                peso_m2_por_pallete as bruto_pallet,
                                */
                                pc_por_caixa * caixas_por_camada as pc_por_camada,
                                caixas_por_camada as cx_por_camada,
                                pc_por_caixa,
                                pc_pallets,
                                pc_por_m2,
                                TO_NUMBER(REPLACE(m2_por_caixa, ',', '.')) AS m2_por_caixa,
                                TO_NUMBER(REPLACE(m2_por_peca, ',', '.')) AS m2_por_peca,
                                TO_NUMBER(REPLACE(m2_por_camada, ',', '.')) AS m2_por_camada,
                                TO_NUMBER(REPLACE(m2_por_pallete, ',', '.')) AS m2_por_pallete,
                                /*
                                m2_por_caixa AS m2_por_caixa, 
                                m2_por_peca AS m2_por_peca, 
                                m2_por_camada AS m2_por_camada, 
                                m2_por_pallete AS m2_por_pallete,
                                */
                                camada_por_pallete,
                                marca_item,
                                ACABAMENTO_DE_BORDA AS ACABAMENTO,
                                CANAL_VENDAS        AS CANAIS,
                                REJUNTE,
                                --msi.classificacao as classe, NR_FACES
                                CASE
                                  WHEN cc.ATTRIBUTE4 = '1' THEN
                                   'EXTRA'
                                  ELSE
                                   'COMERCIAL'
                                END classe,
                                NR_FACES,
                                msi.ppe
                  FROM CONSULTA_PRODUTO_PB_V MSI
                  LEFT JOIN PEX_LINK_IMAGEM_PRODUTO_EVT IM
                    ON TRIM(TRANSLATE(UPPER(MSI.COD_PRODUTO),
                                      'ABCDEFGHIJKLMNOPQRSTUVXYWZÇ',
                                      ' ')) = TO_CHAR(IM.CD_PRODUTO)
                  LEFT JOIN mtl_system_items_b cc
                    ON cc.ORGANIZATION_ID = pb_master_organization_id
                   AND msi.cod_produto = cc.segment1
                 WHERE 1 = 1
                   and (MSI.COD_PRODUTO = l_cd_produto or l_cd_produto is null)
                   AND (MSI.COD_PRODUTO = l_list_produto or l_list_produto is null)
                   AND (MSI.COD_PRODUTO IN (select column_value from table(l_tab)) or
                       l_produtos_in is null)
                   AND (FASE_VIDA = l_fase_vida or l_fase_vida is null)
            )  loop

                 --Verificar se tem Projecao..
                 v_projetado := false;
                 if nvl(l_tipo_retorno,0) = 0 or nvl(l_tipo_retorno,0) = 4 or nvl(l_tipo_retorno,0) = 5 then 
                     open C_PROJECAO(prod.segment1, l_deposito);
                     fetch c_PROJECAO BULK COLLECT into r_PROJECAO;
                     if c_PROJECAO%rowcount = 0 then
                       v_projetado := false;
                     else
                       v_projetado := true;
                     end if;
                     close c_PROJECAO;
                 end if;

                 --Verificar se tem Estoque..
                 v_estoque := false;
                 if nvl(l_tipo_retorno,0) = 0 or nvl(l_tipo_retorno,0) = 3 or nvl(l_tipo_retorno,0) = 5 then 
                     open C_ESTOQUE(prod.segment1, null,l_canal, nvl(l_estoque_zerado,0));
                     fetch C_ESTOQUE BULK COLLECT into R_estoque;
                     if C_ESTOQUE%rowcount = 0 then
                       v_estoque := false;
                     else
                       v_estoque := true;
                     end if;
                     close C_ESTOQUE;
                 end if;
                 --
                 if  (nvl(l_tipo_retorno,0) <> 3 or nvl(l_com_estoque,0) = 0 or (nvl(l_com_estoque,0) = 1 and v_estoque = true) )
                 AND (nvl(l_tipo_retorno,0) <> 4 or nvl(l_com_projetado,0) = 0 or (nvl(l_com_projetado,0) = 1 and v_projetado = true))
                 then
                     $IF dbms_db_version.ver_le_12 $THEN
                         l_root_c := json();
                     $ELSE
                         l_root_c := JSON_OBJECT_T();
                     $END
                     l_root_c.put('id',prod.ITEM_ID);
                     l_root_c.put('listagem',prod.ITEM_ID);
                     l_root_c.put('Codigo',prod.SEGMENT1);
                     l_root_c.put('Descr',prod.PRODUTO);
                     l_root_c.put('DescrComercial',prod.DS_COMERCIAL);
                     l_root_c.put('urlImagem',prod.IMAGEM);
                     l_root_c.put('urlImagemFundo','');
                     l_root_c.put('fundoEscuro','');

                    if v_projetado then 
                        l_root_c.put('temProjetado','Sim');
                     else
                        l_root_c.put('temProjetado','Nao');
                     end if;

                     if v_estoque then 
                        l_root_c.put('temEstoque','Sim');
                     else
                        l_root_c.put('temEstoque','Nao');
                     end if;                     

                     if nvl(l_tipo_retorno,0) in (0,2,5) then --nvl(l_tipo_retorno,0) = 0 or nvl(l_tipo_retorno,0) = 2 then
                        if nvl(l_tipo_retorno,0) in (0,2) then
                          l_root_c.put('linha',prod.LINHA);
                          l_root_c.put('tipologia',prod.TIPOLOGIA);
                          l_root_c.put('material',prod.MATERIAL);
                          l_root_c.put('cor',prod.COR);
                          l_root_c.put('rejunte',prod.REJUNTE);
                          l_root_c.put('marca',prod.MARCA_ITEM);
                          l_root_c.put('acabamento',prod.ACABAMENTO);
                          l_root_c.put('formato',prod.FORMATO);
                          l_root_c.put('formatoReal',prod.FORMATO_REAL);
                          l_root_c.put('nr_faces',prod.nr_faces);
                          l_root_c.put('classificacaoFiscal',prod.classificacao_fiscal);

                          $IF dbms_db_version.ver_le_12 $THEN
                              l_item := new json();
                          $ELSE
                              l_item := new JSON_OBJECT_T();
                          $END
                          l_item.put('peso_liquido', prod.peso_liquido);
                          l_item.put('peso_bruto', prod.peso_bruto);
                          l_item.put('peso_bruto_caixa', prod.bruto_caixa);
                          l_item.put('peso_liquido_peca', prod.liquido_peca);
                          l_item.put('peso_bruto_peca', prod.bruto_peca);
                          l_item.put('peso_pallet', prod.bruto_pallet);


                          l_item.put('pc_por_m2', prod.pc_por_m2);
                          l_item.put('pc_por_camada', prod.pc_por_camada);
                          l_item.put('cx_por_camada', prod.cx_por_camada);
                          l_item.put('pc_por_caixa', prod.pc_por_caixa);
                          l_item.put('pc_por_pallet', prod.pc_pallets);


                          l_item.put('m2_por_caixa', prod.m2_por_caixa);
                          l_item.put('m2_por_peca', prod.m2_por_peca);
                          l_item.put('m2_por_camada', prod.m2_por_camada);
                          l_item.put('m2_por_pallet', prod.m2_por_pallete);

                          l_item.put('camada_por_pallet', prod.CAMADA_POR_PALLETE);

                          $IF dbms_db_version.ver_le_12 $THEN
                              l_list_volume := json_list();
                              l_list_volume.append(l_item.to_json_value);
                          $ELSE
                              l_list_volume := JSON_ARRAY_T();
                              l_list_volume.append(l_item/*.to_json_value*/);
                          $END
                          l_root_c.put('Volume',l_list_volume);
                        end if;
                        l_root_c.put('faseVida',prod.FASE_VIDA);
                        l_root_c.put('unidade',prod.UNIDADE);
                        l_root_c.put('classe',prod.classe);
                        l_root_c.put('ppe',prod.ppe);
                        l_root_c.put('canais',prod.CANAIS);
                     end if;

                    $IF dbms_db_version.ver_le_12 $THEN
                        l_list_saldo := new json_list();
                    $ELSE
                        l_list_saldo := new JSON_ARRAY_T();
                    $END
                    IF v_estoque THEN

                      FOR indx IN 1 .. r_ESTOQUE.COUNT LOOP

                        $IF dbms_db_version.ver_le_12 $THEN
                            l_item := new json();
                        $ELSE
                            l_item := new JSON_OBJECT_T();
                        $END

                        l_item.put('dataEstoque', to_char(R_estoque(indx).last_update_date,'YYYY-MM-DD'));
                        l_item.put('cod_deposito', R_estoque(indx).cod_deposito);
                        l_item.put('ds_deposito', R_estoque(indx).dep);
                        l_item.put('cod_tonalidade_calibre', R_estoque(indx).COD_TONALIDADE_CALIBRE);
                        l_item.put('saldo_disponivel', R_estoque(indx).SALDO_DISPONIVEL);
                        l_item.put('saldo_pbshop', R_estoque(indx).SALDO_PBSHOP);
                        l_item.put('saldo_porcelanateria', R_estoque(indx).SALDO_PBSHOP);

                        if R_estoque(indx).COD_DEPOSITO NOT IN ('CWB', 'CSA', 'CJU', 'CDC', 'CGO') then
                          l_item.put('saldo_engenharia', R_estoque(indx).SALDO_DISPONIVEL);
                          l_item.put('saldo_revenda', R_estoque(indx).SALDO_DISPONIVEL);
                          l_item.put('saldo_exportacao', R_estoque(indx).SALDO_EXPORTACAO);
                        else
                          l_item.put('saldo_engenharia', 0);
                          l_item.put('saldo_revenda', 0);
                          l_item.put('saldo_exportacao', 0);
                        end if;

                        $IF dbms_db_version.ver_le_12 $THEN
                            l_list_saldo.append(l_item.to_json_value);
                        $ELSE
                            l_list_saldo.append(l_item/*.to_json_value*/);
                        $END
                      END LOOP;
                      l_root_c.put('Estoque',l_list_saldo);

                    END IF;          

                    $IF dbms_db_version.ver_le_12 $THEN
                        l_list_pro := new json_list();
                    $ELSE
                        l_list_pro := new JSON_ARRAY_T();
                    $END
                    v_periodosATP := NULL;
                    if v_projetado then
                         FOR indx IN 1 .. r_PROJECAO.COUNT LOOP
                           if nvl(R_PROJECAO(indx).TIJUCAS,0) = 0 or (nvl(R_PROJECAO(indx).TIJUCAS,0) = 1 AND R_PROJECAO(indx).ID_PERIODO <> 10) THEN 
                               if instr(' ' || v_periodosATP, '[' || R_PROJECAO(indx).ID_PERIODO || ']') <= 0 then
                                   IF upper(l_deposito) <> 'TODOS' THEN 
                                      v_periodosATP := v_periodosATP || '[' || R_PROJECAO(indx).ID_PERIODO || ']';
                                   END IF;

                                   $IF dbms_db_version.ver_le_12 $THEN
                                       l_item := new json();
                                   $ELSE
                                       l_item := new JSON_OBJECT_T();
                                   $END
                                   l_item.put('dataProjetado',to_char(R_PROJECAO(indx).last_update_date,'YYYY-MM-DD'));
                                   l_item.put('cod_deposito', R_PROJECAO(indx).cod_cd);
                                   l_item.put('ds_deposito', R_PROJECAO(indx).DEP);
                                   l_item.put('estoque_fabrica', NVL(R_PROJECAO(indx).ESTOQUE_FABRICA,0));
                                   l_item.put('descr_periodo', R_PROJECAO(indx).DS_PERIODO);
                                   
                                   -- Período do projetado
/*                                   l_item.put('dt_inicial_periodo', substr(R_PROJECAO(indx).DS_PERIODO,1,11));
                                   l_item.put('dt_final_periodo', substr(R_PROJECAO(indx).DS_PERIODO,-11));
*/                                   --
                                   l_item.put('dt_inicial_periodo', to_char(to_date(upper(substr(R_PROJECAO(indx).DS_PERIODO,1,11)),'DD-MON-YYYY','NLS_DATE_LANGUAGE = portuguese'),'YYYY-MM-DD'));
                                   l_item.put('dt_final_periodo', to_char(to_date(upper(substr(R_PROJECAO(indx).DS_PERIODO,-11)),'DD-MON-YYYY','NLS_DATE_LANGUAGE = portuguese'),'YYYY-MM-DD'));
                                   --
/*                                   l_item.put('dt_inicial_periodo', to_char(R_PROJECAO(indx).dt_final_periodo-i_intervalo_periodo_proj,'YYYY-MM-DD'));
                                   l_item.put('dt_final_periodo', to_char(R_PROJECAO(indx).dt_final_periodo,'YYYY-MM-DD'));
*/                                   --
                                   
                                   l_item.put('seq_ordenacao', R_PROJECAO(indx).ID_PERIODO); 
                                   l_item.put('saldo_disponivel', R_PROJECAO(indx).QT_SALDO_DISPONIVEL);
                                   l_item.put('saldo_pbshop', R_PROJECAO(indx).QT_SALDO_DISPONIVEL_PBSHOP);
                                   l_item.put('saldo_transito', R_PROJECAO(indx).VOL_META);
                                   --l_item.put('vol_pedido', R_PROJECAO(indx).VOL_PEDIDO);
                                   l_item.put('saldo_engenharia', R_PROJECAO(indx).QT_SALDO_DISPONIVEL);
                                   l_item.put('saldo_revenda', R_PROJECAO(indx).QT_SALDO_DISPONIVEL);
                                   l_item.put('saldo_exportacao', R_PROJECAO(indx).QT_SALDO_DISPONIVEL);
                                   l_item.put('saldo_porcelanateria', R_PROJECAO(indx).QT_SALDO_DISPONIVEL_PBSHOP);

                                   $IF dbms_db_version.ver_le_12 $THEN
                                       l_list_pro.append(l_item.to_json_value);
                                   $ELSE
                                       l_list_pro.append(l_item/*.to_json_value*/);
                                   $END
                               end if;
                           end if; 
                         END LOOP;
                         l_root_c.put('Projetado',l_list_pro);
                    end if;     
                    $IF dbms_db_version.ver_le_12 $THEN
                        l_list_estoque.append(l_root_c.to_json_value);                    
                    $ELSE
                        l_list_estoque.append(l_root_c/*.to_json_value*/);                    
                    $END
                 end if;

                 --
              end loop;

               if nvl(l_tipo_retorno,0) = 0 then
                   l_root.put('Extração Completa (Dados de Cadastro \ Estoque \ Projetado) - Tipo 0',l_list_estoque);
               end if;

               if nvl(l_tipo_retorno,0) = 2 then
                   l_root.put('Listagem de Dados de Cadastro - Tipo 2',l_list_estoque);
               end if;

               if nvl(l_tipo_retorno,0) = 3 then
                   l_root.put('Listagem de Dados de Cadastro Resumido e Estoque - Tipo 3',l_list_estoque);
               end if;

               if nvl(l_tipo_retorno,0) = 4 then
                   l_root.put('Listagem de Dados de Cadastro Resumido e Estoque Projetado - Tipo 4',l_list_estoque);
               end if;

               if nvl(l_tipo_retorno,0) = 5 then
                   l_root.put('tipo_retorno','Listagem de Dados de Cadastro Resumido e Estoque e Estoque Projetado - Tipo 5');
                   l_root.put('dados',l_list_estoque);
               end if;

/*               htp.p('Content-Type: application/json');
               owa_util.http_header_close;
               $IF dbms_db_version.ver_le_12 $THEN
                   l_root.htp;
               $ELSE
                   htp_print_clob(l_root.to_clob);
               $END  */  

        end if;



      if nvl(l_tipo_retorno,0) = 1 then
        for prod in (
                    --SELECT DISTINCT ITEM_ID, MSI.COD_PRODUTO AS SEGMENT1, FASE_VIDA, UNIDADE, msi.classificacao as classe, SD.SALDO, SD.PB, SD.EXPO, REPLACE(IM.DS_LINK_IMAGEM,'{p_size}','200x200') AS IMAGEM,
                    SELECT DISTINCT ITEM_ID, MSI.COD_PRODUTO AS SEGMENT1, FASE_VIDA, UNIDADE,
                    CASE WHEN cc.ATTRIBUTE4 = '1' THEN 'EXTRA' ELSE 'COMERCIAL' END classe,
                    SD.SALDO, SD.PB, SD.EXPO, REPLACE(IM.DS_LINK_IMAGEM,'{p_size}','200x200') AS IMAGEM,
                    REPLACE(REPLACE(PRODUTO,substr(formato, TRIM(instr(formato,'-') + 2)),''),ACABAMENTO_DE_BORDA,'') AS PRODUTO, PRODUTO AS DS_COMERCIAL
                    --FROM CONSULTA_PRODUTO_PB_V MSI LEFT JOIN PB_IMAGEM_PRODUTO IM ON TRIM(TRANSLATE(UPPER(MSI.COD_PRODUTO),'ABCDEFGHIJKLMNOPQRSTUVXYWZÇ', ' ')) = IM.COD_PRODUTO
                    FROM CONSULTA_PRODUTO_PB_V MSI LEFT JOIN PEX_LINK_IMAGEM_PRODUTO_EVT IM ON TRIM(TRANSLATE(UPPER(MSI.COD_PRODUTO),'ABCDEFGHIJKLMNOPQRSTUVXYWZÇ', ' ')) = TO_CHAR(IM.CD_PRODUTO)
                    LEFT JOIN (SELECT SUM(SALDO_DISPONIVEL) SALDO, SUM(SALDO_PBSHOP) PB, SUM(SALDO_EXPORTACAO) EXPO, COD_PRODUTO_ORA FROM XXPB_ESTOQUE_API GROUP BY COD_PRODUTO_ORA) SD ON MSI.COD_PRODUTO = SD.COD_PRODUTO_ORA 
                    LEFT JOIN mtl_system_items_b cc ON cc.ORGANIZATION_ID = pb_master_organization_id AND msi.cod_produto = cc.segment1
                    WHERE 1 = 1 
                    and (MSI.COD_PRODUTO = l_cd_produto or l_cd_produto is null)
                    AND (MSI.COD_PRODUTO = l_list_produto or l_list_produto is null)
                    AND (MSI.COD_PRODUTO IN (select column_value from table(l_tab)) or l_produtos_in is null)
                    AND (FASE_VIDA = l_fase_vida or l_fase_vida is null)
                    )  loop

                     $IF dbms_db_version.ver_le_12 $THEN
                         l_item := new json();
                     $ELSE
                         l_item := new JSON_OBJECT_T();
                     $END
                     l_item.put('Codigo', prod.segment1);
                     l_item.put('Descr',prod.PRODUTO);
                     l_item.put('DescrComercial',prod.DS_COMERCIAL);
                     l_item.put('Unidade', prod.Unidade);
                     l_item.put('Fase_Vida', prod.fase_vida);
                     l_item.put('Classificacao', prod.classe);
                     l_item.put('Disp_Demais', prod.saldo);
                     l_item.put('Disp_Shop', prod.pb);
                     l_item.put('Disp_Expo', prod.expo);
                     l_item.put('urlImagem',prod.IMAGEM);

                     $IF dbms_db_version.ver_le_12 $THEN
                         l_list_estoque.append(l_item.to_json_value);
                     $ELSE
                         l_list_estoque.append(l_item/*.to_json_value*/);
                     $END

         end loop;
         l_root.put('Listagem de Estoque Disponivel - Tipo 1',l_list_estoque);

      end if;

        ------------------------------------------------------
        -- TIPO 6 - CRIADO POR DANIEL GALLINARI PARA REVENDA
        ------------------------------------------------------
        if nvl(l_tipo_retorno,0) = 6 then
            if l_produtos_in IS NOT NULL then
                for prod in (
                    SELECT DISTINCT ITEM_ID, MSI.COD_PRODUTO AS SEGMENT1, FASE_VIDA, UNIDADE,
                           CASE WHEN cc.ATTRIBUTE4 = '1' THEN 'EXTRA' ELSE 'COMERCIAL' END classe,
                        REPLACE(REPLACE(PRODUTO,substr(formato, TRIM(instr(formato,'-') + 2)),''),ACABAMENTO_DE_BORDA,'') AS PRODUTO, PRODUTO AS DS_COMERCIAL,
                            classificacao_fiscal, 
                            substr(LINHA, TRIM(instr(LINHA,'-') + 2)) AS LINHA,
                            substr(TIPOLOGIA, TRIM(instr(TIPOLOGIA,'-') + 2)) AS TIPOLOGIA,
                            MATERIAL, DS_COR AS COR, 
                            substr(formato, instr(formato,'-') + 2) as FORMATO, 
                            substr(formato, instr(formato_real,'-') + 2) FORMATO_REAL,
                            TO_NUMBER(REPLACE(peso_liquido,',','.')) AS PESO_LIQUIDO, 
                            TO_NUMBER(REPLACE(peso_bruto,',','.')) AS peso_bruto, 
                            TO_NUMBER(REPLACE(peso_m2_por_caixa,',','.')) as bruto_caixa, 
                            TO_NUMBER(REPLACE(peso_pc_por_caixa,',','.')) as liquido_peca, 
                            TO_NUMBER(REPLACE(peso_m2_por_peca,',','.')) as bruto_peca, 
                            TO_NUMBER(REPLACE(peso_m2_por_pallete,',','.')) as bruto_pallet,
                            pc_por_caixa * caixas_por_camada as pc_por_camada, caixas_por_camada as cx_por_camada,
                            pc_por_caixa, pc_pallets, pc_por_m2, 
                            TO_NUMBER(REPLACE(m2_por_caixa,',','.')) AS m2_por_caixa, 
                            TO_NUMBER(REPLACE(m2_por_peca,',','.')) AS m2_por_peca, 
                            TO_NUMBER(REPLACE(m2_por_camada,',','.')) AS m2_por_camada, 
                            TO_NUMBER(REPLACE(m2_por_pallete,',','.')) AS m2_por_pallete,
                            camada_por_pallete,
                            marca_item,
                            ACABAMENTO_DE_BORDA AS ACABAMENTO, CANAL_VENDAS AS CANAIS, REJUNTE, NR_FACES,
                        (SELECT SUM(SALDO_DISPONIVEL) SALDO FROM XXPB_ESTOQUE_API SD WHERE MSI.COD_PRODUTO = SD.COD_PRODUTO_ORA GROUP BY SD.COD_PRODUTO_ORA) SALDO,
                        REPLACE(
                            (
                                SELECT DISTINCT IM.DS_LINK_IMAGEM FROM PEX_LINK_IMAGEM_PRODUTO_EVT IM
                                WHERE TRIM(TRANSLATE(UPPER(MSI.COD_PRODUTO),'ABCDEFGHIJKLMNOPQRSTUVXYWZÇ', ' ')) = TO_CHAR(IM.CD_PRODUTO)
                            ),'{p_size}','500x500') AS IMAGEM
                    FROM CONSULTA_PRODUTO_PB_V MSI
                        LEFT JOIN mtl_system_items_b cc ON cc.ORGANIZATION_ID = pb_master_organization_id AND msi.cod_produto = cc.segment1
                    WHERE MSI.COD_PRODUTO IN (select column_value from table(l_tab))
                        AND (FASE_VIDA = l_fase_vida or l_fase_vida is null)
                    )  loop

                     $IF dbms_db_version.ver_le_12 $THEN
                         l_item := new json();
                     $ELSE
                         l_item := new JSON_OBJECT_T();
                     $END
                     l_item.put('id',prod.ITEM_ID);
                    l_item.put('listagem',prod.ITEM_ID);
                    l_item.put('Codigo',prod.SEGMENT1);
                    l_item.put('Descr',prod.PRODUTO);
                    l_item.put('DescrComercial',prod.DS_COMERCIAL);
                    l_item.put('urlImagem',prod.IMAGEM);
                    l_item.put('urlImagemFundo','');
                    l_item.put('fundoEscuro','');
                    l_item.put('linha',prod.LINHA);
                    l_item.put('tipologia',prod.TIPOLOGIA);
                    l_item.put('material',prod.MATERIAL);
                    l_item.put('cor',prod.COR);
                    l_item.put('rejunte',prod.REJUNTE);
                    l_item.put('marca',prod.MARCA_ITEM);
                    l_item.put('acabamento',prod.ACABAMENTO);
                    l_item.put('formato',prod.FORMATO);
                    l_item.put('formatoReal',prod.FORMATO_REAL);
                    l_item.put('faseVida',prod.FASE_VIDA);
                    l_item.put('classe',prod.classe);
                    l_item.put('nr_faces',prod.nr_faces);
                    l_item.put('classificacaoFiscal',prod.classificacao_fiscal);
                    l_item.put('unidade',prod.UNIDADE);
                    l_item.put('canais',prod.CANAIS);

                    l_item.put('peso_liquido', prod.peso_liquido);
                    l_item.put('peso_bruto', prod.peso_bruto);
                    l_item.put('peso_bruto_caixa', prod.bruto_caixa);
                    l_item.put('peso_liquido_peca', prod.liquido_peca);
                    l_item.put('peso_bruto_peca', prod.bruto_peca);
                    l_item.put('peso_pallet', prod.bruto_pallet);


                    l_item.put('pc_por_m2', prod.pc_por_m2);
                    l_item.put('pc_por_camada', prod.pc_por_camada);
                    l_item.put('cx_por_camada', prod.cx_por_camada);
                    l_item.put('pc_por_caixa', prod.pc_por_caixa);
                    l_item.put('pc_por_pallet', prod.pc_pallets);


                    l_item.put('m2_por_caixa', prod.m2_por_caixa);
                    l_item.put('m2_por_peca', prod.m2_por_peca);
                    l_item.put('m2_por_camada', prod.m2_por_camada);
                    l_item.put('m2_por_pallet', prod.m2_por_pallete);

                    l_item.put('camada_por_pallet', prod.CAMADA_POR_PALLETE);
                     $IF dbms_db_version.ver_le_12 $THEN
                         l_root6.append(l_item.to_json_value);
                     $ELSE
                         l_root6.append(l_item/*.to_json_value*/);
                     $END
                end loop;
            end if;

            if l_produtos_in2 IS NOT NULL then
                for prod in (
                    SELECT DISTINCT ITEM_ID, MSI.COD_PRODUTO AS SEGMENT1, FASE_VIDA, UNIDADE,
                           CASE WHEN cc.ATTRIBUTE4 = '1' THEN 'EXTRA' ELSE 'COMERCIAL' END classe,
                        REPLACE(REPLACE(PRODUTO,substr(formato, TRIM(instr(formato,'-') + 2)),''),ACABAMENTO_DE_BORDA,'') AS PRODUTO, PRODUTO AS DS_COMERCIAL,
                            classificacao_fiscal, 
                            substr(LINHA, TRIM(instr(LINHA,'-') + 2)) AS LINHA,
                            substr(TIPOLOGIA, TRIM(instr(TIPOLOGIA,'-') + 2)) AS TIPOLOGIA,
                            MATERIAL, DS_COR AS COR, 
                            substr(formato, instr(formato,'-') + 2) as FORMATO, 
                            substr(formato, instr(formato_real,'-') + 2) FORMATO_REAL,
                            TO_NUMBER(REPLACE(peso_liquido,',','.')) AS PESO_LIQUIDO, 
                            TO_NUMBER(REPLACE(peso_bruto,',','.')) AS peso_bruto, 
                            TO_NUMBER(REPLACE(peso_m2_por_caixa,',','.')) as bruto_caixa, 
                            TO_NUMBER(REPLACE(peso_pc_por_caixa,',','.')) as liquido_peca, 
                            TO_NUMBER(REPLACE(peso_m2_por_peca,',','.')) as bruto_peca, 
                            TO_NUMBER(REPLACE(peso_m2_por_pallete,',','.')) as bruto_pallet,
                            pc_por_caixa * caixas_por_camada as pc_por_camada, caixas_por_camada as cx_por_camada,
                            pc_por_caixa, pc_pallets, pc_por_m2, 
                            TO_NUMBER(REPLACE(m2_por_caixa,',','.')) AS m2_por_caixa, 
                            TO_NUMBER(REPLACE(m2_por_peca,',','.')) AS m2_por_peca, 
                            TO_NUMBER(REPLACE(m2_por_camada,',','.')) AS m2_por_camada, 
                            TO_NUMBER(REPLACE(m2_por_pallete,',','.')) AS m2_por_pallete,
                            camada_por_pallete,
                            marca_item,
                            ACABAMENTO_DE_BORDA AS ACABAMENTO, CANAL_VENDAS AS CANAIS, REJUNTE, NR_FACES,
                        (SELECT SUM(SALDO_DISPONIVEL) SALDO FROM XXPB_ESTOQUE_API SD WHERE MSI.COD_PRODUTO = SD.COD_PRODUTO_ORA GROUP BY SD.COD_PRODUTO_ORA) SALDO,
                        REPLACE(
                            (
                                SELECT DISTINCT IM.DS_LINK_IMAGEM FROM PEX_LINK_IMAGEM_PRODUTO_EVT IM
                                WHERE TRIM(TRANSLATE(UPPER(MSI.COD_PRODUTO),'ABCDEFGHIJKLMNOPQRSTUVXYWZÇ', ' ')) = TO_CHAR(IM.CD_PRODUTO)
                            ),'{p_size}','500x500') AS IMAGEM
                    FROM CONSULTA_PRODUTO_PB_V MSI
                    LEFT JOIN mtl_system_items_b cc ON cc.ORGANIZATION_ID = pb_master_organization_id AND msi.cod_produto = cc.segment1
                    WHERE MSI.COD_PRODUTO IN (select column_value from table(l_tab2))
                        AND (FASE_VIDA = l_fase_vida or l_fase_vida is null)
                    )  loop

                     $IF dbms_db_version.ver_le_12 $THEN
                         l_item := new json();
                     $ELSE
                         l_item := new JSON_OBJECT_T();
                     $END
                     l_item.put('id',prod.ITEM_ID);
                    l_item.put('listagem',prod.ITEM_ID);
                    l_item.put('Codigo',prod.SEGMENT1);
                    l_item.put('Descr',prod.PRODUTO);
                    l_item.put('DescrComercial',prod.DS_COMERCIAL);
                    l_item.put('urlImagem',prod.IMAGEM);
                    l_item.put('urlImagemFundo','');
                    l_item.put('fundoEscuro','');
                    l_item.put('linha',prod.LINHA);
                    l_item.put('tipologia',prod.TIPOLOGIA);
                    l_item.put('material',prod.MATERIAL);
                    l_item.put('cor',prod.COR);
                    l_item.put('rejunte',prod.REJUNTE);
                    l_item.put('marca',prod.MARCA_ITEM);
                    l_item.put('acabamento',prod.ACABAMENTO);
                    l_item.put('formato',prod.FORMATO);
                    l_item.put('formatoReal',prod.FORMATO_REAL);
                    l_item.put('faseVida',prod.FASE_VIDA);
                    l_item.put('classe',prod.classe);
                    l_item.put('nr_faces',prod.nr_faces);
                    l_item.put('classificacaoFiscal',prod.classificacao_fiscal);
                    l_item.put('unidade',prod.UNIDADE);
                    l_item.put('canais',prod.CANAIS);

                    l_item.put('peso_liquido', prod.peso_liquido);
                    l_item.put('peso_bruto', prod.peso_bruto);
                    l_item.put('peso_bruto_caixa', prod.bruto_caixa);
                    l_item.put('peso_liquido_peca', prod.liquido_peca);
                    l_item.put('peso_bruto_peca', prod.bruto_peca);
                    l_item.put('peso_pallet', prod.bruto_pallet);


                    l_item.put('pc_por_m2', prod.pc_por_m2);
                    l_item.put('pc_por_camada', prod.pc_por_camada);
                    l_item.put('cx_por_camada', prod.cx_por_camada);
                    l_item.put('pc_por_caixa', prod.pc_por_caixa);
                    l_item.put('pc_por_pallet', prod.pc_pallets);


                    l_item.put('m2_por_caixa', prod.m2_por_caixa);
                    l_item.put('m2_por_peca', prod.m2_por_peca);
                    l_item.put('m2_por_camada', prod.m2_por_camada);
                    l_item.put('m2_por_pallet', prod.m2_por_pallete);

                    l_item.put('camada_por_pallet', prod.CAMADA_POR_PALLETE);
                     $IF dbms_db_version.ver_le_12 $THEN
                         l_root6.append(l_item.to_json_value);
                     $ELSE
                         l_root6.append(l_item/*.to_json_value*/);
                     $END
                end loop;
            end if;
        end if;

        ------------------------------------------------------
        -- TIPO 7 - CRIADO POR DANIEL GALLINARI PARA REVENDA
        ------------------------------------------------------
        if nvl(l_tipo_retorno,0) = 7 then
            if l_produtos_in IS NOT NULL then
                for prod in (
                    SELECT DISTINCT MSI.COD_PRODUTO AS SEGMENT1,
                        (SELECT SUM(SALDO_DISPONIVEL) SALDO FROM XXPB_ESTOQUE_API SD WHERE MSI.COD_PRODUTO = SD.COD_PRODUTO_ORA GROUP BY SD.COD_PRODUTO_ORA) SALDO
                    FROM CONSULTA_PRODUTO_PB_V MSI
                    WHERE MSI.COD_PRODUTO IN (select column_value from table(l_tab))
                        AND (FASE_VIDA = l_fase_vida or l_fase_vida is null)
                    )  loop

                     l_root.put(prod.segment1, prod.saldo);
                end loop;
            end if;

            if l_produtos_in2 IS NOT NULL then
                for prod in (
                    SELECT DISTINCT MSI.COD_PRODUTO AS SEGMENT1,
                        (SELECT SUM(SALDO_DISPONIVEL) SALDO FROM XXPB_ESTOQUE_API SD WHERE MSI.COD_PRODUTO = SD.COD_PRODUTO_ORA GROUP BY SD.COD_PRODUTO_ORA) SALDO
                    FROM CONSULTA_PRODUTO_PB_V MSI
                    WHERE MSI.COD_PRODUTO IN (select column_value from table(l_tab2))
                        AND (FASE_VIDA = l_fase_vida or l_fase_vida is null)
                    )  loop

                     l_root.put(prod.segment1, prod.saldo);
                end loop;
            end if;
        end if;
        
        
        
       ------------------------------------------------------
        -- TIPO 7 - CRIADO POR DANIEL GALLINARI PARA REVENDA
        ------------------------------------------------------
        if nvl(l_tipo_retorno,0) = 10 then
            if l_produtos_in IS NOT NULL then
                for prod in (
                    SELECT DISTINCT MSI.COD_PRODUTO AS SEGMENT1,
                        (SELECT SUM(SALDO_DISPONIVEL) SALDO FROM XXPB_ESTOQUE_API SD WHERE MSI.COD_PRODUTO = SD.COD_PRODUTO_ORA GROUP BY SD.COD_PRODUTO_ORA) SALDO
                    FROM CONSULTA_PRODUTO_PB_V MSI
                    WHERE MSI.COD_PRODUTO IN (select column_value from table(l_tab))
                        AND (FASE_VIDA = l_fase_vida or l_fase_vida is null)
                    )  loop

                     l_root.put(prod.segment1, prod.saldo);
                end loop;
            end if;

            if l_produtos_in2 IS NOT NULL then
                for prod in (
                    SELECT DISTINCT MSI.COD_PRODUTO AS SEGMENT1,
                        (SELECT SUM(SALDO_DISPONIVEL) SALDO FROM XXPB_ESTOQUE_API SD WHERE MSI.COD_PRODUTO = SD.COD_PRODUTO_ORA GROUP BY SD.COD_PRODUTO_ORA) SALDO
                    FROM CONSULTA_PRODUTO_PB_V MSI
                    WHERE MSI.COD_PRODUTO IN (select column_value from table(l_tab2))
                        AND (FASE_VIDA = l_fase_vida or l_fase_vida is null)
                    )  loop

                     l_root.put(prod.segment1, prod.saldo);
                end loop;
            end if;
        end if;        

    END LOOP; -- fim REQUISICAO

    if nvl(l_tipo_retorno,0) <> 6 /*nvl(l_tipo_retorno,0) = 1 or nvl(l_tipo_retorno,0) = 7*/ then 
        htp.p('Content-Type: application/json');
        owa_util.http_header_close;
        $IF dbms_db_version.ver_le_12 $THEN
            l_root.htp;
        $ELSE
            htp_print_clob(l_root.to_clob);
        $END    
    end if;

    if nvl(l_tipo_retorno,0) = 6 then
        htp.p('Content-Type: application/json');
        owa_util.http_header_close;
        $IF dbms_db_version.ver_le_12 $THEN
            l_root6.htp;
        $ELSE
            htp_print_clob(l_root6.to_clob);
        $END    
    end if;

/*

   if nvl(l_tipo_retorno,0) = 8 then
       l_root.put('Estoque Simples - Tipo 8',l_list_estoque);
       owa_util.http_header_close;
       htp.p('Content-Type: application/json');
       l_root.htp();     
   end if;
*/



END;
/