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
   -- |   Modulo Order Management da solucao                            |
   -- |   solucao Oracle release 12.2.10.                               |
   -- |                                                                 |
   -- | CREATED BY                                                      |
   -- |   Guilherme Rodrigues     REVISION 1.0          17/12/2021      |
   -- |   Guilherme Rodrigues     REVISION 1.1          17/03/2022      |
   -- |   Guilherme Rodrigues     REVISION 1.2          08/04/2022      |
   -- |                                                                 |
   -- | UPDATED BY                                                      |
   -- |                                                                 |
   -- +=================================================================+
   PROCEDURE p_gera_dados_cli_po (errbuf          OUT VARCHAR2,
                                  errcode         OUT VARCHAR2,
                                  p_completa   IN     NUMBER);


   PROCEDURE  (errbuf          OUT VARCHAR2,
                                        errcode         OUT VARCHAR2,
                                        p_completa   IN     NUMBER);


   PROCEDURE p_gera_dados_estoque_prj (errbuf    OUT VARCHAR2,
                                       errcode   OUT VARCHAR2);


   procedure print_pdf(p_header_id number,
                        p_fl_custom boolean default false);

   function print_pdf_local(p_header_id number) return blob;



END PB_INTEGRA_SALESFORCE;
/

CREATE OR REPLACE PACKAGE BODY APPS.PB_INTEGRA_SALESFORCE
IS

  type salesresp_rec is record (
   salesrep_id number,
   name ra_salesreps_all.name%type,
   salesrep_number ra_salesreps_all.salesrep_number%type,
   percent oe_sales_credits.percent%type
  );
  type  salesresp_tab is table  of salesresp_rec index by binary_integer;

  function cf_cliente(p_sold_to_org_id number) return varchar2 is
    l_cd_cliente varchar2(30);
    l_ds_cliente varchar2(100);
  begin

    if p_sold_to_org_id is not null then
      begin

        select hzca.account_number, hzpa.party_name
          into l_cd_cliente, l_ds_cliente
          from hz_cust_accounts_all hzca, hz_parties hzpa
         where hzpa.party_id = hzca.party_id
           and hzca.cust_account_id = p_sold_to_org_id;
        return(substr(l_cd_cliente || ' - ' || l_ds_cliente, 1, 100));
      end;
    else
      return(null);
    end if;
  exception
    when others then
      Raise_application_error(-20000,
                              'Erro ao selecionar Cliente. Erro: ' || sqlerrm);

  end;

  function cf_vendedor(p_org_id      number,
                       p_header_id   number,
                       p_salesrep_id number,
                       x_salesresp       out salesresp_tab) return varchar2 is

    cursor c_sales is
      select oesc.salesrep_id,
             sale.name nome_vendedor,
             sale.salesrep_number numero_vendedor,
             oesc.percent
        from ra_salesreps_all sale, oe_sales_credits oesc
       where sale.org_id = p_org_id
         and sale.salesrep_id = oesc.salesrep_id
         and oesc.header_id = p_header_id
       order by nome_vendedor;

  begin
    open c_sales;
    fetch c_sales bulk collect
      into x_salesresp;
    close c_sales;

    if x_salesresp.count > 1 then
      return('Mais de um Vendedor. Verifique no final.');
    elsif x_salesresp.count = 1 then
      return(substr(x_salesresp(1).salesrep_number || ' - ' || x_salesresp(1).name,
                    1,
                    100));
    else
      return(null);
    end if;

  exception
    when others then
      Raise_application_error(-20001,
                              'Erro ao selecionar Vendedor. Erro: ' ||
                              sqlerrm);
  end;
  function cf_situacao_pedido(p_flow_status_code varchar2) return varchar2 is
    --
    w_situacao varchar2(80);
    --
  begin
    --
    select fnlv.meaning
    into   w_situacao
    from   fnd_lookup_values fnlv
    where  fnlv.lookup_type = 'FLOW_STATUS'
    and    fnlv.language    = 'PTB'
    and    fnlv.lookup_code = p_flow_status_code;
    --
    return(w_situacao);
  exception
    when others then
     Raise_application_error(-20019,'Erro ao selecionar Situação do Pedido. Erro: '||sqlerrm);
  end;
  function cf_portador(p_sold_to_org_id number) return varchar2 is
    l_portador varchar2(30);
  begin
    --
    select cure.receipt_method_name
      into l_portador
      from ar_cust_receipt_methods_v cure
     where cure.customer_id = p_sold_to_org_id
       and cure.primary_flag = 'Y'
       and cure.site_use_id is null;
    --
    return(l_portador);
    --
  exception
    when others then
      Raise_application_error(-20019, 'Erro ao selecionar portador. Erro: ' || sqlerrm);
  end;

  function cf_solicitante return varchar2 is
    cursor c_usuario is
    --select nome from usuario where id =  to_number(apex_util.get_session_state('USER_ID'));
    --l_name usuario.nome%type;
    select 'PortobelloPlay' as nome from dual;
    l_name varchar2(30);
  begin
    open c_usuario;
    fetch c_usuario into l_name;
    close c_usuario;
    return l_name;
  end;
  function cf_metodo_entrega(p_shipping_method_code varchar2)  return varchar2 is
    --
    l_freight_code varchar2(30);
    --
  begin
    --
    select freight_code
    into   l_freight_code
    from   wsh_carriers       wc
          ,wsh_carrier_services wscc
    where  wscc.carrier_id       = wc.carrier_id
    and    wscc.ship_method_code = p_shipping_method_code;
    return(l_freight_code);
  exception
    --
    when others then
      Raise_application_error(-20018,'Erro ao selecionar Método de Entrega. Erro: '||sqlerrm);
  end;
  function cf_regional(p_org_id number,p_sold_to_org_id number,x_mecado out varchar2) return varchar2 is

    l_reg1 varchar2(25);
    l_reg2 varchar2(25);
    l_reg3 varchar2(100);

  begin
    --
    select terr.segment1, terr.segment2, terr.name
      into x_mecado, l_reg2, l_reg3
      from ra_territories terr,
           hz_cust_acct_sites_all hcasa,
           hz_cust_site_uses_all  hcsua
     where hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
       and hcsua.territory_id = terr.territory_id(+)
       and hcsua.site_use_code = 'BILL_TO'
       and hcsua.primary_flag = 'Y'
       and hcasa.cust_account_id = p_sold_to_org_id
       and hcsua.org_id = p_org_id;
       if l_reg1 is not  null or l_reg2 is not null or l_reg3 is not null then
           return(substr(x_mecado || '.' || l_reg2 || ' - ' || l_reg3, 1, 100));
       else
         return  null;
       end if;
  exception
    when others then
     Raise_application_error(-20002, 'Erro ao selecionar Regional. Erro: ' ||p_sold_to_org_id|| sqlerrm);
  end;

  function cf_canal(p_sales_channel_code varchar2) return varchar2 is
    l_cod_canal  varchar2(30);
    l_desc_canal varchar2(80);
  begin
    if p_sales_channel_code is not null then
      begin
        select lookup_code, meaning
          into l_cod_canal, l_desc_canal
          from fnd_lookup_values lova
         where lova.lookup_type = 'SALES_CHANNEL'
           and lova.language = 'PTB'
           and lova.lookup_code = p_sales_channel_code;
        return(substr(l_cod_canal || ' - ' || l_desc_canal, 1, 100));
      end;
    else
      return(null);
    end if;
  exception
    when others then
      Raise_application_error(-20003,
                              'Erro ao selecionar Canal de Vendas. Erro: ' ||
                              sqlerrm);
  end;

  function cf_produto(p_inventory_item_id number) return varchar2 is
    l_prod varchar2(30);
  begin
    select substr(description, 1, 30)
      into l_prod
      from mtl_system_items_b
     where inventory_item_id = p_inventory_item_id
       and organization_id = 43;
    return(l_prod);
  exception
    when no_data_found then
      return(null);
    when others then
      Raise_application_error(-20004,'Erro ao selecionar Descrição do Produto. Erro: ' ||sqlerrm);
  end;


  function cf_peso_liquido_principal(p_org_id      number,
                                     p_header_id   number,
                                     x_item_sem_um out varchar2) return varchar2 is
    --
    w_peso_liquido_unit  number := 0;
    w_peso_liquido_total number := 0;
    w_medida             varchar2(20);
    --
  begin
    --
    begin
      --
      for l in (select line_id, inventory_item_id, ordered_quantity
                  from oe_order_lines_all
                 where org_id = p_org_id
                   and header_id = p_header_id) loop

        --
        begin
          --
          select nvl(syit.unit_weight, 0), syit.weight_uom_code
            into w_peso_liquido_unit, w_medida
            from mtl_system_items_b syit
           where syit.inventory_item_id = l.inventory_item_id
             and syit.organization_id = 43;
          --
          w_peso_liquido_total := w_peso_liquido_total +
                                  (w_peso_liquido_unit * l.ordered_quantity);
          --
        exception
          when no_data_found then
            null;
        end;

        w_peso_liquido_unit := 0;
        --
      end loop;
      --
    exception
      when others then
        Raise_application_error(-20035,
                                'Erro ao selecionar Peso Líquido Total do Pedido e Unidade de Medida. Erro: ' ||
                                sqlerrm);
        --
    end;
    --
    --Mensagem de advertência.
    declare
      retcode  varchar2(5);
      wsucesso boolean;
      w_item   varchar2(1000);
      --
      cursor c1 is
        select m.segment1
          from mtl_system_items_b m, oe_order_lines_all l
         where m.inventory_item_id = l.inventory_item_id
           and m.organization_id = 43
           and m.weight_uom_code is null
           and l.header_id = p_header_id
           and l.org_id = p_org_id;
      --
      rg_c1 c1%rowtype;
      --
    begin
      --
      retcode := 0;
      --
      for rg_c1 in c1 loop
        --
        if w_item is null then
          --
          w_item := rg_c1.segment1;
          --
          retcode := 1;
          --
        else
          --
          w_item := w_item || ' - ' || rg_c1.segment1;
          --
          retcode := 1;
          --
        end if;
        --
      end loop;
      --
      if retcode = 1 then
        --
        x_item_sem_um := '*** Item não possui unidade de medida. Problema nos itens: ' ||
                         w_item;

      end if;
      --
    exception
      --
      when no_data_found then
        null;
      when others then
        Raise_application_error(-200035,
                                'Erro ao verificar Unidade de Medida do Pedido. Erro: ' ||
                                sqlerrm);
        --
    end;
    --
    return to_char(w_peso_liquido_total,'fm999G999G990D00') ||' '|| w_medida;

  exception
    when others then
      Raise_application_error(-200035,
                              'Erro ao selecionar Peso Líquido Total do Pedido. Erro: ' ||
                              sqlerrm);
  end;

  function cf_peso_liquido_item(p_inventory_item_id number,
                                p_ordered_quantity  number) return Number is

    l_peso      number;
    l_un_medida varchar2(3);
    l_peso_liq  number;

  begin
    --
    select nvl(syit.unit_weight, 0), syit.weight_uom_code
      into l_peso, l_un_medida
      from mtl_system_items_b syit
     where syit.inventory_item_id = p_inventory_item_id
       and syit.organization_id = 43;
    --
    l_peso_liq := l_peso * p_ordered_quantity;
    --
    return(l_peso_liq);
  exception
    when no_data_found then
      return(null);
    when others then
      Raise_application_error(-20005,
                              'Erro ao selecionar Peso Líquido do Item. Erro: ' ||
                              sqlerrm);
  end;

  function cf_tabela(p_price_list_id number) return varchar2 is
    --
    l_tabela varchar2(15);
    cursor c_01 is
      select substr(name,1,15)
    from   qp_list_headers_tl
    where  list_header_id = p_price_list_id
    and    language       = 'PTB';
    --
    --
  begin
     open c_01 ;
     fetch c_01 into l_tabela;
     close c_01;
    --
    return(l_tabela);
    --
  exception
    --
    when no_data_found then
      return(null);
    when others then
      Raise_application_error(-20005,'Erro ao selecionar Tabela de Preço. Erro: '||sqlerrm);
      return(null);
    --
  end;
  function cf_status_item (p_line_id number, p_flow_status_code_line varchar2) return varchar2 is

  begin
    if p_flow_status_code_line ='CLOSED' then
      return 'Fechado';
    end if;

    if omp204apo.busca_lote_entrega(p_line_id) is  NULL then
      return  null;
      -- return oe_line_status_pub.Get_Line_Status(p_line_id, p_flow_status_code_line);
    else
       return 'Reservada';
    end if;

  exception
    when others then
      Raise_application_error(-20007,'Erro ao selecionar Status do Item. Erro: '||sqlerrm);
  end;
  function cf_agrupamento(p_line_id number) return varchar2 is
    --
    w_agr varchar2(20);
    --
  begin
    --
 select SET1.SET_NAME
   into w_agr
   FROM OE_ORDER_LINES_ALL       L,
        OE_ORDER_HEADERS_ALL     H,
        OE_SETS                  SET1,
        OE_TRANSACTION_TYPES_ALL OT
  WHERE L.HEADER_ID = H.HEADER_ID
    AND L.SHIPPED_QUANTITY IS NULL
    AND L.ORDERED_QUANTITY > 0
    AND nvl(L.SOURCE_TYPE_CODE, 'INTERNAL') <> 'EXTERNAL'
    AND L.SHIP_SET_ID = SET1.set_id
    AND H.ORDER_TYPE_ID = OT.TRANSACTION_TYPE_ID
    AND H.ORG_ID = OT.ORG_ID
    AND L.OPEN_FLAG = 'Y'
    AND NVL(L.VISIBLE_DEMAND_FLAG, 'N') = 'Y'
    and line_id = p_line_id;
    --
    return(w_agr);
    --
  exception
    --
    when no_data_found then
      return(null);
    when others then
       Raise_application_error(-20007,'Erro ao selecionar Agrupador. Erro: '||sqlerrm);

  end;


