DROP PACKAGE APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG_BY7;
DROP PACKAGE BODY APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG_BY7;

CREATE OR REPLACE PACKAGE APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG_BY7 is
  -- 
  -- ****************************************************************
  -- Objetivo: API para processamento de ordens de venda
  -- ****************************************************************
  -- Autor: GB - By7 - Data: 03/09/2020
  -- ****************************************************************
  --
  c_status_pendente constant varchar2(1) := '0';
  c_status_sucesso  constant varchar2(1) := '1';
  c_status_erro     constant varchar2(1) := '2';
  c_status_advert   constant varchar2(1) := '3';
  vg_user_id        number   := fnd_profile.value('USER_ID');
  MSG_ERRO                                VARCHAR2(500)   := '';
  
  SQL_ERRO_COD                            VARCHAR2(20)    := '';
  SQL_ERRO_MSG                            VARCHAR2(2000)  := '';
  RETORNO_VALIDO                CONSTANT  VARCHAR2(20)    := 'OK';
  RETORNO_ERRO                  CONSTANT  VARCHAR2(20)    := 'ERROR';
  RETORNO_INVALIDO              CONSTANT  VARCHAR2(20)    := 'NO_DATA_FOUND';

  vg_inventory_item_id                    NUMBER;         -- erp_id do item
  vg_segment1                             VARCHAR2(40);   -- código do produto
  vg_primary_uom_code                     VARCHAR2(40);   -- código da unidade de medida
  vg_fase_vida                            VARCHAR2(40);   -- código da fase vida
  vg_item_classificacao                   VARCHAR2(20);   -- código da classificação do item  
  vg_class_fiscal_produto                 VARCHAR2(150);  -- classificação fiscal do produto
  vg_origem_item                          VARCHAR2(150);  -- origem do item
  vg_grupo_imposto                        VARCHAR2(150);  -- grupo de imposto
  ITEM_CLASSIFICACAO_COMERCIAL  CONSTANT  VARCHAR2(20)    := 'COMERCIAL';
  w_id_cota_vendas number;
  w_msg_cota  varchar2(1000);    
  registra_cota varchar2(1); -- Valida a necessidade de inclusão de logs de cota
  l_header_scredit_index       NUMBER;
  w_sales_credit_id NUMBER;
  w_created_by      NUMBER;
  w_creation_date   DATE;
  l_header_scredit_tbl         oe_order_pub.header_scredit_tbl_type;
  w_salesrep_id                NUMBER;

    v_return_status varchar2(1)  := 'S';
    v_log_processo  varchar2(4000) := null;

l_sts_sales_credit           varchar2(1000);
l_msg_count                  number;
l_msg_data                   varchar2(1000);
x_header_rec                 oe_order_pub.header_rec_type;
x_header_val_rec             oe_order_pub.header_val_rec_type;
x_header_adj_tbl             oe_order_pub.header_adj_tbl_type;
x_header_adj_val_tbl         oe_order_pub.header_adj_val_tbl_type;
x_header_price_att_tbl       oe_order_pub.header_price_att_tbl_type;
  x_header_adj_att_tbl         oe_order_pub.header_adj_att_tbl_type;
  x_header_adj_assoc_tbl       oe_order_pub.header_adj_assoc_tbl_type;
  x_header_scredit_tbl         oe_order_pub.header_scredit_tbl_type;
  x_header_scredit_val_tbl     oe_order_pub.header_scredit_val_tbl_type;
x_line_tbl                   oe_order_pub.line_tbl_type;
 x_line_val_tbl               oe_order_pub.line_val_tbl_type;
  x_line_adj_tbl               oe_order_pub.line_adj_tbl_type;
  x_line_adj_val_tbl           oe_order_pub.line_adj_val_tbl_type;
  x_line_price_att_tbl         oe_order_pub.line_price_att_tbl_type;
  x_line_adj_att_tbl           oe_order_pub.line_adj_att_tbl_type;
  x_line_adj_assoc_tbl         oe_order_pub.line_adj_assoc_tbl_type;
  x_line_scredit_tbl           oe_order_pub.line_scredit_tbl_type;
  x_line_scredit_val_tbl       oe_order_pub.line_scredit_val_tbl_type;
  x_lot_serial_tbl             oe_order_pub.lot_serial_tbl_type;
  x_lot_serial_val_tbl         oe_order_pub.lot_serial_val_tbl_type;
x_action_request_tbl         oe_order_pub.request_tbl_type;

