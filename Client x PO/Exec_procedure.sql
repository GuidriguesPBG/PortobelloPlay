BEGIN
    DECLARE 
    erroo varchar2(200);
    cod varchar2(200);
    begin
        apps.PB_INTEGRA_SALESFORCE.p_gera_dados_cli_po(erroo,cod, 1);
    end;
END;