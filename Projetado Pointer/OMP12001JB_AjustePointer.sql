CREATE OR REPLACE PACKAGE APPS."OMP12001JB" is

  -- Vers�o Antiga
  vg_saldo_estoque      NUMBER;
  vg_calcula_atp        VARCHAR2(1) DEFAULT 'Y';
  vg_usa_maior_dmf      VARCHAR2(1) DEFAULT 'Y';
  vg_historico_dmf      VARCHAR(3500);
  --Seleciona DMF linha
  FUNCTION fnd_dmf_linha (p_line_id IN NUMBER) RETURN DATE;


  --Envia o e-mail
  PROCEDURE prc_envia_email (p_ds_email_destino  IN VARCHAR2,
                             p_ds_assunto        IN VARCHAR2,
                             p_ds_corpo          IN VARCHAR2,
                             p_ds_erro           IN OUT VARCHAR2);

  --Verifica o tipo de reserva
  FUNCTION fnd_tipo_reserva (p_canal     IN VARCHAR2,
                             p_header_id IN NUMBER ) RETURN VARCHAR2;

  --Seleciona o canal de venda da ordem
  FUNCTION fnd_canal_venda (p_header_id IN NUMBER) RETURN VARCHAR2;

  --Seleciona o lead time otif por canal
  FUNCTION fnd_lead_time_otif (p_canal IN VARCHAR2) RETURN NUMBER;

  --Seleciona o lead time interno por canal
  FUNCTION fnd_lead_time (p_canal IN VARCHAR2) RETURN NUMBER;

  --Seleciona o horizonte por canal
  FUNCTION fnd_horizonte (p_canal IN VARCHAR2) RETURN NUMBER;

  --Seleciona o percentual disponivel de saldo
  FUNCTION fnd_percentual_dispo return NUMBER;

  --Seleciona o Horizonte da Carteira
  FUNCTION fnd_horizonte_carteira return NUMBER;

  --Seleciona a quantidade de periodos validos do saldo
  FUNCTION fnd_qtd_periodo RETURN NUMBER;

  --Seleciona o grupo de horizonte do saldo
  FUNCTION fnd_grupo_horizonte_saldo RETURN NUMBER;

  --Seleciona a data final do per�odo informado
  FUNCTION fnd_data_fim_periodo (p_id_periodo IN NUMBER)RETURN DATE;

  --Classifica em qual periodo a data se enquadra
  FUNCTION fnd_periodo (p_dt_dmf IN date)RETURN NUMBER;

  --Verifica desponibilidade de estoque
  FUNCTION fnd_estoque_dispo (p_inventory_item_id IN NUMBER,
                            p_organization_id   IN NUMBER,
                            p_qtd               IN NUMBER,
                            p_canal             IN VARCHAR2,
                            p_header_id         IN NUMBER) RETURN VARCHAR2;

  --Verifica desponibilidade de estoque
  FUNCTION fnd_estoque_dispo (p_inventory_item_id IN NUMBER,
                              p_organization_id   IN NUMBER,
                              p_qtd               IN NUMBER,
                              p_canal             IN VARCHAR2,
                              p_header_id         IN NUMBER,
                              p_carteira          IN NUMBER) RETURN VARCHAR2;

  --Seleciona a data de PPE
  FUNCTION fnd_data_ppe (p_inventory_item_id  IN NUMBER,
                         p_sales_channel_code IN VARCHAR2) RETURN DATE;

  --Seleciona o saldo do produto
  FUNCTION fnd_saldo_produto (p_inventory_item_id  IN NUMBER,
                              p_item_um            IN VARCHAR2,
                              p_id_periodo         IN NUMBER,
                              p_sales_channel_code IN VARCHAR2) RETURN NUMBER;

  --Seleciona a proxima agenda
  FUNCTION fnd_agenda (p_id_agenda   IN NUMBER,
                       p_dt_promessa IN DATE) RETURN DATE;

  --Seleciona o maior data da ordem
  FUNCTION fnd_maior_data (p_header_id IN NUMBER,
                           p_dt_promessa IN DATE) RETURN DATE;

  FUNCTION fnd_maior_data ( p_header_id      IN NUMBER,
                            p_dt_promessa    IN DATE,
                            p_dt_dmf         IN DATE,
                            p_data_atualiza  IN VARCHAR2 ) RETURN DATE;

  -- Busca maior DMF COVID. Chamado: 131546 - Alexandre Oliveira.
  FUNCTION fnd_maior_data_covid (p_header_id IN NUMBER) RETURN DATE;

  -- Calcula data promessa, chama a fun��o com mais par�metros chamando o c�lculo p_data_retorno = DP
  FUNCTION fnd_data_promessa_item ( p_inventory_item_id  IN NUMBER,
                                    p_organization_id    IN NUMBER,
                                    p_primary_uom_code   IN VARCHAR2,
                                    p_qt_item            IN NUMBER,
                                    p_dt_dmf             IN DATE,
                                    p_sales_channel_code IN VARCHAR2,
                                    p_header_id          IN NUMBER,
                                    p_id_agenda          IN NUMBER,
                                    p_id_fat_total       IN VARCHAR2,
                                    p_id_familia         IN VARCHAR2,
                                    p_id_calibre         IN VARCHAR2,
                                    p_id_grupo           IN VARCHAR2 ) RETURN DATE;

  --Calcula da data de promessa
  FUNCTION fnd_data_promessa_item ( p_inventory_item_id  IN NUMBER,
                                    p_organization_id    IN NUMBER,
                                    p_primary_uom_code   IN VARCHAR2,
                                    p_qt_item            IN NUMBER,
                                    p_dt_dmf             IN DATE,
                                    p_sales_channel_code IN VARCHAR2,
                                    p_header_id          IN NUMBER,
                                    p_id_agenda          IN NUMBER,
                                    p_id_fat_total       IN VARCHAR2,
                                    p_id_familia         IN VARCHAR2,
                                    p_id_calibre         IN VARCHAR2,
                                    p_id_grupo           IN VARCHAR2,
                                    p_data_retorno       IN VARCHAR2,
                                    p_line_id            IN NUMBER,
                                    p_dmf_old            IN DATE,
                                    p_dp_old             IN DATE,
                                    p_ddc_old            IN DATE,
                                    p_ddc_new            IN DATE,
                                    p_grava_historico    IN VARCHAR2,
                                    p_order_source_id    IN NUMBER
                                    ) RETURN DATE;

  PROCEDURE prd_atualiza_data_linha_ent ( p_retcode           IN OUT VARCHAR2
                                          , p_errbuf          IN OUT VARCHAR2
                                          , p_order_number    IN VARCHAR2 );

  -- Verifica disponibildade de saldo com restri��o para ATP COVID 19
  FUNCTION fnd_saldo_disp_restricao(p_organization_id       IN NUMBER
                                    , p_inventory_item_id   IN NUMBER
                                    , p_id_familia          IN VARCHAR2
                                    , p_id_calibre          IN VARCHAR2
                                    , p_id_grupo            IN VARCHAR2
                                    , p_qtd_ordered         IN VARCHAR2
                                    , p_header_id           IN NUMBER     ) RETURN VARCHAR2;

  -- Retorna se existe saldo dispon�vel para os produtos do grupo de uma ordem de venda.
  FUNCTION fnd_saldo_disp_grupo(p_header_id           IN NUMBER
                                , p_grupo             IN VARCHAR2
                                , p_organization_id   IN NUMBER
                                , p_inventory_item_id IN NUMBER
                                , p_qt_item           IN NUMBER ) RETURN VARCHAR2;

  -- Calcula a DMF, quando atendida a regra.
  FUNCTION prd_ajusta_dmf ( p_inventory_item_id  IN NUMBER
                            , p_dmf               IN DATE
                            , p_sales_channel     IN VARCHAR2
                            , p_line_id           IN NUMBER
                            , p_order_source_id   IN NUMBER
                            , p_organization_id   IN NUMBER
                            , p_header_id         IN NUMBER ) RETURN DATE;

  -- Verifica se tem reserva para linha da ordem de venda.
  FUNCTION valida_reserva_dmf ( p_line_id IN NUMBER ) RETURN VARCHAR2;

  -- Grava hist�rico de c�lculo da DMF
  PROCEDURE fnd_historico_dmf(p_header_id                 IN NUMBER
                              , p_line_id                 IN NUMBER
                              , p_inventory_item_id       IN NUMBER
                              , p_dmf_old                 IN DATE
                              , p_dmf_new                 IN DATE
                              , p_dmf_calculada           IN DATE
                              , p_dp_old                  IN DATE
                              , p_dp_new                  IN DATE
                              , p_ddc_old                 IN DATE
                              , p_ddc_new                 IN DATE
                              , p_regra                   IN VARCHAR2
                              , p_regra_detalhes          IN VARCHAR2
                              , p_origem                  IN VARCHAR2
                              , p_saldo_encontrado        IN NUMBER
                              , p_ordered_quantity        IN NUMBER );

  PROCEDURE prc_historico_dmf_mp(p_header_id                 IN NUMBER
                                 , p_line_id                 IN NUMBER);



  -- Vers�o Nova
  FUNCTION fnd_qtd_periodo_dec RETURN NUMBER;
  --
  FUNCTION fnd_horizonte_periodo_dec (p_horiz_periodo IN VARCHAR2
                                     ,p_de_ate        IN VARCHAR2) RETURN NUMBER;
  --
  FUNCTION fnd_percentual_dispo_dec RETURN NUMBER;
  --
  FUNCTION fnd_grupo_horizonte_saldo_dec RETURN NUMBER;
  --
  FUNCTION fnd_horizonte_carteira_dec RETURN NUMBER;
  --
  FUNCTION fnd_data_fim_periodo_dec (p_id_periodo IN NUMBER
                                    ,p_carteira   IN VARCHAR2
                                    ) RETURN DATE;
  --
  FUNCTION fnd_dias_seguranca_prod_dec RETURN NUMBER;
  --
  FUNCTION fnd_periodo_dec (p_dt_dmf   IN DATE
                           ,p_origem   IN VARCHAR2
                           ,p_carteira IN VARCHAR2 DEFAULT 'N'
                           ) RETURN NUMBER;
  --
  FUNCTION fnd_ajusta_periodos RETURN NUMBER;

  FUNCTION fnd_only_positive (p_number NUMBER) RETURN NUMBER;
  --
