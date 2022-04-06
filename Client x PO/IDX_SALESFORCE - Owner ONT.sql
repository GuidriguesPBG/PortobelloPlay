create index ONT.IDX_SALESFORCE_OHA_01 on ONT.OE_ORDER_HEADERS_ALL("CANCELLED_FLAG","SALES_CHANNEL_CODE","ORDER_CATEGORY_CODE","SHIP_TO_ORG_ID");
create index ONT.IDX_SALESFORCE_OHA_02 on ONT.OE_ORDER_HEADERS_ALL("SALES_CHANNEL_CODE","CANCELLED_FLAG","BOOKED_FLAG","ORDER_CATEGORY_CODE","ORDERED_DATE","SHIP_TO_ORG_ID");