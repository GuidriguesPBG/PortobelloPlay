DROP PACKAGE APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG;

CREATE OR REPLACE PACKAGE APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG is
--**********************************************************
--Objetivo: mantem as rotinas responsáveis por controlar a
--          entrada de pedido por API para o EBS
--
--Autor: Deivde Melo e Giovani Bachtold
--Data: 14/09/2020
--**********************************************************

procedure create_order( p_body         blob,
                        p_current_user varchar2,
                        x_status_code out varchar2 );

end XXPB_SALESFORCE_ORDER_ENTRY_PKG;
/

GRANT EXECUTE ON APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG TO API_RESTFUL_V1;
DROP PACKAGE BODY APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG is

--**********************************************************
--Objetivo: mantem as rotinas responsáveis por controlar a
--          entrada de pedido por API para o EBS
--
--Autor: Deivde Melo e Giovani Bachtold
--Data: 14/09/2020
--**********************************************************

--***************************************************************
--Objetivo: cria os pedidos no EBS utilizando as APIs
--
--Autor: Deivde Melo e Giovani Bachtold
--Data: 14/09/2020
--***************************************************************
procedure create_order( p_body         blob,
                        p_current_user varchar2,
                        x_status_code out varchar2 ) is

$IF  dbms_db_version.ver_le_12 $THEN
  l_root json := json();
$ELSE
  l_root JSON_OBJECT_T := JSON_OBJECT_T();
$END

l_log varchar2(1000);
l_om_header_id  NUMBER;
l_om_order_num  VARCHAR2(250);


BEGIN

  apps.XXPB_SALESFORCE_ORDER_ENTRY_PKG_BY7.main(
                                           p_body         => p_body,
--                                           p_body         => utl_raw.cast_to_varchar2(dbms_lob.substr(p_body)),
                                           x_om_header_id => l_om_header_id,
                                           x_om_order_num => l_om_order_num,
                                           x_log          => l_log,
                                           x_sts_code     => x_status_code );

  if x_status_code <> 1 then
    x_status_code := 500;
    l_root.put('Code', 500);
    l_root.put('Type', 'Error');
    l_root.put('Message ', l_log );
  else
    x_status_code := 200;
    l_root.put('Code', 200);
    l_root.put('Message', 'Processo executado com sucesso');
    l_root.put('om_header_id', l_om_header_id);
    l_root.put('om_order_num', l_om_order_num);

  end if;

  htp.p('Content-Type: application/json');
  owa_util.http_header_close;

  $IF  dbms_db_version.ver_le_12 $THEN
  l_root.htp;
  $ELSE
  htp_print_clob(l_root.to_clob);
  $END


END create_order;

end XXPB_SALESFORCE_ORDER_ENTRY_PKG;
/

GRANT EXECUTE ON APPS.XXPB_SALESFORCE_ORDER_ENTRY_PKG TO API_RESTFUL_V1;