function cf_prazo_padrao(p_flow_status_code_line    varchar2,
                         p_line_id                  number,
                         p_inventory_item_id        number,
                         p_ship_from_org_id         number,
                         p_ordered_quantity         number,
                         x_sku_encontrado           out number,
                         x_description_prazo_padrao out varchar2)
  return varchar2 is
  --
  l_sku         varchar2(30);
  l_qtd_estoque number;
  --
begin
  if p_flow_status_code_line = 'CLOSED' then
    l_sku := omp204apo.busca_sku_linha_fechada(p_line_id); -- Busca o SKU.
  else
    l_sku := omp204apo.busca_lote_entrega(p_line_id); -- Busca o SKU.
  end if;
  --
  if l_sku is not null then
    --
    x_sku_encontrado := 1;
    --
    x_description_prazo_padrao := '* Pronta entrega pós liberação imediata de retenções.';
    return(l_sku || '*'); -- Existe alocação HARD. Retorna SKU.
    --
  else
    --
    x_sku_encontrado := 0;
    --
    l_qtd_estoque := omp204apo.busca_qtde_estoque(p_inventory_item_id,
                                                  p_ship_from_org_id);
    --
    if l_qtd_estoque is not null and l_qtd_estoque > p_ordered_quantity then
      --
      x_description_prazo_padrao := '* Pronta entrega pós liberação imediata de retenções.';
      return('Imediato*'); -- Existe estoque para o Item no Depósito corrente.
      --
    else
      --
      return(x_description_prazo_padrao); -- Não existe estoque para o Item.
      --
    end if;
    --
  end if;

exception
  when others then
   Raise_application_error(-20008, 'Erro ao buscar Prazo Padrão. Erro: ' || sqlerrm);
end;
  function cf_data_prometida(p_attribute17 varchar2,p_sku_encontrado number) return varchar2 is
    w_quinz varchar(5);
  begin
    --
    if p_sku_encontrado = 1 then
      return('Imediato*');
    else
      if to_number(to_char(trunc(to_date(p_attribute17, 'DD/MM/YYYY')), 'DD')) <= 15 then
        w_quinz := '1Qui';
      else
        w_quinz := '2Qui';
      end if;
      return(w_quinz || to_char(to_date(p_attribute17, 'DD/MM/YYYY'), 'MonYY'));
    end if;
  exception
    when others then
       Raise_application_error(-20008, 'Erro ao calcular Data Prometida. Erro: ' || sqlerrm);

  end;

  function cf_transportadora(p_customer_trx_id number) return varchar2 is
    l_transp varchar2(100);
  begin
    select max(rtrim(ltrim(substr(oft.description, 1, 99), ' '), ' ')) nome_transportadora
      into l_transp
      from wsh_delivery_details      wdd,
           wsh_delivery_assignments  wda,
           ra_customer_trx_lines_all rctla,
           wsh_carrier_services      wcs,
           org_freight_tl            oft
     where wdd.delivery_detail_id = wda.delivery_detail_id
       and wdd.source_line_id = rctla.interface_line_attribute6
       and to_number(rctla.interface_line_attribute3) = wda.delivery_id
       and rctla.line_type ='LINE'
       and rctla.customer_trx_id = p_customer_trx_id
       and wcs.ship_method_code = wdd.ship_method_code
       and wcs.carrier_id = oft.party_id
       and oft.language = 'PTB'
      -- and oft.organization_id = 331;
       and oft.disable_date is null; -- Query Turnes.

    return(l_transp);
  exception
    when no_data_found then
      return(null);
    when others then
      Raise_application_error(-20010, 'Erro ao selecionar Transportadora. Erro: ' || sqlerrm);
  end;
  function cf_data_canc_dev(p_org_id number ,p_customer_trx_id number, x_data_canc_dev out varchar2 ) return Date is
    l_data   date;
    l_dev_id number;
    l_status varchar2(30);
    --
  begin
    --
    select DISTINCT
           reap.apply_date
          ,reap.customer_trx_id
      into l_data, l_dev_id
      from ar_receivable_applications_all reap
     where reap.applied_customer_trx_id = p_customer_trx_id
       and reap.org_id = p_org_id
       and reap.application_type = 'CM'
       AND ROWNUM < 2;
    --
    if l_dev_id is not null then
      --
      select racu.status_trx
        into l_status
        from ra_customer_trx_all racu