--  PROCEDURE prc_valida_contra_estoque (p_segment1               IN  NUMBER
--                                      ,p_projetar_pbshop        OUT VARCHAR2
--                                      ,p_projetar_demais_canais OUT VARCHAR2
--                                      );
  --
  FUNCTION fnd_carteira_interna (p_item    NUMBER
                        ,p_um      VARCHAR2
                        ,p_periodo NUMBER
                        ,p_cd      VARCHAR2) RETURN NUMBER;
  --

  FUNCTION fnd_carteira (p_item    NUMBER
                        ,p_um      VARCHAR2
                        ,p_periodo NUMBER
                        ,p_cd      VARCHAR2) RETURN NUMBER;

  FUNCTION fnd_carteira_shop (p_item    NUMBER
                        ,p_um      VARCHAR2
                        ,p_periodo NUMBER) RETURN NUMBER;

  --

  FUNCTION fnd_saldo_anterior_cd (p_item    VARCHAR2
                                 ,p_periodo NUMBER
                                 ,p_cd      VARCHAR2) RETURN NUMBER;
  --
  --PROCEDURE prc_carga_saldo(p_inventory_item_id IN NUMBER, p_gera_log IN NUMBER, p_gera_log_geral IN NUMBER); -- (p_retcode         IN OUT VARCHAR2
  PROCEDURE prc_carga_saldo(p_retcode         IN OUT VARCHAR2,
                             p_errbuf          IN OUT VARCHAR2); 


  PROCEDURE calcula_producao_atp(w_errbuf OUT VARCHAR2, w_retcode OUT NUMBER);
  
  PROCEDURE calcula_producao_pointer(w_errbuf OUT VARCHAR2, w_retcode OUT NUMBER);

  PROCEDURE prc_carga_saldo_pointer(p_retcode         IN OUT VARCHAR2, p_errbuf          IN OUT VARCHAR2); 

  FUNCTION send_email (
    p_dados_erro  IN VARCHAR2
  )
  RETURN VARCHAR2;
  --
END omp12001jb;
/

GRANT EXECUTE ON APPS.OMP12001JB TO APPSR;

GRANT EXECUTE ON APPS.OMP12001JB TO ONT WITH GRANT OPTION;

CREATE OR REPLACE PACKAGE BODY APPS."OMP12001JB" IS
--****  VERS�O ANTIGA **********************************************************************

FUNCTION fnd_dmf_linha (p_line_id IN NUMBER) RETURN DATE IS

CURSOR c_dmf_linha IS
  SELECT schedule_ship_date
  FROM oe_order_lines_all ola
  WHERE ola.line_id = p_line_id;

w_dt_dmf DATE;

PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  --Seleciona DMF da linha
  OPEN c_dmf_linha;
  FETCH c_dmf_linha
  INTO w_dt_dmf;
  CLOSE c_dmf_linha;

  RETURN(trunc(w_dt_dmf));

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar a DMF linha.'||SQLERRM);
END fnd_dmf_linha;


--**************************************************************************
--Objetivo: rotina de envio de e-mail
--
--Autor: Danilo Kramel - JB
--Data: 19/07/2013
--**************************************************************************
PROCEDURE prc_envia_email (p_ds_email_destino  IN VARCHAR2,
                           p_ds_assunto        IN VARCHAR2,
                           p_ds_corpo          IN VARCHAR2,
                           p_ds_erro           IN OUT VARCHAR2) IS

w_erro      EXCEPTION;
w_ds_erro   VARCHAR2(32767);

PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  w_ds_erro:= f2c_send_javamail.SendMail(SMTPServerName => fnd_profile.value('PB_EASY_XML_SMTP_SERVER'),
                                         Sender         => 'oracle@portobello.com.br',
                                         Recipient      => p_ds_email_destino,
                                         CcRecipient    => '',
                                         BccRecipient   => '',
                                         Subject        => p_ds_assunto,
                                         Body           => p_ds_corpo,
                                         ErrorMessage   => w_ds_erro,
                                         Attachments    => NULL );

  IF w_ds_erro <> 0 THEN
    RAISE w_erro;
  END IF;

  COMMIT;

EXCEPTION
  WHEN w_erro THEN
    p_ds_erro := w_ds_erro;

  WHEN OTHERS THEN
    p_ds_erro := 'Erro ao enviar o e-mail.Erro:'||SQLERRM;
END prc_envia_email;


--**************************************************************************
--Objetivo: identifica o tipo de reserva para selecionar a disponibilidade
--          do estoque. Quando executado pelo Microvix e iVop o parâmetro de
--          p_header_id será passado como nulo.
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_tipo_reserva (p_canal     IN VARCHAR2,
                           p_header_id IN NUMBER ) RETURN VARCHAR2 IS
BEGIN
  --
  IF p_canal = '4' then
    --
    return 'PBSHOP';
    --
  ELSIF p_canal = '1' then -- Canal Engenharia
    --
    FOR r IN (SELECT 1
              FROM   oe_order_headers_all
              WHERE  (nvl(attribute19,'236') <> '236' OR
                      nvl(attribute20,'236') <> '236')
              AND    header_id               =  p_header_id) LOOP
      --
      RETURN 'NACIONAIS';
      --
    END LOOP;
    --
  ELSIF p_canal = '11' THEN -- Canal Ação Especial MI.
    --
    FOR r in (SELECT 1
              FROM   oe_order_headers_all
              WHERE  nvl(attribute19,'236') <> '236'
              AND    header_id              =  p_header_id) LOOP
      --
      RETURN 'NACIONAIS';
      --
    END LOOP;
    --
  END IF;
  --
  RETURN null;
  --
EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o tipo de reserva.'||SQLERRM);
END fnd_tipo_reserva;


--**************************************************************************
--Objetivo: seleciona o canal de venda para o número da ordem passada
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_canal_venda (p_header_id IN NUMBER) RETURN VARCHAR2 IS

--seleciona o canal de vendas da ordem
CURSOR c_canal_venda IS
  SELECT sales_channel_code
  FROM oe_order_headers_all
  WHERE header_id = p_header_id;

w_sales_channel_code VARCHAR2(5);
BEGIN

  --Seleciona lead time conforme canal
  OPEN c_canal_venda;
  FETCH c_canal_venda
  INTO w_sales_channel_code;
  CLOSE c_canal_venda;

  RETURN(w_sales_channel_code);

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o canal de venda.'||SQLERRM);
END fnd_canal_venda;

--**************************************************************************
--Objetivo: seleciona o lead time OTIF conforme canal de venda. Essa
--          informação possui a configuração DEFAULT para os demais canais
--          diferente de 1-Engenharia, 2-Revenda e 4-PBSHOP
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_lead_time_otif (p_canal IN VARCHAR2) RETURN NUMBER IS

CURSOR c_lead_time (p_canal IN VARCHAR2)IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    lookup_code         = p_canal
  AND    lookup_type         = 'ONT_ATP_LEAD_TIME_OTIF_PB';

w_lead_time NUMBER;
BEGIN

  --Seleciona lead time conforme canal
  OPEN c_lead_time(p_canal);
  FETCH c_lead_time
  INTO w_lead_time;
  CLOSE c_lead_time;

  --Se nao existir para o canal passado seleciona o valor default
  IF w_lead_time IS NULL THEN
    --Seleciona o valor default
    OPEN c_lead_time('DEFAULT');
    FETCH c_lead_time
    INTO w_lead_time;
    CLOSE c_lead_time;
  END IF;

  RETURN(nvl(w_lead_time,0));

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o lead time interno.'||SQLERRM);
END fnd_lead_time_otif;

--**************************************************************************
--Objetivo: seleciona o lead time interno conforme canal de venda. Essa
--          informação possui a configuração DEFAULT para os demais canais
--          diferente de 1-Engenharia, 2-Revenda e 4-PBSHOP
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_lead_time (p_canal IN VARCHAR2) RETURN NUMBER IS

CURSOR c_lead_time (p_canal IN VARCHAR2)IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    lookup_code         = p_canal
  AND    lookup_type         = 'ONT_ATP_LEAD_TIME_INTERNO_PB';

w_lead_time NUMBER;
BEGIN

  --Seleciona lead time conforme canal
  OPEN c_lead_time(p_canal);
  FETCH c_lead_time
  INTO w_lead_time;
  CLOSE c_lead_time;

  --Se nao existir para o canal passado seleciona o valor default
  IF w_lead_time IS NULL THEN
    --Seleciona o valor default
    OPEN c_lead_time('DEFAULT');
    FETCH c_lead_time
    INTO w_lead_time;
    CLOSE c_lead_time;
  END IF;

  RETURN(nvl(w_lead_time,0));

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o lead time interno.'||SQLERRM);
END fnd_lead_time;

--**************************************************************************
--Objetivo: seleciona o horizonte conforme canal de venda. Essa
--          informação possui a configuração DEFAULT para os demais canais
--          diferente de 1-Engenharia, 2-Revenda e 4-PBSHOP
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_horizonte (p_canal IN VARCHAR2) RETURN NUMBER IS

CURSOR c_horizonte (p_canal IN VARCHAR2)IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    lookup_code         = p_canal
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_ENTRADA_PB';

w_horizonte NUMBER;
BEGIN

  --Seleciona horizonte conforme canal
  OPEN c_horizonte(p_canal);
  FETCH c_horizonte
  INTO w_horizonte;
  CLOSE c_horizonte;

  --Se nao existir para o canal passado seleciona o valor default
  IF w_horizonte IS NULL THEN
    --Seleciona o valor default
    OPEN c_horizonte('DEFAULT');
    FETCH c_horizonte
    INTO w_horizonte;
    CLOSE c_horizonte;
  END IF;

  RETURN(w_horizonte);

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o horizonte.'||SQLERRM);
END fnd_horizonte;


--**************************************************************************
--Objetivo: seleciona o percentual disponivel de saldo
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_percentual_dispo RETURN NUMBER IS

CURSOR c_percentual_dispo IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 2 --Percentual Disponibilidade
  AND    lookup_type         = 'ONT_ATP_PARAMETRO_SALDO_PB';

w_percentual_dispo NUMBER;
BEGIN

  --Seleciona horizonte conforme canal
  OPEN c_percentual_dispo;
  FETCH c_percentual_dispo
  INTO w_percentual_dispo;
  CLOSE c_percentual_dispo;

  RETURN(w_percentual_dispo);

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o percentual de disponibilidade do saldo.'||SQLERRM);
END fnd_percentual_dispo;


--**************************************************************************
--Objetivo: seleciona o Horizonte de carteira a ser atendido pela produ??o planejada.
--
--
--Autor: Marcus Vinicius Peixer Gatis
--Data: 10/04/2020
--**************************************************************************
FUNCTION fnd_horizonte_carteira RETURN NUMBER IS

CURSOR c_horizonte_carteira IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 4 --Horizonte da Carteira
  AND    lookup_type         = 'ONT_ATP_PARAMETRO_SALDO_PB';

w_horizonte_carteira NUMBER;
BEGIN

  --Seleciona horizonte da Carteira
  OPEN c_horizonte_carteira;
  FETCH c_horizonte_carteira
  INTO w_horizonte_carteira;
  CLOSE c_horizonte_carteira;

  RETURN(w_horizonte_carteira);

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o Horizonte da Carteira.'||SQLERRM);
end fnd_horizonte_carteira;

--**************************************************************************
--Objetivo: seleciona a quantidade de períodos que devem ser considerados
--          no calculo do saldo do produto
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_qtd_periodo RETURN NUMBER IS

CURSOR c_periodo IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 1 --Periodos Válidos
  AND    lookup_type         = 'ONT_ATP_PARAMETRO_SALDO_PB';

w_qt_periodo NUMBER;
BEGIN

  --Seleciona a quantidade de períodos
  OPEN c_periodo;
  FETCH c_periodo
  INTO w_qt_periodo;
  CLOSE c_periodo;

  RETURN(w_qt_periodo);

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar os períodos válidos.'||SQLERRM);
END fnd_qtd_periodo;

--**************************************************************************
--Objetivo: seleciona a quantidade de períodos que devem ser considerados
--          no calculo do saldo do produto
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_grupo_horizonte_saldo RETURN NUMBER IS

CURSOR c_grupo_horizonte IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 3 --Grupo saldo Horizonte valido
  AND    lookup_type         = 'ONT_ATP_PARAMETRO_SALDO_PB';

w_cd_grupo_horizonte NUMBER;
BEGIN

  --Seleciona o grupo de horizonte de saldo
  OPEN c_grupo_horizonte;
  FETCH c_grupo_horizonte
  INTO w_cd_grupo_horizonte;
  CLOSE c_grupo_horizonte;

  RETURN(w_cd_grupo_horizonte);

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o grupo de horizonte válido.'||SQLERRM);
END fnd_grupo_horizonte_saldo;


--**************************************************************************
--Objetivo: seleciona a data final do período informado
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_data_fim_periodo (p_id_periodo IN NUMBER)RETURN DATE IS

--Seleciona os dias do período
CURSOR c_periodo IS
  SELECT flv.attribute3
  FROM   fnd_lookup_values flv
  WHERE  flv.language            = userenv('LANG')
  AND    flv.enabled_flag        = 'Y'
  AND    flv.security_group_id   = 0
  AND    flv.view_application_id = 660
  AND    flv.attribute1          = p_id_periodo
  AND    flv.tag                 = omp12001jb.fnd_grupo_horizonte_saldo
  AND    flv.lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_PB';

w_qt_dia_periodo NUMBER;
w_dt_final_periodo DATE;

BEGIN
  --Seleciona a quantidade de períodos
  OPEN c_periodo;
  FETCH c_periodo
  INTO w_qt_dia_periodo;
  CLOSE c_periodo;

  --Verifica se encontrou dias para o período
  IF nvl(w_qt_dia_periodo,0) > 0 THEN
    w_dt_final_periodo := trunc(SYSDATE) + w_qt_dia_periodo;
  ELSE
    w_dt_final_periodo := NULL;
  END IF;

  RETURN(w_dt_final_periodo);

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar data final do período.'||SQLERRM);
END fnd_data_fim_periodo;


--**************************************************************************
--Objetivo: classifica em qual período do horizonte de saldo a data passado
--          como parâmetro se enquadra
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_periodo (p_dt_dmf IN date)RETURN NUMBER IS

--Seleciona o periodo conforme os dias de DMF
CURSOR c_periodo (p_dia_dmf IN NUMBER) IS
  SELECT flv.attribute1
  FROM   fnd_lookup_values flv
  WHERE  flv.language               = userenv('LANG')
  AND    flv.enabled_flag           = 'Y'
  AND    flv.security_group_id      = 0
  AND    flv.view_application_id    = 660
  AND    to_number(flv.attribute2)  < p_dia_dmf
  AND    to_number(flv.attribute3) >= p_dia_dmf
  AND    to_number(flv.attribute1) <= omp12001jb.fnd_qtd_periodo
  AND    flv.tag                    = omp12001jb.fnd_grupo_horizonte_saldo
  AND    flv.lookup_type            = 'ONT_ATP_HORIZONTE_SALDO_PB';

w_qt_periodo NUMBER;
w_dia_dmf    NUMBER;
BEGIN

  --Calcula a quantidade de dias do DMF
  w_dia_dmf := trunc(p_dt_dmf) - trunc(SYSDATE);

  --Seleciona a quantidade de períodos
  OPEN c_periodo(w_dia_dmf);
  FETCH c_periodo
  INTO w_qt_periodo;
  CLOSE c_periodo;

  --Quando nao encontrar periodo assumir 999
  IF w_qt_periodo IS NULL THEN
    w_qt_periodo := 999;
  END IF;

  RETURN(w_qt_periodo);

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar classificar o período.'||SQLERRM);
END fnd_periodo;

--**************************************************************************
--Objetivo: Manter a rotina com menor quantidade de parâmetros funcionando sem 
--          necessidade de informar quantidade em carteira.
--          
--
--Autor: Alexandre Oliveira
--Data: 21/09/2020
--**************************************************************************
FUNCTION fnd_estoque_dispo (p_inventory_item_id IN NUMBER,
                            p_organization_id   IN NUMBER,
                            p_qtd               IN NUMBER,
                            p_canal             IN VARCHAR2,
                            p_header_id         IN NUMBER) RETURN VARCHAR2 IS
  w_dispo char(1);
begin
  --
  w_dispo := fnd_estoque_dispo (p_inventory_item_id => p_inventory_item_id,
                                p_organization_id   => p_organization_id,
                                p_qtd               => p_qtd,
                                p_canal             => p_canal,
                                p_header_id         => p_header_id,
                                p_carteira          => null);

  return (w_dispo);


EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o estoque disponível 01.'||SQLERRM);
END fnd_estoque_dispo;

--**************************************************************************
--Objetivo: verifica se para o produto existe estoque disponivel. Essa
--          rotina é utilizada no calculo da data de promessa. O retorno
--          da rotina é:
--          - Y -> possui estoque
--          - N -> não possui estoque
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_estoque_dispo (p_inventory_item_id IN NUMBER,
                            p_organization_id   IN NUMBER,
                            p_qtd               IN NUMBER,
                            p_canal             IN VARCHAR2,
                            p_header_id         IN NUMBER,
                            p_carteira          IN NUMBER) RETURN VARCHAR2 IS
--Seleciona o código do produto
CURSOR c_item IS
  SELECT segment1
  FROM   mtl_system_items_b
  WHERE  organization_id   = p_organization_id
  AND    inventory_item_id = p_inventory_item_id;

--Seleciona o deposito do produto
CURSOR c_deposito IS
  SELECT organization_code
  FROM   org_organization_definitions
  WHERE  organization_id   = p_organization_id;

--Seleciona o lote do produto
CURSOR c_lote (w_cod_produto_ora varchar2, w_cod_deposito varchar2) IS
  SELECT DISTINCT cod_tonalidade_calibre,
                  sub_lote
  FROM   sig_saldo_estoque_apo_v
  WHERE  qtd_disponivel  > 0
  AND    status          = 'LIB'
  AND    cod_deposito    = w_cod_deposito
  AND    cod_produto_ora = w_cod_produto_ora
  ORDER BY cod_tonalidade_calibre;
--
CURSOR c_saldo_total IS
  SELECT sum(QTD_DISPONIVEL) QTD_DISPONIVEL
  FROM   sig_saldo_estoque_apo_v      sig
  JOIN mtl_system_items_b           mtl ON sig.cod_produto_ora = mtl.segment1
                                            AND organization_id = pb_master_organization_id
  JOIN org_organization_definitions org ON sig.cod_deposito = org.organization_code
  WHERE  qtd_disponivel      > 0
  AND    status              = 'LIB'
  AND org.organization_id    = p_organization_id
  AND mtl.inventory_item_id  = p_inventory_item_id;

v_tipo_reserva  VARCHAR2(100);
w_disponivel    NUMBER;
w_saldo_total   number;

BEGIN
  --Identifica o tipo de reserva
  v_tipo_reserva := omp12001jb.fnd_tipo_reserva(p_canal     => p_canal,
                                                p_header_id => p_header_id);
  --
  if p_carteira is not null then
    --
    -- Valida total em carteira antes de retornar estoque disponível sim ou não.
    open c_saldo_total;
    fetch c_saldo_total into w_saldo_total;
    close c_saldo_total;
    --
    if w_saldo_total < (p_carteira + p_qtd) then
      --
      return ('N');
      --
    end if;
    --
  end if;

  for r_deposito in c_deposito loop
    --
    for r_item in c_item loop
      --
      for r_lote in c_lote (r_item.segment1,r_deposito.organization_code) loop
        --
        w_disponivel := pb_saldo_disponivel_produto ( r_item.segment1               --p_cd_produto
                                                      ,r_deposito.organization_code  --p_cd_deposito
                                                      ,r_lote.cod_tonalidade_calibre --p_lote
                                                      ,r_lote.sub_lote               --p_sublote
                                                      ,'O'                           --p_verifica_reserva
                                                      ,v_tipo_reserva                --p_tipo_reserva
                                                      );

        IF p_carteira is not null then 
          --
          if w_disponivel >= p_qtd then
            --
            vg_saldo_estoque := w_disponivel;
            return 'Y';
            --
          end if;
          --
        else 

          if w_disponivel >= p_qtd then
            --
            vg_saldo_estoque := w_disponivel;
            return 'Y';
            --
          end if;
          --
        end if;
        --
      end loop;
      --
    end loop;
    --
  end loop;
  --
  return 'N';
  --
EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o estoque disponível 02.'||SQLERRM);
END fnd_estoque_dispo;


--**************************************************************************
--Objetivo: retorna a data de PPE. Como regra é data atual + dias de PPE
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_data_ppe (p_inventory_item_id  IN NUMBER,
                       p_sales_channel_code IN VARCHAR2) RETURN DATE IS

w_qt_dia_ppe NUMBER;
BEGIN
  --
  IF p_sales_channel_code = '4' THEN
    --
    w_qt_dia_ppe := omp003apo.converte(pbpkgont01.valida_prazo('DIAS_VIP',p_inventory_item_id));
    --
  ELSE
    --
    w_qt_dia_ppe := omp003apo.converte(pbpkgont01.valida_prazo('DIAS',p_inventory_item_id));
    --
  END IF;

  --Calcula a data de PPE
  RETURN (sysdate + nvl(w_qt_dia_ppe,0));

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar a data PPE.'||SQLERRM);
END fnd_data_ppe;


--**************************************************************************
--Objetivo: retorna a data de PPE. Como regra é data atual + dias de PPE
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--
--Alteração: incluido o parametro p_sales_channel_code
--Autor: Danilo Kramel - JB
--Data: 12/05/2014
--
--**************************************************************************
FUNCTION fnd_saldo_produto (p_inventory_item_id  IN NUMBER,
                            p_item_um            IN VARCHAR2,
                            p_id_periodo         IN NUMBER,
                            p_sales_channel_code IN VARCHAR2) RETURN NUMBER IS

--Seleciona o saldo do produto
--Retira da validacao com a lookup_type = 'ONT_ATP_PRODUTO_LIBERADO_PB'
--conforme solicitado pela Maicon em 03/02/2014
-- Tabela populada pela funcion "PRC_CARGA_SALDO" desta Package
CURSOR c_saldo IS
  SELECT decode(p_sales_channel_code, '4',qt_saldo_disponivel_pbshop,qt_saldo_disponivel)
  FROM om_saldo_produto_atp_jb spa
  WHERE spa.id_periodo        = p_id_periodo
  AND   spa.item_um           = p_item_um
  AND   spa.inventory_item_id = p_inventory_item_id;

w_qt_saldo_produto NUMBER;

BEGIN

  --Seleciona o saldo do Produto
  OPEN c_saldo;
  FETCH c_saldo
  INTO w_qt_saldo_produto;
  CLOSE c_saldo;

  RETURN (nvl(w_qt_saldo_produto,0));

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o saldo produto.'||SQLERRM);
END fnd_saldo_produto;


--**************************************************************************
--Objetivo: para o canal pbshop identifica a proxima data de saida conforme
--          os parâmetros passados
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_agenda (p_id_agenda   IN NUMBER,
                     p_dt_promessa IN DATE) RETURN DATE IS

--Seleciona a transp e agenda
CURSOR c_transp IS
  SELECT ata.cd_agenda,
         ata.id_transp
  FROM ont_agenda_transp_apo ata
  WHERE ata.id_agenda = p_id_agenda;

--Seleciona a proxima data de saida conforme transp e agenda
CURSOR c_agenda (p_cd_agenda   IN VARCHAR2,
                 p_id_transp   IN NUMBER,
                 p_dt_promessa IN DATE) IS
  SELECT ata.dt_saida
  FROM ont_agenda_transp_apo ata
  WHERE trunc(ata.dt_saida)  >= trunc(p_dt_promessa)
  AND   ata.id_transp         = p_id_transp
  AND   ata.cd_agenda         = p_cd_agenda
  ORDER BY ata.dt_saida;

w_cd_agenda VARCHAR2(10);
w_id_transp NUMBER;
w_dt_saida  DATE;

BEGIN

  --Seleciona a transportadora
  OPEN c_transp;
  FETCH c_transp
  INTO w_cd_agenda,
       w_id_transp;
  CLOSE c_transp;

  --Seleciona a proxima data de saida conforme transp e agenda
  OPEN c_agenda(w_cd_agenda,
                w_id_transp,
                p_dt_promessa);
  FETCH c_agenda
  INTO w_dt_saida;
  CLOSE c_agenda;

  RETURN (nvl(w_dt_saida,p_dt_promessa));

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao seleciona a agenda.'||SQLERRM);
END fnd_agenda;


--**************************************************************************
-- Objetivo: Manter a chamada da função conforme desenvolvimento original,
--        com apenas dois parâmetros.
--
-- Autor: Alexandre Oliveira
-- Chamado: 131546
--**************************************************************************
FUNCTION fnd_maior_data (p_header_id      IN NUMBER,
                         p_dt_promessa    IN DATE ) RETURN DATE IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  RETURN(omp12001jb.fnd_maior_data(
    p_header_id
    , p_dt_promessa
    , NULL
    , 'DP'
  ));

END;


--**************************************************************************
--Objetivo: atualiza todas a linhas do pedido com a maior data quando a
--          possui fatuamento total = SIM.
--
--   p_data_atualiza = DMF ou DP
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
-- Atualizado por: Alexandre Oliveira
-- Chamado: 131546 - Calcular DMF
--**************************************************************************
FUNCTION fnd_maior_data (p_header_id      IN NUMBER,
                         p_dt_promessa    IN DATE,
                         p_dt_dmf         IN DATE,
                         p_data_atualiza  IN VARCHAR2 ) RETURN DATE IS


--Seleciona a maior data das linhas quando o faturamento parcial = não
CURSOR c_maior_data IS
  SELECT max(omp12001jb.fnd_data_promessa_item(p_inventory_item_id  => ola.inventory_item_id,
                                               p_organization_id    => ola.ship_from_org_id,
                                               p_primary_uom_code   => ola.order_quantity_uom,
                                               p_qt_item            => ola.ordered_quantity,
                                               p_dt_dmf             => ola.schedule_ship_date,
                                               p_sales_channel_code => oha.sales_channel_code,
                                               p_header_id          => oha.header_id,
                                               p_id_agenda          => oha.attribute20,
                                               p_id_fat_total       => 'N',
                                               p_id_familia         => ola.attribute9,
                                               p_id_calibre         => ola.attribute7,
                                               p_id_grupo           => ola.attribute15))
  FROM oe_order_lines_all   ola,
       oe_order_headers_all oha
  WHERE ola.cancelled_flag  = 'N'
  AND   ola.org_id          = oha.org_id
  AND   ola.header_id       = oha.header_id
  AND   oha.cancelled_flag  = 'N'
  AND   oha.header_id       = p_header_id;

--Seleciona a maior data das linhas quando o faturamento parcial = não
-- Produos fora da lista CE ou na lista mas com saldo em estoque.
CURSOR c_maior_dmf IS
  SELECT max(omp12001jb.fnd_data_promessa_item( p_inventory_item_id   => ola.inventory_item_id,
                                                p_organization_id     => ola.ship_from_org_id,
                                                p_primary_uom_code    => ola.order_quantity_uom,
                                                p_qt_item             => ola.ordered_quantity,
                                                p_dt_dmf              => ola.schedule_ship_date,
                                                p_sales_channel_code  => oha.sales_channel_code,
                                                p_header_id           => oha.header_id,
                                                p_id_agenda           => oha.attribute20,
                                                p_id_fat_total        => 'N',
                                                p_id_familia          => ola.attribute9,
                                                p_id_calibre          => ola.attribute7,
                                                p_id_grupo            => ola.attribute15,
                                                p_data_retorno        => 'DMF',
                                                p_line_id             => ola.line_id,
                                                p_dmf_old             => ola.schedule_ship_date,
                                                p_dp_old              => Trunc(Nvl(To_Date(ola.attribute17, 'DD/MM/RRRR'), SYSDATE)),
                                                p_ddc_old             => ola.request_date,
                                                p_ddc_new             => ola.request_date,
                                                p_grava_historico     => 'N',
                                                p_order_source_id     => ola.order_source_id ))
  FROM oe_order_lines_all               ola
  JOIN oe_order_headers_all             oha   ON ola.header_id       = oha.header_id
  JOIN apps.consulta_produto_pb_v       pro   ON ola.inventory_item_id = pro.item_id
  JOIN org_organization_definitions     org   ON ola.ship_from_org_id = org.organization_id
  left JOIN FND_LOOKUP_VALUES_VL        flok  ON  flok.lookup_type        = 'ONT_ATP_PRODUTOS_CALCULA_DMF'
                                                  AND flok.ENABLED_FLAG   = 'Y'
                                                  AND Trunc(SYSDATE)      BETWEEN Trunc(Nvl(flok.start_date_active, SYSDATE)) AND Trunc(Nvl(flok.end_date_active, SYSDATE))
                                                  AND pro.cod_produto         = flok.description
                                                  and oha.sales_channel_code  = flok.TAG
  WHERE ola.cancelled_flag  = 'N'
    AND ola.org_id          = oha.org_id
    AND oha.cancelled_flag  = 'N'
    AND oha.header_id       = p_header_id
    -- only products outside the CE list.
    -- or in the list but with stock
    AND ( flok.meaning        IS NULL
          OR
          ( flok.meaning        IS NOT NULL
            AND pb_saldo_disponivel_produto ( pro.cod_produto               --p_cd_produto
                    , org.organization_code       --p_cd_deposito
                    , NULL                        --p_lote
                    , NULL                        --p_sublote
                    , 'O'                          --p_verifica_reserva
                    , omp12001jb.fnd_tipo_reserva(p_canal     => oha.sales_channel_code,
                                                  p_header_id => ola.header_id )         --p_tipo_reserva
                  )                                                                                             > ola.ordered_quantity


          )
      );

-- Maior DMF independente se o produto está ou não na lista CE.
CURSOR c_maior_dmf_geral IS
  SELECT max(omp12001jb.fnd_data_promessa_item( p_inventory_item_id   => ola.inventory_item_id,
                                                p_organization_id     => ola.ship_from_org_id,
                                                p_primary_uom_code    => ola.order_quantity_uom,
                                                p_qt_item             => ola.ordered_quantity,
                                                p_dt_dmf              => ola.schedule_ship_date,
                                                p_sales_channel_code  => oha.sales_channel_code,
                                                p_header_id           => oha.header_id,
                                                p_id_agenda           => oha.attribute20,
                                                p_id_fat_total        => 'N',
                                                p_id_familia          => ola.attribute9,
                                                p_id_calibre          => ola.attribute7,
                                                p_id_grupo            => ola.attribute15,
                                                p_data_retorno        => 'DMF',
                                                p_line_id             => ola.line_id,
                                                p_dmf_old             => ola.schedule_ship_date,
                                                p_dp_old              => Trunc(Nvl(To_Date(ola.attribute17, 'DD/MM/RRRR'), SYSDATE)),
                                                p_ddc_old             => ola.request_date,
                                                p_ddc_new             => ola.request_date,
                                                p_grava_historico     => 'N',
                                                p_order_source_id     => ola.order_source_id ))
  FROM oe_order_lines_all               ola
  JOIN oe_order_headers_all             oha   ON ola.header_id       = oha.header_id
  WHERE ola.cancelled_flag  = 'N'
    AND ola.org_id          = oha.org_id
    AND oha.cancelled_flag  = 'N'
    AND oha.header_id       = p_header_id;



w_dt_promessa DATE;
w_dt_dmf      DATE;

PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  IF Nvl(p_data_atualiza, 'DP') = 'DMF' THEN
    w_dt_dmf := null;
    --Seleciona o maior DMF da ordem
    OPEN c_maior_dmf;
    FETCH c_maior_dmf INTO w_dt_dmf;
    CLOSE c_maior_dmf;

    IF w_dt_dmf IS NULL THEN

      OPEN c_maior_dmf_geral;
      FETCH c_maior_dmf_geral INTO w_dt_dmf;
      CLOSE c_maior_dmf_geral;

      IF w_dt_dmf IS NULL THEN
        w_dt_dmf := p_dt_dmf;
      end if;

    END IF;

    RETURN (w_dt_dmf);
    --
  ELSE
    --Seleciona o maior data da ordem
    OPEN c_maior_data;
    FETCH c_maior_data
    INTO w_dt_promessa;
    CLOSE c_maior_data;

    IF w_dt_promessa IS NULL THEN
      w_dt_promessa := p_dt_promessa;
    END IF;

    RETURN (w_dt_promessa);
    --
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar a maior data da ordem.'||SQLERRM);
END fnd_maior_data;

--**************************************************************************
-- Objetivo: Retorna a maior DMF COVID para ajuste nas linhas da OV
-- Linhas na lista CE desde que sem saldo em estoque para atender a linha da ordem.
--
-- Autor: Alexandre Oliveira
-- 22/04/2020 - Chamado: 131546
--**************************************************************************
FUNCTION fnd_maior_data_covid (p_header_id IN NUMBER) RETURN DATE is
  CURSOR c_maior_dmf_covid( p_header IN NUMBER ) IS
          SELECT --schedule_ship_date,
        Max(omp12001jb.prd_ajusta_dmf(p_inventory_item_id   => ite.inventory_item_id
                                    , p_dmf                 => ol.schedule_ship_date
                                    , p_sales_channel       => oh.sales_channel_code
                                    , p_line_id             => ol.line_id
                                    , p_order_source_id     => ol.order_source_id
                                    , p_organization_id     => ol.ship_from_org_id
                                    , p_header_id           => ol.header_id
          ))                                                                       dmf_covid
      FROM oe_order_lines_all               ol
      JOIN oe_order_headers_all             oh  ON ol.header_id = oh.header_id
      JOIN mtl_system_items_b               ite ON ol.inventory_item_id  = ite.inventory_item_id
                                                   AND organization_id   = pb_master_organization_id
      JOIN org_organization_definitions     org  ON ol.ship_from_org_id = org.organization_id
      JOIN FND_LOOKUP_VALUES_VL             flok ON ite.segment1               = flok.description
                                                    and oh.sales_channel_code  = flok.TAG
                                                    AND flok.lookup_type    = 'ONT_ATP_PRODUTOS_CALCULA_DMF'
                                                    AND flok.ENABLED_FLAG   = 'Y'
                                                    AND Trunc(SYSDATE)      BETWEEN Trunc(Nvl(flok.start_date_active, SYSDATE)) AND Trunc(Nvl(flok.end_date_active, SYSDATE))

      WHERE oh.header_id = p_header
       AND pb_saldo_disponivel_produto ( ite.segment1               --p_cd_produto
                    , org.organization_code       --p_cd_deposito
                    , NULL                        --p_lote
                    , NULL                        --p_sublote
                    , 'O'                          --p_verifica_reserva
                    , omp12001jb.fnd_tipo_reserva(p_canal     => oh.sales_channel_code,
                                                  p_header_id => ol.header_id )         --p_tipo_reserva
                  )                                                                                             < ol.ordered_quantity;
/*    SELECT --schedule_ship_date,
        Max(omp12001jb.prd_ajusta_dmf(p_inventory_item_id   => ite.inventory_item_id
                                    , p_dmf                 => ol.schedule_ship_date
                                    , p_sales_channel       => oh.sales_channel_code
                                    , p_line_id             => ol.line_id
                                    , p_order_source_id     => ol.order_source_id
                                    , p_organization_id     => ol.ship_from_org_id
                                    , p_header_id           => ol.header_id
          ))                                                                       dmf_covid
      FROM oe_order_lines_all     ol
      JOIN oe_order_headers_all   oh   ON ol.header_id = oh.header_id
      JOIN mtl_system_items_b     ite  ON ol.inventory_item_id  = ite.inventory_item_id
                                          AND organization_id   = 43
      JOIN FND_LOOKUP_VALUES_VL   flok ON ite.segment1               = flok.description
                                          and oh.sales_channel_code  = flok.TAG
                                          AND flok.lookup_type    = 'ONT_ATP_PRODUTOS_CALCULA_DMF'
                                          AND flok.ENABLED_FLAG   = 'Y'
                                          AND Trunc(SYSDATE)      BETWEEN Trunc(Nvl(flok.start_date_active, SYSDATE)) AND Trunc(Nvl(flok.end_date_active, SYSDATE))

      WHERE oh.header_id = p_header;*/
  --
  w_maior_dmf_covid   DATE;
  --
PRAGMA AUTONOMOUS_TRANSACTION;
--
BEGIN
  w_maior_dmf_covid := NULL;
  --
  OPEN c_maior_dmf_covid(p_header => p_header_id);
  FETCH c_maior_dmf_covid INTO w_maior_dmf_covid;
  --
  CLOSE c_maior_dmf_covid;

  RETURN(w_maior_dmf_covid);

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar a maior DMF. ' || SQLERRM);
END fnd_maior_data_covid;


--**************************************************************************
--Objetivo: retorna a data de promessa para o item conforme os dados passados
--          como parâmetro
-- Chama a função fnd_data_promessa_item com 13 parâmetros adicionando o valor DP para o p_data_retorno
-- Autor: Alexandre Oliveira.
-- Data: 23/04/2020
--**************************************************************************
FUNCTION fnd_data_promessa_item (p_inventory_item_id  IN NUMBER,
                                 p_organization_id    IN NUMBER,
                                 p_primary_uom_code   IN VARCHAR2,
                                 p_qt_item            IN NUMBER,
                                 p_dt_dmf             IN DATE,
                                 p_sales_channel_code IN VARCHAR2,
                                 p_header_id          IN NUMBER,
                                 p_id_agenda          IN NUMBER,
                                 p_id_fat_total       IN VARCHAR2,
                                 p_id_familia         IN VARCHAR2,
                                 p_id_calibre         IN VARCHAR2,
                                 p_id_grupo           IN VARCHAR2 ) RETURN DATE IS

BEGIN
  RETURN omp12001jb.fnd_data_promessa_item (p_inventory_item_id  => p_inventory_item_id,
                                            p_organization_id    => p_organization_id,
                                            p_primary_uom_code   => p_primary_uom_code,
                                            p_qt_item            => p_qt_item,
                                            p_dt_dmf             => p_dt_dmf,
                                            p_sales_channel_code => p_sales_channel_code,
                                            p_header_id          => p_header_id,
                                            p_id_agenda          => p_id_agenda,
                                            p_id_fat_total       => p_id_fat_total,
                                            p_id_familia         => p_id_familia,
                                            p_id_calibre         => p_id_calibre,
                                            p_id_grupo           => p_id_grupo,
                                            p_data_retorno       => 'DP',
                                            p_line_id            => NULL,
                                            p_dmf_old            => NULL,
                                            p_dp_old             => NULL,
                                            p_ddc_old            => NULL,
                                            p_ddc_new            => NULL,
                                            p_grava_historico    => 'N',
                                            p_order_source_id    => NULL
                                            );
END;

--**************************************************************************
--Objetivo: retorna a data de promessa para o item conforme os dados passados
--          como parâmetro
--
-- Parâmetros
--      - p_inventory_item_id  => código do produto
--      - p_organization_id    => organização
--      - p_primary_uom_code   => unidade de medida do item
--      - p_qt_item            => quantidade do produto informada na Ordem Venda
--      - p_dt_dmf             => data de DMF do produto informada na Ordem Venda
--      - p_sales_channel_code => canal de venda da ordem pode ser opcional quando
--                                o número do pedido for informado.
--      - p_header_id          => código da ordem de venda, quando chamado do iVop ou
--                                Microvix esse valor será nulo.
--      - p_id_agenda          => indicador do código de agenda. Esse informação existe
--                                somente para o Oracle e Microvix
--      - p_id_maior_data      => possui valor "S" ou "N" e identifica se a ordem possui
--                                faturamento total ou parcial. Para
--                                origens Microvix e iVop o valor deve ser "N"
--      - p_id_familia         => valor da família para o produto
--      - p_id_calibre         => valor do calibre para o produto
--      - p_id_grupo           => valor do grupo para o produto
--
--Autor: Danilo Kramel - JB
--Data: 16/08/2013
--**************************************************************************
FUNCTION fnd_data_promessa_item (p_inventory_item_id  IN NUMBER,
                                 p_organization_id    IN NUMBER,
                                 p_primary_uom_code   IN VARCHAR2,
                                 p_qt_item            IN NUMBER,
                                 p_dt_dmf             IN DATE,
                                 p_sales_channel_code IN VARCHAR2,
                                 p_header_id          IN NUMBER,
                                 p_id_agenda          IN NUMBER,
                                 p_id_fat_total       IN VARCHAR2,
                                 p_id_familia         IN VARCHAR2,
                                 p_id_calibre         IN VARCHAR2,
                                 p_id_grupo           IN VARCHAR2,
                                 p_data_retorno       IN VARCHAR2,
                                 p_line_id            IN NUMBER,
                                 p_dmf_old            IN DATE,
                                 p_dp_old             IN DATE,
                                 p_ddc_old            IN DATE,
                                 p_ddc_new            IN DATE,
                                 p_grava_historico    IN VARCHAR2,
                                 p_order_source_id    IN NUMBER                                  ) RETURN DATE IS

cursor c_produto_lista_ce is
  select 'Y'
  from FND_LOOKUP_VALUES_VL                  flok
  JOIN apps.consulta_produto_pb_v       pro   ON flok.description = pro.cod_produto
  where flok.lookup_type    = 'ONT_ATP_PRODUTOS_CALCULA_DMF'
    AND flok.ENABLED_FLAG   = 'Y'
    AND Trunc(SYSDATE)      BETWEEN Trunc(Nvl(flok.start_date_active, SYSDATE)) AND Trunc(Nvl(flok.end_date_active, SYSDATE))
    and flok.TAG            = p_sales_channel_code
    and pro.item_id         = p_inventory_item_id;
--
w_produto_lista_ce     char(1);

w_erro               EXCEPTION;
w_ds_erro            VARCHAR2(4000);

w_qt_dia_lead_time      NUMBER(5);
w_qt_dia_lead_time_otif NUMBER(5);
w_qt_dia_horizonte      NUMBER(5);
w_qt_saldo_produto      NUMBER;
w_dt_ppe                DATE;
w_id_estoque_dispo      VARCHAR2(1);
w_sales_channel_code    VARCHAR2(3);
w_dt_promessa           DATE;
w_id_periodo            NUMBER(4);
w_id_existe_saldo       VARCHAR2(1);
-- Chamado: 131546
w_dt_dmf                DATE;
w_dmf_old               DATE;
w_dp_old                DATE;
w_dp_new                DATE;
w_regra                 VARCHAR2(150);
w_regra_detalhes        VARCHAR2(4000);
w_vg                    CHAR(2);
w_maior_dmf_covid       DATE;
w_saldo_restricao       NUMBER;
w_saldo_disp_rest       VARCHAR2(1);

BEGIN
  -- Chamado 131546
  w_dt_dmf          := p_dt_dmf;
  w_dmf_old         := p_dt_dmf;
  vg_saldo_estoque  := NULL;
  vg_historico_dmf  := '';

  --Seleciona o canal de vendas
  IF p_sales_channel_code IS NULL AND p_header_id IS NULL THEN
    w_ds_erro:= 'Parâmetro de canal de venda ou número da ordem devem ser informados.';
    RAISE w_erro;

  ELSIF p_sales_channel_code IS NOT NULL THEN
    w_sales_channel_code := p_sales_channel_code;

  ELSIF p_header_id IS NOT NULL THEN
    w_sales_channel_code := omp12001jb.fnd_canal_venda(p_header_id => p_header_id);
  END IF;

  --Seleciona as variaveis de controle e dias
  w_qt_dia_lead_time := omp12001jb.fnd_lead_time(p_canal => w_sales_channel_code);
  w_qt_dia_lead_time_otif := omp12001jb.fnd_lead_time_otif(p_canal => w_sales_channel_code);
  w_qt_dia_horizonte := omp12001jb.fnd_horizonte(p_canal => w_sales_channel_code);

  --Seleciona a data de PPE - Dia atual + PPE por canal, "shop e outros".
  w_dt_ppe := omp12001jb.fnd_data_ppe(p_inventory_item_id  => p_inventory_item_id,
                                      p_sales_channel_code => w_sales_channel_code);

  --Verifica se possui estoque disponivel
  -- Alimenta variável global "vg_saldo_estoque" com quantidade encontrada em estoque.
  w_id_estoque_dispo := omp12001jb.fnd_estoque_dispo(p_inventory_item_id => p_inventory_item_id,
                                                     p_organization_id   => p_organization_id,
                                                     p_qtd               => p_qt_item,
                                                     p_canal             => w_sales_channel_code,
                                                     p_header_id         => p_header_id);

  --1 Regra: quando linha possuir informações de familia, grupo ou calibre atribuir
  IF p_id_familia  IS NOT NULL OR p_id_calibre  IS NOT NULL OR  p_id_grupo    IS NOT NULL THEN

    --- Validar saldo disponível para família e cálibre.
    -- Caso tenha saldo, não alterar DMF
    -- Só calcula a DMF se não houver saldo em estoque para atendimento da restrição informada.
    w_saldo_disp_rest := omp12001jb.fnd_saldo_disp_restricao( p_organization_id     => p_organization_id
                                                              , p_inventory_item_id => p_inventory_item_id
                                                              , p_id_familia        => p_id_familia
                                                              , p_id_calibre        => p_id_calibre
                                                              , p_id_grupo          => p_id_grupo
                                                              , p_qtd_ordered       => p_qt_item
                                                              , p_header_id         => p_header_id     );
    IF w_saldo_disp_rest = 'N' THEN
      -- Chamado 131546 - Calcular DMF. Alexandre
      w_dt_dmf          := omp12001jb.prd_ajusta_dmf( p_inventory_item_id   => p_inventory_item_id
                                                      , p_dmf               => p_dt_dmf
                                                      , p_sales_channel     => w_sales_channel_code
                                                      , p_line_id           => p_line_id
                                                      , p_order_source_id   => p_order_source_id
                                                      , p_organization_id   => p_organization_id
                                                      , p_header_id         => p_header_id);
    END IF;
    --
    -- Dados para histórico - Chamado 131546
    w_regra           := 'Regra 01: PPE - Familia, Grupo ou Cálibre';
    w_regra_detalhes  := 'Somente DP Calculada com base no desvio de ';
    w_vg              := '';

    IF To_Date(w_dt_dmf, 'dd/mm/rrrr') <> To_Date(p_dt_dmf, 'dd/mm/rrrr') THEN
      --
      w_regra_detalhes  := 'DMF e DP Calculadas com base no desvio de ';
      --
    END IF;
    --
    IF p_id_familia IS NOT NULL THEN
      --
      w_regra_detalhes  := w_regra_detalhes || 'Família: ' || p_id_familia;
      w_vg              := ', ';
      --
    END IF;
    --
    IF p_id_calibre IS NOT NULL THEN
      --
      w_regra_detalhes  := w_vg || w_regra_detalhes || 'Cálibre: ' || p_id_calibre;
      w_vg              := ', ';
      --
    END IF;
    --
    IF p_id_grupo IS NOT NULL THEN
      --
      w_regra_detalhes := w_vg || w_regra_detalhes || 'Grupo: ' || p_id_grupo;
      --
    END IF;
    --

    -- Atribuir a maior data entre DMF e PPE
    IF p_dt_dmf > w_dt_ppe THEN
      w_dt_promessa := (p_dt_dmf + nvl(w_qt_dia_lead_time_otif,0));
    ELSE
      w_dt_promessa := w_dt_ppe;
    END IF;

  --2 Regra: Com estoque disponivel e dentro do horizonte de DMF
  ELSIF nvl(w_id_estoque_dispo,'N') = 'Y' AND p_dt_dmf <= (trunc(SYSDATE) + nvl(w_qt_dia_horizonte,0)) THEN

    -- Dados para histórico - Chamado 131546
    w_regra           := 'Regra 02: Com saldo em estoque';
    w_regra_detalhes  := 'Não há recálculo da DMF por ter saldo em estoque. '
                          || 'Saldo encontrado: ' || To_Char(vg_saldo_estoque) || ' ' || To_Char(p_primary_uom_code);

    --Maior entre (hoje + leade time) ou DMF +lead time otif
    IF (trunc(SYSDATE) + nvl(w_qt_dia_lead_time,0)) > (p_dt_dmf + nvl(w_qt_dia_lead_time_otif,0)) THEN
      w_dt_promessa := trunc(SYSDATE) +  nvl(w_qt_dia_lead_time,0);
    ELSE
      w_dt_promessa := p_dt_dmf + nvl(w_qt_dia_lead_time_otif,0);

    END IF;

  ELSE
    --3 Regra: Para as linhas do pedido sem estoque disponível ou com DMF Futura

    --Atribui o periodo da linha
    w_id_periodo := omp12001jb.fnd_periodo(p_dt_dmf);
    w_id_existe_saldo := 'N';

    --Percorre os periodos até atender a necessidade da linha caso seja possível
    WHILE w_id_periodo <= omp12001jb.fnd_qtd_periodo AND w_id_existe_saldo = 'N' LOOP

      --Seleciona o saldo do produto mantido pelo processo diário conforme periodo
      w_qt_saldo_produto := omp12001jb.fnd_saldo_produto(p_inventory_item_id  => p_inventory_item_id,
                                                         p_item_um            => p_primary_uom_code,
                                                         p_id_periodo         => w_id_periodo,
                                                         p_sales_channel_code => w_sales_channel_code);
      IF p_qt_item <= w_qt_saldo_produto THEN
        w_id_existe_saldo := 'S';
      ELSE
        w_id_periodo := w_id_periodo + 1;
      END IF;
    END LOOP;

    --Verifica se existe saldo
    IF w_id_existe_saldo = 'S' THEN
      --
      w_regra           := 'Regra 03: Produto com Plano de Produção';
      w_regra_detalhes  := 'DP Calculada com base no Plano de Produção. SEM alterações na DMF.';
      --
      -- Chamado 131546 - Calcular DMF. Alexandre
      -- Conforme regra de negócio, com plano de produção, a DMF tbém deve ser calculada.
      w_dt_dmf:= omp12001jb.prd_ajusta_dmf(p_inventory_item_id  => p_inventory_item_id
                                          , p_dmf               => p_dt_dmf
                                          , p_sales_channel     => w_sales_channel_code
                                          , p_line_id           => p_line_id
                                          , p_order_source_id   => p_order_source_id
                                          , p_organization_id   => p_organization_id
                                          , p_header_id         => p_header_id);

      -- Ajusta detalhes do histórico
      IF To_Date(w_dt_dmf, 'dd/mm/rrrr') <> To_Date(p_dt_dmf, 'dd/mm/rrrr') THEN
        --
        w_regra_detalhes  := 'DMF | DP Calculadas com PPE do produto devido ao plano de produção (' || w_dt_dmf || ').';
        --
      END IF;

      -- Aplica a maior DMF + lead time otif entre a definida na Ordem e a Calculada na prd_ajusta_dmf
--      IF To_Date(p_dt_dmf, 'rrrr-mm-dd') > To_Date(w_dt_dmf, 'rrrr-mm-dd') THEN
--        w_dt_dmf :=  p_dt_dmf + nvl(w_qt_dia_lead_time_otif,0);
--      ELSE
--        w_dt_dmf := w_dt_dmf + nvl(w_qt_dia_lead_time_otif,0);
--      END IF;

      --Quando possui saldo data promessa = final periodo + Lead_time_otif
      w_dt_promessa := omp12001jb.fnd_data_fim_periodo(w_id_periodo) + nvl(w_qt_dia_lead_time_otif,0);

    ELSE
      --
      w_regra           := 'Regra 04: Produto SEM estoque e SEM Plano de Produção';
      w_regra_detalhes  := 'DP Calculada com PPE do produto. SEM alterações na DMF.';
      --
      -- Chamado 131546 - Calcular DMF. Alexandre
      w_dt_dmf:= omp12001jb.prd_ajusta_dmf(p_inventory_item_id  => p_inventory_item_id
                                          , p_dmf               => p_dt_dmf
                                          , p_sales_channel     => w_sales_channel_code
                                          , p_line_id           => p_line_id
                                          , p_order_source_id   => p_order_source_id
                                          , p_organization_id   => p_organization_id
                                          , p_header_id         => p_header_id);

      IF To_Date(w_dt_dmf, 'dd/mm/rrrr') <> To_Date(p_dt_dmf, 'dd/mm/rrrr') THEN
        --
        w_regra_detalhes  := 'DMF | DP Calculadas com PPE do produto sem pp (' || w_dt_dmf || ').';
        --
      END IF;

      --Quando não possui saldo data promessa = maior (DMF,data ppe)
      IF p_dt_dmf > w_dt_ppe THEN
        w_dt_promessa := p_dt_dmf + nvl(w_qt_dia_lead_time_otif,0);
      ELSE
        w_dt_promessa := w_dt_ppe;
      END IF;
    END IF;
  END IF;

  -- Chamado 131546 - Alexandre
  -- Caso a data solicitada na ordem seja maior que a calculada, manter a dmf digitada.
  IF Trunc(To_Date(p_dt_dmf, 'dd/mm/rrrr'))       <> Trunc(To_Date(w_dt_dmf, 'dd/mm/rrrr'))
      AND Trunc(To_Date(p_dt_dmf, 'dd/mm/rrrr'))  > Trunc(To_Date(w_dt_dmf, 'dd/mm/rrrr'))
      AND vg_usa_maior_dmf                        = 'Y'                                   THEN
    --
    w_dt_dmf := p_dt_dmf;
    --
  END IF;

  --Regra: Data de promessa calculada nao pode ser menor que data de DMF da linha
  IF w_dt_promessa < p_dt_dmf THEN
    w_dt_promessa := p_dt_dmf + nvl(w_qt_dia_lead_time_otif,0);
  END IF;

  IF Trunc(To_Date(p_dt_dmf, 'dd/mm/rrrr')) <> Trunc(To_Date(w_dt_dmf, 'dd/mm/rrrr'))
      AND To_Date(w_dt_promessa, 'dd/mm/rrrr') < To_Date(w_dt_dmf, 'dd/mm/rrrr') THEN
    --
    w_dt_promessa := w_dt_dmf + nvl(w_qt_dia_lead_time_otif,0);
    --
  END IF;

  --Regra: Quando for canal PBShop selecionar a data de disponibilida igual ou
  --superior a data promessa calculada
  IF p_sales_channel_code = 4 AND p_id_agenda IS NOT NULL THEN
    w_dt_promessa := omp12001jb.fnd_agenda(p_id_agenda   => p_id_agenda,
                                           p_dt_promessa => w_dt_promessa);

    -- Ajusta DMF de acordo com a agenda da loja
    -- Chamado: 131546 - 22/04/2020 - Alexandre
    w_dt_dmf      := omp12001jb.fnd_agenda(p_id_agenda   => p_id_agenda,
                                           p_dt_promessa => w_dt_dmf);
  END IF;

  --Regra: para ordens de faturamento parcial = não igualar todas as linhas
  --       com a maior data calculada para as linhas da ordem
  IF nvl(p_id_fat_total,'N') = 'S' AND p_header_id IS NOT NULL THEN
    w_dt_promessa := fnd_maior_data(p_header_id, w_dt_promessa);
  END IF;

  w_produto_lista_ce := null;
  --
  open c_produto_lista_ce;
  fetch c_produto_lista_ce into w_produto_lista_ce;
  close c_produto_lista_ce;







  -- Chamado: 131546 - 22/04/2020 - Alexandre
  -- Atualiza as linhas com maior DMF se ordem ship.
  IF nvl(p_id_fat_total,'N')  = 'S'
      AND p_header_id         IS NOT NULL
      AND vg_usa_maior_dmf    = 'Y'         
      --
      -- Só ajusta maior DMF se NÿO for um CE - OU - se for um CE com saldo em estoque.
      AND ( nvl(w_produto_lista_ce, 'N') = 'N'
            OR ( nvl(w_id_estoque_dispo, 'N') = 'Y' 
                 and nvl(w_produto_lista_ce, 'N') = 'Y'
            )
      )
      --
      THEN
    --
    -- Com a nova definição de que pode haver mais de uma dmf na ordem
    -- quando ela está com faturamento total, este desvio parece ter perdido o sentido.
    --
    /*w_produto_lista_ce := null;
    --
    open c_produto_lista_ce;
    fetch c_produto_lista_ce into w_produto_lista_ce;
    close c_produto_lista_ce;*/
    --
    if nvl(w_id_estoque_dispo, 'N') = 'N' and nvl(w_produto_lista_ce, 'N') = 'Y'  then
      --
      -- If the product is on the CE list and has no stock, it's necessary to calculate the date with PPE.
      -- Conforme retorno por e-mail da Rainara dia 04/11/2020, a data dos produtos lista CE não podem ser emparelhadas. 
      w_dt_dmf := w_dt_dmf; -- Nvl(omp12001jb.fnd_maior_data_covid(p_header_id => p_header_id), w_dt_dmf);
      --
    else
      --
      -- I needed to put the current date
      -- If I put the calculated DP, the DMF wil be calculated as covid dmf.
      -- Here the DMF will be calculated for products on the CE list with stock or products outside the CE list
      w_dt_dmf := Nvl(omp12001jb.fnd_maior_data(
        p_header_id
        , sysdate -- w_dt_promessa
        , p_dt_dmf
        , 'DMF'
      ), w_dt_dmf);
      --
    end if;

  /*ELSIF nvl(p_id_fat_total,'N') = 'S'
        AND p_header_id         IS NOT NULL THEN
    --
    w_maior_dmf_covid := omp12001jb.fnd_maior_data_covid(p_header_id => p_header_id);

    IF w_maior_dmf_covid IS NULL THEN
      --
      w_dt_dmf := omp12001jb.fnd_maior_data(
        p_header_id
        , w_dt_promessa
        , p_dt_dmf
        , 'DMF'
      );
      --
    ELSE
      --
      w_dt_dmf := w_maior_dmf_covid;
      --
    END IF;*/

  END IF;
  --

  if w_dt_dmf is null then
    --
    w_dt_dmf := p_dt_dmf;
    --
    vg_historico_dmf := vg_historico_dmf || ' (dmf calculada nula, aplicando dmf solicitada. ' || p_dt_dmf || ')';
    --
  end if;

  -- Garantia de ajuste da DP em relação a DMF.
  IF w_dt_promessa < w_dt_dmf then
    w_dt_promessa := w_dt_dmf + nvl(w_qt_dia_lead_time_otif,0);
  end if;

  --- Gera histórico da alteração de DMF
  -- Chamado: 131546 - 22/04/2020 - Alexandre
  IF p_line_id IS NOT NULL
      AND Nvl(p_grava_historico, 'N') = 'Y'
--      AND Trunc(p_dt_dmf) <> Trunc(w_dt_dmf)
      THEN
    --
    omp12001jb.fnd_historico_dmf(
      p_header_id                 => p_header_id
      , p_line_id                 => p_line_id
      , p_inventory_item_id       => p_inventory_item_id
      , p_dmf_old                 => p_dmf_old
      , p_dmf_new                 => p_dt_dmf
      , p_dmf_calculada           => w_dt_dmf
      , p_dp_old                  => p_dp_old
      , p_dp_new                  => w_dt_promessa
      , p_ddc_old                 => p_ddc_old
      , p_ddc_new                 => p_ddc_new
      , p_regra                   => w_regra
      , p_regra_detalhes          => w_regra_detalhes || ' - ' || vg_historico_dmf
      , p_origem                  => 'FABRICA'
      , p_saldo_encontrado        => vg_saldo_estoque
      , p_ordered_quantity        => p_qt_item
    );
    /*-- Salvando histórico sem repetições, somente o histórico da última alteração.
    -- O restante do histórico para consulta, ficará na tabela PB_HISTORICO_CALCULO_DMF
    omp12001jb.prc_historico_dmf_mp(p_header_id        => p_header_id
                                    , p_line_id        =>p_line_id);*/
    --
  END IF;

  IF Nvl(p_data_retorno, 'DP') = 'DMF' THEN
    --
    RETURN(w_dt_dmf);
    --
  ELSE
    RETURN(w_dt_promessa);
  END IF;

EXCEPTION
  WHEN w_erro THEN
    raise_application_error(-20000,w_ds_erro);

  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao calcular a data de promessa para o item.'||SQLERRM);
END fnd_data_promessa_item;


--**************************************************************************
-- Objetivo: Ajusta DMF da ordem nas linhas de entrega para o fechamento do Precurso.
--
-- Autor: Alexandre Oliveira
-- Data: 05/06/2020
--**************************************************************************
PROCEDURE prd_atualiza_data_linha_ent ( p_retcode           IN OUT VARCHAR2
                                        , p_errbuf          IN OUT VARCHAR2
                                        , p_order_number    IN VARCHAR2 ) IS
  CURSOR c_delivery IS
    SELECT ol.schedule_ship_date                      dmf_line
      , DATE_SCHEDULED
      , oh.header_id
      , ol.line_id
      , oh.order_number
      , ol.line_number || '.' || ol.shipment_number   line_number
      , ol.LAST_UPDATE_DATE
    FROM wsh_delivery_details   wdd
    JOIN oe_order_lines_all     ol  ON  wdd.source_header_id     = ol.header_id
                                        AND wdd.source_line_id   = ol.line_id
    JOIN oe_order_headers_all   oh  ON ol.header_id = oH.header_id
    WHERE 1=1
      AND ol.open_flag                                          = 'Y'
      AND Trunc(To_Date(ol.schedule_ship_date, 'dd/mm/rrrr')) <> Trunc(To_Date(wdd.date_scheduled, 'dd/mm/rrrr'))
      --  ajusta por ordem de venda
      AND ( oh.order_number = p_order_number OR p_order_number IS NULL )
      --  Ajusta um período de dois dias retroativo quando não informado o número da ordem de venda.
      AND ( To_Date(ol.LAST_UPDATE_DATE, 'DD/MM/RRRR')          between To_Date(SYSDATE - 2, 'DD/MM/RRRR') AND To_Date(SYSDATE  , 'DD/MM/RRRR')
              OR p_order_number IS NOT NULL
        )
    ORDER BY oh.header_id
      , ol.line_number || '.' || ol.shipment_number;
  --
  r_delivery c_delivery%ROWTYPE;
--
BEGIN
  --
  fnd_file.put_line(fnd_file.Log, 'Iniciando ajuste da DMF nas linhas de entrega.');
  fnd_file.put_line(fnd_file.Log, ' ');
  --
  OPEN c_delivery;
  LOOP
    FETCH c_delivery INTO r_delivery;
    EXIT WHEN c_delivery%NOTFOUND;
    --
    fnd_file.put_line(fnd_file.Log, ' * Ajustando ordem | linha: ' || r_delivery.order_number || ' - ' || r_delivery.line_number);
--    fnd_file.put_line(fnd_file.Log, ' header_id: ' || r_delivery.header_id || ' - line_id: ' || r_delivery.line_id);
    fnd_file.put_line(fnd_file.Log, ' DMF na Linha da Ordem: '                    || r_delivery.dmf_line ||
                                    Chr(10) || ' Data Programada Distribuição: '  || r_delivery.DATE_SCHEDULED);
    fnd_file.put_line(fnd_file.Log, ' - ');
    --
    UPDATE wsh_delivery_details
      SET DATE_SCHEDULED = r_delivery.dmf_line
    WHERE source_header_id  = r_delivery.header_id -- 13917476
      AND source_line_id    = r_delivery.line_id -- 19466475
    ;
  END LOOP;
  CLOSE c_delivery;
  --
EXCEPTION
  WHEN OTHERS THEN
    --
    Raise_Application_Error(-20001, ' Erro ao atualizar a DMF nas linhas de entrega. Erro:' || SQLERRM);
    --
END prd_atualiza_data_linha_ent;


--**************************************************************************
-- Objetivo: Verificar saldo disponível para uma determinada restrição de estoque
-- Utilzado para definir se a DMF será calculada ou não com base o ATP COVID 19.
--
-- Autor: Alexandre Oliveira
-- Data: 04/06/2020
--**************************************************************************
FUNCTION fnd_saldo_disp_restricao(  p_organization_id       IN NUMBER
                                    , p_inventory_item_id   IN NUMBER
                                    , p_id_familia          IN VARCHAR2
                                    , p_id_calibre          IN VARCHAR2
                                    , p_id_grupo            IN VARCHAR2
                                    , p_qtd_ordered         IN VARCHAR2
                                    , p_header_id           IN NUMBER      ) RETURN VARCHAR2 IS
  --
  w_retorno           VARCHAR2(1);
  w_familia           VARCHAR2(2);
  w_calibre           VARCHAR2(1);
  w_cond_like         VARCHAR2(50);
  w_saldo             NUMBER;
  w_cod_deposito      VARCHAR2(20);
  w_cod_produto_ora   VARCHAR2(20);
  w_valda_grupo       VARCHAR2(1);
  w_saldo_disp_grupo  VARCHAR2(1);
  --
  CURSOR c_item IS
    SELECT segment1
    FROM   mtl_system_items_b
    WHERE organization_id   = p_organization_id
      AND inventory_item_id = p_inventory_item_id;

--Seleciona o deposito do produto
CURSOR c_deposito IS
  SELECT organization_code
  FROM   org_organization_definitions
  WHERE  organization_id   = p_organization_id;
BEGIN
  --
  w_retorno       := 'N';
  -- Não valida o Grupo caso não tenha saldo pra o produdo com base em Família ou Cálibre.
  w_valda_grupo   := 'N';

  -- condição padrão: 2 caracteres Família - 3 caracteres anuancia.
  w_cond_like := '_____';

  -- Valida condição Família
  w_familia := SubStr(p_id_familia, 1, 2);
  IF w_familia IS NOT NULL THEN
    --
    w_cond_like := w_familia || '___';
    --
  END IF;

  -- Valida condição Cálibre
  w_calibre := SubStr(p_id_calibre, 1, 1);
  IF w_calibre IS NOT NULL THEN
    --
    w_cond_like := w_cond_like || w_calibre || '%';
    --
  ELSIF w_familia IS NOT NULL THEN
    --
    w_cond_like := w_familia || '%';
    --
  END IF;

  IF w_familia IS NOT NULL OR w_calibre IS NOT NULL THEN
    -- Valida se tem saldo em estoque para atender família e cálibre
    w_saldo := 0;
    --
    OPEN c_item;
    FETCH c_item INTO w_cod_produto_ora;
    CLOSE c_item;
    --
    OPEN c_deposito;
    FETCH c_deposito INTO w_cod_deposito;
    CLOSE c_deposito;
    --
    BEGIN
      --
      SELECT Sum(QTD_DISPONIVEL)
        INTO w_saldo
      FROM   sig_saldo_estoque_apo_v
      WHERE qtd_disponivel  > 0
        AND status                    = 'LIB'
        AND cod_deposito              = w_cod_deposito -- 'EET' --
        AND cod_produto_ora           = w_cod_produto_ora -- '24529E' --
        AND cod_tonalidade_calibre    LIKE w_cond_like
      ORDER BY cod_tonalidade_calibre;
      --
    EXCEPTION
      WHEN OTHERS THEN
        w_saldo := 0;
    END;
    --
    IF w_saldo > p_qtd_ordered THEN
      --
      w_retorno       := 'S';
      -- Valida o grupo caso tenha saldo em estoque.
      w_valda_grupo   := 'S';
      --
      vg_historico_dmf := vg_historico_dmf || ' - DMF Não calculada. Encontrado saldo de ' || w_saldo
        || ' para atendimento da restrição de família | cálibre: ' || Nvl(w_familia, 'N/D') || ' | ' || Nvl(w_calibre, 'N/D');
      --
    END IF;
    --
  ELSE
    --
    -- Valida grupo se não forem informadas a família e clalibre
    w_valda_grupo   := 'S';
    --
  END IF;
  --
  --
  IF p_id_grupo IS NOT NULL AND w_valda_grupo = 'S' THEN
    -- Validar se todas as linhas do mesmo grupo tem saldo em estoque com o mesmo CALIBRE.
    w_saldo_disp_grupo := omp12001jb.fnd_saldo_disp_grupo(  p_header_id             => p_header_id
                                                            , p_grupo               => p_id_grupo
                                                            , p_organization_id     => p_organization_id
                                                            , p_inventory_item_id   => p_inventory_item_id
                                                            , p_qt_item             => p_qtd_ordered   );
    IF w_saldo_disp_grupo = 'S' THEN
      --
      w_retorno := 'S';
      --
    END IF;
    --
  END IF;
  --
  IF w_retorno = 'N' THEN
    --
    vg_historico_dmf := vg_historico_dmf || ' - Não foi encontrado saldo para atendimento da restrição de família | cálibre | Grupo: '
      || Nvl(w_familia, 'N/D') || ' | ' || Nvl(w_calibre, 'N/D') || ' | ' || Nvl(p_id_grupo, 'N/D') || '. ';
    --
  END IF;
  --
  RETURN(w_retorno);
  --
EXCEPTION
  WHEN OTHERS THEN
    Raise_Application_Error(-20001, ' Erro ao verificar saldo de restrição em omp12001jb.fnd_saldo_disp_restricao. ERRO: ' || SQLERRM );
END fnd_saldo_disp_restricao;



--**************************************************************************
-- Objetivo: Calcular DMF para alguns produtos quando a regra for atendida
--  Os produtos devem estar cadastrados no Quick code ONT_ATP_PRODUTOS_CALCULA_DMF
--
-- Autor: Alexandre Oliveira
-- Chamado: 131546
-- Data: 22/04/2020
--**************************************************************************
FUNCTION fnd_saldo_disp_grupo(p_header_id           IN NUMBER
                              , p_grupo             IN VARCHAR2
                              , p_organization_id   IN NUMBER
                              , p_inventory_item_id IN NUMBER
                              , p_qt_item           IN NUMBER    ) RETURN VARCHAR2 IS
  --
  CURSOR c_itens_grupo IS
    SELECT ol.attribute15                               GRUPO
      , LINE_NUMBER || '.' || SHIPMENT_NUMBER           linha
      , ite.segment1                                    produto
      , ol.inventory_item_id
      , org.organization_id
      , ol.ordered_quantity
      , ol.header_id
      , oh.sales_channel_code
    FROM oe_order_lines_all             ol
    JOIN oe_order_headers_all           oh  ON ol.header_id = oh.header_id
    JOIN mtl_system_items_b             ite ON  ol.inventory_item_id = ite.inventory_item_id
                                                AND ite.organization_id = pb_master_organization_id
    --
    JOIN org_organization_definitions   org ON ol.ship_from_org_id = org.organization_id
    WHERE OH.HEADER_ID          = p_header_id -- 13920393
      AND Upper(ol.attribute15) = Upper(Trim(p_grupo));
  --
  r_itens_grupo c_itens_grupo%ROWTYPE;
  --
  --
  w_retorno         VARCHAR2(1);
  w_estoque_dispo   VARCHAR2(1);
  w_estoque_dispo_n VARCHAR2(1);
  w_estoque         VARCHAR2(2);
  w_log             VARCHAR2(250);
  w_log_add         VARCHAR2(250);
  w_canal           VARCHAR2(20);
  --
--
PRAGMA AUTONOMOUS_TRANSACTION;
--
BEGIN
  --
  w_estoque := NULL;
  w_retorno := 'S';
  w_log     := 'Validação do grupo: ' || p_grupo || ' - Produtos: ';
  --
  w_canal := omp12001jb.fnd_canal_venda(p_header_id => p_header_id);
  --
  --- Valida saldo para a quando ela ainda não está inserida em banco.
  -- caso de quando vai inserir uma linha nova em uma ordem registrada.
  w_estoque_dispo_n := omp12001jb.fnd_estoque_dispo(  p_inventory_item_id   => p_inventory_item_id,
                                                        p_organization_id   => p_organization_id,
                                                        p_qtd               => p_qt_item,
                                                        p_canal             => w_canal,
                                                        p_header_id         => p_header_id);
  --
  -- Caso o próprio produto inserido do grupo esteja sem saldo em estoque,
  --  já deve retornar indisponibildade de saldo
  w_log_add := '';
  IF Nvl(w_estoque_dispo_n, 'N') = 'N' THEN
    --
    w_retorno := 'N';
    w_log_add := ' Produto inserido SEM SALDO.';
    --
  ELSE
    --
    w_retorno := 'S';
    --
  END IF;
  --
  -- Combinado com a Rainara que neste primeiro momento não será analisado o saldo
  --  dos outros produtos do mesmo grupo. Essa regra de negócio ainda precis ser analisada.
--  OPEN c_itens_grupo;
--  LOOP
--    FETCH c_itens_grupo INTO r_itens_grupo;
--    EXIT WHEN c_itens_grupo%NOTFOUND;
--      --
--      w_estoque_dispo := omp12001jb.fnd_estoque_dispo(  p_inventory_item_id => r_itens_grupo.inventory_item_id,
--                                                        p_organization_id   => r_itens_grupo.organization_id,
--                                                        p_qtd               => r_itens_grupo.ordered_quantity,
--                                                        p_canal             => r_itens_grupo.sales_channel_code,
--                                                        p_header_id         => r_itens_grupo.header_id);
--      --
--      w_log     := w_log || '(' || r_itens_grupo.linha || ') ' || r_itens_grupo.produto;
--      w_estoque := 'OK';
--      --
--      IF Nvl(w_estoque_dispo, 'N') = 'N' THEN
--        --
--        w_log   := w_log || ' [SEM SALDO], ';
--        w_retorno := 'N';
--        --
--      ELSE
--        w_log   := w_log || ' [com saldo], ';
--      END IF;
--      --
--  END LOOP;
--  --
--  CLOSE c_itens_grupo;
  --
  w_log := w_log || w_log_add;
  --
--  IF w_estoque IS NULL THEN
--    --
--    w_retorno := 'N';
--    --
--  END IF;
  --
  w_estoque := NULL;
  --
  vg_historico_dmf := vg_historico_dmf || w_log;
  --
  RETURN( w_retorno );
  --
EXCEPTION
  WHEN OTHERS THEN
    Raise_Application_Error(-20000, 'Erro ao validar saldo de componibilidade do GRUPO. omp12001jb.fnd_saldo_disp_grupo. ERRO: ' || SQLERRM);
END fnd_saldo_disp_grupo;


--**************************************************************************
-- Objetivo: Calcular DMF para alguns produtos quando a regra for atendida
--  Os produtos devem estar cadastrados no Quick code ONT_ATP_PRODUTOS_CALCULA_DMF
--
-- Autor: Alexandre Oliveira
-- Chamado: 131546
-- Data: 22/04/2020
--**************************************************************************
FUNCTION prd_ajusta_dmf ( p_inventory_item_id   IN NUMBER
                          , p_dmf               IN DATE
                          , p_sales_channel     IN VARCHAR2
                          , p_line_id           IN NUMBER
                          , p_order_source_id   IN NUMBER
                          , p_organization_id   IN NUMBER
                          , p_header_id         IN NUMBER ) RETURN DATE IS
  --
  CURSOR c_calc_dmf (p_inventory_id NUMBER
                     , p_channel    varchar2) IS
    SELECT 1 calcular
    FROM FND_LOOKUP_VALUES_VL   flok
    JOIN mtl_system_items_b     ite  ON flok.DESCRIPTION = ite.segment1
                                        AND organization_id = pb_master_organization_id
    WHERE flok.lookup_type    = 'ONT_ATP_PRODUTOS_CALCULA_DMF'
      and flok.ENABLED_FLAG   = 'Y'
      AND Trunc(SYSDATE)      BETWEEN Trunc(Nvl(flok.start_date_active, SYSDATE)) AND Trunc(Nvl(flok.end_date_active, SYSDATE))
      AND ite.inventory_item_id = p_inventory_id
      and flok.TAG              = p_channel;
  --
  r_calc_dmf c_calc_dmf%ROWTYPE;
  --
  CURSOR c_perm_dmf (p_user_name VARCHAR2) IS
    SELECT 1 permite
    FROM FND_LOOKUP_VALUES_VL   flok
    WHERE flok.lookup_type        = 'ONT_ATP_CONTAS_AJUSTE_DMF'
      and flok.ENABLED_FLAG       = 'Y'
      AND Trunc(SYSDATE)          BETWEEN Trunc(Nvl(flok.start_date_active, SYSDATE)) AND Trunc(Nvl(flok.end_date_active, SYSDATE))
      AND Upper(flok.LOOKUP_CODE) = p_user_name;
  --
  r_perm_dmf c_perm_dmf%ROWTYPE;
  --
  CURSOR c_grupo_ordem  IS
  SELECT Upper(look.MEANING)  grupo_ordem
  FROM apps.oe_order_headers_all        oh
  JOIN apps.oe_transaction_types_all    oetta ON oh.order_type_id = oetta.transaction_type_id
  JOIN apps.FND_LOOKUP_VALUES           look  ON oetta.ATTRIBUTE1 = look.LOOKUP_CODE
  WHERE oh.header_id      = p_header_id
    AND look.LOOKUP_TYPE  = 'ONT_GRUPO_ORDEM'
    and look.language     = 'PTB'
    AND ROWNUM            < 2;
  --
  rg_c_grupo_ordem c_grupo_ordem%ROWTYPE;
  --
  CURSOR c_order_exception  IS
    SELECT 1 QTD
    FROM apps.oe_order_headers_all        oh
    JOIN apps.FND_LOOKUP_VALUES           flok  ON oh.order_type_id = flok.LOOKUP_CODE
    WHERE oh.header_id      = p_header_id
      AND LOOKUP_TYPE       LIKE 'ONT_ATP_TP_OV_EXCECAO_DMF'
      AND ENABLED_FLAG      = 'Y'
      AND flok.LANGUAGE     = 'PTB'
      AND Trunc(SYSDATE)    BETWEEN Nvl(flok.START_DATE_ACTIVE, SYSDATE) AND Nvl(flok.END_DATE_ACTIVE, SYSDATE);

  --
  rg_order_exception c_order_exception%ROWTYPE;
  --
  w_dt_dmf      DATE;
  w_user_id     NUMBER;
  w_user_name   VARCHAR(150);
  --
BEGIN
  w_dt_dmf          := p_dmf;
  --
  -- Regra emergencial, não aplicar ajuste de regra para a pbshop.
  -- Solicitante: Vinícius. 21/08/2020
  -- Autor: Alexandre Oliveira.
  /*if p_sales_channel = '4' then
    return(w_dt_dmf);
  end if;*/
  --
  -- Regra de exceção por tipo de ordem
  -- Tipo de Ordens cadastradas no quick code "ONT_ATP_TP_OV_EXCECAO_DMF" não calculam dmf
  -- Solicitante: Rafael Lucca.
  -- Autorizado por Rainara
  --
  OPEN c_order_exception;
  FETCH c_order_exception INTO rg_order_exception;
  IF c_order_exception%FOUND AND Nvl(rg_order_exception.qtd, 0) > 0 then
    --
    vg_historico_dmf := vg_historico_dmf || ' Tipo de ordem em regra de exceção e não calcula DMF.';
    CLOSE c_order_exception;
    RETURN(w_dt_dmf);
    --
  END IF;
  CLOSE c_order_exception;
  --
  -- Regra de desvio para ordens do grupo QUEBRA.
  -- Solicitante: Rafael Lucca
  -- Autorizado por Rainara.
  --
  fnd_file.put_line(fnd_file.log, ' ---- ');
  fnd_file.put_line(fnd_file.log, 'Validação do cálculo de DMF pelo ATP');
  fnd_file.put_line(fnd_file.log, ' ---- ');
  --
  OPEN c_grupo_ordem;
  FETCH c_grupo_ordem INTO rg_c_grupo_ordem;
  --
  IF rg_c_grupo_ordem.grupo_ordem = 'QUEBRA' THEN
    --
    fnd_file.put_line(fnd_file.log, ' Ordem de Quebra. DMF NÿO será calculada. DMF: ' || w_dt_dmf);
    fnd_file.put_line(fnd_file.log, ' ---- ');
    vg_historico_dmf := vg_historico_dmf || ' Ordem de Quebra. NÿO calcula DMF.';
    --
    CLOSE c_grupo_ordem;
    --
    RETURN(w_dt_dmf);
    --
  END IF;
  --
  CLOSE c_grupo_ordem;
  --
  -- Regra de desvio por usuário autorizado x responsabilidade.
  -- Solicitante: Rainara.
  --
  fnd_profile.get('USER_ID',  w_user_id);
  fnd_profile.get('USERNAME', w_user_name);
  --
  OPEN c_perm_dmf(p_user_name => w_user_name);
  FETCH c_perm_dmf INTO r_perm_dmf;
  --
  IF fnd_global.resp_id IN ( 57935, 58629 )
      AND c_perm_dmf%FOUND
      AND Nvl(r_perm_dmf.permite, 0) = 1 THEN
    --
    fnd_file.put_line(fnd_file.log, ' DMF alterada por usuário autorizado: ' || w_user_name || '. DMF NÿO será calculada. DMF: ' || w_dt_dmf);
    fnd_file.put_line(fnd_file.log, ' ---- ');
    vg_historico_dmf := vg_historico_dmf || ' DMF alterada por usuário autorizado: ' || w_user_name || '. NÿO calcula DMF.';
    --
    CLOSE c_perm_dmf;
    --
    RETURN(w_dt_dmf);
    --
  END IF;
  --
  CLOSE c_perm_dmf;
  -- Desvio para ordens internas com destino aos CDs
  -- Chamado: 132844
  -- 20/05/2020 - Alexandre Oliveira
  IF Nvl(p_order_source_id, 0) = 10 THEN
    --
    fnd_file.put_line(fnd_file.log, ' Identificada criação de Ordem interna. DMF NÿO será calculada. DMF: ' || w_dt_dmf);
    fnd_file.put_line(fnd_file.log, ' ---- ');
    vg_historico_dmf := vg_historico_dmf || ' Ordem interna NÿO calcula DMF.';
    --
    RETURN(w_dt_dmf);
    --
  END IF;
  --
  -- Para o depósito DET, não calcular a DMF Covid.
  -- Chamado: 132844
  -- 20/05/2020 - Alexandre Oliveira
  IF Nvl(p_organization_id, 0 ) IN (1713) THEN
    --
    Fnd_file.put_line(fnd_file.log, ' Encontrado depósito DET. DMF NÿO será calculada. DMF: ' || w_dt_dmf);
    fnd_file.put_line(fnd_file.log, ' ---- ');
    vg_historico_dmf := vg_historico_dmf || ' Depósito DET NÿO calcula DMF.';
    --
    RETURN(w_dt_dmf);
    --
  END IF;
  -- Permite antecipar a DMF caso a linha da ordem já esteja com reserva.
  -- Chamado: 132628
  -- 18/05/2020 - Alexandre Oliveira
  IF p_line_id IS NOT NULL THEN
    --
    IF omp12001jb.valida_reserva_dmf(p_line_id) = 'Y' THEN
      --
      fnd_file.put_line(fnd_file.log, ' Ordem com reserva. DMF NÿO será calculada. DMF: ' || w_dt_dmf);
      fnd_file.put_line(fnd_file.log, ' ---- ');
      vg_historico_dmf := vg_historico_dmf || ' Ordem COM Reserva NÿO calcula DMF.';
      --
      RETURN (w_dt_dmf);
      --
    END IF;
    --
  END IF;
  -- Recalcula DMF conforme regra ATP Covid 19
  -- Chamado: 131546
  OPEN c_calc_dmf(p_inventory_item_id, p_sales_channel);
  FETCH c_calc_dmf INTO r_calc_dmf;
  --
  IF c_calc_dmf%FOUND AND Nvl(r_calc_dmf.calcular, 0) > 0 THEN
    --
    --Seleciona a data de PPE - Dia atual + PPE por canal, "shop e outros".
    w_dt_dmf := omp12001jb.fnd_data_ppe(p_inventory_item_id  => p_inventory_item_id,
                                        p_sales_channel_code => p_sales_channel);
    --
    fnd_file.put_line(fnd_file.log, ' DMF Calculada com PPE. DMF: ' || w_dt_dmf);
    fnd_file.put_line(fnd_file.log, ' ---- ');
    vg_historico_dmf := vg_historico_dmf || ' DMF Calculada com PPE. ' || w_dt_dmf 
                     || ' - r_calc_dmf.calcular: ' || r_calc_dmf.calcular
                     || ' - p_inventory_item_id: ' || p_inventory_item_id
                     || ' - p_sales_channel: ' || p_sales_channel 
                     || '  |  ';
    --
  END IF;
  --
  CLOSE c_calc_dmf;
  --
  RETURN(w_dt_dmf);
  --
EXCEPTION
  WHEN OTHERS THEN
    Raise_Application_Error(-20600, 'Erro ao ajustar DMF. Erro: ' || SQLERRM);
END;


--**************************************************************************
-- Objetivo: Verificar se existe reserva para a linha da ordem de venda
--
-- Autor: Alexandre Oliveira
-- Chamado: 131546
-- Data: 18/05/2020
--**************************************************************************
FUNCTION valida_reserva_dmf ( p_line_id IN NUMBER ) RETURN VARCHAR2 IS
  --
  CURSOR c_reserva (p_line_id NUMBER) IS
    SELECT Sum(PRIMARY_RESERVATION_QUANTITY) qtd_reservada
      , ordered_quantity
      , ol.line_id
    FROM MTL_RESERVATIONS  res
    JOIN oe_order_lines_all   ol  ON res.demand_source_line_id = ol.line_id
    WHERE demand_source_line_id = p_line_id
    GROUP BY ol.line_id
      , ordered_quantity;
  --
  r_reserva c_reserva%ROWTYPE;
  --
PRAGMA AUTONOMOUS_TRANSACTION;
--
BEGIN
  --
  IF p_line_id IS NOT NULL THEN
    --
    OPEN c_reserva(p_line_id);
    FETCH c_reserva INTO r_reserva;
    --
    IF c_reserva%FOUND
        AND Nvl(r_reserva.qtd_reservada, 0) > 0
        AND r_reserva.qtd_reservada = r_reserva.ordered_quantity then
      --

      CLOSE c_reserva;
      RETURN ('Y');
      --
    END IF;
    --
    CLOSE c_reserva;
    --
  END IF;
  --
  RETURN( 'N' );
  --
EXCEPTION
  WHEN OTHERS THEN
    Raise_Application_Error(-20600, 'Erro ao validar reserva para DMF. Erro: ' || SQLERRM);
END;

--**************************************************************************
-- Objetivo: Gravar histórico dos cálculos de DMF com base na nova funcionalidade
--
-- Chamado: 131546
-- Data: 22/04/2020
-- Autor: Alexandre Oliveira
--**************************************************************************
PROCEDURE fnd_historico_dmf(p_header_id                 IN NUMBER
                            , p_line_id                 IN NUMBER
                            , p_inventory_item_id       IN NUMBER
                            , p_dmf_old                 IN DATE
                            , p_dmf_new                 IN DATE
                            , p_dmf_calculada           IN DATE
                            , p_dp_old                  IN DATE
                            , p_dp_new                  IN DATE
                            , p_ddc_old                 IN DATE
                            , p_ddc_new                 IN DATE
                            , p_regra                   IN VARCHAR2
                            , p_regra_detalhes          IN VARCHAR2
                            , p_origem                  IN VARCHAR2
                            , p_saldo_encontrado        IN NUMBER
                            , p_ordered_quantity        IN NUMBER ) IS

--
w_id_usuario      NUMBER;
--
BEGIN
  --
  fnd_profile.get ('USER_ID', w_id_usuario);
  --
  INSERT INTO PB_HISTORICO_CALCULO_DMF (
    his_header_id
    , his_line_id
    , his_inventory_item_id
    , his_dmf_old
    , his_dmf_new
    , his_dmf_calculada
    , his_dp_old
    , his_dp_new
    , his_ddc_old
    , his_ddc_new
    , his_regra
    , his_regra_detalhes
    , his_origem
    , his_enviado
    , creation_date
    , created_by
    , his_saldo_encontrado
    , his_ordered_quantity
  )
  VALUES (
    p_header_id               -- his_header_id
    , p_line_id               -- his_line_id
    , p_inventory_item_id     -- his_inventory_item_id
    , p_dmf_old               -- his_dmf_old
    , p_dmf_new               -- his_dmf_new
    , p_dmf_calculada         -- his_dmf_calculada
    , p_dp_old                -- his_dp_old
    , To_Date(p_dp_new, 'dd/mm/rrrr')                -- his_dp_new
    , p_ddc_old               -- his_ddc_old
    , p_ddc_new               -- his_ddc_new
    , p_regra                 -- his_regra
    , p_regra_detalhes        -- his_regra_detalhes
    , p_origem                -- his_origem
    , '0'                     -- his_enviado
    , SYSDATE                 -- creation_date
    , w_id_usuario            -- created_by
    , p_saldo_encontrado      -- his_saldo_encontrado
    , p_ordered_quantity      -- his_ordered_quantity
  );

  -- Salvando histórico sem repetições, somente o histórico da última alteração.
  -- O restante do histórico para consulta, ficará na tabela PB_HISTORICO_CALCULO_DMF
  omp12001jb.prc_historico_dmf_mp(p_header_id        => p_header_id
                                  , p_line_id        =>p_line_id);



EXCEPTION
  WHEN OTHERS THEN
    --
    Raise_Application_Error(-20000, 'Erro ao gravar histórico de cálculo da DMF. Erro: ' || SQLERRM
      || Chr(10)
      || p_header_id               -- his_header_id
      || ' - ' || p_line_id               -- his_line_id
      || ' - ' ||  p_inventory_item_id     -- his_inventory_item_id
      || ' - ' ||  p_dmf_old               -- his_dmf_old
      ||  ' - ' || p_dmf_new               -- his_dmf_new
      ||  ' - ' || p_dmf_calculada         -- his_dmf_calculada
      ||  ' - ' || p_dp_old                -- his_dp_old
      ||  ' - ' || p_dp_new                -- his_dp_new
      ||  ' - ' || p_ddc_old               -- his_ddc_old
      ||  ' - ' || p_ddc_new               -- his_ddc_new
      ||  ' - ' || p_regra                 -- his_regra
      ||  ' - ' || p_regra_detalhes        -- his_regra_detalhes
      ||  ' - ' || p_origem                -- his_origem
      ||  ' - ' || '0'                     -- his_enviado
      ||  ' - ' || SYSDATE                 -- creation_date
      ||  ' - ' || w_id_usuario
      );
END;

--**************************************************************************
-- Objetivo: Gravar histórico dos cálculos de DMF com base na nova funcionalidade
--
-- Chamado: 131546
-- Data: 22/04/2020
-- Autor: Alexandre Oliveira
--**************************************************************************
PROCEDURE prc_historico_dmf_mp (p_header_id                 IN NUMBER
                                , p_line_id                 IN NUMBER) IS
  CURSOR c_order_line IS
    SELECT HIS_HEADER_ID                                                        header_id
      , HIS_LINE_ID                                                             line_id
      /*, OH.ORDER_NUMBER                                                         order_number*/
      /*, OL.LINE_NUMBER || '.' || OL.SHIPMENT_NUMBER                             LINE_NUMBER*/
      , Trunc(HIS.creation_date, 'MI')                                          his_creation_date
      , Count(*)                                                                total
    FROM APPS.PB_HISTORICO_CALCULO_DMF    HIS
    JOIN OE_ORDER_HEADERS_ALL             OH    ON HIS.HIS_HEADER_ID = OH.HEADER_ID
    /*JOIN OE_ORDER_LINES_ALL               OL    ON OH.HEADER_ID = OL.HEADER_ID
                                                    AND HIS.HIS_LINE_ID = OL.LINE_ID*/

    WHERE HIS.HIS_HEADER_ID                  = p_header_id
      AND HIS.HIS_LINE_ID                  =  p_line_id
      AND Trunc(HIS.CREATION_DATE, 'MI')   = (  SELECT Trunc(Max(CREATION_DATE), 'MI')
                                                FROM APPS.PB_HISTORICO_CALCULO_DMF his2
                                                WHERE his2.his_header_id  = HIS.HIS_HEADER_ID -- 13922613
                                                  AND his2.HIS_LINE_ID  = HIS.HIS_LINE_ID -- 19469889
                                              )

    GROUP BY HIS.HIS_HEADER_ID
      , HIS.HIS_LINE_ID
      , Trunc(HIS.creation_date, 'MI')

    ORDER BY HIS.HIS_HEADER_ID   DESC
      , HIS.HIS_LINE_ID
      , Trunc(HIS.creation_date, 'MI') DESC ;
  --
  r_order_line c_order_line%ROWTYPE;
  --
  CURSOR c_last_update (p_header NUMBER, p_line NUMBER, p_creation_date DATE ) IS
    SELECT HIS_HEADER_ID
      , HIS_LINE_ID
      /*, OH.ORDER_NUMBER
      , OL.LINE_NUMBER || '.' || OL.SHIPMENT_NUMBER                                 LINE_NUMBER*/
      , HIS.creation_date
      , his.created_by
      , HIS_ID
      -- was changed
      , CASE WHEN Trunc(HIS_DMF_OLD) <> Trunc(HIS_DMF_CALCULADA)
          THEN 'Sim'
          ELSE 'n' END                                                              updated

                  -- there was change
      , CASE WHEN Trunc(HIS_DMF_NEW)     <> Trunc(HIS_DMF_OLD)
                  -- the date don't was calculated
                  AND Trunc(HIS_DMF_NEW) = Trunc(HIS_DMF_CALCULADA)
          THEN 'Sim'
          ELSE 'n' END                                                              updated_by_user
                  -- there was change
      , CASE WHEN Trunc(HIS_DMF_OLD)     <> Trunc(HIS_DMF_CALCULADA)
                  -- calculated by system
                  AND Trunc(HIS_DMF_NEW) <> Trunc(HIS_DMF_CALCULADA)
          THEN 'Sim'
          ELSE 'n' END                                                              calculated_date

      -- When the final date was wider then new.
      , CASE WHEN Trunc(HIS_DMF_CALCULADA) > Trunc(HIS_DMF_NEW)
          THEN 'Sim'
          ELSE 'n' END                                                              updated_by_system

                  -- there wasn't change
      , CASE WHEN HIS_DMF_OLD       = HIS_DMF_NEW
                  -- the date was calculated
                  AND Trunc(HIS_DMF_NEW)   <>  Trunc(HIS_DMF_CALCULADA)
          THEN 'Sim'
          ELSE 'n' END                                                              updated_just_by_system

                  -- user tried to change
      , CASE WHEN HIS_DMF_OLD             <> HIS_DMF_NEW
                  --
                  AND Trunc(HIS_DMF_NEW)  =  Trunc(HIS_DMF_CALCULADA)
          THEN 'Sim'
          ELSE 'n' END                                                              user_try_change
      , CASE WHEN flok.meaning IS NOT NULL
                THEN 'Y'
              ELSE 'N'
        END                                                                         produto_ce
      , HIS_DMF_OLD
      , HIS_DMF_NEW
      , HIS_DMF_CALCULADA
      /*, OL.SCHEDULE_SHIP_DATE                                                       DMF_LINHA_ORDEM*/
      , HIS_DP_OLD
      , HIS_DP_NEW
      , his_regra
      , his_regra_detalhes
      /*, OL.ATTRIBUTE17                                                              DP_LINHA_ORDEM*/

    FROM APPS.PB_HISTORICO_CALCULO_DMF    HIS
    JOIN apps.OE_ORDER_HEADERS_ALL        OH    ON HIS.HIS_HEADER_ID = OH.HEADER_ID
    /*JOIN apps.OE_ORDER_LINES_ALL          OL    ON OH.HEADER_ID = OL.HEADER_ID
                                                    AND HIS.HIS_LINE_ID = OL.LINE_ID*/
    JOIN apps.consulta_produto_pb_v       pro   ON  HIS.HIS_INVENTORY_ITEM_ID = pro.item_id
    LEFT JOIN FND_LOOKUP_VALUES_VL        flok  ON  flok.lookup_type        = 'ONT_ATP_PRODUTOS_CALCULA_DMF'
                                                AND flok.ENABLED_FLAG   = 'Y'
                                                AND Trunc(SYSDATE)      BETWEEN Trunc(Nvl(flok.start_date_active, SYSDATE)) AND Trunc(Nvl(flok.end_date_active, SYSDATE))
                                                AND pro.cod_produto         = flok.description
                                                and oh.sales_channel_code   = flok.TAG

    WHERE HIS.HIS_HEADER_ID                    = p_header
      AND HIS.HIS_LINE_ID                      = p_line
      AND Trunc(his.creation_date, 'MI')       = trunc(p_creation_date, 'MI')

    ORDER BY HIS.CREATION_DATE DESC
      , HIS_ID DESC;
  --
  r_last_update c_last_update%ROWTYPE;
  --
  cursor c_ov_post_atp is
    SELECT 1
    FROM PB_HISTORICO_CALCULO_DMF_MPED
    WHERE hisp_header_id           = p_header_id -- 13922613
      AND HISP_POSTERGADA_ATP   = 'Y';
  --
  CURSOR c_first_dmf IS
    SELECT his_dmf_new
      , creation_date
    FROM APPS.PB_HISTORICO_CALCULO_DMF    HIS
    WHERE his_header_id = p_header_id
      AND his_line_id   = p_line_id
      -- Get the first minimal date on history.
      AND his_id        = ( SELECT Min(his_id)
                            FROM APPS.PB_HISTORICO_CALCULO_DMF his2
                            WHERE his2.his_header_id  = his.his_header_id
                              AND his2.his_line_id    = his.his_line_id
                          );
  --
  r_first_dmf  c_first_dmf%ROWTYPE;
  --
  w_ind             NUMBER;
  w_dmf_old         DATE;
  w_dmf_new         DATE;
  w_dmf_calc        dATE;
  w_creation_date   DATE;
  w_created_by      NUMBER;
  w_flag_upd_atp    CHAR(1);
  w_flag_updated    CHAR(1);
  w_ordem           VARCHAR2(20);
  w_linha           VARCHAR2(20);
  w_header_id       NUMBER;
  w_line_id         NUMBER;
  w_his_id_1        NUMBER;
  w_his_id_2        NUMBER;
  w_produto_ce      CHAR(1);
  w_ov_post_atp     number;
  w_flag_atp_ov     char(1);
  w_first_dmf       DATE;
  w_his_regra       VARCHAR2(500);
  w_his_regra_det   VARCHAR2(4000);

BEGIN
  --
  FOR r_order_line IN c_order_line LOOP
    --
    w_ind           := NULL;
    w_flag_upd_atp  := 'N';
    w_flag_updated  := 'N';
    --
    FOR r_last_update IN c_last_update(r_order_line.HEADER_ID
                                       , r_order_line.LINE_ID
                                       , r_order_line.his_creation_date) LOOP
      --
      IF w_ind IS NULL THEN
        --
        w_dmf_new        := r_last_update.his_dmf_new;
        w_dmf_calc       := r_last_update.his_dmf_calculada;
        w_his_id_1       := r_last_update.his_id;
        w_his_regra      := r_last_update.his_regra;
        w_his_regra_det  := r_last_update.his_regra_detalhes;

        w_ind       := 1;
        --
      END IF;
      --
      w_dmf_old         := r_last_update.his_dmf_old;
      w_his_id_2        := r_last_update.his_id;
      w_produto_ce      := r_last_update.produto_ce;
      w_creation_date   := r_last_update.creation_date;
      w_created_by      := r_last_update.created_by;
      --
    END LOOP;
    --
    IF Trunc(w_dmf_calc) > Trunc(w_dmf_new) THEN
      w_flag_upd_atp  := 'Y';
    END IF;

    IF Trunc(w_dmf_old) <> Trunc(w_dmf_new) THEN
      --
      w_flag_updated  := 'Y';
      --
    END IF;
    --
    BEGIN



      INSERT INTO PB_HISTORICO_CALCULO_DMF_MPED (
          hisp_header_id
          , hisp_line_id
          , hisp_dmf_old
          , hisp_dmf_new
          , hisp_dmf_calculada
          , hisp_dmf_aterada
          , hisp_postergada_atp
          , hisp_produto_ce
          , hisp_enviado
          , creation_date
          , created_by
          , hisp_his_regra
          , hisp_his_regra_detalhes
        )
      VALUES (
          r_order_line.HEADER_ID            -- hisp_header_id
          , r_order_line.LINE_ID            -- hisp_line_id
          , w_dmf_old                       -- hisp_dmf_old
          , w_dmf_new                       -- hisp_dmf_new
          , w_dmf_calc                      -- hisp_dmf_calculada
          , w_flag_updated                  -- hisp_dmf_aterada
          , w_flag_upd_atp                  -- hisp_postergada_atp
          , w_produto_ce                    -- hisp_produto_ce
          , 'N'                             -- hisp_enviado
          , w_creation_date                 -- creation_date
          , w_created_by                    -- created_by
          , 'ov2 - ' || w_his_regra                     -- hisp_his_regra
          , 'ov2 - ' || w_his_regra_det                 -- hisp_his_regra
        );
        --
        --commit;
        --
        null;
    EXCEPTION
      WHEN Dup_Val_On_Index THEN
        --
        update PB_HISTORICO_CALCULO_DMF_MPED
          set hisp_dmf_old                  = w_dmf_old
            , hisp_dmf_new                  = w_dmf_new
            , hisp_dmf_calculada            = w_dmf_calc
            , hisp_dmf_aterada              = w_flag_updated
            , hisp_postergada_atp           = w_flag_upd_atp
            , creation_date                 = w_creation_date
            , created_by                    = w_created_by
            , hisp_his_regra                = 'ov2 - ' || w_his_regra
            , hisp_his_regra_detalhes       = 'ov2 - ' || w_his_regra_det
        where hisp_header_id    = r_order_line.HEADER_ID
          and hisp_line_id      = r_order_line.LINE_ID;
        --
        null;
      WHEN OTHERS THEN
        --
        raise_application_error(-20100, 'Erro ao gravar histórico para o Meu pedido da ordem '
                                        || r_order_line.HEADER_ID || ' - '
                                        || r_order_line.LINE_ID || '. Erro: ' || sqlerrm);
        --
    END;
  --
  END LOOP;
  --
  -- Ajusta flag de ordem de venda afetada ou não pelo cálculo do ATP
  --
  w_ov_post_atp     := null;
  --
  open c_ov_post_atp;
  fetch c_ov_post_atp into w_ov_post_atp;
  close c_ov_post_atp;
  --
  w_flag_atp_ov := 'N';
  --
  if nvl(w_ov_post_atp, 0) = 1 then
    w_flag_atp_ov := 'Y';
  end if;
  --
  begin
    --
    update PB_HISTORICO_CALCULO_DMF_MPED
      set hisp_ov_alterada = w_flag_atp_ov
    where hisp_header_id = p_header_id;
    --
  exception
    when others then
      raise_application_error(-20090, 'Erro ao atualizar flag ordem atualizada por regra CE. ERRO: ' || sqlerrm);
  end;
  --
  open c_first_dmf;
  fetch c_first_dmf into r_first_dmf;
  --
  if c_first_dmf%found and r_first_dmf.his_dmf_new is not null then
    --
    begin
      --
      update PB_HISTORICO_CALCULO_DMF_MPED
        set hisp_primeira_dmf = r_first_dmf.his_dmf_new
      where hisp_header_id    = p_header_id
        and hisp_line_id      = p_line_id;
      --
    exception
      when others then
        raise_application_error(-20095, 'Erro ao atualizar Primeira DMF Desejo d Ordem no histórico. Erro: ' || sqlerrm);
    --
    end;
  end if;
  --

  close c_first_dmf;
  --
EXCEPTION
  WHEN OTHERS THEN
    --
    raise_application_error(-20100, 'Erro ao gravar histórico para o Meu pedido. Erro: ' || sqlerrm);
    --
END;


--****  VERS�O NOVA **********************************************************************
FUNCTION fnd_qtd_periodo_dec RETURN NUMBER IS
  --
CURSOR c_periodo IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 1 --Periodos V�lidos para Dec�ndios
  AND    lookup_type         = 'ONT_ATP_PARAMETRO_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))
  ;
  --
  w_qt_periodo NUMBER;
  --
BEGIN
  --
  --Seleciona a quantidade de per�odos
  OPEN c_periodo;
  FETCH c_periodo
  INTO w_qt_periodo;
  CLOSE c_periodo;
  --
  RETURN(w_qt_periodo);
  --
EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar os períodos válidos dec�ndios - '||SQLERRM);
END fnd_qtd_periodo_dec;
--
--**************************************************************************
--
FUNCTION fnd_considera_transitorio RETURN NUMBER IS
  --
CURSOR c_transitorio IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 6 --Periodos V�lidos para Dec�ndios
  AND    lookup_type         = 'ONT_ATP_PARAMETRO_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))
  ;
  --
  w_qt_periodo NUMBER;
  --
BEGIN
  --
  --Seleciona a quantidade de per�odos
  OPEN c_transitorio;
  FETCH c_transitorio
  INTO w_qt_periodo;
  CLOSE c_transitorio;
  --
  RETURN(w_qt_periodo);
  --
EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar os períodos válidos dec�ndios - '||SQLERRM);
END fnd_considera_transitorio;
--
--**************************************************************************
--
FUNCTION fnd_historico_transitorio RETURN NUMBER IS
  --
CURSOR c_transitorio IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 7 --Periodos V�lidos para Dec�ndios
  AND    lookup_type         = 'ONT_ATP_PARAMETRO_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))
  ;
  --
  w_qt_periodo NUMBER;
  --
BEGIN
  --
  --Seleciona a quantidade de per�odos
  OPEN c_transitorio;
  FETCH c_transitorio
  INTO w_qt_periodo;
  CLOSE c_transitorio;
  --
  RETURN(w_qt_periodo);
  --
EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar os períodos válidos dec�ndios - '||SQLERRM);
END fnd_historico_transitorio;
--
--**************************************************************************
--

FUNCTION fnd_hist_dados_transit(p_item    NUMBER) return number
is


begin
    --Seleciona a quantidade em estoque Fronteira
    INSERT INTO OM_SALDO_PRODUTO_ATP_TRANSIT (DATA_CREATED, INVENTORY_ITEM_ID, LOT_NUMBER, QUANTITY, TIPO) 
    SELECT SYSDATE, MS.inventory_item_id, moqd.lot_number, sum(moqd.primary_transaction_quantity), 'FRONTEIRA'
      FROM mtl_onhand_quantities_detail moqd,
           mtl_secondary_inventories msi,
           mtl_lot_numbers mln,
           mtl_parameters mp,
           mtl_system_items_b ms
     WHERE    msi.secondary_inventory_name = moqd.subinventory_code
              AND mln.lot_number = moqd.lot_number
              AND mln.inventory_item_id = moqd.inventory_item_id
              AND mln.organization_id = moqd.organization_id
              AND mp.organization_id = msi.organization_id
              AND msi.organization_id = moqd.organization_id
              AND msi.organization_id = ms.organization_id 
              AND moqd.inventory_item_id = ms.inventory_item_id
              AND mp.organization_code in( select LOOKUP_CODE
                 from fnd_lookup_values flv
                where flv.lookup_type = 'ONT_ATP_ORG_CD_PB'
                  and enabled_flag = 'Y'
                  and language = 'PTB'
                  and tag ='N'
                  and nvl(end_date_active,sysdate+1) > sysdate
                  )              
              --AND mp.organization_code like 'F%'
              and moqd.subinventory_code in('FTR','PIN','E30','CIT_REC','PB_RTJ')
              AND MS.inventory_item_id = p_item
    GROUP BY SYSDATE, MS.inventory_item_id, moqd.lot_number, 'FRONTEIRA';

    --Seleciona a quantidade em estoque F�brica
    INSERT INTO OM_SALDO_PRODUTO_ATP_TRANSIT (DATA_CREATED, INVENTORY_ITEM_ID, LOT_NUMBER, QUANTITY, TIPO) 
    SELECT SYSDATE, MS.inventory_item_id, moqd.lot_number, sum(moqd.primary_transaction_quantity), 'FABRICA'
      FROM mtl_onhand_quantities_detail moqd,
           mtl_secondary_inventories msi,
           mtl_lot_numbers mln,
           mtl_parameters mp,
           mtl_system_items_b ms
     WHERE    msi.secondary_inventory_name = moqd.subinventory_code
              AND mln.lot_number = moqd.lot_number
              AND mln.inventory_item_id = moqd.inventory_item_id
              AND mln.organization_id = moqd.organization_id
              AND mp.organization_id = msi.organization_id
              AND msi.organization_id = moqd.organization_id
              AND msi.organization_id = ms.organization_id 
              AND moqd.inventory_item_id = ms.inventory_item_id
              AND mp.organization_code like 'F%' 
              AND moqd.subinventory_code like 'E%'
              AND MS.inventory_item_id = p_item
     GROUP BY SYSDATE, MS.inventory_item_id, moqd.lot_number,'FABRICA';

    return(0);
END fnd_hist_dados_transit;
--
--**************************************************************************
--
FUNCTION fnd_horizonte_periodo_dec (p_horiz_periodo IN VARCHAR2
                                   ,p_de_ate        IN VARCHAR2) RETURN NUMBER
IS
  --
CURSOR c_horiz_periodo IS
  SELECT To_Number(Decode(p_de_ate,'DE',attribute2,attribute3))
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    lookup_code         = p_horiz_periodo --Horizonte do Per�odo
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                         AND Trunc(Nvl(end_date_active, SYSDATE))
  ;
  --
  w_dia_periodo NUMBER;
  --
BEGIN
  --
  --Seleciona o horizonte
  OPEN c_horiz_periodo;
  FETCH c_horiz_periodo
  INTO w_dia_periodo;
  CLOSE c_horiz_periodo;
  --
  RETURN(w_dia_periodo);
  --
END fnd_horizonte_periodo_dec;

--**************************************************************************
FUNCTION fnd_percentual_dispo_dec RETURN NUMBER IS
--
CURSOR c_percentual_dispo IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 2 --Percentual Disponibilidade
  AND    lookup_type         = 'ONT_ATP_PARAMETRO_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))
  ;
  --
  w_percentual_dispo NUMBER;
  --
BEGIN
  --
  --Seleciona horizonte conforme canal
  OPEN c_percentual_dispo;
  FETCH c_percentual_dispo
  INTO w_percentual_dispo;
  CLOSE c_percentual_dispo;
  --
  RETURN(w_percentual_dispo);
  --
EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o percentual de disponibilidade do saldo.'||SQLERRM);
END fnd_percentual_dispo_dec;
--
--**************************************************************************
FUNCTION fnd_grupo_horizonte_saldo_dec RETURN NUMBER IS
--
CURSOR c_grupo_horizonte IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 3 --Grupo saldo Horizonte valido
  AND    lookup_type         = 'ONT_ATP_PARAMETRO_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))
  ;
  --
  w_cd_grupo_horizonte NUMBER;
  --
BEGIN
  --
  --Seleciona o grupo de horizonte de saldo
  OPEN c_grupo_horizonte;
  FETCH c_grupo_horizonte
  INTO w_cd_grupo_horizonte;
  CLOSE c_grupo_horizonte;
  --
  RETURN(w_cd_grupo_horizonte);
  --
EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o grupo de horizonte v�lido - Dec�ndio - '||SQLERRM);
END fnd_grupo_horizonte_saldo_dec;
--
--**************************************************************************
FUNCTION fnd_horizonte_carteira_dec RETURN NUMBER IS

CURSOR c_horizonte_carteira IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 4 --Horizonte da Carteira
  AND    lookup_type         = 'ONT_ATP_PARAMETRO_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))
  ;
  --
  w_horizonte_carteira NUMBER;
  --
BEGIN
  --
  --Seleciona horizonte da Carteira
  OPEN c_horizonte_carteira;
  FETCH c_horizonte_carteira
  INTO w_horizonte_carteira;
  CLOSE c_horizonte_carteira;
  --
  RETURN(w_horizonte_carteira);
  --
EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar o Horizonte da Carteira.'||SQLERRM);
end fnd_horizonte_carteira_dec;
--
--**************************************************************************
FUNCTION fnd_data_fim_periodo_dec (p_id_periodo IN NUMBER
                                  ,p_carteira   IN VARCHAR2
                                  ) RETURN DATE IS
  --
  w_periodo          NUMBER := 1;
  w_dias_periodo     NUMBER;
  w_qtd_periodos_mes NUMBER;
  w_ini_dec          DATE;
  w_fim_dec          DATE;
  --
BEGIN
  --
  SELECT Count(*)
  INTO   w_qtd_periodos_mes
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))
  ;
  --
  ----dbms_output.put_line('w_qtd_periodos_mes: '||w_qtd_periodos_mes);
  --
  w_dias_periodo := fnd_horizonte_periodo_dec(1,'ATE') - fnd_horizonte_periodo_dec(1,'DE') + 1;
  --
  --dbms_output.put_line('w_dias_periodo: '||w_dias_periodo);
  --
  FOR i IN 1..w_qtd_periodos_mes LOOP
    --
    IF To_Number(To_Char(SYSDATE,'DD')) <= fnd_horizonte_periodo_dec(i,'ATE') THEN -- dia de hoje est� no dec�ndio "i"
      --
      w_ini_dec := To_Date(To_Char(fnd_horizonte_periodo_dec(i,'DE'),'00') || To_Char(SYSDATE,'MMYYYY'), 'DDMMYYYY');
      EXIT;
      --
    END IF;
    --
  END LOOP;
  --
  IF p_carteira = 'S' THEN -- Se for Carteira, come�a um dec�ndio a mais do que Produ��o
    --
    IF To_Number(To_Char(w_ini_dec,'DD')) >= 21 THEN  --$$$$$$$$$fnd_horizonte_periodo_dec(w_qtd_periodos_mes,'DE') THEN
      --
      w_ini_dec := Trunc(LAST_DAY(w_ini_dec)) + 1;
      --
    ELSE
      --
      w_ini_dec := w_ini_dec + w_dias_periodo;
      --
    END IF;
    --
  END IF;
  --
  --dbms_output.put_line('w_ini_dec: '||w_ini_dec);
  --
  LOOP
    --
    IF To_Number(To_Char(w_ini_dec,'DD')) >= 21 THEN --###############fnd_horizonte_periodo_dec(w_qtd_periodos_mes,'DE') THEN
      --
      w_fim_dec := Trunc(LAST_DAY(w_ini_dec));
      --
    ELSE
      --
      w_fim_dec := w_ini_dec + w_dias_periodo-1;
      --
    END IF;
    --
    ----dbms_output.put_line('w_fim_dec: '||w_fim_dec);
    --
    IF w_periodo < omp12001jb.fnd_qtd_periodo_dec THEN
      --
      IF w_periodo = p_id_periodo THEN
        --
        --dbms_output.put_line('RETURN-> w_fim_dec: '||w_fim_dec);
        --
        RETURN(w_fim_dec);
        --
      END IF;
      --
    ELSE
      --
      IF w_periodo >= omp12001jb.fnd_qtd_periodo_dec+2 THEN
        --
        --dbms_output.put_line('RETURN--> w_fim_dec: '||w_fim_dec);
        --
        RETURN(w_fim_dec);
        --
      END IF;
      --
    END IF;
    --
    w_periodo := w_periodo + 1;
    w_ini_dec := w_fim_dec + 1;
    --
    ----dbms_output.put_line('w_periodo := w_periodo + 1....: '||w_periodo);
    ----dbms_output.put_line('w_ini_dec := w_fim_dec + 1....: '||w_ini_dec);
    --
  END LOOP;
  --
EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar data final do per�odo - '||SQLERRM);
END fnd_data_fim_periodo_dec;
--
--**************************************************************************
FUNCTION fnd_dias_seguranca_prod_dec RETURN NUMBER IS

CURSOR c_dias_seguranca IS
  SELECT to_number(tag)
  FROM   fnd_lookup_values
  WHERE  language            = userenv('LANG')
  AND    enabled_flag        = 'Y'
  AND    security_group_id   = 0
  AND    view_application_id = 660
  AND    meaning             = 5 --Dias Seguran�a Prod
  AND    lookup_type         = 'ONT_ATP_PARAMETRO_SALDO_DEC_PB'
  AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))
  ;
  --
  w_dias_seguranca NUMBER;
  --
BEGIN
  --
  --Seleciona horizonte da Carteira
  OPEN c_dias_seguranca;
  FETCH c_dias_seguranca
  INTO w_dias_seguranca;
  CLOSE c_dias_seguranca;
  --
  RETURN(w_dias_seguranca);
  --
EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar a quantidade de Dias de Seguran�ao para Produ��o - '||SQLERRM);
END fnd_dias_seguranca_prod_dec;
--
--**************************************************************************
FUNCTION fnd_periodo_dec (p_dt_dmf   IN DATE
                         ,p_origem   IN VARCHAR2
                         ,p_carteira IN VARCHAR2 DEFAULT 'N'
                         ) RETURN NUMBER
