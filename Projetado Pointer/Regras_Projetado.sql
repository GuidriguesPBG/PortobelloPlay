Fluxo de composição do Saldo Projetado:
	- Looping considerando produtos que tenham Produção\Compras futuras
	- Looping para calculo de periodos (10 periodos decendio)
		- Soma a quantidade de produção do periodo
		- Soma a carteira da Fábrica (EEA)
		- Subtrai de produção a quantidade carteira EEA
		- Looping de calculo por CD
			- Se CD não Fábrica:
				- Se saldo de produção > 0 então
					- Calcula-se o percentual maximo do CD
				- Se não disponivel Prod CD fica com valor zero
				- Soma a carteira do CD
				- Se projetado subtrai quantidade em carteira então 
					- Saldo = Percentual Maximo - Carteira 
				- Se não 
					- Saldo = Percentual Maximo
			
