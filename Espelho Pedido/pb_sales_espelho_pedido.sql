CREATE OR REPLACE PACKAGE APPS.pb_sales_espelho_pedido is

 procedure print_pdf(p_header_id number,
                     p_fl_custom boolean default false);

 function print_pdf_local(p_header_id number) return blob;
 
end pb_sales_espelho_pedido;
/
CREATE OR REPLACE PACKAGE BODY APPS.pb_sales_espelho_pedido is
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
    select nome from usuario where id =  to_number(apex_util.get_session_state('USER_ID'));
    l_name usuario.nome%type;
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


end pb_sales_espelho_pedido;