IS
  --
  w_periodo          NUMBER := 1;
  w_dias_periodo     NUMBER;
  w_qtd_periodos_mes NUMBER;
  w_ini_dec          DATE;
  w_fim_dec          DATE;
  --
BEGIN
  --
  --dbms_output.put_line('...');
  --dbms_output.put_line('p_dt_dmf: '||p_dt_dmf);
  --
  IF p_dt_dmf >= Trunc(SYSDATE) THEN
    --
    SELECT Count(*)
    INTO   w_qtd_periodos_mes
    FROM   FND_LOOKUP_VALUES
    WHERE  language            = userenv('LANG')
    AND    enabled_flag        = 'Y'
    AND    security_group_id   = 0
    AND    view_application_id = 660
    AND    lookup_type         = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
    AND    Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                              AND Trunc(Nvl(end_date_active, SYSDATE))
    ;
    --
    --dbms_output.put_line('w_qtd_periodos_mes: '||w_qtd_periodos_mes);
    --
    w_dias_periodo := omp12001jb.fnd_horizonte_periodo_dec(1,'ATE')
                    - omp12001jb.fnd_horizonte_periodo_dec(1,'DE') + 1
    ;
    --
    --dbms_output.put_line('w_dias_periodo: '||w_dias_periodo);
    --
    FOR i IN 1..w_qtd_periodos_mes LOOP
      --
      IF To_Number(To_Char(SYSDATE,'DD')) <= To_Number(omp12001jb.fnd_horizonte_periodo_dec(i,'ATE')) THEN -- dia de hoje est� no dec�ndio "i"
        --
--        --dbms_output.put_line('To_Number(To_Char(SYSDATE,DD)): '||To_Number(To_Char(SYSDATE,'DD')));
--        --dbms_output.put_line('To_Number(omp12001jb_testeby7.fnd_horizonte_periodo_dec(i,ATE)): '||To_Number(omp12001jb_testeby7.fnd_horizonte_periodo_dec(i,'ATE')));
--        --dbms_output.put_line('fnd_horizonte_periodo_dec(i,DE): '||fnd_horizonte_periodo_dec(i,'DE'));
--        --dbms_output.put_line('To_Char(SYSDATE,MMYYYY: '||To_Char(SYSDATE,'MMYYYY'));
        --
        w_ini_dec := To_Date(To_Char(fnd_horizonte_periodo_dec(i,'DE'),'00') || To_Char(SYSDATE,'MMYYYY'), 'DDMMYYYY');
        --
        --dbms_output.put_line('w_ini_dec.: '||w_ini_dec);
        --
        EXIT;
        --
      END IF;
      --
    END LOOP;
    --
    IF p_carteira = 'S' THEN -- Se for Carteira, come�a um dec�ndio a mais do que Produ��o
      --
      IF To_Number(To_Char(w_ini_dec,'DD')) >= 21 THEN --$$$$$$$$$$$omp12001jb_testeby7.fnd_horizonte_periodo_dec(w_qtd_periodos_mes,'DE') THEN
        --
        w_ini_dec := Trunc(LAST_DAY(w_ini_dec)) + 1;
        --
        --dbms_output.put_line('@w_ini_dec..: '||w_ini_dec);
        --
      ELSE
        --
        w_ini_dec := w_ini_dec + w_dias_periodo;
        --
        --dbms_output.put_line('@w_ini_dec...: '||w_ini_dec);
        --
      END IF;
      --
    END IF;
    --
    LOOP
      --
      IF To_Number(To_Char(w_ini_dec,'DD')) >= 21 THEN --################# omp12001jb_testeby7.fnd_horizonte_periodo_dec(w_qtd_periodos_mes,'DE') THEN
        --
        w_fim_dec := Trunc(LAST_DAY(w_ini_dec));
        --
      ELSE
        --
        w_fim_dec := w_ini_dec + w_dias_periodo-1;
        --
      END IF;
      --
      --dbms_output.put_line('w_fim_dec: '||w_fim_dec);
      --
      IF Trunc(w_ini_dec) > Trunc(SYSDATE) AND w_periodo = 1 THEN
        w_ini_dec := Trunc(SYSDATE);
      END IF;
      --
      IF Trunc(p_dt_dmf) BETWEEN Trunc(w_ini_dec) AND Trunc(w_fim_dec) THEN
        --
        -- Se for CARTEIRA
        IF p_carteira = 'S' THEN
          --
          IF w_periodo < omp12001jb.fnd_qtd_periodo_dec-1 THEN
            --
            --dbms_output.put_line('RETURN.: '||w_periodo);
            --
            RETURN(w_periodo);
            --
          ELSIF (w_periodo BETWEEN omp12001jb.fnd_qtd_periodo_dec-1
                               AND omp12001jb.fnd_qtd_periodo_dec+1) AND
                (Upper(p_origem) IN ('OUTSOURCING','PORTOKOLL')) THEN
            --
            --dbms_output.put_line('RETURN..: '||fnd_qtd_periodo_dec-1);
            --
            RETURN(omp12001jb.fnd_qtd_periodo_dec-1);
            --
          ELSE
            --
            --dbms_output.put_line('RETURN...: 999');
            --
            RETURN(999);
            --
          END IF;
          --
        -- Se for PRODUCAO
        ELSE
          --
          IF w_periodo < omp12001jb.fnd_qtd_periodo_dec THEN
            --
            --dbms_output.put_line('RETURN.: '||w_periodo);
            --
            RETURN(w_periodo);
            --
          ELSIF (w_periodo BETWEEN omp12001jb.fnd_qtd_periodo_dec
                               AND omp12001jb.fnd_qtd_periodo_dec+2) AND
                (Upper(p_origem) IN ('OUTSOURCING','PORTOKOLL')) THEN
            --
            --dbms_output.put_line('RETURN..: '||fnd_qtd_periodo_dec);
            --
            RETURN(omp12001jb.fnd_qtd_periodo_dec);
            --
          ELSE
            --
            --dbms_output.put_line('RETURN...: 999');
            --
            RETURN(999);
            --
          END IF;
          --
        END IF;
        --
      END IF;
      --
      w_ini_dec := w_fim_dec + 1;
      w_periodo := w_periodo + 1;
      --
    END LOOP;
    --
  ELSE
    --
    IF p_carteira = 'S' THEN -- Se for Carteira, pedidos com DMF anterior considerar como do primeiro periodo
      RETURN(1);
    ELSE
      RETURN(999);
    END IF;
    --
  END IF;
  --
EXCEPTION
  WHEN OTHERS THEN
    Raise_Application_Error(-20000, 'Erro ao selecionar o per�odo - '||SQLERRM);
END fnd_periodo_dec;


--Fun��o criada para redefini��o de descritivo de periodos do dec�ndio
--Guilherme Rodrigues - 06/04/2021 
FUNCTION fnd_ajusta_periodos RETURN NUMBER IS
  --
 nDia number;
 dtBase date;
 dtAtu date;
 dtIni date;
 dtFim date;
 dtAtual date;

BEGIN
  SELECT extract(day from SYSDATE) into nDia FROM DUAL;

  SELECT LAST_UPDATE_DATE 
  into dtAtu 
  from FND_LOOKUP_VALUES
  WHERE language            = userenv('LANG')
    AND enabled_flag        = 'Y'
    AND LOOKUP_CODE = 1 
    AND LOOKUP_TYPE = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
    AND VIEW_APPLICATION_ID = 660
    AND SECURITY_GROUP_ID = 0
    AND Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                         AND Trunc(Nvl(end_date_active, SYSDATE));

  dtBase := trunc(sysdate);

  -- Testes
  --nDia:= 11;
  --dtBase := to_date('11/05/2021','dd/MM/yyyy');
  --select sysdate - 75 from dual


  if trunc(dtBase) <> trunc(dtAtu) then 
     if nvl(nDia,0) = 1 or nvl(nDia,0) = 11 or nvl(nDia,0) = 21 then
         dtAtual := dtBase;
         FOR i IN 1..10 LOOP
            IF i <> 10 then
                dtIni := dtAtual;

                if extract(day from dtIni) = 21 then
                    dtFim := last_day(dtIni); 
                else
                    dtFim := dtAtual + 9;
                end if;

                dtAtual := dtFim + 1;
            else
                dtIni := dtAtual;
                --dtFim := last_day(dtIni);

                if nvl(nDia,0) = 1 then 
                    dtFim := last_day(dtIni);
                end if;

                dtAtual := add_months(dtAtual,1);
                if nvl(nDia,0) = 11 then 
                    dtFim := '10/' || to_char(dtAtual,'MM/YYYY');
                end if;

                if nvl(nDia,0) = 21 then 
                    dtFim := '20/' || to_char(dtAtual,'MM/YYYY');
                end if;
            end if;


            UPDATE FND_LOOKUP_VALUES 
            SET DESCRIPTION = to_char(dtIni,'DD-mon-YYYY') || ' at� ' || to_char(dtFim, 'DD-mon-YYYY'), 
            LAST_UPDATE_DATE = SYSDATE
            WHERE 1=1 --language = userenv('LANG')
            AND enabled_flag        = 'Y'
            AND LOOKUP_CODE = i 
            AND LOOKUP_TYPE = 'ONT_ATP_HORIZONTE_SALDO_DEC_PB'
            AND VIEW_APPLICATION_ID = 660
            AND SECURITY_GROUP_ID = 0
            AND Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                 AND Trunc(Nvl(end_date_active, SYSDATE));

            COMMIT;


         END LOOP;
     end if;
  end if;

  RETURN(1);
  --
EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20000, 'Erro ao selecionar os periodos validos dec�ndios - '||SQLERRM);
    RETURN(99);
END fnd_ajusta_periodos;


--
--**************************************************************************
FUNCTION fnd_only_positive (p_number number) RETURN NUMBER is
begin
  if p_number > 0 then
    return(p_number);
  else
    return(0);
  end if;
exception
  when others then
    --
    Raise_Application_Error(-29000, 'Erro na função omp12001jb.fnd_only_positive: ERRO:' || SQLERRM);
    --
end;
--
--**************************************************************************
/*
PROCEDURE prc_valida_contra_estoque (p_segment1               IN  NUMBER
                                    ,p_projetar_pbshop        OUT VARCHAR2
                                    ,p_projetar_demais_canais OUT VARCHAR2
                                    )
IS
  --
  w_item_ce_demais_canais NUMBER;
  w_item_ce_pbshop        NUMBER;
  --
BEGIN
  --
  p_projetar_pbshop        := 'S';
  p_projetar_demais_canais := 'S';
  --
  SELECT Count(*)
    INTO w_item_ce_pbshop
    FROM FND_LOOKUP_VALUES
   WHERE LANGUAGE            = USERENV('LANG')
     AND enabled_flag        = 'Y'
     AND security_group_id   = 0
     AND view_application_id = 660
     AND lookup_type         = 'ONT_ATP_PRODUTOS_CALCULA_DMF'
     AND description         = p_segment1
     AND tag                 = '4' -->Portobello Shop
     AND Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                            AND Trunc(Nvl(end_date_active, SYSDATE))
  ;
  --
  IF w_item_ce_pbshop > 0 THEN
    --
    p_projetar_pbshop := 'N';
    --
  ELSE
    --
    SELECT Count(*)
      INTO w_item_ce_demais_canais
      FROM FND_LOOKUP_VALUES
     WHERE LANGUAGE            = USERENV('LANG')
       AND enabled_flag        = 'Y'
       AND security_group_id   = 0
       AND view_application_id = 660
       AND lookup_type         = 'ONT_ATP_PRODUTOS_CALCULA_DMF'
       AND description         = p_segment1
       AND tag                 IN ('1','2','7') -->Engenharia, Revenda, Exporta��o
       AND Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                              AND Trunc(Nvl(end_date_active, SYSDATE))
    ;
    --
    IF w_item_ce_demais_canais > 0 THEN
      --
      p_projetar_demais_canais := 'N';
      --
    END IF;
    --
  END IF;
  --
END;
*/
--Fun��o de retorno de quantidade de carteira do item/periodo/CD Interno
FUNCTION fnd_carteira_interna(p_item    NUMBER
                      ,p_um      VARCHAR2
                      ,p_periodo NUMBER
                      ,p_cd      VARCHAR2) RETURN NUMBER
IS
  --
  CURSOR c_carteira (p_inventory_item_id NUMBER
                    ,p_item_um           VARCHAR2
                    ,p_id_periodo        NUMBER
                    ,p_cd                VARCHAR2
                    )
  IS
    SELECT sum(ola.ordered_quantity - NVL((SELECT SUM(mr.reservation_quantity)
                                             FROM MTL_RESERVATIONS mr
                                            WHERE mr.demand_source_line_id = ola.line_id),0)) qt_item
    FROM
    OE_ORDER_LINES_ALL        ola
    inner join OE_ORDER_HEADERS_ALL  oha  on  ola.org_id = oha.org_id AND ola.header_id = oha.header_id
    inner join OE_TRANSACTION_TYPES_ALL  tta on tta.transaction_type_id               = oha.order_type_id
    left join (select * from mtl_system_items_b where organization_id = pb_master_organization_id ) msi on ola.inventory_item_id = msi.inventory_item_id
    left join TEMP_DRP_RESSUPRIMENTO f on oha.order_number = f.ordem_venda and msi.segment1 = f.cod_produto
    WHERE ola.order_quantity_uom  = p_item_um
    AND   ola.inventory_item_id   = p_inventory_item_id
    AND   f.ot is null
    AND   ola.booked_flag         = 'Y'
    AND   ola.open_flag           = 'Y'
    AND   ola.cancelled_flag      = 'N'
    and   oha.org_id              = fnd_profile.value('ORG_ID')
    and   oha.order_type_id not in (1002,4504, 1823, 5753, 2243)
    AND   tta.transaction_type_code             = 'ORDER'
    AND   nvl(tta.sales_document_type_code,'O') <> 'B'
    AND   oha.cancelled_flag                    = 'N'
    AND   oha.booked_flag                       = 'Y'
    AND   oha.open_flag                         = 'Y'
    AND   ola.flow_status_code                  = 'AWAITING_SHIPPING'
    AND   omp12001jb.fnd_periodo_dec(ola.schedule_ship_date
                                           ,(SELECT a.origem_item
                                               FROM apps.CONSULTA_PRODUTO_PB_V a
                                              WHERE a.cod_produto = ola.ordered_item AND a.master_organization_id= pb_master_organization_id
                                            )
                                           ,'S') = p_id_periodo
    AND EXISTS (SELECT 1
                  FROM MTL_PARAMETERS e
                 WHERE e.organization_id = ola.ship_from_org_id
                   AND e.organization_code IN (SELECT LOOKUP_CODE
                                                 FROM FND_LOOKUP_VALUES
                                                WHERE LANGUAGE            = USERENV('LANG')
                                                  AND enabled_flag        = 'Y'
                                                  AND security_group_id   = 0
                                                  AND view_application_id = 660
                                                  --
                                                  AND LOOKUP_CODE = p_cd
                                                  --
                                                  AND lookup_type         = 'ONT_ATP_ORG_CD_PB'
                                                  AND Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                                         AND Trunc(Nvl(end_date_active, SYSDATE))
                                              )
                );                                           
BEGIN
  --
  FOR r_carteira IN c_carteira (p_item, p_um, p_periodo, p_cd) LOOP
    --
    RETURN(r_carteira.qt_item);
    --
  END LOOP;
  --
END;


--**************************************************************************
--**************************************************************************
--**************************************************************************
FUNCTION fnd_carteira (p_item    NUMBER
                      ,p_um      VARCHAR2
                      ,p_periodo NUMBER
                      ,p_cd      VARCHAR2) RETURN NUMBER
IS
  --
  CURSOR c_carteira (p_inventory_item_id NUMBER
                    ,p_item_um           VARCHAR2
                    ,p_id_periodo        NUMBER
                    ,p_cd                VARCHAR2
                    )
  IS
    SELECT sum(ola.ordered_quantity - NVL((SELECT SUM(mr.reservation_quantity)
                                             FROM MTL_RESERVATIONS mr
                                            WHERE mr.demand_source_line_id = ola.line_id),0)) qt_item
    FROM
    OE_ORDER_LINES_ALL        ola
    inner join OE_ORDER_HEADERS_ALL  oha  on  ola.org_id = oha.org_id AND ola.header_id = oha.header_id
    inner join OE_TRANSACTION_TYPES_ALL  tta on tta.transaction_type_id               = oha.order_type_id
    left join (select * from mtl_system_items_b where organization_id = pb_master_organization_id ) msi on ola.inventory_item_id = msi.inventory_item_id
    left join TEMP_DRP_RESSUPRIMENTO f on oha.order_number = f.ordem_venda and msi.segment1 = f.cod_produto
    WHERE ola.order_quantity_uom  = p_item_um
    AND   ola.inventory_item_id   = p_inventory_item_id
    AND   f.ot is null
    AND   ola.booked_flag         = 'Y'
    AND   ola.open_flag           = 'Y'
    AND   ola.cancelled_flag      = 'N'
    and   oha.org_id              = fnd_profile.value('ORG_ID')
    and   oha.order_type_id not in (1002,4504, 1823, 5753, 2243)
    AND   tta.transaction_type_code             = 'ORDER'
    AND   nvl(tta.sales_document_type_code,'O') <> 'B'
    AND   oha.cancelled_flag                    = 'N'
    AND   oha.booked_flag                       = 'Y'
    AND   oha.open_flag                         = 'Y'
    AND   ola.flow_status_code                  = 'AWAITING_SHIPPING'
    AND   omp12001jb.fnd_periodo_dec(ola.schedule_ship_date
                                           ,(SELECT a.origem_item
                                               FROM apps.CONSULTA_PRODUTO_PB_V a
                                              WHERE a.cod_produto = ola.ordered_item AND a.master_organization_id= pb_master_organization_id
                                            )
                                           ,'S') = p_id_periodo
    AND   NOT EXISTS ( SELECT SUM(mr.reservation_quantity)
                         FROM MTL_RESERVATIONS     mr
                             ,OE_ORDER_LINES_ALL   ola2
                        WHERE mr.demand_source_line_id = ola.line_id
                          AND ola2.header_id           = ola.header_id
                          AND ola2.line_id             = ola.line_id
                        HAVING SUM(mr.reservation_quantity) > 0
                    )
    AND EXISTS (SELECT 1
                  FROM MTL_PARAMETERS e
                 WHERE e.organization_id = ola.ship_from_org_id
                   AND e.organization_code IN (SELECT LOOKUP_CODE
                                                 FROM FND_LOOKUP_VALUES
                                                WHERE LANGUAGE            = USERENV('LANG')
                                                  AND enabled_flag        = 'Y'
                                                  AND security_group_id   = 0
                                                  AND view_application_id = 660
                                                  --
                                                  AND ( (LOOKUP_CODE = P_CD)
                                                  OR
                                                   (NVL(P_CD,'X') = 'X' AND TAG = 'S')
                                                  )
                                                  --
                                                  AND lookup_type         = 'ONT_ATP_ORG_CD_PB'
                                                  AND Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                                         AND Trunc(Nvl(end_date_active, SYSDATE))
                                              )
                )
    AND nvl(oha.sales_channel_code,0) = 4;
--
BEGIN
  --
  FOR r_carteira IN c_carteira (p_item, p_um, p_periodo, p_cd) LOOP
    --
    RETURN(r_carteira.qt_item);
    --
  END LOOP;
  --
END;

--**************************************************************************
FUNCTION fnd_carteira_shop (p_item    NUMBER
                      ,p_um      VARCHAR2
                      ,p_periodo NUMBER) RETURN NUMBER