l_msg_index_out              number(10);
  --
  $IF  dbms_db_version.ver_le_12 $THEN
    l_root        json := json();
    l_log         json;
    l_logs        json_list;
  $ELSE
    l_root        json_object_t := json_object_t();
    l_log         json_object_t;
    l_logs        json_array_t;
  $END
  -- Estrutura de registro de cabecalho ordem de venda
  type order_header_r is record(cust_po_number               varchar2(20)   -- [obrigatorio] - Numero do pedido de compra do cliente PBG
                               ,cust_po_number2              varchar2(20)   -- [obrigatorio] - Numero do pedido de compra do cliente Final
                               ,cust_so_number               varchar2(20)   -- [Opcional] - Numero do pedido de venda do cliente
                               ,order_type                   varchar2(30)   -- [obrigatorio] - Tipo de ordem do cliente
                               ,currence_code                varchar2(3)    -- [Opcional] - Padrao 'BLR' - codigo de moeda do EBS (BRL e padrao para Brasil)
                               ,pricing_date                 date           -- [Opcional] - Padrao Sysdate - Data do preco
                               ,request_date                 date           -- [Opcional] - Padrao Sysdate - Data de desejo do cliente
                               ,domestic_foreign_ind         varchar2(1)    -- [Obrigatorio] - 'D' - Mercado interno - Domestic, 'F' - Mercado externo - Foreign
                               ,sold_from_fiscal_id          varchar2(18)   -- [Opcional] - Este campo conte a chave de identificacao da organização da qual o cliente está adquirindo seus produtos em sua ordem de compra
                               ,order_source                 varchar2(30)   -- Aplicacao de integracao - usado para reconhecimento em tratativas particulares
                               ,source_hdr_id                number         -- Chave de identificacao da aplicacao de integracao a nivel de cabecalho
                               ,payment_term_code            varchar2(30)   -- [Opcional] - Prazo de pagamento. Caso não seja informado, usar o valor configurado no painel.
                               ,ship_set_code                varchar2(30)   -- [Opcional] - Indica se permite entrega parcial para o pedido
                               ,emailaccwhensuccess          varchar2(300)  -- [Opcional] - E-mail para envio de msg de processamento com sucesso
                               ,emailaccwhenerror            varchar2(300)  -- [Opcional] - E-mail para envio de msg de processamento com erro
                               -- Dados do cliente
                               ,sold_to_fiscal_id            varchar2(18)   -- [Opcional] - Este campo conte a chave de identificacao do cliente que está adquirindo os produtos
                               ,cust_ind_type                varchar2(1)    -- Indicador de tipo de cliente 1-Pessoa Fisica ou 2-Pessoa Juridica
                               ,cust_reg_number              varchar2(14)   -- Numero do CPF ou do CNPJ do cliente, conforme o tipo de pessoa (fisica ou juridica)
                               ,cust_state_inscription       varchar2(14)   -- Inscricao estadual do cliente
                               ,cust_city_inscription        varchar2(14)   -- Inscricao municipal do cliente
                               ,cust_suframa_inscription     varchar2(14)   -- Inscricao Suframa do cliente
                               ,cust_name                    varchar2(150)  -- Nome do cliente
                               ,cust_zip_code                varchar2(8)    -- CEP do cliente
                               ,cust_address1                varchar2(60)   -- Linha 1 do endereço
                               ,cust_address2                varchar2(10)   -- Número do endereço (nulo para sem número)
                               ,cust_address3                varchar2(50)   -- Linha 3 do endereço
                               ,cust_address4                varchar2(50)   -- Linha 4 do endereço
                               ,cust_city                    varchar2(50)   -- Cidade do cliente
                               ,cust_state                   varchar2(2)    -- Sigla do estado do cliente
                               ,cust_country                 varchar2(6)    -- [Opcional] - Padrão 'Brasil' - Pais do cliente
                               ,cust_city_ibge               varchar2(10)   -- Codigo IBGE do municipio
                               ,cust_state_ibge              varchar2(10)   -- Codigo IBGE do estado
                               ,cust_phone_number            varchar2(25)   -- Telefone do cliente
                               ,packing_instructions         varchar2(1000) -- Instrucoes para embalamento
                               ,shipping_instructions        varchar2(1000) -- Instrucoes para entrega
                               ,invoice_instructions         varchar2(120)  -- Instrucoes para faturamento
                               ,customer_preference_set_code varchar2(30)   -- Venda parcial sim ou não
                               -- Dados para entrega e contatos para entrega
                               ,ds_contato                   varchar2(50)   -- Descricao do contato do cliente
                               ,cd_area_contato              varchar2(30)   -- Codigo de area do telefone do contato
                               ,nr_telefone_contato          varchar2(30)   -- Telefone do contato
                               ,id_local_entrega             number         -- ID do local de entrega do EBS
                               ,hr_entrega_inicio            date           -- Data e hora para inicio da janela de entrega
                               ,hr_entrega_final             date           -- Data e hora para fim da janela de entrega
                               ,id_acessa_caminhao           varchar2(10)   -- Indicador para acesso de caminhao
                               ,ds_ponto_referencia          varchar2(150)  -- Ponto de referencia do endereco de entrega
                               ,qt_dia_entrega_cliente       number         -- Quantidade limite para entrefa por dia
                               ,ds_armazenar                 varchar2(250)  -- Instrucoes para armazenagem
                               ,ds_dificuldade               varchar2(250)  -- Instrucoes a respeito das dificuldades de entrega
                               ,ds_comentario                varchar2(250)  -- Comentarios a respeito da entrega
                               ,ds_email                     varchar2(250)  -- E-mail do cliente
                               ,cd_area_contato2             varchar2(30)   -- Codigo de área do telefone de contato 2
                               ,nr_telefone_contato2         varchar2(30)   -- Telefone de contato 2
                               -- Dados adicionados para a integração PB Salesforce
                               ,list_header_id               number       -- ID da lista de preço utilizada na venda
                               ,cust_acct_site_id            number       -- ID do cliente (ExternalID - Account Salesforce)
                               ,ship_from_org_id             number       -- ID da organizacao de estoque no EBS de onde o produto sera retirado
                               ,order_type_id                number       -- ID do tipo de ordem do EBS
                               ,salesrep_id                  number       -- ID do representante de vendas do EBS
                               ,sales_channel_code           varchar2(50) -- Canal de vendas do EBS
                               ,payment_term_id              number       -- ID da condicao de pagamento do EBS
                               ,billing_account              number       -- ID do cliente no EBS para o qual o pedido sera faturado
                               ,discount_1                   number       -- Desconto de Cabeçalho 1 
                               ,discount_2                   number       -- Desconto de Cabeçalho 2
                               ,discount_3                   number       -- Desconto de Cabeçalho 3 
                               ,term_discount                number       -- Desconto de Cabeçalho Prazo 
                               ,carrier_id                   number       -- ID da transportadora
                               ,type_construction            varchar2(30) -- Tipo de Obra
                               ,nacional_account             varchar2(30) -- Conta Nacional
                               ,sold_to_org_id               number       -- ID do cliente no EBS para o qual o pedido foi vendido
                               ,freight_type                 varchar2(30) -- Tipo de Frete
                               ,specifier_name               varchar2(50) -- Nome do Especificador\Arquiteto
                               ,demand_class_code            varchar2(30) -- Nicho 
                               ,total_opportunity_quantity   number       -- Quantidade total em m2 - Validação de cotas
                               );
  --
  -- Tabela referente a estrutura do cabecalho da ordem de venda
  type order_header_t is table of order_header_r index by binary_integer;
  --order_header_aux_r
  -- Estrutura de registro de cabecalho ordem de venda auxiliar
  type order_header_aux_r is record(sold_to_org_id         number       -- [obrigatorio] - ID do cliente no EBS para o qual o pedido foi vendido
                                   ,ship_to_org_id         number       -- [obrigatorio] - ID do cliente no EBS para o qual o pedido sera entregue
                                   ,invoice_to_org_id      number       -- [obrigatorio] - ID do cliente no EBS para o qual o pedido sera faturado
                                   ,deliver_to_org_id      number       -- [Opcional]    - Padrao Nulo - ID da cliente no EBS para o qual o pedido sera entregue
                                   ,sold_from_org_id       number       -- [obrigatorio] - ID da unidade operacional
                                   ,ship_from_org_id       number       -- [obrigatorio] - ID da organizacao de estoque no EBS de onde o produto sera retirado
                                   ,salesrep_id            number       -- [obrigatorio] - ID do representante de vendas do EBS
                                   ,order_type_id          number       -- [obrigatorio] - ID do tipo de ordem do EBS
                                   ,payment_term_id        number       -- [obrigatorio] - ID da condicao de pagamento do EBS
                                   ,code_combination_id    number       -- [Opcional]    - ID da combinacao contabil no EBS
                                   ,cust_contrib_type      varchar2(16) -- [Opcional]    - Tipo de contribuinte
                                   ,shipping_method_code   varchar2(30) -- [obrigatorio] - Metodo de entrega do EBS
                                   ,agenda_id              number       -- [Opcional]    - ID da agenda no EBS
                                   ,price_list_id          number       -- [obrigatorio] - ID da tabela de preco do EBS
                                   ,sales_channel_code     varchar2(50) -- [obrigatorio] - Canal de vendas do EBS
                                   ,shipment_priority_code varchar2(30) -- [obrigatorio] - Prioridade de entrega do EBS
                                   ,fob_point_code         varchar2(30) -- [Opcional]    - Tipo de frete do EBS
                                   ,estado_filial_fat      varchar2(30) -- [Opcional]    - Estado da filial faturadora da PBG
                                   ,sold_to_fiscal_id_f    varchar2(18) -- [Opcional]    - Este campo conte a chave de identificacao do cliente que irá faturar para o cliente ME, painel de configuracao
                                   ,demand_class_code      varchar2(30) -- [Opcional]    - Nicho 
                                   ,attribute1             oe_order_headers_all.attribute1%type
                                   ,attribute2             oe_order_headers_all.attribute2%type
                                   ,attribute3             oe_order_headers_all.attribute3%type
                                   ,attribute4             oe_order_headers_all.attribute4%type
                                   ,attribute5             oe_order_headers_all.attribute5%type
                                   ,attribute6             oe_order_headers_all.attribute6%type
                                   ,attribute7             oe_order_headers_all.attribute7%type
                                   ,attribute8             oe_order_headers_all.attribute8%type
                                   ,attribute9             oe_order_headers_all.attribute9%type
                                   ,attribute10            oe_order_headers_all.attribute10%type
                                   ,attribute11            oe_order_headers_all.attribute11%type
                                   ,attribute12            oe_order_headers_all.attribute12%type
                                   ,attribute13            oe_order_headers_all.attribute13%type
                                   ,attribute14            oe_order_headers_all.attribute14%type
                                   ,attribute15            oe_order_headers_all.attribute15%type
                                   ,attribute16            oe_order_headers_all.attribute16%type
                                   ,attribute17            oe_order_headers_all.attribute17%type
                                   ,attribute18            oe_order_headers_all.attribute18%type
                                   ,attribute19            oe_order_headers_all.attribute19%type
                                   ,attribute20            oe_order_headers_all.attribute20%type
                                   );
  --
  -- Tabela referente a estrutura do cabecalho da ordem de venda auxiliar
  type order_header_aux_t is table of order_header_aux_r index by binary_integer;
  --
  -- Estrutura de registro de linha da ordem de venda
  type order_line_r is record(line_number              number        -- [opcional] - Numero da linha na ordem de compra. Usar contador caso nao seja informado
                             ,inventory_item_code      varchar2(50 ) -- [obrigatório] - Codigo do produto
                             ,unit_price               number        -- [opcional] - Preço unitario do produto - Sera validado contra a tabela de precos do EBS
                             ,list_price               number        -- [opcional] - Preço unitario do produto na Lista de preço - Sera validado contra a tabela de precos do EBS
                             ,ordered_quantity         number        -- [obrigatorio] - Quantidade vendida
                             ,unit_of_measure          varchar2(3)   -- [obrigatorio] - Unidade de medida
                             ,ship_from_org_code       varchar2(50)  -- [opcional] - Usar local do CNPJ do cliente ou Padrao 'EET' - Codigo da oraganizacao de estoque de onde o produto sera retirado
                             ,request_date             date          -- Data de desejo do cliente
                             ,schedule_ship_date       date          -- Data de agendamento da entrega para o cliente
                             ,promise_date             date          -- Data de promessa da entrega para o cliente
                             ,familia                  varchar2(50)  -- Familia de produto
                             ,calibre                  varchar2(50)  -- Calibre do produto
                             ,sku                      varchar2(50)  -- SKU do produto
                             ,grupo                    varchar2(50)  -- Codigo do agrupamento entre produtos do pedido
                             ,camada                   varchar2(50)  -- Camada do produto
                             ,assistance_number        varchar2(50)  -- Numero da ordem da Assistencia Tecnica
                             ,line_discount            number        -- Desconto da linha do pedido
                             ,earliest_acceptable_date date          -- Data minima de faturamento
                             ,ambient_type             varchar2(250) -- Tipo de ambiente
                             ,ship_set                 varchar2(250) -- Agrupamento para faturamento parcial dos itens
                             );
  --
  -- Tabela referente a estrutura da linha da ordem de venda
  type order_line_t is table of order_line_r;
  --
  -- Estrutura de registro de linha da ordem de venda auxiliar
  type order_line_aux_r is record(line_number              number        -- [opcional] - Numero da linha na ordem de compra. Usar contador caso nao seja informado
                                 ,price_list_id            number        -- [opcional] - ID da tabela de preço do EBS
                                 ,ship_from_org_id         number        -- [obrigatorio] - ID da organizacao de estoque no EBS de onde o produto sera retirado
                                 ,validate_price           boolean default false
                                 ,desc_error               varchar2(250) -- [opcional] - Preenchido no momento da validacao da lista de preco
                                 );
  --
  -- Tabela referente a estrutura da linha da ordem de venda auxiliar
  type order_line_aux_t is table of order_line_aux_r;
  --
  --
  type r_order_json is record(order_source                 varchar2(30)   
                             ,order_number                 varchar2(20)   
                             ,source_hdr_id                number         
                             ,request_date                 date           
                             ,ds_contato                   varchar2(500)   
                             ,cd_area_contato              integer
                             ,nr_telefone_contato          integer
                             ,id_local_entrega             integer
                             ,hr_entrega_inicio            date
                             ,hr_entrega_final             date
                             ,id_acessa_caminhao           varchar2(50)
                             ,ds_ponto_referencia          varchar2(500)
                             ,qt_dia_entrega_cliente       number
                             ,ds_armazenar                 varchar2(500)
                             ,ds_dificuldade               varchar2(500)
                             ,ds_comentario                varchar2(500)
                             ,ds_email                     varchar2(250)
                             ,cd_area_contato2             integer
                             ,nr_telefone_contato2         integer
                             ,sold_to_fiscal_id            varchar2(18)   
                             ,cust_ind_type                varchar2(1)    
                             ,cust_reg_number              varchar2(14)   
                             ,cust_state_inscription       varchar2(14)   
                             ,cust_city_inscription        varchar2(14)   
                             ,cust_suframa_inscription     varchar2(14)   
                             ,cust_name                    varchar2(250)  
                             ,cust_zip_code                varchar2(8)    
                             ,cust_address1                varchar2(60)   
                             ,cust_address2                varchar2(10)   
                             ,cust_address3                varchar2(250)   
                             ,cust_address4                varchar2(250)   
                             ,cust_city                    varchar2(50)   
                             ,cust_state                   varchar2(2)    
                             ,cust_country                 varchar2(6)    
                             ,cust_city_ibge               varchar2(10)   
                             ,cust_state_ibge              varchar2(10)   
                             ,cust_phone_number            varchar2(25)   
                             ,packing_instructions         varchar2(4000) 
                             ,shipping_instructions        varchar2(4000) 
                             ,invoice_instructions         varchar2(120)  
                             ,customer_preference_set_code varchar2(30)
                             ,entrega_parcial              varchar2(5)
                             );
  --
  -- Tabela referente a estrutura do cabecalho da ordem de venda
  type t_order_json is table of r_order_json index by binary_integer;
  rec_order_json  t_order_json;
  --
  -- Procedimento principal - initial processing
   procedure main(p_body          blob,
   --procedure main(p_body           in varchar2,
                 x_om_header_id  out number,
                 x_om_order_num  out varchar2,
                 x_log           out varchar2,
                 x_sts_code      out varchar2
                );
  --
  -- Procedure para envio de e-mail
  procedure prc_envia_email (p_ds_email_destino  in     varchar2
                            ,p_ds_assunto        in     varchar2
                            ,p_ds_corpo          in     varchar2
                            ,p_camimho_arquivo   in     varchar2
                            ,p_ds_erro           in out varchar2
                            );
  -- Procedimento para selecao de dados adiconais para processamento da ordem de venda
  procedure busca_dados_adicionais(p_header     in out order_header_r,
                                   p_header_aux in out order_header_aux_r,
                                   o_sts_code   in out number
                                  );
  --
  -- Procedimento para busca de dados do cliente
  procedure valida_cliente(p_header     in out order_header_r,
                           p_header_aux in out order_header_aux_r,
                           o_sts_code   in out number
                          );
  --
  -- Procedimento para buscar lista de preco
  procedure valida_list_price(p_header     in out order_header_r,
                              p_items      in out order_line_t,
                              p_header_aux in out order_header_aux_r,
                              p_items_aux  in out order_line_aux_t,
                              o_sts_code   in out number
                             );
  --
  -- Procedimento para criacao de ordem de venda
  procedure ont_create_order(p_header          in order_header_r,
                             p_items           in order_line_t,
                             p_header_aux      in order_header_aux_r,
                             p_items_aux       in order_line_aux_t,
                             l_header_scredit_tbl in oe_order_pub.header_scredit_tbl_type,
                             p_order_source_id in number,
                             x_om_header_id    out number,
                             x_om_order_num    out varchar2,
                             x_sts_code        out varchar2
                            );
  --
  -- Procedimento para validacao de regra comerciais
  procedure processa_regras_comerciais (p_header         in order_header_r,
                                        p_items          in order_line_t,
                                        p_header_aux in out order_header_aux_r,
                                        p_items_aux      in order_line_aux_t,
                                        o_sts_code      out number
                                       );
  --
  -- Procedimento para validacao de linha
  procedure validate_lines (p_header       in     order_header_r,
                            p_header_aux   in     order_header_aux_r,
                            p_items        in out order_line_t,
                            p_items_aux    in out order_line_aux_t,
                            x_sts_code        out varchar2
                           );
  --
  -- Procedimento para insercao de log de processamento
  procedure insert_log (p_source_hdr_id    in number
                       ,p_source_lin_id    in number
                       ,p_message          in varchar2
                       ,p_log_type         in number
                       );
  --
  -- Procedimento para leitura de log de processamento
  function read_log (p_source_hdr_id    in number
                    ,p_source_lin_id    in number
                    ,p_log_type         in number
                    ) return varchar2;
  --
  -- Procedimento para busca de filial faturadora
   procedure validate_filial_faturadora(p_header     in out order_header_r,
                                        p_header_aux in out order_header_aux_r,
                                        p_items      in     order_line_t,
                                       o_sts_code       out varchar2
                                      );
  --
  -- Procedimento para busca de endereco de distribuicao
  procedure valida_end_distribuicao(p_header     in out order_header_r,
                                    p_header_aux in out order_header_aux_r,
                                    o_sts_code   in out number
                                   );
  --
  --Procedure para aplica retenção
  procedure prc_aplica_retencao(p_header_id     in  number
                               ,p_source_hdr_id in  number
                               ,p_ds_hold       in  varchar2
                               ,o_sts_code   in out number
                               );
  --
  -- Procedimento para validar divergencia de preco e aplicacao de retencao
  procedure valida_diverg_preco(p_header     in     order_header_r,
                                p_items_aux  in     order_line_aux_t,
                                p_header_id  in     number,
                                p_msg           out varchar2,
                                o_sts_code   in out number
                               );
  --
  -- Procedure criada para validar informações das ordens. - Juliano Floriano - 03/08/2021
  procedure p_vldt_infos_updt_order(p_header           in r_order_json
                                   ,p_header_id        out oe_order_headers_all.header_id%type
                                   ,p_return_status    out varchar2
                                   ,p_log_processo     out varchar2);
  --
  -- Procedure criada para validar informações do cliente das ordens. - Juliano Floriano - 03/08/2021
  procedure p_vldt_insert_sites(p_header        in out r_order_json
                               ,p_header_aux    in out order_header_aux_r
                               ,p_return_status    out varchar2
                               ,p_log_processo     out varchar2);
  --
  -- Procedure criada para atualizar ordens. - Juliano Floriano - 03/08/2021
  Procedure ont_update_order(p_body          blob,
  --procedure ont_update_order(p_body           in varchar2,
                             p_log_processo  out varchar2,
                             p_status_code   out varchar2);
  --
  
    FUNCTION valida_item (
      p_segment1 IN VARCHAR2,
      p_organization_id IN NUMBER,
      p_sku             IN VARCHAR2
    )
    RETURN VARCHAR2;

    --
    FUNCTION valida_item_deposito_line (
      p_segment1 IN VARCHAR2,
      p_organization_id IN NUMBER
    )
    RETURN VARCHAR2;


    FUNCTION valida_componibilidade (
      p_nr_lote       IN VARCHAR2,
      p_item_erp_id   IN NUMBER,
      p_qtd_sol       IN NUMBER,
      p_depos_erp_id  IN VARCHAR2 DEFAULT NULL
    )
    RETURN VARCHAR2;
    --

    FUNCTION valida_item_de_in (
      p_item_erp_id       IN NUMBER,
      p_qtd_sol           IN NUMBER,
      p_ship_from_org_id  IN VARCHAR2,
      p_fase_vida         IN VARCHAR2
    )
    RETURN VARCHAR2;
    --

    FUNCTION valida_item_comercial (
      p_camada_comercial  IN VARCHAR2,
      p_item_erp_id       IN NUMBER,
      p_qtd_sol           IN NUMBER,
      p_ship_from_org_id  IN VARCHAR2
    )
    RETURN VARCHAR2;

    FUNCTION valida_item_comercial_estoque (
      p_camada_comercial  IN VARCHAR2,
      p_item_erp_id       IN NUMBER,
      p_qtd_sol           IN NUMBER,
      p_ship_from_org_id  IN VARCHAR2,
      p_sku               in varchar2,
      p_ship_from_org     in number,
      p_tipo              IN INT
    )
    RETURN VARCHAR2;

     

    FUNCTION valida_oc_do_cliente (p_oc_cliente IN VARCHAR2) RETURN VARCHAR2;

    --
    PROCEDURE limpa_var_integracao_linha;
  
    procedure prc_consumo_cota_sales(p_header in order_header_r, p_return_msg out varchar2);
    
    
  
end XXPB_SALESFORCE_ORDER_ENTRY_PKG_BY7;
/

GRANT EXECUTE ON APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG_BY7 TO API_RESTFUL_V1;


CREATE OR REPLACE PACKAGE BODY APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG_BY7 is
  --
  -- ****************************************************************
  -- Objetivo: API para processamento de ordens de venda
  -- ****************************************************************
  -- Autor: GB - By7 - Data: 03/09/2020
  -- ****************************************************************
  --
  --
  procedure p_dbms_processo(p_dbms varchar2
                           ,p_tipo varchar2) is
    --
    w_dbms varchar2(4000);
    --
  Begin
    --
    w_dbms := 'XXPB_SALESFORCE_ORDER_ENTRY_PKG_BY7: '||substr(to_char(sysdate,'hh24:mi:ss')||' - '||p_dbms,1,4000);
    --
    if p_tipo = 1 then -->> dbms
      dbms_output.put_line(w_dbms);
      fnd_file.put_line(fnd_file.output,w_dbms);
    elsif p_tipo = 2 then
      dbms_output.put_line(w_dbms);
      fnd_file.put_line(fnd_file.log,w_dbms);
    else
      dbms_output.put_line(w_dbms);
      fnd_file.put_line(fnd_file.log,w_dbms);
      fnd_file.put_line(fnd_file.output,w_dbms);
    End if;
    --
  End p_dbms_processo;
  -- Procedure criada para validar ifnormações de atualização da ordem. - Juliano Floriano - 03/08/2021
  procedure p_vldt_infos_updt_order(p_header        in r_order_json
                                   ,p_header_id     out oe_order_headers_all.header_id%type
                                   ,p_return_status out varchar2
                                   ,p_log_processo  out varchar2) is
    --
    cursor c_order_number is
      select header_id
            ,ordered_date
            ,request_date
            ,sold_to_org_id
      from (select orde.header_id
                  ,orde.ordered_date
                  ,orde.request_date
                  ,orde.sold_to_org_id
            from oe_order_headers_all orde
            where 1=1
              and orde.order_number = p_header.order_number
              and trim(p_header.order_number)  is not null
            union all
            select orde.header_id
                  ,orde.ordered_date
                  ,orde.request_date
                  ,orde.sold_to_org_id
            from oe_order_headers_all orde
                ,oe_order_sources     sour
            where 1=1
              and orde.order_source_id       = sour.order_source_id
              and upper(sour.name)           = upper(p_header.order_source)
              and orde.orig_sys_document_ref = to_char(p_header.source_hdr_id)
              and trim(p_header.order_number)  is null);
    --
    TYPE rec_order IS RECORD(header_id      oe_order_headers_all.header_id%type
                            ,ordered_date   oe_order_headers_all.ordered_date%type
                            ,request_date   oe_order_headers_all.request_date%type
                            ,sold_to_org_id oe_order_headers_all.sold_to_org_id%type);
    type t_rec_order is table of rec_order index by binary_integer;
    r_rec_order t_rec_order;
    --
    l_error_exception EXCEPTION;
    v_dt_entrega_cont number := 0;
    v_request_date    date;
    --
    /**************************************
    -->> Regras a serem implementadas
    Duvida: Caso qualquer linha do pedido já tenha sido faturada, ou possua data de agendamento de entrega, o pedido não poderá ser alterado.
    Produto não pode ser DE ou Comercial;
    Itens da Officina não devem ter data DMF alterada, então estes itens devem ser ignorados.
    **************************************/
    --
  Begin
    --
    p_return_status := 'S';
    --
    if (p_header.order_source is null or p_header.source_hdr_id is null)
    and (p_header.order_number is null) then
      --
      p_log_processo  := 'As informações de referência do pedido estão em branco. Favor Verificar';
      RAISE l_error_exception;
      --
    end if;
    --
/*    If trim(p_header.request_date) is null then -- deve permmitir não enviar a DMF
      --
      p_log_processo  := 'Data de Requisição em Branco. Favor Verificar';
      RAISE l_error_exception;
      --
    End If;*/
    --
    p_dbms_processo('c_order_number' ,0);
    open  c_order_number;
    FETCH c_order_number BULK COLLECT INTO r_rec_order;
    close c_order_number;
    --
    If r_rec_order(1).header_id is null then
      --
      p_log_processo  := 'Pedido não encontrado com as referências enviadas, favor verificar: '||
                         'Número do pedido ['||p_header.order_number||'], '||
                         'Referência da origem do pedido ['||p_header.order_source||', '||p_header.order_source||']. ';
      RAISE l_error_exception;
      --
    Else
      --
      v_request_date := p_header.request_date;
      if v_request_date is not null then
        --Pode postergar apenas até 180 dias da data de criação do pedido. O pedido será alterado, mas no limite de 180 dias da data de criação do pedido;
        if trunc(v_request_date) > trunc(r_rec_order(1).ordered_date + 180) then
          --
          p_log_processo  := 'Data de Agendamento de Entrega não pode ser maior que 180 dias da data da Ordem. Dt Entrega: '||v_request_date||'. Dt Ordem: '||r_rec_order(1).ordered_date;
          RAISE l_error_exception;
          --
        ElsIf trunc(v_request_date) <= trunc(sysdate + 10) then
          -->> A DMF pode ser antecipada para não menos que 10 dias da data de hoje e sempre será ajustada para a próxima agenda do cliente;
          p_log_processo  := 'A DMF ['||v_request_date||'] pode ser antecipada para não menos que 10 dias da data de hoje. Favor Verificar';
          RAISE l_error_exception;
          --
        Elsif trunc(r_rec_order(1).request_date) <= trunc(sysdate + 10) then
          -->> Não permite alterar se a DMF já estiver a menos de 10 dias da data de hoje. 
          -->>Neste caso, retornará o erro ¿O pedido não pode ser alterado pois a DMF já está a menos de 10 dias da data de hoje.¿
          p_log_processo  := 'O pedido não pode ser alterado pois a DMF já está a menos de 10 dias da data de hoje. Favor Verificar';
          RAISE l_error_exception;
          --
        End If;
      end if;
      --
      select count(*)
      into v_dt_entrega_cont
      from ont_agenda_entrega_evt onta
      where onta.header_id = r_rec_order(1).header_id
        and onta.dt_agenda_entrega is not null;
      --
      If v_dt_entrega_cont > 0 then
        --
        -->> A linha do pedido deve estar aberta e sem distribuição ou agendamento de entrega;
        p_log_processo  := 'Essa ordem já possui Linhas com Data de Agendamento de Entrega. Qtde: '||v_dt_entrega_cont||'. ID: '||r_rec_order(1).header_id;
        RAISE l_error_exception;
        --
      End If;
      --
      p_header_id := r_rec_order(1).header_id;
      --
    End If;
    --
  Exception
    WHEN l_error_exception THEN
      p_return_status := 'E';
    when others then
      p_return_status := 'E';
      p_log_processo  := 'Erro ao validar as informações da ordem (order_source:'||p_header.order_source||'. Source_hdr_id: '||p_header.source_hdr_id||'. Order_number: '||p_header.order_number||'). Erro: '||sqlerrm;
  End p_vldt_infos_updt_order;
  --
  procedure p_vldt_insert_sites(p_header        in out r_order_json
                               ,p_header_aux    in out order_header_aux_r
                               ,p_return_status    out varchar2
                               ,p_log_processo     out varchar2) is
    --
    --Seleciona o codigo do cliente
    cursor c_cliente (p_sold_to_org_id number) is
      select hca.account_number
            ,hca.cust_account_id
            ,hca.party_id
      from   hz_cust_accounts hca
      where  1=1
      and    hca.cust_account_id = p_sold_to_org_id;
    --
    --Valida se cliente esta cadastrado
    cursor c_existe_cliente (p_account_number in varchar2)is
      select hca.cust_account_id,
             hca.party_id
      from   hz_cust_accounts hca
      where  1=1
      and    hca.account_number = p_account_number;
    --
    --Busca ID do perfil
    cursor c_profile is
      select profile_class_id
      from   hz_cust_profile_classes
      where  1=1
      and    name = 'Clientes MI';
    --
    --Valida se o Endereço Existe para o cliente
    cursor c_existe_endereco(p_cust_account_id number,
                             p_postal_code     varchar2,
                             p_address3        varchar2
                            ) is
      select hcsua.site_use_id
      from hz_cust_acct_sites_all hcasa,
           hz_cust_site_uses_all hcsua,
           hz_party_sites         hps,
           hz_locations           hl
      where hps.party_site_id               = hcasa.party_site_id
      and   hl.location_id                  = hps.location_id
      and   hcasa.cust_account_id           = p_cust_account_id
      and   hcsua.site_use_code             = 'DELIVER_TO'
      and   hcsua.cust_acct_site_id         = hcasa.cust_acct_site_id
      and   hcasa.status                    = 'A'
      and   nvl(hl.postal_code,'00000-000') = nvl(p_postal_code,'00000-000')
      and   hcasa.org_id                    =  fnd_profile.value('ORG_ID')
      and   nvl( regexp_replace(hl.address3,'[^0-9]+'),'######') = nvl(regexp_replace(p_address3,'[^0-9]+'),'######');
    --
    v_account_number    varchar2(20);
    v_raiz_cnpj_cpf     varchar2(20);
    v_filial_cnpj       varchar2(10);
    v_digito_cpf_cnpj   varchar2(10);
    v_id_cpf_cnpj       varchar2(50);
    v_msg_text          varchar2(4000);
    v_ds_erro           varchar2(4000);
    --
    v_cust_account_id   number;
    v_profile_class_id  number;
    v_party_id          number;
    v_cust_acct_site_id number;
    v_party_site_id     number;
    v_location_id       number;
    v_site_use_id       number;
    --
    l_error_exception   exception;
    --
  begin
    --
    --Objetivo: valida se todos os campos obrigatorios estao preenchidos
    if (  p_header.cust_ind_type         is null
      or  p_header.cust_reg_number       is null
      or  p_header.cust_zip_code         is null
      or  p_header.cust_address1         is null
      or  p_header.cust_address2         is null
      or  p_header.cust_city             is null
      or  p_header.cust_state            is null
      or  p_header.cust_country          is null) then
      --
      v_msg_text := 'Erro: Para atualizar o cadastro de endereco os campos a seguir são obrigatorios. Verifique o(s) campo(s): ';
      --
      if (  p_header.cust_ind_type is null) then
        --
        v_msg_text := v_msg_text||'CNJP/CPF - Tipo de Clinete (CUST_IND_TYPE) ';
        --
      end if; -- if (  p_header.cust_ind_type is null) then
      --
      if ( p_header.cust_reg_number is null) then
        --
        v_msg_text := v_msg_text||'Código do Cliente (CUST_REG_NUMBER) ';
        --
      end if; -- if ( p_header.cust_reg_number is null) then
      --
      if ( p_header.cust_zip_code is null) then
        --
        v_msg_text := v_msg_text||'CEP (CUST_ZIP_CODE) ';
        --
      end if; -- if ( p_header.cust_zip_code is null) then
      --
      if ( p_header.cust_address1 is null) then
        --
        v_msg_text := v_msg_text||'Logradouro (CUST_ADDRESS1) ';
        --
      end if; -- if ( p_header.cust_address1 is null) then
      --
      if ( p_header.cust_address2 is null) then
        --
        v_msg_text := v_msg_text||'Nr. End. (CUST_ADDRESS2) ';
        --
      end if; -- if ( p_header.cust_address2 is null) then
      --
      if ( p_header.cust_city is null) then
        --
        v_msg_text := v_msg_text||'Cidade (CUST_CITY) ';
        --
      end if; -- if ( p_header.cust_city is null) then
      --
      if ( p_header.cust_state is null) then
        --
        v_msg_text := v_msg_text||'Estado (CUST_STATE) ';
        --
      end if; -- if ( p_header.cust_state is null) then
      --
      if ( p_header.cust_country is null) then
        --
        v_msg_text := v_msg_text||'País (CUST_COUNTRY) ';
        --
      end if; -- if ( p_header.cust_country is null) then
      --
      p_log_processo  := v_msg_text;
      RAISE l_error_exception;
      --
    else -- Objetivo: valida se todos os campos obrigatorios estao preenchidos
      --
      --Define o código do cliente de destino
      if p_header.cust_ind_type = 1 then
        --
        v_account_number  := substr(p_header.cust_reg_number, 1, 10);
        v_raiz_cnpj_cpf   := substr(p_header.cust_reg_number, 1, 10);
        v_digito_cpf_cnpj := substr(p_header.cust_reg_number, 11, 2);
        v_id_cpf_cnpj     := 'CPF';
        --
      else
        --
        v_account_number  := '0'||substr(p_header.cust_reg_number, 1, 8);
        v_raiz_cnpj_cpf   := substr(p_header.cust_reg_number, 1, 8);
        v_filial_cnpj     := substr(p_header.cust_reg_number, 9, 4);
        v_digito_cpf_cnpj := substr(p_header.cust_reg_number, 13, 2);
        v_id_cpf_cnpj     := 'CNPJ';
        --
      end if; -- if p_header.cust_ind_type = 1 then
      --
      --Verifica cliente cadastrado
      v_account_number  := null;
      v_cust_account_id := null;
      v_party_id        := null;
      --
      open  c_cliente (p_header_aux.sold_to_org_id);
      fetch c_cliente
      into  v_account_number
           ,v_cust_account_id
           ,v_party_id;
      close c_cliente;
      --
      --Busca ID perfil
      open  c_profile;
      fetch c_profile
      into  v_profile_class_id;
      close c_profile;
      --
      -- Cliente nao cadastrado
      if v_cust_account_id is null then
        --
        p_log_processo  := 'Cliente não cadastrado para essa ordem';
        raise l_error_exception;
        --
      end if; -- if v_cust_account_id is null then
      --
      v_site_use_id := null;
      --
      -- Valida endereco de entrega para o cliente
      open  c_existe_endereco(v_cust_account_id,
                              p_header.cust_zip_code,
                              p_header.cust_address3
                             );
      fetch c_existe_endereco
      into  v_site_use_id;
      close c_existe_endereco;
      --
      -- Endereco nao cadastrado
      if v_site_use_id is null then
        --
        -- Cadastrar endereco/local
        ontk12013evt.prd_create_local(p_dest_pais   => p_header.cust_country,
                                      p_dest_lgr    => p_header.cust_address1,
                                      p_dest_cpl    => p_header.cust_address2,
                                      p_dest_nro    => p_header.cust_address3,
                                      p_dest_bairro => p_header.cust_address4,
                                      p_dest_mun    => p_header.cust_city,
                                      p_dest_cep    => p_header.cust_zip_code,
                                      p_dest_uf     => p_header.cust_state,
                                      p_location_id => v_location_id,
                                      p_ds_erro     => v_ds_erro
                                     );
        --
        -- Erro cadastro endereco/local, apresentar msg de erro
        if v_ds_erro is not null then
          --
          p_log_processo  := v_ds_erro;
          raise l_error_exception;
          --
        end if; -- if v_ds_erro is not null then
        --
        -- Cria local na parte
        ontk12013evt.prd_create_party_site(p_location_id   => v_location_id,
                                           p_party_id      => v_party_id,
                                           p_party_site_id => v_party_site_id,
                                           p_ds_erro       => v_ds_erro
                                          );
        --
        -- Erro cadastro local na parte, apresentar msg de erro
        if v_ds_erro is not null then
          --
          p_log_processo  := v_ds_erro;
          raise l_error_exception;
          --
        end if; -- if v_ds_erro is not null then
        --
        -- Cadastrar CNPJ/CPF para o Cliente
        ontk12013evt.prd_create_endereco(p_cust_account_id         => v_cust_account_id,
                                         p_party_site_id           => v_party_site_id,
                                         p_global_attribute2       => p_header.cust_ind_type,
                                         p_global_attribute3       => v_raiz_cnpj_cpf,
                                         p_global_attribute4       => v_filial_cnpj,
                                         p_global_attribute5       => v_digito_cpf_cnpj,
                                         p_dest_ie                 => p_header.cust_state_inscription,
                                         p_cust_contrib_type       => null,
                                         p_orig_system_address_ref => null,
                                         p_cust_acct_site_id       => v_cust_acct_site_id,
                                         p_ds_erro                 => v_ds_erro
                                        );
        --
        -- Erro cadastro CNPJ/CPG para o cliente, apresentar msg de erro
        if v_ds_erro is not null then
          --
          p_log_processo  := v_ds_erro;
          raise l_error_exception;
          --
        end if; -- if v_ds_erro is not null then
        --
        --Cadastrar Uso de Endereco
        ontk12013evt.prd_create_uso_endereco(p_cust_acct_site_id   => v_cust_acct_site_id,
                                             p_code_combination_id => NULL,
                                             p_location            => v_location_id,
                                             p_site_use_code_tab   => 'DELIVER_TO',
                                             p_profile_class_id    => v_profile_class_id,
                                             p_site_use_id         => v_site_use_id,
                                             p_ds_erro             => v_ds_erro
                                            );
        --
        -- Erro cadastro uso de endereco, apresentar msg de erro
        if v_ds_erro is not null then
          --
          p_log_processo  := v_ds_erro;
          raise l_error_exception;
          --
        end if; -- if v_return_status is not null then
        --
      end if; -- if v_site_use_id is null then
      --
      p_header_aux.deliver_to_org_id := v_site_use_id;
      p_header_aux.ship_to_org_id    := v_site_use_id;
      p_header_aux.invoice_to_org_id := v_site_use_id;
      --
    end if; -- Objetivo: valida se todos os campos obrigatorios estao preenchidos
    --
  Exception
    WHEN l_error_exception THEN
      p_return_status := 'E';
    when others then
      p_return_status := 'E';
      p_log_processo  := 'Erro ao Validar as informações de cliente a ordem (p_account_number:'||substr(p_header.cust_reg_number, 1, 10)||'). Erro: '||sqlerrm;
  end p_vldt_insert_sites;
  --
  Procedure ont_update_order(p_body          blob,
  --procedure ont_update_order(p_body           in varchar2,
                             p_log_processo  out varchar2,
                             p_status_code   out varchar2) is
    --
    cursor c_json is
      select distinct 
             order_source
            ,order_number
            ,source_hdr_id
            ,to_date(request_date,'YYYY-MM-DD') request_date
            ,ds_contato
            ,cd_area_contato        
            ,nr_telefone_contato    
            ,id_local_entrega       
            ,case 
               when hr_entrega_inicio is not null then 
                 to_date(to_char(sysdate,'YYYY-MM-DD"T"')||hr_entrega_inicio,'YYYY-MM-DD"T"HH24:MI:SS') 
               else 
                 cast(null as date)
             end hr_entrega_inicio
            ,case 
               when hr_entrega_final is not null then 
                 to_date(to_char(sysdate,'YYYY-MM-DD"T"')||hr_entrega_final,'YYYY-MM-DD"T"HH24:MI:SS')
               else 
                 cast(null as date)
             end hr_entrega_final       
            ,id_acessa_caminhao     
            ,ds_ponto_referencia    
            ,qt_dia_entrega_cliente 
            ,ds_armazenar           
            ,ds_dificuldade         
            ,ds_comentario          
            ,ds_email             
            ,cd_area_contato2
            ,nr_telefone_contato2
            ,sold_to_fiscal_id       
            ,cust_ind_type           
            ,cust_reg_number         
            ,cust_state_inscription  
            ,cust_city_inscription   
            ,cust_suframa_inscription
            ,cust_name               
            ,cust_zip_code           
            ,cust_address1           
            ,cust_address2           
            ,cust_address3           
            ,cust_address4           
            ,cust_city               
            ,cust_state              
            ,cust_country            
            ,cust_city_ibge          
            ,cust_state_ibge         
            ,cust_phone_number       
            ,packing_instructions    
            ,shipping_instructions   
            ,invoice_instructions    
            ,customer_preference_set_code
            ,entrega_parcial
      from json_table (p_body,'$.dados[*]'
                        columns(order_source                 varchar2 path '$.order_source'
                               ,source_hdr_id                number  path '$.source_hdr_id'
                               ,order_number                 varchar2 path '$.order_number'
                               ,request_date                 varchar2 path '$.request_date'
                                --
                               ,sold_to_fiscal_id            varchar2 path '$.cliente.sold_to_fiscal_id'
                               ,cust_ind_type                varchar2 path '$.cliente.cust_ind_type'
                               ,cust_reg_number              varchar2 path '$.cliente.cust_reg_number'
                               ,cust_state_inscription       varchar2 path '$.cliente.cust_state_inscription'
                               ,cust_city_inscription        varchar2 path '$.cliente.cust_city_inscription'
                               ,cust_suframa_inscription     varchar2 path '$.cliente.cust_suframa_inscription'
                               ,cust_name                    varchar2 path '$.cliente.cust_name'
                               ,cust_zip_code                varchar2 path '$.cliente.cust_zip_code'
                               ,cust_address1                varchar2 path '$.cliente.cust_address1'
                               ,cust_address2                varchar2 path '$.cliente.cust_address2'
                               ,cust_address3                varchar2 path '$.cliente.cust_address3'
                               ,cust_address4                varchar2 path '$.cliente.cust_address4'
                               ,cust_city                    varchar2 path '$.cliente.cust_city'
                               ,cust_state                   varchar2 path '$.cliente.cust_state'
                               ,cust_country                 varchar2 path '$.cliente.cust_country'
                               ,cust_city_ibge               varchar2 path '$.cliente.cust_city_ibge'
                               ,cust_state_ibge              varchar2 path '$.cliente.cust_state_ibge'
                               ,cust_phone_number            varchar2 path '$.cliente.cust_phone_number'
                               ,packing_instructions         varchar2 path '$.cliente.packing_instructions'
                               ,shipping_instructions        varchar2 path '$.cliente.shipping_instructions'
                               ,invoice_instructions         varchar2 path '$.cliente.invoice_instructions'
                                --
                               ,customer_preference_set_code varchar2 path '$.cliente.entrega.customer_preference_set_code'
                               ,entrega_parcial              varchar2 path '$.cliente.entrega.entrega_parcial'
                               ,ds_contato                   varchar2 path '$.cliente.entrega.ds_contato'
                               ,cd_area_contato              integer  path '$.cliente.entrega.cd_area_contato'
                               ,nr_telefone_contato          integer  path '$.cliente.entrega.nr_telefone_contato'
                               ,id_local_entrega             integer  path '$.cliente.entrega.id_local_entrega'
                               ,hr_entrega_inicio            varchar2 path '$.cliente.entrega.hr_entrega_inicio'
                               ,hr_entrega_final             varchar2 path '$.cliente.entrega.hr_entrega_final'
                               ,id_acessa_caminhao           varchar2 path '$.cliente.entrega.id_acessa_caminhao'
                               ,ds_ponto_referencia          varchar2 path '$.cliente.entrega.ds_ponto_referencia'
                               ,qt_dia_entrega_cliente       number   path '$.cliente.entrega.qt_dia_entrega_cliente'
                               ,ds_armazenar                 varchar2 path '$.cliente.entrega.ds_armazenar'
                               ,ds_dificuldade               varchar2 path '$.cliente.entrega.ds_dificuldade'
                               ,ds_comentario                varchar2 path '$.cliente.entrega.ds_comentario'
                               ,ds_email                     varchar2 path '$.cliente.entrega.ds_email'
                               ,cd_area_contato2             integer  path '$.cliente.entrega.cd_area_contato2'
                               ,nr_telefone_contato2         integer  path '$.cliente.entrega.nr_telefone_contato2'
                                --
                                )
                    );
    --
    TYPE log_rec IS RECORD (order_num   varchar2(50)
                           ,msg_output  varchar2(4000));
    --
    TYPE tab_log_rec IS TABLE OF log_rec INDEX BY BINARY_INTEGER;
    out_rec  tab_log_rec;
    --
    idx             number := 0;
    --
    v_return_status varchar2(1)  := 'S';
    v_log_processo  varchar2(4000) := null;
    --
    v_request_date      date;
    v_hr_entrega_inicio date;
    v_hr_entrega_final  date;
    --
    v_header_id        oe_order_headers_all.header_id%type;
    l_order_header_aux order_header_aux_r;
    --
    v_tem_endereco boolean := false;
    v_tem_entrega boolean := false;
    v_tem_entrega_parcial boolean := false;
    --
  Begin
    --
    --Seta as variaveis de contexto do EBS, para alterar os pedidos
    fnd_global.apps_initialize( 14878, 21623, 660);
    mo_global.set_policy_context('S', fnd_profile.value('ORG_ID'));
    mo_global.init('ONT');    
    --
    p_dbms_processo('Inicio',0);
    --
    OPEN  c_json;
    FETCH c_json BULK COLLECT INTO rec_order_json;
    CLOSE c_json;
    --
    l_log := json_object_t();
    l_logs := json_array_t();
    for i in 1..rec_order_json.count loop
      --
      idx             := idx + 1;
      v_return_status := 'S';
      --
      if     rec_order_json(i).cust_ind_type   is not null
          or rec_order_json(i).cust_reg_number is not null
          or rec_order_json(i).cust_zip_code   is not null
          or rec_order_json(i).cust_address1   is not null
          or rec_order_json(i).cust_address2   is not null
          or rec_order_json(i).cust_city       is not null
          or rec_order_json(i).cust_state      is not null
          or rec_order_json(i).cust_country    is not null 
      then 
        v_tem_endereco := true;
      end if;
      --
      if   rec_order_json(i).ds_contato             is not null
        or rec_order_json(i).cd_area_contato        is not null
        or rec_order_json(i).nr_telefone_contato    is not null
        or rec_order_json(i).id_local_entrega       is not null
        or v_hr_entrega_inicio                      is not null
        or v_hr_entrega_final                       is not null
        or rec_order_json(i).id_acessa_caminhao     is not null
        or rec_order_json(i).ds_ponto_referencia    is not null
        or rec_order_json(i).qt_dia_entrega_cliente is not null
        or rec_order_json(i).ds_armazenar           is not null
        or rec_order_json(i).ds_dificuldade         is not null
        or rec_order_json(i).ds_comentario          is not null
        or rec_order_json(i).ds_email               is not null
        or rec_order_json(i).cd_area_contato2       is not null
        or rec_order_json(i).nr_telefone_contato2   is not null
      then
        v_tem_entrega := true;
      end if;
      --
      if   rec_order_json(i).customer_preference_set_code is not null
        or rec_order_json(i).entrega_parcial              is not null
      then
        v_tem_entrega_parcial := true;
      end if;
      --
      -->> Chamada de procedure de validação de informações
      p_vldt_infos_updt_order(rec_order_json(i)
                             ,v_header_id
                             ,v_return_status 
                             ,v_log_processo  );
      --
      If v_return_status = 'S' and v_tem_endereco then
        p_vldt_insert_sites(rec_order_json(i)
                           ,l_order_header_aux
                           ,v_return_status
                           ,v_log_processo);
      End If;
      --
      If v_return_status = 'S' then
        --
        v_request_date      := rec_order_json(i).request_date;
        v_hr_entrega_inicio := rec_order_json(i).hr_entrega_inicio;
        v_hr_entrega_final  := rec_order_json(i).hr_entrega_final;
        --
        if v_request_date is not null then
          Begin
            update oe_order_headers_all
            set request_date      = v_request_date
               ,last_update_date  = sysdate
               ,last_updated_by   = nvl(vg_user_id,-1)
            where header_id = v_header_id;
          Exception
            when others then
              v_return_status := 'N';
              v_log_processo  := 'Erro ao atualizar DMF da ordem (header_id:'||v_header_id||'. Ordem: '||rec_order_json(i).order_number||'). Erro: '||sqlerrm;
          End;
          --
          /*Begin -- A atualização das linhas é feita automaticamente
            update oe_order_lines_all line
            set schedule_ship_date = v_request_date
               ,last_update_date   = sysdate
               ,last_updated_by    = nvl(vg_user_id,-1)
            where header_id = v_header_id
              and open_flag = 'Y'
              and not exists (select '1'
                              from ont_agenda_entrega_evt onta
                              where onta.header_id = line.header_id
                                and onta.dt_agenda_entrega is not null);
          Exception
            when others then
              v_return_status := 'N';
              v_log_processo  := 'Erro ao atualizar a linha (header_id:'||v_header_id||'. Ordem: '||rec_order_json(i).order_number||'). Erro: '||sqlerrm;
          End;*/
        end if;

        if v_tem_endereco then
          Begin
            update oe_order_headers_all
            set last_update_date  = sysdate
               ,last_updated_by   = nvl(vg_user_id,-1)
               ,ship_to_org_id    = l_order_header_aux.ship_to_org_id
               ,invoice_to_org_id = l_order_header_aux.invoice_to_org_id
               ,deliver_to_org_id = l_order_header_aux.deliver_to_org_id
            where header_id = v_header_id;
          Exception
            when others then
              v_return_status := 'N';
              v_log_processo  := 'Erro ao atualizar endereço da ordem (header_id:'||v_header_id||'. Ordem: '||rec_order_json(i).order_number||'). Erro: '||sqlerrm;
          End;
        end if;
        --
        --
        if v_tem_entrega then
          Begin
            update ont.ont_info_entrega_pedido_pb e
            set last_update_date       = sysdate
               ,last_updated_by        = nvl(vg_user_id,-1)
               ,ds_contato             = coalesce(rec_order_json(i).ds_contato,ds_contato)
               ,cd_area_contato        = coalesce(rec_order_json(i).cd_area_contato,cd_area_contato)
               ,nr_telefone_contato    = coalesce(rec_order_json(i).nr_telefone_contato,nr_telefone_contato)
               ,id_local_entrega       = coalesce(rec_order_json(i).id_local_entrega,id_local_entrega)
               ,hr_entrega_inicio      = coalesce(v_hr_entrega_inicio,hr_entrega_inicio)
               ,hr_entrega_final       = coalesce(v_hr_entrega_final,hr_entrega_final)
               ,id_acessa_caminhao     = coalesce(rec_order_json(i).id_acessa_caminhao,id_acessa_caminhao)
               ,ds_ponto_referencia    = coalesce(rec_order_json(i).ds_ponto_referencia,ds_ponto_referencia)
               ,qt_dia_entrega_cliente = coalesce(rec_order_json(i).qt_dia_entrega_cliente,qt_dia_entrega_cliente)
               ,ds_armazenar           = coalesce(rec_order_json(i).ds_armazenar,ds_armazenar)
               ,ds_dificuldade         = coalesce(rec_order_json(i).ds_dificuldade,ds_dificuldade)
               ,ds_comentario          = coalesce(rec_order_json(i).ds_comentario,ds_comentario)
               ,ds_email               = coalesce(rec_order_json(i).ds_email,ds_email)
               ,cd_area_contato2       = coalesce(rec_order_json(i).cd_area_contato2,cd_area_contato2)
               ,nr_telefone_contato2   = coalesce(rec_order_json(i).nr_telefone_contato2,nr_telefone_contato2)
            where header_id = v_header_id;
          Exception
            when others then
              v_return_status := 'N';
              v_log_processo  := 'Erro ao atualizar Infos de Entrega (header_id:'||v_header_id||'. Ordem: '||rec_order_json(i).order_number||'). Erro: '||sqlerrm;
          end;
        end if;
        --
        if v_tem_entrega_parcial then
          Begin
            update oe_order_headers_all
            set customer_preference_set_code  = coalesce(rec_order_json(i).customer_preference_set_code
                                                        ,decode(upper(rec_order_json(i).entrega_parcial)
                                                               ,'NÃ¿O','SHIP'
                                                               ,'NAO','SHIP'
                                                               ,'N'  ,'SHIP'
                                                               ,'SIM',NULL
                                                               ,'S'  ,NULL
                                                               ,customer_preference_set_code
                                                               )
                                                        )
            where header_id = v_header_id;
          Exception
            when others then
              v_return_status := 'N';
              v_log_processo  := 'Erro ao atualizar Infos de entrega parcial (header_id:'||v_header_id||'. Ordem: '||rec_order_json(i).order_number||'). Erro: '||sqlerrm;
          end;
        end if;
        --
      End If;
      --
      --
      If nvl(v_return_status,'S') in ('S') then
        out_rec(idx).msg_output := 'Pedido processado com SUCESSO. Header_id: '||v_header_id||'.'/*||to_char(p_body)*/;
        p_status_code           := 200;
      Else
        out_rec(idx).msg_output := 'Final de processo com ERRO. '||v_log_processo;
        p_status_code           := 500;
        --exit;
      End If;
      --
      l_log.put('order_source',rec_order_json(idx).order_source);
      l_log.put('source_hdr_id',rec_order_json(idx).source_hdr_id);
      l_log.put('order_number',rec_order_json(idx).order_number);
      l_log.put('logMessage',out_rec(idx).msg_output);
      l_log.put('status',p_status_code);
      l_logs.append(l_log);
      --
    End Loop;
    --
    for i in 1..idx loop
      --
      p_log_processo := p_log_processo||'. Log: '||out_rec(i).msg_output||CHR(13);
      --
    End Loop;
    --
    l_root.put('Message', l_logs);
    htp.p('Content-Type: application/json');
    owa_util.http_header_close;
    --
    $IF  dbms_db_version.ver_le_12 $THEN
      l_root.htp;
    $ELSE
      htp_print_clob(l_root.to_clob);
    $END
    --
    commit;
    --
    p_dbms_processo('p_log_processo: '||p_log_processo,0);
    --
  End ont_update_order;
  --
  -- Procedure para envio de e-mail
  procedure prc_envia_email (p_ds_email_destino  in     varchar2
                            ,p_ds_assunto        in     varchar2
                            ,p_ds_corpo          in     varchar2
                            ,p_camimho_arquivo   in     varchar2
                            ,p_ds_erro           in out varchar2
                            ) is
    --
    w_erro      exception;
    w_ds_erro   varchar2(32767);
    v_diretorio varchar2(50);
    v_arquivo   varchar2(70);
    --
  begin
    --
    w_ds_erro:= f2c_send_javamail.sendmail(smtpservername => fnd_profile.value('PB_EASY_XML_SMTP_SERVER'),
                                           sender         => 'oracle@portobello.com.br',
                                           recipient      => p_ds_email_destino,
                                           ccrecipient    => '',
                                           bccrecipient   => '',
                                           subject        => p_ds_assunto,
                                           body           => p_ds_corpo,
                                           errormessage   => w_ds_erro,
                                           attachments    => f2c_send_javamail.attachments_list(p_camimho_arquivo)
                                          );
    --
    if w_ds_erro <> 0 then
      --
      raise w_erro;
      --
    end if;
    --
    commit;
    --
  exception
    when w_erro then
      pbsendmail(from_name    => 'oracle@portobello.com.br'
                ,to_names     => p_ds_email_destino
                ,subject      => p_ds_assunto
                ,message      => p_ds_corpo
                ,html_message => null
                );
    when others then
      p_ds_erro := 'Erro ao enviar o e-mail.Erro:'||sqlerrm;
  end prc_envia_email;
  --
  -- Procedimento para insercao de log de processamento
  procedure insert_log (p_source_hdr_id    in number
                       ,p_source_lin_id    in number
                       ,p_message          in varchar2
                       ,p_log_type         in number
                       ) is
  --
  -- ***************************
  -- ******* Tipo de Log *******
  -- 0 -> Pendente
  -- 1 -> Sucesso
  -- 2 -> Erro
  --***************************
  --
  -- Valida se mensagem a ser inserida já existe na tabela para o ID e LOG_TYPE a nivel de cabecalho
  cursor c1 is
    select 1
    from   xxpb_order_api_process_logs
    where  1=1
    and    source_hdr_id    = p_source_hdr_id
    and    message          = p_message
    and    log_type         = p_log_type;
    --
  rg_c1 c1%rowtype;
  --
  -- Valida se mensagem a ser inserida já existe na tabela para o ID e LOG_TYPE a nivel de linha
  cursor c2 is
    select 1
    from   xxpb_order_api_process_logs
    where  1=1
    and    source_hdr_id     = p_source_hdr_id
    and    source_lin_id     = p_source_lin_id
    and    message           = p_message
    and    log_type          = p_log_type;
    --
  rg_c2 c2%rowtype;
  --
  v_insere_msg boolean default false;
  --
  begin
    --
    if p_source_lin_id is not null then
      --
      -- Valida se mensagem a ser inserida já existe na tabela para o ID e LOG_TYPE a nivel de linha
      open c2;
      fetch c2 into rg_c2;
      --
      -- Senão existir, insere, caso contrário não faz nada
      if c2%notfound then
        --
        v_insere_msg := true;
        --
      end if;
      --
      close c2;
      --
    else
      --
      -- Valida se mensagem a ser inserida já existe na tabela para o ID e LOG_TYPE a nivel de cabecalho
      open c1;
      fetch c1 into rg_c1;
      --
      -- Senão existir, insere, caso contrário não faz nada
      if c1%notfound then
        --
        v_insere_msg := true;
        --
      end if;
      --
      close c1;
      --
    end if;
    --
    if v_insere_msg then
      --
      begin
        insert into xxpb_order_api_process_logs(source_hdr_id     --number        not null
                                               ,source_lin_id     --number
                                               ,message           --varchar2(4000)
                                               ,log_type          --number        not null
                                               ,conc_request_id   --number
                                               ,creation_date     --date
                                               ,creation_by       --number
                                               )
                                        values (p_source_hdr_id
                                               ,p_source_lin_id
                                               ,replace(replace(trim(p_message),Chr(10),' '),'  ',' ')
                                               ,p_log_type
                                               ,fnd_global.conc_request_id
                                               ,sysdate
                                               ,vg_user_id
                                               );
      exception
        when others then
          insert_log(p_source_hdr_id,p_source_lin_id,'Erro: 1 - Erro na insercao de log na tabela XXPB_ORDER_API_PROCESS_LOGS. Erro: '||sqlerrm||dbms_utility.format_error_backtrace, 2);
      end;
      --
      commit;
      --
    end if;
    --
  exception
    when others then
      raise_application_error(-20001, 'Erro: 2 - Erro na procedure INSERT_LOG. Erro: '||sqlerrm||dbms_utility.format_error_backtrace);
  end insert_log;
  --
  -- Procedimento para leitura de log de processamento
  function read_log (p_source_hdr_id    in number
                    ,p_source_lin_id    in number
                    ,p_log_type         in number
                    ) return varchar2 is
    --
    -- Seleciona as msg a nível de cabecalho
    cursor c1 is
      select message
      from   xxpb_order_api_process_logs
      where  1=1
      and    source_hdr_id    = p_source_hdr_id
      and    log_type         = p_log_type
      order  by creation_date, message;
      --
    r1 c1%rowtype;
    --
    -- Seleciona as msg a nível de linha
    cursor c2 is
      select message
      from   xxpb_order_api_process_logs
      where  1=1
      and    source_hdr_id     = p_source_hdr_id
      and    source_lin_id     = p_source_lin_id
      and    log_type          = p_log_type
      order  by creation_date, message;
      --
    r2 c2%rowtype;
    --
    w_return_msg varchar2(4000);
    --
  begin
    --
    if p_source_lin_id is null then
      --
      for r1 in c1 loop
        --
        if w_return_msg is null then
          --
          w_return_msg := r1.message;
          --
        else
          --
          w_return_msg := w_return_msg||chr(10)||r1.message;
          --
        end if;
        --
      end loop; -- c1
      --
    else
      --
      for r2 in c2 loop
        --
        if w_return_msg is null then
          --
          w_return_msg := r2.message;
          --
        else
          --
          w_return_msg := w_return_msg||chr(10)||r2.message;
          --
        end if;
        --
      end loop; -- c2
      --
    end if;
    --
    return w_return_msg;
    --
  end read_log;
  --
  -- Procedure para validar unidade de medida do item, converter em caso necessário, para a UOM principal do item
  procedure valida_uom_item(p_header              in order_header_r
                           ,p_inventory_item_code in  varchar2
                           ,p_in_qtde_item        in  number
                           ,p_in_uom              in  varchar2
                           ,p_in_preco            in  number
                           ,p_out_qtde_item       out number
                           ,p_out_uom             out varchar2
                           ,p_out_preco           out number
                           --,p_converte            out varchar2
                           ) is
  --
  -- Cursor para validar se uom do item é a principal
  cursor c1 is
    select 1
    from   mtl_system_items_b msi
    where  1=1
    and    msi.organization_id         = pb_master_organization_id
    and    msi.segment1                = p_inventory_item_code
    and    msi.primary_unit_of_measure = p_in_uom;
    --
  -- Cursor para selecionar uom do item principal
  cursor c2 is
    select msi.primary_unit_of_measure
          ,msi.primary_uom_code
          ,msi.inventory_item_id
    from   mtl_system_items_b msi
    where  1=1
    and    msi.organization_id = pb_master_organization_id
    and    msi.segment1        = p_inventory_item_code;
    --
  r1 c1%rowtype;
  r2 c2%rowtype;
  --
  -- Variaveis
  w_fator number;
  w_qtde_cx_o number; -- quantidade de caixas conforme quantidade em SF
  w_qtde_cx_a number; -- quantidade de caixas arredondando para cima
  w_inventory_item_id integer;
  --
  begin

    --
    -- Cursor para validar se uom do item é a principal
    open c1;
    fetch c1 into r1;
    --
    if c1%notfound then
      --
      -- Cursor para selecionar uom do item principal
      for r2 in c2 loop
        --
        p_out_uom := r2.primary_uom_code;
        --
        -- Converter quantidade do item
        p_out_qtde_item := inv_convert.inv_um_convert(item_id       => r2.inventory_item_id
                                                     ,precision     => null -- default (-5)
                                                     ,from_quantity => p_in_qtde_item
                                                     ,from_unit     => p_in_uom  -- null -- cod uom
                                                     ,to_unit       => p_out_uom -- null -- cod uom
                                                     ,from_name     => null -- cod uom -> p_in_uom
                                                     ,to_name       => null -- cod uom -> p_out_uom
                                                     );
        --
        w_inventory_item_id := r2.inventory_item_id;
      end loop; -- c2
      --

      -- Verificar múltiplo de caixa quando a unidade do cliente for 'SF' - 'Square Foot'
      if p_in_uom = 'sf' then

        -- Converte para quantide em caixas
        w_qtde_cx_o := inv_convert.inv_um_convert(item_id       => w_inventory_item_id
                                                 ,precision     => null -- default (-5)
                                                 ,from_quantity => p_out_qtde_item
                                                 ,from_unit     => p_out_uom  -- null -- cod uom
                                                 ,to_unit       => 'cx' -- null -- cod uom
                                                 ,from_name     => null -- cod uom -> p_in_uom
                                                 ,to_name       => null -- cod uom -> p_out_uom
                                                 );

        if w_qtde_cx_o <> -99999 then -- Encontrou arredondamento

          -- Arredonda quantidade de caixas para cima        
          w_qtde_cx_a := ceil(w_qtde_cx_o);

          if w_qtde_cx_a <> w_qtde_cx_o then
            -- Converte novamente para a unidade principal do item, usando a quantidade arredondada
            p_out_qtde_item := inv_convert.inv_um_convert(item_id       => w_inventory_item_id
                                                         ,precision     => null -- default (-5)
                                                         ,from_quantity => w_qtde_cx_a
                                                         ,from_unit     => 'cx'  -- null -- cod uom
                                                         ,to_unit       => p_out_uom -- null -- cod uom
                                                         ,from_name     => null -- cod uom -> p_in_uom
                                                         ,to_name       => null -- cod uom -> p_out_uom
                                                         );

            insert_log(p_source_hdr_id => p_header.source_hdr_id,
                       p_source_lin_id => null,
                       p_message       => 'A quantidade do item '||p_inventory_item_code||
                                          ' foi ajustada para atender a regra de multiplo de caixas.',
                       p_log_type      => 1);

          end if;
        end if;
      end if;

      w_fator := p_in_qtde_item/p_out_qtde_item;
      p_out_preco := round(p_in_preco * w_fator,2);
      --
      --p_converte := 'Y';
      --
/*    else
      --
      p_converte := 'N';
*/      --
    end if; -- c1
    --
    close c1;
    --
  end valida_uom_item;
  --
   procedure main(p_body         blob,
   --procedure main(p_body           in varchar2,
                 x_om_header_id  out number,
                 x_om_order_num  out varchar2,
                 x_log           out varchar2,
                 x_sts_code      out varchar2
                ) is
    --
    -- Seleciona dados do cabecalho da ordem de venda
    cursor c_order_header is
      with dmfmin as
      (select lookup_code chave
             ,flv.TAG     dias
         from fnd_lookup_values_vl flv
        where flv.LOOKUP_TYPE = 'OM_INTPEDIDO_DMFMIN_CLIENTE'
          and flv.ENABLED_FLAG = 'Y'
          and sysdate between coalesce(flv.START_DATE_ACTIVE,sysdate-1) and coalesce(flv.END_DATE_ACTIVE,sysdate+1)
      )
      select cust_po_number
            ,cust_po_number2
            ,cust_so_number
            ,order_type
            ,nvl(currence_code,'BRL') currence_code
            ,to_date(pricing_date,'YYYY-MM-DD"T"hh24:MI:SS') pricing_date
            ,greatest(coalesce(to_date(request_date,'YYYY-MM-DD"T"hh24:MI:SS'),sysdate),
                      sysdate+coalesce(dmfmin.dias,'0')) request_date
            ,domestic_foreign_ind
            ,sold_from_fiscal_id
            ,upper(order_source) order_source
            ,coalesce(source_hdr_id, -- Source id enviado pela API
                     (select (extract( day from diff )*24*60*60 +
                              extract( hour from diff )*60*60 +
                              extract( minute from diff )*60)*1000000 +
                             (round(extract( second from diff )*1000)*1000) +
                             rownum  id
                        from (select systimestamp - to_date('01-01-2020','DD-MM-YYYY') diff
                                from dual)
                     ) + rownum) source_hdr_id
            ,payment_term_code
            ,ship_set_code
            ,emailaccwhensuccess
            ,emailaccwhenerror
            --Dados do cliente
            ,case when domestic_foreign_ind = 'F' 
                  then replace(json_table.sold_to_fiscal_id,'-','')
                  else json_table.sold_to_fiscal_id 
             end sold_to_fiscal_id
            ,cust_ind_type
            ,cust_reg_number
            ,cust_state_inscription
            ,cust_city_inscription
            ,cust_suframa_inscription
            ,cust_name
            ,cust_zip_code
            ,cust_address1
            ,cust_address2
            ,cust_address3
            ,cust_address4
            ,cust_city
            ,cust_state
            ,cust_country
            ,cust_city_ibge
            ,cust_state_ibge
            ,cust_phone_number
            ,packing_instructions
            ,shipping_instructions
            ,invoice_instructions
            ,customer_preference_set_code
            -- Dados para entrega e contatos para entrega
            ,ds_contato
            ,cd_area_contato
            ,nr_telefone_contato
            ,id_local_entrega
            ,to_date(hr_entrega_inicio,'YYYY-MM-DD"T"hh24:MI:SS') hr_entrega_inicio
            ,to_date(hr_entrega_final,'YYYY-MM-DD"T"hh24:MI:SS') hr_entrega_final
            ,id_acessa_caminhao
            ,ds_ponto_referencia
            ,qt_dia_entrega_cliente
            ,ds_armazenar
            ,ds_dificuldade
            ,ds_comentario
            ,ds_email
            ,cd_area_contato2
            ,nr_telefone_contato2
            ,list_header_id
            ,cust_acct_site_id
            ,ship_from_org_id
            ,order_type_id
            ,salesrep_id
            ,sales_channel_code
            ,payment_term_id
            ,billing_account            
            ,discount_1                   
            ,discount_2                   
            ,discount_3                   
            ,term_discount                
            ,carrier_id                     
            ,type_construction             
            ,nacional_account            
            ,sold_to_org_id
            ,freight_type            
            ,specifier_name              
            ,demand_class_code           
            ,total_opportunity_quantity   
       from dmfmin,
            json_table (p_body,'$' columns (cust_po_number               varchar2   path '$.cust_po_number'
                                           ,cust_po_number2              varchar2   path '$.cust_po_number2'
                                           ,cust_so_number               varchar2   path '$.cust_so_number'
                                           ,order_type                   varchar2   path '$.order_type'
                                           ,currence_code                varchar2   path '$.currence_code'
                                           ,pricing_date                 varchar2   path '$.pricing_date'
                                           ,request_date                 varchar2   path '$.request_date'
                                           ,domestic_foreign_ind         varchar2   path '$.domestic_foreign_ind'
                                           ,sold_from_fiscal_id          varchar2   path '$.sold_from_fiscal_id'
                                           ,order_source                 varchar2   path '$.order_source'
                                           ,source_hdr_id                number     path '$.source_hdr_id'
                                           ,payment_term_code            varchar2   path '$.payment_term_code'
                                           ,ship_set_code                varchar2   path '$.ship_set_code'
                                           ,emailaccwhensuccess          varchar2   path '$.emailAccWhenSuccess'
                                           ,emailaccwhenerror            varchar2   path '$.emailAccWhenError'
                                           -- Dados do cliente
                                           ,sold_to_fiscal_id            varchar2   path '$.cliente.sold_to_fiscal_id'
                                           ,cust_ind_type                varchar2   path '$.cliente.cust_ind_type'
                                           ,cust_reg_number              varchar2   path '$.cliente.cust_reg_number'
                                           ,cust_state_inscription       varchar2   path '$.cliente.cust_state_inscription'
                                           ,cust_city_inscription        varchar2   path '$.cliente.cust_city_inscription'
                                           ,cust_suframa_inscription     varchar2   path '$.cliente.cust_suframa_inscription'
                                           ,cust_name                    varchar2   path '$.cliente.cust_name'
                                           ,cust_zip_code                varchar2   path '$.cliente.cust_zip_code'
                                           ,cust_address1                varchar2   path '$.cliente.cust_address1'
                                           ,cust_address2                varchar2   path '$.cliente.cust_address2'
                                           ,cust_address3                varchar2   path '$.cliente.cust_address3'
                                           ,cust_address4                varchar2   path '$.cliente.cust_address4'
                                           ,cust_city                    varchar2   path '$.cliente.cust_city'
                                           ,cust_state                   varchar2   path '$.cliente.cust_state'
                                           ,cust_country                 varchar2   path '$.cliente.cust_country'
                                           ,cust_city_ibge               varchar2   path '$.cliente.cust_city_ibge'
                                           ,cust_state_ibge              varchar2   path '$.cliente.cust_state_ibge'
                                           ,cust_phone_number            varchar2   path '$.cliente.cust_phone_number'
                                           ,packing_instructions         varchar2   path '$.cliente.packing_instructions'
                                           ,shipping_instructions        varchar2   path '$.cliente.shipping_instructions'
                                           ,invoice_instructions         varchar2   path '$.cliente.invoice_instructions'
                                           ,customer_preference_set_code varchar2   path '$.cliente.customer_preference_set_code'
                                           -- Dados para entrega e contatos para entrega
                                           ,ds_contato                   varchar2   path '$.cliente.entrega.ds_contato'
                                           ,cd_area_contato              varchar2   path '$.cliente.entrega.cd_area_contato'
                                           ,nr_telefone_contato          varchar2   path '$.cliente.entrega.nr_telefone_contato'
                                           ,id_local_entrega             number     path '$.cliente.entrega.id_local_entrega'
                                           ,hr_entrega_inicio            varchar2   path '$.cliente.entrega.hr_entrega_inicio'
                                           ,hr_entrega_final             varchar2   path '$.cliente.entrega.hr_entrega_final'
                                           ,id_acessa_caminhao           varchar2   path '$.cliente.entrega.id_acessa_caminhao'
                                           ,ds_ponto_referencia          varchar2   path '$.cliente.entrega.ds_ponto_referencia'
                                           ,qt_dia_entrega_cliente       number     path '$.cliente.entrega.qt_dia_entrega_cliente'
                                           ,ds_armazenar                 varchar2   path '$.cliente.entrega.ds_armazenar'
                                           ,ds_dificuldade               varchar2   path '$.cliente.entrega.ds_dificuldade'
                                           ,ds_comentario                varchar2   path '$.cliente.entrega.ds_comentario'
                                           ,ds_email                     varchar2   path '$.cliente.entrega.ds_email'
                                           ,cd_area_contato2             varchar2   path '$.cliente.entrega.cd_area_contato2'
                                           ,nr_telefone_contato2         varchar2   path '$.cliente.entrega.nr_telefone_contato2'
                                           --Dados POP Salesforce
                                           ,list_header_id               number        path '$.list_header_id'
                                           ,cust_acct_site_id            number        path '$.cliente.cust_acct_site_id'
                                           ,ship_from_org_id             number        path '$.ship_from_org_id'
                                           ,order_type_id                number        path '$.order_type_id'
                                           ,salesrep_id                  number        path '$.salesrep_id'
                                           ,sales_channel_code           varchar2(50)  path '$.sales_channel_code'
                                           ,payment_term_id              number        path '$.payment_term_id'
                                           ,billing_account              number        path '$.cliente.billing_account'
                                           ,discount_1                   number        path '$.discount_1'
                                           ,discount_2                   number        path '$.discount_2'
                                           ,discount_3                   number        path '$.discount_3'
                                           ,term_discount                number        path '$.term_discount'
                                           ,carrier_id                   number        path '$.carrier_id'
                                           ,type_construction            varchar2(30)  path '$.type_construction'
                                           ,nacional_account             varchar2(30)  path '$.nacional_account'
                                           ,sold_to_org_id               number        path '$.sold_to_org_id'  
                                           ,freight_type                 varchar2(30)  path '$.freight_type' 
                                           ,specifier_name               varchar2(50)  path '$.specifier_name' 
                                           ,demand_class_code            varchar2(30)  path '$.demand_class_code' 
                                           ,total_opportunity_quantity   number        path '$.total_opportunity_quantity' 
                                           )
            ) json_table
      where dmfmin.chave (+)= json_table.order_source||'-'||
                             (case when domestic_foreign_ind = 'F' 
                                then replace(json_table.sold_to_fiscal_id,'-','')
                                else json_table.sold_to_fiscal_id 
                              end);
    --
    -- Seleciona dados da linha da ordem de venda
    cursor c_order_line is
      select nvl(line_number,rownum) line_number
            ,inventory_item_code
            ,unit_price
            ,list_price
            ,ordered_quantity
            ,unit_of_measure
            ,ship_from_org_code
            ,to_date(request_date,'YYYY-MM-DD"T"hh24:MI:SS') request_date
            ,to_date(schedule_ship_date,'YYYY-MM-DD"T"hh24:MI:SS') schedule_ship_date
            ,to_date(promise_date,'YYYY-MM-DD"T"hh24:MI:SS') promise_date            
            ,familia
            ,calibre
            ,sku
            ,grupo
            ,camada
            ,assistance_number
            ,line_discount
            ,earliest_acceptable_date
            ,ambient_type
            ,ship_set
       from json_table (p_body,'$.items[*]' columns (line_number              number     path '$.line_number'
                                                    ,inventory_item_code      varchar2   path '$.inventory_item_code'
                                                    ,unit_price               number     path '$.unit_price'
                                                    ,list_price               number     path '$.list_price'
                                                    ,ordered_quantity         number     path '$.ordered_quantity'
                                                    ,unit_of_measure          varchar2   path '$.unit_of_measure'
                                                    ,ship_from_org_code       varchar2   path '$.ship_from_org_code'
                                                    ,request_date             varchar2   path '$.request_date'
                                                    ,schedule_ship_date       varchar2   path '$.schedule_ship_date'
                                                    ,promise_date             varchar2   path '$.promise_date'       
                                                    ,familia                  varchar2   path '$.familia'
                                                    ,calibre                  varchar2   path '$.calibre'
                                                    ,sku                      varchar2   path '$.sku'
                                                    ,grupo                    varchar2   path '$.grupo'
                                                    ,camada                   varchar2   path '$.camada'
                                                    ,assistance_number        varchar2   path '$.assistance_number'
                                                    ,line_discount            number     path '$.line_discount'
                                                    ,earliest_acceptable_date date   path '$.earliest_acceptable_date'
                                                    ,ambient_type             varchar2   path '$.ambient_type'
                                                    ,ship_set                 varchar2   path '$.ship_set'
                                                    )
                       )
     where inventory_item_code is not null;
    --

    -- Seleciona a origem para transacao a ser gerada
    cursor c_source(p_source_name varchar2) is
      select order_source_id
      from   oe_order_sources
      where  1=1
      and    upper(name) = p_source_name;
    --
    w_erro     exception;
    w_po_existente exception;
    w_cliente_nao_habilitado exception;
    i_habilitado integer;
    --
    l_ds_erro  varchar2(4000);
    l_msg      varchar2(4000);
    l_msg2     varchar2(4000);
    l_log_list varchar2(4000);
    --
    l_order_header     order_header_r;
    l_order_line       order_line_t;
    l_order_header_aux order_header_aux_r;
    l_order_line_aux   order_line_aux_t;
    idx                integer := 0;
    --
    l_order_source_id  oe_order_headers_all.order_source_id%type;
    l_om_header_id     oe_order_headers_all.header_id%type;
    l_om_order_number  oe_order_headers_all.order_number%type;
    --
  begin
    --
    -- Seleciona dados do cabecalho da ordem de venda
    open  c_order_header;
    fetch c_order_header into l_order_header;
    close c_order_header;
    --
    -- Verifica se o pedido já foi integrado
    for r in (select 1
                from xxpb_po_integration_ctrl
               where order_source = l_order_header.order_source
                 and source_hdr_id = l_order_header.source_hdr_id) 
    loop
      raise w_po_existente;
    end loop;

    -- Registra pedido no controle de pedidos integrados
    insert into xxpb_po_integration_ctrl (order_source, source_hdr_id)
    values (l_order_header.order_source,l_order_header.source_hdr_id);
    commit;
    --
    -- Verificar se o cliente está habilitado para integração
    begin
      select count(1) habilitado
        into i_habilitado
        from fnd_lookup_values_vl flv
       where flv.LOOKUP_TYPE = 'OM_INTPEDIDO_CLIENTES'
         and flv.ENABLED_FLAG = 'Y'
         and sysdate between coalesce(flv.START_DATE_ACTIVE,sysdate-1) and coalesce(flv.END_DATE_ACTIVE,sysdate+1)
         and UPPER(flv.LOOKUP_CODE) in (
             l_order_header.order_source||'-'||l_order_header.sold_to_fiscal_id,
             l_order_header.order_source||'-TODOS'
             );
    exception
      when others then
        i_habilitado := 0;
    end;
    if i_habilitado = 0 then
       raise w_cliente_nao_habilitado;
    end if;

    --
    -- Seleciona dados da linha da ordem de venda
    open  c_order_line;
    fetch c_order_line bulk collect into l_order_line;
    close c_order_line;
    --
    -- Carrega tabela auxiliar de linhas
    l_order_line_aux := order_line_aux_t();
    for r_order_line in c_order_line loop
      --
      l_order_line_aux.extend;
      idx := idx +1;
      l_order_line_aux(idx).line_number := r_order_line.line_number;
      --
    end loop; -- c_order_line
    --
    --Seta as variaveis de contexto do EBS, para cria os pedidos
    fnd_global.apps_initialize( 14878, 21623, 660);
    mo_global.set_policy_context('S', fnd_profile.value('ORG_ID'));
    mo_global.init('ONT');    
    --
    -- Limpa dados de processamento da tabela de log
    begin
      --
      delete from xxpb_order_api_process_logs
      where  source_hdr_id = l_order_header.source_hdr_id;
      --
      commit;
      --
    exception
      when others then
        l_ds_erro := 'Erro: 1 - Erro ao excluir log do processamento, XXPB_ORDER_API_PROCESS_LOGS. Erro: '||sqlerrm||dbms_utility.format_error_backtrace;
        raise w_erro;
    end;
    --
    -- Seleciona a origem para transacao a ser gerada
    open  c_source(l_order_header.order_source);
    fetch c_source
    into  l_order_source_id;
    close c_source;
    --
    if l_order_source_id is null then
      --
      l_ds_erro := 'Erro: 2 - Erro ao selecionar configuracao de origem de importacao da ordem de venda no OM.';
      raise w_erro;
      --
    end if;
    --l_order_header_aux.invoice_to_org_id     := l_order_header.invoice_to_org_id;     
    
    l_order_header_aux.ship_from_org_id       := l_order_header.ship_from_org_id;
    l_order_header_aux.sold_to_org_id         := l_order_header.sold_to_org_id;
    l_order_header_aux.order_type_id          := l_order_header.order_type_id; 
    l_order_header_aux.salesrep_id            := l_order_header.salesrep_id;
    l_order_header_aux.sales_channel_code     := l_order_header.sales_channel_code;
    l_order_header_aux.price_list_id          := l_order_header.list_header_id; 
    l_order_header_aux.payment_term_id        := l_order_header.payment_term_id; 
    l_order_header_aux.sold_from_org_id       := l_order_header.sold_from_fiscal_id; 
    l_order_header_aux.fob_point_code         := l_order_header.freight_type;
    l_order_header_aux.demand_class_code      := l_order_header.demand_class_code;

      begin
        select uf filial_faturadora
        into   l_order_header_aux.estado_filial_fat
        from   ar_info_filial_pb
        where  1=1
        and    cnpjemit = l_order_header.sold_from_fiscal_id;
      exception
        when no_data_found then
          l_ds_erro := 'Erro: 4 - Estado da filial faturadora não encontrado para o SOLD_FROM_FISCAL_ID '|| l_order_header.sold_from_fiscal_id||'.';
          raise w_erro;
        when too_many_rows then
          l_ds_erro := 'Erro: 5 - Mais de um estado encontrado para a filial faturadora.';
          raise w_erro;
        when others then
          l_ds_erro := 'Erro: 6 - Erro ao selecionar o estado da filial faturadora. Erro: '||sqlerrm||dbms_utility.format_error_backtrace;
          raise w_erro;
      end;


        prc_consumo_cota_sales(l_order_header,w_msg_cota);        
        IF (w_msg_cota <> 'OK') THEN
            x_sts_code := c_status_erro;
            insert_log(l_order_header.source_hdr_id, '', 'Erro: 2 - Rotina de validacao de linhas - Validação Cota - '||w_msg_cota, 2);
        END IF;


    if nvl(l_order_header.carrier_id,0) > 0 then 
        select ship_method_code into l_order_header_aux.shipping_method_code from WSH_CARRIER_SERVICES where carrier_id = nvl(l_order_header.carrier_id,0);
    else
        select DISTINCT shipping_method_code, shipment_priority_code 
        into l_order_header_aux.shipping_method_code, l_order_header_aux.shipment_priority_code 
        from APPS.XXPB_HIST_PO_CLIENT where carrier_id = nvl(l_order_header.carrier_id,0);
    end if;
    
/*    
 l_ds_erro := 'Ship from org id:' || l_order_header.ship_from_org_id 
    || ' - sold_to_org_id:' || l_order_header.sold_to_org_id 
    || ' - order_type_id:' || l_order_header.order_type_id
    || ' - salesrep_id:' || l_order_header.salesrep_id 
    || ' - sales_channel_code:' || l_order_header.sales_channel_code 
    || ' - price_list_id:' || l_order_header.list_header_id
    || ' - payment_term_id:' || l_order_header.payment_term_id
    || ' - sold_from_org_id:' || l_order_header.sold_from_fiscal_id
    || ' - fob_point_code:' || l_order_header.freight_type
    || ' - sold_from_fiscal_id:' || l_order_header.sold_from_fiscal_id
    || ' - carrier_id:' || l_order_header.carrier_id
    || ' - sales_channel_code:' || l_order_header.sales_channel_code;     
    raise w_erro;
*/    
    -- Valida preenchimento de conta nacional - Canal ENGENHARIA
    BEGIN
      -- valida a conta nacional      
      if l_order_header.sales_channel_code = '1' or l_order_header.sales_channel_code = '101' then 
          IF (l_order_header.nacional_account IS NULL) THEN
              l_ds_erro := 'Erro: 6.0 - Conta Nacional não informada. Obrigatório para o Canal de Engenharia';
              raise w_erro;
          END IF;
      end if;
      --
    END;

    --
    if nvl(x_sts_code,c_status_pendente) != c_status_erro then
      --
      -- Procedimento para busca de dados do cliente
      valida_cliente(p_header     => l_order_header,
                     p_header_aux => l_order_header_aux,
                     o_sts_code   => x_sts_code
                    );
      --
    end if;
    --
    --if nvl(x_sts_code,c_status_pendente) != c_status_erro and l_order_header.domestic_foreign_ind = 'D' then
    --
    -- Procedimento para busca de filial faturadora
    if nvl(x_sts_code,c_status_pendente) != c_status_erro then

        validate_filial_faturadora(p_header     => l_order_header,
                                   p_header_aux => l_order_header_aux,
                                   p_items      => l_order_line,
                                   o_sts_code   => x_sts_code
                                  );
    end if;
    
/*
    -- Condição para testes iniciais, remover posteriormente
    if nvl(x_sts_code,c_status_pendente) != c_status_erro and l_order_header.domestic_foreign_ind = 'D' and l_order_header.order_source <> 'LEROY_MERLIN' then
      --
      -- Procedimento para busca de endereco de distribuicao
      valida_end_distribuicao(p_header     => l_order_header,
                              p_header_aux => l_order_header_aux,
                              o_sts_code   => x_sts_code
                             );
      --
    end if;
    --
*/    
    if nvl( x_sts_code, c_status_pendente ) != c_status_erro then
        /*
      -- Procedimento para selecao de dados adiconais para processamento da ordem de venda
      busca_dados_adicionais(p_header     => l_order_header,
                             p_header_aux => l_order_header_aux,
                             o_sts_code   => x_sts_code
                            );
        */
          -- Procedimento para validacao de linha
          validate_lines(p_header     => l_order_header,
                         p_header_aux => l_order_header_aux,
                         p_items      => l_order_line,
                         p_items_aux  => l_order_line_aux,
                         x_sts_code   => x_sts_code
                        );
      --
    end if;
    --
    if nvl( x_sts_code, c_status_pendente ) != c_status_erro then
      --
      -- Procedimento para buscar lista de preco
      valida_list_price(p_header     => l_order_header,
                        p_items      => l_order_line,
                        p_header_aux => l_order_header_aux,
                        p_items_aux  => l_order_line_aux,
                        o_sts_code   => x_sts_code
                       );
      --
    end if;
    --
    if nvl(x_sts_code,c_status_pendente) != c_status_erro then
      --
      -- Verifica se a ordem de venda atende as regras comerciais
      processa_regras_comerciais(p_header     => l_order_header,
                                 p_items      => l_order_line,
                                 p_header_aux => l_order_header_aux,
                                 p_items_aux  => l_order_line_aux,
                                 o_sts_code   => x_sts_code
                                );
      --
    end if;


    --
    if nvl( x_sts_code, c_status_pendente ) != c_status_erro then
      --
      ont_create_order(l_order_header,
                       l_order_line,
                       l_order_header_aux,
                       l_order_line_aux,
                       l_header_scredit_tbl,
                       l_order_source_id,
                       l_om_header_id,
                       l_om_order_number,
                       x_sts_code
                      );
      --
    end if;
    --
    -- Valida se processou com erro
    if x_sts_code <> c_status_sucesso then
      --
      x_om_header_id := l_om_header_id;
      x_om_order_num := l_om_order_number;
      --
      -- Procedimento para leitura de log de processamento
      x_log := read_log (p_source_hdr_id    => l_order_header.source_hdr_id
                        ,p_source_lin_id    => null
                        ,p_log_type         => 2 -- Erro
                        );
      --
      if x_om_header_id is not null then
        --
        -- Procedimento para validar divergencia de preco e aplicacao de retencao
        valida_diverg_preco(p_header     => l_order_header,
                            p_items_aux  => l_order_line_aux,
                            p_header_id  => x_om_header_id,
                            p_msg        => l_msg2,
                            o_sts_code   => x_sts_code
                           );
        --
        x_log := x_log || l_msg2;
        --
      end if;
      --
      l_msg := 'Ordem de Compra '||l_order_header.order_source||' processada com erro! '||chr(10)||chr(10)||
               --
               'Ordem de Compra '||l_order_header.order_source||': '||l_order_header.cust_po_number||chr(10)||
               'Ordem de Compra do cliente final: '||l_order_header.cust_po_number2||chr(10)||
               'Ordem de Venda do cliente PBG: '||l_order_header.cust_so_number||chr(10)||chr(10)||
               --
               'Ordem de Venda Oracle: '||x_om_order_num||chr(10)||chr(10)||
               --
               'Erro: '                 ||x_log||chr(10)||
               l_msg2
               ;
      --
      -- registra PO na tabela de controle caso tenha criado a OV
      if x_om_order_num is null then
        -- Em caso de erro, remove pedido da lista para permitir reenvio
        delete from xxpb_po_integration_ctrl
         where order_source = l_order_header.order_source
           and source_hdr_id = l_order_header.source_hdr_id;
        commit;
      end if;
      --      
      if l_order_header.emailaccwhenerror is not null then
        --
        -- Procedure para envio de e-mail
        prc_envia_email (p_ds_email_destino  => l_order_header.emailaccwhenerror
                        ,p_ds_assunto        => 'Integracao de Pedido '||l_order_header.order_source||' e EBS - Erro API XXPB_SALESFORCE_ORDER_ENTRY_PKG_BY7'
                        ,p_ds_corpo          => l_msg
                        ,p_camimho_arquivo   => null
                        ,p_ds_erro           => l_ds_erro
                        );
        --
      else
        insert_log(p_source_hdr_id => l_order_header.source_hdr_id,
                   p_source_lin_id => null,
                   p_message       => 'Sem conta para enviar e-mail '||l_msg,
                   p_log_type      => 1);
      end if;
      --
    -- Valida se processo com sucesso
    else
      --
      x_om_header_id := l_om_header_id;
      x_om_order_num := l_om_order_number;
      x_sts_code     := 1;
      
      
        IF registra_cota = 'S' THEN 
           xxpb_ont001_by7_k.prc_update_consumo_meta(p_id_cota_vendas  => w_id_cota_vendas
                                                    ,p_header_id       => l_om_header_id
                                                    ,p_ivop_id         => null
                                                    ,p_vl_consumo_meta => nvl(l_order_header.total_opportunity_quantity,0)
                                                    );
        
        END IF;
      

    -- Comissão e divisão de comissão
    --Chama a API para compartilhar a comissão
    l_header_scredit_index := 1;
    --l_header_scredit_tbl   := oe_order_pub.header_scredit_tbl_type;
    --Seleciona as comissoes da ordem
    FOR r_comiss IN (select val_percent, rep_id
                     from json_table (p_body,'$.comissions[*]' columns (val_percent number     path '$.val_percent',
                                                                           rep_id      number     path '$.rep_id'
                                                                        )
                                      )     where nvl(val_percent,0) > 0 ) LOOP

/*
      --Busca dados da comissao ja criada
      SELECT sales_credit_id,
               b.created_by,
               creation_date,
               salesrep_id
          INTO w_sales_credit_id,
               w_created_by,
               w_creation_date,
               w_salesrep_id
      FROM oe_sales_credits b
      WHERE header_id = l_om_header_id;


      IF w_salesrep_id = l_order_header.salesrep_id THEN
        l_header_scredit_tbl(l_header_scredit_index).operation             := oe_globals.g_opr_update; --oe_globals.g_opr_update;
        l_header_scredit_tbl(l_header_scredit_index).sales_credit_id       := w_sales_credit_id;
        l_header_scredit_tbl(l_header_scredit_index).created_by            := w_created_by;
        l_header_scredit_tbl(l_header_scredit_index).creation_date         := w_creation_date;
      ELSE
        l_header_scredit_tbl(l_header_scredit_index).operation             := oe_globals.g_opr_create;
        l_header_scredit_tbl(l_header_scredit_index).sales_credit_id       := oe_sales_credits_s.nextval;
      END IF;
*/
      
         l_header_scredit_tbl(l_header_scredit_index).operation             := oe_globals.g_opr_create;
      l_header_scredit_tbl(l_header_scredit_index).sales_credit_id       := oe_sales_credits_s.nextval;
      l_header_scredit_tbl(l_header_scredit_index).header_id             := l_om_header_id;
      l_header_scredit_tbl(l_header_scredit_index).percent               := r_comiss.val_percent;
      l_header_scredit_tbl(l_header_scredit_index).salesrep_id           := r_comiss.rep_id;
      l_header_scredit_tbl(l_header_scredit_index).sales_credit_type_id  := 1;
      l_header_scredit_index                                             := l_header_scredit_index + 1;
    END LOOP;


        oe_order_pub.process_order( p_api_version_number   => 1
                                   ,p_init_msg_list        => fnd_api.g_false
                                   ,p_return_values        => fnd_api.g_false
                                   ,p_action_commit        => fnd_api.g_false
                                   ,x_return_status        => l_sts_sales_credit
                                   ,x_msg_count            => l_msg_count
                                   ,x_msg_data             => l_msg_data
                                   ,p_header_scredit_tbl   => l_header_scredit_tbl
                                   --out
                                   ,x_header_rec           => x_header_rec
                                   ,x_header_val_rec       => x_header_val_rec
                                   ,x_header_adj_tbl       => x_header_adj_tbl
                                   ,x_header_adj_val_tbl   => x_header_adj_val_tbl
                                   ,x_header_price_att_tbl => x_header_price_att_tbl
                                   ,x_header_adj_att_tbl   => x_header_adj_att_tbl
                                   ,x_header_adj_assoc_tbl => x_header_adj_assoc_tbl
                                   ,x_header_scredit_tbl   => x_header_scredit_tbl
                                   ,x_header_scredit_val_tbl => x_header_scredit_val_tbl
                                   ,x_line_tbl             => x_line_tbl
                                   ,x_line_val_tbl         => x_line_val_tbl
                                   ,x_line_adj_tbl         => x_line_adj_tbl
                                   ,x_line_adj_val_tbl     => x_line_adj_val_tbl
                                   ,x_line_price_att_tbl   => x_line_price_att_tbl
                                   ,x_line_adj_att_tbl     => x_line_adj_att_tbl
                                   ,x_line_adj_assoc_tbl   => x_line_adj_assoc_tbl
                                   ,x_line_scredit_tbl     => x_line_scredit_tbl
                                   ,x_line_scredit_val_tbl => x_line_scredit_val_tbl
                                   ,x_lot_serial_tbl       => x_lot_serial_tbl
                                   ,x_lot_serial_val_tbl   => x_lot_serial_val_tbl
                                   ,x_action_request_tbl   => x_action_request_tbl);

        if nvl(l_sts_sales_credit,'ZZZ') = fnd_api.g_ret_sts_success then
          commit;
          
        else
          insert_log(l_order_header.source_hdr_id, '', 'Erro: 2 - Rotina de validacao de linhas - Erro comissão '||l_msg_data || ' - ' || l_msg_count || ' - ' || l_sts_sales_credit, 2);
          rollback;
        END IF;
      
      
      -- Procedimento para leitura de log de processamento
      x_log := read_log (p_source_hdr_id    => l_order_header.source_hdr_id
                        ,p_source_lin_id    => null
                        ,p_log_type         => 1 -- Advertências
                        );
      --
      if x_om_header_id is not null then
        --
        -- Procedimento para validar divergencia de preco e aplicacao de retencao
        valida_diverg_preco(p_header     => l_order_header,
                            p_items_aux  => l_order_line_aux,
                            p_header_id  => x_om_header_id,
                            p_msg        => l_msg2,
                            o_sts_code   => x_sts_code
                           );
        --
        if x_log is not null and l_msg2 is not null then
          x_log := x_log || chr(10);
        end if;
        x_log := x_log || l_msg2;
        --
      end if;
      --
      l_msg := 'Ordem de Compra '||l_order_header.order_source||' processada com sucesso: '||chr(10)||chr(10)||
               --
               'Ordem de Compra do cliente PBG: '||l_order_header.cust_po_number||chr(10)||
               'Ordem de Compra do cliente final: '||l_order_header.cust_po_number2||chr(10)||
               'Ordem de Venda do cliente PBG: '||l_order_header.cust_so_number||chr(10)||chr(10)||
               --
               'Ordem de Venda Oracle: '||x_om_order_num;

      if x_log is not null then
         l_msg := l_msg||chr(10)||chr(10)||
                  'Observacoes: '||chr(10)||
                  x_log;
      end if;
      --
      if l_order_header.emailaccwhensuccess is not null then
        --
        -- Procedure para envio de e-mail-
        prc_envia_email (p_ds_email_destino  => l_order_header.emailaccwhensuccess
                        ,p_ds_assunto        => 'Integracao de Pedido '||l_order_header.order_source||' e EBS - Ordem de Compra '||
                                                coalesce(l_order_header.cust_po_number2
                                                        ,l_order_header.cust_po_number)||
                                                ' processada com sucesso'
                        ,p_ds_corpo          => l_msg
                        ,p_camimho_arquivo   => null
                        ,p_ds_erro           => l_ds_erro
                        );
        --
      else
        insert_log(p_source_hdr_id => l_order_header.source_hdr_id,
                   p_source_lin_id => null,
                   p_message       => 'Sem conta para enviar e-mail '||l_msg,
                   p_log_type      => 1);
      end if;
      --
    end if;
    --
  exception
    when w_cliente_nao_habilitado then 
      x_sts_code := c_status_erro;
      x_log := 'O cliente '||l_order_header.sold_to_fiscal_id||' da origem '||l_order_header.order_source||
               ' não está habilitado para esta integração.';
      -- Em caso de erro, remove pedido da lista para permitir reenvio
      delete from xxpb_po_integration_ctrl
       where order_source = l_order_header.order_source
         and source_hdr_id = l_order_header.source_hdr_id;
      commit;
    when w_po_existente then 
      x_sts_code := c_status_advert;
      x_log := 'A PO '||l_order_header.source_hdr_id||' da origem '||l_order_header.order_source||
               ' já foi integrada anteriormente.';
    when w_erro then
      x_sts_code := c_status_erro;
      x_log      := l_ds_erro;
      -- registra PO na tabela de controle caso tenha criado a OV
      if x_om_order_num is null then
        -- Em caso de erro, remove pedido da lista para permitir reenvio
        delete from xxpb_po_integration_ctrl
         where order_source = l_order_header.order_source
           and source_hdr_id = l_order_header.source_hdr_id;
        commit;
      else
        x_log := x_log || '. '|| 'Ordem de venda criada: '||x_om_order_num||'. Verifique seu status.';
      end if;      
    when others then
      x_sts_code := c_status_erro;
      x_log := 'Erro na rotina main. Erro: '||sqlerrm||dbms_utility.format_error_backtrace;
      -- registra PO na tabela de controle caso tenha criado a OV
      if x_om_order_num is null then
        -- Em caso de erro, remove pedido da lista para permitir reenvio
        delete from xxpb_po_integration_ctrl
         where order_source = l_order_header.order_source
           and source_hdr_id = l_order_header.source_hdr_id;
        commit;
      else
        x_log := x_log || '. '|| 'Ordem de venda criada: '||x_om_order_num||'. Verifique seu status.';
      end if;      
  end main;
  --
  -- Procedimento para selecao de dados adiconais para processamento da ordem de venda
  procedure busca_dados_adicionais(p_header     in out order_header_r,
                                   p_header_aux in out order_header_aux_r,
                                   o_sts_code   in out number
                                  ) is
    --
    -- Seleciona dados adicionais com base na parametrizacao do painel de configuracoes
    -- Cursor alterado no dia 29/04/2021 - Juliano Floriano
    -- Union colocado para atender a regra abaixo
    -- Usando a combinação de campos ¿order_source¿ e ¿order_type¿:
    -- Campo ¿order_source¿: indica a origem ou contexto da integração;
    -- Campo ¿order_type¿: Tipo de Ordem do cliente;
    cursor c1 is
      select org_code
            ,order_type_id
            ,shipment_priority_code
            ,shipping_method_code
            ,salesrep_id
            ,list_header_id
            ,organization_id
      From ( select xoc.org_code
                   ,xoc.order_type_id
                   ,xoc.shipment_priority_code
                   ,xoc.shipping_method_code
                   ,xoc.salesrep_id
                   ,xoc.list_header_id
                   ,mp.organization_id
             from   xxpb_order_config_api xoc
                   ,mtl_parameters        mp
             where  1=1
             and    xoc.org_code            = mp.organization_code
             and    xoc.sold_from_fiscal_id = p_header.sold_from_fiscal_id
             and    xoc.sold_to_fiscal_id   = coalesce(p_header_aux.sold_to_fiscal_id_f,
                                                       p_header.sold_to_fiscal_id)
             --decode(p_header.domestic_foreign_ind,'D',p_header.sold_to_fiscal_id,p_header_aux.sold_to_fiscal_id_f)
             and    xoc.tp_ordem_cliente    = p_header.order_type
             union
                   select xoc.org_code
                   ,xoc.order_type_id
                   ,xoc.shipment_priority_code
                   ,xoc.shipping_method_code
                   ,xoc.salesrep_id
                   ,xoc.list_header_id
                   ,mp.organization_id
             from   xxpb_order_config_api xoc
                   ,mtl_parameters        mp
             where  1=1
             and    xoc.org_code            = mp.organization_code
             and    upper(xoc.order_source)        = p_header.order_source
             and    xoc.tp_ordem_cliente    = p_header.order_type
             and    xoc.sold_from_fiscal_id = p_header.sold_from_fiscal_id)
      Where rownum = 1;
      --
    r1 c1%rowtype;
    --
    -- Parametrizacao de condicao de pagamento de/para
    cursor c2 is
      select terms_id
      from   xxpb_order_config_api_termpay
      where  1=1
      and    cond_pag_cliente =  p_header.payment_term_code;
      --
    r2 c2%rowtype;
    --
    w_organization_id number default 1719;
    --
  begin
    --
    -- Seleciona dados adicionais com base na parametrizacao do painel de configuracoes
    open c1;
    fetch c1 into r1;
    --
    if c1%notfound then
      --
      o_sts_code := c_status_erro;
      insert_log(p_header.source_hdr_id,null,'Erro: 1 - Erro ao selecionar dados no painel de configuração. '||
                                             'Dados não encontrados com os parâmetros informados:'||
                                             ' SOLD_FROM_FISCAL_ID: '||      p_header.sold_from_fiscal_id||
                                             ', SOLD_TO_FISCAL_ID: '||       coalesce(p_header_aux.sold_to_fiscal_id_f,
                                                                                      p_header.sold_to_fiscal_id)|| 
                                                                              /*(CASE 
                                                                               WHEN p_header.domestic_foreign_ind = 'D' 
                                                                               THEN p_header.sold_to_fiscal_id
                                                                               ELSE p_header_aux.sold_to_fiscal_id_f
                                                                             END)||*/
                                             ', TP_ORDEM_CLIENTE: '|| p_header.order_type||
                                             ', ORDER_SOURCE: '|| p_header.order_source, 2);
      --
    else
      --
      w_organization_id                   := r1.organization_id;
      p_header_aux.order_type_id          := r1.order_type_id;
      p_header_aux.shipment_priority_code := r1.shipment_priority_code;
      p_header_aux.shipping_method_code   := r1.shipping_method_code;
      --
      p_header_aux.salesrep_id            := r1.salesrep_id;
      --insert_log(p_header.source_hdr_id,null,'p_header_aux.salesrep_id: '||p_header_aux.salesrep_id,1);
      --
      p_header_aux.sales_channel_code := xxpb_dados_ov_om.get_canal_vendedor(p_header_aux.salesrep_id);
      --
      if p_header_aux.price_list_id is null and r1.list_header_id is not null then
        --
        p_header_aux.price_list_id := r1.list_header_id;
        --
      end if;
      --
    end if; -- if c1%notfound then
    --
    close c1;
    --
    -- Parametrizacao de condicao de pagamento de/para
    open c2;
    fetch c2 into r2;
    --
    if c2%notfound then
      --
      o_sts_code := c_status_erro;
      insert_log(p_header.source_hdr_id,null,'Erro: 2 - Erro ao selecionar condição de pagamento do painel de configuração. Dados não encontrados com os parâmetros informados!', 2);
      --
    else
      --
      p_header_aux.payment_term_id := r2.terms_id;
      --
    end if; -- if c1%notfound then
    --
    close c2;
    --
    --
    p_header_aux.ship_from_org_id := w_organization_id;
    --
    if p_header_aux.sold_from_org_id is null then
      --
      p_header_aux.sold_from_org_id := fnd_profile.value('ORG_ID');
      --
    end if; -- if p_header_aux.sold_from_org_id is null then
    --
    o_sts_code := c_status_sucesso;
    --
  exception
    when others then
      o_sts_code := c_status_erro;
      insert_log(p_header.source_hdr_id,null,'Erro: 3 - Erro procedure BUSCA_DADOS_ADICIONAIS. Erro: '||sqlerrm||dbms_utility.format_error_backtrace, 2);
  end busca_dados_adicionais;
  --
  -- Procedimento para busca de dados do cliente
  procedure valida_cliente(p_header     in out order_header_r,
                           p_header_aux in out order_header_aux_r,
                           o_sts_code   in out number
                          ) is
    --
    -- Busca informacoes de clientes ja cadastrados
    cursor c1 is
      select party_name
            ,site_use_code
            ,nr_documento
            ,global_attribute2
            ,global_attribute3
            ,global_attribute4
            ,global_attribute5
            ,cust_contrib_type
            ,cust_acct_site_id
            ,cust_account_id
            ,party_site_id
            ,site_use_id
            ,party_id
            ,org_id
            ,bill_to_site_use_id
            ,primary_salesrep_id
            ,payment_term_id
            ,sales_channel_code
            ,country
            ,address1
            ,address2
            ,address3
            ,address4
            ,city
            ,postal_code
            ,state
            ,location
            ,price_list_id
      from (select hp.party_name
                  ,hcsua.site_use_code
                  ,decode(hcasa.global_attribute2,'1','CPF','2','CNPJ','EXTERIOR/OUTROS') tipo_documento
                  ,decode(hcasa.global_attribute2,'1',hcasa.global_attribute3||hcasa.global_attribute5
                                                 ,'2',hcasa.global_attribute3||hcasa.global_attribute4||hcasa.global_attribute5
                                                 ,hcasa.global_attribute3) nr_documento
                  ,hcasa.global_attribute2
                  ,hcasa.global_attribute3
                  ,hcasa.global_attribute4
                  ,hcasa.global_attribute5
                  ,hcasa.global_attribute8 cust_contrib_type
                  ,hcasa.cust_acct_site_id
                  ,hcasa.cust_account_id
                  ,hcasa.party_site_id
                  ,hcsua.site_use_id
                  ,hp.party_id
                  ,hcasa.org_id
                  ,COALESCE (hcsua.bill_to_site_use_id,
                            (select hcsua1.site_use_id 
                             from   apps.hz_cust_site_uses_all hcsua1
                             where  hcasa.cust_acct_site_id = hcsua1.cust_acct_site_id
                             and    hcsua1.site_use_code    = 'BILL_TO'
                             and    hcsua1.status           = 'A' )) bill_to_site_use_id
                  ,hcsua.primary_salesrep_id
                  ,hcaa.payment_term_id
                  ,hcaa.sales_channel_code
                  ,hl.country
                  ,hl.address1
                  ,hl.address2
                  ,hl.address3
                  ,hl.address4
                  ,hl.city
                  ,hl.postal_code
                  ,hl.state
                  ,hcsua.location
                  ,(select price_list_id
                    from   hz_cust_site_uses_all
                    where  1=1
                    and    site_use_id = hcsua.bill_to_site_use_id) price_list_id
            from   apps.hz_cust_acct_sites_all    hcasa
                  ,apps.hz_party_sites            hps
                  ,apps.hz_locations              hl
                  ,apps.hz_parties                hp
                  ,apps.hz_cust_accounts_all      hcaa
                  ,apps.hz_cust_site_uses_all     hcsua
            where  1=1
            and    hcasa.party_site_id     = hps.party_site_id
            and    hl.location_id          = hps.location_id
            and    hcaa.cust_account_id    = hcasa.cust_account_id
            and    hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
            and    hp.party_id             = hcaa.party_id
            and    hcsua.site_use_code     = 'SHIP_TO'
            and    hcasa.org_id            = fnd_profile.value('ORG_ID')
            and    hcasa.status            = 'A'
            and    hcsua.status            = 'A'
            --
            and hcasa.cust_acct_site_id  = p_header.cust_acct_site_id
            and hcasa.global_attribute3||hcasa.global_attribute4||hcasa.global_attribute5 = p_header.sold_to_fiscal_id

            and hcsua.location like p_header_aux.estado_filial_fat||'%'
            )
      where 1=1
      --and   (nr_documento = p_header.sold_to_fiscal_id or nr_documento = '0'||p_header.sold_to_fiscal_id)
      --and   location   like p_header_aux.estado_filial_fat||'%'
      ;
      --
    r1 c1%rowtype;


    -- Busca informacoes de clientes ja cadastrados - Cliente de Faturamento
    cursor c2 is
      select party_name
            ,site_use_code
            ,nr_documento
            ,global_attribute2
            ,global_attribute3
            ,global_attribute4
            ,global_attribute5
            ,cust_contrib_type
            ,cust_acct_site_id
            ,cust_account_id
            ,party_site_id
            ,site_use_id
            ,party_id
            ,org_id
            ,bill_to_site_use_id
            ,primary_salesrep_id
            ,payment_term_id
            ,sales_channel_code
            ,country
            ,address1
            ,address2
            ,address3
            ,address4
            ,city
            ,postal_code
            ,state
            ,location
            ,price_list_id
      from (select hp.party_name
                  ,hcsua.site_use_code
                  ,decode(hcasa.global_attribute2,'1','CPF','2','CNPJ','EXTERIOR/OUTROS') tipo_documento
                  ,decode(hcasa.global_attribute2,'1',hcasa.global_attribute3||hcasa.global_attribute5
                                                 ,'2',hcasa.global_attribute3||hcasa.global_attribute4||hcasa.global_attribute5
                                                 ,hcasa.global_attribute3) nr_documento
                  ,hcasa.global_attribute2
                  ,hcasa.global_attribute3
                  ,hcasa.global_attribute4
                  ,hcasa.global_attribute5
                  ,hcasa.global_attribute8 cust_contrib_type
                  ,hcasa.cust_acct_site_id
                  ,hcasa.cust_account_id
                  ,hcasa.party_site_id
                  ,hcsua.site_use_id
                  ,hp.party_id
                  ,hcasa.org_id
                  ,COALESCE (hcsua.bill_to_site_use_id,
                            (select hcsua1.site_use_id 
                             from   apps.hz_cust_site_uses_all hcsua1
                             where  hcasa.cust_acct_site_id = hcsua1.cust_acct_site_id
                             and    hcsua1.site_use_code    = 'BILL_TO'
                             and    hcsua1.status           = 'A' )) bill_to_site_use_id
                  ,hcsua.primary_salesrep_id
                  ,hcaa.payment_term_id
                  ,hcaa.sales_channel_code
                  ,hl.country
                  ,hl.address1
                  ,hl.address2
                  ,hl.address3
                  ,hl.address4
                  ,hl.city
                  ,hl.postal_code
                  ,hl.state
                  ,hcsua.location
                  ,(select price_list_id
                    from   hz_cust_site_uses_all
                    where  1=1
                    and    site_use_id = hcsua.bill_to_site_use_id) price_list_id
            from   apps.hz_cust_acct_sites_all    hcasa
                  ,apps.hz_party_sites            hps
                  ,apps.hz_locations              hl
                  ,apps.hz_parties                hp
                  ,apps.hz_cust_accounts_all      hcaa
                  ,apps.hz_cust_site_uses_all     hcsua
            where  1=1
            and    hcasa.party_site_id     = hps.party_site_id
            and    hl.location_id          = hps.location_id
            and    hcaa.cust_account_id    = hcasa.cust_account_id
            and    hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
            and    hp.party_id             = hcaa.party_id
            and    hcsua.site_use_code     = 'SHIP_TO'
            and    hcasa.org_id            = fnd_profile.value('ORG_ID')
            and    hcasa.status            = 'A'
            and    hcsua.status            = 'A'
            --
            and hcasa.cust_acct_site_id  = p_header.billing_account
            and hcasa.global_attribute3||hcasa.global_attribute4||hcasa.global_attribute5 = p_header.sold_to_fiscal_id

            and hcsua.location like p_header_aux.estado_filial_fat||'%'
            )
      where 1=1
      --and   (nr_documento = p_header.sold_to_fiscal_id or nr_documento = '0'||p_header.sold_to_fiscal_id)
      --and   location   like p_header_aux.estado_filial_fat||'%'
      ;
      --
    r2 c2%rowtype;
    -- Busca informacoes de clientes ja cadastrados com objetivo comercial faturar para, caso esta informação não seja capturada no cursor 1
    cursor c4 is
      select nr_documento
            ,site_use_id
            ,location
            ,price_list_id
      from (select decode(hcasa.global_attribute2,'1',hcasa.global_attribute3||hcasa.global_attribute5
                                                 ,'2',hcasa.global_attribute3||hcasa.global_attribute4||hcasa.global_attribute5
                                                 ,hcasa.global_attribute3) nr_documento
                  ,hcsua.site_use_id
                  ,hcsua.location
                  ,hcsua.price_list_id
            from   apps.hz_cust_acct_sites_all    hcasa
                  ,apps.hz_party_sites            hps
                  ,apps.hz_locations              hl
                  ,apps.hz_parties                hp
                  ,apps.hz_cust_accounts_all      hcaa
                  ,apps.hz_cust_site_uses_all     hcsua
            where  1=1
            and    hcasa.party_site_id     = hps.party_site_id
            and    hl.location_id          = hps.location_id
            and    hcaa.cust_account_id    = hcasa.cust_account_id
            and    hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
            and    hp.party_id             = hcaa.party_id
            and    hcsua.site_use_code     = 'BILL_TO'
            and    hcasa.org_id            = fnd_profile.value('ORG_ID')
            and    hcasa.status            = 'A'
            and    hcsua.status            = 'A'
            and hcasa.global_attribute3||hcasa.global_attribute4||hcasa.global_attribute5 = p_header.sold_to_fiscal_id

            --
            and ((p_header.domestic_foreign_ind = 'F' and 
                  hcasa.global_attribute2 = '3' and 
                  hcasa.global_attribute3 = p_header.sold_to_fiscal_id) or 
                 (p_header.domestic_foreign_ind = 'D' and 
                  hcasa.global_attribute2 = '2' and 
                  hcasa.global_attribute3||hcasa.global_attribute4||hcasa.global_attribute5 = '0'||p_header.sold_to_fiscal_id
                 )
                )
            and hcsua.location like p_header_aux.estado_filial_fat||'%'
            )
      where 1=1
      --and   (nr_documento = p_header.sold_to_fiscal_id or nr_documento = '0'||p_header.sold_to_fiscal_id)
      --and   location   like p_header_aux.estado_filial_fat||'%'
      ;
      --
    r4 c4%rowtype;
    --
  begin
    
    -- Cliente cliente mercado interno
    if p_header.domestic_foreign_ind = 'D' or 
         (p_header.domestic_foreign_ind = 'F' and upper(p_header.order_type) not in ('DROPSHIP')) then
      --
      -- Este campo conte a chave de identificacao do cliente que está adquirindo os produtos
      if p_header.sold_to_fiscal_id is not null then
        --
        open c1;
        fetch c1 into r1;
        --
        if c1%found then
          --
          if p_header.sold_to_org_id is not null then 
            p_header_aux.sold_to_org_id     := p_header.sold_to_org_id;
          else
            p_header_aux.sold_to_org_id     := r1.cust_account_id;
          end if;
          
          p_header_aux.ship_to_org_id     := r1.site_use_id;
          p_header_aux.invoice_to_org_id  := r1.bill_to_site_use_id;
          if p_header.billing_account !=  p_header.cust_acct_site_id then 
            p_header_aux.invoice_to_org_id  := r2.bill_to_site_use_id;
          end if;
          p_header_aux.sold_from_org_id   := r1.org_id;
          p_header_aux.cust_contrib_type  := r1.cust_contrib_type;
          --
          if p_header_aux.invoice_to_org_id is null then
            --
            for r4 in c4 loop
              p_header_aux.invoice_to_org_id := r4.site_use_id;
            end loop;
            --
            if p_header_aux.invoice_to_org_id is null then
              --
              o_sts_code := c_status_erro;
              insert_log(p_header.source_hdr_id,null,'Erro: 5 - Endereço de faturamento não encontrado para o cliente!', 2);
              --
            end if;
            --
          end if;
          --
        else -- if c1%notfound then
          --
          o_sts_code := c_status_erro;
          insert_log(p_header.source_hdr_id,null,'Erro: 6 - Valor informado no campo SOLD_TO_FISCAL_ID inválido, cliente não encontrado!', 2);
          --
        end if; -- c1
        --
        close c1;
        --
      else -- if p_header.sold_to_fiscal_id is null then
        --
        o_sts_code := c_status_erro;
        insert_log(p_header.source_hdr_id,null,'Erro: 7 - Valor nulo informado no campo SOLD_TO_FISCAL_ID!', 2);
        --
      end if; -- if p_header.sold_to_fiscal_id is not null then
      --
    end if; -- if p_header.domestic_foreign_ind = 'F' then
    --
  exception
    when others then
      o_sts_code := c_status_erro;
      insert_log(p_header.source_hdr_id,null,'Erro: 8 - Erro procedure VALIDA_CLIENTE. Erro: '||sqlerrm||dbms_utility.format_error_backtrace, 2);
  end valida_cliente;
  --
  -- Procedimento para buscar lista de preco
  procedure valida_list_price(p_header     in out order_header_r,
                              p_items      in out order_line_t,
                              p_header_aux in out order_header_aux_r,
                              p_items_aux  in out order_line_aux_t,
                              o_sts_code   in out number
                             ) is
  --
  cursor c1(p_inventory_item_code in varchar2
           ,p_price_date          in date
           ) is
    select hcsua.site_use_id
          ,ocat.prefixo||
           case when ocat.fase_vida = 'S' then msi.attribute9 else '' end||
           case when ocat.uf = 'S'        then hl.state       else '' end||
           to_char(p_price_date,coalesce(
           ( select   flv.MEANING  
             from     fnd_lookup_values_vl flv
             where ocat.periodo = flv.lookup_code
             and flv.LOOKUP_TYPE = 'OM_INTPEDIDO_TABPRECO_PERIODO'
             and flv.ENABLED_FLAG = 'Y'
             and sysdate between coalesce(flv.START_DATE_ACTIVE,sysdate-1) and coalesce(flv.END_DATE_ACTIVE,sysdate+1)
                      ),'YYMM')) nome_tabela


          ,qll.operand preco
          ,ocat.prioridade
          ,ocat.cust_account_id
          ,ocat.sales_channel
          ,ocat.tipo
          ,ocat.prefixo
          ,ocat.fase_vida
          ,ocat.uf
          ,ocat.periodo
          ,hca.account_number
          ,msi.attribute9 fase_vida_item
          ,hl.state
          ,hca.sales_channel_code
          ,qlh.list_header_id
          ,qll.list_line_id
      from xxpb_order_config_api_tabprice ocat
          ,hz_cust_acct_sites_all         hcasa
          ,hz_cust_site_uses_all          hcsua
          ,hz_cust_accounts               hca
          ,apps.hz_party_sites            hps
          ,apps.hz_locations              hl
          ,mtl_system_items_b             msi
          ,qp_list_headers                qlh
          ,qp_list_lines                  qll
     where 1=1
       -- liganto tabela de parâmetros com o cliente ou com seu canal de vendas
       and (ocat.cust_account_id = hcasa.cust_account_id or
            ocat.sales_channel   = hca.sales_channel_code)
       --
       and hcasa.party_site_id     = hps.party_site_id
       and hl.location_id          = hps.location_id
       and hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
       and hcsua.site_use_code     = 'BILL_TO'
       and hca.cust_account_id     = hcasa.cust_account_id
       and msi.organization_id     = pb_master_organization_id
       and qll.list_header_id      = qlh.list_header_id
       and qll.inventory_item_id   = msi.inventory_item_id
       and trunc(sysdate) between coalesce(qlh.START_DATE_ACTIVE,sysdate-1) and coalesce(qlh.END_DATE_ACTIVE,sysdate+1)
       and trunc(sysdate) between coalesce(qll.START_DATE_ACTIVE,sysdate-1) and coalesce(qll.END_DATE_ACTIVE,sysdate+1)
       and qlh.name                = ocat.prefixo||
                                     case when ocat.fase_vida = 'S' then msi.attribute9 else '' end||
                                     case when ocat.uf = 'S'        then hl.state       else '' end||
                                     to_char(p_price_date,coalesce(
                                                 ( select   flv.MEANING  
                                                   from     fnd_lookup_values_vl flv
                                                   where ocat.periodo = flv.lookup_code
                                                   and flv.LOOKUP_TYPE = 'OM_INTPEDIDO_TABPRECO_PERIODO'
                                                   and flv.ENABLED_FLAG = 'Y'
                                                   and sysdate between coalesce(flv.START_DATE_ACTIVE,sysdate-1) and coalesce(flv.END_DATE_ACTIVE,sysdate+1)
                                                            ),'YYMM'))
       and qlh.ATTRIBUTE15         = pb_categorias_item(W_INVENTORY_ITEM_ID => msi.inventory_item_id,
                                                        W_ORGANIZATION_CODE => null,
                                                        W_ORGANIZATION_ID   => msi.organization_id,
                                                        W_CATEGORIA         => 'Marca do Item',
                                                        W_FORM_LEFT_PROMPT  => 'Marca',
                                                        W_TIPO_INFORMACAO   => 1)
       -- Contexto de cliente e item
       and hcsua.site_use_id       = p_header_aux.invoice_to_org_id
       and msi.segment1            = p_inventory_item_code
     order by ocat.prioridade;
     --
    r1 c1%rowtype;
    --
    cursor c2(p_list_header_id integer, p_cod_produto varchar2) is
    --
    select qlh.NAME                       tabela
          ,qll.operand                    preco
          --
      from qp_list_headers                qlh
          ,qp_list_lines                  qll
          ,mtl_system_items_b             msi
          --
     where qll.list_header_id             = qlh.list_header_id
       and qll.inventory_item_id          = msi.inventory_item_id
       and msi.organization_id            = pb_master_organization_id
       and sysdate between coalesce(qlh.START_DATE_ACTIVE,sysdate-1) and coalesce(qlh.END_DATE_ACTIVE,sysdate+1)
       and sysdate between coalesce(qll.START_DATE_ACTIVE,sysdate-1) and coalesce(qll.END_DATE_ACTIVE,sysdate+1)
       --
       and msi.segment1                   = p_cod_produto
       and qlh.list_header_id             = p_list_header_id
     ;
    r2 c2%rowtype;

    v_price_list_id_cliente integer;
    --
  begin
    --
    v_price_list_id_cliente:=p_header_aux.price_list_id;
    --
    for i in p_items.first..p_items.last loop
      --
      p_items_aux(i).line_number  := i;
      --
      open c2(v_price_list_id_cliente,p_items(i).inventory_item_code);
      fetch c2 into r2;

      if c2%found then

        p_items_aux(i).price_list_id  := v_price_list_id_cliente;
        if r2.preco = p_items(i).list_price then
           p_items_aux(i).validate_price := true;
        else
          p_items_aux(i).validate_price := false;
          p_items_aux(i).desc_error     := 'Divergencia entre preço '||p_items(i).list_price||
                                           ' da PO versus preço '||r2.preco||' da tabela '||
                                           r2.tabela||
                                           ' para o item '||p_items(i).inventory_item_code;
        end if;
        close c2;

      else

        close c2;
        open c1(p_items(i).inventory_item_code
               ,coalesce(p_header.pricing_date,sysdate)
               );
        fetch c1 into r1;
        --
        if c1%found then
          --
          close c1;
          --
          for r1 in c1(p_items(i).inventory_item_code
                      ,nvl(p_header.pricing_date,sysdate)
                      ) loop
            --
            if r1.preco = p_items(i).list_price then
              --
              p_items_aux(i).price_list_id  := r1.list_header_id;
              p_items_aux(i).validate_price := true;
              --
            else
              --
              p_items_aux(i).price_list_id  := r1.list_header_id;
              p_items_aux(i).validate_price := false;
              p_items_aux(i).desc_error     := 'Divergencia entre preço '||p_items(i).list_price||
                                               ' da PO versus preço '||r1.preco||' da tabela '||
                                               r1.nome_tabela||
                                               ' para o item '||p_items(i).inventory_item_code;
              --
            end if;
            --
            -- Verifica se lista de preco do cabecalho esta informada, caso negativo, atribuir a primeira lista que achar
            if p_header_aux.price_list_id is null then
              --
              p_header_aux.price_list_id := r1.list_header_id;
              --
            end if;
            --
            if p_items_aux(i).price_list_id is not null then
              --
              exit;
              --
            end if;
            --
          end loop; -- c1
          --
        else -- if c1%notfound then
          --
          close c1;
          --
          p_items_aux(i).validate_price := false;
          p_items_aux(i).desc_error     := 'Erro: 1 - Não encontrada tabela de preços para o item '||p_items(i).inventory_item_code||
                                           ' na data '||coalesce(p_header.pricing_date,sysdate);
          --
          insert_log(p_source_hdr_id => p_header.source_hdr_id,
                     p_source_lin_id => null,
                     p_message       => p_items_aux(i).desc_error||'.',
                     p_log_type      => 2);
        end if; -- if c1%found then
        --
      end if;
    end loop; -- p_items
    --
  exception
    when others then
      o_sts_code := c_status_erro;
      insert_log(p_header.source_hdr_id,null,'Erro: 2 - Erro na procedure VALIDA_LIST_PRICE. Erro: '||sqlerrm||dbms_utility.format_error_backtrace, 2);
  end valida_list_price;
  --
  --Objetivo: Registrar ordem de venda no Oracle.
  procedure book_order ( p_source_hdr_id    in number
                        ,p_om_header_id     in number
                        ,o_sts_code        out varchar2) is
    --
    l_flow_status_code       varchar2(50) := null;
    l_action_request_tbl     oe_order_pub.request_tbl_type := oe_order_pub.g_miss_request_tbl;
    --out variables
    o_header_rec             oe_order_pub.header_rec_type;
    o_line_tbl               oe_order_pub.line_tbl_type;
    o_action_request_tbl     oe_order_pub.request_tbl_type;
    o_return_status          varchar2(1000) := null;
    o_msg_count              number := 0;
    o_msg_data               varchar2(1000) := null;
    o_header_val_rec         oe_order_pub.header_val_rec_type;
    o_header_adj_tbl         oe_order_pub.header_adj_tbl_type;
    o_header_adj_val_tbl     oe_order_pub.header_adj_val_tbl_type;
    o_header_price_att_tbl   oe_order_pub.header_price_att_tbl_type;
    o_header_adj_att_tbl     oe_order_pub.header_adj_att_tbl_type;
    o_header_adj_assoc_tbl   oe_order_pub.header_adj_assoc_tbl_type;
    o_header_scredit_tbl     oe_order_pub.header_scredit_tbl_type;
    o_header_scredit_val_tbl oe_order_pub.header_scredit_val_tbl_type;
    o_line_val_tbl           oe_order_pub.line_val_tbl_type;
    o_line_adj_tbl           oe_order_pub.line_adj_tbl_type;
    o_line_adj_val_tbl       oe_order_pub.line_adj_val_tbl_type;
    o_line_price_att_tbl     oe_order_pub.line_price_att_tbl_type;
    o_line_adj_att_tbl       oe_order_pub.line_adj_att_tbl_type;
    o_line_adj_assoc_tbl     oe_order_pub.line_adj_assoc_tbl_type;
    o_line_scredit_tbl       oe_order_pub.line_scredit_tbl_type;
    o_line_scredit_val_tbl   oe_order_pub.line_scredit_val_tbl_type;
    o_lot_serial_tbl         oe_order_pub.lot_serial_tbl_type;
    o_lot_serial_val_tbl     oe_order_pub.lot_serial_val_tbl_type;
    o_msg_index_out          number := 0;
  --
  begin
    --
    oe_msg_pub.initialize;
    --
    l_action_request_tbl(1).request_type := oe_globals.g_book_order;
    l_action_request_tbl(1).entity_code  := oe_globals.g_entity_header;
    l_action_request_tbl(1).entity_id    := p_om_header_id;
    --
    --Objetivo: Executar processo que registrar o pedido de venda no Oracle.
    oe_order_pub.process_order( p_api_version_number     => 1
                               ,p_init_msg_list          => fnd_api.g_false
                               ,p_return_values          => fnd_api.g_false
                               ,p_action_commit          => fnd_api.g_false
                               ,p_action_request_tbl     => l_action_request_tbl
                               --out variables
                               ,x_header_rec             => o_header_rec
                               ,x_header_val_rec         => o_header_val_rec
                               ,x_header_adj_tbl         => o_header_adj_tbl
                               ,x_header_adj_val_tbl     => o_header_adj_val_tbl
                               ,x_header_price_att_tbl   => o_header_price_att_tbl
                               ,x_header_adj_att_tbl     => o_header_adj_att_tbl
                               ,x_header_adj_assoc_tbl   => o_header_adj_assoc_tbl
                               ,x_header_scredit_tbl     => o_header_scredit_tbl
                               ,x_header_scredit_val_tbl => o_header_scredit_val_tbl
                               ,x_line_tbl               => o_line_tbl
                               ,x_line_val_tbl           => o_line_val_tbl
                               ,x_line_adj_tbl           => o_line_adj_tbl
                               ,x_line_adj_val_tbl       => o_line_adj_val_tbl
                               ,x_line_price_att_tbl     => o_line_price_att_tbl
                               ,x_line_adj_att_tbl       => o_line_adj_att_tbl
                               ,x_line_adj_assoc_tbl     => o_line_adj_assoc_tbl
                               ,x_line_scredit_tbl       => o_line_scredit_tbl
                               ,x_line_scredit_val_tbl   => o_line_scredit_val_tbl
                               ,x_lot_serial_tbl         => o_lot_serial_tbl
                               ,x_lot_serial_val_tbl     => o_lot_serial_val_tbl
                               ,x_action_request_tbl     => o_action_request_tbl
                               ,x_return_status          => o_return_status
                               ,x_msg_count              => o_msg_count
                               ,x_msg_data               => o_msg_data
                               );
    --
    --Objetivo: Recuperar status do cabecalho.
    begin
      select flow_status_code
      into   l_flow_status_code
      from   oe_order_headers_all
      where  header_id = p_om_header_id;
    exception
      when others then
        l_flow_status_code := '';
    end;
    --
    --Objetivo: Verificar se pedido foi registrado corretamente no Oracle.
    if o_return_status = fnd_api.g_ret_sts_success and l_flow_status_code = 'BOOKED' then
      --
      o_sts_code := c_status_sucesso;
      --
    elsif o_return_status = fnd_api.g_ret_sts_success and l_flow_status_code != 'BOOKED' then
      --
      o_sts_code := c_status_erro;
      --
      for i in 1 .. o_msg_count loop
        --
        --Objetivo: Retorno para registro do erro na tabela de log.
        oe_msg_pub.get(i, fnd_api.g_false, o_msg_data, o_msg_index_out);
        insert_log(p_source_hdr_id,null,'Erro: 1 - Erro ao registrar ordem de venda no Oracle. Erro: '||trim(o_msg_data), 2);
        --
      end loop;
      --Objetivo: Retorno para registro do erro no output e envio para microvix.
      insert_log(p_source_hdr_id,null,'Erro: 2 - Ordem nao foi registrada. Verificar erros na tela de ordem de venda. Status do pedido: '||l_flow_status_code, 2);
      --
    elsif o_return_status != fnd_api.g_ret_sts_success then
      --
      rollback;
      --
      o_sts_code := c_status_erro;
      --
      for i in 1 .. o_msg_count loop
        --
        --Objetivo: Retorno para registro do erro na tabela de log.
        oe_msg_pub.get(i, fnd_api.g_false, o_msg_data, o_msg_index_out);
        --
        insert_log(p_source_hdr_id,null,'Erro: 3 - Erro ao registrar ordem de venda. Erro: '||trim(o_msg_data), 2);
        --
      end loop;
      --
      --Objetivo: Retorno para registro do erro no output e envio para microvix.
      insert_log(p_source_hdr_id,null,'Erro: 4 - Erro ao registrar ordem de venda. Erro: '||trim(o_msg_data), 2);
      --
    end if;
    --
    commit;
    --
  end book_order;
  --
  procedure ont_create_order(p_header             in order_header_r,
                             p_items              in order_line_t,
                             p_header_aux         in order_header_aux_r,
                             p_items_aux          in order_line_aux_t,
                             l_header_scredit_tbl in oe_order_pub.header_scredit_tbl_type,
                             p_order_source_id    in number,
                             x_om_header_id       out number,
                             x_om_order_num       out varchar2,
                             x_sts_code           out varchar2
                             ) is
    --
 wmsg_data        varchar2(2000);
  wmsg_count       number;
  wreturn_status   varchar2(1);    
    --
    -- Seleciona o ID do item
    cursor c_item (p_inventory_item_code in varchar2)is
      select msy.inventory_item_id
      from   mtl_system_items_b msy
      where  1=1
      and    msy.organization_id = pb_master_organization_id
      and    msy.segment1        = p_inventory_item_code;
    --
    -- Seleciona informacoes do tipo de transacao do OM
    cursor c_order_type(p_transaction_type_id number) is
      select ott.shipping_method_code,                -- Metodo de Entrega
             ott.attribute12--,                         -- Obriga_agenda_transporte
             --ott.default_outbound_line_type_id        -- Tipo de linha
      from   ont.oe_transaction_types_all ott
      where  1=1
      and    ott.transaction_type_id   = p_transaction_type_id
      and    ott.transaction_type_code = 'ORDER';
    --
    l_header_rec             oe_order_pub.header_rec_type;
    l_line_tbl               oe_order_pub.line_tbl_type;
    l_line_tbl_index         number := 0;

    l_ds_contato             pb_mvix_om_headers.ds_contato%type                 := null;
    l_cd_area_contato        pb_mvix_om_headers.cd_area_contato%type            := null;
    l_nr_telefone_contato    pb_mvix_om_headers.nr_telefone_contato%type        := null;
    l_id_local_entrega       pb_mvix_om_headers.id_local_entrega%type           := null;
    l_hr_entrega_inicio      pb_mvix_om_headers.hr_entrega_inicio%type          := null;
    l_hr_entrega_final       pb_mvix_om_headers.hr_entrega_final%type           := null;
    l_id_acessa_caminhao     pb_mvix_om_headers.id_acessa_caminhao%type         := null;
    l_ds_ponto_referencia    pb_mvix_om_headers.ds_ponto_referencia%type        := null;
    l_qt_dia_entrega_cliente pb_mvix_om_headers.qt_dia_entrega_cliente%type     := null;
    l_ds_armazenar           pb_mvix_om_headers.ds_armazenar%type               := null;
    l_ds_dificuldade         pb_mvix_om_headers.ds_dificuldade%type             := null;
    l_ds_comentario          pb_mvix_om_headers.ds_comentario%type              := null;
    l_ds_email               pb_mvix_om_headers.ds_email%type                   := null;
    l_cd_area_contato2       pb_mvix_om_headers.cd_area_contato2%type           := null;
    l_nr_telefone_contato2   pb_mvix_om_headers.nr_telefone_contato2%type       := null;
    l_mvix_sales_approval_date pb_mvix_om_headers.mvix_sales_approval_date%type := null;
    l_cust_name              pb_mvix_om_headers.cust_name%type                  := null;
    l_cust_area_code         pb_mvix_om_headers.cust_phone_number%type          := null;
    l_cust_phone_number      pb_mvix_om_headers.cust_phone_number%type          := null;
    l_instructions           varchar2(1000)                                     := null;
    l_iface_lines            number                                             := 0;
    l_loop_lines             number                                             := 0;
    --out variables
    o_msg_index_out          number                                             := 0;
    o_header_rec             oe_order_pub.header_rec_type;
    o_line_tbl               oe_order_pub.line_tbl_type;
    o_action_request_tbl     oe_order_pub.request_tbl_type;
    o_return_status          varchar2(1000)                                     := null;
    o_msg_count              number                                             := 0;
    o_msg_date               varchar2(1000)                                     := null;
    o_header_val_rec         oe_order_pub.header_val_rec_type;
    o_header_adj_tbl         oe_order_pub.header_adj_tbl_type;
    o_header_adj_val_tbl     oe_order_pub.header_adj_val_tbl_type;
    o_header_price_att_tbl   oe_order_pub.header_price_att_tbl_type;
    o_header_adj_att_tbl     oe_order_pub.header_adj_att_tbl_type;
    o_header_adj_assoc_tbl   oe_order_pub.header_adj_assoc_tbl_type;
    o_header_scredit_tbl     oe_order_pub.header_scredit_tbl_type;
    o_header_scredit_val_tbl oe_order_pub.header_scredit_val_tbl_type;
    o_line_val_tbl           oe_order_pub.line_val_tbl_type;
    o_line_adj_tbl           oe_order_pub.line_adj_tbl_type;
    o_line_adj_val_tbl       oe_order_pub.line_adj_val_tbl_type;
    o_line_price_att_tbl     oe_order_pub.line_price_att_tbl_type;
    o_line_adj_att_tbl       oe_order_pub.line_adj_att_tbl_type;
    o_line_adj_assoc_tbl     oe_order_pub.line_adj_assoc_tbl_type;
    o_line_scredit_tbl       oe_order_pub.line_scredit_tbl_type;
    o_line_scredit_val_tbl   oe_order_pub.line_scredit_val_tbl_type;
    o_lot_serial_tbl         oe_order_pub.lot_serial_tbl_type;
    o_lot_serial_val_tbl     oe_order_pub.lot_serial_val_tbl_type;
    l_shipping_method_code   oe_transaction_types_all.shipping_method_code%type;
    l_attribute12            oe_transaction_types_all.attribute12%type;
    l_inventory_item_id      mtl_system_items_b.inventory_item_id%TYPE;
    l_line_type_id           integer;
    --
    
    
  begin
    --
    oe_msg_pub.initialize;
    --
    mo_global.set_policy_context('S', fnd_profile.value('ORG_ID'));
    mo_global.init('ONT');
    --
    open  c_order_type(p_header_aux.order_type_id);
    fetch c_order_type into l_shipping_method_code,l_attribute12
                            --,l_line_type_id
                            ;
    close c_order_type;
    --
    
    --o_header_scredit_tbl       := l_header_scredit_tbl;
    
    l_ds_contato               := p_header.ds_contato;
    l_cd_area_contato          := p_header.cd_area_contato;
    l_nr_telefone_contato      := p_header.nr_telefone_contato;
    l_id_local_entrega         := p_header.id_local_entrega;
    l_hr_entrega_inicio        := to_date(p_header.hr_entrega_inicio,'YYYY-MM-DD"T"hh24:MI:SS');
    l_hr_entrega_final         := to_date(p_header.hr_entrega_final,'YYYY-MM-DD"T"hh24:MI:SS');
    l_id_acessa_caminhao       := p_header.id_acessa_caminhao;
    l_ds_ponto_referencia      := p_header.ds_ponto_referencia;
    l_qt_dia_entrega_cliente   := p_header.qt_dia_entrega_cliente;
    l_ds_armazenar             := p_header.ds_armazenar;
    l_ds_dificuldade           := p_header.ds_dificuldade;
    l_ds_comentario            := p_header.ds_comentario;
    l_ds_email                 := p_header.ds_email;
    l_cd_area_contato2         := p_header.cd_area_contato2;
    l_nr_telefone_contato2     := p_header.nr_telefone_contato2;
    l_cust_name                := p_header.cust_name;
    l_cust_area_code           := substr(p_header.cust_phone_number,1,2);
    l_cust_phone_number        := substr(p_header.cust_phone_number,3);
    l_instructions             := substr(p_header.packing_instructions||chr(13)||p_header.shipping_instructions,1,1000);
    --
    --Purpose: popular tabela l_header_rec.
    l_header_rec                              := oe_order_pub.g_miss_header_rec;
    l_header_rec.flow_status_code             := 'BOOKED';
    l_header_rec.operation                    := oe_globals.g_opr_create;
    l_header_rec.orig_sys_document_ref        := p_header.source_hdr_id;
    l_header_rec.order_source_id              := p_order_source_id;
    l_header_rec.sold_to_org_id               := p_header_aux.sold_to_org_id;
    l_header_rec.ship_to_org_id               := p_header_aux.ship_to_org_id;
    l_header_rec.sold_from_org_id             := p_header_aux.sold_from_org_id;
    l_header_rec.ship_from_org_id             := p_header_aux.ship_from_org_id;
    l_header_rec.invoice_to_org_id            := p_header_aux.invoice_to_org_id;
    l_header_rec.deliver_to_org_id            := p_header_aux.deliver_to_org_id;
    l_header_rec.transactional_curr_code      := p_header.currence_code;
    l_header_rec.price_list_id                := p_header_aux.price_list_id;
    l_header_rec.cust_po_number               := coalesce(p_header.cust_po_number2,p_header.cust_po_number);
    l_header_rec.request_date                 := case
                                                    when trunc(p_header.request_date) < trunc(sysdate) then
                                                         trunc(sysdate)
                                                    else trunc(p_header.request_date)
                                                 end;
    l_header_rec.shipping_method_code         := nvl(l_shipping_method_code,p_header_aux.shipping_method_code);
    l_header_rec.salesrep_id                  := p_header_aux.salesrep_id;
    l_header_rec.order_type_id                := p_header_aux.order_type_id;
    l_header_rec.payment_term_id              := case
                                                   when p_header_aux.order_type_id in (3844,3426) then
                                                     1000
                                                   else
                                                     p_header_aux.payment_term_id
                                                 end;
    l_header_rec.sales_channel_code           := p_header_aux.sales_channel_code;
    l_header_rec.packing_instructions         := p_header.packing_instructions;
    l_header_rec.shipping_instructions        := p_header.shipping_instructions;
    l_header_rec.shipment_priority_code       := p_header_aux.shipment_priority_code;
    l_header_rec.customer_preference_set_code := p_header.customer_preference_set_code;
    --
    l_header_rec.context                      := p_header_aux.sales_channel_code;
    --
    l_header_rec.attribute1                   := p_header_aux.attribute1;
    l_header_rec.attribute2                   := p_header_aux.attribute2;
    l_header_rec.attribute3                   := p_header_aux.attribute3;
    l_header_rec.attribute4                   := p_header_aux.attribute4;
    l_header_rec.attribute5                   := p_header_aux.attribute5;
    l_header_rec.attribute6                   := p_header_aux.attribute6;
    l_header_rec.attribute7                   := p_header_aux.attribute7;
    l_header_rec.attribute8                   := p_header_aux.attribute8;
    l_header_rec.attribute9                   := p_header_aux.attribute9;
    l_header_rec.attribute10                  := p_header_aux.attribute10;
    l_header_rec.attribute11                  := p_header_aux.attribute11;
    l_header_rec.attribute12                  := p_header_aux.attribute12;
    l_header_rec.attribute13                  := p_header_aux.attribute13;
    l_header_rec.attribute14                  := p_header_aux.attribute14;
    l_header_rec.attribute15                  := p_header_aux.attribute15;
    l_header_rec.attribute16                  := p_header_aux.attribute16;
    l_header_rec.attribute18                  := p_header_aux.attribute18;
    l_header_rec.attribute19                  := p_header_aux.attribute19;
    l_header_rec.attribute20                  := p_header_aux.attribute20;
    
    


    
    
    --
    for i in p_items.first..p_items.last loop
      --
      l_inventory_item_id := NULL;
      --Seleciona o código do item
      open  c_item(p_items(i).inventory_item_code);
      fetch c_item
      into  l_inventory_item_id;
      close c_item;
      --
      l_loop_lines                                          := l_loop_lines + 1;
      --Purpose: popular tabela l_line_tbl.
      l_line_tbl_index                                      := l_loop_lines;
      l_line_tbl(l_line_tbl_index)                          := oe_order_pub.g_miss_line_rec;
      l_line_tbl(l_line_tbl_index).line_number              := to_number(p_items(i).line_number);
      l_line_tbl(l_line_tbl_index).operation                := oe_globals.g_opr_create;
      l_line_tbl(l_line_tbl_index).order_source_id          := p_order_source_id;
      l_line_tbl(l_line_tbl_index).sold_to_org_id           := p_header_aux.sold_to_org_id;
      l_line_tbl(l_line_tbl_index).ship_to_org_id           := p_header_aux.ship_to_org_id;
      l_line_tbl(l_line_tbl_index).sold_from_org_id         := p_header_aux.sold_from_org_id;
      l_line_tbl(l_line_tbl_index).deliver_to_org_id        := p_header_aux.deliver_to_org_id;
      l_line_tbl(l_line_tbl_index).orig_sys_document_ref    := p_items(i).line_number;
      l_line_tbl(l_line_tbl_index).inventory_item_id        := l_inventory_item_id;
      l_line_tbl(l_line_tbl_index).ordered_quantity         := round( p_items(i).ordered_quantity,3);
      l_line_tbl(l_line_tbl_index).price_list_id            := p_items_aux(i).price_list_id;
      l_line_tbl(l_line_tbl_index).ship_from_org_id         := p_items_aux(i).ship_from_org_id;
      l_line_tbl(l_line_tbl_index).request_date             := coalesce(
                                                               (case
                                                                 when trunc(p_items(i).request_date) < trunc(sysdate) then
                                                                      trunc(sysdate)
                                                                 else trunc(p_items(i).request_date)
                                                                end),l_header_rec.request_date);
      l_line_tbl(l_line_tbl_index).schedule_ship_date       := p_items(i).schedule_ship_date;
      l_line_tbl(l_line_tbl_index).promise_date             := p_items(i).promise_date;
      l_line_tbl(l_line_tbl_index).user_item_description    := p_items(i).assistance_number;
      l_line_tbl(l_line_tbl_index).context                  := 'Dados Adicionais';
      l_line_tbl(l_line_tbl_index).attribute3               := p_items(i).camada;
      l_line_tbl(l_line_tbl_index).attribute9               := p_items(i).familia;
      l_line_tbl(l_line_tbl_index).attribute7               := p_items(i).calibre;
      l_line_tbl(l_line_tbl_index).attribute5               := p_items(i).sku;
      l_line_tbl(l_line_tbl_index).attribute15              := p_items(i).grupo;
--      l_line_tbl(l_line_tbl_index).attribute17              := p_items(i).promise_date;
      l_line_tbl(l_line_tbl_index).cust_model_serial_number := substr( p_items(i).ambient_type,1,49);
      l_line_tbl(l_line_tbl_index).cust_po_number           := coalesce(p_header.cust_po_number2,p_header.cust_po_number);
      l_line_tbl(l_line_tbl_index).customer_production_line := p_header.cust_so_number;
--      l_line_tbl(l_line_tbl_index).line_type_id             := l_line_type_id;

      --
    end loop;
    --
    l_iface_lines := p_items.count;
    --
    --Purpose: compara se quantidade de linhas do loop e igual da tabela de linhas da interface.
    if l_loop_lines = l_iface_lines then
      --
      --Purpose: executar API que cria pedido de venda no Oracle.
      oe_order_pub.process_order( p_api_version_number     => 1
                                 ,p_init_msg_list          => fnd_api.g_false
                                 ,p_return_values          => fnd_api.g_false
                                 ,p_action_commit          => fnd_api.g_false
                                 ,p_header_rec             => l_header_rec
                                 ,p_line_tbl               => l_line_tbl
                                 --out variables
                                 ,x_header_rec             => o_header_rec
                                 ,x_header_val_rec         => o_header_val_rec
                                 ,x_header_adj_tbl         => o_header_adj_tbl
                                 ,x_header_adj_val_tbl     => o_header_adj_val_tbl
                                 ,x_header_price_att_tbl   => o_header_price_att_tbl
                                 ,x_header_adj_att_tbl     => o_header_adj_att_tbl
                                 ,x_header_adj_assoc_tbl   => o_header_adj_assoc_tbl
                                 ,x_header_scredit_tbl     => o_header_scredit_tbl
                                 ,x_header_scredit_val_tbl => o_header_scredit_val_tbl
                                 ,x_line_tbl               => o_line_tbl
                                 ,x_line_val_tbl           => o_line_val_tbl
                                 ,x_line_adj_tbl           => o_line_adj_tbl
                                 ,x_line_adj_val_tbl       => o_line_adj_val_tbl
                                 ,x_line_price_att_tbl     => o_line_price_att_tbl
                                 ,x_line_adj_att_tbl       => o_line_adj_att_tbl
                                 ,x_line_adj_assoc_tbl     => o_line_adj_assoc_tbl
                                 ,x_line_scredit_tbl       => o_line_scredit_tbl
                                 ,x_line_scredit_val_tbl   => o_line_scredit_val_tbl
                                 ,x_lot_serial_tbl         => o_lot_serial_tbl
                                 ,x_lot_serial_val_tbl     => o_lot_serial_val_tbl
                                 ,x_action_request_tbl     => o_action_request_tbl
                                 ,x_return_status          => o_return_status
                                 ,x_msg_count              => o_msg_count
                                 ,x_msg_data               => o_msg_date);
      --
      --Purpose: verificar se pedido de venda foi criado corretamente.
      if o_return_status = fnd_api.g_ret_sts_success then
        --
        x_om_header_id := o_header_rec.header_id;
        --
        --Purpose: atualiza flexfield do tipo special.
        --

        if x_om_header_id is not null then
          --
          update oe_order_headers_all
          set    attribute17 = p_header_aux.attribute17 -- l_hdr_attribute17
          where  1=1
          and    header_id   = x_om_header_id;
          --
        end if;
        --
        if x_om_header_id is not null then
          --
          begin
            --
            insert into ont.ont_info_entrega_pedido_pb(header_id
                                                      ,fl_restricao
                                                      ,obs_restricao
                                                      ,ds_contato
                                                      ,cd_area_contato
                                                      ,nr_telefone_contato
                                                      ,creation_date
                                                      ,created_by
                                                      ,last_update_date
                                                      ,last_updated_by
                                                      ,last_update_login
                                                      ,id_local_entrega
                                                      ,hr_entrega_inicio
                                                      ,hr_entrega_final
                                                      ,id_acessa_caminhao
                                                      ,ds_ponto_referencia
                                                      ,qt_dia_entrega_cliente
                                                      ,ds_armazenar
                                                      ,ds_dificuldade
                                                      ,ds_comentario
                                                      ,ds_email
                                                      ,cd_area_contato2
                                                      ,nr_telefone_contato2
                                                      ,mvix_sales_approval_date
                                                      )
                                               values (x_om_header_id
                                                      ,null                        --fl_restricao
                                                      ,null                        --obs_restricao
                                                      ,nvl(nvl(l_ds_contato, l_cust_name),0)
                                                      ,nvl(nvl(l_cd_area_contato, l_cust_area_code),0)
                                                      ,nvl(nvl(l_nr_telefone_contato, regexp_replace(l_cust_phone_number,'[^0-9]','')),0)
                                                      ,sysdate                      --creation_date
                                                      ,fnd_profile.value('USER_ID') --created_by
                                                      ,sysdate                      --last_update_date
                                                      ,fnd_profile.value('USER_ID') --last_updated_by
                                                      ,fnd_profile.value('USER_ID') --last_update_login
                                                      ,l_id_local_entrega
                                                      ,l_hr_entrega_inicio
                                                      ,l_hr_entrega_final
                                                      ,l_id_acessa_caminhao
                                                      ,l_ds_ponto_referencia
                                                      ,l_qt_dia_entrega_cliente
                                                      ,l_ds_armazenar
                                                      ,l_ds_dificuldade
                                                      ,nvl(l_ds_comentario, substr(l_instructions,1,499))
                                                      ,l_ds_email
                                                      ,l_cd_area_contato2
                                                      ,l_nr_telefone_contato2
                                                      ,l_mvix_sales_approval_date);
            --
            commit;
            --
          end;
          --
        end if;
        --
        x_om_order_num := o_header_rec.order_number;
        x_sts_code     := c_status_sucesso;
        --
        --Objetivo: Registrar ordem de venda no Oracle.
        book_order (p_source_hdr_id    => p_header.source_hdr_id
                   ,p_om_header_id     => x_om_header_id
                   ,o_sts_code         => x_sts_code
                   );
        --
        -- Definir automaticamente número de container para OVs PBA da F
        if p_header.order_source = 'PBA' and 
           p_header.sold_to_fiscal_id = '814393637' and 
           x_om_header_id is not null then
          --
          update oe_order_lines_all
             set attribute11 = x_om_order_num||'01'
           where 1=1
             and header_id   = x_om_header_id;
          commit;
        end if;
        -- 
/*       
        for i in p_items.first..p_items.last loop

          update oe_order_lines_all
             set attribute17 =  p_items(i).promise_date--l_line_tbl(l_line_tbl_index).attribute17 
           where 1=1
             and header_id   = x_om_header_id
             and line_number =  p_items(i).line_number;
          commit;
       end loop;*/

      else
        --
        rollback;
        --
        x_sts_code := c_status_erro;
        --
        for i in 1 .. o_msg_count loop
          --
           --Purpose: retorno para registro do erro na tabela de log.
           oe_msg_pub.get(i, fnd_api.g_false, o_msg_date, o_msg_index_out);
           insert_log(p_header.source_hdr_id,null, 'Erro: 1 - Erro ao criar ordem de venda no Oracle: '||trim(o_msg_date), 2);
           --
           --Purpose: retorno para registro do erro no output e envio para tabela de log.
           insert_log(p_header.source_hdr_id,null, 'Erro: 2 - Pedido nao foi criado no Oracle: '||trim(o_msg_date), 2);
           --
        end loop;
        --
      end if;
      --
      commit;
      --
    else
      --
      rollback;
      --
      x_sts_code := c_status_erro;
      --
      insert_log(p_header.source_hdr_id,null, 'Erro: 3 - Erro na validacao de quantidade de linhas. Quantidades processadas diferente da quantidade de linhas na interface.', 2);
      --
    end if;
    --
  end ont_create_order;
  --
  --***************************************************************
  --Objetivo: Procedimento para validacao de regra comerciais
  --***************************************************************
  procedure processa_regras_comerciais (p_header         in order_header_r,
                                        p_items          in order_line_t,
                                        p_header_aux in out order_header_aux_r,
                                        p_items_aux      in order_line_aux_t,
                                        o_sts_code      out number
                                       ) is
    --
    -- Cursor especifico para validar cliente
    cursor c_regra_cliente(p_sold_to_org_id in number) is
      select 1
      from   apps.hz_cust_acct_sites_all hcasa
      where  1=1
      and    hcasa.cust_account_id = p_sold_to_org_id;
      --
    --Seleciona a unidade de medida
    cursor c_primary_uom(p_organization_id     number,
                         p_inventory_item_code varchar2) is
      select msi.primary_uom_code,
             msi.inventory_item_id
      from  mtl_system_items_b msi
      where 1=1
      and   msi.segment1        = p_inventory_item_code
      and   msi.organization_id = p_organization_id;
    --
    l_primary_uom_code  mtl_system_items_b.primary_uom_code%type;
    l_id_regra_cliente  number;
    l_inventory_item_id number;
    w_out_validacao     boolean;
    w_out_regras        long;
    --
  begin
    --
    
    p_header_aux.attribute4  := qp_002_apo(p_header_aux.ship_to_org_id, p_header_aux.sold_to_org_id, p_header_aux.order_type_id, 'Online', 'D');--desconto_icms
    p_header_aux.attribute5  := p_header.term_discount;--Desconto de Prazo
    p_header_aux.attribute6  := '0.00';
    p_header_aux.attribute7  := p_header.discount_1;--desconto_extra1
    p_header_aux.attribute8  := p_header.discount_2;--desconto_extra2
    p_header_aux.attribute9  := p_header.discount_3;--desconto_extra3
    p_header_aux.attribute18 := p_header.invoice_instructions; --Observações NF
    p_header_aux.attribute16 := NULL ;--Ação Marketing
    p_header_aux.attribute17 := NULL ;--Conta p/ Amostras

    --
    --
    IF p_header_aux.sales_channel_code = '2' or p_header_aux.sales_channel_code = '102' THEN     -- REVENDA
      --
      p_header_aux.attribute10 := '0.00';
      p_header_aux.attribute11 := '0.00';
      --
    END IF;
    --
    IF p_header_aux.sales_channel_code = '1' or  p_header_aux.sales_channel_code = '101'  or  p_header_aux.sales_channel_code = '23'  or  p_header_aux.sales_channel_code = '25'  THEN     -- ENGENHARIA
      --
      
      if NVL(p_header.specifier_name,' ') <> ' ' then 
        p_header_aux.attribute1  := p_header.specifier_name; --Nome do Arquiteto
      else
        p_header_aux.attribute1  := 'ARQUITETO NÃO DEFINIDO'; --Nome do Arquiteto
      end if;
      
      p_header_aux.attribute2  := '0'; --Valor da Comissão
      p_header_aux.attribute3  := 'Percentual'; --Tipo de Comissão
      p_header_aux.attribute10 := '0';--Qualificador da Engenharia
      p_header_aux.attribute11 := NULL ; --Loja PB-Shop

      if NVL(p_header.type_construction, ' ') <> ' ' then 
        p_header_aux.attribute12 := p_header.type_construction; -- Tipo de Obra
      else
        p_header_aux.attribute12 := 'NOVA'; -- Tipo de Obra
      end if;
      p_header_aux.attribute13 := NULL ;--Valor Total VP
      p_header_aux.attribute14 := NULL ;--% Mínimo p/Fat
      p_header_aux.attribute15 := NULL ;--Valor Saldo VP
      p_header_aux.attribute19 := '236';--TOP Construtora
      
      IF NVL(p_header.nacional_account, ' ') <> ' ' then 
        p_header_aux.attribute20 := p_header.nacional_account;--Conta Nacional 1
      else
        p_header_aux.attribute20 := '236';--Conta Nacional 1
      end if;
      --
    END IF;
    --
  end processa_regras_comerciais;
  --
  -- Procedure para validar fechamento de caixa
  procedure valida_fecha_caixa(p_inventory_item_code in varchar2
                              ,p_quantidade          in number
                              ,p_uom                 in varchar2
                              ,p_return             out varchar2
                              ) is
    --
    w_return varchar2(240);
    --
    cursor c1 is
      select inventory_item_id
      from   mtl_system_items_b
      where  1=1
      and    segment1        = p_inventory_item_code
      and    organization_id = pb_master_organization_id;
      --
    r1 c1%rowtype;
    --
  begin
    --
    open c1;
    fetch c1 into r1;
    --
    if c1%found then
      --
      -- Chama rotina para validação
      p_return := omp004apo.lotes_multiplos (winventory_item_id  => r1.inventory_item_id --in  number
                                            ,wquantidade         => p_quantidade         --in  varchar2
                                            ,worder_quantity_uom => p_uom                --in  varchar2
                                            ,wsales_channel_code => null                 --in  number
                                            ,permissao           => '1'                  --in  varchar2 --fixo para tratar como caixa e não sub-embalagem.
                                            ,wheader_id          => null                 --in  number
                                            ,wtipo_ordem         => null                 --in  varchar2
                                            );
      --
      /*if p_return <> 'OK' then
        --
        -- Caso a primeira tentativa falhe, tentar validar com caixa baixa para o campo unidade de medida
        w_return := omp004apo.lotes_multiplos(winventory_item_id  => r1.inventory_item_id --in  number
                                             ,wquantidade         => p_quantidade         --in  varchar2
                                             ,worder_quantity_uom => lower(p_uom)         --in  varchar2
                                             ,wsales_channel_code => null                 --in  number
                                             ,permissao           => '1'                  --in  varchar2 --fixo para tratar como caixa e não sub-embalagem.
                                             ,wheader_id          => null                 --in  number
                                             ,wtipo_ordem         => null                 --in  varchar2
                                             );
        --
        if w_return <> 'OK' then
          --
          -- Caso a primeira tentativa falhe, tentar validar com caixa alta para o campo unidade de medida
          w_return := omp004apo.lotes_multiplos(winventory_item_id  => r1.inventory_item_id --in  number
                                               ,wquantidade         => p_quantidade         --in  varchar2
                                               ,worder_quantity_uom => upper(p_uom)         --in  varchar2
                                               ,wsales_channel_code => null                 --in  number
                                               ,permissao           => '1'                  --in  varchar2 --fixo para tratar como caixa e não sub-embalagem.
                                               ,wheader_id          => null                 --in  number
                                               ,wtipo_ordem         => null                 --in  varchar2
                                               );
          --
        end if;
        --
        p_return := w_return;
        --
      end if;
      */--
    else -- if c1 notfound
      --
      p_return := 'Erro ao selecionar ID do item: '||p_inventory_item_code||'. Dados não encontrado!';
      --
    end if; -- if c1
    --
    close c1;
    --
  end valida_fecha_caixa;
  --
  -- Procedure para ajuste de unidade de medida cliente X PBG, DEPARA
  procedure ajusta_uom_depara(p_order_source in varchar2
                             ,p_from_uom     in varchar2
                             ,p_to_uom      out varchar2
                             ) is
    --
    -- Cursor para selecionar parametrização de depara por origem
    cursor c1 is
      select to_uom
      from   xxpb_order_config_api_uom
      where  1=1
      and    upper(order_source) = p_order_source
      and    from_uom     = p_from_uom;
      --
    r1 c1%rowtype;
    --
  begin
    --
    open c1;
    fetch c1 into r1;
    --
    if c1%found then
      --
      p_to_uom := r1.to_uom;
      --
    else
      --
      p_to_uom := p_from_uom;
      --
    end if;
    --
    close c1;
    --
  end ajusta_uom_depara;
  --
  --********************************************************************************
  --Objetivo: Procedimento para validacao de dados de linha informacoes obrigatorias
  --********************************************************************************
  -- Procedimento para validacao de linha
  procedure validate_lines(p_header       in     order_header_r,
                           p_header_aux   in     order_header_aux_r,
                           p_items        in out order_line_t,
                           p_items_aux    in out order_line_aux_t,
                           x_sts_code        out varchar2
                          ) is
    --
    l_return_caixa varchar2(2000);
    --l_converte     varchar2(1);
    --
  begin
    --
    --Purpose: Veriricar quantidade de linhas

    if p_items.count = 0 then
      --
      x_sts_code := c_status_erro;
      --
      --purpose: retorno para registro do erro no output
      insert_log(p_header.source_hdr_id, null, 'Erro: 1 - Rotina de validacao de linhas - Nao existe(m) linha(s) para esse pedido.', 2);
      --
    else
      --
      x_sts_code := c_status_sucesso;
      --
      for i in p_items.first..p_items.last loop
        --insert_log(p_header.source_hdr_id, null, 'Tipo de ordem da linha '||i||': '||p_items(i).

        --
        l_return_caixa := null;
        --
        --purpose: veriricar campo inventory_item_id
        if p_items(i).inventory_item_code is null then
          --
          x_sts_code := c_status_erro;
          --
          --purpose: retorno para registro do erro no output
          insert_log(p_header.source_hdr_id, null, 'Erro: 3 - Rotina de validacao de linhas - linha'||i||' sem código de item informado.', 2);
          --
        end if;
        --
        --l_converte := null;
        --
        -- Procedure para ajuste de unidade de medida cliente X PBG, DEPARA
        ajusta_uom_depara(p_order_source => p_header.order_source
                         ,p_from_uom     => p_items(i).unit_of_measure
                         ,p_to_uom       => p_items(i).unit_of_measure
                         );
        --
        -- Procedure para validar unidade de medida do item, converter em caso necessário, para a UOM principal do item
        valida_uom_item(p_header              => p_header
                       ,p_inventory_item_code => p_items(i).inventory_item_code -- in
                       ,p_in_qtde_item        => p_items(i).ordered_quantity    -- in
                       ,p_in_uom              => p_items(i).unit_of_measure     -- in
                       ,p_in_preco            => p_items(i).unit_price          -- in
                       ,p_out_qtde_item       => p_items(i).ordered_quantity    -- out
                       ,p_out_uom             => p_items(i).unit_of_measure     -- out
                       ,p_out_preco           => p_items(i).unit_price          -- out
--                       ,p_converte            => l_converte
                       );
        --
        -- Procedure para validar fechamento de caixa
        valida_fecha_caixa(p_inventory_item_code => p_items(i).inventory_item_code
                          ,p_quantidade          => p_items(i).ordered_quantity
                          ,p_uom                 => p_items(i).unit_of_measure
                          ,p_return              => l_return_caixa
                          );
        --
        
        limpa_var_integracao_linha();
        
        IF valida_item(p_items(i).inventory_item_code, pb_master_organization_id, p_items(i).sku) <> RETORNO_VALIDO THEN
            x_sts_code := c_status_erro;
            insert_log(p_header.source_hdr_id, p_items(i).line_number, 'Erro: 2 - Rotina de validacao de linhas -  '||i||', item: '||p_items(i).inventory_item_code||'. '||MSG_ERRO, 2);
        END IF;
        
        IF valida_item_deposito_line(p_items(i).inventory_item_code, p_header.ship_from_org_id) <> RETORNO_VALIDO THEN
            x_sts_code := c_status_erro;
            insert_log(p_header.source_hdr_id, p_items(i).line_number, 'Erro: 2 - Rotina de validacao de linhas -  '||i||', item: '||p_items(i).inventory_item_code||'. '||MSG_ERRO, 2);
        END IF;

        IF valida_componibilidade(p_items(i).sku, vg_inventory_item_id, p_items(i).ordered_quantity, p_items(i).ship_from_org_code) <> RETORNO_VALIDO THEN
            x_sts_code := c_status_erro;
            insert_log(p_header.source_hdr_id, p_items(i).line_number, 'Erro: 2 - Rotina de validacao de linhas - '||i||', item: '||p_items(i).inventory_item_code||'. '||MSG_ERRO, 2);
        END IF;

        IF valida_item_de_in (vg_inventory_item_id, p_items(i).ordered_quantity, p_items(i).ship_from_org_code, vg_fase_vida) <> RETORNO_VALIDO THEN
            x_sts_code := c_status_erro;
            insert_log(p_header.source_hdr_id, p_items(i).line_number, 'Erro: 2 - Rotina de validacao de linhas - '||i||', item: '||p_items(i).inventory_item_code||'. '||MSG_ERRO, 2);
        END IF;

        IF (UPPER(vg_item_classificacao) = ITEM_CLASSIFICACAO_COMERCIAL) THEN
          IF valida_item_comercial(p_items(i).sku, vg_inventory_item_id, p_items(i).ordered_quantity, p_items(i).ship_from_org_code) <> RETORNO_VALIDO THEN
            x_sts_code := c_status_erro;
            insert_log(p_header.source_hdr_id, p_items(i).line_number, 'Erro: 2 - Rotina de validacao de linhas - '||i||', item: '||p_items(i).inventory_item_code||'. '||MSG_ERRO, 2);
          END IF;
        END IF;

            IF vg_fase_vida = 'SU' then
              fnd_file.put_line(fnd_file.log, '-------------------');
              fnd_file.put_line(fnd_file.log, 'Validação de Estoque de itens - Fase de vida SU');
              IF valida_item_comercial_estoque (p_items(i).camada, vg_inventory_item_id, p_items(i).ordered_quantity, p_items(i).ship_from_org_code, p_items(i).sku, p_header.ship_from_org_id, 2) <> RETORNO_VALIDO THEN
                x_sts_code := c_status_erro;
                insert_log(p_header.source_hdr_id, p_items(i).line_number, 'Erro: 2 - Rotina de validacao de linhas - '||i||', item: '||p_items(i).inventory_item_code||'. '||MSG_ERRO, 2);
              END IF;
            end if;
            


            IF (UPPER(vg_item_classificacao) = ITEM_CLASSIFICACAO_COMERCIAL) THEN
              IF valida_item_comercial_estoque (p_items(i).camada, vg_inventory_item_id, p_items(i).ordered_quantity, p_items(i).ship_from_org_code, p_items(i).sku, p_header.ship_from_org_id, 1) <> RETORNO_VALIDO THEN
                x_sts_code := c_status_erro;
                insert_log(p_header.source_hdr_id, p_items(i).line_number, 'Erro: 2 - Rotina de validacao de linhas - '||i||', item: '||p_items(i).inventory_item_code||'. '||MSG_ERRO, 2);
              END IF;
            END IF;
            
 


        
        if l_return_caixa <> 'OK' then
          --
          x_sts_code := c_status_erro;
          --
          insert_log(p_header.source_hdr_id, p_items(i).line_number, 'Erro: 2 - Rotina de validacao de linhas -  Erro no fechamento de caixa para linha '||i||', item: '||p_items(i).inventory_item_code||'. '||l_return_caixa, 2);
          --
        end if;
        --
      end loop;
      --
      for i in p_items_aux.first..p_items_aux.last loop
        --
        --purpose: veriricar campo l_ship_from_org_id
        if p_items_aux(i).ship_from_org_id is null then
          --
          if p_header_aux.ship_from_org_id is null then
            --
            x_sts_code := c_status_erro;
            --purpose: retorno para registro do erro no output
            insert_log(p_header.source_hdr_id, null, 'Erro: 4 - Rotina de validacao de linhas - linha '||i||', item '||p_items(i).inventory_item_code||' sem ID de deposito informado.', 2);
            --
          end if;
          --
          p_items_aux(i).ship_from_org_id := p_header_aux.ship_from_org_id;
          --
        end if;
        --
        --purpose: veriricar campo price_list_id
        /*if p_items_aux(i).price_list_id is null then
          --
          x_sts_code := c_status_erro;
          --purpose: retorno para registro do erro no output
          insert_log(p_header.source_hdr_id, null, 'Erro: 5 - Rotina de validacao de linhas - linha '||i||', item '||p_items(i).inventory_item_code||' sem ID de lista de preço informado.', 2);
          --
        end if;*/
        --
      end loop;
      --
    end if;
    --
  end validate_lines;
  --
  --******************************************************
  --Objetivo: Procedimento para busca de filial faturadora
  --******************************************************
  -- Procedimento para busca de filial faturadora
   procedure validate_filial_faturadora(p_header     in out order_header_r,
                                        p_header_aux in out order_header_aux_r,
                                        p_items      in     order_line_t,
                                        o_sts_code      out varchar2
                                       ) is
  --
  l_ship_to_org_id number := null;
  w_error exception;
  --
  begin
    --
    -- Valida APP de integracao
    if p_header.order_source in ('POP_SALESFORCE','IVOP') then
      --
      begin
        select hcsu.site_use_id
        into   l_ship_to_org_id
        from   hz_cust_accounts        hca
        ,      hz_party_sites          hps
        ,      hz_locations            hl
        ,      hz_cust_acct_sites_all  hcas
        ,      hz_cust_site_uses_all   hcsu
        where  1=1
        and    hca.party_id            = hps.party_id
        and    hps.location_id         = hl.location_id
        and    hps.party_site_id       = hcas.party_site_id
        and    hcas.cust_acct_site_id  = hcsu.cust_acct_site_id
        and    hcsu.site_use_code      = 'SHIP_TO'
        and    hcas.org_id             = fnd_profile.value('ORG_ID')
        and    hcsu.org_id             = fnd_profile.value('ORG_ID')
        and    hcsu.status             = 'A'
        and    hca.cust_account_id     = p_header_aux.sold_to_org_id
        and    hcsu.site_use_id        = p_header_aux.ship_to_org_id
        and    substr(hcsu.location,1,instr(hcsu.location,'-')-1)
                                       = (select flv.attribute1
                                          from   oe_transaction_types_all ott
                                          ,      fnd_lookup_values flv
                                          where  1=1
                                          and    ott.transaction_type_id = p_header_aux.order_type_id
                                          and    flv.lookup_code         = ott.ship_source_type_code
                                          and    flv.lookup_type         = 'SOURCE_TYPE'
                                          and    flv.language            = 'PTB')
        and    hl.address1             = (select hl.address1
                                          from   hz_cust_accounts        hca
                                          ,      hz_party_sites          hps
                                          ,      hz_locations            hl
                                          ,      hz_cust_acct_sites_all  hcas
                                          ,      hz_cust_site_uses_all   hcsu
                                          where  1=1
                                          and    hca.party_id            = hps.party_id
                                          and    hps.location_id         = hl.location_id
                                          and    hps.party_site_id       = hcas.party_site_id
                                          and    hcas.cust_acct_site_id  = hcsu.cust_acct_site_id
                                          and    hcsu.site_use_code      = 'SHIP_TO'
                                          and    hcas.org_id             = fnd_profile.value('ORG_ID')
                                          and    hcsu.org_id             = fnd_profile.value('ORG_ID')
                                          and    hcsu.status             = 'A'
                                          and    hca.cust_account_id     = p_header_aux.sold_to_org_id
                                          and    hcsu.site_use_id        = p_header_aux.ship_to_org_id
                                         );
      exception
        when no_data_found then
          l_ship_to_org_id := null;
          o_sts_code       := c_status_erro;
          insert_log(p_header.source_hdr_id, null, 'Erro: 1 - Validacao do endereco de filial faturadora. Nao foi encontrada filial.', 2);
        when too_many_rows then
          l_ship_to_org_id := null;
          o_sts_code := c_status_erro;
          insert_log(p_header.source_hdr_id, null, 'Erro: 2 - Validacao do endereco de filial faturadora. Foram encontrados diversas filiais faturadoras.', 2);
        when others then
          l_ship_to_org_id := null;
          o_sts_code := c_status_erro;
          insert_log(p_header.source_hdr_id, null, 'Erro: 3 - Validacao do endereco de filial faturadora. Erro: '||sqlerrm||dbms_utility.format_error_backtrace, 2);
      end;
      --
      if l_ship_to_org_id is not null then
        --
        p_header_aux.ship_to_org_id := l_ship_to_org_id;
        --
      end if;
      --
    end if; -- if p_header.order_source = 'MICROVIX' then
    --
    if p_header.sold_from_fiscal_id is not null then
      --
      begin
        select uf filial_faturadora
        into   p_header_aux.estado_filial_fat
        from   ar_info_filial_pb
        where  1=1
        and    cnpjemit = p_header.sold_from_fiscal_id;
      exception
        when no_data_found then
          l_ship_to_org_id := null;
          o_sts_code       := c_status_erro;
          insert_log(p_header.source_hdr_id, null, 'Erro: 4 - Estado da filial faturadora não encontrado para o SOLD_FROM_FISCAL_ID '||
                                                   p_header.sold_from_fiscal_id||'.', 2);
        when too_many_rows then
          l_ship_to_org_id := null;
          o_sts_code := c_status_erro;
          insert_log(p_header.source_hdr_id, null, 'Erro: 5 - Mais de um estado encontrado para a filial faturadora.', 2);
        when others then
          l_ship_to_org_id := null;
          o_sts_code := c_status_erro;
          insert_log(p_header.source_hdr_id, null, 'Erro: 6 - Erro ao selecionar o estado da filial faturadora. Erro: '||sqlerrm||dbms_utility.format_error_backtrace, 2);
      end;
      --
    else -- if p_header.sold_from_fiscal_id is null then
      --
      for i in p_items.first..p_items.last loop
        --
        begin
          if p_items(i).inventory_item_code is null then 
            raise w_error;
          end if;
          --
          select decode(mc.segment1,'002','AL','SC')
          into   p_header_aux.estado_filial_fat
          from   apps.mtl_category_sets     mcs     
                ,apps.mtl_item_categories_v mic
                ,apps.mtl_categories_v      mc
                ,apps.mtl_system_items_b    msi
          where  1=1
          and    mic.inventory_item_id = msi.inventory_item_id
          and    mic.organization_id   = msi.organization_id
          and    mic.category_set_id   = mcs.category_set_id
          and    mc.category_id        = mic.category_id
          and    mic.organization_id   = apps.pb_master_organization_id
          and    mcs.category_set_name = 'Origem do Item'
          --and    mc.segment1           = '002'
          and    msi.segment1          = p_items(i).inventory_item_code;
        exception
          when w_error then
            insert_log(p_source_hdr_id => p_header.source_hdr_id,
                       p_source_lin_id => i,
                       p_message       => 'Erro: Código do produto não informado para a linha '||i||' do pedido .',
                       p_log_type      => 2);
            l_ship_to_org_id := null;
            o_sts_code := c_status_erro;
          when too_many_rows then
            l_ship_to_org_id := null;
            o_sts_code := c_status_erro;
            insert_log(p_header.source_hdr_id, null, 'Erro: 7 - Mais de uma origem encontrada para o item: '||p_items(i).inventory_item_code, 2);
          when others then
            l_ship_to_org_id := null;
            o_sts_code := c_status_erro;
            insert_log(p_header.source_hdr_id, null, 'Erro: 8 - Erro ao selecionar origem do item: '||p_items(i).inventory_item_code||'. '||
                                                     'Erro: '||sqlerrm||dbms_utility.format_error_backtrace, 2);
        end;
        --
      end loop;
      --
      if p_header_aux.estado_filial_fat is null then
        --
        p_header_aux.estado_filial_fat := 'SC';
        --
      end if;

      if p_header_aux.estado_filial_fat = 'AL' then
         p_header.sold_from_fiscal_id := '83475913004006';
      else
         p_header.sold_from_fiscal_id := '83475913000272';
      end if;
      --
    end if;
    --
  end validate_filial_faturadora;
  --
  --*********************************************************************************************
  --Objetivo: Busca por endereço de distribuição, caso negativo, cadastra e atribuido ao registro
  --*********************************************************************************************
  -- Procedimento para busca de endereco de distribuicao
  procedure valida_end_distribuicao(p_header     in out order_header_r,
                                    p_header_aux in out order_header_aux_r,
                                    o_sts_code   in out number
                                   ) is
    --
    -- Seleciona se cliente/recurso tem login de acesso via internet
    cursor c_loja (p_account_number varchar2) is
      select 'S'
      from   hz_parties             hzp,
             hz_cust_accounts_all   hca,
             jtf_rs_defresources_vl jrd
      where 1=1
      and   hzp.party_id        = hca.party_id
      and   jrd.attribute3      = to_char(hca.cust_account_id)
      and   jrd.attribute2     is not null
      and   hca.account_number  = p_account_number;
    --
    --Seleciona o codigo do cliente de venda - Loja
    cursor c_cliente (p_sold_to_org_id number) is
      select hca.account_number
      from   hz_cust_accounts hca
      where  1=1
      and    hca.cust_account_id = p_sold_to_org_id;
    --
    --Valida se cliente esta cadastrado
    cursor c_existe_cliente (p_account_number in varchar2)is
      select hca.cust_account_id,
             hca.party_id
      from   hz_cust_accounts hca
      where  1=1
      and    hca.account_number = p_account_number;
    --
    --Busca ID do perfil
    cursor c_profile is
      select profile_class_id
      from   hz_cust_profile_classes
      where  1=1
      and    name = 'Clientes MI';
    --
    --Valida se o Endereço Existe para o cliente
    cursor c_existe_endereco(p_cust_account_id number,
                             p_postal_code     varchar2,
                             p_address3        varchar2
                            ) is
      select hcsua.site_use_id
      from hz_cust_acct_sites_all hcasa,
           hz_cust_site_uses_all hcsua,
           hz_party_sites         hps,
           hz_locations           hl
      where hps.party_site_id               = hcasa.party_site_id
      and   hl.location_id                  = hps.location_id
      and   hcasa.cust_account_id           = p_cust_account_id
      and   hcsua.site_use_code             = 'DELIVER_TO'
      and   hcsua.cust_acct_site_id         = hcasa.cust_acct_site_id
      and   hcasa.status                    = 'A'
      and   nvl(hl.postal_code,'00000-000') = nvl(p_postal_code,'00000-000')
      and   hcasa.org_id                    =  fnd_profile.value('ORG_ID')
      and   nvl( regexp_replace(hl.address3,'[^0-9]+'),'######') = nvl(regexp_replace(p_address3,'[^0-9]+'),'######');
    --
    l_loja              varchar2(1);
    l_account_number    varchar2(20);
    l_raiz_cnpj_cpf     varchar2(20);
    l_filial_cnpj       varchar2(10);
    l_digito_cpf_cnpj   varchar2(10);
    l_cust_account_id   number;
    l_profile_class_id  number;
    l_party_id          number;
    l_party_number      varchar2(50);
    l_profile_id        number;
    l_ds_erro           varchar2(4000);
    w_erro              exception;
    l_id_cpf_cnpj       varchar2(50);
    l_cust_acct_site_id number;
    l_party_site_id     number;
    l_location_id       number;
    l_site_use_id       number;
    l_msg_text          varchar2(4000);
    --
  begin
    --
    --Valida necessidade de cadastramento ou se endereco informado e valido
    if  p_header.cust_name is null and p_header.cust_reg_number is null and p_header_aux.deliver_to_org_id is null then
      --
      o_sts_code := c_status_erro;
      insert_log( p_header.source_hdr_id, null, 'Erro: 1 - Endereco de distribuicao obrigatorio. Informacoes para cadastramento ou endereço valido nao informados!', 2);
      --
    --Valida necessidade de cadastrar endereco de distribuicao
    elsif  p_header.cust_name is not null and  p_header.cust_reg_number is not null and  p_header_aux.deliver_to_org_id is null then
      --
      --Objetivo: valida se todos os campos obrigatorios estao preenchidos
      if (  p_header.cust_ind_type         is null
        or  p_header.cust_reg_number       is null
        or  p_header_aux.cust_contrib_type is null
        or  p_header.cust_zip_code         is null
        or  p_header.cust_address1         is null
        or  p_header.cust_address2         is null
        or  p_header.cust_city             is null
        or  p_header.cust_state            is null
        or  p_header.cust_country          is null) then
        --
        o_sts_code := c_status_erro;
        l_msg_text := 'Erro: 2 - Para o endereco de distribuicao os campos são obrigatorios. Verifique o(s) campo(s): ';
        --
        if (  p_header.cust_ind_type is null) then
          --
          l_msg_text := l_msg_text||'CNJP/CPF - Tipo de Clinete (CUST_IND_TYPE) ';
          --
        end if; -- if (  p_header.cust_ind_type is null) then
        --
        if ( p_header.cust_reg_number is null) then
          --
          l_msg_text := l_msg_text||'Código do Cliente (CUST_REG_NUMBER) ';
          --
        end if; -- if ( p_header.cust_reg_number is null) then
        --
        if ( p_header_aux.cust_contrib_type is null) then
          --
          l_msg_text := l_msg_text||'Tipo de Contribuinte (CUST_CONTRIB_TYPE) ';
          --
        end if; -- if ( p_header.cust_contrib_type is null) then
        --
        if ( p_header.cust_zip_code is null) then
          --
          l_msg_text := l_msg_text||'CEP (CUST_ZIP_CODE) ';
          --
        end if; -- if ( p_header.cust_zip_code is null) then
        --
        if ( p_header.cust_address1 is null) then
          --
          l_msg_text := l_msg_text||'Logradouro (CUST_ADDRESS1) ';
          --
        end if; -- if ( p_header.cust_address1 is null) then
        --
        if ( p_header.cust_address2 is null) then
          --
          l_msg_text := l_msg_text||'Nr. End. (CUST_ADDRESS2) ';
          --
        end if; -- if ( p_header.cust_address2 is null) then
        --
        if ( p_header.cust_city is null) then
          --
          l_msg_text := l_msg_text||'Cidade (CUST_CITY) ';
          --
        end if; -- if ( p_header.cust_city is null) then
        --
        if ( p_header.cust_state is null) then
          --
          l_msg_text := l_msg_text||'Estado (CUST_STATE) ';
          --
        end if; -- if ( p_header.cust_state is null) then
        --
        if ( p_header.cust_country is null) then
          --
          l_msg_text := l_msg_text||'País (CUST_COUNTRY) ';
          --
        end if; -- if ( p_header.cust_country is null) then
        --
        -- Insere log
        insert_log(p_header.source_hdr_id, null, l_msg_text, 2);
        --
      else -- Objetivo: valida se todos os campos obrigatorios estao preenchidos
        --
        --Define o código do cliente de destino
        if p_header.cust_ind_type = 1 then
          --
          l_account_number  := substr(p_header.cust_reg_number, 1, 10);
          l_raiz_cnpj_cpf   := substr(p_header.cust_reg_number, 1, 10);
          l_digito_cpf_cnpj := substr(p_header.cust_reg_number, 11, 2);
          l_id_cpf_cnpj     := 'CPF';
          --
        else
          --
          l_account_number  := '0'||substr(p_header.cust_reg_number, 1, 8);
          l_raiz_cnpj_cpf   := substr(p_header.cust_reg_number, 1, 8);
          l_filial_cnpj     := substr(p_header.cust_reg_number, 9, 4);
          l_digito_cpf_cnpj := substr(p_header.cust_reg_number, 13, 2);
          l_id_cpf_cnpj     := 'CNPJ';
          --
        end if; -- if p_header.cust_ind_type = 1 then
        --
        l_loja := 'N';
        --
        --Verifica se o cliente é uma loja
        open  c_loja(l_account_number);
        fetch c_loja
        into  l_loja;
        close c_loja;
        --
        if nvl(l_loja,'N') = 'S' then
          --
          --Busca o código do cliente atraves de ID informado
          open  c_cliente (p_header_aux.sold_to_org_id);
          fetch c_cliente
          into  l_account_number;
          close c_cliente;
          --
        end if; -- if nvl(l_loja,'N') = 'S' then
        --
        l_cust_account_id := null;
        l_party_id        := null;
        --
        --Verifica cliente cadastrado
        open  c_existe_cliente(l_account_number);
        fetch c_existe_cliente
        into  l_cust_account_id,
              l_party_id;
        close c_existe_cliente;
        --
        --Busca ID perfil
        open  c_profile;
        fetch c_profile
        into  l_profile_class_id;
        close c_profile;
        --
        -- Cliente nao cadastrado
        if l_cust_account_id is null then
          --
          -- Cadastrar cliente
          ontk12013evt.prd_create_cliente(p_profile_class_id   => l_profile_class_id,
                                          p_account_number     => l_account_number,
                                          p_party_name         => p_header.cust_name,
                                          p_sales_channel_code => 4,
                                          p_sold_to_org_id     => p_header_aux.sold_to_org_id,
                                          p_id_cpf_cnpj        => l_id_cpf_cnpj,
                                          --out
                                          p_cust_account_id    => l_cust_account_id,
                                          p_party_id           => l_party_id,
                                          p_party_number       => l_party_number,
                                          p_profile_id         => l_profile_id,
                                          p_ds_erro            => l_ds_erro
                                         );
          --
          -- Erro cadastro cliente, apresentar msg de erro
          if l_ds_erro is not null then
            --
            raise w_erro;
            --
          end if; -- if l_ds_erro is not null then
          --
        end if; -- if l_cust_account_id is null then
        --
        l_site_use_id := null;
        --
        -- Valida endereco de entrega para o cliente
        open  c_existe_endereco(l_cust_account_id,
                                p_header.cust_zip_code,
                                p_header.cust_address3
                               );
        fetch c_existe_endereco
        into  l_site_use_id;
        close c_existe_endereco;
        --
        -- Endereco nao cadastrado
        if l_site_use_id is null then
          --
          -- Cadastrar endereco/local
          ontk12013evt.prd_create_local(p_dest_pais   => p_header.cust_country,
                                        p_dest_lgr    => p_header.cust_address1,
                                        p_dest_cpl    => p_header.cust_address2,
                                        p_dest_nro    => p_header.cust_address3,
                                        p_dest_bairro => p_header.cust_address4,
                                        p_dest_mun    => p_header.cust_city,
                                        p_dest_cep    => p_header.cust_zip_code,
                                        p_dest_uf     => p_header.cust_state,
                                        p_location_id => l_location_id,
                                        p_ds_erro     => l_ds_erro
                                       );
          --
          -- Erro cadastro endereco/local, apresentar msg de erro
          if l_ds_erro is not null then
            --
            raise w_erro;
            --
          end if; -- if l_ds_erro is not null then
          --
          -- Cria local na parte
          ontk12013evt.prd_create_party_site(p_location_id   => l_location_id,
                                             p_party_id      => l_party_id,
                                             p_party_site_id => l_party_site_id,
                                             p_ds_erro       => l_ds_erro
                                            );
          --
          -- Erro cadastro local na parte, apresentar msg de erro
          if l_ds_erro is not null then
            --
            raise w_erro;
            --
          end if; -- if l_ds_erro is not null then
          --
          -- Cadastrar CNPJ/CPF para o Cliente
          ontk12013evt.prd_create_endereco(p_cust_account_id         => l_cust_account_id,
                                           p_party_site_id           => l_party_site_id,
                                           p_global_attribute2       => p_header.cust_ind_type,
                                           p_global_attribute3       => l_raiz_cnpj_cpf,
                                           p_global_attribute4       => l_filial_cnpj,
                                           p_global_attribute5       => l_digito_cpf_cnpj,
                                           p_dest_ie                 => p_header.cust_state_inscription,
                                           p_cust_contrib_type       => p_header_aux.cust_contrib_type,
                                           p_orig_system_address_ref => null,
                                           p_cust_acct_site_id       => l_cust_acct_site_id,
                                           p_ds_erro                 => l_ds_erro
                                          );
          --
          -- Erro cadastro CNPJ/CPG para o cliente, apresentar msg de erro
          if l_ds_erro is not null then
            --
            raise w_erro;
            --
          end if; -- if l_ds_erro is not null then
          --
          --Cadastrar Uso de Endereco
          ontk12013evt.prd_create_uso_endereco(p_cust_acct_site_id   => l_cust_acct_site_id,
                                               p_code_combination_id => NULL,
                                               p_location            => l_location_id,
                                               p_site_use_code_tab   => 'DELIVER_TO',
                                               p_profile_class_id    => l_profile_class_id,
                                               p_site_use_id         => l_site_use_id,
                                               p_ds_erro             => l_ds_erro
                                              );
          --
          -- Erro cadastro uso de endereco, apresentar msg de erro
          if l_ds_erro is not null then
            --
            raise w_erro;
            --
          end if; -- if l_ds_erro is not null then
          --
        end if; -- if l_site_use_id is null then
        --
        p_header_aux.deliver_to_org_id := l_site_use_id;
        --
      end if; -- Objetivo: valida se todos os campos obrigatorios estao preenchidos
      --
    end if; -- if  p_header.cust_name is null and p_header.cust_reg_number is null and p_header.deliver_to_org_id is null then
    --
  exception
    when w_erro then
      o_sts_code := c_status_erro;
      insert_log(p_header.source_hdr_id, null, l_ds_erro, 2);
    when others then
      o_sts_code := c_status_erro;
      insert_log(p_header.source_hdr_id, null, sqlerrm||dbms_utility.format_error_backtrace, 2);
  end valida_end_distribuicao;
  --
  --Procedure para aplica retenção
  procedure prc_aplica_retencao(p_header_id     in  number
                               ,p_source_hdr_id in  number
                               ,p_ds_hold       in  varchar2
                               ,o_sts_code   in out number
                               ) is
    --
  --seleciona o código do hold_id
  cursor c_hold is
    select hold_id
    from oe_hold_definitions hde
    where hde.attribute1 = p_ds_hold
    and   hde.type_code  = 'HOLD'
    and   hde.context    = 'Informações Adicionais';
    --
  l_msg_count          number;
  l_msg_data           varchar2(2000);
  l_return_status      varchar2(100);
  l_hold_source_rec    oe_holds_pvt.hold_source_rec_type;
  w_hold_id            number;
  --
  begin
    --
    --Seleciona o código do hold_id
    open c_hold;
    fetch c_hold
    into w_hold_id;
    close c_hold;
    --
    l_hold_source_rec.hold_id          := w_hold_id;  -- Requested Hold id
    l_hold_source_rec.hold_entity_code := 'O';         -- Order Hold
    l_hold_source_rec.hold_entity_id   := p_header_id; -- Order Header id
    l_hold_source_rec.hold_comment     := 'Divergência de preço entre ordem de compra do cliente e lista de preço da PBG';
    l_hold_source_rec.header_id        := p_header_id; -- ID do Cabeçalho da Ordem.
    --
    oe_holds_pub.apply_holds(p_api_version      => 1.0
                            ,p_commit           => fnd_api.g_true
                            ,p_validation_level => fnd_api.g_valid_level_none
                            ,p_hold_source_rec  => l_hold_source_rec
                            ,x_msg_count        => l_msg_count
                            ,x_msg_data         => l_msg_data
                            ,x_return_status    => l_return_status
                            );
    --
    commit;
    --
  exception
    when others then
      o_sts_code := c_status_erro;
      insert_log(p_source_hdr_id, null, 'Erro: 1 - Erro ao aplicar retenção na ordem de venda. Erro: '||sqlerrm||dbms_utility.format_error_backtrace, 2);
  end prc_aplica_retencao;
  --
  -- Procedimento para validar divergencia de preco e aplicacao de retencao
  procedure valida_diverg_preco(p_header     in     order_header_r,
                                p_items_aux  in     order_line_aux_t,
                                p_header_id  in     number,
                                p_msg           out varchar2,
                                o_sts_code   in out number
                               ) is
  --
  w_app_hold boolean default false;
  --
  begin
    --
    for i in p_items_aux.first..p_items_aux.last loop
      --
      if p_items_aux(i).validate_price = false then
        --
        if w_app_hold = false then
          --
          w_app_hold := true;
          --
        end if;
        --
        if p_msg is null then
          --
          p_msg := 'Divergência de Preço:'||chr(10);
          p_msg := p_msg || 'Linha '||i||': '||p_items_aux(i).desc_error||chr(10);
          --
        else
          --
          p_msg := p_msg || 'Linha '||i||': '||p_items_aux(i).desc_error||chr(10);
          --
        end if;
        --
      end if;
      --
    end loop; -- p_items
    --
    if w_app_hold then
      --
      --Procedure para aplica retenção
      prc_aplica_retencao(p_header_id     => p_header_id
                         ,p_source_hdr_id => p_header.source_hdr_id
                         ,p_ds_hold       => 'DPPE'
                         ,o_sts_code      => o_sts_code
                         );
      --
    end if;
    --
  exception
    when others then
      o_sts_code := c_status_erro;
      insert_log(p_header.source_hdr_id,null,'Erro: 1 - Erro na procedure VALIDA_DIVERG_PRECO. Erro: '||sqlerrm||dbms_utility.format_error_backtrace, 2);
  end valida_diverg_preco;
  --
  
    FUNCTION valida_item (--p_package_item_id   IN NUMBER
                          p_segment1          IN VARCHAR2
                          , p_organization_id IN NUMBER
                          , p_sku             IN VARCHAR2 
                          ) RETURN VARCHAR2
    IS
    --
      v_inventory_item_id NUMBER;
      v_cod_produto       VARCHAR2(18);
      v_deposito          VARCHAR2(70);
      -- Help: 64598 - Alexandre Oliveira.
      l_categ_fase_vida   VARCHAR2(50);
      --
      -- Busca categoria do produto para validar em conjunto com a fase DP - Chamado: 64598 - Alexandre Oliveira.
      CURSOR c_categ_fase_vida (p_inventory_item_id NUMBER) IS
        SELECT Nvl(ic.SEGMENT1, 'x') ciclo
        FROM apps.MTL_ITEM_CATEGORIES_V    ic
        WHERE ic.inventory_item_id = p_inventory_item_id
          AND ic.organization_id   = pb_master_organization_id
          AND ic.CATEGORY_SET_NAME = ('PB - Ciclos das Fases de Vida');
    --
    BEGIN
      --
      fnd_file.put_line(fnd_file.log, '   - Valida o item: ' || To_Char(p_segment1));
      dbms_output.put_line('   - Valida o item: ' || To_Char(p_segment1));
      --
      /************************************************************************************************
      ** Por melhoria de Performance, separei a consulta do inventory_item_id, realizada via dblink  **
      ** da consulta dentro da base do EBS.                                                          **
      ** Ganho aproximado de: 4 minutos para 4 segundos.                                             **
      ** Autor: Alexandre Oliveira                                                                   **
      *************************************************************************************************/
      BEGIN
        -- tratamento para identificar onde está o no_data_found que ocorre intermitentemente - Alexandre
        SELECT inventory_item_id
          INTO v_inventory_item_id
        from mtl_system_items_b 
        where segment1 = p_segment1 and organization_id = p_organization_id;
      EXCEPTION
        WHEN No_Data_Found THEN
          --
          MSG_ERRO := '    ERRO: Favor editar, salvar o Pedido e sincronizá-lo novamente. Item NÃO foi encontrado pelo Oracle na base do iVop. Código interno do item - p_segment1: '
                      || To_Char(p_segment1) || ' - p_organization_id = ' || To_Char(p_organization_id);
          RETURN RETORNO_INVALIDO;
          -- erro de processo
        WHEN OTHERS THEN
          --
          MSG_ERRO := '    ERRO: Favor editar, salvar o Pedido e sincronizá-lo novamente. Houve um erro ao verificar dados do item na base do iVop. Código interno do item - p_segment1: '
                      || To_Char(p_segment1) || ' - p_organization_id = ' || To_Char(p_organization_id);
          RETURN RETORNO_INVALIDO;
          -- erro de processo
      END;
      --
      SELECT  msi.inventory_item_id
             ,msi.segment1 cd_produto
             ,msi.primary_uom_code unidade_medida
             ,msi.attribute9 fase_vida
             ,Nvl( (  SELECT ffvt.description
                      FROM fnd_flex_values      ffv
                      JOIN fnd_flex_value_sets  ffvs  ON ffv.flex_value_set_id  = ffvs.flex_value_set_id
                      JOIN fnd_flex_values_tl   ffvt  ON ffvt.flex_value_id     = ffv.flex_value_id
                      WHERE ffvt.LANGUAGE           = 'PTB'
                        AND flex_value_set_name     = 'INV_CLASSIFICACAO_APO'
                        AND ffvt.FLEX_VALUE_MEANING = msi.attribute4
                    ), 'N/A'
             ) classificacao
             ----------------------------------------------------------------------------------
             ,msi.global_attribute1
             ,msi.global_attribute2
        INTO vg_inventory_item_id
             ,vg_segment1
             ,vg_primary_uom_code
             ,vg_fase_vida
             ,vg_item_classificacao
             ,vg_class_fiscal_produto
             ,vg_origem_item
        FROM mtl_system_items_b msi
             --- Alterada consulta para buscar da view que contém a regra de busca pela organização relacionada ao contexto ---
             --- Na nova versão, a tfsales_item_pb_v é uma tabela temporária.                                           ---
             --- Autor: Alexandre Oliveira                                                                                  ---
    --         ,apps.tfsales_item_pb_view vw
       WHERE msi.organization_id    = pb_master_organization_id
         AND msi.inventory_item_id  = v_inventory_item_id;
         /**
          * Removi o relacionamento com a view TFSALES_ITEM_PB_VIEW desta validação;
          * Existe um momento, quando o produto não está na tabela de INFORMAÇÕES COMERCIAIS, "inv_produto_cml_pb" que gera erro inválido de integração
          * Este erro ocorre quando o concorrente PB - GERAR DADOS DO INV PARA WEB está rodando.
          * A validação precisa somente dizer: O item existe na base Oracle ? Somente com a MTL_SYSTEM_ITEMS_B já é possível responder isso.
          * @ Autor: Alexandre Oliveira.
          * @ Data: 05/01/2017
          */
    --     AND msi.inventory_item_id  = vw.inventory_item_id;
      --
      fnd_file.put_line(fnd_file.log, '    -> Item ' || vg_segment1 || ' válido.');
      dbms_output.put_line('    -> Item ' || vg_segment1 || ' válido.');
      --
      /**
       * Inserindo validação da Fase de vida - Chamado 64598 - Alexandre.
       * Código fonte extraido de: "ONTK12008JB.f_valida_fase_vida"
       * Código duplicado para maior agilidade e menor impacto na liberação da restrição.
       *
       * 14/12/2016 - Alexandre.
       * Lógica no iVop: Só deverá fazer a validação se o SKU NÃO for informado no iVop. SALES_ORDER_LINE.attribute01 = null.
       *                  Caso contrário o saldo será validado em outro processo conforme o SKU informado.
       */

      -- Chamado 113733 - Desativar controle de fase de vida "DP"
    --  IF vg_fase_vida = 'DP' AND Nvl( Trim(p_sku), 'x' ) = 'x' then
      IF vg_fase_vida = 'DPXX' AND Nvl( Trim(p_sku), 'x' ) = 'x' then
        /**
          * Nova alteração na DP - Chamado 64598.
          * Criar novo fluxo onde a fase de vida DP estará aberta para entrada de ordens sem saldo em estoque somente por três meses sendo eles:
          * DEZEMBRO, JANEIRO e FEVEREIRO.
          * No restante dos meses o Produto parametrizado com uma categoria específica para esta questão, só permitirá entrada de ordens com
          *  saldo em estoque e SKU informado na ordem.
          * Autor: Alexandre Oliveira.
          */
        --
        fnd_file.put_line(fnd_file.log, '    -> Validação fase de vida do item: ' || vg_segment1 || '.');
        dbms_output.put_line('    -> Validação fase de vida do item: ' || vg_segment1 || '.');
        --
        BEGIN
          OPEN c_categ_fase_vida (To_Number(v_inventory_item_id));
          FETCH c_categ_fase_vida INTO l_categ_fase_vida;
          --
          l_categ_fase_vida := Nvl(l_categ_fase_vida, 'x');
          --
          fnd_file.put_line(fnd_file.log, '    -> Categoria da fase de vida identificada: ' || l_categ_fase_vida || '.');
          dbms_output.put_line('    -> Categoria da fase de vida identificada: ' || l_categ_fase_vida || '.');
          --
        EXCEPTION
          WHEN OTHERS THEN
            --
            l_categ_fase_vida := 'x';
            --
            fnd_file.put_line(fnd_file.log, '    -> Categoria da fase de vida NÃO LOCALIZADA: ' || l_categ_fase_vida || '.');
            dbms_output.put_line('    -> Categoria da fase de vida NÃO LOCALIZADA: ' || l_categ_fase_vida || '.');
            --
        END;
        CLOSE c_categ_fase_vida;
        --
        IF l_categ_fase_vida = 'SEMESTRAL' AND To_Char(SYSDATE, 'MM') NOT IN (10,11,12,1,2) THEN
          -- Bloqueia entrada sem saldo em estoque caso o Mês vigente seja DIFERENTE de Dezembro, Janeiro ou Fevereiro
          --
          MSG_ERRO := '    ERRO: Produto ' || vg_segment1 || ' em fase de vida DP com ciclo SEMESTRAL. É Obrigatório informar SKU. '
                      || ' - p_organization_id = ' || p_organization_id;
          --
          fnd_file.put_line(fnd_file.log, '    -> Produto em Fase DP Bloqueado ' || To_Char(SYSDATE, 'dd/mm/yyyy hh24:mi:ss') || '. Categoria da fase de vida: ' || l_categ_fase_vida || '.');
          dbms_output.put_line('    -> Produto em Fase DP Bloqueado ' || To_Char(SYSDATE, 'dd/mm/yyyy hh24:mi:ss') || '. Categoria da fase de vida: ' || l_categ_fase_vida || '.');
          --
          RETURN RETORNO_INVALIDO;
          --
        ELSIF trunc(sysdate) > last_day(to_date('06', 'mm')) AND l_categ_fase_vida <> 'SEMESTRAL' THEN
          -- A regra definida pelo Marketing e repassada a Equipe Comercial da Portobello:
          -- Jan a Jun - DP: Permite a entrada de pedido mesmo não tendo em estoque, mas com faturamento até Dez do mesmo ano.
          -- Jul a Dez - DP = DE: Só permite a entrada de pedido se tiver em estoque.
          -- Chamado 64598 - Só libera se categoria for diferente de SEMESTRAL. 01/12/2016 - Alexandre Oliveira.
          MSG_ERRO := '    ERRO: Produto ' || vg_segment1 || ' em fase de vida DP com ciclo ANUAL. É Obrigatório informar SKU. '
                      || ' - p_organization_id = ' || To_Char(p_organization_id);
          --
          fnd_file.put_line(fnd_file.log, '    -> Produto em Fase DP Bloqueado ' || To_Char(SYSDATE, 'dd/mm/yyyy hh24:mi:ss') || '. Categoria da fase de vida: ' || l_categ_fase_vida || '.');
          dbms_output.put_line('    -> Produto em Fase DP Bloqueado ' || To_Char(SYSDATE, 'dd/mm/yyyy hh24:mi:ss') || '. Categoria da fase de vida: ' || l_categ_fase_vida || '.');
          --
          RETURN RETORNO_INVALIDO;
          --
        end if;
      -- FINAL - IF l_attribute9 = DP
    --    elsif l_attribute9 = 'DS' then
    --      p_mensagem := 'Não é aceito produto com fase de vida DS';
    --      return false;
    --    elsif l_attribute9 not in ('DE', 'IN', 'OP', 'SC','DP') AND NOT l_comercial then
    --      -- Não tem restrição de fase de vida
    --      if p_lot_number is null then
    --        -- Não tem restrisão de saldo porque não tem lote
    --        return true;
    --      end if;
    --      l_restricao_fase_vida := false;
        --
        fnd_file.put_line(fnd_file.log, '    -> Produto em Fase DP sem SKU LIBERADO ' || To_Char(SYSDATE, 'dd/mm/yyyy hh24:mi:ss') || '. Categoria da fase de vida: ' || l_categ_fase_vida || '.');
        dbms_output.put_line('    -> Produto em Fase DP sem SKU LIBERADO ' || To_Char(SYSDATE, 'dd/mm/yyyy hh24:mi:ss') || '. Categoria da fase de vida: ' || l_categ_fase_vida || '.');
        --
      end if; -- END IF vg_fase_vida = 'DP' AND Nvl( Trim(p_sku), 'x' ) = 'x'
      --
      RETURN RETORNO_VALIDO;
      --
    EXCEPTION
      -- cliente não encontrado
      WHEN NO_DATA_FOUND THEN
        -- Dados para geração do erro mais claro ao usuário.
        -- Dados do Produto
        SELECT msi.segment1
          INTO v_cod_produto
        FROM MTL_SYSTEM_ITEMS_B MSI
        WHERE msi.organization_id   = pb_master_organization_id
         AND msi.inventory_item_id  = v_inventory_item_id;
        -- Dados do depósito
        SELECT NAME
          INTO v_deposito
        FROM hr_organization_units
        WHERE ORGANIZATION_ID = p_organization_id;
        -- Final dados para geração do log - Alexandre Oliveira
        MSG_ERRO := '    ERRO: Item ' || v_cod_produto || ' NÃO cadastrado para o depósito ' || v_deposito || '. p_package_item_id = ' || p_segment1 || ' - p_organization_id = ' || p_organization_id;
        RETURN RETORNO_INVALIDO;
        -- erro de processo
      WHEN OTHERS THEN
        MSG_ERRO := '    ERRO: Erro no processo de validação do item. p_package_item_id = ' || p_segment1 || ' - p_organization_id = ' || p_organization_id;
        SQL_ERRO_COD := SQLCODE;
        SQL_ERRO_MSG := SQLERRM;
        RETURN RETORNO_ERRO;
      --
    END;

    FUNCTION valida_item_deposito_line (p_segment1 IN VARCHAR2, p_organization_id IN NUMBER) RETURN VARCHAR2
    IS
    --
      v_inventory_item_id NUMBER;
      v_cod_produto       VARCHAR2(18);
      v_deposito          VARCHAR2(70);
    --
    BEGIN
      --
      fnd_file.put_line(fnd_file.log, '   - Valida o item com Depósito da Linha: ' || p_segment1);
      dbms_output.put_line('   - Valida o item com Depósito da Linha: ' || p_segment1);
      --
      /************************************************************************************************
      ** Por melhoria de Performance, separei a consulta do inventory_item_id, realizada via dblink  **
      ** da consulta dentro da base do EBS.                                                          **
      ** Ganho aproximado de: 4 minutos para 4 segundos.                                             **
      ** Autor: Alexandre Oliveira                                                                   **
      *************************************************************************************************/
      SELECT inventory_item_id
          INTO v_inventory_item_id
        from mtl_system_items_b 
        where segment1 = p_segment1 and organization_id = p_organization_id;
        
      v_cod_produto := p_segment1;

      --
      fnd_file.put_line(fnd_file.log, '    -> Item ' || v_cod_produto || ' válido para o depósito ' || p_organization_id || '.');
      dbms_output.put_line('    -> Item ' || v_cod_produto || ' válido para o depósito ' || p_organization_id || '.');
      --
      RETURN RETORNO_VALIDO;
      --
    EXCEPTION
      -- ITEM não encontrado
      WHEN NO_DATA_FOUND THEN
        -- Dados para geração do erro mais claro ao usuário.
        -- Dados do Produto
        SELECT msi.segment1
          INTO v_cod_produto
        FROM MTL_SYSTEM_ITEMS_B MSI
        WHERE msi.organization_id   = pb_master_organization_id
         AND msi.inventory_item_id  = v_inventory_item_id;
        -- Dados do depósito
        SELECT NAME
          INTO v_deposito
        FROM hr_organization_units
        WHERE ORGANIZATION_ID = p_organization_id;
        -- Final dados para geração do log - Alexandre Oliveira
        MSG_ERRO := '    ERRO: Item ' || v_cod_produto || ' NÃO está cadastrado para o depósito ' || v_deposito || '. p_package_item_id = ' || p_segment1 || ' - p_organization_id = ' || p_organization_id;
        RETURN RETORNO_INVALIDO;
        -- erro de processo
      WHEN OTHERS THEN
        MSG_ERRO := '    ERRO: Erro no processo de validação do item POR DEPÓSITO. p_package_item_id = ' || p_segment1 || ' - p_organization_id = ' || p_organization_id;
        SQL_ERRO_COD := SQLCODE;
        SQL_ERRO_MSG := SQLERRM;
        RETURN RETORNO_ERRO;
      --
    END;

    FUNCTION valida_componibilidade (p_nr_lote IN VARCHAR2, p_item_erp_id IN NUMBER, p_qtd_sol IN NUMBER, p_depos_erp_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2
    IS
      --
      vl_qtd_estoque  NUMBER;
      vl_qtd_sol      NUMBER;
      --
    BEGIN
      --
      fnd_file.put_line(fnd_file.log, '   - Valida a componibilidade do item. Lote nr: ' || p_nr_lote);
      dbms_output.put_line('   - Valida a componibilidade do item. Lote nr: ' || p_nr_lote);
      --
      -- verifica se não preencheu
      IF (p_nr_lote IS NULL) THEN
        --
        fnd_file.put_line(fnd_file.log, '    -> Componibilidade do item não preenchida.');
        dbms_output.put_line('    -> Componibilidade do item não preenchida.');
        RETURN RETORNO_VALIDO;
        --
      -- se preencheu, valida a quantidade em estoque
      ELSE
        -- Arredondamento em 5 casas para comparação entre solicitado e disponível - Help 40301 -- Alexandre Oliveira.
        vl_qtd_sol := Round(p_qtd_sol, 5);
        --
        
        select sum(saldo_disponivel) 
        INTO   vl_qtd_estoque
        from XXPB_ESTOQUE_API est
        join inv_produto_cml_pb inv on est.cod_produto_ora = inv.cd_produto
        where est.cod_tonalidade_calibre = p_nr_lote
        AND  inv.ITEM_ID = p_item_erp_id
        AND (est.COD_DEPOSITO = p_depos_erp_id);

        -- se tem estoque
        IF (vl_qtd_estoque >= vl_qtd_sol) THEN
          --
          fnd_file.put_line(fnd_file.log, '    -> Componibilidade do item válida. Produto em estoque.');
          dbms_output.put_line('    -> Componibilidade do item válida. Produto em estoque.');
          RETURN RETORNO_VALIDO;
          --
        -- senão tem estoque
        ELSE
          --
          MSG_ERRO := ' ERRO: Estoque insuficiente! Qtd. Estoque / Solicitada: ' || vl_qtd_estoque || '/' || vl_qtd_sol;
          RETURN RETORNO_INVALIDO;
          --
        END IF;
        --
      END IF;
      --
    EXCEPTION
      -- estoque não encontrado
      WHEN NO_DATA_FOUND THEN
        MSG_ERRO := '    ERRO: Componibilidade do item inválida. Estoque não encontrado.';
        RETURN RETORNO_INVALIDO;
        -- erro de processo
      WHEN OTHERS THEN
        MSG_ERRO := '    ERRO: Erro no processo de validação da componibilidade do item.';
        SQL_ERRO_COD := SQLCODE;
        SQL_ERRO_MSG := SQLERRM;
        RETURN RETORNO_ERRO;
      --
    END;


    FUNCTION valida_item_de_in (p_item_erp_id IN NUMBER, p_qtd_sol IN NUMBER, p_ship_from_org_id IN VARCHAR2, p_fase_vida IN VARCHAR2) RETURN VARCHAR2
    IS
    --
      vl_ret  NUMBER;
      vl_mes  NUMBER;
    BEGIN
      --
      /*
       * Comentado trecho para tendimento do chamado 64598 - Nova fase de vida SEMESTRAL.
      BEGIN
        -- CHAMADO 51555 - PERMITIR FASE VIDA DP DURANTE O PRIMEIRO SEMESTRE DE CADA ANO.
        -- ALTERADO POR: Alexandre Oliveira
        -- Solicitante: João Augusto - Pointer.
        SELECT To_Number(To_Char(SYSDATE, 'MM')) MES
          INTO vl_mes
        FROM DUAL;
      EXCEPTION
        WHEN No_Data_Found THEN
          vl_mes := 12;
        WHEN OTHERS THEN
          vl_mes := 12;
      END;
      */
      --
      IF ( p_fase_vida NOT IN ('DP', 'AT') ) THEN
        --
        SELECT pbpkgont01.valida_fase_vida(p_item_erp_id, Round(p_qtd_sol, 5), p_ship_from_org_id)
        INTO vl_ret
        FROM dual;
        --
        IF vl_ret = 1 THEN
          -- se não possui estoque
          MSG_ERRO := '     ERRO: Saldo insuficiente produto com fase de vida DE/IN.';
          RETURN RETORNO_INVALIDO;
          --
        END IF;
        --
      END IF;
      --
      RETURN RETORNO_VALIDO;
      --
    EXCEPTION
      -- erro de processo
      WHEN OTHERS THEN
        MSG_ERRO := '    ERRO: Erro no processo de validação de estoque para itens DE/IN.';
        SQL_ERRO_COD := SQLCODE;
        SQL_ERRO_MSG := SQLERRM;
        RETURN RETORNO_ERRO;
      --
    END;



    FUNCTION valida_item_comercial (p_camada_comercial IN VARCHAR2, p_item_erp_id IN NUMBER, p_qtd_sol IN NUMBER, p_ship_from_org_id IN VARCHAR2) RETURN VARCHAR2
    IS
    --
      vl_ret  NUMBER;
    BEGIN
      --
      SELECT pbpkgont01.valida_comercial(p_camada_comercial, p_item_erp_id, Round(p_qtd_sol, 5), p_ship_from_org_id)
        INTO vl_ret
        FROM dual;
      --
      -- se não possui estoque
      IF (vl_ret = 1) THEN
        MSG_ERRO := '     ERRO: Saldo insuficiente para o produto comercial.';
        RETURN RETORNO_INVALIDO;
      END IF;
      --
      RETURN RETORNO_VALIDO;
      --
    EXCEPTION
      -- erro de processo
      WHEN OTHERS THEN
        MSG_ERRO := '    ERRO: Erro no processo de validação de estoque para itens comercial.';
        SQL_ERRO_COD := SQLCODE;
        SQL_ERRO_MSG := SQLERRM;
        RETURN RETORNO_ERRO;
      --
    END;

    FUNCTION valida_item_comercial_estoque (p_camada_comercial IN VARCHAR2, p_item_erp_id IN NUMBER, p_qtd_sol IN NUMBER, p_ship_from_org_id IN VARCHAR2, p_sku IN VARCHAR2, p_ship_from_org IN NUMBER, p_tipo IN INT) RETURN VARCHAR2
    IS
    --
      vl_ret  NUMBER;
      qtd_carteira NUMBER;
      qtd_disp NUMBER;
      cd_produto varchar2(10);
    BEGIN
      --
      qtd_carteira := 0;
      cd_produto := '';

      SELECT pbpkgont01.valida_comercial_estoque(p_camada_comercial, p_item_erp_id, Round(p_qtd_sol, 5), p_ship_from_org_id, p_sku, p_ship_from_org)
        INTO vl_ret
        FROM dual;
      --
      -- se não possui estoque
      IF (vl_ret = 1 or p_tipo != 1) THEN
        SELECT msi.segment1
        into cd_produto
        FROM mtl_system_items_b msi
        WHERE msi.organization_id    = pb_master_organization_id
         AND msi.inventory_item_id  = p_item_erp_id;

        SELECT pbpkgont01.QTD_CARTEIRA_ESTOQUE(p_item_erp_id, p_sku, p_ship_from_org)
        INTO qtd_carteira
        FROM dual;

        SELECT pbpkgont01.QTD_DISP_ESTOQUE(p_camada_comercial, p_item_erp_id, Round(p_qtd_sol, 5), p_ship_from_org_id, p_sku, p_ship_from_org)
        INTO qtd_disp
        FROM dual;

        IF p_tipo = 1 then 
            MSG_ERRO := 'ERRO: Saldo insuficiente para o produto comercial - ' || cd_produto || ' (Qtd. em Carteira:' || nvl(qtd_carteira,0) || ' \ Disponivel :' || nvl(qtd_disp,0) || ')' ;
        else
            MSG_ERRO := 'ERRO: Saldo insuficiente para o produto SU - ' || cd_produto || ' (Qtd. em Carteira:' || nvl(qtd_carteira,0) || ' \ Disponivel :' || nvl(qtd_disp,0) || ')' ;
        end if;

        RETURN RETORNO_INVALIDO;
      END IF;
      --
      RETURN RETORNO_VALIDO;
      --
    EXCEPTION
      -- erro de processo
      WHEN OTHERS THEN
        MSG_ERRO := '    ERRO: Erro no processo de validação de estoque para itens comercial.';
        SQL_ERRO_COD := SQLCODE;
        SQL_ERRO_MSG := SQLERRM;
        RETURN RETORNO_ERRO;
      --
    END;

    FUNCTION valida_oc_do_cliente (p_oc_cliente IN VARCHAR2) RETURN VARCHAR2  IS
    --
    BEGIN
      --
      fnd_file.put_line(fnd_file.log, ' - Verifica tamanho do campo ordem de compra do cliente: ' || p_oc_cliente);
      dbms_output.put_line('- Verifica tamanho do campo ordem de compra do cliente: ' || p_oc_cliente);
      --
      IF Length( To_Char(p_oc_cliente) ) > 20 THEN
        MSG_ERRO := 'O valor informado para Ordem de Compra do cliente é inválido --> '
                    || p_oc_cliente || ' <--. Tamanho máxio é de 20 caracteres.';
        fnd_file.put_line(fnd_file.log, '  -> Tamanho ultrapassou o limite' || p_oc_cliente);
        dbms_output.put_line('  -> Tamanho ultrapassou o limite: ' || p_oc_cliente);
        RETURN RETORNO_INVALIDO;
      ELSE
        fnd_file.put_line(fnd_file.log, '  -> Tamanho dentro do limite' || p_oc_cliente);
        dbms_output.put_line('  -> Tamanho dentro do limite: ' || p_oc_cliente);
        RETURN RETORNO_VALIDO;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        MSG_ERRO := '  ERRO: Erro na validação do tamanho do campo OC do cliente.';
        SQL_ERRO_COD := SQLCODE;
        SQL_ERRO_MSG := SQLERRM;
        RETURN RETORNO_ERRO;
      --
    END;  
    
    --
    PROCEDURE limpa_var_integracao_linha
    IS
    --
    BEGIN
      -- zera as variaveis de integração
      vg_inventory_item_id      := NULL;
      vg_segment1               := NULL;
      vg_primary_uom_code       := NULL;
      vg_fase_vida              := NULL;
      vg_item_classificacao     := NULL;
      --vg_natureza_operacao      := NULL;
      --vg_price_list_item_erp_id := NULL;
      vg_origem_item            := NULL;
      --vg_prazo_entrega_item     := NULL;
      --vg_unit_list_price        := NULL;
      vg_class_fiscal_produto   := NULL;
      vg_grupo_imposto          := NULL;
    END;
    
    
    
   procedure prc_consumo_cota_sales(p_header       in     order_header_r
                             ,p_return_msg out varchar2
                             ) is
     --
     -- Seleciona total da ordem
     cursor c1(p_period_name in varchar2) is
       select rat.segment2 as cod_filial
       from apps.ra_territories          rat,
       apps.ra_salesrep_territories rast,
       jtf_rs_salesreps             jrs
      where  1 = 1
      and    rast.salesrep_id      = p_header.salesrep_id 
      and    rast.end_date_active is null
      and    jrs.org_id            = nvl(fnd_profile.value('ORG_ID'),42)
      and    rat.territory_id      = rast.territory_id;

     --
     r1 c1%rowtype;
     --
     w_period         varchar2(32);
     
     w_vl_meta_disp   number default 0;
     --
   begin
     --
        registra_cota := 'N';
     
       select gp.period_name
       into w_period
       from   gl_periods gp
       where  1=1
       and    gp.period_set_name        = 'Fiscal'
       and    gp.adjustment_period_flag = 'N'
       --and    ooh.header_id             = p_header_id
       and    trunc(SYSDATE)   between start_date and end_date;

     for r1 in c1(w_period) loop
       --
       -- Busca parametrização de cota por canal de venda e filial para um período em questão
       xxpb_ont001_by7_k.prc_busca_cota_f(p_sales_channel_code => p_header.sales_channel_code
                                         ,p_cod_filial         => r1.cod_filial
                                         ,p_periodo            => w_period
                                         ,p_id_cota_vendas     => w_id_cota_vendas
                                         ,p_vl_meta_disp       => w_vl_meta_disp
                                         );
       --
       -- Valida ID de regra para cotas
       if w_id_cota_vendas is null then
         --
         p_return_msg := 'OK';
         --
       else
         --
         if nvl(p_header.total_opportunity_quantity,0) <= w_vl_meta_disp then
           --
           registra_cota := 'S';
           p_return_msg := 'OK';
           --
         else
           --
           p_return_msg := 'Validação de Cota(Registro): Saldo insuficiente, disponível: '||to_char(w_vl_meta_disp,'FM999G999G999G990D00')||'!';
           --
         end if; -- if r1.tot_ov <= w_vl_meta_disp then
         --
       end if; -- if w_id_cota_vendas is null then
       --
     end loop; -- c1
     --
     w_period         := null;
     w_id_cota_vendas := null;
     w_vl_meta_disp   := 0;
     --
   end prc_consumo_cota_sales;    
    
end XXPB_SALESFORCE_ORDER_ENTRY_PKG_BY7;
/

GRANT EXECUTE ON APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG_BY7 TO API_RESTFUL_V1;