--       where racu.cust_trx_type_id = l_dev_id
       where racu.customer_trx_id = l_dev_id
         and racu.org_id = p_org_id
         AND ROWNUM < 2;
    end if;
    x_data_canc_dev := l_status;
    return(l_data);
    --
  exception
    --
    when no_data_found then
      return(null);
    when others then
      Raise_application_error(-20012,
                  'Erro ao selecionar Data de Cancelamento / Devolução. Erro: ' ||
                  sqlerrm);
      return(null);
      --
  end;


  function cf_valor_total_nota(p_org_id number, p_customer_trx_id number) return Number is
    l_valor_nota number;
  begin
    select sum(cutl.extended_amount)
      into l_valor_nota
      from ra_customer_trx_lines_all cutl
     where customer_trx_id = p_customer_trx_id
       and org_id = p_org_id
       and line_type = 'LINE';
    return(l_valor_nota);
  exception
    when no_data_found then
      return(null);
    when others then
     Raise_application_error(-20011,
                  'Erro ao calcular Valor Total das Notas. Erro: ' || sqlerrm);
  end;


  function cf_imp(p_printing_count number) return varchar2 is
  begin
    if nvl(p_printing_count, 0) > 0 then
      return('Sim');
    else
      return('Não');
    end if;
  exception
    when others then
      Raise_application_error(-20013,
                              'Erro ao selecionar Impressão. Erro: ' ||
                              sqlerrm);
  end;
  function cf_total_icms_st(p_header_id number) return Number is
    l_total_icms_st number;
  begin
    select sum(nvl(price.adjusted_amount, 0))
      into l_total_icms_st
      from oe_price_adjustments price, oe_order_lines_all orli
     where orli.flow_status_code <> 'CANCELLED'
       and orli.header_id = p_header_id
       and price.line_id = orli.line_id
       and price.list_line_type_code = 'TAX'
       and price.tax_code like 'ICMS-ST-%'
       and price.adjusted_amount > 0;
    return(nvl(l_total_icms_st, 0));
  exception
    when no_data_found then
      return(0);
    when others then
      Raise_application_error(-20015,
                  'Erro ao selecionar Total de ICMS-ST. Erro: ' || sqlerrm);
      return(null);
      --
  end;

  function cf_total_ipi(p_header_id number,p_linha_fechada boolean ) return Number is
    l_total_ipi number;
  begin
     if p_linha_fechada then
        select sum(nvl(price.adjusted_amount, 0))
          into l_total_ipi
          from oe_price_adjustments price,
               oe_order_lines_all orli
         where orli.flow_status_code <> 'CANCELLED'
           and orli.header_id = p_header_id
           and price.line_id = orli.line_id
           and price.list_line_type_code = 'TAX'
           and price.tax_code like 'IPI%'
           and price.adjusted_amount > 0;
     else
        select sum(nvl(price.adjusted_amount, 0))
          into l_total_ipi
          from oe_price_adjustments price, oe_order_lines_all orli
         where orli.flow_status_code <> 'CANCELLED'
           and orli.header_id = p_header_id
           and price.line_id = orli.line_id
           and price.list_line_type_code = 'TAX'
           and price.tax_code like 'IPI%'
           and price.adjusted_amount > 0
            and orli.flow_status_code <> 'CLOSED';
     end if;
     return(nvl(l_total_ipi, 0));
  exception
    when no_data_found then
      return 0 ;
    when others then
       Raise_application_error(-20009,'Erro ao selecionar Total de IPI. Erro: ' || sqlerrm);
  end;
  function cf_faturamento_parcial(p_customer_preference_set_code varchar2) return varchar2 is
  begin
    if p_customer_preference_set_code is null then
      return('Sim');
    else
      return('Não');
    end if;
  end;
  function cf_qtd_uom(p_header_id NUMBER,p_uom varchar2) return Number is
    l_qt_m2 number;
  begin
    select sum(orli.ordered_quantity)
    into   l_qt_m2
    from   oe_order_lines_all   orli
    where  orli.header_id          = p_header_id
    and    orli.order_quantity_uom = p_uom;
    return(l_qt_m2);
  exception
    when others then
      Raise_application_error(-20020,'Erro ao selecionar Quantidade em m2. Erro: '||sqlerrm);
  end;
  function cf_valor_liquido_pedido(p_header_id number) return Number is
    l_valor number;
  begin
    select sum(ordered_quantity * unit_selling_price)
      into l_valor
      from oe_order_lines_all orli
     where orli.header_id = p_header_id;
    return(l_valor);
  exception
    when others then
      Raise_application_error(-20021,
                  'Erro ao selecionar Valor Líquido do Pedido. Erro: ' ||
                  sqlerrm);
  end;

  function cf_desconto_item(p_line_id number) return number is
    l_desc number;
  begin
    select distinct nvl(operand, 0)
      into l_desc
      from oe_price_adjustments_v  prad
     where prad.line_id = p_line_id
       and prad.adjustment_name = 'MI DSC ITEM';
    return l_desc;
  exception

    when no_data_found then
        return  0;

    when others then
       Raise_application_error(-20019,
                  'Erro ao selecionar Desconto do Item. Erro: ' || sqlerrm);

  end;
  function cf_desc_extra(p_header_id number,p_context varchar2) return varchar2 is
    w_desc1  varchar2(240);
    w_desc2  varchar2(240);
    w_desc3  varchar2(240);
    w_desc4  varchar2(240);
    w_desc5  varchar2(240);
    w_return varchar2(300);
  begin
    select ltrim(rtrim(attribute7, ' '), ' '),
           ltrim(rtrim(attribute8, ' '), ' '),
           ltrim(rtrim(attribute9, ' '), ' '),
           ltrim(rtrim(attribute10, ' '), ' '),
           ltrim(rtrim(attribute11, ' '), ' ')
      into w_desc1, w_desc2, w_desc3, w_desc4, w_desc5
      from oe_order_headers_all
     where header_id = p_header_id
       and context in (1, 2, 4, 11);
    --
    if p_context in ('1') then
      -- Canal Engenharia - Tem apenas 3 Descontos Extra.
      --
      w_desc4 := null;
      w_desc5 := null;
      --
    end if;
    --
    if w_desc1 is not null then
      w_return := w_desc1;
    end if;
    if w_desc2 is not null then
      w_return := w_return || ' + ' || w_desc2;
    end if;
    if w_desc3 is not null then
      w_return := w_return || ' + ' || w_desc3;
    end if;
    if w_desc4 is not null then
      w_return := w_return || ' + ' || w_desc4;
    end if;
    if w_desc5 is not null then
      w_return := w_return || ' + ' || w_desc5;
    end if;
    --
    return(translate(w_return, ',.', '.,'));
  exception
    when no_data_found then
      return(null);
    when others then
       Raise_application_error(-20022, 'Erro ao selecionar Desconto Extra. Erro: ' || sqlerrm);
  end;

  function cf_prazo(p_payment_term_id number) return Number is
    l_prazo number;
  begin
    select avg(due_days)
    into   l_prazo
    from   ra_terms_lines
    where  term_id = p_payment_term_id;
    return(l_prazo);
  exception
    when no_data_found then
      return(null);
    when others then
      Raise_application_error(-20021,'Erro ao selecionar Prazo de Pagamento. Erro: '||sqlerrm);
  end;
  function cf_condicao_pagamento(p_header_id number) return varchar2 is
    w_cond varchar2(100);
  begin
    select rtrim(ltrim(substr(rate.name,1,100),' '),' ')
    into   w_cond
    from   ra_terms_tl          rate
          ,oe_order_headers_all orhe
    where  rate.term_id   = orhe.payment_term_id
    and    rate.language  = 'PTB'
    and    orhe.header_id = p_header_id;
    --
    return(w_cond);
  exception
    --
    when no_data_found then
      return(null);
    when others then
     Raise_application_error(-20021,'Erro ao selecionar Condição de Pagamento. Erro: '||sqlerrm);

  end;
  function cf_moeda(p_transactional_curr_code varchar2) return Char is
    w_moeda varchar2(240);
  begin
    --
    select description
      into w_moeda
      from fnd_currencies_tl
     where currency_code = p_transactional_curr_code
       and language = 'PTB';
    --
    return(ltrim(rtrim(substr(p_transactional_curr_code || ' - ' || w_moeda,
                              1,
                              100),
                       ' '),
                 ' '));
    --
  exception
    --
    when no_data_found then
      return(null);
    when others then
      Raise_application_error(-20024, 'Erro ao selecionar Moeda. Erro: ' || sqlerrm);
      return(null);
      --
  end;

  function cf_vs (p_header_id number,p_context varchar2) return varchar2 is
    --
    w_vs varchar2(3);
    --
  begin
    --
    if p_context not in ('1') then
      w_vs := 'Não';
    else
      --
      select decode(nvl(attribute19, 'N'), 'N', 'Não', 'Sim')
        into w_vs
        from oe_order_headers_all
       where header_id = p_header_id;
      --
    end if;
    --
    return(w_vs);
    --
  end;

  function cf_tipo_ordem(p_order_type_id number ) return varchar2   is
    --
    w_ordem varchar2(100);
    --
  begin
    --
    select ltrim(rtrim(substr(description,1,100),' '),' ')
    into   w_ordem
    from   oe_transaction_types_tl
    where  transaction_type_id = p_order_type_id
      and language ='PTB';
    --
    return(w_ordem);
    --
  exception
    --
    when no_data_found then
      return(null);
    when others then
       Raise_application_error(-20025,'Erro ao selecionar Tipo de Ordem. Erro: '||sqlerrm);
      return(null);
    --
  end;

  function cf_incoterms(p_fob_point_code varchar2) return varchar2 is
    --
    w_incoterms varchar2(100);
    --
  begin
    --
    select ltrim(rtrim(substr(meaning, 1, 99), ' '), ' ')
      into w_incoterms
      from fnd_lookup_values
     where lookup_type = 'FOB'
       and lookup_code = p_fob_point_code
       and language = (select userenv('LANG') from dual);
    --
    return(w_incoterms);
    --
  exception
    --
    when no_data_found then
      return(null);
    when others then
      Raise_application_error(-20025, 'Erro ao selecionar Incoterms. Erro: ' || sqlerrm);
      --
  end;

  function CF_tipo_container(p_fob_point_code varchar2,p_sold_to_org_id number) return varchar2 is
    --
    w_tipo_container varchar2(100);
    --
  begin
    /*
    select ltrim(rtrim(substr(descricao, 1, 99), ' '), ' ')
      into w_tipo_container
      from exp_portobello_complementos
     where via_transporte = 'MARITIMO'
       and tipo = 'TIPO_CONTAINER'
       and incoterm = p_fob_point_code
       and cliente_id = p_sold_to_org_id;
    */
    return(w_tipo_container);
    --
  exception
    --
    when no_data_found then
      return(null);
    when others then
      Raise_application_error(-20032, 'Erro ao selecionar Tipo Container. Erro: ' || sqlerrm);
      return(null);
      --
  end;

  function cf_via_transporte(p_fob_point_code varchar2,
                             p_sold_to_org_id number) return varchar2 is
    --
    w_via_transporte varchar2(100);
    --
  begin
    --
  /*  select distinct ltrim(rtrim(substr(via_transporte, 1, 99), ' '), ' ')
      into w_via_transporte
      from exp_portobello_complementos
     where incoterm = p_fob_point_code
       and cliente_id = p_sold_to_org_id;*/

    return(w_via_transporte);
    --
  exception
    --
    when no_data_found then
      return(null);
    when others then
    Raise_application_error(-20033, 'Erro ao selecionar Via Transporte. Erro: ' || sqlerrm);

      --
  end;


  function cf_peso_bruto_embarque(p_header_id number)return number is
  --
  w_uom_pb varchar2(5);
  w_sum_pb number;
  --
