execute dbms_stats.gather_table_stats(ownname => 'XXPB', tabname => 'OM_SALDO_PRODUTO_ATP_POINTER', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE AUTO');
execute dbms_stats.gather_table_stats(ownname => 'XXPB', tabname => 'XXPB_ESTOQUE_API_ZERO', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE AUTO');
execute dbms_stats.gather_table_stats(ownname => 'XXPB', tabname => 'XXPB_ESTOQUE_API', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE AUTO');

