PB_INTEGRA_SALESFORCE.p_gera_dados_cli_po(msg, cod, completa);
Concorrente
1 x por semana full e a cada 5 min não full 

PB_INTEGRA_SALESFORCE.p_gera_dados_estoque_zero(msg, cod, completa);
Concorrente
1 x por dia full e a cada 5 min não full 

PB_INTEGRA_SALESFORCE.p_gera_dados_estoque_prj(msg, cod);
*Incluir chamada no processo de saldo projetado


Carga Geral:
	LAST_UPDATE_DATE := SYSDATE
	1 - XXPB_ESTOQUE_API_ZERO recebe a carga de estoque atual de XXPB_ESTOQUE_API (guardará o campo chave do Sales (DEPOSITO + TONALIDADE + PRODUTO)) - FLAG_STK = 1 
	2 - XXPB_ESTOQUE_API_ZERO recebe a carga da chave  DEPOSITO + TONALIDADE + PRODUTO | FLAG_STK = 0
		* Será adotado o SKU '000000'
		* Se não houver registro correspondente para a chave DEPOSITO + PRODUTO em XXPB_ESTOQUE_API
	
	
Carga Parcial (Last Update)	
	1 - XXPB_ESTOQUE_API_ZERO recebe atualização no campo LAST_UPDATE_DATE quando:
		a) chave do sales "not exists" na tabela XXPB_ESTOQUE_API e FLAG_STK = 1 e FLAG_EXC = 0| Atualiza o campo FLAG_EXC = 1 
		b) Não houver registro correspondente em XXPB_ESTOQUE_API para a chave DEPOSITO + PRODUTO e FLAG_STK = 0 e houver corresponde a chave em registro com FLAG_STK = 1 e FLAG_EXC = 1 
	
	2 - XXPB_ESTOQUE_API_ZERO recebe a carga de estoque atual de XXPB_ESTOQUE_API (guardará o campo chave do Sales (DEPOSITO + TONALIDADE + PRODUTO)) - FLAG_STK = 1 
	
	3 - XXPB_ESTOQUE_API_ZERO recebe a carga da chave  DEPOSITO + TONALIDADE + PRODUTO | FLAG_STK = 0
		* Será adotado o SKU '000000'
		* Se não houver registro correspondente para a chave DEPOSITO + PRODUTO em XXPB_ESTOQUE_API

	
API
Carga Geral:
	Não é enviado dados 
	Recebe todos dados da tabela XXPB_ESTOQUE_API (Exceto Registros FLAG_EXC = 1) + Dados da tabela XXPB_ESTOQUE_API_ZERO (Quando a chave Produto x Deposito não existir E FLAG_STK = 0)
	* deverá ser feita exclusão dos dados do Salesforce antes de realizar a carga
	
Carga Parcial (Last Update)
	Envia a data desejada e será utilizada em filtro das tabelas conforme abaixo
		a) Recebe todos dados da tabela XXPB_ESTOQUE_API 
		b) Recebe dados da tabela XXPB_ESTOQUE_API_ZERO (Quando a chave Produto x Deposito não existir em XXPB_ESTOQUE_API e FLAG_STK = 0) 
		c) Recebe dados da tabela XXPB_ESTOQUE_API_ZERO e FLAG_STK = 1 e FLAG_EXC = 1 
	
Middleware
	Se registro tiver a tag Excluir = 1 o registro/chave deverá ser excluido do Salesforce



-- EXECUÇÕES
BEGIN
DECLARE
    RET VARCHAR2(100);
    COD VARCHAR2(100);
    BEGIN
    PB_INTEGRA_SALESFORCE.P_GERA_DADOS_ESTOQUE_ZERO(RET,COD,1);
    END;
END;

BEGIN
DECLARE
    RET VARCHAR2(100);
    COD VARCHAR2(100);
    BEGIN
    PB_INTEGRA_SALESFORCE.P_GERA_DADOS_ESTOQUE_ZERO(RET,COD,1);
    END;
END;



SELECT MEANING FROM FND_LOOKUP_VALUES     WHERE language            = userenv('LANG')    AND   enabled_flag        = 'Y'    AND    lookup_type         = 'ONT_DEPOSITOS_SALES_PB'
	
	