begin
  --
  select nvl(sum(gross_weight),0)
        ,weight_uom_code
  into   w_sum_pb
        ,w_uom_pb
  from   wsh_delivery_details
  where  source_header_id = p_header_id
  and    organization_id  = 43
  group by weight_uom_code;
  return w_sum_pb;

  --
exception
  --
  when no_data_found then
    return(null);
  when others then
       Raise_application_error(-20031,'Erro ao calcular Peso Bruto de Embarque. Erro: '||sqlerrm);

  --
end;



function cf_porto_origem(p_fob_point_code varchar2,p_sold_to_org_id number) return varchar2 is
  --
  w_porto_origem varchar2(100);
  --
begin
  --
 /* select ltrim(rtrim(substr(descricao,1,99),' '),' ')
  into   w_porto_origem
  from   exp_portobello_complementos
  where  via_transporte = 'MARITIMO'
  and    tipo           = 'PORTO_EMBARQUE'
  and    incoterm       = p_fob_point_code
  and    cliente_id     = p_sold_to_org_id;
  -*/

  return(w_porto_origem);
  --
exception
  --
  when no_data_found then
    return(null);
  when others then
   Raise_application_error(-20029,'Erro ao selecionar Porto de Origem. Erro: '||sqlerrm);

end;
function cf_porto_destino(p_context varchar2,p_attribute9 varchar2) return varchar2 is
  --
  w_porto_destino varchar2(100);
  --
begin

  if p_context in ('6','7','8') then
    --
    w_porto_destino := substr(ltrim(rtrim(p_attribute9,' '),' '),1,99);
    --
  end if;
  --
  return(w_porto_destino);
  --
exception
  --
  when no_data_found then
    return(null);
  when others then
   Raise_application_error(-20030,'Erro ao selecionar Porto de Destino. Erro: '||sqlerrm);
    return(null);
  --
end;



  function cf_tipo_pallet(p_org_id number,p_header_id number )  return varchar2 is
    --
    w_tipo_pallet varchar2(100);
    --
  begin
    --
    select distinct rtrim(ltrim(substr(msib.description,1,99),' '),' ')
    into   w_tipo_pallet
    from   mtl_system_items_b   msib
          ,wsh_delivery_details dede_f
    where  dede_f.delivery_detail_id = (select distinct deas.parent_delivery_detail_id
                                        from   wsh_delivery_assignments deas
                                              ,wsh_delivery_details     dede
                                              ,oe_order_lines_all       orli
                                        where  orli.header_id          = p_header_id
                                        and    orli.org_id             = p_org_id
                                        and    dede.delivery_detail_id = deas.delivery_detail_id
                                        and    dede.source_header_id   = p_header_id
                                        and    dede.source_line_id     = orli.line_id
                                        and    deas.active_flag        = 'Y'
                                        )
    and    dede_f.container_type_code in ('PALLETPADRAO','EUROPALLET');
    --
    return(w_tipo_pallet);
    --
  exception
    --
    when no_data_found then
      return(null);
    when others then
      Raise_application_error(-20028,'Erro ao selecionar Tipo de Pallet. Erro: '||sqlerrm);
    --
  end;

  function cf_agente(p_sold_to_org_id number,x_com_ag out varchar2) return varchar2 is
  --
  w_agente     varchar2(100);

  --
begin
  /*
  select ltrim(rtrim(substr(nome,1,99),' '),' ')
        ,nvl(comissao,0)
  into   w_agente
        ,x_com_ag
  from   exp_portobello_representantes
  where  cliente_id = p_sold_to_org_id;
  */
  return(w_agente);
  --
exception
  --
  when no_data_found then
    return(null);
  when others then
    Raise_application_error(-20024,'Erro ao selecionar Agente e Com. Ag. Erro: '||sqlerrm);
    return(null);
  --