IS
  --
  CURSOR c_carteira (p_inventory_item_id NUMBER
                    ,p_item_um           VARCHAR2
                    ,p_id_periodo        NUMBER
                    )
  IS
    SELECT sum(ola.ordered_quantity - NVL((SELECT SUM(mr.reservation_quantity)
                                             FROM MTL_RESERVATIONS mr
                                            WHERE mr.demand_source_line_id = ola.line_id),0)) qt_item
    FROM
    OE_ORDER_LINES_ALL        ola
    inner join OE_ORDER_HEADERS_ALL  oha  on  ola.org_id = oha.org_id AND ola.header_id = oha.header_id
    inner join OE_TRANSACTION_TYPES_ALL  tta on tta.transaction_type_id               = oha.order_type_id
    left join (select * from mtl_system_items_b where organization_id = pb_master_organization_id ) msi on ola.inventory_item_id = msi.inventory_item_id
    left join TEMP_DRP_RESSUPRIMENTO f on oha.order_number = f.ordem_venda and msi.segment1 = f.cod_produto
    WHERE ola.order_quantity_uom  = p_item_um
    AND   ola.inventory_item_id   = p_inventory_item_id
    AND   f.ot is null
    AND   ola.booked_flag         = 'Y'
    AND   ola.open_flag           = 'Y'
    AND   ola.cancelled_flag      = 'N'
    and   oha.org_id              = fnd_profile.value('ORG_ID')
    and   oha.order_type_id not in (1002,4504, 1823, 5753, 2243)
    AND   tta.transaction_type_code             = 'ORDER'
    AND   nvl(tta.sales_document_type_code,'O') <> 'B'
    AND   oha.cancelled_flag                    = 'N'
    AND   oha.booked_flag                       = 'Y'
    AND   oha.open_flag                         = 'Y'
    AND   ola.flow_status_code                  = 'AWAITING_SHIPPING'
    AND   omp12001jb.fnd_periodo_dec(ola.schedule_ship_date
                                           ,(SELECT a.origem_item
                                               FROM apps.CONSULTA_PRODUTO_PB_V a
                                              WHERE a.cod_produto = ola.ordered_item AND a.master_organization_id= pb_master_organization_id
                                            )
                                           ,'S') = p_id_periodo
    AND   NOT EXISTS ( SELECT SUM(mr.reservation_quantity)
                         FROM MTL_RESERVATIONS     mr
                             ,OE_ORDER_LINES_ALL   ola2
                        WHERE mr.demand_source_line_id = ola.line_id
                          AND ola2.header_id           = ola.header_id
                          AND ola2.line_id             = ola.line_id
                        HAVING SUM(mr.reservation_quantity) > 0
                    )
    AND nvl(oha.sales_channel_code,0) = 4;
--
BEGIN
  --
  FOR r_carteira IN c_carteira (p_item, p_um, p_periodo) LOOP
    --
    RETURN(r_carteira.qt_item);
    --
  END LOOP;
  --
END;

--**************************************************************************
--**************************************************************************
--**************************************************************************
FUNCTION fnd_saldo_anterior_cd (p_item    VARCHAR2
                               ,p_periodo NUMBER
                               ,p_cd      VARCHAR2) RETURN NUMBER IS
  --
  w_saldo_anterior NUMBER := 0;
  --
BEGIN
  --
  IF p_periodo > 1 THEN
    --
    select Nvl(Sum(saldo_total),0)
      into w_saldo_anterior
      from OM_SALDO_PRODUTO_ATP_JB_CD_V2
     where cod_item   = p_item
       and des_cd     = p_cd
       and id_periodo = p_periodo-1
    ;
    --
  END IF;
  --
  if Nvl(w_saldo_anterior,0) < 0 then
    RETURN(w_saldo_anterior);
  else
    RETURN(0);
  end if;
  --
EXCEPTION
  WHEN OTHERS THEN
    Dbms_Output.put_line('Erro ao retornar saldo anterior (fnd_saldo_anterior_cd) - w_saldo_anterior = '||w_saldo_anterior||' - '||SQLERRM);
    RETURN(0);
END fnd_saldo_anterior_cd;
--
--**************************************************************************

PROCEDURE calcula_producao_atp (w_errbuf  OUT VARCHAR2, w_retcode OUT NUMBER) IS
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- Guilherme de Andrade Rodrigues - 18.08.2021
  -- CARGA EM PB_PRODUCAO_PP_ATP - Apartado para calculo de Saldo Projetado
  -- Versao: 1.0
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  --
  CURSOR c_base IS
    SELECT msib.inventory_item_id,
           msib.segment1,
           msib.description,
           msib.primary_uom_code,
           fmd.inventory_item_id p_prod_id
      FROM fm_form_mst_b      ffm,
           fm_matl_dtl        fmd,
           fm_matl_dtl        fmd_i,
           mtl_system_items_b msib
     WHERE ffm.formula_id = fmd.formula_id
       AND ffm.formula_status = 700
       AND fmd.line_type = 1 /*1 PRODUTO*/
       AND fmd_i.line_type = -1 /*-1 INGREDIENTE*/
       AND fmd_i.formula_id = fmd.formula_id
       AND fmd_i.inventory_item_id = msib.inventory_item_id
       AND msib.item_type = 'BASE'
       and msib.organization_id = pb_master_organization_id;

  CURSOR c_producao(p_id_planejamento number, P_short_code varchar2) IS
    SELECT gbh.plant_code cod_fabrica,
           gbh.batch_no cod_ordem,
           gbh.batch_id,
           decode(gbh.batch_status,
                  -1,
                  'Cancelado',
                  1,
                  'Pendente',
                  2,
                  'WIP',
                  3,
                  'Concluido',
                  4,
                  'Fechado') status_ordem,
           nvl(frh.attribute1, 0) cod_minifabrica,
           nvl(frh.attribute2, 0) cod_linha_producao,
           gbh.plan_start_date,
           gbh.actual_start_date,
           gbh.plan_cmplt_date,
           gbh.actual_cmplt_date,
           gbh.attribute3 tipo_op,
           nvl(gmd.actual_qty, 0) actual_qty,
           nvl(gmd.plan_qty, 0) plan_qty,
           gbh.order_priority,
           dpp.inventory_item_id,
           dpp.item_um,
           dpp.cod,
           dpp.descricao,
           dpp.origem,
           dpp.fornecedor,
           dpp.cd_marca,
           dpp.cd_origem_item,
           fu.user_name
      FROM gme_batch_header gbh, gme_material_details gmd, gmd_routings frh
           ,mtl_parameters mp, pb_carga_dados_pp dpp, fnd_user fu
     WHERE mp.organization_id = gbh.organization_id
       AND gbh.batch_id = gmd.batch_id
       AND gbh.batch_status IN (1, 2, 3) /*1 - Pendente, 2 - WIP, 3 - Concluido*/
       AND gmd.line_type = 1 -- Produto
       AND frh.routing_id = gbh.routing_id
       and mp.master_organization_id = pb_master_organization_id
       and dpp.org_code = P_short_code
       and gmd.inventory_item_id = dpp.inventory_item_id       
       and gbh.created_by = fu.user_id
    UNION ALL
    SELECT mp.organization_code cod_fabrica,
           op.nr_ordem_producao cod_ordem,
           cast(null as integer) batch_id,
           'Planejada' status_ordem,
           nvl(frh.attribute1, 0) cod_minifabrica,
           nvl(frh.attribute2, 0) cod_linha_producao,
           op.dt_prioridade plan_start_date,
           cast(null as date) actual_start_date,
           op.dt_prioridade+1 plan_cmplt_date,
           cast(null as date) actual_cmplt_date,
           '9' tipo_op,
           0 actual_qty,
           nvl(item.qt_demanda, 0) plan_qty,
           op.nr_prioridade order_priority,
           dpp.inventory_item_id,
           dpp.item_um,
           dpp.cod,
           dpp.descricao,
           dpp.origem,
           dpp.fornecedor,
           dpp.cd_marca,
           dpp.cd_origem_item,
           fu.user_name
    FROM GMP_PRE_ORDEM_PRODUCAO_EVT_V  OP
        ,GMP_ITEM_PRE_ORDEM_PROD_EVT_V ITEM
        ,gmd_routings                  frh
        ,mtl_parameters                mp
        ,pb_carga_dados_pp             dpp
        ,fnd_user                      fu
    WHERE op.id_pre_ordem_producao = item.id_pre_ordem_producao
      AND op.routing_id            = frh.ROUTING_ID
      AND mp.organization_id       = item.organization_id
      AND op.id_status_ordem_pre <> 'CRI'
      AND op.id_status_ordem_drm = 'P'
      AND op.id_planejamento     = p_id_planejamento
      AND op.nr_linha_mini       is not null
      and dpp.org_code = P_short_code
      and item.inventory_item_id = dpp.inventory_item_id
      and fu.user_id = op.created_by;


  CURSOR c_compra(P_short_code varchar2) IS
    SELECT oc.*, dpp.inventory_item_id,
                           dpp.item_um,
                           dpp.cod,
                           dpp.descricao,
                           dpp.origem,
                           dpp.fornecedor,
                           dpp.cd_marca,
                           dpp.cd_origem_item
      FROM pb_ordem_compra_001 oc, pb_carga_dados_pp dpp
     WHERE oc.segment1 = dpp.cod
       and dpp.org_code = P_short_code;


  v_qtd_plam_mto    NUMBER;
  -- Parametros P/ Geracao do Arquivo  --
  v_diretorio VARCHAR2(100);
  v_arquivo   VARCHAR2(30);
  arq_saida   utl_file.file_type;
  v_separador VARCHAR2(20);

  q_carga_prod     BOOLEAN;
  --
  dia_ref  NUMBER;
  w_semana NUMBER;
  v_short_code hr_operating_units.short_code%type;
  w_cd_organization_id NUMBER;
  v_id_planejamento GMP_PRE_ORDEM_PRODUCAO_EVT.id_planejamento%type;
  --