end;
  function cf_desc_total(p_header_id number) return Number is
    w_desc_icms  number;
    w_desc_prazo number;
    w_desc_pont  number;
    w_desc_e1    number;
    w_desc_e2    number;
    w_desc_e3    number;
    w_desc_e4    number;
    w_desc_e5    number;
    desc_aux     number;
    desc_final   number;
    --
  begin
    --
    begin
      --
      select distinct nvl(operand, 0)
        into w_desc_icms
        from oe_price_adjustments_v prad, oe_order_lines_all orli
       where orli.line_id = prad.line_id
         and orli.flow_status_code <> 'CANCELLED'
         and orli.header_id = p_header_id
         and prad.adjustment_name = 'MI DSC ICMS';
      --
    exception
      --
      when others then
        w_desc_icms := 0;
        --
    end;
    --
    begin
      --
      select distinct nvl(operand, 0)
        into w_desc_prazo
        from oe_price_adjustments_v prad, oe_order_lines_all orli
       where orli.line_id = prad.line_id
         and orli.flow_status_code <> 'CANCELLED'
         and orli.header_id = p_header_id
         and prad.adjustment_name = 'MI DSC PRAZO';
      --
    exception
      --
      when others then
        w_desc_prazo := 0;
        --
    end;
    --
    begin
      --
      select distinct nvl(operand, 0)
        into w_desc_pont
        from oe_price_adjustments_v prad, oe_order_lines_all orli
       where orli.line_id = prad.line_id
         and orli.flow_status_code <> 'CANCELLED'
         and orli.header_id = p_header_id
         and prad.adjustment_name = 'MI DSC PONT';
      --
    exception
      --
      when others then
        w_desc_pont := 0;
        --
    end;
    --
    begin
      --
      select distinct nvl(operand, 0)
        into w_desc_e1
        from oe_price_adjustments_v prad, oe_order_lines_all orli
       where orli.line_id = prad.line_id
         and orli.flow_status_code <> 'CANCELLED'
         and orli.header_id = p_header_id
         and prad.adjustment_name = 'MI DSC EXTRA 1';
      --
    exception
      --
      when others then
        w_desc_e1 := 0;
        --
    end;
    --
    begin
      --
      select distinct nvl(operand, 0)
        into w_desc_e2
        from oe_price_adjustments_v prad, oe_order_lines_all orli
       where orli.line_id = prad.line_id
         and orli.flow_status_code <> 'CANCELLED'
         and orli.header_id = p_header_id
         and prad.adjustment_name = 'MI DSC EXTRA 2';
      --
    exception
      --
      when others then
        w_desc_e2 := 0;
        --
    end;
    --
    begin
      --
      select distinct nvl(operand, 0)
        into w_desc_e3
        from oe_price_adjustments_v prad, oe_order_lines_all orli
       where orli.line_id = prad.line_id
         and orli.flow_status_code <> 'CANCELLED'
         and orli.header_id = p_header_id
         and prad.adjustment_name = 'MI DSC EXTRA 3';
      --
    exception
      --
      when others then
        w_desc_e1 := 3;
        --
    end;
    --
    begin
      --
      select distinct nvl(operand, 0)
        into w_desc_e4
        from oe_price_adjustments_v prad, oe_order_lines_all orli
       where orli.line_id = prad.line_id
         and orli.flow_status_code <> 'CANCELLED'
         and orli.header_id = p_header_id
         and prad.adjustment_name = 'MI DSC EXTRA 4';
      --
    exception
      --
      when others then
        w_desc_e4 := 0;
        --
    end;
    --
    begin
      --
      select distinct nvl(operand, 0)
        into w_desc_e5
        from oe_price_adjustments_v prad, oe_order_lines_all orli
       where orli.line_id = prad.line_id
         and orli.flow_status_code <> 'CANCELLED'
         and orli.header_id = p_header_id
         and prad.adjustment_name = 'MI DSC EXTRA 5';
      --
    exception
      --
      when others then
        w_desc_e5 := 0;
        --
    end;
    --
    desc_aux := ((100 - w_desc_icms) / 100) * ((100 - w_desc_prazo) / 100) *
                ((100 - w_desc_pont) / 100) * ((100 - w_desc_e1) / 100) *
                ((100 - w_desc_e2) / 100) * ((100 - w_desc_e3) / 100) *
                ((100 - w_desc_e4) / 100) * ((100 - w_desc_e5) / 100);
    --
    desc_final := (1 - desc_aux) * 100;
    --
    return(desc_final);
  exception
    --
    when no_data_found then
      return(null);
    when others then
       Raise_application_error(-20023,'Erro ao calcular Desconto Total. Erro: ' || sqlerrm);
      return(null);
      --
  end;


 procedure report(p_header_id     number,
                  p_ajuste        boolean default false,
                  p_linha_fechada boolean default true,
                  p_fl_custom     boolean default FALSE )   is

  l_wcol1 number:=9.5;
  l_wcol2 number:=9.6;
  l_wcol3 number:=8.5;
  l_hcol number:=0.28;
  l_agente varchar2(100);
  l_item_sem_um varchar2(4000);
  l_exit_ret boolean;
  l_x    number;
  l_y    number;

  l_ajuste_y number;
  l_ajuste_x number;
  l_ret_y  number;
  l_salesresp_y number;
  l_mercado ra_territories.segment1%type;
  l_item_y number;
  l_total_geral number;
  l_nff_y number;
  l_total_ipi number;
  l_valor_frete number;
  l_sku_encontrou number;
  l_total_icms_st number;
  l_total_nff number;
  l_total_nota number;
  l_total_valor_item number;
  l_prazo_padrao_cp varchar2(250);
  l_data_canc_dev date;
  l_data_canc_dev_status varchar2(30);
  cursor c_end_bill(p_org_id number ,p_cust_account_id number) is
  SELECT  LOC.address1 || ' ' || LOC.address3 || ' ' || LOC.address2 address,
          LOC.address2 address2,
          null fat_address3,
          LOC.address4 address4,
          LOC.city cidade,
          LOC.state estado,
          LOC.postal_code cep,
          ACCT_SITE.cust_account_id
  FROM HZ_CUST_SITE_USES_ALL  SITE,
       HZ_PARTY_SITES         PARTY_SITE,
       HZ_LOCATIONS           LOC,
       HZ_CUST_ACCT_SITES_all ACCT_SITE
 WHERE SITE.SITE_USE_CODE = 'BILL_TO'
   AND SITE.CUST_ACCT_SITE_ID = ACCT_SITE.CUST_ACCT_SITE_ID
   AND ACCT_SITE.PARTY_SITE_ID = PARTY_SITE.PARTY_SITE_ID
   AND PARTY_SITE.LOCATION_ID = LOC.LOCATION_ID
   AND SITE.ORG_ID = ACCT_SITE.ORG_ID
   and ACCT_SITE.Cust_Account_Id = P_Cust_Account_Id
   and ACCT_SITE.Org_Id = P_ORG_ID;

  -- Enderecos
  CURSOR  c_end(p_site_use_id number,p_site_use_code varchar2) is
   select hl.address1 || ' ' || hl.address3 || ' ' || hl.address2 address,
          hl.address2 address2,
          null fat_address3,
          hl.address4 bairro,
          hl.city cidade,
          hl.state estado,
          hl.postal_code cep,
          cust_acct_b.cust_account_id
     from hz_cust_site_uses_all  acct_site_uses,
          hz_cust_accounts_all   cust_acct_b,
          hz_parties             party_b,
          hz_cust_acct_sites_all acct_site,
          hz_locations           hl,
          hz_party_sites         party_site
    where cust_acct_b.party_id = party_b.party_id
      and acct_site_uses.cust_acct_site_id = acct_site.cust_acct_site_id
      and acct_site.party_site_id = party_site.party_site_id
      and acct_site.cust_account_id = cust_acct_b.cust_account_id
      and party_site.location_id = hl.LOCATION_ID
      and acct_site_uses.site_use_id = p_site_use_id
      and acct_site_uses.site_use_code = p_site_use_code
    order by 1;
  --Pedido
  cursor c_principal is
   SELECT H.HEADER_ID
         ,H.ORG_ID
         ,h.invoice_to_org_id
         ,H.ORDER_NUMBER
         ,H.ORDERED_DATE
         ,H.SOLD_TO_ORG_ID
         ,H.SALESREP_ID
         ,H.SHIP_TO_ORG_ID
         ,H.SALES_CHANNEL_CODE
         ,H.ORDER_CATEGORY_CODE
         ,H.FLOW_STATUS_CODE
         ,H.SHIPPING_METHOD_CODE
         ,H.REQUEST_DATE
         ,H.CUST_PO_NUMBER
         ,H.CUSTOMER_PREFERENCE_SET_CODE
         ,H.SHIPPING_INSTRUCTIONS INSTRUCAO_ENTREGA
         ,H.DELIVER_TO_ORG_ID
         ,H.FOB_POINT_CODE
         ,SOLD_TO_ORG.NAME SOLD_TO_ORG_NAME
         ,SOLD_TO_ORG.CUSTOMER_NUMBER
         ,H.ATTRIBUTE18 OBSERVACAO_NF
         ,H.PACKING_INSTRUCTIONS OBSERVACAO_PEDIDO
         ,DECODE(CONTEXT, '6', NVL(H.ATTRIBUTE11, 'Fechado'),
                         '7', NVL(H.ATTRIBUTE11, 'Fechado'),
                         '8', NVL(H.ATTRIBUTE11, 'Fechado'),
                       '12', NVL(H.ATTRIBUTE11, 'Fechado') -- LZ 2011.01.20 - Ação Especial.
                            , NULL)  TIPO_FRETE
        ,DECODE(CONTEXT, '6', OMP003APO.CONVERTE(NVL(H.ATTRIBUTE12, '0')),
                         '7', OMP003APO.CONVERTE(NVL(H.ATTRIBUTE12, '0')),
                         '8', OMP003APO.CONVERTE(NVL(H.ATTRIBUTE12, '0')),
                       '12', OMP003APO.CONVERTE(NVL(H.ATTRIBUTE12, '0')) -- LZ 2011.01.20 - Ação Especial.
                            , NULL)  VALOR_FRETE
        ,h.attribute9
        ,decode(h.context, 4, omp003apo.converte(nvl(h.attribute1,'0')),
                           '0')  del_credere

        ,h.transactional_curr_code
        ,h.payment_term_id payment_term_id
        ,h.order_type_id
        --,h.context
        ,decode(h.context -- LZ 2011.01.20 - Ação Especial.
                 ,'11',(select sales_channel_code from hz_cust_accounts_all where cust_account_id = h.sold_to_org_id)
                 ,'12',(select sales_channel_code from hz_cust_accounts_all where cust_account_id = h.sold_to_org_id)
                 ,h.context)               context
        ,h.conversion_type_code
        ,h.conversion_rate
        ,decode(h.context, 6, h.attribute5,
                           7, h.attribute5,
                           8, h.attribute5,
                           12, h.attribute5, -- LZ 2011.01.20 - Ação Especial.
                           null)  marca_cliente
        ,decode(h.context, 1, omp003apo.converte(h.attribute4),
                           2, omp003apo.converte(h.attribute4),
                           4, omp003apo.converte(h.attribute4),
                           11, omp003apo.converte(h.attribute4), -- LZ 2011.01.20 - Ação Especial.
                           null)  desc_icms
        ,decode(h.context, 1, omp003apo.converte(h.attribute5),
                           2, omp003apo.converte(h.attribute5),
                           4, omp003apo.converte(h.attribute5),
                           11, omp003apo.converte(h.attribute5), -- LZ 2011.01.20 - Ação Especial.
                           null)  desc_prazo
        ,decode(h.context, 1, omp003apo.converte(h.attribute6),
                           2, omp003apo.converte(h.attribute6),
                           4, omp003apo.converte(h.attribute6),
                           11, omp003apo.converte(h.attribute6), -- LZ 2011.01.20 - Ação Especial.
                           null)  desc_pont

FROM     OE_ORDER_HEADERS_ALL    H
        ,OE_SOLD_TO_ORGS_V       SOLD_TO_ORG
WHERE H.SOLD_TO_ORG_ID    = SOLD_TO_ORG.ORGANIZATION_ID  (+)
  and h.order_source_id <> 10
--
--AND      H.ORG_ID            = NVL(:P_ORG_ID,    H.ORG_ID)
AND      H.HEADER_ID         = P_HEADER_ID;
--and        h.created_by        = nvl(:p_created_by,h.created_by)
--
--
--ORDER BY H.ORDER_NUMBER;
  cursor c_items(p_header_id  number) is
  select l.line_id
         ,l.org_id org_id_itens
         ,l.header_id header_id_itens
         ,l.line_number
         ,l.ordered_item
         ,l.order_quantity_uom
         ,l.global_attribute1 cfo
         ,l.schedule_ship_date
         ,l.inventory_item_id
         ,l.ordered_quantity
         ,l.shipped_quantity
         ,l.invoiced_quantity
         ,l.attribute1 st_compr
         ,l.unit_list_price
         ,l.unit_selling_price unit_selling_price
         ,l.ordered_quantity * l.unit_selling_price valor_item
         ,l.attribute4 tonalidade
         ,substr(rtrim(ltrim(l.attribute5,' '),' '),1,1) calibre
         ,to_date(l.attribute6,'DD/MM/YYYY HH24:MI:SS') compr1
         ,l.attribute8 compr_sobre
         ,l.price_list_id
         ,l.flow_status_code flow_status_code_line
         ,l.attribute20 lotes_item
         ,l.global_attribute2 frete_item
         ,l.attribute9 ref_data_cpto
         ,l.attribute11  container
         ,l.attribute2 prazo_padrao
         ,l.ship_from_org_id
         ,l.creation_date data_criacao
         ,l.promise_date
         ,l.attribute17