BEGIN
  --
  select max(id_planejamento)
    into v_id_planejamento
    from GMP_PRE_ORDEM_PRODUCAO_EVT;
  --
  fnd_file.put_line(fnd_file.log,'Time: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
  dia_ref := 1; --1 - Domingo 2 Segunda Feira.
  --
  q_carga_prod     := TRUE;

  w_cd_organization_id := pb_master_organization_id;

  --
  begin
  Select nvl(b.short_code,'PB')
    into v_short_code
    from hr_operating_units            b
   where  b.organization_id        = fnd_profile.value('ORG_ID');
  exception when others then
    v_short_code := pb_master_organization_id;
  end;

  -- INICIO PP PRODUCAO
  IF q_carga_prod THEN
    --
    DECLARE
      w_data_ini     DATE;
      w_data_fim     DATE;
      w_semana       NUMBER;
      w_semana_fim   NUMBER;
      w_dt_temp      DATE;
      w_dia          NUMBER;
      w_last_dt_per  DATE;
      w_dias_prod    NUMBER;
      w_prec_prod    NUMBER;
      w_qtd_prod     NUMBER;
      w_qtd_prod_sem NUMBER;
      w_qtd_pendente NUMBER;
    BEGIN
      --
      fnd_file.put_line(fnd_file.log,'q_carga_prod');
      fnd_file.put_line(fnd_file.log,'Time: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
      DELETE pb_producao_pp_atp where org_code = v_short_code;

        FOR r_prod IN c_producao(V_id_planejamento, v_short_code) LOOP
          -- Pesquisa reservas MTO.
          fnd_file.put_line(fnd_file.log,'Time1: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
          fnd_file.put_line(fnd_file.log,
                            'Ordem: ' || r_prod.cod_fabrica || '-' ||
                            r_prod.cod_ordem || ' Qtd Planejada: ' ||
                            r_prod.plan_qty || ' Qtd Real: ' ||
                            r_prod.actual_qty);
          --
          SELECT nvl(SUM(oll.ordered_quantity), 0)
            INTO v_qtd_plam_mto
            FROM nin_reservation_rules_mto      rr,
                 nin_reservation_rule_lines_mto rl,
                 oe_order_lines_all             oll
           WHERE rl.rule_id = rr.rule_id
             AND rr.status = 'A'
             AND rl.status = 'A'
             AND rl.reservation_id IS NULL
             AND rl.header_id = oll.header_id
             AND rl.line_id = oll.line_id
             AND rr.op_header_id = r_prod.batch_id
             --AND rr.inventory_item_id = dados.inventory_item_id
             AND rr.inventory_item_id = r_prod.inventory_item_id
             ;
          --
          ------------------------------------------------------
          --
          BEGIN
            --
            SELECT decode(r_prod.status_ordem,
                          'WIP',
                          r_prod.actual_start_date,
                          r_prod.plan_start_date)
              INTO w_data_ini
              FROM dual;
            --
            w_qtd_prod    := r_prod.actual_qty;
            w_semana      := to_number(to_char(w_data_ini, 'iw'));
            w_dt_temp     := to_date('01/01/' ||
                                     to_char(w_data_ini, 'yyyy'),
                                     'dd/mm/yyyy');
            w_dia         := to_number(to_char(w_dt_temp, 'd'));
            w_last_dt_per := trunc(last_day(w_data_ini)) + .99999;
            w_dias_prod   := r_prod.plan_cmplt_date - w_data_ini;
            --
            IF w_dias_prod = 0 THEN
              w_dias_prod := 1;
            END IF;
            --
            IF w_semana > to_number(to_char(r_prod.plan_cmplt_date, 'iw')) THEN
              fnd_file.put_line(fnd_file.log,
                                'w_semana: ' || w_semana ||
                                ' w_semana_fim: ' ||
                                to_number(to_char(r_prod.plan_cmplt_date,
                                                  'iw')));
              --if to_number(to_char(w_data_ini,'YYYY')) < to_number(to_char(r_prod.plan_cmplt_date,'YYYY')) then
              w_semana_fim := to_number(to_char(r_prod.plan_cmplt_date,
                                                'iw')) + w_semana + 1;
              fnd_file.put_line(fnd_file.log,
                                'Ordem de virada de ano. w_semana: ' ||
                                w_semana || ' w_semana_fim: ' ||
                                w_semana_fim);
              --else
              --  w_semana_fim := w_semana;
              fnd_file.put_line(fnd_file.log,
                                'Ordem com data de inicio maior que a data de termino, OP ' ||
                                r_prod.cod_ordem || ' Fabrica ' ||
                                r_prod.cod_fabrica || '. w_semana_fim:' ||
                                to_number(to_char(r_prod.plan_cmplt_date,
                                                  'iw')));
              --end if;
            ELSE
              w_semana_fim := to_number(to_char(r_prod.plan_cmplt_date,
                                                'iw'));
            END IF;
            --
            FOR i IN w_semana .. w_semana_fim LOOP
              --
              BEGIN
                --
                WHILE w_data_ini > (w_dt_temp + w_semana * 7 -
                      (7 + w_dia - dia_ref)) + .99999 LOOP
                  --fnd_file.put_line(fnd_file.log,'dt inicio maior que dt fim. Dt Ini: '||w_data_ini||' - Semana: '||w_semana||' - dt_fim: '||(w_dt_temp + w_semana * 7  - (7 + w_dia - dia_ref)));
                  w_semana := w_semana + 1;
                  --w_data_ini := w_dt_temp + w_semana * 7 - (7 + w_dia - dia_ref);
                END LOOP;
                --
                IF r_prod.plan_cmplt_date < (w_dt_temp + w_semana * 7 -
                   (7 + w_dia - dia_ref)) + .99999 THEN
                  w_data_fim := r_prod.plan_cmplt_date;
                  --fnd_file.put_line(fnd_file.log,'1. w_data_fim: '||w_data_fim);
                ELSE
                  w_data_fim := (w_dt_temp + w_semana * 7 -
                                (7 + w_dia - dia_ref)) + .99999;
                END IF;
                --
                -- verificar se a ordem vai virar o mes.
                IF w_data_fim > w_last_dt_per THEN
                  -- Ordem vai viar o mes.
                  --
                  w_prec_prod := ((w_last_dt_per - w_data_ini) * 100) /
                                 w_dias_prod;
                  IF w_prec_prod = 0 THEN
                    w_prec_prod := 100;
                  END IF;
                  --
                  IF ((w_prec_prod * r_prod.plan_qty) / 100) > w_qtd_prod THEN
                    w_qtd_prod_sem := w_qtd_prod;
                    w_qtd_prod     := 0;
                  ELSIF ((w_prec_prod * r_prod.plan_qty) / 100) <
                        w_qtd_prod THEN
                    --
                    w_qtd_prod_sem := ((w_prec_prod * r_prod.plan_qty) / 100);
                    w_qtd_prod     := w_qtd_prod -
                                      ((w_prec_prod * r_prod.plan_qty) / 100);
                    --
                    IF w_qtd_prod < 0 THEN
                      w_qtd_prod := 0;
                    END IF;
                  ELSIF ((w_prec_prod * r_prod.plan_qty) / 100) = 0 THEN
                    w_qtd_prod_sem := 0;
                  END IF;
                  --
                  w_qtd_pendente := ((w_prec_prod * r_prod.plan_qty) / 100) -
                                    w_qtd_prod_sem;
                  --
                  IF w_data_ini < w_last_dt_per THEN
                    --
                    insert into pb_producao_pp_atp
                    VALUES
                      (r_prod.inventory_item_id,
                       NULL,
                       SYSDATE,
                       fnd_global.user_id,
                       fnd_global.conc_request_id,
                       r_prod.cod,
                       r_prod.item_um,
                       r_prod.cod_fabrica,
                       r_prod.cod_ordem,
                       r_prod.status_ordem,
                       r_prod.cod_minifabrica,
                       r_prod.cod_linha_producao,
                       w_data_ini,
                       r_prod.actual_start_date,
                       w_last_dt_per,
                       r_prod.actual_cmplt_date,
                       r_prod.tipo_op,
                       ((w_prec_prod * r_prod.plan_qty) / 100),
                       w_qtd_prod_sem,
                       w_qtd_pendente,
                       v_qtd_plam_mto,
                       w_semana,
                       r_prod.order_priority,
                       r_prod.cod_fabrica,
                       v_short_code,
                       r_prod.cd_marca,
                       r_prod.cd_origem_item,
                       r_prod.user_name,
                       null);
                    --
                  END IF;
                  --
                  w_data_ini    := w_last_dt_per + .00001;
                  w_last_dt_per := trunc(last_day(w_data_ini)) + .99999;
                END IF;
                --
                w_prec_prod := ((w_data_fim - w_data_ini) * 100) /
                               w_dias_prod;
                IF w_prec_prod = 0 THEN
                  w_prec_prod := 100;
                END IF;
                --
                IF ((w_prec_prod * r_prod.plan_qty) / 100) > w_qtd_prod THEN
                  w_qtd_prod_sem := w_qtd_prod; --((w_prec_prod * r_prod.actual_qty) / 100);
                  w_qtd_prod     := 0; --(((w_prec_prod * r_prod.actual_qty) / 100) - w_qtd_prod);
                ELSIF ((w_prec_prod * r_prod.plan_qty) / 100) < w_qtd_prod THEN
                  IF /*w_semana*/
                   i = to_number(to_char(r_prod.plan_cmplt_date, 'iw')) THEN
                    -- Ultima semana.
                    w_qtd_prod_sem := w_qtd_prod; --((w_prec_prod * r_prod.actual_qty) / 100);
                    w_qtd_prod     := 0; --(((w_prec_prod * r_prod.actual_qty) / 100) - w_qtd_prod);
                  ELSE
                    w_qtd_prod_sem := ((w_prec_prod * r_prod.plan_qty) / 100);
                    w_qtd_prod     := w_qtd_prod -
                                      ((w_prec_prod * r_prod.plan_qty) / 100);
                  END IF;
                  IF w_qtd_prod < 0 THEN
                    w_qtd_prod := 0;
                  END IF;
                ELSIF ((w_prec_prod * r_prod.plan_qty) / 100) = 0 THEN
                  w_qtd_prod_sem := 0;
                END IF;
                --
                w_qtd_pendente := ((w_prec_prod * r_prod.plan_qty) / 100) -
                                  w_qtd_prod_sem;
                IF w_qtd_pendente < 0 THEN
                  w_qtd_pendente := 0;
                END IF;
                --
                if w_data_ini != w_data_fim then
                  --
                  INSERT INTO pb_producao_pp_atp
                  VALUES
                    (r_prod.inventory_item_id,
                     NULL,
                     SYSDATE,
                     fnd_global.user_id,
                     fnd_global.conc_request_id,
                     r_prod.cod,
                     r_prod.item_um,
                     r_prod.cod_fabrica,
                     r_prod.cod_ordem,
                     r_prod.status_ordem,
                     r_prod.cod_minifabrica,
                     r_prod.cod_linha_producao,
                     w_data_ini,
                     r_prod.actual_start_date,
                     w_data_fim,
                     r_prod.actual_cmplt_date,
                     r_prod.tipo_op,
                     ((w_prec_prod * r_prod.plan_qty) / 100),
                     w_qtd_prod_sem,
                     w_qtd_pendente,
                     v_qtd_plam_mto,
                     w_semana,
                     r_prod.order_priority,
                     r_prod.cod_fabrica,
                     v_short_code,
                     r_prod.cd_marca,
                     r_prod.cd_origem_item,
                     r_prod.user_name,
                     null);
                  --
                end if;
                --
                w_data_ini := w_data_fim + .00001;
                w_semana   := w_semana + 1;
                --
              EXCEPTION
                WHEN OTHERS THEN
                  fnd_file.put_line(fnd_file.log,
                                    'Erro no item: ' ||
                                    r_prod.inventory_item_id ||
                                    ' w_data_ini: ' || w_data_ini ||
                                    ' w_data_fim: ' || w_data_fim ||
                                    ' Erro: ' || SQLERRM);
              END;
            END LOOP;
            --
          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,
                                'Erro no item: ' || r_prod.inventory_item_id ||
                                ' w_data_ini: ' || w_data_ini ||
                                ' w_data_fim: ' || w_data_fim || ' Erro: ' ||
                                SQLERRM);
          END;
        END LOOP;
        --
        fnd_file.put_line(fnd_file.log,'Time: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));

        --Compras...
        FOR r_compras IN c_compra(v_short_code) LOOP
          --
          INSERT INTO pb_producao_pp_atp
          VALUES
            (r_compras.inventory_item_id,
             NULL,
             SYSDATE,
             NULL,
             NULL,
             r_compras.cod,
             r_compras.item_um,
             r_compras.origem,
             r_compras.po_num,
             NULL,
             'Compras',
             r_compras.fornecedor,
             NULL,
             NULL,
             r_compras.promised_date,
             NULL,
             NULL,
             r_compras.quantity,
             0,
             r_compras.quantity,
             0,
             NULL,
             NULL,
             r_compras.LOCATION_CODE,
             v_short_code,
             r_compras.cd_marca,
             r_compras.cd_origem_item,
             null,
             r_compras.RELEASE_NUM);
          --
        END LOOP;
      --
      fnd_file.put_line(fnd_file.log,'Delete pb_producao_pp_atp');
      fnd_file.put_line(fnd_file.log,'Time: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
      --
      DELETE pb_producao_pp_atp
       WHERE qtd_pendente <= 0.1
         AND qtd_pendente > 0
         and org_code = v_short_code;
      --
    END;
    -- FINAL PP PRODU��O
  END IF;
  fnd_file.put_line(fnd_file.log,'Time: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
  --
EXCEPTION
  WHEN OTHERS THEN
    w_errbuf  := 'Erro geral na Rotina calcula_producao_atp: Erro:' || SQLERRM;
    w_retcode := 2;
END;
--**************************************************************************
--**************************************************************************

PROCEDURE calcula_producao_pointer (w_errbuf  OUT VARCHAR2, w_retcode OUT NUMBER) IS
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- Guilherme de Andrade Rodrigues - 18.08.2021
  -- CARGA EM PB_PRODUCAO_PP_ATP - Apartado para calculo de Saldo Projetado
  -- Versao: 1.0
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  --
  CURSOR c_base IS
    SELECT msib.inventory_item_id,
           msib.segment1,
           msib.description,
           msib.primary_uom_code,
           fmd.inventory_item_id p_prod_id
      FROM fm_form_mst_b      ffm,
           fm_matl_dtl        fmd,
           fm_matl_dtl        fmd_i,
           mtl_system_items_b msib
     WHERE ffm.formula_id = fmd.formula_id
       AND ffm.formula_status = 700
       AND fmd.line_type = 1 /*1 PRODUTO*/
       AND fmd_i.line_type = -1 /*-1 INGREDIENTE*/
       AND fmd_i.formula_id = fmd.formula_id
       AND fmd_i.inventory_item_id = msib.inventory_item_id
       AND msib.item_type = 'BASE'
       and msib.organization_id = pb_master_organization_id;

  CURSOR c_producao(p_id_planejamento number, p_cd_organization_id number) IS
    SELECT gbh.plant_code cod_fabrica,
           gbh.batch_no cod_ordem,
           gbh.batch_id,
           decode(gbh.batch_status,
                  -1,
                  'Cancelado',
                  1,
                  'Pendente',
                  2,
                  'WIP',
                  3,
                  'Concluido',
                  4,
                  'Fechado') status_ordem,
           nvl(frh.attribute1, 0) cod_minifabrica,
           nvl(frh.attribute2, 0) cod_linha_producao,
           gbh.plan_start_date,
           gbh.actual_start_date,
           gbh.plan_cmplt_date,
           gbh.actual_cmplt_date,
           gbh.attribute3 tipo_op,
           nvl(gmd.actual_qty, 0) actual_qty,
           nvl(gmd.plan_qty, 0) plan_qty,
           gbh.order_priority,
           mtl.cod_produto cod,
           mtl.item_id inventory_item_id,
           lower(mtl.unidade) item_um,
           mtl.produto descricao,
           mtl.fornecedororigem origem,
           mtl.fornecedor  fornecedor,
           mtl.marca_item cd_marca, 
           mtl.origem_item cd_origem_item,
           fu.user_name
      FROM gme_batch_header gbh, gme_material_details gmd, gmd_routings frh
           ,mtl_parameters mp, 
           consulta_produto_pt_v mtl ,
           fnd_user fu
     WHERE mp.organization_id = gbh.organization_id
       AND gbh.batch_id = gmd.batch_id
       AND gbh.batch_status IN (1, 2, 3) /*1 - Pendente, 2 - WIP, 3 - Concluido*/
       AND gmd.line_type = 1 -- Produto
       AND frh.routing_id = gbh.routing_id
       and mp.master_organization_id = pb_master_organization_id
       and gmd.inventory_item_id = mtl.item_id       
       and gmd.organization_id = p_cd_organization_id
       and gbh.created_by = fu.user_id
       and nvl(gbh.actual_cmplt_date,gbh.plan_cmplt_date) > sysdate;
       --and (gmd.material_detail_id in(22045348,22045387,22045425)        or gmd.creation_date > sysdate - 1 );


  CURSOR c_compra(P_short_code varchar2) IS
    SELECT oc.*, dpp.inventory_item_id,
                           dpp.item_um,
                           dpp.cod,
                           dpp.descricao,
                           dpp.origem,
                           dpp.fornecedor,
                           dpp.cd_marca,
                           dpp.cd_origem_item
      FROM pb_ordem_compra_001 oc, pb_carga_dados_pp dpp
     WHERE oc.segment1 = dpp.cod
       and dpp.org_code = P_short_code;


  v_qtd_plam_mto    NUMBER;
  -- Parametros P/ Geracao do Arquivo  --
  v_diretorio VARCHAR2(100);
  v_arquivo   VARCHAR2(30);
  arq_saida   utl_file.file_type;
  v_separador VARCHAR2(20);

  q_carga_prod     BOOLEAN;
  --
  dia_ref  NUMBER;
  w_semana NUMBER;
  v_short_code hr_operating_units.short_code%type;
  w_cd_organization_id NUMBER;
  v_id_planejamento GMP_PRE_ORDEM_PRODUCAO_EVT.id_planejamento%type;
  --
BEGIN
  --
  select max(id_planejamento)
    into v_id_planejamento
    from GMP_PRE_ORDEM_PRODUCAO_EVT;
  --
  fnd_file.put_line(fnd_file.log,'Time: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
  dia_ref := 1; --1 - Domingo 2 Segunda Feira.
  --
  q_carga_prod     := TRUE;

  w_cd_organization_id := 1983;
  v_short_code := 'POINTER';

  -- INICIO PP PRODUCAO
  IF q_carga_prod THEN
    --
    DECLARE
      w_data_ini     DATE;
      w_data_fim     DATE;
      w_semana       NUMBER;
      w_semana_fim   NUMBER;
      w_dt_temp      DATE;
      w_dia          NUMBER;
      w_last_dt_per  DATE;
      w_dias_prod    NUMBER;
      w_prec_prod    NUMBER;
      w_qtd_prod     NUMBER;
      w_qtd_prod_sem NUMBER;
      w_qtd_pendente NUMBER;
    BEGIN
      --
      fnd_file.put_line(fnd_file.log,'q_carga_prod');
      fnd_file.put_line(fnd_file.log,'Time: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));

      DELETE pb_producao_pp_atp where org_code = v_short_code;
      COMMIT;

        FOR r_prod IN c_producao(V_id_planejamento, w_cd_organization_id) LOOP
          -- Pesquisa reservas MTO.
          fnd_file.put_line(fnd_file.log,'Time1: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
          fnd_file.put_line(fnd_file.log,
                            'Ordem: ' || r_prod.cod_fabrica || '-' ||
                            r_prod.cod_ordem || ' Qtd Planejada: ' ||
                            r_prod.plan_qty || ' Qtd Real: ' ||
                            r_prod.actual_qty);
          --
          SELECT nvl(SUM(oll.ordered_quantity), 0)
            INTO v_qtd_plam_mto
            FROM nin_reservation_rules_mto      rr,
                 nin_reservation_rule_lines_mto rl,
                 oe_order_lines_all             oll
           WHERE rl.rule_id = rr.rule_id
             AND rr.status = 'A'
             AND rl.status = 'A'
             AND rl.reservation_id IS NULL
             AND rl.header_id = oll.header_id
             AND rl.line_id = oll.line_id
             AND rr.op_header_id = r_prod.batch_id
             --AND rr.inventory_item_id = dados.inventory_item_id
             AND rr.inventory_item_id = r_prod.inventory_item_id
             ;
          --
          ------------------------------------------------------
          --
          BEGIN
            --
            SELECT decode(r_prod.status_ordem,
                          'WIP',
                          r_prod.actual_start_date,
                          r_prod.plan_start_date)
              INTO w_data_ini
              FROM dual;
            --
            w_qtd_prod    := r_prod.actual_qty;
            w_semana      := to_number(to_char(w_data_ini, 'iw'));
            w_dt_temp     := to_date('01/01/' ||
                                     to_char(w_data_ini, 'yyyy'),
                                     'dd/mm/yyyy');
            w_dia         := to_number(to_char(w_dt_temp, 'd'));
            w_last_dt_per := trunc(last_day(w_data_ini)) + .99999;
            w_dias_prod   := r_prod.plan_cmplt_date - w_data_ini;
            --
            IF w_dias_prod = 0 THEN
              w_dias_prod := 1;
            END IF;
            --
            IF w_semana > to_number(to_char(r_prod.plan_cmplt_date, 'iw')) THEN
              fnd_file.put_line(fnd_file.log,
                                'w_semana: ' || w_semana ||
                                ' w_semana_fim: ' ||
                                to_number(to_char(r_prod.plan_cmplt_date,
                                                  'iw')));
              --if to_number(to_char(w_data_ini,'YYYY')) < to_number(to_char(r_prod.plan_cmplt_date,'YYYY')) then
              w_semana_fim := to_number(to_char(r_prod.plan_cmplt_date,
                                                'iw')) + w_semana + 1;
              fnd_file.put_line(fnd_file.log,
                                'Ordem de virada de ano. w_semana: ' ||
                                w_semana || ' w_semana_fim: ' ||
                                w_semana_fim);
              --else
              --  w_semana_fim := w_semana;
              fnd_file.put_line(fnd_file.log,
                                'Ordem com data de inicio maior que a data de termino, OP ' ||
                                r_prod.cod_ordem || ' Fabrica ' ||
                                r_prod.cod_fabrica || '. w_semana_fim:' ||
                                to_number(to_char(r_prod.plan_cmplt_date,
                                                  'iw')));
              --end if;
            ELSE
              w_semana_fim := to_number(to_char(r_prod.plan_cmplt_date,
                                                'iw'));
            END IF;
            --
            FOR i IN w_semana .. w_semana_fim LOOP
              --
              BEGIN
                --
                WHILE w_data_ini > (w_dt_temp + w_semana * 7 -
                      (7 + w_dia - dia_ref)) + .99999 LOOP
                  --fnd_file.put_line(fnd_file.log,'dt inicio maior que dt fim. Dt Ini: '||w_data_ini||' - Semana: '||w_semana||' - dt_fim: '||(w_dt_temp + w_semana * 7  - (7 + w_dia - dia_ref)));
                  w_semana := w_semana + 1;
                  --w_data_ini := w_dt_temp + w_semana * 7 - (7 + w_dia - dia_ref);
                END LOOP;
                --
                IF r_prod.plan_cmplt_date < (w_dt_temp + w_semana * 7 -
                   (7 + w_dia - dia_ref)) + .99999 THEN
                  w_data_fim := r_prod.plan_cmplt_date;
                  --fnd_file.put_line(fnd_file.log,'1. w_data_fim: '||w_data_fim);
                ELSE
                  w_data_fim := (w_dt_temp + w_semana * 7 -
                                (7 + w_dia - dia_ref)) + .99999;
                END IF;
                --
                -- verificar se a ordem vai virar o mes.
                IF w_data_fim > w_last_dt_per THEN
                  -- Ordem vai viar o mes.
                  --
                  w_prec_prod := ((w_last_dt_per - w_data_ini) * 100) /
                                 w_dias_prod;
                  IF w_prec_prod = 0 THEN
                    w_prec_prod := 100;
                  END IF;
                  --
                  IF ((w_prec_prod * r_prod.plan_qty) / 100) > w_qtd_prod THEN
                    w_qtd_prod_sem := w_qtd_prod;
                    w_qtd_prod     := 0;
                  ELSIF ((w_prec_prod * r_prod.plan_qty) / 100) <
                        w_qtd_prod THEN
                    --
                    w_qtd_prod_sem := ((w_prec_prod * r_prod.plan_qty) / 100);
                    w_qtd_prod     := w_qtd_prod -
                                      ((w_prec_prod * r_prod.plan_qty) / 100);
                    --
                    IF w_qtd_prod < 0 THEN
                      w_qtd_prod := 0;
                    END IF;
                  ELSIF ((w_prec_prod * r_prod.plan_qty) / 100) = 0 THEN
                    w_qtd_prod_sem := 0;
                  END IF;
                  --
                  w_qtd_pendente := ((w_prec_prod * r_prod.plan_qty) / 100) -
                                    w_qtd_prod_sem;
                  --
                  IF w_data_ini < w_last_dt_per THEN
                    --
                    insert into pb_producao_pp_atp
                    VALUES
                      (r_prod.inventory_item_id,
                       NULL,
                       SYSDATE,
                       fnd_global.user_id,
                       fnd_global.conc_request_id,
                       r_prod.cod,
                       r_prod.item_um,
                       r_prod.cod_fabrica,
                       r_prod.cod_ordem,
                       r_prod.status_ordem,
                       r_prod.cod_minifabrica,
                       r_prod.cod_linha_producao,
                       w_data_ini,
                       r_prod.actual_start_date,
                       w_last_dt_per,
                       r_prod.actual_cmplt_date,
                       r_prod.tipo_op,
                       ((w_prec_prod * r_prod.plan_qty) / 100),
                       w_qtd_prod_sem,
                       w_qtd_pendente,
                       v_qtd_plam_mto,
                       w_semana,
                       r_prod.order_priority,
                       r_prod.cod_fabrica,
                       v_short_code,
                       r_prod.cd_marca,
                       r_prod.cd_origem_item,
                       r_prod.user_name,
                       null);
                       COMMIT;
                    --
                  END IF;
                  --
                  w_data_ini    := w_last_dt_per + .00001;
                  w_last_dt_per := trunc(last_day(w_data_ini)) + .99999;
                END IF;
                --
                w_prec_prod := ((w_data_fim - w_data_ini) * 100) /
                               w_dias_prod;
                IF w_prec_prod = 0 THEN
                  w_prec_prod := 100;
                END IF;
                --
                IF ((w_prec_prod * r_prod.plan_qty) / 100) > w_qtd_prod THEN
                  w_qtd_prod_sem := w_qtd_prod; --((w_prec_prod * r_prod.actual_qty) / 100);
                  w_qtd_prod     := 0; --(((w_prec_prod * r_prod.actual_qty) / 100) - w_qtd_prod);
                ELSIF ((w_prec_prod * r_prod.plan_qty) / 100) < w_qtd_prod THEN
                  IF /*w_semana*/
                   i = to_number(to_char(r_prod.plan_cmplt_date, 'iw')) THEN
                    -- Ultima semana.
                    w_qtd_prod_sem := w_qtd_prod; --((w_prec_prod * r_prod.actual_qty) / 100);
                    w_qtd_prod     := 0; --(((w_prec_prod * r_prod.actual_qty) / 100) - w_qtd_prod);
                  ELSE
                    w_qtd_prod_sem := ((w_prec_prod * r_prod.plan_qty) / 100);
                    w_qtd_prod     := w_qtd_prod -
                                      ((w_prec_prod * r_prod.plan_qty) / 100);
                  END IF;
                  IF w_qtd_prod < 0 THEN
                    w_qtd_prod := 0;
                  END IF;
                ELSIF ((w_prec_prod * r_prod.plan_qty) / 100) = 0 THEN
                  w_qtd_prod_sem := 0;
                END IF;
                --
                w_qtd_pendente := ((w_prec_prod * r_prod.plan_qty) / 100) -
                                  w_qtd_prod_sem;
                IF w_qtd_pendente < 0 THEN
                  w_qtd_pendente := 0;
                END IF;
                --
                if w_data_ini != w_data_fim then
                  --
                  INSERT INTO pb_producao_pp_atp
                  VALUES
                    (r_prod.inventory_item_id,
                     NULL,
                     SYSDATE,
                     fnd_global.user_id,
                     fnd_global.conc_request_id,
                     r_prod.cod,
                     r_prod.item_um,
                     r_prod.cod_fabrica,
                     r_prod.cod_ordem,
                     r_prod.status_ordem,
                     r_prod.cod_minifabrica,
                     r_prod.cod_linha_producao,
                     w_data_ini,
                     r_prod.actual_start_date,
                     w_data_fim,
                     r_prod.actual_cmplt_date,
                     r_prod.tipo_op,
                     ((w_prec_prod * r_prod.plan_qty) / 100),
                     w_qtd_prod_sem,
                     w_qtd_pendente,
                     v_qtd_plam_mto,
                     w_semana,
                     r_prod.order_priority,
                     r_prod.cod_fabrica,
                     v_short_code,
                     r_prod.cd_marca,
                     r_prod.cd_origem_item,
                     r_prod.user_name,
                     null);
                     COMMIT;
                  --
                end if;
                --
                w_data_ini := w_data_fim + .00001;
                w_semana   := w_semana + 1;
                --
              EXCEPTION
                WHEN OTHERS THEN
                  fnd_file.put_line(fnd_file.log,
                                    'Erro no item: ' ||
                                    r_prod.inventory_item_id ||
                                    ' w_data_ini: ' || w_data_ini ||
                                    ' w_data_fim: ' || w_data_fim ||
                                    ' Erro: ' || SQLERRM);
              END;
            END LOOP;
            --
          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,
                                'Erro no item: ' || r_prod.inventory_item_id ||
                                ' w_data_ini: ' || w_data_ini ||
                                ' w_data_fim: ' || w_data_fim || ' Erro: ' ||
                                SQLERRM);
          END;
        END LOOP;
        --
        fnd_file.put_line(fnd_file.log,'Time: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));

        --Compras...
        FOR r_compras IN c_compra(v_short_code) LOOP
          --
          INSERT INTO pb_producao_pp_atp
          VALUES
            (r_compras.inventory_item_id,
             NULL,
             SYSDATE,
             NULL,
             NULL,
             r_compras.cod,
             r_compras.item_um,
             r_compras.origem,
             r_compras.po_num,
             NULL,
             'Compras',
             r_compras.fornecedor,
             NULL,
             NULL,
             r_compras.promised_date,
             NULL,
             NULL,
             r_compras.quantity,
             0,
             r_compras.quantity,
             0,
             NULL,
             NULL,
             r_compras.LOCATION_CODE,
             v_short_code,
             r_compras.cd_marca,
             r_compras.cd_origem_item,
             null,
             r_compras.RELEASE_NUM);
             COMMIT;
          --
        END LOOP;
      --
      fnd_file.put_line(fnd_file.log,'Delete pb_producao_pp_atp');
      fnd_file.put_line(fnd_file.log,'Time: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
      --
      DELETE pb_producao_pp_atp
       WHERE qtd_pendente <= 0.1
         AND qtd_pendente > 0
         and org_code = v_short_code;
      COMMIT;
      --
    END;
    -- FINAL PP PRODU��O
  END IF;
  fnd_file.put_line(fnd_file.log,'Time: '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
  --
EXCEPTION
  WHEN OTHERS THEN
    w_errbuf  := 'Erro geral na Rotina calcula_producao_atp: Erro:' || SQLERRM;
    w_retcode := 2;
END;



--**************************************************************************
--**************************************************************************
--PROCEDURE prc_carga_saldo(p_inventory_item_id IN NUMBER, p_gera_log IN NUMBER, p_gera_log_geral IN NUMBER) 
PROCEDURE prc_carga_saldo(p_retcode         IN OUT VARCHAR2,
                           p_errbuf          IN OUT VARCHAR2)  

IS
--
p_inventory_item_id NUMBER;
p_gera_log NUMBER;
p_gera_log_geral NUMBER;



--Seleciona os produtos que possui programa de produ��o ou compra
CURSOR c_produto IS
SELECT INVENTORY_ITEM_ID, SEGMENT1, ITEM_UM, max(COMPRAS) AS COMPRAS FROM (
  SELECT DISTINCT ppp.inventory_item_id
        ,segment1
        ,ppp.item_um
        ,0 AS compras
    FROM MTL_SYSTEM_ITEMS_B msi
        ,PB_PRODUCAO_PP_ATP ppp
   WHERE msi.item_type          = 'PA' --Produto acabado
  -- Início - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
     AND msi.organization_id    = pb_master_organization_id
     -- Fim - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
     AND msi.inventory_item_id  = ppp.inventory_item_id
     and (msi.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
     AND (ppp.status_op         IN ('WIP','Pendente') OR
          ppp.cod_minifabrica   = 'Compras'
         )
     AND ppp.qtd_pendente       > 0
     AND msi.attribute4         = 1
     AND msi.attribute9        != 'DS'
     AND ((Upper(ppp.cod_fabrica) IN ('OFFICINA', 'PBELLO', 'F02', 'F05', 'F09', 'F04'
                                     ,'F10', 'F01', 'PEX', 'F30', 'CIT', 'PUC', 'P11')
           AND ppp.tipo_op != '5'
          )
         )
     AND Trunc(ppp.dt_termino_plan) >= Trunc(SYSDATE)
     --
UNION
  SELECT DISTINCT ppp.inventory_item_id
        ,segment1
        ,ppp.item_um
        ,1 AS compras
    FROM MTL_SYSTEM_ITEMS_B msi
        ,PB_PRODUCAO_PP_ATP ppp
   WHERE msi.item_type          = 'PA' --Produto acabado
  -- Início - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
     AND msi.organization_id    = pb_master_organization_id
     -- Fim - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
     AND msi.inventory_item_id  = ppp.inventory_item_id
     and (msi.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
     AND (ppp.status_op         IN ('WIP','Pendente') OR
          ppp.cod_minifabrica   = 'Compras'
         )
     AND ppp.qtd_pendente       > 0
     AND msi.attribute4         = 1
     AND msi.attribute9        != 'DS'
     AND Upper(ppp.cod_fabrica) IN ('OUTSOURCING', 'PORTOKOLL')
     AND ppp.status_op IS NULL 
     AND Trunc(ppp.dt_termino_plan) >= Trunc(SYSDATE)
UNION
  --
  SELECT DISTINCT msi.inventory_item_id
        ,msi.segment1
        ,ot.und_medida as item_um
        ,0 AS compras
   FROM MTL_SYSTEM_ITEMS_B msi
        ,TEMP_DRP_ESTOQUE_TRANSITO ot
   WHERE msi.item_type       = 'PA' --Produto acabado
   AND msi.attribute4         = 1
   AND msi.attribute9        != 'DS'
   AND (msi.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
   AND msi.organization_id = pb_master_organization_id
   AND msi.segment1        = ot.cod_item
UNION 
  SELECT DISTINCT MS.inventory_item_id
        ,MS.segment1
        ,MS.PRIMARY_UOM_CODE AS item_um
        ,0 AS compras
      FROM mtl_onhand_quantities_detail moqd,
           mtl_secondary_inventories msi,
           mtl_lot_numbers mln,
           mtl_parameters mp,
           mtl_system_items_b ms
     WHERE    msi.secondary_inventory_name = moqd.subinventory_code
              AND mln.lot_number = moqd.lot_number
              AND mln.inventory_item_id = moqd.inventory_item_id
              AND mln.organization_id = moqd.organization_id
              AND mp.organization_id = msi.organization_id
              AND msi.organization_id = moqd.organization_id
              AND msi.organization_id = ms.organization_id 
              AND moqd.inventory_item_id = ms.inventory_item_id
              AND ms.item_type       = 'PA' --Produto acabado
              AND ms.attribute4         = 1
              AND ms.attribute9        != 'DS'
              AND mp.organization_code in( select LOOKUP_CODE
                 from fnd_lookup_values flv
                where flv.lookup_type = 'ONT_ATP_ORG_CD_PB'
                  and enabled_flag = 'Y'
                  and language = 'PTB'
                  and tag ='N'
                  and nvl(end_date_active,sysdate+1) > sysdate
                  )              
              and moqd.subinventory_code in('FTR','PIN','E30','CIT_REC','PB_RTJ')
              and (ms.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
UNION 
  SELECT DISTINCT MS.inventory_item_id
        ,MS.segment1
        ,MS.PRIMARY_UOM_CODE AS item_um
        ,0 AS compras
      FROM mtl_onhand_quantities_detail moqd,
           mtl_secondary_inventories msi,
           mtl_lot_numbers mln,
           mtl_parameters mp,
           mtl_system_items_b ms
     WHERE    msi.secondary_inventory_name = moqd.subinventory_code
              AND mln.lot_number = moqd.lot_number
              AND mln.inventory_item_id = moqd.inventory_item_id
              AND mln.organization_id = moqd.organization_id
              AND mp.organization_id = msi.organization_id
              AND msi.organization_id = moqd.organization_id
              AND msi.organization_id = ms.organization_id 
              AND moqd.inventory_item_id = ms.inventory_item_id
              AND ms.item_type       = 'PA' --Produto acabado
              AND ms.attribute4         = 1
              AND ms.attribute9        != 'DS'
              AND mp.organization_code like 'F%' 
              AND moqd.subinventory_code like 'E%'
              and (ms.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
) GROUP BY INVENTORY_ITEM_ID, SEGMENT1, ITEM_UM;    
  --
  --and msi.inventory_item_id = 3138947
  --AND ppp.inventory_item_id = 2843145
  --
--Seleciona a quantidade de reserva e alocada
CURSOR c_reserva (p_inventory_item_id IN NUMBER,
                  p_item_um           IN VARCHAR2)
IS
  SELECT SUM (MIN_QUANTITY) MIN_QUANTITY, sum(NIN_INV_RESERVE_PROCESS_PKG.GET_RULE_RESERVED_QUANTITY(rule_id)) qt_alocada
    FROM NIN_RESERVATION_RULES
   WHERE STATUS            = 'A'
     AND RESERVATION_NAME != 'PBSHOP'
     AND INVENTORY_ITEM_ID = p_inventory_item_id
     AND primary_uom_code  = p_item_um
  ;
  --
/* Query ajustada para alinhar saldo com tela do EBS (Valor de Alocado Duplicado)
  SELECT sum(reg.min_quantity)  qt_reserva,
         sum(mr.reservation_quantity) qt_alocada
  FROM   mtl_reservations mr,
         nin_reservation_rules reg
  WHERE  mr.demand_source_name (+) = reg.reservation_name
  AND    mr.inventory_item_id  (+) = reg.inventory_item_id
  AND    mr.organization_id    (+) = reg.organization_id
  AND    reg.status                = 'A'
  AND    reg.reservation_name     <> 'PBSHOP'
  AND    reg.primary_uom_code      = p_item_um
  AND    reg.inventory_item_id     = p_inventory_item_id
  ;
  --
*/

--Seleciona a quantidade de reserva desconsiderado o pote PBSHOP
CURSOR c_reserva_pbshop (p_inventory_item_id IN NUMBER,
                         p_item_um           IN VARCHAR2)
IS
  SELECT SUM (MIN_QUANTITY) MIN_QUANTITY, sum(NIN_INV_RESERVE_PROCESS_PKG.GET_RULE_RESERVED_QUANTITY(rule_id)) qt_alocada
    FROM NIN_RESERVATION_RULES
   WHERE STATUS            = 'A'
     AND RESERVATION_NAME  = 'PBSHOP'
     AND INVENTORY_ITEM_ID = p_inventory_item_id
     AND primary_uom_code  = p_item_um
  ;


/* Query ajustada para alinhar saldo com tela do EBS (Valor de Alocado Duplicado)
  SELECT sum(reg.min_quantity)  qt_reserva,
         sum(mr.reservation_quantity) qt_alocada
  FROM   mtl_reservations mr,
         nin_reservation_rules reg
  WHERE  mr.demand_source_name (+) = reg.reservation_name
  AND    mr.inventory_item_id  (+) = reg.inventory_item_id
  AND    mr.organization_id    (+) = reg.organization_id
  AND    reg.status                = 'A'
  AND    reg.reservation_name      = 'PBSHOP'
  AND    reg.primary_uom_code      = p_item_um
  AND    reg.inventory_item_id     = p_inventory_item_id
  ;
  --
*/

--Seleciona as quantidade de compra por CD que projeta saldo
cursor c_compras_cd(p_inventory_item_id IN NUMBER
                   ,p_item_um           IN VARCHAR2
                   ,p_id_periodo        IN VARCHAR2
                   ,p_cd                IN VARCHAR2)
IS
        SELECT segment1
              --,lookup_code
              --,r_periodo
              ,Nvl(REPLACE(qtd_compras,'.',','),0)  --Sum(vol_meta)
              ,data_termino
        FROM (
        select msi.segment1
              ,org.lookup_code
              ,sum(nvl(ppp.qtd_pendente,0)) qtd_compras
              ,max(ppp.dt_termino_plan) data_termino, ppp.cod_fabrica
          FROM PB_PRODUCAO_PP_ATP ppp
        INNER JOIN (select segment1, inventory_item_id from mtl_system_items_b where organization_id = pb_master_organization_id) msi on ppp.inventory_item_id = msi.inventory_item_id
        INNER JOIN (
           select MEANING, LOOKUP_CODE, TAG
             from fnd_lookup_values flv
            where flv.lookup_type = 'ONT_ATP_ORG_CD_PB'
              and enabled_flag = 'Y'
              and language = 'PTB'
              and lookup_code = p_cd
              and (tag ='S' OR (tag ='N' AND lookup_code = 'EET'))
              and nvl(end_date_active,sysdate+1) > sysdate
        ) ORG ON PPP.ORGANIZACAO = ORG.MEANING
          WHERE ppp.item_um = p_item_um
            AND ppp.inventory_item_id = p_inventory_item_id
            AND ((Upper(ppp.cod_fabrica) IN ('OUTSOURCING', 'PORTOKOLL')
                  AND ppp.status_op IS NULL
                 )
                )
          group by msi.segment1, msi.inventory_item_id, ppp.item_um, org.lookup_code, ppp.cod_fabrica ) a
          where omp12001jb.fnd_periodo_dec(a.data_termino + Nvl(omp12001jb.fnd_dias_seguranca_prod_dec,0)
                                                 ,a.cod_fabrica
                                                 ) = p_id_periodo;



--Seleciona as quantidades de compra por CD que projeta saldo - EET
CURSOR c_compras_interna(p_inventory_item_id IN NUMBER
                        ,p_item_um           IN VARCHAR2
                        ,p_id_periodo        IN VARCHAR2)
IS
SELECT NVL(SUM(A.QTD_PENDENTE),0) FROM (
select cod_ordem , inventory_item_id , cod_fabrica, max(dt_termino_plan) data_termino, sum(qtd_pendente) qtd_pendente
  FROM PB_PRODUCAO_PP_ATP ppp
INNER JOIN (
  select MEANING, LOOKUP_CODE, TAG
    from fnd_lookup_values flv
   where flv.lookup_type = 'ONT_ATP_ORG_CD_PB'
     and enabled_flag = 'Y'
     and language = 'PTB'
     and tag ='N'
     and nvl(end_date_active,sysdate+1) > sysdate
) ORG ON PPP.ORGANIZACAO = ORG.MEANING
  WHERE ppp.item_um = p_item_um
    AND ppp.inventory_item_id = p_inventory_item_id
    AND ((Upper(ppp.cod_fabrica) IN ('OUTSOURCING')
          AND ppp.status_op IS NULL
         )
        )
group by cod_ordem, inventory_item_id, cod_fabrica) a
where omp12001jb.fnd_periodo_dec(a.data_termino+ Nvl(omp12001jb.fnd_dias_seguranca_prod_dec,0)
                                       ,a.cod_fabrica
                                       ) = p_id_periodo;


--Seleciona as quantidades de compra por CD que projeta saldo - EET
CURSOR c_compras_interna_portokoll(p_inventory_item_id IN NUMBER
                        ,p_item_um           IN VARCHAR2
                        ,p_id_periodo        IN VARCHAR2)
IS
SELECT nvl(SUM(A.QTD_PENDENTE),0), nvl(lookup_code ,'') FROM (
select cod_ordem , inventory_item_id , cod_fabrica, max(dt_termino_plan) data_termino, sum(qtd_pendente) qtd_pendente, lookup_code
  FROM PB_PRODUCAO_PP_ATP ppp
INNER JOIN (
  select MEANING, LOOKUP_CODE, TAG
    from fnd_lookup_values flv
   where flv.lookup_type = 'ONT_ATP_ORG_CD_PB'
     and enabled_flag = 'Y'
     and language = 'PTB'
     and tag ='N'
     and nvl(end_date_active,sysdate+1) > sysdate
) ORG ON PPP.ORGANIZACAO = ORG.MEANING
  WHERE ppp.item_um = p_item_um
    AND ppp.inventory_item_id = p_inventory_item_id
    AND ((Upper(ppp.cod_fabrica) IN ('PORTOKOLL')
          AND ppp.status_op IS NULL
         )
        )
group by cod_ordem, inventory_item_id, cod_fabrica, lookup_code) a
where omp12001jb.fnd_periodo_dec(a.data_termino+ Nvl(omp12001jb.fnd_dias_seguranca_prod_dec,0)
                                       ,a.cod_fabrica
                                       ) = p_id_periodo
group by lookup_code;


--Seleciona as quantidades de compra por CD que projeta saldo - EET
CURSOR c_tem_portokoll(p_inventory_item_id IN NUMBER
                        ,p_item_um           IN VARCHAR2
                        ,p_id_periodo        IN VARCHAR2)
IS
SELECT NVL(SUM(A.QTD_PENDENTE),0) FROM (
select cod_ordem , inventory_item_id , cod_fabrica, max(dt_termino_plan) data_termino, sum(qtd_pendente) qtd_pendente, lookup_code
  FROM PB_PRODUCAO_PP_ATP ppp
INNER JOIN (
  select MEANING, LOOKUP_CODE, TAG
    from fnd_lookup_values flv
   where flv.lookup_type = 'ONT_ATP_ORG_CD_PB'
     and enabled_flag = 'Y'
     and language = 'PTB'
     and tag ='N'
     and nvl(end_date_active,sysdate+1) > sysdate
) ORG ON PPP.ORGANIZACAO = ORG.MEANING
  WHERE ppp.item_um = p_item_um
    AND ppp.inventory_item_id = p_inventory_item_id
    AND ((Upper(ppp.cod_fabrica) IN ('PORTOKOLL')
          AND ppp.status_op IS NULL
         )
        )
group by cod_ordem, inventory_item_id, cod_fabrica, lookup_code) a
where omp12001jb.fnd_periodo_dec(a.data_termino+ Nvl(omp12001jb.fnd_dias_seguranca_prod_dec,0)
                                       ,a.cod_fabrica
                                       ) <= p_id_periodo
group by lookup_code;


--Seleciona a quantidade programada do produto conforme periodo
CURSOR c_producao(p_inventory_item_id IN NUMBER
                 ,p_item_um           IN VARCHAR2
                 ,p_id_periodo        IN VARCHAR2
                 )
IS
SELECT sum(nvl(round(qtd_pendente,2),0))
FROM (
  SELECT cod_ordem , inventory_item_id , cod_fabrica, max(dt_termino_plan) data_termino, sum(qtd_pendente) qtd_pendente
    FROM PB_PRODUCAO_PP_ATP ppp
   WHERE ppp.item_um = p_item_um
     AND ppp.inventory_item_id = p_inventory_item_id
     AND ((Upper(ppp.cod_fabrica) IN ('OFFICINA', 'PBELLO', 'F02', 'F05', 'F09', 'F04'
                                     ,'F10', 'F01', 'PEX', 'F30', 'CIT', 'PUC', 'P11')
           AND ppp.tipo_op != '5'
          )
/*       -- Desconsiderar as ordens de compra
         OR
          (Upper(ppp.cod_fabrica) IN ('OUTSOURCING', 'PORTOKOLL')
           AND ppp.status_op IS NULL
          )
*/
         )
   GROUP BY cod_ordem, inventory_item_id, cod_fabrica
) a
WHERE omp12001jb.fnd_periodo_dec(a.data_termino+ Nvl(omp12001jb.fnd_dias_seguranca_prod_dec,0)
                                       ,a.cod_fabrica
                                       ) = p_id_periodo
;


--Seleciona a quantidade em estoque de fronteira
CURSOR c_fronteira(p_inventory_item_id IN NUMBER
                 ,p_item_um           IN VARCHAR2
                 ,p_id_periodo        IN VARCHAR2
                 )
IS
SELECT NVL(sum(moqd.primary_transaction_quantity),0)
  FROM mtl_onhand_quantities_detail moqd,
       mtl_secondary_inventories msi,
       mtl_lot_numbers mln,
       mtl_parameters mp,
       mtl_system_items_b ms
 WHERE    msi.secondary_inventory_name = moqd.subinventory_code
          AND mln.lot_number = moqd.lot_number
          AND mln.inventory_item_id = moqd.inventory_item_id
          AND mln.organization_id = moqd.organization_id
          AND mp.organization_id = msi.organization_id
          AND msi.organization_id = moqd.organization_id
          AND msi.organization_id = ms.organization_id 
          AND moqd.inventory_item_id = ms.inventory_item_id
              AND mp.organization_code in( select LOOKUP_CODE
                 from fnd_lookup_values flv
                where flv.lookup_type = 'ONT_ATP_ORG_CD_PB'
                  and enabled_flag = 'Y'
                  and language = 'PTB'
                  and tag ='N'
                  and nvl(end_date_active,sysdate+1) > sysdate
                  )              
              and moqd.subinventory_code in('FTR','PIN','E30','CIT_REC','PB_RTJ')
          --AND mp.organization_code like 'F%'
          AND MS.inventory_item_id = p_inventory_item_id
order by moqd.lot_number;

--Seleciona a quantidade em estoque F�brica
CURSOR c_fabrica(p_inventory_item_id IN NUMBER
                 ,p_item_um           IN VARCHAR2
                 ,p_id_periodo        IN VARCHAR2
                 )
IS
SELECT NVL(sum(moqd.primary_transaction_quantity),0)
  FROM mtl_onhand_quantities_detail moqd,
       mtl_secondary_inventories msi,
       mtl_lot_numbers mln,
       mtl_parameters mp,
       mtl_system_items_b ms
 WHERE    msi.secondary_inventory_name = moqd.subinventory_code
          AND mln.lot_number = moqd.lot_number
          AND mln.inventory_item_id = moqd.inventory_item_id
          AND mln.organization_id = moqd.organization_id
          AND mp.organization_id = msi.organization_id
          AND msi.organization_id = moqd.organization_id
          AND msi.organization_id = ms.organization_id 
          AND moqd.inventory_item_id = ms.inventory_item_id
          AND mp.organization_code LIKE 'F%'
          and moqd.subinventory_code LIKE 'E%'
          AND MS.inventory_item_id = p_inventory_item_id
order by moqd.lot_number;


--
-- Seleciona os CDs n�o Internos/F�brica
CURSOR c_cd
is 
 select MEANING, LOOKUP_CODE, TAG
             from fnd_lookup_values flv
            where flv.lookup_type = 'ONT_ATP_ORG_CD_PB'
              and enabled_flag = 'Y'
              and language = 'PTB'
              and tag ='S'
              and nvl(end_date_active,sysdate+1) > sysdate;

--Seleciona a Carteria de DMF
CURSOR c_carteira_ped (p_inventory_item_id IN NUMBER
                      ,p_item_um           IN VARCHAR2
                      ,p_id_periodo        IN VARCHAR2
                      )
IS
  SELECT sum(ola.ordered_quantity - NVL((SELECT SUM(mr.reservation_quantity)
                                           FROM MTL_RESERVATIONS mr
                                          WHERE mr.demand_source_line_id = ola.line_id),0)) qt_item
  FROM
  OE_ORDER_LINES_ALL        ola
  inner join OE_ORDER_HEADERS_ALL  oha  on  ola.org_id = oha.org_id AND ola.header_id = oha.header_id
  inner join OE_TRANSACTION_TYPES_ALL  tta on tta.transaction_type_id               = oha.order_type_id
  left join (select * from mtl_system_items_b where organization_id = pb_master_organization_id ) msi on ola.inventory_item_id = msi.inventory_item_id
  left join TEMP_DRP_RESSUPRIMENTO f on oha.order_number = f.ordem_venda and msi.segment1 = f.cod_produto
  WHERE  ola.order_quantity_uom  = p_item_um
  AND    ola.inventory_item_id   = p_inventory_item_id
  AND    f.ot is null
  AND    ola.booked_flag         = 'Y'
  AND    ola.open_flag           = 'Y'
  AND    ola.cancelled_flag      = 'N'
  and    oha.org_id              = fnd_profile.value('ORG_ID')
  and   oha.order_type_id not in (1002,4504, 1823, 5753, 2243)
  AND   tta.transaction_type_code             = 'ORDER'
  AND   nvl(tta.sales_document_type_code,'O') <> 'B'
  AND   oha.cancelled_flag                    = 'N'
  AND   oha.booked_flag                       = 'Y'
  AND   oha.open_flag                         = 'Y'
  AND   ola.flow_status_code     = 'AWAITING_SHIPPING'
  AND   omp12001jb.fnd_periodo_dec(ola.schedule_ship_date
                                           ,(SELECT a.origem_item
                                               FROM apps.CONSULTA_PRODUTO_PB_V a
                                              WHERE a.cod_produto = ola.ordered_item AND a.master_organization_id= pb_master_organization_id
                                            )
                                           ,'S')   = p_id_periodo
  AND   NOT EXISTS ( SELECT SUM(mr.reservation_quantity)
                       FROM MTL_RESERVATIONS     mr
                           ,OE_ORDER_LINES_ALL   ola2
                      WHERE mr.demand_source_line_id = ola.line_id
                        AND ola2.header_id           = ola.header_id
                        AND ola2.line_id             = ola.line_id
                        --
                        --AND ola.flow_status_code     = 'AWAITING_SHIPPING'
                        --
                        AND EXISTS (SELECT 1
                                      FROM MTL_PARAMETERS e
                                     WHERE e.organization_id = ola2.ship_from_org_id
                                       AND e.organization_code IN (SELECT LOOKUP_CODE
                                                                     FROM FND_LOOKUP_VALUES
                                                                    WHERE LANGUAGE            = USERENV('LANG')
                                                                      AND enabled_flag        = 'Y'
                                                                      AND security_group_id   = 0
                                                                      AND view_application_id = 660
                                                                      AND lookup_type         = 'ONT_ATP_ORG_CD_PB'
                                                                      AND Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                                                             AND Trunc(Nvl(end_date_active, SYSDATE))
                                                                  )
                                   )
                        --
/*                        AND EXISTS (SELECT 1
                                      FROM FAT_DRP_RESSUPRIMENTO f
                                          ,OE_ORDER_HEADERS_ALL  oha
                                     WHERE oha.header_id    = ola2.header_id
                                       AND oha.order_number = f.ordem_venda
                                       AND f.ot IS NOT NULL
                                   )*/
                      HAVING SUM(mr.reservation_quantity) > 0
                   )
                   ;
  --
  w_erro                        EXCEPTION;
  w_ds_erro                     VARCHAR2(4000);
  w_ds_email                    VARCHAR2(4000);
  w_qt_programada_producao      NUMBER;
  w_qt_carteira_pedido          NUMBER;
  w_qt_reserva                  NUMBER;
  w_qt_reserva_pbshop           NUMBER;
  w_qt_alocada                  NUMBER;
  w_qt_alocada_pbshop           NUMBER;
  w_pr_disponivel_saldo         NUMBER;
  w_qt_saldo                    NUMBER;
  w_qt_saldo_anterior           NUMBER;
  w_qt_saldo_disponivel         NUMBER;
  w_qt_saldo_pbshop             NUMBER;
  --
  -- Ajuste realizado para calculo de saldo negativo (PBSHOP)
  w_qt_saldo_pbshop_negativo    NUMBER;
  w_qt_saldo_anterior_pbshop    NUMBER;
  w_qt_saldo_disponivel_pbshop  NUMBER;
  w_id_usuario                  NUMBER;
  w_qt_transferencia            NUMBER;
  -- Austes saldo projetado 13/08/2020 - Alexandre
  w_producao_menos_carteira     NUMBER;
  w_pote_shop_encher            NUMBER;
  w_usado_pote_shop             NUMBER;
  w_pote_demais_canais          NUMBER;
  w_saldo_demais_canais         NUMBER;
  --
  -- BY7 
  w_qt_saldo_deb_demais_canais  NUMBER;
  w_qt_saldo_deb_pbshop         NUMBER;
  w_qt_carteira_pedido_anterior NUMBER;
  w_STK_Transf_CD               NUMBER;
  w_projetar_pbshop             VARCHAR2(1);
  w_projetar_demais_canais      VARCHAR2(1);
  --
  cont                          NUMBER :=0;
  --
  --
  -- 10/03/2021 - Rodrigues - Novas Vari�veis (amig�veis)
  qt_producao         NUMBER;
  qt_producao_perc    NUMBER;
  qt_carteira         NUMBER;
  qt_carteira_pb      NUMBER;
  qt_carteira_ant     NUMBER;
  qt_carteira_ant_portokoll     NUMBER;
  qt_potes_demais     NUMBER;
  qt_potes_pb         NUMBER;
  qt_reserva          NUMBER;
  qt_alocada          NUMBER;
  qt_reserva_pb       NUMBER;
  qt_alocada_pb       NUMBER;
  qt_saldo            NUMBER;
  qt_saldo_pb         NUMBER;
  qt_saldo_neg        NUMBER;
  qt_saldo_neg_pb     NUMBER;
  qt_compras_eet      NUMBER;
  qt_compras_eet_portokoll NUMBER;
  qt_carteira_portokoll NUMBER;
  qt_cd_portokoll VARCHAR2(10);
  it_compra_int_portokoll INT;
  qt_fabrica         NUMBER;
  qt_fronteira         NUMBER;

  cd_codigo varchar2(20);
  cd_cd varchar2(10);
  cd_qtd number;
  cd_data varchar2(20);
  cd_pedidos number;
  cd_negativo number;
  cd_saldo_geral number;
  cd_negativo_geral number;


  considera_transitorio number;
  w_ret number;


  cd_demanda_geral number;
  cd_prod_carteira number;
  cd_saldo number;
  cd_projecao number;
  cd_carteira_negativa number;

  --
  retAj number;

  --cd_carteira_atual number;
  cd_carteira_geral number;
  cd_volume_meta number;
  cd_data_meta varchar2(20);

  qt_saldo_cd number;

  dados_log varchar2(800);
  dados_log_cd varchar2(800);

  log_passo_a_passo number;
  log_geral number;

  v_err varchar2(200);
  v_code number;

BEGIN
  --
  DBMS_OUTPUT.enable(1000000000000000);
  --
  --dbms_output.put_line('In�cio..');
  --
  fnd_profile.get ('USER_ID', w_id_usuario);
  --
  --Elimina o historico antigo
  BEGIN
    DELETE OM_SALDO_PRODUTO_ATP_HIS_JB
    WHERE dt_historico < (SYSDATE - 30);

    DELETE OM_SALDO_PRODUTO_ATP_HIS_JB_CD_V2
    WHERE dt_historico < (SYSDATE - 30);

  EXCEPTION
    WHEN OTHERS THEN
      w_ds_erro:= 'Erro ao excluir a tabela OM_SALDO_PRODUTO_ATP_HIS_JB de saldo ATP. Erro:'||SQLERRM;
      RAISE w_erro;
  END;
  --
  --
  --dbms_output.put_line('0..');
  --
  --Grava o historico atual
  BEGIN
    INSERT INTO OM_SALDO_PRODUTO_ATP_HIS_JB
    SELECT inventory_item_id,
           item_um,
           id_periodo,
           SYSDATE,
           dt_final_periodo,
           qt_programada_producao,
           qt_carteira_pedido,
           qt_reserva,
           qt_alocada,
           pr_disponivel_saldo,
           qt_saldo,
           qt_saldo_disponivel,
           creation_date,
           created_by,
           last_update_date,
           last_updated_by,
           qt_saldo_disponivel_pbshop,
           qt_transferencia,
           qt_reserva_pbshop,
           qt_alocada_pbshop
    FROM OM_SALDO_PRODUTO_ATP_JB;
    COMMIT;

    INSERT INTO APPS.OM_SALDO_PRODUTO_ATP_HIS_JB_CD_V2 (DT_HISTORICO, COD_ITEM, DES_CD, ID_PERIODO, VOL_META, CREATION_DATE, CREATED_BY, DATA_CHEGADA, SALDO_TOTAL, VOL_PEDIDO, STK_META, CARTEIRA_GERAL, STK_META_GERAL)
    SELECT SYSDATE, COD_ITEM, DES_CD, ID_PERIODO, VOL_META, CREATION_DATE, CREATED_BY, DATA_CHEGADA, SALDO_TOTAL, VOL_PEDIDO, STK_META, CARTEIRA_GERAL, STK_META_GERAL
    FROM APPS.OM_SALDO_PRODUTO_ATP_JB_CD_V2;
    COMMIT; 


  EXCEPTION
    WHEN OTHERS THEN
      w_ds_erro:= 'Erro ao gerar hist�rico na tabela OM_SALDO_PRODUTO_ATP_HIS_JB. Erro:'||SQLERRM;
      RAISE w_erro;
  END;
  --
  --Exclui a tabela de saldo
  BEGIN
    --DELETE OM_SALDO_PRODUTO_ATP_JB;
    --DELETE OM_SALDO_PRODUTO_ATP_JB_CD_V2;
    --COMMIT;

    DELETE OM_SALDO_PRODUTO_ATP_JB_CD_V2 WHERE COD_ITEM NOT IN(SELECT DISTINCT SEGMENT1
                                        FROM (SELECT DISTINCT
                                                     ppp.inventory_item_id,
                                                     segment1,
                                                     ppp.item_um,
                                                     0 AS compras
                                                FROM MTL_SYSTEM_ITEMS_B msi,
                                                     PB_PRODUCAO_PP_ATP ppp
                                               WHERE     msi.item_type = 'PA' --Produto acabado
                                                     -- Início - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
                                                     AND msi.organization_id =
                                                            pb_master_organization_id
                                                     -- Fim - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
                                                     AND msi.inventory_item_id =
                                                            ppp.inventory_item_id
                                                     --and (msi.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
                                                     AND (   ppp.status_op IN
                                                                ('WIP',
                                                                 'Pendente')
                                                          OR ppp.cod_minifabrica =
                                                                'Compras')
                                                     AND ppp.qtd_pendente > 0
                                                     AND msi.attribute4 = 1
                                                     AND msi.attribute9 !=
                                                            'DS'
                                                     AND ( (    UPPER (
                                                                   ppp.cod_fabrica) IN
                                                                   ('OFFICINA',
                                                                    'PBELLO',
                                                                    'F02',
                                                                    'F05',
                                                                    'F09',
                                                                    'F04',
                                                                    'F10',
                                                                    'F01',
                                                                    'PEX',
                                                                    'F30',
                                                                    'CIT',
                                                                    'PUC',
                                                                    'P11')
                                                            AND ppp.tipo_op !=
                                                                   '5'))
                                                     AND TRUNC (
                                                            ppp.dt_termino_plan) >=
                                                            TRUNC (SYSDATE)
                                              --
                                              UNION
                                              SELECT DISTINCT
                                                     ppp.inventory_item_id,
                                                     segment1,
                                                     ppp.item_um,
                                                     1 AS compras
                                                FROM MTL_SYSTEM_ITEMS_B msi,
                                                     PB_PRODUCAO_PP_ATP ppp
                                               WHERE     msi.item_type = 'PA' --Produto acabado
                                                     -- Início - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
                                                     AND msi.organization_id =
                                                            pb_master_organization_id
                                                     -- Fim - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
                                                     AND msi.inventory_item_id =
                                                            ppp.inventory_item_id
                                                     --and (msi.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
                                                     AND (   ppp.status_op IN
                                                                ('WIP',
                                                                 'Pendente')
                                                          OR ppp.cod_minifabrica =
                                                                'Compras')
                                                     AND ppp.qtd_pendente > 0
                                                     AND msi.attribute4 = 1
                                                     AND msi.attribute9 !=
                                                            'DS'
                                                     AND UPPER (
                                                            ppp.cod_fabrica) IN
                                                            ('OUTSOURCING',
                                                             'PORTOKOLL')
                                                     AND ppp.status_op
                                                            IS NULL
                                                     AND TRUNC (
                                                            ppp.dt_termino_plan) >=
                                                            TRUNC (SYSDATE)
                                              UNION
                                              --
                                              SELECT DISTINCT
                                                     msi.inventory_item_id,
                                                     msi.segment1,
                                                     ot.und_medida AS item_um,
                                                     0 AS compras
                                                FROM MTL_SYSTEM_ITEMS_B msi,
                                                     TEMP_DRP_ESTOQUE_TRANSITO ot
                                               WHERE     msi.item_type = 'PA' --Produto acabado
                                                     --and (msi.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
                                                     AND msi.organization_id =
                                                            pb_master_organization_id
                                                     AND msi.segment1 =
                                                            ot.cod_item
                                                     AND msi.attribute4         = 1
                                                     AND msi.attribute9        != 'DS'
                                              UNION
                                              SELECT DISTINCT
                                                     MS.inventory_item_id,
                                                     MS.segment1,
                                                     MS.PRIMARY_UOM_CODE
                                                        AS item_um,
                                                     0 AS compras
                                                FROM mtl_onhand_quantities_detail moqd,
                                                     mtl_secondary_inventories msi,
                                                     mtl_lot_numbers mln,
                                                     mtl_parameters mp,
                                                     mtl_system_items_b ms
                                               WHERE     msi.secondary_inventory_name =
                                                            moqd.subinventory_code
                                                     AND mln.lot_number =
                                                            moqd.lot_number
                                                     AND mln.inventory_item_id =
                                                            moqd.inventory_item_id
                                                     AND mln.organization_id =
                                                            moqd.organization_id
                                                     AND mp.organization_id =
                                                            msi.organization_id
                                                     AND msi.organization_id =
                                                            moqd.organization_id
                                                     AND msi.organization_id =
                                                            ms.organization_id
                                                     AND ms.item_type       = 'PA' --Produto acabado
                                                     AND ms.attribute4         = 1
                                                     AND ms.attribute9        != 'DS'
                                                     AND moqd.inventory_item_id =
                                                            ms.inventory_item_id
                                                     AND mp.organization_code IN
                                                            (SELECT LOOKUP_CODE
                                                               FROM fnd_lookup_values flv
                                                              WHERE     flv.lookup_type =
                                                                           'ONT_ATP_ORG_CD_PB'
                                                                    AND enabled_flag =
                                                                           'Y'
                                                                    AND language =
                                                                           'PTB'
                                                                    AND tag =
                                                                           'N'
                                                                    AND NVL (
                                                                           end_date_active,
                                                                             SYSDATE
                                                                           + 1) >
                                                                           SYSDATE)
                                                     AND moqd.subinventory_code IN
                                                            ('FTR',
                                                             'PIN',
                                                             'E30',
                                                             'CIT_REC',
                                                             'PB_RTJ')
                                              --and (ms.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
                                              UNION
                                              SELECT DISTINCT
                                                     MS.inventory_item_id,
                                                     MS.segment1,
                                                     MS.PRIMARY_UOM_CODE
                                                        AS item_um,
                                                     0 AS compras
                                                FROM mtl_onhand_quantities_detail moqd,
                                                     mtl_secondary_inventories msi,
                                                     mtl_lot_numbers mln,
                                                     mtl_parameters mp,
                                                     mtl_system_items_b ms
                                               WHERE     msi.secondary_inventory_name =
                                                            moqd.subinventory_code
                                                     AND ms.item_type       = 'PA' --Produto acabado
                                                     AND ms.attribute4         = 1
                                                     AND ms.attribute9        != 'DS'
                                                     AND mln.lot_number =
                                                            moqd.lot_number
                                                     AND mln.inventory_item_id =
                                                            moqd.inventory_item_id
                                                     AND mln.organization_id =
                                                            moqd.organization_id
                                                     AND mp.organization_id =
                                                            msi.organization_id
                                                     AND msi.organization_id =
                                                            moqd.organization_id
                                                     AND msi.organization_id =
                                                            ms.organization_id
                                                     AND moqd.inventory_item_id =
                                                            ms.inventory_item_id
                                                     AND mp.organization_code LIKE
                                                            'F%'
                                                     AND moqd.subinventory_code LIKE
                                                            'E%'--and (ms.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
                                             ));
                                             COMMIT;

    DELETE FROM OM_SALDO_PRODUTO_ATP_JB
      WHERE inventory_item_id NOT IN (SELECT DISTINCT INVENTORY_ITEM_ID
                                        FROM (SELECT DISTINCT
                                                     ppp.inventory_item_id,
                                                     segment1,
                                                     ppp.item_um,
                                                     0 AS compras
                                                FROM MTL_SYSTEM_ITEMS_B msi,
                                                     PB_PRODUCAO_PP_ATP ppp
                                               WHERE     msi.item_type = 'PA' --Produto acabado
                                                     -- Início - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
                                                     AND msi.organization_id =
                                                            pb_master_organization_id
                                                     -- Fim - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
                                                     AND msi.inventory_item_id =
                                                            ppp.inventory_item_id
                                                     --and (msi.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
                                                     AND (   ppp.status_op IN
                                                                ('WIP',
                                                                 'Pendente')
                                                          OR ppp.cod_minifabrica =
                                                                'Compras')
                                                     AND ppp.qtd_pendente > 0
                                                     AND msi.attribute4 = 1
                                                     AND msi.attribute9 !=
                                                            'DS'
                                                     AND ( (    UPPER (
                                                                   ppp.cod_fabrica) IN
                                                                   ('OFFICINA',
                                                                    'PBELLO',
                                                                    'F02',
                                                                    'F05',
                                                                    'F09',
                                                                    'F04',
                                                                    'F10',
                                                                    'F01',
                                                                    'PEX',
                                                                    'F30',
                                                                    'CIT',
                                                                    'PUC',
                                                                    'P11')
                                                            AND ppp.tipo_op !=
                                                                   '5'))
                                                     AND TRUNC (
                                                            ppp.dt_termino_plan) >=
                                                            TRUNC (SYSDATE)
                                              --
                                              UNION
                                              SELECT DISTINCT
                                                     ppp.inventory_item_id,
                                                     segment1,
                                                     ppp.item_um,
                                                     1 AS compras
                                                FROM MTL_SYSTEM_ITEMS_B msi,
                                                     PB_PRODUCAO_PP_ATP ppp
                                               WHERE     msi.item_type = 'PA' --Produto acabado
                                                     -- Início - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
                                                     AND msi.organization_id =
                                                            pb_master_organization_id
                                                     -- Fim - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
                                                     AND msi.inventory_item_id =
                                                            ppp.inventory_item_id
                                                     --and (msi.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
                                                     AND (   ppp.status_op IN
                                                                ('WIP',
                                                                 'Pendente')
                                                          OR ppp.cod_minifabrica =
                                                                'Compras')
                                                     AND ppp.qtd_pendente > 0
                                                     AND msi.attribute4 = 1
                                                     AND msi.attribute9 !=
                                                            'DS'
                                                     AND UPPER (
                                                            ppp.cod_fabrica) IN
                                                            ('OUTSOURCING',
                                                             'PORTOKOLL')
                                                     AND ppp.status_op
                                                            IS NULL
                                                     AND TRUNC (
                                                            ppp.dt_termino_plan) >=
                                                            TRUNC (SYSDATE)
                                              UNION
                                              --
                                              SELECT DISTINCT
                                                     msi.inventory_item_id,
                                                     msi.segment1,
                                                     ot.und_medida AS item_um,
                                                     0 AS compras
                                                FROM MTL_SYSTEM_ITEMS_B msi,
                                                     TEMP_DRP_ESTOQUE_TRANSITO ot
                                               WHERE     msi.item_type = 'PA' --Produto acabado
                                                     --and (msi.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
                                                     AND msi.organization_id =
                                                            pb_master_organization_id
                                                     AND msi.segment1 =
                                                            ot.cod_item
                                                     AND msi.attribute4         = 1
                                                     AND msi.attribute9        != 'DS'
                                              UNION
                                              SELECT DISTINCT
                                                     MS.inventory_item_id,
                                                     MS.segment1,
                                                     MS.PRIMARY_UOM_CODE
                                                        AS item_um,
                                                     0 AS compras
                                                FROM mtl_onhand_quantities_detail moqd,
                                                     mtl_secondary_inventories msi,
                                                     mtl_lot_numbers mln,
                                                     mtl_parameters mp,
                                                     mtl_system_items_b ms
                                               WHERE     msi.secondary_inventory_name =
                                                            moqd.subinventory_code
                                                     AND mln.lot_number =
                                                            moqd.lot_number
                                                     AND mln.inventory_item_id =
                                                            moqd.inventory_item_id
                                                     AND mln.organization_id =
                                                            moqd.organization_id
                                                     AND mp.organization_id =
                                                            msi.organization_id
                                                     AND msi.organization_id =
                                                            moqd.organization_id
                                                     AND msi.organization_id =
                                                            ms.organization_id
                                                     AND ms.item_type       = 'PA' --Produto acabado
                                                     AND ms.attribute4         = 1
                                                     AND ms.attribute9        != 'DS'
                                                     AND moqd.inventory_item_id =
                                                            ms.inventory_item_id
                                                     AND mp.organization_code IN
                                                            (SELECT LOOKUP_CODE
                                                               FROM fnd_lookup_values flv
                                                              WHERE     flv.lookup_type =
                                                                           'ONT_ATP_ORG_CD_PB'
                                                                    AND enabled_flag =
                                                                           'Y'
                                                                    AND language =
                                                                           'PTB'
                                                                    AND tag =
                                                                           'N'
                                                                    AND NVL (
                                                                           end_date_active,
                                                                             SYSDATE
                                                                           + 1) >
                                                                           SYSDATE)
                                                     AND moqd.subinventory_code IN
                                                            ('FTR',
                                                             'PIN',
                                                             'E30',
                                                             'CIT_REC',
                                                             'PB_RTJ')
                                              --and (ms.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
                                              UNION
                                              SELECT DISTINCT
                                                     MS.inventory_item_id,
                                                     MS.segment1,
                                                     MS.PRIMARY_UOM_CODE
                                                        AS item_um,
                                                     0 AS compras
                                                FROM mtl_onhand_quantities_detail moqd,
                                                     mtl_secondary_inventories msi,
                                                     mtl_lot_numbers mln,
                                                     mtl_parameters mp,
                                                     mtl_system_items_b ms
                                               WHERE     msi.secondary_inventory_name =
                                                            moqd.subinventory_code
                                                     AND ms.item_type       = 'PA' --Produto acabado
                                                     AND ms.attribute4         = 1
                                                     AND ms.attribute9        != 'DS'
                                                     AND mln.lot_number =
                                                            moqd.lot_number
                                                     AND mln.inventory_item_id =
                                                            moqd.inventory_item_id
                                                     AND mln.organization_id =
                                                            moqd.organization_id
                                                     AND mp.organization_id =
                                                            msi.organization_id
                                                     AND msi.organization_id =
                                                            moqd.organization_id
                                                     AND msi.organization_id =
                                                            ms.organization_id
                                                     AND moqd.inventory_item_id =
                                                            ms.inventory_item_id
                                                     AND mp.organization_code LIKE
                                                            'F%'
                                                     AND moqd.subinventory_code LIKE
                                                            'E%'--and (ms.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
                                             ));
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      w_ds_erro:= 'Erro ao excluir a tabela OM_SALDO_PRODUTO_ATP_JB. Erro:'||SQLERRM;
      RAISE w_erro;
  END;
  --
/*
  --Exclui a tabela de volume meta por CD
  BEGIN
    DELETE OM_SALDO_PRODUTO_ATP_JB_CD_V2;
  EXCEPTION
    WHEN OTHERS THEN
      w_ds_erro:= 'Erro ao excluir a tabela OM_SALDO_PRODUTO_ATP_JB_CD_V2. Erro:'||SQLERRM;
      RAISE w_erro;
  END;
  --
*/
  --dbms_output.put_line('1..');
  --
  --Seleciona o percentual de disponibilidade de saldo
  w_pr_disponivel_saldo := omp12001jb.fnd_percentual_dispo_dec;
  --
  --Seleciona os produtos que possuam plano de producao

  --Seleciona op��o de inclus�o de saldo transitorio
  considera_transitorio := omp12001jb.fnd_considera_transitorio;

  --Redefini��o de descritivo de periodos\dec�ncios
  retAj := fnd_ajusta_periodos();
  --

    dbms_output.put_line('======================================================================');
    dbms_output.put_line('Composi��o de dados FAT_DRP..');


    DELETE APPS.TEMP_DRP_RESSUPRIMENTO;
    COMMIT;
    INSERT INTO APPS.TEMP_DRP_RESSUPRIMENTO (ORDEM_VENDA, COD_PRODUTO, OT) SELECT ORDEM_VENDA, COD_PRODUTO, OT FROM FAT_DRP_RESSUPRIMENTO;
    DELETE APPS.TEMP_DRP_ESTOQUE_TRANSITO;
    COMMIT; 
    INSERT INTO APPS.TEMP_DRP_ESTOQUE_TRANSITO (UND_MEDIDA, COD_ITEM, VOL_META, DES_CD, DAT_PREVISAO_CHEGADA) SELECT UND_MEDIDA, COD_ITEM, VOL_META, DES_CD, DAT_PREVISAO_CHEGADA FROM FAT_DRP_ESTOQUE_TRANSITO;

    dbms_output.put_line('Fim da composi��o de dados FAT_DRP..');
    dbms_output.put_line('======================================================================');

  begin
    calcula_producao_atp(v_err, v_code);
  end;


  FOR r_produto IN c_produto LOOP
    -- 10/03/2021 - Guilherme - Novo bloco de variaveis


    cd_carteira_geral := 0;

    qt_producao      := 0;
    qt_producao_perc := 0;
    qt_compras_eet   := 0;
    qt_compras_eet_portokoll   := 0;
    qt_carteira      := 0;
    qt_carteira_pb   := 0;
    qt_carteira_ant  := 0;
    qt_carteira_ant_portokoll  := 0;
    qt_carteira_portokoll :=0;
    qt_potes_demais  := 0;
    qt_potes_pb      := 0;
    qt_reserva       := 0;
    qt_alocada       := 0;
    qt_reserva_pb    := 0;
    qt_alocada_pb    := 0;
    qt_saldo         := 0;
    qt_saldo_pb      := 0;
    qt_saldo_neg     := 0;
    qt_saldo_neg_pb  := 0;
    qt_cd_portokoll  := NULL;
    it_compra_int_portokoll := 0;
    qt_fabrica    := 0;
    qt_fronteira  := 0;
    cd_saldo_geral := 0;
    cd_negativo_geral := 0;

    log_passo_a_passo := p_gera_log;
    log_geral := p_gera_log_geral;


    --
    OPEN c_reserva(r_produto.inventory_item_id
                  ,r_produto.item_um);
    FETCH c_reserva
    INTO qt_reserva,
         qt_alocada;
    CLOSE c_reserva;
    --
    -- Busca dados de Reserva\Alocado da PBShop - Apenas no primeiro periodo (variaveis zeradas antes do loop do primeiro ciclo
    OPEN c_reserva_pbshop(r_produto.inventory_item_id
                         ,r_produto.item_um);
    FETCH c_reserva_pbshop
    INTO qt_reserva_pb, qt_alocada_pb;
    CLOSE c_reserva_pbshop;
    --
    w_qt_reserva := qt_reserva;
    w_qt_alocada := qt_alocada;
    --
    w_qt_reserva_pbshop := qt_reserva_pb;
    w_qt_alocada_pbshop := qt_alocada_pb;
    --
    cont := cont+1;

    if log_geral = 1 THEN 
        dbms_output.put_line('');
        dbms_output.put_line('======================================================================');
        dbms_output.put_line('Loop de produto..');
        dbms_output.put_line('Cont: '||cont);
        dbms_output.put_line('r_produto.inventory_item_id: '||r_produto.inventory_item_id);
        dbms_output.put_line('r_produto.segment1: '||r_produto.segment1);
    end if;

    DELETE OM_SALDO_PRODUTO_ATP_JB_CD_V2 WHERE COD_ITEM = r_produto.segment1;
    DELETE OM_SALDO_PRODUTO_ATP_JB WHERE INVENTORY_ITEM_ID = r_produto.inventory_item_id; 
    COMMIT;


    --
    w_qt_reserva               := 0;
    w_qt_reserva_pbshop        := 0;
    w_qt_alocada               := 0;
    w_qt_alocada_pbshop        := 0;
    w_qt_carteira_pedido       := 0;
    --
    w_qt_saldo_anterior        := 0;
    w_qt_saldo_anterior_pbshop := 0;
    w_qt_saldo_pbshop_negativo := 0;
    --
    w_qt_saldo                 := 0;

    w_STK_Transf_CD := 0;

    --Seleciona os periodos do horizonte de saldo
    FOR r_periodo IN 1..omp12001jb.fnd_qtd_periodo_dec LOOP
      if log_passo_a_passo = 1 THEN 
        dbms_output.put_line('INICIO DO LOOP POR PERIODO');
          -- Busca dados de Carteira de pedidos do periodo
        dbms_output.put_line('Busca dados de Carteira de Pedidos');
      end if;
      OPEN c_carteira_ped(r_produto.inventory_item_id
                         ,r_produto.item_um
                         ,r_periodo
                         );
      FETCH c_carteira_ped
      INTO qt_carteira;
      CLOSE c_carteira_ped;



      dados_log := NULL;
      dados_log := 'Codigo: '|| r_produto.segment1 || ' | ';
      dados_log := dados_log ||'Id.: '|| r_produto.inventory_item_id || ' | ';
      dados_log := dados_log ||'Periodo: '|| to_char(r_periodo) || ' | ';

      --
      -- Calculo de Saldo para encher potes - Demais Canais
      if log_passo_a_passo = 1 THEN 
        dbms_output.put_line('Calculo de Potes - Demais Canais');
      end if;
      if nvl(qt_reserva,0) > nvl(qt_alocada,0) then
        qt_potes_demais := nvl(qt_reserva,0) - nvl(qt_alocada,0);
      else
        qt_potes_demais := 0;
      end if;
      --
      -- Calculo de Saldo para encher potes - PBShop
          if log_passo_a_passo = 1 THEN 
            dbms_output.put_line('Calculo de Potes - PBShop');
        end if;
      if nvl(qt_reserva_pb,0) > nvl(qt_alocada_pb,0) then
        qt_potes_pb := nvl(qt_reserva_pb,0) - nvl(qt_alocada_pb,0);
      else
        qt_potes_pb := 0;
      end if;

      dados_log := dados_log || 'Potes Demais: '||nvl(qt_potes_demais,0)|| ' | Potes PB: ' || nvl(qt_potes_pb,0) || ' | ';

      --
      qt_producao := 0;
      --  Busca dados de produ��o dentro do periodo
          if log_passo_a_passo = 1 THEN 
            dbms_output.put_line('Busca dados de produ��o');
        end if;
      OPEN c_producao (r_produto.inventory_item_id,
                       r_produto.item_um,
                       r_periodo
                      );
      FETCH c_producao
      INTO qt_producao;
      CLOSE c_producao;
      --

      dados_log := dados_log || 'Producao: '||nvl(qt_producao,0)|| ' | ';

      qt_compras_eet := 0;
      --  Busca dados de produ��o dentro do periodo
          if log_passo_a_passo = 1 THEN 
            dbms_output.put_line('Busca dados de Compras Internas');
        end if;
      OPEN c_compras_interna (r_produto.inventory_item_id,
                              r_produto.item_um,
                              r_periodo
                             );
      FETCH c_compras_interna
      INTO qt_compras_eet;
      CLOSE c_compras_interna;
      --

      dados_log := dados_log || 'Compra Interna: '||nvl(qt_compras_eet,0)|| ' | ';

      qt_compras_eet_portokoll := 0;

      --VALIDA��ES E COMPOSI��ES QUE OCORREM SOMENTE NO PRIMEIRO PERIODO
      if nvl(r_periodo,0) = 1 then
        if nvl(considera_transitorio,0) = 1 then
              --  Busca dados de estoque Fabrica
                  if log_passo_a_passo = 1 THEN 
                    dbms_output.put_line('Busca dados de Estoque Fabrica');
                end if;
              OPEN c_fabrica (r_produto.inventory_item_id,
                               r_produto.item_um,
                               r_periodo
                              );
              FETCH c_fabrica
              INTO qt_fabrica;
              CLOSE c_fabrica;

              --  Busca dados de estoque Fronteira
                  if log_passo_a_passo = 1 THEN 
                    dbms_output.put_line('Busca dados de Estoque Fronteira');
                end if;
              OPEN c_fronteira (r_produto.inventory_item_id,
                               r_produto.item_um,
                               r_periodo    
                              );
              FETCH c_fronteira
              INTO qt_fronteira;
              CLOSE c_fronteira;

              w_ret := omp12001jb.fnd_hist_dados_transit(r_produto.inventory_item_id);

              --
        end if;


        it_compra_int_portokoll := 0;
            if log_passo_a_passo = 1 THEN 
                dbms_output.put_line('Verifica se � compra interna Portokoll');
            end if;
        OPEN c_tem_portokoll(r_produto.inventory_item_id,
                             r_produto.item_um,
                             omp12001jb.fnd_qtd_periodo_dec);
        FETCH c_tem_portokoll
        INTO it_compra_int_portokoll;
        CLOSE c_tem_portokoll;
      end if;




      if nvl(it_compra_int_portokoll,0) > 0 then 
             if log_passo_a_passo = 1 THEN 
                dbms_output.put_line('Compra interna Portokoll');
            end if;


         qt_cd_portokoll := 'EET';

         dados_log := dados_log || 'Compra Portokoll: Sim' || ' | ';
            --  Busca dados de produ��o dentro do periodo - Somente Portokoll
                if log_passo_a_passo = 1 THEN 
                    dbms_output.put_line('Busca dados de Compra interna Portokoll');
                end if;
          OPEN c_compras_interna_portokoll (r_produto.inventory_item_id,
                                  r_produto.item_um,
                                  r_periodo
                                 );
          FETCH c_compras_interna_portokoll
          INTO qt_compras_eet_portokoll, qt_cd_portokoll;
          CLOSE c_compras_interna_portokoll;

          dados_log := dados_log || 'Qtde. Compra Portokoll: '|| nvl(qt_compras_eet_portokoll,0)|| ' | CD : EET'  ||' | ';



          -- Busca carteira de pedidos somente do CD que realizou a compra interna

          if nvl(r_periodo,0) = 1 then
            qt_carteira_portokoll := nvl(omp12001jb.fnd_carteira_interna(r_produto.inventory_item_id, r_produto.item_um, r_periodo, 'EET'),0);
          end if;
          if nvl(r_periodo,0) = 2 then
            qt_carteira_portokoll := 0;
          end if;
          if nvl(r_periodo,0) > 2 then 
            qt_carteira_portokoll := nvl(omp12001jb.fnd_carteira_interna(r_produto.inventory_item_id, r_produto.item_um, r_periodo - 1, 'EET'),0);
          end if;
          dados_log := dados_log || 'Qtde. Carteira Portokoll: '|| nvl(qt_carteira_portokoll,0)|| ' | ';
          dados_log := dados_log || 'Qtde. Cart. Ant. Portokoll: '|| nvl(qt_carteira_ant_portokoll,0)|| ' | ';
          dados_log := dados_log || 'Saldo Negativo: '|| nvl(qt_saldo_neg,0)|| ' | ';


          if log_passo_a_passo = 1 THEN 
            dbms_output.put_line('Inicio do Calculo');
          end if;

          --qt_producao_perc := ((nvl(qt_producao,0) + nvl(qt_compras_eet,0)) * (w_pr_disponivel_saldo / 100));
          qt_producao_perc := nvl(qt_compras_eet_portokoll,0);

          dados_log := dados_log || 'Est. Fabrica: ' || nvl(qt_fabrica,0)|| ' | Est. Fronteira: ' || nvl(qt_fronteira,0) || ' | ';
          qt_producao_perc := nvl(qt_producao_perc,0) + nvl(qt_fabrica,0) + nvl(qt_fronteira,0);


          --
          -- Calculo de Saldo - Demais Canais
          if nvl(r_periodo,0) = 1 then
            qt_saldo := nvl(qt_producao_perc,0) - nvl(qt_carteira_portokoll,0) - nvl(qt_potes_demais,0) - nvl(qt_potes_pb,0);
            if nvl(qt_saldo,0) < 0 then
              qt_saldo_neg := abs(nvl(qt_saldo,0));
            else
              qt_saldo_neg := 0;
            end if;
          else
            if nvl(r_periodo,0) = 2 then
              qt_saldo := nvl(qt_producao_perc,0) - nvl(qt_saldo_neg,0) ;
              if nvl(qt_saldo,0) < 0 then
                qt_saldo_neg := abs(nvl(qt_saldo,0));
              else
                qt_saldo_neg := 0;
              end if;
            else
              --qt_saldo := nvl(qt_producao_perc,0) - nvl(qt_saldo_neg,0) - nvl(qt_carteira_ant_portokoll,0) ;
              qt_saldo := nvl(qt_producao_perc,0) - nvl(qt_saldo_neg,0) - nvl(qt_carteira_portokoll,0) ;
              if nvl(qt_saldo,0) < 0 then
                qt_saldo_neg := abs(nvl(qt_saldo,0));
              else
                qt_saldo_neg := 0;
              end if;
            end if;
          end if;
          --
          -- v2 : retirado o desconto de carteira e de saldo negativo
          -- Calculo de Saldo - PBShop
          if nvl(r_periodo,0) = 1 then
            --qt_saldo_pb := nvl(qt_producao_perc,0) - nvl(qt_carteira_portokoll,0) - nvl(qt_potes_demais,0);
            qt_saldo_pb := nvl(qt_producao_perc,0) - nvl(qt_potes_demais,0);
            if nvl(qt_saldo_pb,0) < 0 then
              qt_saldo_neg_pb := abs(nvl(qt_saldo_pb,0));
            else
              qt_saldo_neg_pb := 0;
            end if;
          else
            if nvl(r_periodo,0) = 2 then
              --qt_saldo_pb := nvl(qt_producao_perc,0) - nvl(qt_saldo_neg_pb,0);
              qt_saldo_pb := nvl(qt_producao_perc,0) - nvl(qt_saldo_neg_pb,0);
              --qt_saldo_pb := nvl(qt_producao_perc,0) ;
              if nvl(qt_saldo_pb,0) < 0 then
                qt_saldo_neg_pb := abs(nvl(qt_saldo_pb,0));
              else
                qt_saldo_neg_pb := 0;
              end if;
            else
              --qt_saldo_pb := nvl(qt_producao_perc,0) - nvl(qt_saldo_neg_pb,0) - nvl(qt_carteira_ant_portokoll,0);
              --qt_saldo_pb := nvl(qt_producao_perc,0);
              qt_saldo_pb := nvl(qt_producao_perc,0) - nvl(qt_saldo_neg_pb,0);
              if nvl(qt_saldo_pb,0) < 0 then
                qt_saldo_neg_pb := abs(nvl(qt_saldo_pb,0));
              else
                qt_saldo_neg_pb := 0;
              end if;
            end if;
          end if;


      else
              if log_passo_a_passo = 1 THEN 
                dbms_output.put_line('N�o � Compra interna Portokoll');
            end if;

         dados_log := dados_log || 'Compra Portokoll: N�o' || ' | ';
          --qt_producao_perc := ((nvl(qt_producao,0) + nvl(qt_compras_eet,0)) * (w_pr_disponivel_saldo / 100));
          qt_producao_perc := ((nvl(qt_producao,0)  * (w_pr_disponivel_saldo / 100)) + nvl(qt_compras_eet,0));

          dados_log := dados_log || 'Est. Fabrica: ' || nvl(qt_fabrica,0)|| ' | Est. Fronteira: ' || nvl(qt_fronteira,0) || ' | ';
          qt_producao_perc := nvl(qt_producao_perc,0) + nvl(qt_fabrica,0) + nvl(qt_fronteira,0);
          --
          dados_log := dados_log || 'Qtd. Carteira: ' || nvl(qt_carteira,0)|| ' | ';
          dados_log := dados_log || 'Saldo Negativo: ' || nvl(qt_saldo_neg,0)|| ' | ';


              if log_passo_a_passo = 1 THEN 
                dbms_output.put_line('Inicio do Calculo');
            end if;

          -- Calculo de Saldo - Demais Canais
          if nvl(r_periodo,0) = 1 then
            qt_saldo := nvl(qt_producao_perc,0) - nvl(qt_carteira,0) - nvl(qt_potes_demais,0) - nvl(qt_potes_pb,0);
            if nvl(qt_saldo,0) < 0 then
              qt_saldo_neg := abs(nvl(qt_saldo,0));
            else
              qt_saldo_neg := 0;
            end if;
          else
            if nvl(r_periodo,0) = 2 then
              qt_saldo := nvl(qt_producao_perc,0) - nvl(qt_saldo_neg,0) ;
              if nvl(qt_saldo,0) < 0 then
                qt_saldo_neg := abs(nvl(qt_saldo,0));
              else
                qt_saldo_neg := 0;
              end if;
            else
              qt_saldo := nvl(qt_producao_perc,0) - nvl(qt_saldo_neg,0) - nvl(qt_carteira_ant,0) ;
              if nvl(qt_saldo,0) < 0 then
                qt_saldo_neg := abs(nvl(qt_saldo,0));
              else
                qt_saldo_neg := 0;
              end if;
            end if;
          end if;
          --
          -- v2 : retirado o desconto de carteira e de saldo negativo
          -- Calculo de Saldo - PBShop
          if nvl(r_periodo,0) = 1 then
            --qt_saldo_pb := nvl(qt_producao_perc,0) - nvl(qt_carteira,0) - nvl(qt_potes_demais,0);
            qt_saldo_pb := nvl(qt_producao_perc,0) - nvl(qt_potes_demais,0);
          else

            qt_saldo_pb := nvl(qt_producao_perc,0);

          end if;
      end if;



      --
      if Upper(r_produto.item_um) = 'PC' then
        --
        w_producao_menos_carteira := Trunc(w_producao_menos_carteira);
        w_qt_saldo_disponivel     := Trunc(w_qt_saldo_disponivel);
        --
      end if;

      BEGIN
        IF nvl(r_produto.compras,0) = 0 or nvl(it_compra_int_portokoll,0) = 0 then

            cd_codigo := r_produto.segment1;

            cd_carteira_geral:= 0;
            if nvl(r_periodo,0) = 1 then 
              cd_carteira_negativa := 0;
               cd_carteira_geral := nvl(omp12001jb.fnd_carteira_shop(r_produto.inventory_item_id, r_produto.item_um, r_periodo),0);
            end if;
            if nvl(r_periodo,0) = 2 then 
              cd_carteira_geral := 0;
            end if;
            if nvl(r_periodo,0) > 2 then 
              cd_carteira_geral := nvl(omp12001jb.fnd_carteira_shop(r_produto.inventory_item_id, r_produto.item_um, r_periodo - 1),0);
            end if;

            cd_pedidos := 0;
            if r_periodo = 1 then 
              cd_pedidos := nvl(omp12001jb.fnd_carteira(r_produto.inventory_item_id, r_produto.item_um, r_periodo, 'EET'),0);
            else 
              if r_periodo = 2 then 
                cd_pedidos := 0;
              else
                cd_pedidos := nvl(omp12001jb.fnd_carteira(r_produto.inventory_item_id, r_produto.item_um, r_periodo - 1, 'EET'),0);
              end if;
            end if;

            w_STK_Transf_CD := 0;
            --SELECT Nvl(Sum(REPLACE(fdet.vol_meta,'.',',')),0)  --Nvl(Sum(fdet.vol_meta),0)
            SELECT Nvl(Sum(APPS.OMP003APO.CONVERTE(fdet.vol_meta)),0)  --Nvl(Sum(fdet.vol_meta),0)
              INTO w_STK_Transf_CD
              FROM TEMP_DRP_ESTOQUE_TRANSITO fdet
            WHERE fdet.cod_item = r_produto.segment1
              AND omp12001jb.fnd_periodo_dec(To_Date(SubStr(fdet.dat_previsao_chegada,1,10),'YYYY-MM-DD'),fdet.des_cd) = r_periodo;

            cd_volume_meta := 0;
            --SELECT Nvl(Sum(REPLACE(fdet.vol_meta,'.',',')),0), max(dat_previsao_chegada)  --Nvl(Sum(fdet.vol_meta),0)
            SELECT Nvl(Sum(APPS.OMP003APO.CONVERTE(fdet.vol_meta)),0), max(dat_previsao_chegada)  --Nvl(Sum(fdet.vol_meta),0)
              INTO cd_volume_meta, cd_data_meta
              FROM TEMP_DRP_ESTOQUE_TRANSITO fdet
            WHERE fdet.cod_item = r_produto.segment1
              AND omp12001jb.fnd_periodo_dec(To_Date(SubStr(fdet.dat_previsao_chegada,1,10),'YYYY-MM-DD'),fdet.des_cd) = r_periodo
              AND fdet.DES_CD = 'EET';

            cd_demanda_geral := 0;
            cd_demanda_geral := (nvl(cd_carteira_geral,0) - nvl(w_STK_Transf_CD,0)) + nvl(cd_carteira_negativa,0);

            cd_negativo := 0;
            if r_periodo > 1 then 
              cd_negativo := nvl(omp12001jb.fnd_saldo_anterior_cd(cd_codigo, r_periodo, 'EET'),0);
            end if;
            cd_pedidos := nvl(cd_pedidos,0) + abs(nvl(cd_negativo,0));

            cd_demanda_geral := nvl(cd_demanda_geral,0) - (nvl(cd_pedidos,0) + nvl(cd_volume_meta,0));

            cd_prod_carteira := 0;
            cd_prod_carteira := nvl(qt_saldo_pb,0) - nvl(cd_demanda_geral,0); -- (nvl(cd_carteira_geral,0) + nvl(w_STK_Transf_CD,0))- nvl(cd_carteira_negativa,0);

            cd_saldo :=0;
            cd_saldo := nvl(cd_volume_meta,0) - nvl(cd_pedidos,0);

            --cd_saldo := nvl(cd_saldo,0) + nvl(cd_negativo,0);


            cd_projecao := 0;
            if nvl(qt_saldo_pb,0) <= 0 then 
                cd_projecao := nvl(cd_saldo,0);
            else
                if nvl(cd_prod_carteira,0) >0 then 
                    cd_projecao := nvl(cd_saldo,0) + nvl(cd_prod_carteira,0);
                else
                    cd_projecao := nvl(cd_saldo,0);
                end if;
            end if;

            dados_log_cd := 'CD : EET' || ' | ';
            dados_log_cd := dados_log_cd || 'Produ��o - Potes Demais: ' || nvl(qt_saldo_pb,0) || ' | ';
            dados_log_cd := dados_log_cd || 'Carteira Geral: ' || nvl(cd_carteira_geral,0) || ' | ';
            dados_log_cd := dados_log_cd || 'Demanda Geral: ' || nvl(cd_demanda_geral,0) || ' | ';
            dados_log_cd := dados_log_cd || 'Carteira CD: ' || nvl(cd_pedidos,0) || ' | ';
            dados_log_cd := dados_log_cd || 'Vol. Meta Total.: ' || nvl(w_STK_Transf_CD,0) || ' | ';
            dados_log_cd := dados_log_cd || 'Vol. Meta CD: ' || nvl(cd_volume_meta,0) || ' | ';
            dados_log_cd := dados_log_cd || 'Saldo PRD vs CART: ' || nvl(cd_prod_carteira,0) || ' | ';
            dados_log_cd := dados_log_cd || 'Negativo do CD: ' || nvl(cd_negativo,0) || ' | ';
            dados_log_cd := dados_log_cd || 'Saldo CD: ' || nvl(cd_saldo,0) || ' | ';
            dados_log_cd := dados_log_cd || 'Proje��o CD: ' || nvl(cd_projecao,0);
            dados_log_cd := dados_log_cd || 'Negativo - Periodo Anterior: ' || nvl(cd_carteira_negativa,0);
            if log_geral = 1 or log_passo_a_passo = 1 THEN
              dbms_output.put_line(dados_log_cd);
            end if;

            INSERT INTO OM_SALDO_PRODUTO_ATP_JB_CD_V2(COD_ITEM, DES_CD, ID_PERIODO, VOL_META, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, DATA_CHEGADA, SALDO_TOTAL, VOL_PEDIDO, STK_META, CARTEIRA_GERAL, STK_META_GERAL)
            VALUES (cd_codigo, 'EET', r_periodo, 0, sysdate, nvl(w_id_usuario,0), sysdate, nvl(w_id_usuario,0), NULL, nvl(cd_projecao,0), 0,2,nvl(cd_carteira_geral,0),nvl(w_STK_Transf_CD,0));

            COMMIT;


            FOR r_cds IN c_cd LOOP
                  cd_cd := r_cds.lookup_code;

                   cd_pedidos := 0;
                  if r_periodo = 1 then 
                     cd_pedidos := nvl(omp12001jb.fnd_carteira(r_produto.inventory_item_id, r_produto.item_um, r_periodo, cd_cd),0);
                  else 
                    if r_periodo = 2 then 
                      cd_pedidos := 0;
                    else
                        cd_pedidos := nvl(omp12001jb.fnd_carteira(r_produto.inventory_item_id, r_produto.item_um, r_periodo - 1, cd_cd),0);
                    end if;
                  end if;

                  cd_volume_meta := 0;
                  --SELECT Nvl(Sum(REPLACE(fdet.vol_meta,'.',',')),0), max(dat_previsao_chegada)  --Nvl(Sum(fdet.vol_meta),0)
                  SELECT Nvl(Sum(APPS.OMP003APO.CONVERTE(fdet.vol_meta)),0), max(dat_previsao_chegada)  --Nvl(Sum(fdet.vol_meta),0)
                  INTO cd_volume_meta, cd_data_meta
                  FROM TEMP_DRP_ESTOQUE_TRANSITO fdet
                  WHERE fdet.cod_item = r_produto.segment1
                  AND omp12001jb.fnd_periodo_dec(To_Date(SubStr(fdet.dat_previsao_chegada,1,10),'YYYY-MM-DD'),fdet.des_cd) = r_periodo
                  AND fdet.DES_CD = cd_cd;

                    cd_negativo := 0;
                    if r_periodo > 1 then 
                      cd_negativo := nvl(omp12001jb.fnd_saldo_anterior_cd(cd_codigo, r_periodo, cd_cd),0);
                    end if;
                    cd_pedidos := nvl(cd_pedidos,0) + abs(nvl(cd_negativo,0));

                    cd_demanda_geral := 0;
                    cd_demanda_geral := (nvl(cd_carteira_geral,0) - nvl(w_STK_Transf_CD,0)) + nvl(cd_carteira_negativa,0);
                    cd_demanda_geral := nvl(cd_demanda_geral,0) - (nvl(cd_pedidos,0) + nvl(cd_volume_meta,0));

                    cd_prod_carteira := 0;
                    cd_prod_carteira := nvl(qt_saldo_pb,0) - nvl(cd_demanda_geral,0); -- (nvl(cd_carteira_geral,0) + nvl(w_STK_Transf_CD,0))- nvl(cd_carteira_negativa,0);

                    cd_saldo :=0;
                    cd_saldo := nvl(cd_volume_meta,0) - nvl(cd_pedidos,0);
                    --cd_saldo := nvl(cd_saldo,0) + nvl(cd_negativo,0);

                    cd_projecao := 0;
                    if nvl(qt_saldo_pb,0) <= 0 then 
                        cd_projecao := nvl(cd_saldo,0);
                    else
                        if nvl(cd_prod_carteira,0) >0 then 
                            cd_projecao := nvl(cd_saldo,0) + nvl(cd_prod_carteira,0);
                        else
                            cd_projecao := nvl(cd_saldo,0);
                        end if;
                    end if;


                  dados_log_cd := 'CD : ' || cd_cd || ' | ';
                  dados_log_cd := dados_log_cd || 'Produ��o - Potes Demais: ' || nvl(qt_saldo_pb,0) || ' | ';
                  dados_log_cd := dados_log_cd || 'Carteira Geral: ' || nvl(cd_carteira_geral,0) || ' | ';
                  dados_log_cd := dados_log_cd || 'Demanda Geral: ' || nvl(cd_demanda_geral,0) || ' | ';
                  dados_log_cd := dados_log_cd || 'Carteira CD: ' || nvl(cd_pedidos,0) || ' | ';
                  dados_log_cd := dados_log_cd || 'Vol. Meta Total.: ' || nvl(w_STK_Transf_CD,0) || ' | ';
                  dados_log_cd := dados_log_cd || 'Vol. Meta CD: ' || nvl(cd_volume_meta,0) || ' | ';
                  dados_log_cd := dados_log_cd || 'Saldo PRD vs CART: ' || nvl(cd_prod_carteira,0) || ' | ';
                  dados_log_cd := dados_log_cd || 'Negativo do CD: ' || nvl(cd_negativo,0) || ' | ';
                  dados_log_cd := dados_log_cd || 'Saldo CD: ' || nvl(cd_saldo,0) || ' | ';
                  dados_log_cd := dados_log_cd || 'Proje��o CD: ' || nvl(cd_projecao,0);
                  if log_geral = 1 or log_passo_a_passo = 1 THEN
                     dbms_output.put_line(dados_log_cd);
                  end if;

                  INSERT INTO OM_SALDO_PRODUTO_ATP_JB_CD_V2(COD_ITEM, DES_CD, ID_PERIODO, VOL_META, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, DATA_CHEGADA, SALDO_TOTAL, VOL_PEDIDO, STK_META, CARTEIRA_GERAL, STK_META_GERAL)
                  VALUES (cd_codigo, cd_cd, r_periodo, cd_volume_meta, sysdate, nvl(w_id_usuario,0), sysdate, nvl(w_id_usuario,0), cd_data_meta, nvl(cd_projecao,0), nvl(cd_pedidos,0),2,nvl(cd_carteira_geral,0),nvl(w_STK_Transf_CD,0));

                  commit;

            end loop;          

            if nvl(cd_prod_carteira,0) > 0 then 
                cd_carteira_negativa := 0;
            else
                cd_carteira_negativa := abs(cd_prod_carteira) - nvl(cd_volume_meta,0) + nvl(cd_pedidos,0);
            end if;


        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          IF ( send_email( 'Erro ao gravar o saldo de produto na tabela OM_SALDO_PRODUTO_ATP_JB_CD_V2 (Produ��o). Erro: '||SQLERRM || ' | Codigo: '||SQLCODE || ' - Log: ' || dados_log || ' - Log CD:' || dados_log_cd) <> 'OK' ) THEN
             dbms_output.put_line('  ERRO: N�o foi poss�vel enviar o e-mail.');
          END IF;

          w_ds_erro:= 'Erro ao gravar o saldo de produtos. Erro:'||SQLERRM;
          dbms_output.put_line('Calulo Producao por CD:' || w_ds_erro);
          --RAISE w_erro;

      END;



      begin
          IF nvl(it_compra_int_portokoll,0) = 1 then 

              cd_codigo := r_produto.segment1;

              cd_cd := 'EET';
              cd_qtd := 0;
              cd_data := null;
              cd_pedidos := 0;
              cd_negativo := 0;      

              if log_passo_a_passo = 1 THEN 
                dbms_output.put_line('Execucao do calculo - Compra interna do CD ' || cd_cd);

                dbms_output.put_line('Busca dados de compra do CD');                      
              end if;

              OPEN c_compras_cd (r_produto.inventory_item_id,
                          r_produto.item_um,
                          r_periodo,
                          cd_cd
                         );
              FETCH c_compras_cd
              INTO cd_codigo, cd_qtd, cd_data;
              CLOSE c_compras_cd;

              cd_qtd := nvl(cd_qtd,0) + nvl(qt_fabrica,0) + nvl(qt_fronteira,0);


              if log_passo_a_passo = 1 THEN 
                dbms_output.put_line('Busca dados de Carteira do CD');                      
              end if;
              if r_periodo = 1 then 
                cd_pedidos := nvl(omp12001jb.fnd_carteira(r_produto.inventory_item_id, r_produto.item_um, r_periodo, cd_cd),0);
              else 
                if r_periodo = 2 then 
                    cd_pedidos := 0;
                else
                    cd_pedidos := nvl(omp12001jb.fnd_carteira(r_produto.inventory_item_id, r_produto.item_um, r_periodo - 1, cd_cd),0);
                end if;
              end if;

              if log_passo_a_passo = 1 THEN 
                dbms_output.put_line('Busca dados de saldo negativo do CD');                      
              end if;
              cd_negativo := nvl(omp12001jb.fnd_saldo_anterior_cd(cd_codigo, r_periodo, cd_cd),0);



              dados_log_cd := 'CD : EET' || ' | ';
              dados_log_cd := dados_log_cd || 'Compras do CD: ' || nvl(cd_qtd,0) || ' | ';
              dados_log_cd := dados_log_cd || 'Pedidos do CD: ' || nvl(cd_pedidos,0) || ' | ';
              dados_log_cd := dados_log_cd || 'Saldo Negativo: ' || nvl(cd_negativo,0) || ' | ';
              dados_log_cd := dados_log_cd || 'Saldo CD: ' || (nvl(cd_qtd,0) - nvl(cd_pedidos,0) - (nvl(cd_negativo,0) * -1));

              if log_geral = 1 or log_passo_a_passo = 1 THEN
                dbms_output.put_line(dados_log_cd);
              end if;


              INSERT INTO OM_SALDO_PRODUTO_ATP_JB_CD_V2(COD_ITEM, DES_CD, ID_PERIODO, VOL_META, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, DATA_CHEGADA, SALDO_TOTAL, VOL_PEDIDO, STK_META)
              VALUES (cd_codigo, cd_cd, r_periodo, cd_qtd, sysdate, nvl(w_id_usuario,0), sysdate, nvl(w_id_usuario,0), cd_data, nvl(cd_qtd,0) - nvl(cd_pedidos,0) - (nvl(cd_negativo,0) * -1), nvl(cd_pedidos,0),0);

              commit;              

              FOR r_cds IN c_cd LOOP

                      cd_cd := r_cds.lookup_code;
                      cd_qtd := 0;
                      cd_data := null;
                      cd_pedidos := 0;
                      cd_negativo := 0;      

                        if log_passo_a_passo = 1 THEN 
                            dbms_output.put_line('Execucao do calculo - Compra interna do CD ' || cd_cd);

                            dbms_output.put_line('Busca dados de compra do CD');                      
                        end if;

                      OPEN c_compras_cd (r_produto.inventory_item_id,
                                  r_produto.item_um,
                                  r_periodo,
                                  r_cds.lookup_code
                                 );
                      FETCH c_compras_cd
                      INTO cd_codigo, cd_qtd, cd_data;
                      CLOSE c_compras_cd;

                          if log_passo_a_passo = 1 THEN 
                            dbms_output.put_line('Busca dados de Carteira do CD');                      
                        end if;
                      if r_periodo = 1 then 
                        cd_pedidos := nvl(omp12001jb.fnd_carteira(r_produto.inventory_item_id, r_produto.item_um, r_periodo, cd_cd),0);
                      else 
                        if r_periodo = 2 then 
                            cd_pedidos := 0;
                        else
                            cd_pedidos := nvl(omp12001jb.fnd_carteira(r_produto.inventory_item_id, r_produto.item_um, r_periodo - 1, cd_cd),0);
                        end if;
                      end if;

                          if log_passo_a_passo = 1 THEN 
                            dbms_output.put_line('Busca dados de saldo negativo do CD');                      
                        end if;
                      cd_negativo := nvl(omp12001jb.fnd_saldo_anterior_cd(cd_codigo, r_periodo, cd_cd),0);



                      dados_log_cd := 'CD :' || cd_cd || ' | ';
                      dados_log_cd := dados_log_cd || 'Compras do CD: ' || nvl(cd_qtd,0) || ' | ';
                      dados_log_cd := dados_log_cd || 'Pedidos do CD: ' || nvl(cd_pedidos,0) || ' | ';
                      dados_log_cd := dados_log_cd || 'Saldo Negativo: ' || nvl(cd_negativo,0) || ' | ';
                      dados_log_cd := dados_log_cd || 'Saldo CD: ' || (nvl(cd_qtd,0) - nvl(cd_pedidos,0) - (nvl(cd_negativo,0) * -1));

                      if log_geral = 1 or log_passo_a_passo = 1 THEN
                        dbms_output.put_line(dados_log_cd);
                      end if;


                      INSERT INTO OM_SALDO_PRODUTO_ATP_JB_CD_V2(COD_ITEM, DES_CD, ID_PERIODO, VOL_META, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, DATA_CHEGADA, SALDO_TOTAL, VOL_PEDIDO, STK_META)
                      VALUES (cd_codigo, cd_cd, r_periodo, cd_qtd, sysdate, nvl(w_id_usuario,0), sysdate, nvl(w_id_usuario,0), cd_data, nvl(cd_qtd,0) - nvl(cd_pedidos,0) - (nvl(cd_negativo,0) * -1), nvl(cd_pedidos,0),0);

                      commit;
              end loop;          
          end if;

      EXCEPTION
        WHEN OTHERS THEN
          IF ( send_email( 'Erro ao gravar o saldo de produto na tabela OM_SALDO_PRODUTO_ATP_JB_CD_V2 (Compras). Erro: '||SQLERRM || ' | Codigo: '||SQLCODE || ' - Log: ' || dados_log || ' - Log CD:' || dados_log_cd) <> 'OK' ) THEN
             dbms_output.put_line('  ERRO: N�o foi poss�vel enviar o e-mail.');
          END IF;

          w_ds_erro:= 'Erro ao gravar o saldo de compra de produtos. Erro:'||SQLERRM;
          dbms_output.put_line('Calulo Compras por CD:' || w_ds_erro);
          --RAISE w_erro;
      end;


      --
      BEGIN
        dados_log := dados_log || 'Saldo Demais: ' || nvl(qt_saldo,0)|| ' | ';
        dados_log := dados_log || 'Saldo PBShop: ' || nvl(cd_saldo_geral,0)|| ' | ';
        if log_geral = 1 or log_passo_a_passo = 1 THEN
            dbms_output.put_line(dados_log);
        end if;


        INSERT INTO OM_SALDO_PRODUTO_ATP_JB
          (inventory_item_id,
          item_um,
          id_periodo,
          dt_final_periodo,
          qt_programada_producao,
          qt_carteira_pedido,
          qt_reserva,
          qt_alocada,
          pr_disponivel_saldo,
          qt_saldo,
          qt_saldo_disponivel,
          creation_date,
          created_by,
          last_update_date,
          last_updated_by,
          qt_saldo_disponivel_pbshop,
          qt_transferencia,
          qt_reserva_pbshop,
          qt_alocada_pbshop,
          qtd_saldo_neg,          -- adicionado em 04/mar/2021
          qtd_saldo_neg_pb        -- adicionado em 04/mar/2021
          --id_projetar_demais_canais,
          --id_projetar_pbshop
          )
        VALUES
          (r_produto.inventory_item_id,
          r_produto.item_um,
          r_periodo,  --.id_periodo,
          omp12001jb.fnd_data_fim_periodo_dec(r_periodo,'N'),
          nvl(qt_producao,0),
          nvl(qt_carteira,0),
          nvl(qt_reserva,0),
          nvl(qt_alocada,0),
          nvl(w_pr_disponivel_saldo,0),
          case when nvl(qt_saldo,0)<0 then 0 else nvl(qt_saldo,0) end,
          nvl(w_qt_saldo_disponivel,0),
          SYSDATE,
          nvl(w_id_usuario,0),
          SYSDATE,
          nvl(w_id_usuario,0),
          case when nvl(qt_saldo_pb,0)<0 then 0 else nvl(qt_saldo_pb,0) end,
          nvl(w_STK_Transf_CD,0),
          nvl(qt_reserva_pb,0),
          nvl(qt_alocada_pb,0),
          nvl(qt_saldo_neg,0) ,
          nvl(qt_saldo_neg_pb,0)
          --w_projetar_demais_canais,
          --w_projetar_pbshop
        );
        --
        COMMIT;
        --
      EXCEPTION
        WHEN OTHERS THEN
          IF ( send_email( 'Erro ao gravar o saldo de produto na tabela OM_SALDO_PRODUTO_ATP_JB. Erro: '||SQLERRM || ' | Codigo: '||SQLCODE || ' - Log: ' || dados_log || ' - Log CD:' || dados_log_cd) <> 'OK' ) THEN
             dbms_output.put_line('  ERRO: N�o foi poss�vel enviar o e-mail.');
          END IF;
          w_ds_erro:= 'Erro ao gravar o saldo de produto na tabela OM_SALDO_PRODUTO_ATP_JB. Erro:'||SQLERRM;
          RAISE w_erro;
      END;
      --
      qt_reserva_pb := 0;
      qt_alocada_pb := 0;
      qt_reserva := 0;
      qt_alocada := 0;
      qt_carteira_ant := qt_carteira;
      qt_carteira_ant_portokoll := qt_carteira_portokoll;
      qt_potes_demais := 0;
      qt_potes_pb := 0;
      qt_saldo := 0;
      qt_saldo_pb := 0;
      qt_fabrica    := 0;
      qt_fronteira  := 0;

      --
    END LOOP;
    --
  END LOOP;
  --
  COMMIT;
  --
  --Envia o e-mail para o grupo d GATE
  w_ds_email := 'Em '||to_char(SYSDATE,'dd/mm/rrrr hh24:mi')|| ' carga de saldo executada com sucesso.';
  --
EXCEPTION
  WHEN w_erro THEN
    dbms_output.put_line('Erro: '||w_ds_erro);
    ROLLBACK;
    --
    w_ds_email := 'Em '||to_char(SYSDATE,'dd/mm/rrrr hh24:mi')||
                   ' ocorreu o erro na carga do saldo APT.'||CHR(10)||
                   'Rotina: omp12001jb.PRC_CARGA_SALDO'||CHR(10)||
                   w_ds_erro;
   --
    --
  WHEN OTHERS THEN
    --dbms_output.put_line('Erro na carga do saldo atp. Erro:'||SQLERRM);
    ROLLBACK;

    w_ds_email := 'Em '||to_char(SYSDATE,'dd/mm/rrrr hh24:mi')||
                   ' ocorreu o erro na carga do saldo APT.'||CHR(10)||
                   'Rotina: omp12001jb.PRC_CARGA_SALDO'||CHR(10)||
                   w_ds_erro;
   --
   --dbms_output.put_line(w_ds_email);

--
END prc_carga_saldo;

PROCEDURE prc_carga_saldo_pointer(p_retcode IN OUT VARCHAR2, p_errbuf IN OUT VARCHAR2)  
IS
p_inventory_item_id NUMBER;
total_consumido number;
qtd_saldo_neg_cd number;
qtd_carteira_fab number;
qtd_producao number;
qtd_saldo number;
qtd_prod_cd number;
qtd_saldo_neg number;
qtd_carteira number;
w_id_usuario NUMBER;
w_erro EXCEPTION;
w_ds_erro VARCHAR2(4000);
v_err varchar2(200);
valida_cd NUMBER;
w_ds_email VARCHAR2(4000);
v_code number;

--Seleciona os produtos que possui programa de produ��o ou compra
CURSOR c_produto IS
SELECT INVENTORY_ITEM_ID, SEGMENT1, ITEM_UM, max(COMPRAS) AS COMPRAS FROM (
  SELECT DISTINCT ppp.inventory_item_id
        ,segment1
        ,ppp.item_um
        ,0 AS compras
    FROM MTL_SYSTEM_ITEMS_B msi
        ,PB_PRODUCAO_PP_ATP ppp
   WHERE msi.item_type          = 'PA' --Produto acabado
  -- Início - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
     AND msi.organization_id    = pb_master_organization_id
     -- Fim - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
     AND msi.inventory_item_id  = ppp.inventory_item_id
     and (msi.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
     AND (ppp.status_op         IN ('WIP','Pendente') OR
          ppp.cod_minifabrica   = 'Compras'
         )
     AND ppp.qtd_pendente       > 0
     AND msi.attribute4         = 1
     AND msi.attribute9        != 'DS'
     
     AND ((Upper(ppp.cod_fabrica) IN ('F40')
           AND ppp.tipo_op != '5'
          )
         )
     AND Trunc(ppp.dt_termino_plan) >= Trunc(SYSDATE)
	 AND ppp.org_code = 'POINTER'
     --
UNION
  SELECT DISTINCT ppp.inventory_item_id
        ,segment1
        ,ppp.item_um
        ,1 AS compras
    FROM MTL_SYSTEM_ITEMS_B msi
        ,PB_PRODUCAO_PP_ATP ppp
   WHERE msi.item_type          = 'PA' --Produto acabado
  -- Início - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
     AND msi.organization_id    = pb_master_organization_id
     -- Fim - Inclusão de condição abaixo por Giovani - Projeto Pointer - Tratativa de organização mestre
     AND msi.inventory_item_id  = ppp.inventory_item_id
     and (msi.inventory_item_id IN(p_inventory_item_id) or nvl(p_inventory_item_id,0) = 0)
     AND (ppp.status_op         IN ('WIP','Pendente') OR
          ppp.cod_minifabrica   = 'Compras'
         )
     AND ppp.qtd_pendente       > 0
     AND msi.attribute4         = 1
     AND msi.attribute9        != 'DS'
     AND Upper(ppp.cod_fabrica) IN ('OUTSOURCING', 'PORTOKOLL')
     AND ppp.status_op IS NULL 
     AND Trunc(ppp.dt_termino_plan) >= Trunc(SYSDATE)
	 AND ppp.org_code = 'POINTER'
) GROUP BY INVENTORY_ITEM_ID, SEGMENT1, ITEM_UM;    


--Seleciona a quantidade programada do produto conforme periodo
CURSOR c_producao(p_inventory_item_id IN NUMBER
                 ,p_item_um           IN VARCHAR2
                 ,p_id_periodo        IN VARCHAR2
                 )
IS
SELECT sum(nvl(round(qtd_pendente,2),0))
FROM (
  SELECT cod_ordem , inventory_item_id , cod_fabrica, max(dt_termino_plan) data_termino, sum(qtd_pendente) qtd_pendente
    FROM PB_PRODUCAO_PP_ATP ppp
   WHERE ppp.item_um = p_item_um
     AND ppp.inventory_item_id = p_inventory_item_id
     AND ((Upper(ppp.cod_fabrica) IN ('F40')
           AND ppp.tipo_op != '5'
          )
         )
   GROUP BY cod_ordem, inventory_item_id, cod_fabrica
) a
WHERE omp12001jb.fnd_periodo_dec(a.data_termino+ Nvl(omp12001jb.fnd_dias_seguranca_prod_dec,0)
                                       ,a.cod_fabrica
                                       ) = p_id_periodo;

cursor c_parametros
is
SELECT lookup_code id, meaning cod, description atende_carteira, tag percente
                     FROM FND_LOOKUP_VALUES
                    WHERE LANGUAGE            = USERENV('LANG')
                      AND enabled_flag        = 'Y'
                      AND security_group_id   = 0
                      AND view_application_id = 660
                      AND lookup_type         = 'PB_PARAM_ATP_POINTER'
                      AND Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                             AND Trunc(Nvl(end_date_active, SYSDATE));


--Seleciona a Carteria de DMF
CURSOR c_carteira_ped (p_inventory_item_id IN NUMBER
                      ,p_item_um           IN VARCHAR2
                      ,p_id_periodo        IN VARCHAR2
					  ,p_deposito          IN NUMBER
                      )
IS
  SELECT sum(ola.ordered_quantity - NVL((SELECT SUM(mr.reservation_quantity)
                                           FROM MTL_RESERVATIONS mr
                                          WHERE mr.demand_source_line_id = ola.line_id),0)) qt_item
  FROM
  OE_ORDER_LINES_ALL        ola
  inner join OE_ORDER_HEADERS_ALL  oha  on  ola.org_id = oha.org_id AND ola.header_id = oha.header_id
  inner join OE_TRANSACTION_TYPES_ALL  tta on tta.transaction_type_id               = oha.order_type_id
  left join (select * from mtl_system_items_b where organization_id = pb_master_organization_id ) msi on ola.inventory_item_id = msi.inventory_item_id
  left join TEMP_DRP_RESSUPRIMENTO f on oha.order_number = f.ordem_venda and msi.segment1 = f.cod_produto
  WHERE  ola.order_quantity_uom  = p_item_um
  AND    ola.inventory_item_id   = p_inventory_item_id
  AND    (oha.SHIP_FROM_ORG_ID    = p_deposito or p_deposito = 0)
  AND    f.ot is null
  AND    ola.booked_flag         = 'Y'
  AND    ola.open_flag           = 'Y'
  AND    ola.cancelled_flag      = 'N'
  and    oha.org_id              = fnd_profile.value('ORG_ID')
  and   oha.order_type_id        in(6728,6732,5813,5830,4524,5163,5633,5132,5138)
  AND   tta.transaction_type_code             = 'ORDER'
  AND   nvl(tta.sales_document_type_code,'O') <> 'B'
  AND   oha.cancelled_flag                    = 'N'
  AND   oha.booked_flag                       = 'Y'
  AND   oha.open_flag                         = 'Y'
  AND   ola.flow_status_code     = 'AWAITING_SHIPPING'
  AND   (omp12001jb.fnd_periodo_dec(ola.schedule_ship_date
                                           ,(SELECT a.origem_item
                                               FROM apps.CONSULTA_PRODUTO_PT_V a
                                              WHERE a.cod_produto = ola.ordered_item  
                                            )
                                           ,'S')   = p_id_periodo or p_id_periodo = 0)
  AND   NOT EXISTS ( SELECT SUM(mr.reservation_quantity)
                       FROM MTL_RESERVATIONS     mr
                           ,OE_ORDER_LINES_ALL   ola2
                      WHERE mr.demand_source_line_id = ola.line_id
                        AND ola2.header_id           = ola.header_id
                        AND ola2.line_id             = ola.line_id
                        AND EXISTS (SELECT 1
                                      FROM MTL_PARAMETERS e
                                     WHERE e.organization_id = ola2.ship_from_org_id
                                       AND e.organization_code IN (SELECT  MEANING 
                                                                     FROM FND_LOOKUP_VALUES
                                                                    WHERE LANGUAGE            = USERENV('LANG')
                                                                      AND enabled_flag        = 'Y'
                                                                      AND security_group_id   = 0
                                                                      AND view_application_id = 660
                                                                      AND lookup_type         = 'PB_PARAM_ATP_POINTER'
                                                                      AND Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
                                                                                             AND Trunc(Nvl(end_date_active, SYSDATE))
                                                                  )
                                   )
                      HAVING SUM(mr.reservation_quantity) > 0
                   )
                   ;

BEGIN

  DBMS_OUTPUT.enable(1000000000000000);
  --
  --dbms_output.put_line('In�cio..');
  --
  fnd_profile.get ('USER_ID', w_id_usuario);
  --
  --Elimina o historico antigo
  BEGIN
    DELETE OM_SALDO_PRODUTO_ATP_HIS_POINTER
    WHERE dt_historico < (SYSDATE - 30);

  EXCEPTION
    WHEN OTHERS THEN
      w_ds_erro:= 'Erro ao excluir a tabela OM_SALDO_PRODUTO_ATP_HIS_POINTER de saldo ATP. Erro:'||SQLERRM;
      RAISE w_erro;
  END;
  --
  --
  --dbms_output.put_line('0..');
  --
  --Grava o historico atual
  BEGIN
    INSERT INTO OM_SALDO_PRODUTO_ATP_HIS_POINTER
    SELECT inventory_item_id,
           item_um,
           id_periodo,
		   id_deposito,
           SYSDATE,
           qt_programada_producao,
           qt_carteira_pedido,
           qt_saldo,
           creation_date,
           created_by,
           last_update_date,
           last_updated_by,
           qt_saldo_neg	
    FROM OM_SALDO_PRODUTO_ATP_POINTER;
    COMMIT;


  EXCEPTION
    WHEN OTHERS THEN
      w_ds_erro:= 'Erro ao gerar hist�rico na tabela OM_SALDO_PRODUTO_ATP_HIS_POINTER. Erro:'||SQLERRM;
      RAISE w_erro;
  END;
  

	begin
		calcula_producao_pointer(v_err, v_code);
	end;
  
  
	select count(1)                       	
	into valida_cd 
	FROM FND_LOOKUP_VALUES
	  WHERE LANGUAGE            = USERENV('LANG')
	  AND enabled_flag        = 'Y'
	  AND security_group_id   = 0
	  AND view_application_id = 660
	  AND lookup_type         = 'PB_PARAM_ATP_POINTER'
	  AND Trunc(SYSDATE) BETWEEN Trunc(Nvl(start_date_active, SYSDATE))
							 AND Trunc(Nvl(end_date_active, SYSDATE))
	  AND NVL(TAG,0) = 0;
					  
	if valida_cd > 1 then 
	  w_ds_erro:= 'Erro Par�metro inv�lidos em PB_PARAM_ATP_POINTER';
      RAISE w_erro;
	end if;
  
    FOR r_produto IN c_produto LOOP
		DELETE OM_SALDO_PRODUTO_ATP_POINTER WHERE INVENTORY_ITEM_ID = r_produto.inventory_item_id; 
		COMMIT;
	
		FOR r_periodo IN 1..omp12001jb.fnd_qtd_periodo_dec LOOP
			
			--  Busca dados de produ��o dentro do periodo
			qtd_producao := 0;
			total_consumido := 0;

			OPEN c_producao (r_produto.inventory_item_id,
							 r_produto.item_um,
							 r_periodo
							 );
			FETCH c_producao
			INTO qtd_producao;
			CLOSE c_producao;
			
					
			OPEN c_carteira_ped(r_produto.inventory_item_id
						 ,r_produto.item_um
						 ,r_periodo
						 ,1982
						 );
			FETCH c_carteira_ped
			INTO qtd_carteira_fab;
			CLOSE c_carteira_ped;		
			
			if r_periodo = 1 then
				qtd_saldo_neg  := 0;
			ELSE
				SELECT nvl(qt_saldo_neg,0) * - 1
				into qtd_saldo_neg  
				from OM_SALDO_PRODUTO_ATP_POINTER
				where inventory_item_id = r_produto.inventory_item_id
				and id_deposito = 1982
				and id_periodo = nvl(r_periodo,0) - 1; 
			end if;			
			qtd_carteira_fab := qtd_carteira_fab + qtd_saldo_neg;
			--qtd_producao := nvl(qtd_producao,0) - nvl(qtd_carteira_fab,0);

			for r_param in c_parametros LOOP
				if nvl(r_param.percente,0) > 0 then
					qtd_saldo := 0;
					qtd_carteira := 0;
					
					if qtd_producao > 0 then 
						qtd_prod_cd := qtd_producao * (r_param.percente / 100);
					ELSE
						qtd_prod_cd := 0;
					end if;
					
					OPEN c_carteira_ped(r_produto.inventory_item_id
								 ,r_produto.item_um
								 ,r_periodo
								 ,r_param.id							 
								 );
					FETCH c_carteira_ped
					INTO qtd_carteira;
					CLOSE c_carteira_ped;		

					if r_periodo = 1 then
						qtd_saldo_neg  := 0;
					ELSE
						SELECT nvl(qt_saldo_neg,0) * - 1
						into qtd_saldo_neg  
						from OM_SALDO_PRODUTO_ATP_POINTER
						where inventory_item_id = r_produto.inventory_item_id
						and id_deposito = r_param.id
						and id_periodo = nvl(r_periodo,0) - 1; 
					end if;
					qtd_carteira := qtd_carteira + qtd_saldo_neg;
					if nvl(qtd_carteira,0) = 0 then 
						qtd_prod_cd := 0;
					end if;
					
					
					if qtd_carteira > 0 then 
						if r_param.atende_carteira = 'S' then
							if qtd_carteira > qtd_prod_cd and (qtd_producao -  nvl(qtd_carteira_fab,0)) > qtd_carteira then 
								qtd_prod_cd := qtd_carteira;
							end if;
						end if;
						
						qtd_saldo := qtd_prod_cd - qtd_carteira;
						
						total_consumido := total_consumido + qtd_prod_cd ;
					end if;
					
					if qtd_saldo <= 0 then 
						qtd_saldo_neg := qtd_saldo * -1;
						qtd_saldo := 0;
					else 	
						qtd_saldo_neg := 0;
					end if;

					INSERT INTO OM_SALDO_PRODUTO_ATP_POINTER
					(inventory_item_id, item_um, id_periodo, id_deposito, qt_programada_producao, qt_carteira_pedido, qt_saldo, creation_date, created_by, last_update_date, last_updated_by, qt_saldo_neg ) 
					values 
					(r_produto.inventory_item_id, r_produto.item_um, r_periodo, r_param.id, nvl(qtd_producao,0), nvl(qtd_carteira,0), nvl(qtd_saldo,0), SYSDATE, nvl(w_id_usuario,0), SYSDATE, nvl(w_id_usuario,0), nvl(qtd_saldo_neg,0));
					COMMIT;
				else
					if qtd_producao > 0 then 
						qtd_prod_cd := qtd_producao - total_consumido;
					ELSE
						qtd_prod_cd := 0;
					end if;
					
					qtd_saldo := qtd_prod_cd - qtd_carteira_fab;
					
					if qtd_saldo <= 0 then 
						qtd_saldo_neg := qtd_saldo * -1;
						qtd_saldo := 0;
					else
						qtd_saldo_neg := 0;
					end if;
					
					INSERT INTO OM_SALDO_PRODUTO_ATP_POINTER
					(inventory_item_id, item_um, id_periodo, id_deposito, qt_programada_producao, qt_carteira_pedido, qt_saldo, creation_date, created_by, last_update_date, last_updated_by, qt_saldo_neg) 
					values 
					(r_produto.inventory_item_id, r_produto.item_um, r_periodo, r_param.id, nvl(qtd_producao,0), nvl(qtd_carteira,0), nvl(qtd_saldo,0), SYSDATE, nvl(w_id_usuario,0), SYSDATE, nvl(w_id_usuario,0), nvl(qtd_saldo_neg,0) );					
					COMMIT;
				end if; 
			END LOOP;
		
        END LOOP;
    END LOOP;
EXCEPTION
  WHEN w_erro THEN
    dbms_output.put_line('Erro: '||w_ds_erro);
    ROLLBACK;
    --
    w_ds_email := 'Em '||to_char(SYSDATE,'dd/mm/rrrr hh24:mi')||
                   ' ocorreu o erro na carga do saldo APT.'||CHR(10)||
                   'Rotina: omp12001jb.PRC_CARGA_SALDO'||CHR(10)||
                   w_ds_erro;
   --
    --
  WHEN OTHERS THEN
    --dbms_output.put_line('Erro na carga do saldo atp. Erro:'||SQLERRM);
    ROLLBACK;

    w_ds_email := 'Em '||to_char(SYSDATE,'dd/mm/rrrr hh24:mi')||
                   ' ocorreu o erro na carga do saldo APT.'||CHR(10)||
                   'Rotina: omp12001jb.PRC_CARGA_SALDO'||CHR(10)||
                   w_ds_erro;
   --
   --dbms_output.put_line(w_ds_email);

--
END prc_carga_saldo_pointer;




  FUNCTION send_email (p_dados_erro IN VARCHAR2) RETURN VARCHAR2 IS
  --
  v_error_message  VARCHAR2(32000)  := NULL;
  v_ambiente       VARCHAR2(10)     := NULL;
  v_descricao      VARCHAR2(150)    := NULL;
  --
  BEGIN
    --
    BEGIN
      SELECT instance_name                                          instance_name
          , Decode(instance_name
                    , 'DEV', 'Ambiente de desenvolvimento - DEV'
                    , 'QAS', 'Ambiente de desenvolvimento - QAS'
                    , 'TST', 'Ambiente de desenvolvimento - TST'
                    , 'PRD', 'Ambiente de Produ��o')                instance_descricao
        INTO v_ambiente, v_descricao
      FROM V$INSTANCE;
    EXCEPTION
      WHEN OTHERS THEN
      v_ambiente:= 'INDEFINIDO';
    END;
    --
    v_error_message := f2c_send_javamail.sendmail( 'mail.portobello.com.br'                               -- SMTPServerName
                                                , 'oreply@portobello.com.br'                             -- Sender
                                                , 'guilherme.rodrigues@portobello.com.br'                               -- Recipient
                                                , ''                                         -- CcRecipient
                                                , ''                                                     -- BccRecipient
                                                , v_ambiente || ' - ERRO na Gera��o de Dados - OMP12001JB'  -- Subject
                                                , ' - ERRO na Gera��o de dados de Saldo Projetado' || Chr(10)
                                                    || v_descricao || Chr(10) || Chr(10)
                                                    || 'Dados do erro:' || Chr(10)
                                                    || p_dados_erro || Chr(10)
                                                , v_error_message                                        -- ErrorMessage
                                                , null                                                   -- Attachments
                                                );
    --
    fnd_file.put_line(fnd_file.log, '  Retorno Send Mail: ' || v_error_message);
    dbms_output.put_line('  Retorno Send Mail: ' || v_error_message);
    --
    IF (v_error_message <> NULL AND v_error_message <> '0') THEN
      RETURN 'NO_DATA_FOUND';
    ELSE
      RETURN 'OK';
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'ERROR';
  END;


--
END omp12001jb;
/

GRANT EXECUTE ON APPS.OMP12001JB TO APPSR;

GRANT EXECUTE ON APPS.OMP12001JB TO ONT WITH GRANT OPTION;