from oe_order_lines_all l
where l.flow_status_code <> 'CANCELLED'
 and l.header_id  = p_header_id
--order by l.line_number
order by l.attribute11
             ,decode(flow_status_code
               ,'CLOSED',2
               ,1)
        ,l.line_number;
  --Notas fiscais
 cursor c_nff(p_header_id number) is
    select cutr.interface_header_attribute1
              ,cutr.trx_number
              ,cutr.trx_date
              ,cutr.printing_count
              ,cutr.ship_via
              ,cutr.customer_trx_id
    from    ra_customer_trx_all     cutr
    where   cutr.customer_trx_id in (select rctla.customer_trx_id
                                       from ra_customer_trx_lines_all rctla,
                                            oe_order_lines_all oola
                                      where oola.header_id = p_header_id
                                        and rctla.interface_line_attribute6 =  to_char(oola.line_id))
    and     cutr.printing_option = 'PRI';

  cursor c_hold(p_ORG_ID number, p_hold_entity_id varchar2 ) is
    SELECT DISTINCT '* ' || HODE.NAME RET_DS
      FROM OE_HOLD_SOURCES_ALL HOSO,
           OE_HOLD_DEFINITIONS HODE,
           OE_ORDER_HOLDS_ALL  OOHA
     WHERE HOSO.HOLD_ID = HODE.HOLD_ID
       AND OOHA.HOLD_SOURCE_ID = HOSO.HOLD_SOURCE_ID
       AND HOSO.RELEASED_FLAG = 'N'
       AND HOSO.HOLD_ENTITY_CODE = 'O'
       and HOSO.HOLD_ENTITY_ID = p_hold_entity_id
       and HOSO.ORG_ID = p_ORG_ID
     ORDER BY 1;



  l_end_fat c_end%rowtype;
  l_end_ent c_end%rowtype;
  l_end_dis c_end%rowtype;
  l_vendedor varchar2(4000);
  l_salesresp salesresp_tab;
  l_prazo_padrao varchar2(250);
   c_items_01  number (10,5):=0.9;
   c_items_02  number (10,5):=1.3;
   c_items_03  number (10,5):=3.25;
   c_items_04  number (10,5):=1.85;
   c_items_05  number (10,5):=0.5;
   c_items_06  number (10,5):=1.56;
   c_items_07  number (10,5):=1;
   c_items_08  number (10,5):=1;
   c_items_09  number (10,5):=1.5;
   c_items_10  number (10,5):=0;
   c_items_11  number (10,5):=0;
   c_items_12  number (10,5):=0;
   c_items_13  number (10,5):=0;
   c_items_14  number (10,5):=0;
   c_items_15  number (10,5):=0;
   c_items_16  number (10,5):=0;
   c_items_17  number (10,5):=0;
   c_items_18 number (10,5):=0;
   l_font_size number(3):=8;
   l_char_size number;
 begin
    l_char_size:=0.0211*l_font_size;
    pdf.FPDF('L', 'cm', 'A4');
    pdf.openpdf;
    pdf.SetTitle('Relatório Espelho do Pedido');
    pdf.SetAuthor('Portobello S/A');
    pdf.SetCreator('Portobello S/A');


     pdf.setmargins(0.3,1,0.75);
     pdf.SetFillColor(255, 255, 255);
     pdf.SetTextColor(0, 0, 0);

     for r in c_principal loop

      open c_end(r.ship_to_org_id,'SHIP_TO');
      fetch c_end  into l_end_ent;
      close c_end;

      open c_end(r.invoice_to_org_id,'BILL_TO');
      fetch c_end  into l_end_fat;
      close c_end;

      open c_end(r.deliver_to_org_id,'DELIVER_TO');
      fetch c_end  into l_end_dis;
      close c_end;

      l_vendedor := cf_vendedor(p_org_id =>r.org_id,
                                p_header_id=>r.header_id,
                                p_salesrep_id=>r.salesrep_id,
                                x_salesresp=>l_salesresp);
      pdf.SetAliasNbPages;
      pdf.SetFont('Courier', '',l_font_size);
      pdf.setx(0.30);
      pdf.AddPage;

    -- pdf.SetCellSpacing(0);
     l_wcol1:= l_char_size*60;
     l_wcol2:= l_char_size*55;
     l_wcol3:= l_char_size*55;
      c_items_01:=l_char_size*4;
      c_items_02:=l_char_size*7;
      c_items_03:=l_char_size*18;
      c_items_04:=l_char_size*10;
      c_items_05:=(l_char_size*2)+0.05;
      c_items_06:=l_char_size*8;
      c_items_07:=l_char_size*7;
      c_items_08:=l_char_size*6;
      c_items_09:=l_char_size*9;
      c_items_10:=l_char_size*11;
      c_items_11:=l_char_size*9;
      c_items_12:=l_char_size*6;
      c_items_13:=l_char_size*8;
      c_items_14:=l_char_size*7;
      c_items_15:=l_char_size*11;
      c_items_16:=l_char_size*11;
      c_items_17:=l_char_size*3;
      c_items_18:=l_char_size*16;
      pdf.Cell(10*l_char_size,l_hcol,'PORTOBELLO',0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'Data do Relatório: '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'),0,1,'R',1);
      pdf.Cell(l_wcol1,l_hcol,'Solicitante: '||cf_solicitante,0,0,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'Relatório Espelho do Pedido',0,0,'L',1);
      pdf.Cell(5.5,l_hcol,'Página: '||pdf.PageNo||' de {nb}',0,1,'R',1);
      pdf.Cell(l_wcol1,l_hcol,'SITUAÇÃO',0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'EMBARQUE MARÍTIMO',0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'ENDEREÇO FATURAMENTO',0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'------------------------------------------------------------',0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'-------------------------------------------------------',0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'------------------------------------------------------',0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'Número da Ordem: '||r.order_number,0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'Via. Transporte: '||cf_via_transporte(r.fob_point_code,r.sold_to_org_id),0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'Endereço: '||l_end_fat.ADDRESS,0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'Data Emissão: '||to_char(r.ordered_date,'DD-MON-YYYY'),0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'Tipo Container: '||CF_tipo_container(r.fob_point_code,r.sold_to_org_id),0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'Bairro: '||l_end_fat.bairro,0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'Cliente: '||cf_cliente(r.sold_to_org_id),0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'Tipo Pallet: '||cf_tipo_pallet(r.org_id, r.header_id),0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'Cidade: '||l_end_fat.CIDADE,0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'Vendedor: '||l_vendedor,0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'Peso Bruto: '||cf_peso_bruto_embarque(r.header_id),0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'Estado: '||l_end_fat.estado,0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'Regional: '||cf_regional(r.org_id, r.sold_to_org_id,l_mercado),0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'Marca Cliente: '||r.marca_cliente,0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'CEP: '||l_end_fat.CEP,0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'Canal: '||cf_canal(r.sales_channel_code),0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'Porto Origem: '||cf_porto_origem(r.fob_point_code,r.sold_to_org_id),0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'Agente: '||cf_agente(r.sold_to_org_id,l_agente),0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'Porto Destino: '||cf_porto_destino(r.context, r.attribute9),0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'ENDEREÇO ENTREGA:',0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'% Com. Ag.: '||l_agente,0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'Incoterms: '||cf_incoterms(r.fob_point_code),0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'----------------------------------------------------',0,1,'L',1);

      IF p_fl_custom THEN
        pdf.Cell(l_wcol1,l_hcol,'Situação do Pedido: '||cf_situacao_pedido(r.flow_status_code),0,0,'L',1);
        pdf.Cell(l_wcol2,l_hcol,'',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Endereço: '||l_end_ent.address,0,1,'L',1);
        l_ret_y:=pdf.gety;
        pdf.Cell(l_wcol1,l_hcol,'Portador: '||cf_portador(r.sold_to_org_id),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Método Entrega: '||cf_metodo_entrega(r.shipping_method_code),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Peso Líquido: '||cf_peso_liquido_principal(r.org_id,r.header_id,l_item_sem_um),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Dt.Min.Fatura: '||to_char(r.request_date,'DD-MON-YY'),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Ordem de Compra: '||R.CUST_PO_NUMBER,0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Fat.Parcial: '||cf_faturamento_parcial(r.customer_preference_set_code),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Mercado: '||l_mercado,0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Valor Líquido Pedido: '||to_char(cf_valor_liquido_pedido(r.header_id),'fm999G999G990D00'),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Qtd M²: '||to_char(cf_qtd_uom(r.header_id,'m2'),'fm999G999G990D00'),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Qtd Peças: '||to_char(cf_qtd_uom(r.header_id,'pc'),'fm999G999G990'),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Qtd Kg: '||to_char(cf_qtd_uom(r.header_id,'kg'),'fm999G999G990D000'),0,1,'L',1);
        l_ajuste_y:= pdf.GetY;

        l_x:=l_wcol1+0.3;
        pdf.SetXY(l_wcol1+0.3,l_ret_y);
        pdf.Cell(l_wcol2,l_hcol,'FINANCEIRO:',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Bairro '||l_end_ent.bairro,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'------------------------------------------------------',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Cidade: '||l_end_ent.cidade,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Condição de Pagamento: '||cf_condicao_pagamento(r.header_id),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Estado: '||l_end_ent.estado,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Desconto ICMS: '||to_char(r.desc_icms,'fm990d00'),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'CEP: '||l_end_ent.cep,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Moeda: '||cf_moeda(r.transactional_curr_code),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'',0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Tipo de Ordem: '||cf_tipo_ordem(r.order_type_id),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'ENDEREÇO COBRANÇA',0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2-3,l_hcol,'Venda Segregada: '||cf_vs(r.header_id,r.context),0,0,'L',1);
        pdf.Cell(3,l_hcol,'Del Credere: '||to_char(r.del_credere,'fm999g999g990d00') ,0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'----------------------------------------------------',0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,' ',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Endereço: '||l_end_fat.address,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,' ',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Bairro: '||l_end_fat.bairro,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,' ',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Cidade: '||l_end_fat.cidade,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,' ',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Estado: '||l_end_fat.estado,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,' ',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'CEP: '||l_end_fat.cep,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'',0,1,'L',1);
      ELSE
        pdf.Cell(l_wcol1,l_hcol,'Retenções:',0,0,'L',1);
        pdf.Cell(l_wcol2,l_hcol,'',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Endereço: '||l_end_ent.address,0,1,'L',1);
        l_ret_y:=pdf.gety;
        l_exit_ret:=false;
        for ret in c_hold(r.org_id,r.header_id) loop
          pdf.Cell(l_wcol1,l_hcol,ret.ret_ds ,0,1,'L',1);
          l_exit_ret:=true;
        end loop;

        if not l_exit_ret then
          pdf.Cell(l_wcol1,l_hcol,'Não existem retenções.' ,0,1,'L',1);
        end if;

        pdf.Cell(l_wcol1,l_hcol,'Situação do Pedido: '||cf_situacao_pedido(r.flow_status_code),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Portador: '||cf_portador(r.sold_to_org_id),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Método Entrega: '||cf_metodo_entrega(r.shipping_method_code),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Peso Líquido: '||cf_peso_liquido_principal(r.org_id,r.header_id,l_item_sem_um),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Dt.Min.Fatura: '||to_char(r.request_date,'DD-MON-YY'),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Ordem de Compra: '||R.CUST_PO_NUMBER,0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Fat.Parcial: '||cf_faturamento_parcial(r.customer_preference_set_code),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Mercado: '||l_mercado,0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Valor Líquido Pedido: '||to_char(cf_valor_liquido_pedido(r.header_id),'fm999G999G990D00'),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Qtd M²: '||to_char(cf_qtd_uom(r.header_id,'m2'),'fm999G999G990D00'),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Qtd Peças: '||to_char(cf_qtd_uom(r.header_id,'pc'),'fm999G999G990'),0,1,'L',1);
        pdf.Cell(l_wcol1,l_hcol,'Qtd Kg: '||to_char(cf_qtd_uom(r.header_id,'kg'),'fm999G999G990D000'),0,1,'L',1);
        l_ajuste_y:= pdf.GetY;

        l_x:=l_wcol1+0.3;
        pdf.SetXY(l_wcol1+0.3,l_ret_y);
        pdf.Cell(l_wcol2,l_hcol,'FINANCEIRO:',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Bairro '||l_end_ent.bairro,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'------------------------------------------------------',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Cidade: '||l_end_ent.cidade,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Condição de Pagamento: '||cf_condicao_pagamento(r.header_id),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Estado: '||l_end_ent.estado,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Prazo: '||to_char(cf_prazo(r.payment_term_id),'fm999g990d00'),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'CEP: '||l_end_ent.cep,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Desconto ICMS: '||to_char(r.desc_icms,'fm990d00'),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'',0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Desconto Prazo: '||to_char(r.desc_prazo,'fm990d00'),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'ENDEREÇO COBRANÇA',0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Desconto Pontualidade: '||to_char(r.desc_pont,'fm990d00'),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'----------------------------------------------------',0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Desconto Extra: '||cf_desc_extra(r.header_id,r.context),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Endereço: '||l_end_fat.address,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Desconto Total: '||to_char(cf_desc_total(r.header_id),'990d00'),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Bairro: '||l_end_fat.bairro,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Moeda: '||cf_moeda(r.transactional_curr_code),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Cidade: '||l_end_fat.cidade,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'Tipo de Ordem: '||cf_tipo_ordem(r.order_type_id),0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'Estado: '||l_end_fat.estado,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2-3,l_hcol,'Venda Segregada: '||cf_vs(r.header_id,r.context),0,0,'L',1);
        pdf.Cell(3,l_hcol,'Del Credere: '||to_char(r.del_credere,'fm999g999g990d00') ,0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'CEP: '||l_end_fat.cep,0,1,'L',1);
        pdf.SetX(l_x);
        pdf.Cell(l_wcol2,l_hcol,'',0,0,'L',1);
        pdf.Cell(l_wcol3,l_hcol,'',0,1,'L',1);
      END IF;

      l_ajuste_y:= greatest(pdf.GetY,l_ajuste_y);
      pdf.SetX(l_x);
      pdf.Cell(l_wcol2,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'ENDEREÇO DISTRIBUIÇÃO',0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'----------------------------------------------------',0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'Endereço: '||l_end_dis.address,0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'Bairro: '||l_end_dis.bairro,0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'Cidade: '||l_end_dis.cidade,0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'Estado: '||l_end_dis.estado,0,1,'L',1);
      pdf.Cell(l_wcol1,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol2,l_hcol,'',0,0,'L',1);
      pdf.Cell(l_wcol3,l_hcol,'CEP: '||l_end_dis.cep,0,1,'L',1);
      l_item_y :=pdf.GetY;
       -- Ajustes de preço

     if p_ajuste  then
        pdf.SetXY(l_x,l_ajuste_y);
        pdf.Cell(l_wcol2,l_hcol,'AJUSTES DE PREÇO',0,1,'L',1);
        pdf.SetX(l_ajuste_x);
        pdf.Cell(l_wcol2,l_hcol,'------------------------------------------------------',0,1,'L',1);
      else
        pdf.SetXY(l_x,l_ajuste_y);
        pdf.Cell(l_wcol2,l_hcol,'',0,1,'L',1);
      end if;
      pdf.setCellMargin(0);
      -- Itens do pedido
      pdf.SetY(l_item_y);
      pdf.Cell(l_wcol1,l_hcol,'---ITENS PEDIDO-----------------------------------------------------------------------------------------------------------------------------------------------------------',0,1,'L',1);
      pdf.Cell(c_items_01,l_hcol,'Seq',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      --  raise_application_error(-20000,'C'||pdf.GetLineSpacing);

      pdf.Cell(c_items_02,l_hcol,'Código',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_03,l_hcol,'Produto',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_04,l_hcol,'Qtde',0,0,'R',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_05,l_hcol,'Un',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_06,l_hcol,'Tabela',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_07,l_hcol,'Pr. Un.',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);

      IF NOT p_fl_custom THEN
        pdf.Cell(c_items_08,l_hcol,'Desc',0,0,'L',1);
      END IF;

      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_09,l_hcol,'Prev. Fat',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_10,l_hcol,'PrazoPadrão',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_11,l_hcol,'Data Prom',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_12,l_hcol,'Status',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_13,l_hcol,'Caixas',0,0,'R',1);
       pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_14,l_hcol,'Pallets',0,0,'R',1);
       pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_15,l_hcol,'Peso Liq',0,0,'R',1);
       pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_16,l_hcol,'Peso Bruto',0,0,'R',1);
       pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(c_items_17,l_hcol,'Agr',0,0,'L',1);
       pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);

      IF p_fl_custom THEN
        pdf.Cell(c_items_18+1,l_hcol,'Valor Total',0,1,'R',1);
      ELSE
        pdf.Cell(c_items_18,l_hcol,'Valor Total',0,1,'R',1);
      END IF;


      IF p_fl_custom THEN
        pdf.Cell(2,l_hcol,'---- ------- ------------------ ---------- -- -------- ------- --------- ----------- --------- ------ -------- ------- ----------- ----------- --- -----------------------',0,1,'L',1);
      ELSE
        pdf.Cell(2,l_hcol,'---- ------- ------------------ ---------- -- -------- ------- ------ --------- ----------- --------- ------ -------- ------- ----------- ----------- --- ----------------',0,1,'L',1);
      END IF;

      l_total_valor_item:=0;
      l_item_y :=  pdf.GetY;

      for l_itens in c_items(r.header_id) loop
        pdf.SetY(l_item_y) ;
        l_prazo_padrao:= cf_prazo_padrao(l_itens.flow_status_code_line,
                                         l_itens.line_id,
                                         l_itens.inventory_item_id,
                                         l_itens.ship_from_org_id,
                                         l_itens.ordered_quantity,
                                         l_sku_encontrou,
                                         l_prazo_padrao_cp);

        pdf.Cell(c_items_01,l_hcol,l_itens.line_number,0,0,'R',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_02,l_hcol,l_itens.ordered_item,0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        l_y:=pdf.GetY;
        l_x:=pdf.GetX+c_items_03;
        pdf.MultiCell(c_items_03,l_hcol,cf_produto(l_itens.inventory_item_id),0,'L',1,0);
        l_item_y:= pdf.GetY;
        pdf.setXY(l_x,l_y);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_04,l_hcol,to_char(l_itens.ordered_quantity,'999g999g990d000'),0,0,'R',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_05,l_hcol,l_itens.order_quantity_uom,0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_06,l_hcol,cf_tabela(l_itens.price_list_id),0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_07,l_hcol,to_char(l_itens.unit_selling_price,'fm999G999G990D00'),0,0,'R',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);

        IF NOT p_fl_custom THEN
          pdf.Cell(c_items_08,l_hcol,to_char(cf_desconto_item(l_itens.line_id),'fm90D00')||'%',0,0,'R',1);
        END IF;

        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_09,l_hcol,to_char(l_itens.schedule_ship_date,'DD-MON-YY'),0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_10,l_hcol,l_prazo_padrao,0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_11,l_hcol,cf_data_prometida(l_itens.attribute17,l_sku_encontrou),0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_12,l_hcol,cf_status_item(l_itens.line_id,l_itens.flow_status_code_line),0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_13,l_hcol,to_char(inv_convert.inv_um_convert(l_itens.inventory_item_id,2,l_itens.ordered_quantity,l_itens.order_quantity_uom,'cx',null,null),'fm999g990d00'),0,0,'R',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_14,l_hcol,to_char(inv_convert.inv_um_convert(l_itens.inventory_item_id,2,l_itens.ordered_quantity,l_itens.order_quantity_uom,'pa',null,null),'fm999g990d00'),0,0,'R',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_15,l_hcol,to_char(cf_peso_liquido_item(l_itens.inventory_item_id,l_itens.ordered_quantity),'fm999G990D000'),0,0,'R',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_16,l_hcol,to_char(wshp201apo.peso_bruto_linha(l_itens.line_id),'fm999G990D000'),0,0,'R',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(c_items_17,l_hcol,cf_agrupamento(l_itens.line_id),0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);

        IF p_fl_custom THEN
          pdf.Cell(c_items_18+1,l_hcol,to_char(l_itens.Valor_Item,'999G999G990D00'),0,1,'R',1);
        ELSE
          pdf.Cell(c_items_18,l_hcol,to_char(l_itens.Valor_Item,'999G999G990D00'),0,1,'R',1);
        END IF;
        l_total_valor_item:= l_total_valor_item+l_itens.Valor_Item;
      end loop;
      pdf.SetY(l_item_y);
      pdf.SetX(8);
      l_total_ipi:=cf_total_ipi(r.header_id,p_linha_fechada);
      l_valor_frete:=0;
      l_total_icms_st:=cf_total_icms_st(r.header_id);
      l_total_geral :=(nvl(l_total_valor_item,0) +
                       nvl(l_total_ipi,0) +
                       nvl(l_valor_frete,0) +
                       nvl(l_total_icms_st,0));
      pdf.SetX(l_char_size*67);
      pdf.Cell(l_char_size*30,l_hcol,'Total dos Itens: '||to_char(l_total_valor_item,'fm999G999G990D00'),0,0,'L',1);
      pdf.Cell(l_char_size*30,l_hcol,'Total de ICMS-ST: '||to_char(l_total_icms_st,'fm999G999G990D00'),0,1,'L',1);
      pdf.SetX(l_char_size*67);
      pdf.Cell(l_char_size*30,l_hcol,'Total de IPI: '||to_char(l_total_ipi,'fm999G999G990D00'),0,0,'L',1);
      pdf.Cell(l_char_size*49,l_hcol,'Total de Frete: '||to_char(l_valor_frete,'fm999G999G990D00'),0,0,'L',1);
      pdf.Cell(l_char_size*11,l_hcol,'Total Geral: ',0,0,'L',1);
      pdf.Cell(l_char_size*15,l_hcol,to_char(l_total_geral,'fm999G999G990D00'),0,1,'R',1);

      pdf.SetX(l_char_size*67);
      pdf.Cell(2,l_hcol,'---------------------------------------------------------------------------------------------------------',0,1,'L',1);
      pdf.Cell(l_char_size*84,l_hcol,'---NOTAS FISCAIS PEDIDO-------------------------------------------------------------',0,0,'L',1);
      if  l_salesresp.count > 1 then
        pdf.Cell(l_char_size*59,l_hcol,'   ---VENDEDORES PEDIDO------------------------------------',0,1,'L',1);
      else
        pdf.Cell(l_char_size*56,l_hcol,'',0,1,'L',1);
      end if;
      pdf.Cell(l_char_size*8,l_hcol,'Nota',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(l_char_size*9,l_hcol,'Emissão',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(l_char_size*3,l_hcol,'Imp',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(l_char_size*10,l_hcol,'Dt Cancela',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(l_char_size*9,l_hcol,'Devolução',0,0,'L',1);
      pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(l_char_size*9,l_hcol,'Dt Emb',0,0,'L',1);
       pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(l_char_size*16,l_hcol,'Transportador',0,0,'L',1);
       pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(l_char_size*13,l_hcol,'Valor Nota',0,0,'L',1);
       pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
      pdf.Cell(l_char_size*3,l_hcol,'',0,0,'L',1);
      if l_salesresp.count > 1 then
        pdf.Cell(l_char_size*11,l_hcol,'Código',0,0,'L',1);

        pdf.Cell(l_char_size*34,l_hcol,'Nome',0,0,'L',1);
        pdf.Cell(1,l_hcol,'Percentual',0,1,'L',1);
      else
      pdf.Cell(1.3,l_hcol,'',0,1,'L',1);
      end if;
      pdf.Cell(l_char_size*84,l_hcol,'-------- --------- --- ---------- --------- --------- ---------------- -------------',0,0,'L',1);
      if  l_salesresp.count > 1 then
        pdf.Cell(l_char_size*59,l_hcol,'   --------------------------------------------------------',0,1,'L',1);
      else
         pdf.Cell(5,l_hcol,'',0,1,'L',1);
      end if;
      --Informaçoes da NFFF
      l_total_nff:=0;
      l_salesresp_y := pdf.GetY;
      for nff in c_nff(r.header_id) loop

        l_data_canc_dev:= cf_data_canc_dev(r.org_id,nff.customer_trx_id,l_data_canc_dev_status);
        pdf.Cell(l_char_size*8,l_hcol,nff.trx_number ,0,0,'R',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(l_char_size*9,l_hcol,to_char(nff.trx_date,'DD-MON-YY') ,0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(l_char_size*3,l_hcol,cf_imp(nff.printing_count) ,0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(l_char_size*10,l_hcol,to_char(l_data_canc_dev,'DD-MON-YY'),0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(l_char_size*9,l_hcol,l_data_canc_dev_status,0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        pdf.Cell(l_char_size*10,l_hcol,'',0,0,'L',1);
        pdf.Cell(l_char_size*16,l_hcol,cf_transportadora(nff.customer_trx_id),0,0,'L',1);
        pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
        l_total_nota:=cf_valor_total_nota(r.org_id,nff.customer_trx_id);
        pdf.Cell(l_char_size*13,l_hcol,to_char(l_total_nota,'999G990D00'),0,1,'R',1);
        l_total_nff:=l_total_nota+l_total_nff;
      end loop;

       pdf.SetX(l_char_size*72);
       pdf.Cell(l_char_size*14,l_hcol,'--------------',0,1,'L',1);
       pdf.SetX(l_char_size*72);
       pdf.Cell(l_char_size*14,l_hcol,to_char(l_total_nff,'999G990D00'),0,1,'R',1);
       l_nff_y:= pdf.GetY;
       -- Vendedor
       if l_salesresp.count > 1 then
           pdf.sety(l_salesresp_y);

           for i in l_salesresp.first..l_salesresp.last loop
             pdf.SetX(l_char_size*89);
             pdf.Cell(l_char_size*10,l_hcol,l_salesresp(i).salesrep_number,0,0,'R',1);
             pdf.Cell(l_char_size,l_hcol,' ',0,0,'L',1);
             pdf.Cell(l_char_size*34,l_hcol,l_salesresp(i).name,0,0,'L',1);
             pdf.Cell(l_char_size*11,l_hcol,to_char(l_salesresp(i).percent,'990D00'),0,1,'R',1);
           end loop;
       end if;
       pdf.SetY(greatest(pdf.GetY,l_nff_y));



       pdf.Cell(18,l_hcol,'',0,1,'L',1);
       pdf.Cell(4,l_hcol,'Instruções de Entrega: ',0,0,'L',1);

       pdf.MultiCell(24.5,l_hcol,r.instrucao_entrega,0,'J',1);
       pdf.Cell(18,l_hcol,'',0,1,'L',1);
       pdf.Cell(4,l_hcol,'Observações Pedido: ',0,0,'L',1);

       pdf.MultiCell(24.5,l_hcol,r.observacao_pedido,0,'J',1);
       pdf.Cell(26,l_hcol,'',0,1,'L',1);
       pdf.Cell(4,l_hcol,'Observações NF:',0,0,'L',1);
       pdf.MultiCell(24.5,l_hcol,r.observacao_nf,0,'J',1);


    end loop;
    pdf.closepdf;

 end;

  procedure print_pdf(p_header_id NUMBER,
                      p_fl_custom boolean default false) is
  begin
    report(p_header_id, FALSE, TRUE, p_fl_custom);

    pdf.output;
  end;

  function print_pdf_local(p_header_id NUMBER) return blob is 
  begin
    report(p_header_id, FALSE, TRUE, false);
    
    return pdf.getpdf();
  end;





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


      --SELECT MAX (created_date) - 15 / 1440
      --  INTO v_last_exec
      --  FROM apps.XXPB_HIST_PO_CLIENT;

      UPDATE APPS.XXPB_HIST_PO_CLIENT SET PROCESSED = 0;



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
                           AND OHA.ORDERED_DATE >= NVL (null, (SELECT MAX (created_date) - 15 / 1440 FROM apps.XXPB_HIST_PO_CLIENT))))
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