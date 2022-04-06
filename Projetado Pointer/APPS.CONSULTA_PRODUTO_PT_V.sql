CREATE MATERIALIZED VIEW APPS.CONSULTA_PRODUTO_PT_V (ITEM_ID,COD_PRODUTO,PRODUTO,UNIDADE,MARCA_ITEM,ORIGEM_ITEM,FORNECEDORORIGEM,FORNECEDOR)
TABLESPACE APPS_TS_TX_DATA
PCTUSED    0
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
NOCACHE
LOGGING
NOCOMPRESS
NOPARALLEL
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
WITH PRIMARY KEY
 USING TRUSTED CONSTRAINTS
AS 
/* Formatted on 18/03/2022 10:56:30 (QP5 v5.215.12089.38647) */
SELECT "A2"."INVENTORY_ITEM_ID" "ITEM_ID",
       "A2"."SEGMENT1" "COD_PRODUTO",
       SUBSTR (NLS_UPPER ("A2"."DESCRIPTION"), 1, 80) "PRODUTO",
       SUBSTR (NLS_UPPER ("A2"."PRIMARY_UOM_CODE"), 1, 2) "UNIDADE",
          ''
       || (SELECT "A18"."DESCRIPTION" "DESCRIPTION"
             FROM (SELECT "A85"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                          "A85"."CONTROL_LEVEL" "CONTROL_LEVEL",
                          "A85"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                          "A85"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                          "A85"."CREATION_DATE" "CREATION_DATE",
                          "A85"."CREATED_BY" "CREATED_BY",
                          "A85"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
                          "A85"."REQUEST_ID" "REQUEST_ID",
                          "A85"."PROGRAM_APPLICATION_ID"
                             "PROGRAM_APPLICATION_ID",
                          "A85"."PROGRAM_ID" "PROGRAM_ID",
                          "A85"."PROGRAM_UPDATE_DATE" "PROGRAM_UPDATE_DATE",
                          "A86"."CATEGORY_SET_NAME" "CATEGORY_SET_NAME",
                          "A86"."DESCRIPTION" "DESCRIPTION"
                     FROM "INV"."MTL_CATEGORY_SETS_TL" "A86",
                          "INV"."MTL_CATEGORY_SETS_B" "A85"
                    WHERE     "A85"."CATEGORY_SET_ID" =
                                 "A86"."CATEGORY_SET_ID"
                          AND "A86"."LANGUAGE" = USERENV ('LANG')) "A20",
                  (SELECT "A91"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
                          "A91"."ORGANIZATION_ID" "ORGANIZATION_ID",
                          "A91"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                          "A91"."CATEGORY_ID" "CATEGORY_ID",
                          "A91"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                          "A91"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                          "A91"."CREATION_DATE" "CREATION_DATE",
                          "A91"."CREATED_BY" "CREATED_BY",
                          "A91"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
                          "A91"."REQUEST_ID" "REQUEST_ID",
                          "A91"."PROGRAM_APPLICATION_ID"
                             "PROGRAM_APPLICATION_ID",
                          "A91"."PROGRAM_ID" "PROGRAM_ID",
                          "A91"."PROGRAM_UPDATE_DATE" "PROGRAM_UPDATE_DATE",
                          "A87"."SEGMENT1" "SEGMENT1",
                          "A87"."SEGMENT2" "SEGMENT2",
                          "A87"."SEGMENT3" "SEGMENT3",
                          "A87"."SEGMENT4" "SEGMENT4",
                          "A87"."SEGMENT5" "SEGMENT5",
                          "A87"."SEGMENT6" "SEGMENT6",
                          "A87"."SEGMENT7" "SEGMENT7",
                          "A87"."SEGMENT8" "SEGMENT8",
                          "A87"."SEGMENT9" "SEGMENT9",
                          "A87"."SEGMENT10" "SEGMENT10",
                          "A87"."SEGMENT11" "SEGMENT11",
                          "A87"."SEGMENT12" "SEGMENT12",
                          "A87"."SEGMENT13" "SEGMENT13",
                          "A87"."SEGMENT14" "SEGMENT14",
                          "A87"."SEGMENT15" "SEGMENT15",
                          "A87"."SEGMENT16" "SEGMENT16",
                          "A87"."SEGMENT17" "SEGMENT17",
                          "A87"."SEGMENT18" "SEGMENT18",
                          "A87"."SEGMENT19" "SEGMENT19",
                          "A87"."SEGMENT20" "SEGMENT20",
                          "A87"."SUMMARY_FLAG" "SUMMARY_FLAG",
                          "A87"."ENABLED_FLAG" "ENABLED_FLAG"
                     FROM "INV"."MTL_ITEM_CATEGORIES" "A91",
                          "INV"."MTL_CATEGORY_SETS_TL" "A90",
                          "INV"."MTL_CATEGORY_SETS_B" "A89",
                          (SELECT "A92"."LOOKUP_TYPE" "LOOKUP_TYPE",
                                  TO_NUMBER ("A92"."LOOKUP_CODE")
                                     "LOOKUP_CODE",
                                  "A92"."MEANING" "MEANING",
                                  "A92"."DESCRIPTION" "DESCRIPTION",
                                  "A92"."ENABLED_FLAG" "ENABLED_FLAG",
                                  "A92"."START_DATE_ACTIVE"
                                     "START_DATE_ACTIVE",
                                  "A92"."END_DATE_ACTIVE" "END_DATE_ACTIVE",
                                  "A92"."CREATED_BY" "CREATED_BY",
                                  "A92"."CREATION_DATE" "CREATION_DATE",
                                  "A92"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                                  "A92"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                                  "A92"."LAST_UPDATE_LOGIN"
                                     "LAST_UPDATE_LOGIN"
                             FROM "APPLSYS"."FND_LOOKUP_VALUES" "A92"
                            WHERE     "A92"."LANGUAGE" = USERENV ('LANG')
                                  AND "A92"."VIEW_APPLICATION_ID" = 700
                                  AND "A92"."SECURITY_GROUP_ID" = 0) "A88",
                          (SELECT "A93"."CATEGORY_ID" "CATEGORY_ID",
                                  "A93"."SEGMENT2" "SEGMENT2",
                                  "A93"."SEGMENT19" "SEGMENT19",
                                  "A93"."REQUEST_ID" "REQUEST_ID",
                                  "A93"."ATTRIBUTE1" "ATTRIBUTE1",
                                  "A93"."ATTRIBUTE6" "ATTRIBUTE6",
                                  "A93"."LAST_UPDATE_LOGIN"
                                     "LAST_UPDATE_LOGIN",
                                  "A93"."ATTRIBUTE15" "ATTRIBUTE15",
                                  "A93"."SEGMENT1" "SEGMENT1",
                                  "A93"."ATTRIBUTE13" "ATTRIBUTE13",
                                  "A93"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                                  "A93"."SEGMENT7" "SEGMENT7",
                                  "A93"."SEGMENT8" "SEGMENT8",
                                  "A93"."SEGMENT20" "SEGMENT20",
                                  "A93"."ATTRIBUTE5" "ATTRIBUTE5",
                                  "A93"."ATTRIBUTE7" "ATTRIBUTE7",
                                  "A93"."PROGRAM_APPLICATION_ID"
                                     "PROGRAM_APPLICATION_ID",
                                  "A93"."PROGRAM_UPDATE_DATE"
                                     "PROGRAM_UPDATE_DATE",
                                  "A93"."SEGMENT13" "SEGMENT13",
                                  "A93"."SEGMENT5" "SEGMENT5",
                                  "A93"."SEGMENT11" "SEGMENT11",
                                  "A93"."ATTRIBUTE3" "ATTRIBUTE3",
                                  "A93"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                                  "A93"."CREATED_BY" "CREATED_BY",
                                  "A93"."SEGMENT12" "SEGMENT12",
                                  "A93"."ATTRIBUTE4" "ATTRIBUTE4",
                                  "A93"."ATTRIBUTE8" "ATTRIBUTE8",
                                  "A93"."ATTRIBUTE9" "ATTRIBUTE9",
                                  "A93"."SEGMENT9" "SEGMENT9",
                                  "A93"."SUMMARY_FLAG" "SUMMARY_FLAG",
                                  "A93"."ATTRIBUTE11" "ATTRIBUTE11",
                                  "A93"."WEB_STATUS" "WEB_STATUS",
                                  "A93"."DESCRIPTION" "DESCRIPTION",
                                  "A93"."SEGMENT15" "SEGMENT15",
                                  "A93"."ATTRIBUTE10" "ATTRIBUTE10",
                                  "A93"."ATTRIBUTE14" "ATTRIBUTE14",
                                  "A93"."SEGMENT6" "SEGMENT6",
                                  "A93"."END_DATE_ACTIVE" "END_DATE_ACTIVE",
                                  "A93"."ATTRIBUTE2" "ATTRIBUTE2",
                                  "A93"."ENABLED_FLAG" "ENABLED_FLAG",
                                  "A93"."ATTRIBUTE12" "ATTRIBUTE12",
                                  "A93"."SEGMENT4" "SEGMENT4",
                                  "A93"."SEGMENT10" "SEGMENT10",
                                  "A93"."SEGMENT14" "SEGMENT14",
                                  "A93"."SEGMENT16" "SEGMENT16",
                                  "A93"."SEGMENT3" "SEGMENT3",
                                  "A93"."SEGMENT17" "SEGMENT17",
                                  "A93"."ATTRIBUTE_CATEGORY"
                                     "ATTRIBUTE_CATEGORY",
                                  "A93"."CREATION_DATE" "CREATION_DATE",
                                  "A93"."PROGRAM_ID" "PROGRAM_ID",
                                  "A93"."SEGMENT18" "SEGMENT18",
                                  "A93"."START_DATE_ACTIVE"
                                     "START_DATE_ACTIVE"
                             FROM "INV"."MTL_CATEGORIES_B" "A93") "A87"
                    WHERE     "A91"."CATEGORY_SET_ID" =
                                 "A89"."CATEGORY_SET_ID"
                          AND "A89"."CATEGORY_SET_ID" =
                                 "A90"."CATEGORY_SET_ID"
                          AND "A90"."LANGUAGE" = USERENV ('LANG')
                          AND "A91"."CATEGORY_ID" = "A87"."CATEGORY_ID"
                          AND "A89"."CONTROL_LEVEL" = "A88"."LOOKUP_CODE"
                          AND "A88"."LOOKUP_TYPE" = 'ITEM_CONTROL_LEVEL_GUI') "A19",
                  (SELECT "A94"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                          "A94"."FLEX_VALUE" "FLEX_VALUE",
                          "A94"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                          "A94"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                          "A94"."CREATION_DATE" "CREATION_DATE",
                          "A94"."CREATED_BY" "CREATED_BY",
                          "A94"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
                          "A94"."ENABLED_FLAG" "ENABLED_FLAG",
                          "A94"."SUMMARY_FLAG" "SUMMARY_FLAG",
                          "A94"."START_DATE_ACTIVE" "START_DATE_ACTIVE",
                          "A94"."END_DATE_ACTIVE" "END_DATE_ACTIVE",
                          "A94"."ATTRIBUTE1" "ATTRIBUTE1",
                          "A94"."ATTRIBUTE2" "ATTRIBUTE2",
                          "A94"."ATTRIBUTE3" "ATTRIBUTE3",
                          "A94"."ATTRIBUTE4" "ATTRIBUTE4",
                          "A94"."ATTRIBUTE5" "ATTRIBUTE5",
                          "A94"."ATTRIBUTE6" "ATTRIBUTE6",
                          "A94"."ATTRIBUTE7" "ATTRIBUTE7",
                          "A94"."ATTRIBUTE8" "ATTRIBUTE8",
                          "A94"."ATTRIBUTE9" "ATTRIBUTE9",
                          "A94"."ATTRIBUTE10" "ATTRIBUTE10",
                          "A94"."ATTRIBUTE11" "ATTRIBUTE11",
                          "A94"."ATTRIBUTE12" "ATTRIBUTE12",
                          "A94"."ATTRIBUTE13" "ATTRIBUTE13",
                          "A94"."ATTRIBUTE14" "ATTRIBUTE14",
                          "A94"."ATTRIBUTE15" "ATTRIBUTE15",
                          "A94"."ATTRIBUTE16" "ATTRIBUTE16",
                          "A94"."ATTRIBUTE17" "ATTRIBUTE17",
                          "A94"."ATTRIBUTE18" "ATTRIBUTE18",
                          "A94"."ATTRIBUTE19" "ATTRIBUTE19",
                          "A94"."ATTRIBUTE20" "ATTRIBUTE20",
                          "A94"."ATTRIBUTE21" "ATTRIBUTE21",
                          "A94"."ATTRIBUTE22" "ATTRIBUTE22",
                          "A94"."ATTRIBUTE23" "ATTRIBUTE23",
                          "A94"."ATTRIBUTE24" "ATTRIBUTE24",
                          "A94"."ATTRIBUTE25" "ATTRIBUTE25",
                          "A94"."ATTRIBUTE26" "ATTRIBUTE26",
                          "A94"."ATTRIBUTE27" "ATTRIBUTE27",
                          "A94"."ATTRIBUTE28" "ATTRIBUTE28",
                          "A94"."ATTRIBUTE29" "ATTRIBUTE29",
                          "A94"."ATTRIBUTE30" "ATTRIBUTE30",
                          "A95"."DESCRIPTION" "DESCRIPTION"
                     FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A95",
                          "APPLSYS"."FND_FLEX_VALUES" "A94"
                    WHERE     "A94"."FLEX_VALUE_ID" = "A95"."FLEX_VALUE_ID"
                          AND "A95"."LANGUAGE" = USERENV ('LANG')) "A18"
            WHERE     "A20"."CATEGORY_SET_NAME" = 'Marca do Item'
                  AND "A19"."CATEGORY_SET_ID" = "A20"."CATEGORY_SET_ID"
                  AND "A18"."FLEX_VALUE" = "A19"."SEGMENT1"
                  AND "A19"."INVENTORY_ITEM_ID" = "A2"."INVENTORY_ITEM_ID"
                  AND "A19"."ORGANIZATION_ID" = "A2"."ORGANIZATION_ID"
                  AND "A18"."FLEX_VALUE_SET_ID" =
                         (SELECT "A36"."FLEX_VALUE_SET_ID"
                                    "FLEX_VALUE_SET_ID"
                            FROM "APPLSYS"."FND_FLEX_VALUE_SETS" "A36"
                           WHERE "A36"."FLEX_VALUE_SET_NAME" = 'GL_PB_MARCA'))
          "MARCA_ITEM",
          ''
       || (SELECT "A15"."DESCRIPTION" "DESCRIPTION"
             FROM (SELECT "A74"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                          "A74"."CONTROL_LEVEL" "CONTROL_LEVEL",
                          "A74"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                          "A74"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                          "A74"."CREATION_DATE" "CREATION_DATE",
                          "A74"."CREATED_BY" "CREATED_BY",
                          "A74"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
                          "A74"."REQUEST_ID" "REQUEST_ID",
                          "A74"."PROGRAM_APPLICATION_ID"
                             "PROGRAM_APPLICATION_ID",
                          "A74"."PROGRAM_ID" "PROGRAM_ID",
                          "A74"."PROGRAM_UPDATE_DATE" "PROGRAM_UPDATE_DATE",
                          "A75"."CATEGORY_SET_NAME" "CATEGORY_SET_NAME",
                          "A75"."DESCRIPTION" "DESCRIPTION"
                     FROM "INV"."MTL_CATEGORY_SETS_TL" "A75",
                          "INV"."MTL_CATEGORY_SETS_B" "A74"
                    WHERE     "A74"."CATEGORY_SET_ID" =
                                 "A75"."CATEGORY_SET_ID"
                          AND "A75"."LANGUAGE" = USERENV ('LANG')) "A17",
                  (SELECT "A80"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
                          "A80"."ORGANIZATION_ID" "ORGANIZATION_ID",
                          "A80"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                          "A80"."CATEGORY_ID" "CATEGORY_ID",
                          "A80"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                          "A80"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                          "A80"."CREATION_DATE" "CREATION_DATE",
                          "A80"."CREATED_BY" "CREATED_BY",
                          "A80"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
                          "A80"."REQUEST_ID" "REQUEST_ID",
                          "A80"."PROGRAM_APPLICATION_ID"
                             "PROGRAM_APPLICATION_ID",
                          "A80"."PROGRAM_ID" "PROGRAM_ID",
                          "A80"."PROGRAM_UPDATE_DATE" "PROGRAM_UPDATE_DATE",
                          "A76"."SEGMENT1" "SEGMENT1",
                          "A76"."SEGMENT2" "SEGMENT2",
                          "A76"."SEGMENT3" "SEGMENT3",
                          "A76"."SEGMENT4" "SEGMENT4",
                          "A76"."SEGMENT5" "SEGMENT5",
                          "A76"."SEGMENT6" "SEGMENT6",
                          "A76"."SEGMENT7" "SEGMENT7",
                          "A76"."SEGMENT8" "SEGMENT8",
                          "A76"."SEGMENT9" "SEGMENT9",
                          "A76"."SEGMENT10" "SEGMENT10",
                          "A76"."SEGMENT11" "SEGMENT11",
                          "A76"."SEGMENT12" "SEGMENT12",
                          "A76"."SEGMENT13" "SEGMENT13",
                          "A76"."SEGMENT14" "SEGMENT14",
                          "A76"."SEGMENT15" "SEGMENT15",
                          "A76"."SEGMENT16" "SEGMENT16",
                          "A76"."SEGMENT17" "SEGMENT17",
                          "A76"."SEGMENT18" "SEGMENT18",
                          "A76"."SEGMENT19" "SEGMENT19",
                          "A76"."SEGMENT20" "SEGMENT20",
                          "A76"."SUMMARY_FLAG" "SUMMARY_FLAG",
                          "A76"."ENABLED_FLAG" "ENABLED_FLAG"
                     FROM "INV"."MTL_ITEM_CATEGORIES" "A80",
                          "INV"."MTL_CATEGORY_SETS_TL" "A79",
                          "INV"."MTL_CATEGORY_SETS_B" "A78",
                          (SELECT "A81"."LOOKUP_TYPE" "LOOKUP_TYPE",
                                  TO_NUMBER ("A81"."LOOKUP_CODE")
                                     "LOOKUP_CODE",
                                  "A81"."MEANING" "MEANING",
                                  "A81"."DESCRIPTION" "DESCRIPTION",
                                  "A81"."ENABLED_FLAG" "ENABLED_FLAG",
                                  "A81"."START_DATE_ACTIVE"
                                     "START_DATE_ACTIVE",
                                  "A81"."END_DATE_ACTIVE" "END_DATE_ACTIVE",
                                  "A81"."CREATED_BY" "CREATED_BY",
                                  "A81"."CREATION_DATE" "CREATION_DATE",
                                  "A81"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                                  "A81"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                                  "A81"."LAST_UPDATE_LOGIN"
                                     "LAST_UPDATE_LOGIN"
                             FROM "APPLSYS"."FND_LOOKUP_VALUES" "A81"
                            WHERE     "A81"."LANGUAGE" = USERENV ('LANG')
                                  AND "A81"."VIEW_APPLICATION_ID" = 700
                                  AND "A81"."SECURITY_GROUP_ID" = 0) "A77",
                          (SELECT "A82"."CATEGORY_ID" "CATEGORY_ID",
                                  "A82"."SEGMENT2" "SEGMENT2",
                                  "A82"."SEGMENT19" "SEGMENT19",
                                  "A82"."REQUEST_ID" "REQUEST_ID",
                                  "A82"."ATTRIBUTE1" "ATTRIBUTE1",
                                  "A82"."ATTRIBUTE6" "ATTRIBUTE6",
                                  "A82"."LAST_UPDATE_LOGIN"
                                     "LAST_UPDATE_LOGIN",
                                  "A82"."ATTRIBUTE15" "ATTRIBUTE15",
                                  "A82"."SEGMENT1" "SEGMENT1",
                                  "A82"."ATTRIBUTE13" "ATTRIBUTE13",
                                  "A82"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                                  "A82"."SEGMENT7" "SEGMENT7",
                                  "A82"."SEGMENT8" "SEGMENT8",
                                  "A82"."SEGMENT20" "SEGMENT20",
                                  "A82"."ATTRIBUTE5" "ATTRIBUTE5",
                                  "A82"."ATTRIBUTE7" "ATTRIBUTE7",
                                  "A82"."PROGRAM_APPLICATION_ID"
                                     "PROGRAM_APPLICATION_ID",
                                  "A82"."PROGRAM_UPDATE_DATE"
                                     "PROGRAM_UPDATE_DATE",
                                  "A82"."SEGMENT13" "SEGMENT13",
                                  "A82"."SEGMENT5" "SEGMENT5",
                                  "A82"."SEGMENT11" "SEGMENT11",
                                  "A82"."ATTRIBUTE3" "ATTRIBUTE3",
                                  "A82"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                                  "A82"."CREATED_BY" "CREATED_BY",
                                  "A82"."SEGMENT12" "SEGMENT12",
                                  "A82"."ATTRIBUTE4" "ATTRIBUTE4",
                                  "A82"."ATTRIBUTE8" "ATTRIBUTE8",
                                  "A82"."ATTRIBUTE9" "ATTRIBUTE9",
                                  "A82"."SEGMENT9" "SEGMENT9",
                                  "A82"."SUMMARY_FLAG" "SUMMARY_FLAG",
                                  "A82"."ATTRIBUTE11" "ATTRIBUTE11",
                                  "A82"."WEB_STATUS" "WEB_STATUS",
                                  "A82"."DESCRIPTION" "DESCRIPTION",
                                  "A82"."SEGMENT15" "SEGMENT15",
                                  "A82"."ATTRIBUTE10" "ATTRIBUTE10",
                                  "A82"."ATTRIBUTE14" "ATTRIBUTE14",
                                  "A82"."SEGMENT6" "SEGMENT6",
                                  "A82"."END_DATE_ACTIVE" "END_DATE_ACTIVE",
                                  "A82"."ATTRIBUTE2" "ATTRIBUTE2",
                                  "A82"."ENABLED_FLAG" "ENABLED_FLAG",
                                  "A82"."ATTRIBUTE12" "ATTRIBUTE12",
                                  "A82"."SEGMENT4" "SEGMENT4",
                                  "A82"."SEGMENT10" "SEGMENT10",
                                  "A82"."SEGMENT14" "SEGMENT14",
                                  "A82"."SEGMENT16" "SEGMENT16",
                                  "A82"."SEGMENT3" "SEGMENT3",
                                  "A82"."SEGMENT17" "SEGMENT17",
                                  "A82"."ATTRIBUTE_CATEGORY"
                                     "ATTRIBUTE_CATEGORY",
                                  "A82"."CREATION_DATE" "CREATION_DATE",
                                  "A82"."PROGRAM_ID" "PROGRAM_ID",
                                  "A82"."SEGMENT18" "SEGMENT18",
                                  "A82"."START_DATE_ACTIVE"
                                     "START_DATE_ACTIVE"
                             FROM "INV"."MTL_CATEGORIES_B" "A82") "A76"
                    WHERE     "A80"."CATEGORY_SET_ID" =
                                 "A78"."CATEGORY_SET_ID"
                          AND "A78"."CATEGORY_SET_ID" =
                                 "A79"."CATEGORY_SET_ID"
                          AND "A79"."LANGUAGE" = USERENV ('LANG')
                          AND "A80"."CATEGORY_ID" = "A76"."CATEGORY_ID"
                          AND "A78"."CONTROL_LEVEL" = "A77"."LOOKUP_CODE"
                          AND "A77"."LOOKUP_TYPE" = 'ITEM_CONTROL_LEVEL_GUI') "A16",
                  (SELECT "A83"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                          "A83"."FLEX_VALUE" "FLEX_VALUE",
                          "A83"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                          "A83"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                          "A83"."CREATION_DATE" "CREATION_DATE",
                          "A83"."CREATED_BY" "CREATED_BY",
                          "A83"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
                          "A83"."ENABLED_FLAG" "ENABLED_FLAG",
                          "A83"."SUMMARY_FLAG" "SUMMARY_FLAG",
                          "A83"."START_DATE_ACTIVE" "START_DATE_ACTIVE",
                          "A83"."END_DATE_ACTIVE" "END_DATE_ACTIVE",
                          "A83"."ATTRIBUTE1" "ATTRIBUTE1",
                          "A83"."ATTRIBUTE2" "ATTRIBUTE2",
                          "A83"."ATTRIBUTE3" "ATTRIBUTE3",
                          "A83"."ATTRIBUTE4" "ATTRIBUTE4",
                          "A83"."ATTRIBUTE5" "ATTRIBUTE5",
                          "A83"."ATTRIBUTE6" "ATTRIBUTE6",
                          "A83"."ATTRIBUTE7" "ATTRIBUTE7",
                          "A83"."ATTRIBUTE8" "ATTRIBUTE8",
                          "A83"."ATTRIBUTE9" "ATTRIBUTE9",
                          "A83"."ATTRIBUTE10" "ATTRIBUTE10",
                          "A83"."ATTRIBUTE11" "ATTRIBUTE11",
                          "A83"."ATTRIBUTE12" "ATTRIBUTE12",
                          "A83"."ATTRIBUTE13" "ATTRIBUTE13",
                          "A83"."ATTRIBUTE14" "ATTRIBUTE14",
                          "A83"."ATTRIBUTE15" "ATTRIBUTE15",
                          "A83"."ATTRIBUTE16" "ATTRIBUTE16",
                          "A83"."ATTRIBUTE17" "ATTRIBUTE17",
                          "A83"."ATTRIBUTE18" "ATTRIBUTE18",
                          "A83"."ATTRIBUTE19" "ATTRIBUTE19",
                          "A83"."ATTRIBUTE20" "ATTRIBUTE20",
                          "A83"."ATTRIBUTE21" "ATTRIBUTE21",
                          "A83"."ATTRIBUTE22" "ATTRIBUTE22",
                          "A83"."ATTRIBUTE23" "ATTRIBUTE23",
                          "A83"."ATTRIBUTE24" "ATTRIBUTE24",
                          "A83"."ATTRIBUTE25" "ATTRIBUTE25",
                          "A83"."ATTRIBUTE26" "ATTRIBUTE26",
                          "A83"."ATTRIBUTE27" "ATTRIBUTE27",
                          "A83"."ATTRIBUTE28" "ATTRIBUTE28",
                          "A83"."ATTRIBUTE29" "ATTRIBUTE29",
                          "A83"."ATTRIBUTE30" "ATTRIBUTE30",
                          "A84"."DESCRIPTION" "DESCRIPTION"
                     FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A84",
                          "APPLSYS"."FND_FLEX_VALUES" "A83"
                    WHERE     "A83"."FLEX_VALUE_ID" = "A84"."FLEX_VALUE_ID"
                          AND "A84"."LANGUAGE" = USERENV ('LANG')) "A15"
            WHERE     "A17"."CATEGORY_SET_NAME" = 'Origem do Item'
                  AND "A16"."CATEGORY_SET_ID" = "A17"."CATEGORY_SET_ID"
                  AND "A15"."FLEX_VALUE" = "A16"."SEGMENT1"
                  AND "A16"."INVENTORY_ITEM_ID" = "A2"."INVENTORY_ITEM_ID"
                  AND "A16"."ORGANIZATION_ID" = "A2"."ORGANIZATION_ID"
                  AND "A15"."FLEX_VALUE_SET_ID" =
                         (SELECT "A37"."FLEX_VALUE_SET_ID"
                                    "FLEX_VALUE_SET_ID"
                            FROM "APPLSYS"."FND_FLEX_VALUE_SETS" "A37"
                           WHERE "A37"."FLEX_VALUE_SET_NAME" = 'GL_PB_ORIGEM'))
          "ORIGEM_ITEM",
       "A6"."CD_FORNECEDORORIGEM" || ' - ' || "A6"."DS_FORNECEDORORIGEM"
          "FORNECEDORORIGEM",
       "A6"."CD_FORNECEDOR" || ' - ' || "A6"."DS_FORNECEDOR" "FORNECEDOR"
  FROM (SELECT "A45"."ORGANIZATION_ID" "ORGANIZATION_ID",
               "A45"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
               "A45"."SEGMENT1" "CD_LINHA",
               "A45"."SEGMENT2" "CD_COR",
               "A45"."SEGMENT3" "CD_PEI",
               "A45"."SEGMENT4" "CD_USO",
               "A44"."DS_LINHA" "DS_LINHA",
               "A42"."DESCRIPTION" "DS_COR",
               "A40"."DESCRIPTION" "DS_PEI",
               "A38"."DESCRIPTION" "DS_USO",
               "A44"."IN_CONCEITO" "IN_CONCEITO"
          FROM (SELECT "A116"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                       "A116"."CONTROL_LEVEL" "CONTROL_LEVEL",
                       "A117"."CATEGORY_SET_NAME" "CATEGORY_SET_NAME"
                  FROM "INV"."MTL_CATEGORY_SETS_TL" "A117",
                       "INV"."MTL_CATEGORY_SETS_B" "A116"
                 WHERE     "A116"."CATEGORY_SET_ID" =
                              "A117"."CATEGORY_SET_ID"
                       AND "A117"."LANGUAGE" = USERENV ('LANG')) "A46",
               (SELECT "A122"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
                       "A122"."ORGANIZATION_ID" "ORGANIZATION_ID",
                       "A122"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                       "A122"."CATEGORY_ID" "CATEGORY_ID",
                       "A118"."SEGMENT1" "SEGMENT1",
                       "A118"."SEGMENT2" "SEGMENT2",
                       "A118"."SEGMENT3" "SEGMENT3",
                       "A118"."SEGMENT4" "SEGMENT4"
                  FROM "INV"."MTL_ITEM_CATEGORIES" "A122",
                       "INV"."MTL_CATEGORY_SETS_TL" "A121",
                       "INV"."MTL_CATEGORY_SETS_B" "A120",
                       (SELECT "A123"."LOOKUP_TYPE" "LOOKUP_TYPE",
                               TO_NUMBER ("A123"."LOOKUP_CODE") "LOOKUP_CODE",
                               "A123"."MEANING" "MEANING"
                          FROM "APPLSYS"."FND_LOOKUP_VALUES" "A123"
                         WHERE     "A123"."LANGUAGE" = USERENV ('LANG')
                               AND "A123"."VIEW_APPLICATION_ID" = 700
                               AND "A123"."SECURITY_GROUP_ID" = 0) "A119",
                       (SELECT "A124"."CATEGORY_ID" "CATEGORY_ID",
                               "A124"."SEGMENT2" "SEGMENT2",
                               "A124"."SEGMENT1" "SEGMENT1",
                               "A124"."SEGMENT4" "SEGMENT4",
                               "A124"."SEGMENT3" "SEGMENT3"
                          FROM "INV"."MTL_CATEGORIES_B" "A124") "A118"
                 WHERE     "A122"."CATEGORY_SET_ID" =
                              "A120"."CATEGORY_SET_ID"
                       AND "A120"."CATEGORY_SET_ID" =
                              "A121"."CATEGORY_SET_ID"
                       AND "A121"."LANGUAGE" = USERENV ('LANG')
                       AND "A122"."CATEGORY_ID" = "A118"."CATEGORY_ID"
                       AND "A120"."CONTROL_LEVEL" = "A119"."LOOKUP_CODE"
                       AND "A119"."LOOKUP_TYPE" = 'ITEM_CONTROL_LEVEL_GUI') "A45",
               "GMI"."GMI_LINHA_APO" "A44",
               "APPLSYS"."FND_FLEX_VALUE_SETS" "A43",
               (SELECT "A125"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                       "A125"."FLEX_VALUE" "FLEX_VALUE",
                       "A126"."DESCRIPTION" "DESCRIPTION"
                  FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A126",
                       "APPLSYS"."FND_FLEX_VALUES" "A125"
                 WHERE     "A125"."FLEX_VALUE_ID" = "A126"."FLEX_VALUE_ID"
                       AND "A126"."LANGUAGE" = USERENV ('LANG')) "A42",
               "APPLSYS"."FND_FLEX_VALUE_SETS" "A41",
               (SELECT "A127"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                       "A127"."FLEX_VALUE" "FLEX_VALUE",
                       "A128"."DESCRIPTION" "DESCRIPTION"
                  FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A128",
                       "APPLSYS"."FND_FLEX_VALUES" "A127"
                 WHERE     "A127"."FLEX_VALUE_ID" = "A128"."FLEX_VALUE_ID"
                       AND "A128"."LANGUAGE" = USERENV ('LANG')) "A40",
               "APPLSYS"."FND_FLEX_VALUE_SETS" "A39",
               (SELECT "A129"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                       "A129"."FLEX_VALUE" "FLEX_VALUE",
                       "A130"."DESCRIPTION" "DESCRIPTION"
                  FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A130",
                       "APPLSYS"."FND_FLEX_VALUES" "A129"
                 WHERE     "A129"."FLEX_VALUE_ID" = "A130"."FLEX_VALUE_ID"
                       AND "A130"."LANGUAGE" = USERENV ('LANG')) "A38"
         WHERE     "A45"."CATEGORY_SET_ID" = "A46"."CATEGORY_SET_ID"
               AND "A46"."CATEGORY_SET_NAME" = 'Linha de Produto PB'
               AND "A44"."NR_LINHA" = "A45"."SEGMENT1"
               AND "A43"."FLEX_VALUE_SET_ID" = "A42"."FLEX_VALUE_SET_ID"
               AND "A43"."FLEX_VALUE_SET_NAME" = 'INV_COR_APO'
               AND "A42"."FLEX_VALUE" = "A45"."SEGMENT2"
               AND "A41"."FLEX_VALUE_SET_ID" = "A40"."FLEX_VALUE_SET_ID"
               AND "A41"."FLEX_VALUE_SET_NAME" = 'INV_PEI_APO'
               AND "A40"."FLEX_VALUE" = "A45"."SEGMENT3"
               AND "A39"."FLEX_VALUE_SET_ID" = "A38"."FLEX_VALUE_SET_ID"(+)
               AND "A39"."FLEX_VALUE_SET_NAME"(+) = 'INV_USO_PB'
               AND "A38"."FLEX_VALUE"(+) = "A45"."SEGMENT4") "A7",
       (SELECT "A67"."ORGANIZATION_ID" "ORGANIZATION_ID",
               "A67"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
               "A67"."SEGMENT1" "CD_FORNECEDORORIGEM",
               "A67"."SEGMENT2" "CD_FORNECEDOR",
               "A65"."DESCRIPTION" "DS_FORNECEDORORIGEM",
               "A63"."DESCRIPTION" "DS_FORNECEDOR"
          FROM (SELECT "A161"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                       "A161"."CONTROL_LEVEL" "CONTROL_LEVEL",
                       "A162"."CATEGORY_SET_NAME" "CATEGORY_SET_NAME"
                  FROM "INV"."MTL_CATEGORY_SETS_TL" "A162",
                       "INV"."MTL_CATEGORY_SETS_B" "A161"
                 WHERE     "A161"."CATEGORY_SET_ID" =
                              "A162"."CATEGORY_SET_ID"
                       AND "A162"."LANGUAGE" = USERENV ('LANG')) "A68",
               (SELECT "A167"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
                       "A167"."ORGANIZATION_ID" "ORGANIZATION_ID",
                       "A167"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                       "A163"."SEGMENT1" "SEGMENT1",
                       "A163"."SEGMENT2" "SEGMENT2",
                       "A163"."SEGMENT3" "SEGMENT3",
                       "A163"."SEGMENT4" "SEGMENT4"
                  FROM "INV"."MTL_ITEM_CATEGORIES" "A167",
                       "INV"."MTL_CATEGORY_SETS_TL" "A166",
                       "INV"."MTL_CATEGORY_SETS_B" "A165",
                       (SELECT "A168"."LOOKUP_TYPE" "LOOKUP_TYPE",
                               TO_NUMBER ("A168"."LOOKUP_CODE") "LOOKUP_CODE",
                               "A168"."MEANING" "MEANING"
                          FROM "APPLSYS"."FND_LOOKUP_VALUES" "A168"
                         WHERE     "A168"."LANGUAGE" = USERENV ('LANG')
                               AND "A168"."VIEW_APPLICATION_ID" = 700
                               AND "A168"."SECURITY_GROUP_ID" = 0) "A164",
                       (SELECT "A169"."CATEGORY_ID" "CATEGORY_ID",
                               "A169"."SEGMENT2" "SEGMENT2",
                               "A169"."SEGMENT1" "SEGMENT1",
                               "A169"."SEGMENT4" "SEGMENT4",
                               "A169"."SEGMENT3" "SEGMENT3"
                          FROM "INV"."MTL_CATEGORIES_B" "A169") "A163"
                 WHERE     "A167"."CATEGORY_SET_ID" =
                              "A165"."CATEGORY_SET_ID"
                       AND "A165"."CATEGORY_SET_ID" =
                              "A166"."CATEGORY_SET_ID"
                       AND "A166"."LANGUAGE" = USERENV ('LANG')
                       AND "A167"."CATEGORY_ID" = "A163"."CATEGORY_ID"
                       AND "A165"."CONTROL_LEVEL" = "A164"."LOOKUP_CODE"
                       AND "A164"."LOOKUP_TYPE" = 'ITEM_CONTROL_LEVEL_GUI') "A67",
               "APPLSYS"."FND_FLEX_VALUE_SETS" "A66",
               (SELECT "A170"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                       "A170"."FLEX_VALUE" "FLEX_VALUE",
                       "A171"."DESCRIPTION" "DESCRIPTION"
                  FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A171",
                       "APPLSYS"."FND_FLEX_VALUES" "A170"
                 WHERE     "A170"."FLEX_VALUE_ID" = "A171"."FLEX_VALUE_ID"
                       AND "A171"."LANGUAGE" = USERENV ('LANG')) "A65",
               "APPLSYS"."FND_FLEX_VALUE_SETS" "A64",
               (SELECT "A172"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                       "A172"."FLEX_VALUE" "FLEX_VALUE",
                       "A172"."PARENT_FLEX_VALUE_LOW" "PARENT_FLEX_VALUE_LOW",
                       "A173"."DESCRIPTION" "DESCRIPTION"
                  FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A173",
                       "APPLSYS"."FND_FLEX_VALUES" "A172"
                 WHERE     "A172"."FLEX_VALUE_ID" = "A173"."FLEX_VALUE_ID"
                       AND "A173"."LANGUAGE" = USERENV ('LANG')) "A63"
         WHERE     "A67"."CATEGORY_SET_ID" = "A68"."CATEGORY_SET_ID"
               AND "A68"."CATEGORY_SET_NAME" = 'Fornecedor do Produto PB'
               AND "A66"."FLEX_VALUE_SET_ID" = "A65"."FLEX_VALUE_SET_ID"
               AND "A66"."FLEX_VALUE_SET_NAME" = 'INV_FORNECEDOR_ORIGEM_PB'
               AND "A65"."FLEX_VALUE" = "A67"."SEGMENT1"
               AND "A64"."FLEX_VALUE_SET_ID" = "A63"."FLEX_VALUE_SET_ID"
               AND "A64"."FLEX_VALUE_SET_NAME" = 'INV_FORNECEDOR_PB'
               AND "A63"."FLEX_VALUE" = "A67"."SEGMENT2"
               AND "A63"."PARENT_FLEX_VALUE_LOW" = "A67"."SEGMENT1") "A6",
       (SELECT "A61"."ORGANIZATION_ID" "ORGANIZATION_ID",
               "A61"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
               "A61"."SEGMENT1" "CD_FORMATO",
               "A61"."SEGMENT2" "CD_FORMATO_REAL",
               "A59"."DESCRIPTION" "DS_FORMATO",
               "A57"."DESCRIPTION" "DS_FORMATO_REAL"
          FROM (SELECT "A148"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                       "A148"."CONTROL_LEVEL" "CONTROL_LEVEL",
                       "A149"."CATEGORY_SET_NAME" "CATEGORY_SET_NAME"
                  FROM "INV"."MTL_CATEGORY_SETS_TL" "A149",
                       "INV"."MTL_CATEGORY_SETS_B" "A148"
                 WHERE     "A148"."CATEGORY_SET_ID" =
                              "A149"."CATEGORY_SET_ID"
                       AND "A149"."LANGUAGE" = USERENV ('LANG')) "A62",
               (SELECT "A154"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
                       "A154"."ORGANIZATION_ID" "ORGANIZATION_ID",
                       "A154"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                       "A154"."CATEGORY_ID" "CATEGORY_ID",
                       "A150"."SEGMENT1" "SEGMENT1",
                       "A150"."SEGMENT2" "SEGMENT2",
                       "A150"."SEGMENT3" "SEGMENT3",
                       "A150"."SEGMENT4" "SEGMENT4"
                  FROM "INV"."MTL_ITEM_CATEGORIES" "A154",
                       "INV"."MTL_CATEGORY_SETS_TL" "A153",
                       "INV"."MTL_CATEGORY_SETS_B" "A152",
                       (SELECT "A155"."LOOKUP_TYPE" "LOOKUP_TYPE",
                               TO_NUMBER ("A155"."LOOKUP_CODE") "LOOKUP_CODE",
                               "A155"."MEANING" "MEANING"
                          FROM "APPLSYS"."FND_LOOKUP_VALUES" "A155"
                         WHERE     "A155"."LANGUAGE" = USERENV ('LANG')
                               AND "A155"."VIEW_APPLICATION_ID" = 700
                               AND "A155"."SECURITY_GROUP_ID" = 0) "A151",
                       (SELECT "A156"."CATEGORY_ID" "CATEGORY_ID",
                               "A156"."SEGMENT2" "SEGMENT2",
                               "A156"."SEGMENT1" "SEGMENT1",
                               "A156"."SEGMENT4" "SEGMENT4",
                               "A156"."SEGMENT3" "SEGMENT3"
                          FROM "INV"."MTL_CATEGORIES_B" "A156") "A150"
                 WHERE     "A154"."CATEGORY_SET_ID" =
                              "A152"."CATEGORY_SET_ID"
                       AND "A152"."CATEGORY_SET_ID" =
                              "A153"."CATEGORY_SET_ID"
                       AND "A153"."LANGUAGE" = USERENV ('LANG')
                       AND "A154"."CATEGORY_ID" = "A150"."CATEGORY_ID"
                       AND "A152"."CONTROL_LEVEL" = "A151"."LOOKUP_CODE"
                       AND "A151"."LOOKUP_TYPE" = 'ITEM_CONTROL_LEVEL_GUI') "A61",
               "APPLSYS"."FND_FLEX_VALUE_SETS" "A60",
               (SELECT "A157"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                       "A157"."FLEX_VALUE" "FLEX_VALUE",
                       "A158"."DESCRIPTION" "DESCRIPTION"
                  FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A158",
                       "APPLSYS"."FND_FLEX_VALUES" "A157"
                 WHERE     "A157"."FLEX_VALUE_ID" = "A158"."FLEX_VALUE_ID"
                       AND "A158"."LANGUAGE" = USERENV ('LANG')) "A59",
               "APPLSYS"."FND_FLEX_VALUE_SETS" "A58",
               (SELECT "A159"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                       "A159"."FLEX_VALUE" "FLEX_VALUE",
                       "A159"."PARENT_FLEX_VALUE_LOW" "PARENT_FLEX_VALUE_LOW",
                       "A160"."DESCRIPTION" "DESCRIPTION"
                  FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A160",
                       "APPLSYS"."FND_FLEX_VALUES" "A159"
                 WHERE     "A159"."FLEX_VALUE_ID" = "A160"."FLEX_VALUE_ID"
                       AND "A160"."LANGUAGE" = USERENV ('LANG')) "A57"
         WHERE     "A61"."CATEGORY_SET_ID" = "A62"."CATEGORY_SET_ID"
               AND "A62"."CATEGORY_SET_NAME" = 'Formato de Produto PB'
               AND "A60"."FLEX_VALUE_SET_ID" = "A59"."FLEX_VALUE_SET_ID"
               AND "A60"."FLEX_VALUE_SET_NAME" = 'INV_FORMATO_NOMINAL_APO'
               AND "A59"."FLEX_VALUE" = "A61"."SEGMENT1"
               AND "A58"."FLEX_VALUE_SET_ID" = "A57"."FLEX_VALUE_SET_ID"
               AND "A58"."FLEX_VALUE_SET_NAME" = 'INV_FORMATO_REAL_APO'
               AND "A57"."FLEX_VALUE" = "A61"."SEGMENT2"
               AND "A57"."PARENT_FLEX_VALUE_LOW" = "A61"."SEGMENT1") "A5",
       (SELECT "A55"."ORGANIZATION_ID" "ORGANIZATION_ID",
               "A55"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
               "A55"."SEGMENT1" "CD_TIPOLOGIA_COMERCIAL",
               "A55"."SEGMENT2" "CD_TIPOLOGIA_PRINCIPAL",
               "A55"."SEGMENT3" "CD_TIPOLOGIA_SECUNDARIA",
               "A55"."SEGMENT4" "CD_APLICACAO_TECNICA",
               "A53"."DESCRIPTION" "DS_TIPOLOGIA_COMERCIAL",
               "A51"."DESCRIPTION" "DS_TIPOLOGIA_PRINCIPAL",
               "A49"."DESCRIPTION" "DS_TIPOLOGIA_SECUNDARIA",
               "A47"."DESCRIPTION" "DS_APLICACAO_TECNICA"
          FROM (SELECT "A131"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                       "A131"."CONTROL_LEVEL" "CONTROL_LEVEL",
                       "A132"."CATEGORY_SET_NAME" "CATEGORY_SET_NAME"
                  FROM "INV"."MTL_CATEGORY_SETS_TL" "A132",
                       "INV"."MTL_CATEGORY_SETS_B" "A131"
                 WHERE     "A131"."CATEGORY_SET_ID" =
                              "A132"."CATEGORY_SET_ID"
                       AND "A132"."LANGUAGE" = USERENV ('LANG')) "A56",
               (SELECT "A137"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
                       "A137"."ORGANIZATION_ID" "ORGANIZATION_ID",
                       "A137"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                       "A137"."CATEGORY_ID" "CATEGORY_ID",
                       "A133"."SEGMENT1" "SEGMENT1",
                       "A133"."SEGMENT2" "SEGMENT2",
                       "A133"."SEGMENT3" "SEGMENT3",
                       "A133"."SEGMENT4" "SEGMENT4"
                  FROM "INV"."MTL_ITEM_CATEGORIES" "A137",
                       "INV"."MTL_CATEGORY_SETS_TL" "A136",
                       "INV"."MTL_CATEGORY_SETS_B" "A135",
                       (SELECT "A138"."LOOKUP_TYPE" "LOOKUP_TYPE",
                               TO_NUMBER ("A138"."LOOKUP_CODE") "LOOKUP_CODE",
                               "A138"."MEANING" "MEANING"
                          FROM "APPLSYS"."FND_LOOKUP_VALUES" "A138"
                         WHERE     "A138"."LANGUAGE" = USERENV ('LANG')
                               AND "A138"."VIEW_APPLICATION_ID" = 700
                               AND "A138"."SECURITY_GROUP_ID" = 0) "A134",
                       (SELECT "A139"."CATEGORY_ID" "CATEGORY_ID",
                               "A139"."SEGMENT2" "SEGMENT2",
                               "A139"."SEGMENT1" "SEGMENT1",
                               "A139"."SEGMENT4" "SEGMENT4",
                               "A139"."SEGMENT3" "SEGMENT3"
                          FROM "INV"."MTL_CATEGORIES_B" "A139") "A133"
                 WHERE     "A137"."CATEGORY_SET_ID" =
                              "A135"."CATEGORY_SET_ID"
                       AND "A135"."CATEGORY_SET_ID" =
                              "A136"."CATEGORY_SET_ID"
                       AND "A136"."LANGUAGE" = USERENV ('LANG')
                       AND "A137"."CATEGORY_ID" = "A133"."CATEGORY_ID"
                       AND "A135"."CONTROL_LEVEL" = "A134"."LOOKUP_CODE"
                       AND "A134"."LOOKUP_TYPE" = 'ITEM_CONTROL_LEVEL_GUI') "A55",
               "APPLSYS"."FND_FLEX_VALUE_SETS" "A54",
               (SELECT "A140"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                       "A140"."FLEX_VALUE" "FLEX_VALUE",
                       "A141"."DESCRIPTION" "DESCRIPTION"
                  FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A141",
                       "APPLSYS"."FND_FLEX_VALUES" "A140"
                 WHERE     "A140"."FLEX_VALUE_ID" = "A141"."FLEX_VALUE_ID"
                       AND "A141"."LANGUAGE" = USERENV ('LANG')) "A53",
               "APPLSYS"."FND_FLEX_VALUE_SETS" "A52",
               (SELECT "A142"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                       "A142"."FLEX_VALUE" "FLEX_VALUE",
                       "A143"."DESCRIPTION" "DESCRIPTION"
                  FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A143",
                       "APPLSYS"."FND_FLEX_VALUES" "A142"
                 WHERE     "A142"."FLEX_VALUE_ID" = "A143"."FLEX_VALUE_ID"
                       AND "A143"."LANGUAGE" = USERENV ('LANG')) "A51",
               "APPLSYS"."FND_FLEX_VALUE_SETS" "A50",
               (SELECT "A144"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                       "A144"."FLEX_VALUE" "FLEX_VALUE",
                       "A145"."DESCRIPTION" "DESCRIPTION"
                  FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A145",
                       "APPLSYS"."FND_FLEX_VALUES" "A144"
                 WHERE     "A144"."FLEX_VALUE_ID" = "A145"."FLEX_VALUE_ID"
                       AND "A145"."LANGUAGE" = USERENV ('LANG')) "A49",
               "APPLSYS"."FND_FLEX_VALUE_SETS" "A48",
               (SELECT "A146"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                       "A146"."FLEX_VALUE" "FLEX_VALUE",
                       "A147"."DESCRIPTION" "DESCRIPTION"
                  FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A147",
                       "APPLSYS"."FND_FLEX_VALUES" "A146"
                 WHERE     "A146"."FLEX_VALUE_ID" = "A147"."FLEX_VALUE_ID"
                       AND "A147"."LANGUAGE" = USERENV ('LANG')) "A47"
         WHERE     "A55"."CATEGORY_SET_ID" = "A56"."CATEGORY_SET_ID"
               AND "A56"."CATEGORY_SET_NAME" = 'Tipologia de Produto PB'
               AND "A54"."FLEX_VALUE_SET_ID" = "A53"."FLEX_VALUE_SET_ID"
               AND "A54"."FLEX_VALUE_SET_NAME" =
                      'INV_TIPOLOGIA_COMERCIAL_APO'
               AND "A53"."FLEX_VALUE" = "A55"."SEGMENT1"
               AND "A52"."FLEX_VALUE_SET_ID" = "A51"."FLEX_VALUE_SET_ID"
               AND "A52"."FLEX_VALUE_SET_NAME" =
                      'INV_TIPOLOGIA_PRINCIPAL_APO'
               AND "A51"."FLEX_VALUE" = "A55"."SEGMENT2"
               AND "A50"."FLEX_VALUE_SET_ID" = "A49"."FLEX_VALUE_SET_ID"
               AND "A50"."FLEX_VALUE_SET_NAME" =
                      'INV_TIPOLOGIA_SECUNDARIA_APO'
               AND "A49"."FLEX_VALUE" = "A55"."SEGMENT3"
               AND "A48"."FLEX_VALUE_SET_ID" = "A47"."FLEX_VALUE_SET_ID"
               AND "A48"."FLEX_VALUE_SET_NAME" = 'INV_APLICACAO_TECNICA_APO'
               AND "A47"."FLEX_VALUE" = "A55"."SEGMENT4") "A4",
       "REC"."REC_FISCAL_CLASSIFICATIONS" "A3",
       (SELECT "A113"."ROW_ID" "ROW_ID",
               "A113"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
               "A113"."ORGANIZATION_ID" "ORGANIZATION_ID",
               "A113"."PRIMARY_UOM_CODE" "PRIMARY_UOM_CODE",
               "A113"."PRIMARY_UNIT_OF_MEASURE" "PRIMARY_UNIT_OF_MEASURE",
               "A113"."ITEM_TYPE" "ITEM_TYPE",
               "A113"."INVENTORY_ITEM_STATUS_CODE"
                  "INVENTORY_ITEM_STATUS_CODE",
               "A113"."ALLOWED_UNITS_LOOKUP_CODE" "ALLOWED_UNITS_LOOKUP_CODE",
               "A113"."ITEM_CATALOG_GROUP_ID" "ITEM_CATALOG_GROUP_ID",
               "A113"."CATALOG_STATUS_FLAG" "CATALOG_STATUS_FLAG",
               "A113"."INVENTORY_ITEM_FLAG" "INVENTORY_ITEM_FLAG",
               "A113"."STOCK_ENABLED_FLAG" "STOCK_ENABLED_FLAG",
               "A113"."MTL_TRANSACTIONS_ENABLED_FLAG"
                  "MTL_TRANSACTIONS_ENABLED_FLAG",
               "A113"."CHECK_SHORTAGES_FLAG" "CHECK_SHORTAGES_FLAG",
               "A113"."REVISION_QTY_CONTROL_CODE" "REVISION_QTY_CONTROL_CODE",
               "A113"."RESERVABLE_TYPE" "RESERVABLE_TYPE",
               "A113"."SHELF_LIFE_CODE" "SHELF_LIFE_CODE",
               "A113"."SHELF_LIFE_DAYS" "SHELF_LIFE_DAYS",
               "A113"."CYCLE_COUNT_ENABLED_FLAG" "CYCLE_COUNT_ENABLED_FLAG",
               "A113"."NEGATIVE_MEASUREMENT_ERROR"
                  "NEGATIVE_MEASUREMENT_ERROR",
               "A113"."POSITIVE_MEASUREMENT_ERROR"
                  "POSITIVE_MEASUREMENT_ERROR",
               "A113"."LOT_CONTROL_CODE" "LOT_CONTROL_CODE",
               "A113"."AUTO_LOT_ALPHA_PREFIX" "AUTO_LOT_ALPHA_PREFIX",
               "A113"."START_AUTO_LOT_NUMBER" "START_AUTO_LOT_NUMBER",
               "A113"."SERIAL_NUMBER_CONTROL_CODE"
                  "SERIAL_NUMBER_CONTROL_CODE",
               "A113"."AUTO_SERIAL_ALPHA_PREFIX" "AUTO_SERIAL_ALPHA_PREFIX",
               "A113"."START_AUTO_SERIAL_NUMBER" "START_AUTO_SERIAL_NUMBER",
               "A113"."LOCATION_CONTROL_CODE" "LOCATION_CONTROL_CODE",
               "A113"."RESTRICT_SUBINVENTORIES_CODE"
                  "RESTRICT_SUBINVENTORIES_CODE",
               "A113"."RESTRICT_LOCATORS_CODE" "RESTRICT_LOCATORS_CODE",
               "A113"."BOM_ENABLED_FLAG" "BOM_ENABLED_FLAG",
               "A113"."BOM_ITEM_TYPE" "BOM_ITEM_TYPE",
               "A113"."BASE_ITEM_ID" "BASE_ITEM_ID",
               "A113"."EFFECTIVITY_CONTROL" "EFFECTIVITY_CONTROL",
               "A113"."ENG_ITEM_FLAG" "ENG_ITEM_FLAG",
               "A113"."ENGINEERING_ECN_CODE" "ENGINEERING_ECN_CODE",
               "A113"."ENGINEERING_ITEM_ID" "ENGINEERING_ITEM_ID",
               "A113"."ENGINEERING_DATE" "ENGINEERING_DATE",
               "A113"."PRODUCT_FAMILY_ITEM_ID" "PRODUCT_FAMILY_ITEM_ID",
               "A113"."AUTO_CREATED_CONFIG_FLAG" "AUTO_CREATED_CONFIG_FLAG",
               "A113"."MODEL_CONFIG_CLAUSE_NAME" "MODEL_CONFIG_CLAUSE_NAME",
               "A113"."NEW_REVISION_CODE" "NEW_REVISION_CODE",
               "A113"."COSTING_ENABLED_FLAG" "COSTING_ENABLED_FLAG",
               "A113"."INVENTORY_ASSET_FLAG" "INVENTORY_ASSET_FLAG",
               "A113"."DEFAULT_INCLUDE_IN_ROLLUP_FLAG"
                  "DEFAULT_INCLUDE_IN_ROLLUP_FLAG",
               "A113"."COST_OF_SALES_ACCOUNT" "COST_OF_SALES_ACCOUNT",
               "A113"."STD_LOT_SIZE" "STD_LOT_SIZE",
               "A113"."PURCHASING_ITEM_FLAG" "PURCHASING_ITEM_FLAG",
               "A113"."PURCHASING_ENABLED_FLAG" "PURCHASING_ENABLED_FLAG",
               "A113"."MUST_USE_APPROVED_VENDOR_FLAG"
                  "MUST_USE_APPROVED_VENDOR_FLAG",
               "A113"."ALLOW_ITEM_DESC_UPDATE_FLAG"
                  "ALLOW_ITEM_DESC_UPDATE_FLAG",
               "A113"."RFQ_REQUIRED_FLAG" "RFQ_REQUIRED_FLAG",
               "A113"."OUTSIDE_OPERATION_FLAG" "OUTSIDE_OPERATION_FLAG",
               "A113"."OUTSIDE_OPERATION_UOM_TYPE"
                  "OUTSIDE_OPERATION_UOM_TYPE",
               "A113"."TAXABLE_FLAG" "TAXABLE_FLAG",
               "A113"."PURCHASING_TAX_CODE" "PURCHASING_TAX_CODE",
               "A113"."RECEIPT_REQUIRED_FLAG" "RECEIPT_REQUIRED_FLAG",
               "A113"."INSPECTION_REQUIRED_FLAG" "INSPECTION_REQUIRED_FLAG",
               "A113"."BUYER_ID" "BUYER_ID",
               "A113"."UNIT_OF_ISSUE" "UNIT_OF_ISSUE",
               "A113"."RECEIVE_CLOSE_TOLERANCE" "RECEIVE_CLOSE_TOLERANCE",
               "A113"."INVOICE_CLOSE_TOLERANCE" "INVOICE_CLOSE_TOLERANCE",
               "A113"."UN_NUMBER_ID" "UN_NUMBER_ID",
               "A113"."HAZARD_CLASS_ID" "HAZARD_CLASS_ID",
               "A113"."LIST_PRICE_PER_UNIT" "LIST_PRICE_PER_UNIT",
               "A113"."MARKET_PRICE" "MARKET_PRICE",
               "A113"."PRICE_TOLERANCE_PERCENT" "PRICE_TOLERANCE_PERCENT",
               "A113"."ROUNDING_FACTOR" "ROUNDING_FACTOR",
               "A113"."ENCUMBRANCE_ACCOUNT" "ENCUMBRANCE_ACCOUNT",
               "A113"."EXPENSE_ACCOUNT" "EXPENSE_ACCOUNT",
               "A113"."ASSET_CATEGORY_ID" "ASSET_CATEGORY_ID",
               "A113"."RECEIPT_DAYS_EXCEPTION_CODE"
                  "RECEIPT_DAYS_EXCEPTION_CODE",
               "A113"."DAYS_EARLY_RECEIPT_ALLOWED"
                  "DAYS_EARLY_RECEIPT_ALLOWED",
               "A113"."DAYS_LATE_RECEIPT_ALLOWED" "DAYS_LATE_RECEIPT_ALLOWED",
               "A113"."ALLOW_SUBSTITUTE_RECEIPTS_FLAG"
                  "ALLOW_SUBSTITUTE_RECEIPTS_FLAG",
               "A113"."ALLOW_UNORDERED_RECEIPTS_FLAG"
                  "ALLOW_UNORDERED_RECEIPTS_FLAG",
               "A113"."ALLOW_EXPRESS_DELIVERY_FLAG"
                  "ALLOW_EXPRESS_DELIVERY_FLAG",
               "A113"."QTY_RCV_EXCEPTION_CODE" "QTY_RCV_EXCEPTION_CODE",
               "A113"."QTY_RCV_TOLERANCE" "QTY_RCV_TOLERANCE",
               "A113"."RECEIVING_ROUTING_ID" "RECEIVING_ROUTING_ID",
               "A113"."ENFORCE_SHIP_TO_LOCATION_CODE"
                  "ENFORCE_SHIP_TO_LOCATION_CODE",
               "A113"."WEIGHT_UOM_CODE" "WEIGHT_UOM_CODE",
               "A113"."UNIT_WEIGHT" "UNIT_WEIGHT",
               "A113"."VOLUME_UOM_CODE" "VOLUME_UOM_CODE",
               "A113"."UNIT_VOLUME" "UNIT_VOLUME",
               "A113"."CONTAINER_ITEM_FLAG" "CONTAINER_ITEM_FLAG",
               "A113"."VEHICLE_ITEM_FLAG" "VEHICLE_ITEM_FLAG",
               "A113"."CONTAINER_TYPE_CODE" "CONTAINER_TYPE_CODE",
               "A113"."INTERNAL_VOLUME" "INTERNAL_VOLUME",
               "A113"."MAXIMUM_LOAD_WEIGHT" "MAXIMUM_LOAD_WEIGHT",
               "A113"."MINIMUM_FILL_PERCENT" "MINIMUM_FILL_PERCENT",
               "A113"."INVENTORY_PLANNING_CODE" "INVENTORY_PLANNING_CODE",
               "A113"."PLANNER_CODE" "PLANNER_CODE",
               "A113"."PLANNING_MAKE_BUY_CODE" "PLANNING_MAKE_BUY_CODE",
               "A113"."MIN_MINMAX_QUANTITY" "MIN_MINMAX_QUANTITY",
               "A113"."MAX_MINMAX_QUANTITY" "MAX_MINMAX_QUANTITY",
               "A113"."MINIMUM_ORDER_QUANTITY" "MINIMUM_ORDER_QUANTITY",
               "A113"."MAXIMUM_ORDER_QUANTITY" "MAXIMUM_ORDER_QUANTITY",
               "A113"."ORDER_COST" "ORDER_COST",
               "A113"."CARRYING_COST" "CARRYING_COST",
               "A113"."SOURCE_TYPE" "SOURCE_TYPE",
               "A113"."SOURCE_ORGANIZATION_ID" "SOURCE_ORGANIZATION_ID",
               "A113"."SOURCE_SUBINVENTORY" "SOURCE_SUBINVENTORY",
               "A113"."MRP_SAFETY_STOCK_CODE" "MRP_SAFETY_STOCK_CODE",
               "A113"."SAFETY_STOCK_BUCKET_DAYS" "SAFETY_STOCK_BUCKET_DAYS",
               "A113"."MRP_SAFETY_STOCK_PERCENT" "MRP_SAFETY_STOCK_PERCENT",
               "A113"."FIXED_ORDER_QUANTITY" "FIXED_ORDER_QUANTITY",
               "A113"."FIXED_DAYS_SUPPLY" "FIXED_DAYS_SUPPLY",
               "A113"."FIXED_LOT_MULTIPLIER" "FIXED_LOT_MULTIPLIER",
               "A113"."MRP_PLANNING_CODE" "MRP_PLANNING_CODE",
               "A113"."ATO_FORECAST_CONTROL" "ATO_FORECAST_CONTROL",
               "A113"."PLANNING_EXCEPTION_SET" "PLANNING_EXCEPTION_SET",
               "A113"."END_ASSEMBLY_PEGGING_FLAG" "END_ASSEMBLY_PEGGING_FLAG",
               "A113"."SHRINKAGE_RATE" "SHRINKAGE_RATE",
               "A113"."ROUNDING_CONTROL_TYPE" "ROUNDING_CONTROL_TYPE",
               "A113"."ACCEPTABLE_EARLY_DAYS" "ACCEPTABLE_EARLY_DAYS",
               "A113"."REPETITIVE_PLANNING_FLAG" "REPETITIVE_PLANNING_FLAG",
               "A113"."OVERRUN_PERCENTAGE" "OVERRUN_PERCENTAGE",
               "A113"."ACCEPTABLE_RATE_INCREASE" "ACCEPTABLE_RATE_INCREASE",
               "A113"."ACCEPTABLE_RATE_DECREASE" "ACCEPTABLE_RATE_DECREASE",
               "A113"."MRP_CALCULATE_ATP_FLAG" "MRP_CALCULATE_ATP_FLAG",
               "A113"."AUTO_REDUCE_MPS" "AUTO_REDUCE_MPS",
               "A113"."PLANNING_TIME_FENCE_CODE" "PLANNING_TIME_FENCE_CODE",
               "A113"."PLANNING_TIME_FENCE_DAYS" "PLANNING_TIME_FENCE_DAYS",
               "A113"."DEMAND_TIME_FENCE_CODE" "DEMAND_TIME_FENCE_CODE",
               "A113"."DEMAND_TIME_FENCE_DAYS" "DEMAND_TIME_FENCE_DAYS",
               "A113"."RELEASE_TIME_FENCE_CODE" "RELEASE_TIME_FENCE_CODE",
               "A113"."RELEASE_TIME_FENCE_DAYS" "RELEASE_TIME_FENCE_DAYS",
               "A113"."PREPROCESSING_LEAD_TIME" "PREPROCESSING_LEAD_TIME",
               "A113"."FULL_LEAD_TIME" "FULL_LEAD_TIME",
               "A113"."POSTPROCESSING_LEAD_TIME" "POSTPROCESSING_LEAD_TIME",
               "A113"."FIXED_LEAD_TIME" "FIXED_LEAD_TIME",
               "A113"."VARIABLE_LEAD_TIME" "VARIABLE_LEAD_TIME",
               "A113"."CUM_MANUFACTURING_LEAD_TIME"
                  "CUM_MANUFACTURING_LEAD_TIME",
               "A113"."CUMULATIVE_TOTAL_LEAD_TIME"
                  "CUMULATIVE_TOTAL_LEAD_TIME",
               "A113"."LEAD_TIME_LOT_SIZE" "LEAD_TIME_LOT_SIZE",
               "A113"."BUILD_IN_WIP_FLAG" "BUILD_IN_WIP_FLAG",
               "A113"."WIP_SUPPLY_TYPE" "WIP_SUPPLY_TYPE",
               "A113"."WIP_SUPPLY_SUBINVENTORY" "WIP_SUPPLY_SUBINVENTORY",
               "A113"."WIP_SUPPLY_LOCATOR_ID" "WIP_SUPPLY_LOCATOR_ID",
               "A113"."OVERCOMPLETION_TOLERANCE_TYPE"
                  "OVERCOMPLETION_TOLERANCE_TYPE",
               "A113"."OVERCOMPLETION_TOLERANCE_VALUE"
                  "OVERCOMPLETION_TOLERANCE_VALUE",
               "A113"."CUSTOMER_ORDER_FLAG" "CUSTOMER_ORDER_FLAG",
               "A113"."CUSTOMER_ORDER_ENABLED_FLAG"
                  "CUSTOMER_ORDER_ENABLED_FLAG",
               "A113"."SHIPPABLE_ITEM_FLAG" "SHIPPABLE_ITEM_FLAG",
               "A113"."INTERNAL_ORDER_FLAG" "INTERNAL_ORDER_FLAG",
               "A113"."INTERNAL_ORDER_ENABLED_FLAG"
                  "INTERNAL_ORDER_ENABLED_FLAG",
               "A113"."SO_TRANSACTIONS_FLAG" "SO_TRANSACTIONS_FLAG",
               "A113"."PICK_COMPONENTS_FLAG" "PICK_COMPONENTS_FLAG",
               "A113"."ATP_FLAG" "ATP_FLAG",
               "A113"."REPLENISH_TO_ORDER_FLAG" "REPLENISH_TO_ORDER_FLAG",
               "A113"."ATP_RULE_ID" "ATP_RULE_ID",
               "A113"."ATP_COMPONENTS_FLAG" "ATP_COMPONENTS_FLAG",
               "A113"."SHIP_MODEL_COMPLETE_FLAG" "SHIP_MODEL_COMPLETE_FLAG",
               "A113"."PICKING_RULE_ID" "PICKING_RULE_ID",
               "A113"."COLLATERAL_FLAG" "COLLATERAL_FLAG",
               "A113"."DEFAULT_SHIPPING_ORG" "DEFAULT_SHIPPING_ORG",
               "A113"."RETURNABLE_FLAG" "RETURNABLE_FLAG",
               "A113"."RETURN_INSPECTION_REQUIREMENT"
                  "RETURN_INSPECTION_REQUIREMENT",
               "A113"."OVER_SHIPMENT_TOLERANCE" "OVER_SHIPMENT_TOLERANCE",
               "A113"."UNDER_SHIPMENT_TOLERANCE" "UNDER_SHIPMENT_TOLERANCE",
               "A113"."OVER_RETURN_TOLERANCE" "OVER_RETURN_TOLERANCE",
               "A113"."UNDER_RETURN_TOLERANCE" "UNDER_RETURN_TOLERANCE",
               "A113"."INVOICEABLE_ITEM_FLAG" "INVOICEABLE_ITEM_FLAG",
               "A113"."INVOICE_ENABLED_FLAG" "INVOICE_ENABLED_FLAG",
               "A113"."ACCOUNTING_RULE_ID" "ACCOUNTING_RULE_ID",
               "A113"."INVOICING_RULE_ID" "INVOICING_RULE_ID",
               "A113"."TAX_CODE" "TAX_CODE",
               "A113"."SALES_ACCOUNT" "SALES_ACCOUNT",
               "A113"."PAYMENT_TERMS_ID" "PAYMENT_TERMS_ID",
               "A113"."SERVICE_ITEM_FLAG" "SERVICE_ITEM_FLAG",
               "A113"."VENDOR_WARRANTY_FLAG" "VENDOR_WARRANTY_FLAG",
               "A113"."COVERAGE_SCHEDULE_ID" "COVERAGE_SCHEDULE_ID",
               "A113"."SERVICE_DURATION" "SERVICE_DURATION",
               "A113"."SERVICE_DURATION_PERIOD_CODE"
                  "SERVICE_DURATION_PERIOD_CODE",
               "A113"."SERVICEABLE_PRODUCT_FLAG" "SERVICEABLE_PRODUCT_FLAG",
               "A113"."SERVICE_STARTING_DELAY" "SERVICE_STARTING_DELAY",
               "A113"."MATERIAL_BILLABLE_FLAG" "MATERIAL_BILLABLE_FLAG",
               "A113"."TIME_BILLABLE_FLAG" "TIME_BILLABLE_FLAG",
               "A113"."EXPENSE_BILLABLE_FLAG" "EXPENSE_BILLABLE_FLAG",
               "A113"."SERVICEABLE_COMPONENT_FLAG"
                  "SERVICEABLE_COMPONENT_FLAG",
               "A113"."PREVENTIVE_MAINTENANCE_FLAG"
                  "PREVENTIVE_MAINTENANCE_FLAG",
               "A113"."PRORATE_SERVICE_FLAG" "PRORATE_SERVICE_FLAG",
               "A113"."SERVICEABLE_ITEM_CLASS_ID" "SERVICEABLE_ITEM_CLASS_ID",
               "A113"."BASE_WARRANTY_SERVICE_ID" "BASE_WARRANTY_SERVICE_ID",
               "A113"."WARRANTY_VENDOR_ID" "WARRANTY_VENDOR_ID",
               "A113"."MAX_WARRANTY_AMOUNT" "MAX_WARRANTY_AMOUNT",
               "A113"."RESPONSE_TIME_PERIOD_CODE" "RESPONSE_TIME_PERIOD_CODE",
               "A113"."RESPONSE_TIME_VALUE" "RESPONSE_TIME_VALUE",
               "A113"."PRIMARY_SPECIALIST_ID" "PRIMARY_SPECIALIST_ID",
               "A113"."SECONDARY_SPECIALIST_ID" "SECONDARY_SPECIALIST_ID",
               "A113"."WH_UPDATE_DATE" "WH_UPDATE_DATE",
               "A113"."SEGMENT1" "SEGMENT1",
               "A113"."SEGMENT2" "SEGMENT2",
               "A113"."SEGMENT3" "SEGMENT3",
               "A113"."SEGMENT4" "SEGMENT4",
               "A113"."SEGMENT5" "SEGMENT5",
               "A113"."SEGMENT6" "SEGMENT6",
               "A113"."SEGMENT7" "SEGMENT7",
               "A113"."SEGMENT8" "SEGMENT8",
               "A113"."SEGMENT9" "SEGMENT9",
               "A113"."SEGMENT10" "SEGMENT10",
               "A113"."SEGMENT11" "SEGMENT11",
               "A113"."SEGMENT12" "SEGMENT12",
               "A113"."SEGMENT13" "SEGMENT13",
               "A113"."SEGMENT14" "SEGMENT14",
               "A113"."SEGMENT15" "SEGMENT15",
               "A113"."SEGMENT16" "SEGMENT16",
               "A113"."SEGMENT17" "SEGMENT17",
               "A113"."SEGMENT18" "SEGMENT18",
               "A113"."SEGMENT19" "SEGMENT19",
               "A113"."SEGMENT20" "SEGMENT20",
               "A113"."SUMMARY_FLAG" "SUMMARY_FLAG",
               "A113"."ENABLED_FLAG" "ENABLED_FLAG",
               "A113"."START_DATE_ACTIVE" "START_DATE_ACTIVE",
               "A113"."END_DATE_ACTIVE" "END_DATE_ACTIVE",
               "A113"."ATTRIBUTE_CATEGORY" "ATTRIBUTE_CATEGORY",
               "A113"."ATTRIBUTE1" "ATTRIBUTE1",
               "A113"."ATTRIBUTE2" "ATTRIBUTE2",
               "A113"."ATTRIBUTE3" "ATTRIBUTE3",
               "A113"."ATTRIBUTE4" "ATTRIBUTE4",
               "A113"."ATTRIBUTE5" "ATTRIBUTE5",
               "A113"."ATTRIBUTE6" "ATTRIBUTE6",
               "A113"."ATTRIBUTE7" "ATTRIBUTE7",
               "A113"."ATTRIBUTE8" "ATTRIBUTE8",
               "A113"."ATTRIBUTE9" "ATTRIBUTE9",
               "A113"."ATTRIBUTE10" "ATTRIBUTE10",
               "A113"."ATTRIBUTE11" "ATTRIBUTE11",
               "A113"."ATTRIBUTE12" "ATTRIBUTE12",
               "A113"."ATTRIBUTE13" "ATTRIBUTE13",
               "A113"."ATTRIBUTE14" "ATTRIBUTE14",
               "A113"."ATTRIBUTE15" "ATTRIBUTE15",
               "A113"."ATTRIBUTE16" "ATTRIBUTE16",
               "A113"."ATTRIBUTE17" "ATTRIBUTE17",
               "A113"."ATTRIBUTE18" "ATTRIBUTE18",
               "A113"."ATTRIBUTE19" "ATTRIBUTE19",
               "A113"."ATTRIBUTE20" "ATTRIBUTE20",
               "A113"."ATTRIBUTE21" "ATTRIBUTE21",
               "A113"."ATTRIBUTE22" "ATTRIBUTE22",
               "A113"."ATTRIBUTE23" "ATTRIBUTE23",
               "A113"."ATTRIBUTE24" "ATTRIBUTE24",
               "A113"."ATTRIBUTE25" "ATTRIBUTE25",
               "A113"."ATTRIBUTE26" "ATTRIBUTE26",
               "A113"."ATTRIBUTE27" "ATTRIBUTE27",
               "A113"."ATTRIBUTE28" "ATTRIBUTE28",
               "A113"."ATTRIBUTE29" "ATTRIBUTE29",
               "A113"."ATTRIBUTE30" "ATTRIBUTE30",
               "A113"."GLOBAL_ATTRIBUTE_CATEGORY" "GLOBAL_ATTRIBUTE_CATEGORY",
               "A113"."GLOBAL_ATTRIBUTE1" "GLOBAL_ATTRIBUTE1",
               "A113"."GLOBAL_ATTRIBUTE2" "GLOBAL_ATTRIBUTE2",
               "A113"."GLOBAL_ATTRIBUTE3" "GLOBAL_ATTRIBUTE3",
               "A113"."GLOBAL_ATTRIBUTE4" "GLOBAL_ATTRIBUTE4",
               "A113"."GLOBAL_ATTRIBUTE5" "GLOBAL_ATTRIBUTE5",
               "A113"."GLOBAL_ATTRIBUTE6" "GLOBAL_ATTRIBUTE6",
               "A113"."GLOBAL_ATTRIBUTE7" "GLOBAL_ATTRIBUTE7",
               "A113"."GLOBAL_ATTRIBUTE8" "GLOBAL_ATTRIBUTE8",
               "A113"."GLOBAL_ATTRIBUTE9" "GLOBAL_ATTRIBUTE9",
               "A113"."GLOBAL_ATTRIBUTE10" "GLOBAL_ATTRIBUTE10",
               "A113"."EQUIPMENT_TYPE" "EQUIPMENT_TYPE",
               "A113"."RECOVERED_PART_DISP_CODE" "RECOVERED_PART_DISP_CODE",
               "A113"."DEFECT_TRACKING_ON_FLAG" "DEFECT_TRACKING_ON_FLAG",
               "A113"."USAGE_ITEM_FLAG" "USAGE_ITEM_FLAG",
               "A113"."EVENT_FLAG" "EVENT_FLAG",
               "A113"."ELECTRONIC_FLAG" "ELECTRONIC_FLAG",
               "A113"."DOWNLOADABLE_FLAG" "DOWNLOADABLE_FLAG",
               "A113"."VOL_DISCOUNT_EXEMPT_FLAG" "VOL_DISCOUNT_EXEMPT_FLAG",
               "A113"."COUPON_EXEMPT_FLAG" "COUPON_EXEMPT_FLAG",
               "A113"."COMMS_NL_TRACKABLE_FLAG" "COMMS_NL_TRACKABLE_FLAG",
               "A113"."ASSET_CREATION_CODE" "ASSET_CREATION_CODE",
               "A113"."COMMS_ACTIVATION_REQD_FLAG"
                  "COMMS_ACTIVATION_REQD_FLAG",
               "A113"."ORDERABLE_ON_WEB_FLAG" "ORDERABLE_ON_WEB_FLAG",
               "A113"."BACK_ORDERABLE_FLAG" "BACK_ORDERABLE_FLAG",
               "A113"."WEB_STATUS" "WEB_STATUS",
               "A113"."INDIVISIBLE_FLAG" "INDIVISIBLE_FLAG",
               "A113"."DIMENSION_UOM_CODE" "DIMENSION_UOM_CODE",
               "A113"."UNIT_LENGTH" "UNIT_LENGTH",
               "A113"."UNIT_WIDTH" "UNIT_WIDTH",
               "A113"."UNIT_HEIGHT" "UNIT_HEIGHT",
               "A113"."BULK_PICKED_FLAG" "BULK_PICKED_FLAG",
               "A113"."LOT_STATUS_ENABLED" "LOT_STATUS_ENABLED",
               "A113"."DEFAULT_LOT_STATUS_ID" "DEFAULT_LOT_STATUS_ID",
               "A113"."SERIAL_STATUS_ENABLED" "SERIAL_STATUS_ENABLED",
               "A113"."DEFAULT_SERIAL_STATUS_ID" "DEFAULT_SERIAL_STATUS_ID",
               "A113"."LOT_SPLIT_ENABLED" "LOT_SPLIT_ENABLED",
               "A113"."LOT_MERGE_ENABLED" "LOT_MERGE_ENABLED",
               "A113"."INVENTORY_CARRY_PENALTY" "INVENTORY_CARRY_PENALTY",
               "A113"."OPERATION_SLACK_PENALTY" "OPERATION_SLACK_PENALTY",
               "A113"."FINANCING_ALLOWED_FLAG" "FINANCING_ALLOWED_FLAG",
               "A113"."EAM_ITEM_TYPE" "EAM_ITEM_TYPE",
               "A113"."EAM_ACTIVITY_TYPE_CODE" "EAM_ACTIVITY_TYPE_CODE",
               "A113"."EAM_ACTIVITY_CAUSE_CODE" "EAM_ACTIVITY_CAUSE_CODE",
               "A113"."EAM_ACT_NOTIFICATION_FLAG" "EAM_ACT_NOTIFICATION_FLAG",
               "A113"."EAM_ACT_SHUTDOWN_STATUS" "EAM_ACT_SHUTDOWN_STATUS",
               "A113"."DUAL_UOM_CONTROL" "DUAL_UOM_CONTROL",
               "A113"."SECONDARY_UOM_CODE" "SECONDARY_UOM_CODE",
               "A113"."DUAL_UOM_DEVIATION_HIGH" "DUAL_UOM_DEVIATION_HIGH",
               "A113"."DUAL_UOM_DEVIATION_LOW" "DUAL_UOM_DEVIATION_LOW",
               "A113"."CONTRACT_ITEM_TYPE_CODE" "CONTRACT_ITEM_TYPE_CODE",
               "A113"."SUBSCRIPTION_DEPEND_FLAG" "SUBSCRIPTION_DEPEND_FLAG",
               "A113"."SERV_REQ_ENABLED_CODE" "SERV_REQ_ENABLED_CODE",
               "A113"."SERV_BILLING_ENABLED_FLAG" "SERV_BILLING_ENABLED_FLAG",
               "A113"."SERV_IMPORTANCE_LEVEL" "SERV_IMPORTANCE_LEVEL",
               "A113"."PLANNED_INV_POINT_FLAG" "PLANNED_INV_POINT_FLAG",
               "A113"."LOT_TRANSLATE_ENABLED" "LOT_TRANSLATE_ENABLED",
               "A113"."DEFAULT_SO_SOURCE_TYPE" "DEFAULT_SO_SOURCE_TYPE",
               "A113"."CREATE_SUPPLY_FLAG" "CREATE_SUPPLY_FLAG",
               "A113"."SUBSTITUTION_WINDOW_CODE" "SUBSTITUTION_WINDOW_CODE",
               "A113"."SUBSTITUTION_WINDOW_DAYS" "SUBSTITUTION_WINDOW_DAYS",
               "A113"."IB_ITEM_INSTANCE_CLASS" "IB_ITEM_INSTANCE_CLASS",
               "A113"."CONFIG_MODEL_TYPE" "CONFIG_MODEL_TYPE",
               "A113"."LOT_SUBSTITUTION_ENABLED" "LOT_SUBSTITUTION_ENABLED",
               "A113"."MINIMUM_LICENSE_QUANTITY" "MINIMUM_LICENSE_QUANTITY",
               "A113"."EAM_ACTIVITY_SOURCE_CODE" "EAM_ACTIVITY_SOURCE_CODE",
               "A113"."LIFECYCLE_ID" "LIFECYCLE_ID",
               "A113"."CURRENT_PHASE_ID" "CURRENT_PHASE_ID",
               "A113"."OBJECT_VERSION_NUMBER" "OBJECT_VERSION_NUMBER",
               "A113"."TRACKING_QUANTITY_IND" "TRACKING_QUANTITY_IND",
               "A113"."ONT_PRICING_QTY_SOURCE" "ONT_PRICING_QTY_SOURCE",
               "A113"."SECONDARY_DEFAULT_IND" "SECONDARY_DEFAULT_IND",
               "A113"."OPTION_SPECIFIC_SOURCED" "OPTION_SPECIFIC_SOURCED",
               "A113"."APPROVAL_STATUS" "APPROVAL_STATUS",
               "A113"."VMI_MINIMUM_UNITS" "VMI_MINIMUM_UNITS",
               "A113"."VMI_MINIMUM_DAYS" "VMI_MINIMUM_DAYS",
               "A113"."VMI_MAXIMUM_UNITS" "VMI_MAXIMUM_UNITS",
               "A113"."VMI_MAXIMUM_DAYS" "VMI_MAXIMUM_DAYS",
               "A113"."VMI_FIXED_ORDER_QUANTITY" "VMI_FIXED_ORDER_QUANTITY",
               "A113"."SO_AUTHORIZATION_FLAG" "SO_AUTHORIZATION_FLAG",
               "A113"."CONSIGNED_FLAG" "CONSIGNED_FLAG",
               "A113"."ASN_AUTOEXPIRE_FLAG" "ASN_AUTOEXPIRE_FLAG",
               "A113"."VMI_FORECAST_TYPE" "VMI_FORECAST_TYPE",
               "A113"."FORECAST_HORIZON" "FORECAST_HORIZON",
               "A113"."EXCLUDE_FROM_BUDGET_FLAG" "EXCLUDE_FROM_BUDGET_FLAG",
               "A113"."DAYS_TGT_INV_SUPPLY" "DAYS_TGT_INV_SUPPLY",
               "A113"."DAYS_TGT_INV_WINDOW" "DAYS_TGT_INV_WINDOW",
               "A113"."DAYS_MAX_INV_SUPPLY" "DAYS_MAX_INV_SUPPLY",
               "A113"."DAYS_MAX_INV_WINDOW" "DAYS_MAX_INV_WINDOW",
               "A113"."DRP_PLANNED_FLAG" "DRP_PLANNED_FLAG",
               "A113"."CRITICAL_COMPONENT_FLAG" "CRITICAL_COMPONENT_FLAG",
               "A113"."CONTINOUS_TRANSFER" "CONTINOUS_TRANSFER",
               "A113"."CONVERGENCE" "CONVERGENCE",
               "A113"."DIVERGENCE" "DIVERGENCE",
               "A113"."CONFIG_ORGS" "CONFIG_ORGS",
               "A113"."CONFIG_MATCH" "CONFIG_MATCH",
               "A113"."CREATION_DATE" "CREATION_DATE",
               "A113"."CREATED_BY" "CREATED_BY",
               "A113"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
               "A113"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
               "A113"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
               "A113"."REQUEST_ID" "REQUEST_ID",
               "A113"."PROGRAM_APPLICATION_ID" "PROGRAM_APPLICATION_ID",
               "A113"."PROGRAM_ID" "PROGRAM_ID",
               "A113"."PROGRAM_UPDATE_DATE" "PROGRAM_UPDATE_DATE",
               "A114"."DESCRIPTION" "DESCRIPTION",
               "A114"."LONG_DESCRIPTION" "LONG_DESCRIPTION",
               "A113"."CONCATENATED_SEGMENTS" "CONCATENATED_SEGMENTS",
               "A113"."PADDED_CONCATENATED_SEGMENTS"
                  "PADDED_CONCATENATED_SEGMENTS",
               "A113"."LOT_DIVISIBLE_FLAG" "LOT_DIVISIBLE_FLAG",
               "A113"."GRADE_CONTROL_FLAG" "GRADE_CONTROL_FLAG",
               "A113"."DEFAULT_GRADE" "DEFAULT_GRADE",
               "A113"."CHILD_LOT_FLAG" "CHILD_LOT_FLAG",
               "A113"."PARENT_CHILD_GENERATION_FLAG"
                  "PARENT_CHILD_GENERATION_FLAG",
               "A113"."CHILD_LOT_PREFIX" "CHILD_LOT_PREFIX",
               "A113"."CHILD_LOT_STARTING_NUMBER" "CHILD_LOT_STARTING_NUMBER",
               "A113"."CHILD_LOT_VALIDATION_FLAG" "CHILD_LOT_VALIDATION_FLAG",
               "A113"."COPY_LOT_ATTRIBUTE_FLAG" "COPY_LOT_ATTRIBUTE_FLAG",
               "A113"."RECIPE_ENABLED_FLAG" "RECIPE_ENABLED_FLAG",
               "A113"."PROCESS_COSTING_ENABLED_FLAG"
                  "PROCESS_COSTING_ENABLED_FLAG",
               "A113"."RETEST_INTERVAL" "RETEST_INTERVAL",
               "A113"."EXPIRATION_ACTION_INTERVAL"
                  "EXPIRATION_ACTION_INTERVAL",
               "A113"."EXPIRATION_ACTION_CODE" "EXPIRATION_ACTION_CODE",
               "A113"."MATURITY_DAYS" "MATURITY_DAYS",
               "A113"."HOLD_DAYS" "HOLD_DAYS",
               "A113"."PROCESS_QUALITY_ENABLED_FLAG"
                  "PROCESS_QUALITY_ENABLED_FLAG",
               "A113"."PROCESS_EXECUTION_ENABLED_FLAG"
                  "PROCESS_EXECUTION_ENABLED_FLAG",
               "A113"."PROCESS_SUPPLY_SUBINVENTORY"
                  "PROCESS_SUPPLY_SUBINVENTORY",
               "A113"."PROCESS_SUPPLY_LOCATOR_ID" "PROCESS_SUPPLY_LOCATOR_ID",
               "A113"."PROCESS_YIELD_SUBINVENTORY"
                  "PROCESS_YIELD_SUBINVENTORY",
               "A113"."PROCESS_YIELD_LOCATOR_ID" "PROCESS_YIELD_LOCATOR_ID",
               "A113"."HAZARDOUS_MATERIAL_FLAG" "HAZARDOUS_MATERIAL_FLAG",
               "A113"."CAS_NUMBER" "CAS_NUMBER",
               "A113"."CHARGE_PERIODICITY_CODE" "CHARGE_PERIODICITY_CODE",
               "A113"."REPAIR_LEADTIME" "REPAIR_LEADTIME",
               "A113"."REPAIR_YIELD" "REPAIR_YIELD",
               "A113"."PREPOSITION_POINT" "PREPOSITION_POINT",
               "A113"."REPAIR_PROGRAM" "REPAIR_PROGRAM",
               "A113"."SUBCONTRACTING_COMPONENT" "SUBCONTRACTING_COMPONENT",
               "A113"."OUTSOURCED_ASSEMBLY" "OUTSOURCED_ASSEMBLY",
               "A113"."GDSN_OUTBOUND_ENABLED_FLAG"
                  "GDSN_OUTBOUND_ENABLED_FLAG",
               "A113"."TRADE_ITEM_DESCRIPTOR" "TRADE_ITEM_DESCRIPTOR",
               "A113"."STYLE_ITEM_ID" "STYLE_ITEM_ID",
               "A113"."STYLE_ITEM_FLAG" "STYLE_ITEM_FLAG",
               "A113"."LAST_SUBMITTED_NIR_ID" "LAST_SUBMITTED_NIR_ID",
               "A113"."GLOBAL_ATTRIBUTE11" "GLOBAL_ATTRIBUTE11",
               "A113"."GLOBAL_ATTRIBUTE12" "GLOBAL_ATTRIBUTE12",
               "A113"."GLOBAL_ATTRIBUTE13" "GLOBAL_ATTRIBUTE13",
               "A113"."GLOBAL_ATTRIBUTE14" "GLOBAL_ATTRIBUTE14",
               "A113"."GLOBAL_ATTRIBUTE15" "GLOBAL_ATTRIBUTE15",
               "A113"."GLOBAL_ATTRIBUTE16" "GLOBAL_ATTRIBUTE16",
               "A113"."GLOBAL_ATTRIBUTE17" "GLOBAL_ATTRIBUTE17",
               "A113"."GLOBAL_ATTRIBUTE18" "GLOBAL_ATTRIBUTE18",
               "A113"."GLOBAL_ATTRIBUTE19" "GLOBAL_ATTRIBUTE19",
               "A113"."GLOBAL_ATTRIBUTE20" "GLOBAL_ATTRIBUTE20",
               "A113"."SERIAL_TAGGING_FLAG" "SERIAL_TAGGING_FLAG",
               "A113"."EGO_MASTER_ITEMS_DFF_CTX" "EGO_MASTER_ITEMS_DFF_CTX",
               "A113"."DEFAULT_MATERIAL_STATUS_ID"
                  "DEFAULT_MATERIAL_STATUS_ID",
               "A113"."IB_ITEM_TRACKING_LEVEL" "IB_ITEM_TRACKING_LEVEL",
               "A113"."MCC_CLASSIFICATION_TYPE" "MCC_CLASSIFICATION_TYPE",
               "A113"."MCC_CONTROL_CODE" "MCC_CONTROL_CODE",
               "A113"."MCC_TRACKING_CODE" "MCC_TRACKING_CODE",
               "A113"."GLOBAL_ATTRIBUTE21" "GLOBAL_ATTRIBUTE21",
               "A113"."GLOBAL_ATTRIBUTE22" "GLOBAL_ATTRIBUTE22",
               "A113"."GLOBAL_ATTRIBUTE23" "GLOBAL_ATTRIBUTE23",
               "A113"."GLOBAL_ATTRIBUTE24" "GLOBAL_ATTRIBUTE24",
               "A113"."GLOBAL_ATTRIBUTE25" "GLOBAL_ATTRIBUTE25",
               "A113"."GLOBAL_ATTRIBUTE26" "GLOBAL_ATTRIBUTE26",
               "A113"."GLOBAL_ATTRIBUTE27" "GLOBAL_ATTRIBUTE27",
               "A113"."GLOBAL_ATTRIBUTE28" "GLOBAL_ATTRIBUTE28",
               "A113"."GLOBAL_ATTRIBUTE29" "GLOBAL_ATTRIBUTE29",
               "A113"."GLOBAL_ATTRIBUTE30" "GLOBAL_ATTRIBUTE30",
               "A113"."GLOBAL_ATTRIBUTE31" "GLOBAL_ATTRIBUTE31",
               "A113"."GLOBAL_ATTRIBUTE32" "GLOBAL_ATTRIBUTE32",
               "A113"."GLOBAL_ATTRIBUTE33" "GLOBAL_ATTRIBUTE33",
               "A113"."GLOBAL_ATTRIBUTE34" "GLOBAL_ATTRIBUTE34",
               "A113"."GLOBAL_ATTRIBUTE35" "GLOBAL_ATTRIBUTE35",
               "A113"."GLOBAL_ATTRIBUTE36" "GLOBAL_ATTRIBUTE36",
               "A113"."GLOBAL_ATTRIBUTE37" "GLOBAL_ATTRIBUTE37",
               "A113"."GLOBAL_ATTRIBUTE38" "GLOBAL_ATTRIBUTE38",
               "A113"."GLOBAL_ATTRIBUTE39" "GLOBAL_ATTRIBUTE39",
               "A113"."GLOBAL_ATTRIBUTE40" "GLOBAL_ATTRIBUTE40"
          FROM "INV"."MTL_SYSTEM_ITEMS_TL" "A114",
               (SELECT "A115".ROWID "ROW_ID",
                       "A115"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
                       "A115"."ORGANIZATION_ID" "ORGANIZATION_ID",
                       "A115"."SEGMENT1" "CONCATENATED_SEGMENTS",
                       RPAD (NVL ("A115"."SEGMENT1", ' '), 100)
                          "PADDED_CONCATENATED_SEGMENTS",
                       "A115"."OUTSIDE_OPERATION_FLAG"
                          "OUTSIDE_OPERATION_FLAG",
                       "A115"."CHILD_LOT_STARTING_NUMBER"
                          "CHILD_LOT_STARTING_NUMBER",
                       "A115"."DEFAULT_GRADE" "DEFAULT_GRADE",
                       "A115"."ATTRIBUTE30" "ATTRIBUTE30",
                       "A115"."MARKET_PRICE" "MARKET_PRICE",
                       "A115"."SOURCE_ORGANIZATION_ID"
                          "SOURCE_ORGANIZATION_ID",
                       "A115"."GLOBAL_ATTRIBUTE8" "GLOBAL_ATTRIBUTE8",
                       "A115"."DIMENSION_UOM_CODE" "DIMENSION_UOM_CODE",
                       "A115"."PICKING_RULE_ID" "PICKING_RULE_ID",
                       "A115"."OVERCOMPLETION_TOLERANCE_TYPE"
                          "OVERCOMPLETION_TOLERANCE_TYPE",
                       "A115"."SEGMENT14" "SEGMENT14",
                       "A115"."RECEIVE_CLOSE_TOLERANCE"
                          "RECEIVE_CLOSE_TOLERANCE",
                       "A115"."OPTION_SPECIFIC_SOURCED"
                          "OPTION_SPECIFIC_SOURCED",
                       "A115"."VMI_MINIMUM_UNITS" "VMI_MINIMUM_UNITS",
                       "A115"."GLOBAL_ATTRIBUTE28" "GLOBAL_ATTRIBUTE28",
                       "A115"."DEFECT_TRACKING_ON_FLAG"
                          "DEFECT_TRACKING_ON_FLAG",
                       "A115"."FULL_LEAD_TIME" "FULL_LEAD_TIME",
                       "A115"."UNIT_OF_ISSUE" "UNIT_OF_ISSUE",
                       "A115"."GLOBAL_ATTRIBUTE25" "GLOBAL_ATTRIBUTE25",
                       "A115"."SERVICE_STARTING_DELAY"
                          "SERVICE_STARTING_DELAY",
                       "A115"."GLOBAL_ATTRIBUTE_CATEGORY"
                          "GLOBAL_ATTRIBUTE_CATEGORY",
                       "A115"."PURCHASING_TAX_CODE" "PURCHASING_TAX_CODE",
                       "A115"."OBJECT_VERSION_NUMBER" "OBJECT_VERSION_NUMBER",
                       "A115"."RESPONSE_TIME_VALUE" "RESPONSE_TIME_VALUE",
                       "A115"."INVOICEABLE_ITEM_FLAG" "INVOICEABLE_ITEM_FLAG",
                       "A115"."CHILD_LOT_PREFIX" "CHILD_LOT_PREFIX",
                       "A115"."GLOBAL_ATTRIBUTE34" "GLOBAL_ATTRIBUTE34",
                       "A115"."DEFAULT_SERIAL_STATUS_ID"
                          "DEFAULT_SERIAL_STATUS_ID",
                       "A115"."ATTRIBUTE18" "ATTRIBUTE18",
                       "A115"."FINANCING_ALLOWED_FLAG"
                          "FINANCING_ALLOWED_FLAG",
                       "A115"."DAYS_TGT_INV_SUPPLY" "DAYS_TGT_INV_SUPPLY",
                       "A115"."SEGMENT7" "SEGMENT7",
                       "A115"."SEGMENT12" "SEGMENT12",
                       "A115"."ACCEPTABLE_EARLY_DAYS" "ACCEPTABLE_EARLY_DAYS",
                       "A115"."PRIMARY_UNIT_OF_MEASURE"
                          "PRIMARY_UNIT_OF_MEASURE",
                       "A115"."MIN_MINMAX_QUANTITY" "MIN_MINMAX_QUANTITY",
                       "A115"."RECIPE_ENABLED_FLAG" "RECIPE_ENABLED_FLAG",
                       "A115"."ITEM_CATALOG_GROUP_ID" "ITEM_CATALOG_GROUP_ID",
                       "A115"."PLANNING_EXCEPTION_SET"
                          "PLANNING_EXCEPTION_SET",
                       "A115"."PREPOSITION_POINT" "PREPOSITION_POINT",
                       "A115"."SEGMENT5" "SEGMENT5",
                       "A115"."SO_AUTHORIZATION_FLAG" "SO_AUTHORIZATION_FLAG",
                       "A115"."DAYS_LATE_RECEIPT_ALLOWED"
                          "DAYS_LATE_RECEIPT_ALLOWED",
                       "A115"."PICK_COMPONENTS_FLAG" "PICK_COMPONENTS_FLAG",
                       "A115"."GLOBAL_ATTRIBUTE22" "GLOBAL_ATTRIBUTE22",
                       "A115"."DOWNLOADABLE_FLAG" "DOWNLOADABLE_FLAG",
                       "A115"."LOT_CONTROL_CODE" "LOT_CONTROL_CODE",
                       "A115"."RETURN_INSPECTION_REQUIREMENT"
                          "RETURN_INSPECTION_REQUIREMENT",
                       "A115"."DUAL_UOM_DEVIATION_LOW"
                          "DUAL_UOM_DEVIATION_LOW",
                       "A115"."ROUNDING_FACTOR" "ROUNDING_FACTOR",
                       "A115"."ROUNDING_CONTROL_TYPE" "ROUNDING_CONTROL_TYPE",
                       "A115"."GLOBAL_ATTRIBUTE35" "GLOBAL_ATTRIBUTE35",
                       "A115"."GLOBAL_ATTRIBUTE37" "GLOBAL_ATTRIBUTE37",
                       "A115"."END_DATE_ACTIVE" "END_DATE_ACTIVE",
                       "A115"."PLANNING_TIME_FENCE_DAYS"
                          "PLANNING_TIME_FENCE_DAYS",
                       "A115"."EFFECTIVITY_CONTROL" "EFFECTIVITY_CONTROL",
                       "A115"."ATTRIBUTE26" "ATTRIBUTE26",
                       "A115"."POSTPROCESSING_LEAD_TIME"
                          "POSTPROCESSING_LEAD_TIME",
                       "A115"."PRIMARY_SPECIALIST_ID" "PRIMARY_SPECIALIST_ID",
                       "A115"."COVERAGE_SCHEDULE_ID" "COVERAGE_SCHEDULE_ID",
                       "A115"."QTY_RCV_EXCEPTION_CODE"
                          "QTY_RCV_EXCEPTION_CODE",
                       "A115"."MCC_CONTROL_CODE" "MCC_CONTROL_CODE",
                       "A115"."SEGMENT13" "SEGMENT13",
                       "A115"."AUTO_SERIAL_ALPHA_PREFIX"
                          "AUTO_SERIAL_ALPHA_PREFIX",
                       "A115"."SHIP_MODEL_COMPLETE_FLAG"
                          "SHIP_MODEL_COMPLETE_FLAG",
                       "A115"."GLOBAL_ATTRIBUTE1" "GLOBAL_ATTRIBUTE1",
                       "A115"."MAXIMUM_LOAD_WEIGHT" "MAXIMUM_LOAD_WEIGHT",
                       "A115"."VMI_MAXIMUM_UNITS" "VMI_MAXIMUM_UNITS",
                       "A115"."SERVICEABLE_COMPONENT_FLAG"
                          "SERVICEABLE_COMPONENT_FLAG",
                       "A115"."INVENTORY_PLANNING_CODE"
                          "INVENTORY_PLANNING_CODE",
                       "A115"."GLOBAL_ATTRIBUTE6" "GLOBAL_ATTRIBUTE6",
                       "A115"."MUST_USE_APPROVED_VENDOR_FLAG"
                          "MUST_USE_APPROVED_VENDOR_FLAG",
                       "A115"."MODEL_CONFIG_CLAUSE_NAME"
                          "MODEL_CONFIG_CLAUSE_NAME",
                       "A115"."OVERCOMPLETION_TOLERANCE_VALUE"
                          "OVERCOMPLETION_TOLERANCE_VALUE",
                       "A115"."GLOBAL_ATTRIBUTE16" "GLOBAL_ATTRIBUTE16",
                       "A115"."RESERVABLE_TYPE" "RESERVABLE_TYPE",
                       "A115"."SEGMENT19" "SEGMENT19",
                       "A115"."MINIMUM_ORDER_QUANTITY"
                          "MINIMUM_ORDER_QUANTITY",
                       "A115"."DUAL_UOM_CONTROL" "DUAL_UOM_CONTROL",
                       "A115"."ENFORCE_SHIP_TO_LOCATION_CODE"
                          "ENFORCE_SHIP_TO_LOCATION_CODE",
                       "A115"."CARRYING_COST" "CARRYING_COST",
                       "A115"."AUTO_LOT_ALPHA_PREFIX" "AUTO_LOT_ALPHA_PREFIX",
                       "A115"."SUBSCRIPTION_DEPEND_FLAG"
                          "SUBSCRIPTION_DEPEND_FLAG",
                       "A115"."SEGMENT6" "SEGMENT6",
                       "A115"."GLOBAL_ATTRIBUTE33" "GLOBAL_ATTRIBUTE33",
                       "A115"."PLANNER_CODE" "PLANNER_CODE",
                       "A115"."TIME_BILLABLE_FLAG" "TIME_BILLABLE_FLAG",
                       "A115"."ATTRIBUTE28" "ATTRIBUTE28",
                       "A115"."GLOBAL_ATTRIBUTE21" "GLOBAL_ATTRIBUTE21",
                       "A115"."EXCLUDE_FROM_BUDGET_FLAG"
                          "EXCLUDE_FROM_BUDGET_FLAG",
                       "A115"."EXPIRATION_ACTION_INTERVAL"
                          "EXPIRATION_ACTION_INTERVAL",
                       "A115"."COMMS_NL_TRACKABLE_FLAG"
                          "COMMS_NL_TRACKABLE_FLAG",
                       "A115"."ATTRIBUTE5" "ATTRIBUTE5",
                       "A115"."SEGMENT17" "SEGMENT17",
                       "A115"."AUTO_REDUCE_MPS" "AUTO_REDUCE_MPS",
                       "A115"."LOT_STATUS_ENABLED" "LOT_STATUS_ENABLED",
                       "A115"."SECONDARY_SPECIALIST_ID"
                          "SECONDARY_SPECIALIST_ID",
                       "A115"."CHECK_SHORTAGES_FLAG" "CHECK_SHORTAGES_FLAG",
                       "A115"."MRP_CALCULATE_ATP_FLAG"
                          "MRP_CALCULATE_ATP_FLAG",
                       "A115"."NEGATIVE_MEASUREMENT_ERROR"
                          "NEGATIVE_MEASUREMENT_ERROR",
                       "A115"."EQUIPMENT_TYPE" "EQUIPMENT_TYPE",
                       "A115"."SUBSTITUTION_WINDOW_CODE"
                          "SUBSTITUTION_WINDOW_CODE",
                       "A115"."ATTRIBUTE27" "ATTRIBUTE27",
                       "A115"."EGO_MASTER_ITEMS_DFF_CTX"
                          "EGO_MASTER_ITEMS_DFF_CTX",
                       "A115"."STOCK_ENABLED_FLAG" "STOCK_ENABLED_FLAG",
                       "A115"."ALLOW_ITEM_DESC_UPDATE_FLAG"
                          "ALLOW_ITEM_DESC_UPDATE_FLAG",
                       "A115"."PREVENTIVE_MAINTENANCE_FLAG"
                          "PREVENTIVE_MAINTENANCE_FLAG",
                       "A115"."ATTRIBUTE15" "ATTRIBUTE15",
                       "A115"."REVISION_QTY_CONTROL_CODE"
                          "REVISION_QTY_CONTROL_CODE",
                       "A115"."START_AUTO_LOT_NUMBER" "START_AUTO_LOT_NUMBER",
                       "A115"."DRP_PLANNED_FLAG" "DRP_PLANNED_FLAG",
                       "A115"."COST_OF_SALES_ACCOUNT" "COST_OF_SALES_ACCOUNT",
                       "A115"."GDSN_OUTBOUND_ENABLED_FLAG"
                          "GDSN_OUTBOUND_ENABLED_FLAG",
                       "A115"."ATP_FLAG" "ATP_FLAG",
                       "A115"."TAXABLE_FLAG" "TAXABLE_FLAG",
                       "A115"."LOCATION_CONTROL_CODE" "LOCATION_CONTROL_CODE",
                       "A115"."CAS_NUMBER" "CAS_NUMBER",
                       "A115"."HOLD_DAYS" "HOLD_DAYS",
                       "A115"."TRADE_ITEM_DESCRIPTOR" "TRADE_ITEM_DESCRIPTOR",
                       "A115"."HAZARD_CLASS_ID" "HAZARD_CLASS_ID",
                       "A115"."UNDER_SHIPMENT_TOLERANCE"
                          "UNDER_SHIPMENT_TOLERANCE",
                       "A115"."SOURCE_SUBINVENTORY" "SOURCE_SUBINVENTORY",
                       "A115"."MINIMUM_FILL_PERCENT" "MINIMUM_FILL_PERCENT",
                       "A115"."OVER_RETURN_TOLERANCE" "OVER_RETURN_TOLERANCE",
                       "A115"."CUMULATIVE_TOTAL_LEAD_TIME"
                          "CUMULATIVE_TOTAL_LEAD_TIME",
                       "A115"."GLOBAL_ATTRIBUTE27" "GLOBAL_ATTRIBUTE27",
                       "A115"."ATTRIBUTE22" "ATTRIBUTE22",
                       "A115"."INVENTORY_ITEM_FLAG" "INVENTORY_ITEM_FLAG",
                       "A115"."EXPIRATION_ACTION_CODE"
                          "EXPIRATION_ACTION_CODE",
                       "A115"."MRP_PLANNING_CODE" "MRP_PLANNING_CODE",
                       "A115"."ATTRIBUTE11" "ATTRIBUTE11",
                       "A115"."CONTRACT_ITEM_TYPE_CODE"
                          "CONTRACT_ITEM_TYPE_CODE",
                       "A115"."ATTRIBUTE29" "ATTRIBUTE29",
                       "A115"."USAGE_ITEM_FLAG" "USAGE_ITEM_FLAG",
                       "A115"."MAXIMUM_ORDER_QUANTITY"
                          "MAXIMUM_ORDER_QUANTITY",
                       "A115"."GLOBAL_ATTRIBUTE36" "GLOBAL_ATTRIBUTE36",
                       "A115"."RESPONSE_TIME_PERIOD_CODE"
                          "RESPONSE_TIME_PERIOD_CODE",
                       "A115"."NEW_REVISION_CODE" "NEW_REVISION_CODE",
                       "A115"."CURRENT_PHASE_ID" "CURRENT_PHASE_ID",
                       "A115"."RECEIVING_ROUTING_ID" "RECEIVING_ROUTING_ID",
                       "A115"."VEHICLE_ITEM_FLAG" "VEHICLE_ITEM_FLAG",
                       "A115"."GLOBAL_ATTRIBUTE3" "GLOBAL_ATTRIBUTE3",
                       "A115"."ATTRIBUTE3" "ATTRIBUTE3",
                       "A115"."GLOBAL_ATTRIBUTE26" "GLOBAL_ATTRIBUTE26",
                       "A115"."GLOBAL_ATTRIBUTE18" "GLOBAL_ATTRIBUTE18",
                       "A115"."DEMAND_TIME_FENCE_CODE"
                          "DEMAND_TIME_FENCE_CODE",
                       "A115"."ATTRIBUTE24" "ATTRIBUTE24",
                       "A115"."PROCESS_COSTING_ENABLED_FLAG"
                          "PROCESS_COSTING_ENABLED_FLAG",
                       "A115"."CYCLE_COUNT_ENABLED_FLAG"
                          "CYCLE_COUNT_ENABLED_FLAG",
                       "A115"."INVENTORY_CARRY_PENALTY"
                          "INVENTORY_CARRY_PENALTY",
                       "A115"."ENABLED_FLAG" "ENABLED_FLAG",
                       "A115"."BACK_ORDERABLE_FLAG" "BACK_ORDERABLE_FLAG",
                       "A115"."LOT_MERGE_ENABLED" "LOT_MERGE_ENABLED",
                       "A115"."CATALOG_STATUS_FLAG" "CATALOG_STATUS_FLAG",
                       "A115"."FIXED_ORDER_QUANTITY" "FIXED_ORDER_QUANTITY",
                       "A115"."FORECAST_HORIZON" "FORECAST_HORIZON",
                       "A115"."BASE_WARRANTY_SERVICE_ID"
                          "BASE_WARRANTY_SERVICE_ID",
                       "A115"."SERVICE_DURATION" "SERVICE_DURATION",
                       "A115"."LOT_DIVISIBLE_FLAG" "LOT_DIVISIBLE_FLAG",
                       "A115"."INVOICE_ENABLED_FLAG" "INVOICE_ENABLED_FLAG",
                       "A115"."ATTRIBUTE8" "ATTRIBUTE8",
                       "A115"."OVERRUN_PERCENTAGE" "OVERRUN_PERCENTAGE",
                       "A115"."ATTRIBUTE7" "ATTRIBUTE7",
                       "A115"."ATTRIBUTE13" "ATTRIBUTE13",
                       "A115"."SALES_ACCOUNT" "SALES_ACCOUNT",
                       "A115"."MRP_SAFETY_STOCK_PERCENT"
                          "MRP_SAFETY_STOCK_PERCENT",
                       "A115"."OUTSOURCED_ASSEMBLY" "OUTSOURCED_ASSEMBLY",
                       "A115"."CREATED_BY" "CREATED_BY",
                       "A115"."MRP_SAFETY_STOCK_CODE" "MRP_SAFETY_STOCK_CODE",
                       "A115"."PROCESS_EXECUTION_ENABLED_FLAG"
                          "PROCESS_EXECUTION_ENABLED_FLAG",
                       "A115"."WARRANTY_VENDOR_ID" "WARRANTY_VENDOR_ID",
                       "A115"."GLOBAL_ATTRIBUTE5" "GLOBAL_ATTRIBUTE5",
                       "A115"."CUSTOMER_ORDER_ENABLED_FLAG"
                          "CUSTOMER_ORDER_ENABLED_FLAG",
                       "A115"."CRITICAL_COMPONENT_FLAG"
                          "CRITICAL_COMPONENT_FLAG",
                       "A115"."ATTRIBUTE19" "ATTRIBUTE19",
                       "A115"."GRADE_CONTROL_FLAG" "GRADE_CONTROL_FLAG",
                       "A115"."PROCESS_YIELD_SUBINVENTORY"
                          "PROCESS_YIELD_SUBINVENTORY",
                       "A115"."SEGMENT3" "SEGMENT3",
                       "A115"."SERVICEABLE_ITEM_CLASS_ID"
                          "SERVICEABLE_ITEM_CLASS_ID",
                       "A115"."ORDERABLE_ON_WEB_FLAG" "ORDERABLE_ON_WEB_FLAG",
                       "A115"."BULK_PICKED_FLAG" "BULK_PICKED_FLAG",
                       "A115"."SO_TRANSACTIONS_FLAG" "SO_TRANSACTIONS_FLAG",
                       "A115"."DEFAULT_SHIPPING_ORG" "DEFAULT_SHIPPING_ORG",
                       "A115"."GLOBAL_ATTRIBUTE40" "GLOBAL_ATTRIBUTE40",
                       "A115"."GLOBAL_ATTRIBUTE7" "GLOBAL_ATTRIBUTE7",
                       "A115"."END_ASSEMBLY_PEGGING_FLAG"
                          "END_ASSEMBLY_PEGGING_FLAG",
                       "A115"."OVER_SHIPMENT_TOLERANCE"
                          "OVER_SHIPMENT_TOLERANCE",
                       "A115"."GLOBAL_ATTRIBUTE11" "GLOBAL_ATTRIBUTE11",
                       "A115"."SEGMENT11" "SEGMENT11",
                       "A115"."RECEIPT_DAYS_EXCEPTION_CODE"
                          "RECEIPT_DAYS_EXCEPTION_CODE",
                       "A115"."SERIAL_NUMBER_CONTROL_CODE"
                          "SERIAL_NUMBER_CONTROL_CODE",
                       "A115"."SERV_BILLING_ENABLED_FLAG"
                          "SERV_BILLING_ENABLED_FLAG",
                       "A115"."PROGRAM_ID" "PROGRAM_ID",
                       "A115"."PROCESS_QUALITY_ENABLED_FLAG"
                          "PROCESS_QUALITY_ENABLED_FLAG",
                       "A115"."LEAD_TIME_LOT_SIZE" "LEAD_TIME_LOT_SIZE",
                       "A115"."RFQ_REQUIRED_FLAG" "RFQ_REQUIRED_FLAG",
                       "A115"."WIP_SUPPLY_LOCATOR_ID" "WIP_SUPPLY_LOCATOR_ID",
                       "A115"."GLOBAL_ATTRIBUTE29" "GLOBAL_ATTRIBUTE29",
                       "A115"."REQUEST_ID" "REQUEST_ID",
                       "A115"."PRORATE_SERVICE_FLAG" "PRORATE_SERVICE_FLAG",
                       "A115"."WEIGHT_UOM_CODE" "WEIGHT_UOM_CODE",
                       "A115"."PLANNED_INV_POINT_FLAG"
                          "PLANNED_INV_POINT_FLAG",
                       "A115"."RELEASE_TIME_FENCE_DAYS"
                          "RELEASE_TIME_FENCE_DAYS",
                       "A115"."ATTRIBUTE9" "ATTRIBUTE9",
                       "A115"."GLOBAL_ATTRIBUTE24" "GLOBAL_ATTRIBUTE24",
                       "A115"."GLOBAL_ATTRIBUTE9" "GLOBAL_ATTRIBUTE9",
                       "A115"."CONFIG_MATCH" "CONFIG_MATCH",
                       "A115"."REPAIR_YIELD" "REPAIR_YIELD",
                       "A115"."RELEASE_TIME_FENCE_CODE"
                          "RELEASE_TIME_FENCE_CODE",
                       "A115"."DAYS_TGT_INV_WINDOW" "DAYS_TGT_INV_WINDOW",
                       "A115"."RESTRICT_LOCATORS_CODE"
                          "RESTRICT_LOCATORS_CODE",
                       "A115"."LOT_SUBSTITUTION_ENABLED"
                          "LOT_SUBSTITUTION_ENABLED",
                       "A115"."SERVICE_ITEM_FLAG" "SERVICE_ITEM_FLAG",
                       "A115"."PROCESS_SUPPLY_SUBINVENTORY"
                          "PROCESS_SUPPLY_SUBINVENTORY",
                       "A115"."REPETITIVE_PLANNING_FLAG"
                          "REPETITIVE_PLANNING_FLAG",
                       "A115"."PAYMENT_TERMS_ID" "PAYMENT_TERMS_ID",
                       "A115"."GLOBAL_ATTRIBUTE10" "GLOBAL_ATTRIBUTE10",
                       "A115"."CHARGE_PERIODICITY_CODE"
                          "CHARGE_PERIODICITY_CODE",
                       "A115"."DAYS_EARLY_RECEIPT_ALLOWED"
                          "DAYS_EARLY_RECEIPT_ALLOWED",
                       "A115"."WIP_SUPPLY_TYPE" "WIP_SUPPLY_TYPE",
                       "A115"."LOT_SPLIT_ENABLED" "LOT_SPLIT_ENABLED",
                       "A115"."APPROVAL_STATUS" "APPROVAL_STATUS",
                       "A115"."RETEST_INTERVAL" "RETEST_INTERVAL",
                       "A115"."ASSET_CREATION_CODE" "ASSET_CREATION_CODE",
                       "A115"."GLOBAL_ATTRIBUTE20" "GLOBAL_ATTRIBUTE20",
                       "A115"."ATTRIBUTE25" "ATTRIBUTE25",
                       "A115"."SEGMENT20" "SEGMENT20",
                       "A115"."ACCEPTABLE_RATE_DECREASE"
                          "ACCEPTABLE_RATE_DECREASE",
                       "A115"."LOT_TRANSLATE_ENABLED" "LOT_TRANSLATE_ENABLED",
                       "A115"."CREATE_SUPPLY_FLAG" "CREATE_SUPPLY_FLAG",
                       "A115"."HAZARDOUS_MATERIAL_FLAG"
                          "HAZARDOUS_MATERIAL_FLAG",
                       "A115"."BUILD_IN_WIP_FLAG" "BUILD_IN_WIP_FLAG",
                       "A115"."UN_NUMBER_ID" "UN_NUMBER_ID",
                       "A115"."REPAIR_LEADTIME" "REPAIR_LEADTIME",
                       "A115"."PURCHASING_ENABLED_FLAG"
                          "PURCHASING_ENABLED_FLAG",
                       "A115"."RETURNABLE_FLAG" "RETURNABLE_FLAG",
                       "A115"."DEMAND_TIME_FENCE_DAYS"
                          "DEMAND_TIME_FENCE_DAYS",
                       "A115"."ENCUMBRANCE_ACCOUNT" "ENCUMBRANCE_ACCOUNT",
                       "A115"."SEGMENT16" "SEGMENT16",
                       "A115"."OUTSIDE_OPERATION_UOM_TYPE"
                          "OUTSIDE_OPERATION_UOM_TYPE",
                       "A115"."SHELF_LIFE_DAYS" "SHELF_LIFE_DAYS",
                       "A115"."COMMS_ACTIVATION_REQD_FLAG"
                          "COMMS_ACTIVATION_REQD_FLAG",
                       "A115"."SEGMENT9" "SEGMENT9",
                       "A115"."ATTRIBUTE14" "ATTRIBUTE14",
                       "A115"."SEGMENT10" "SEGMENT10",
                       "A115"."VOL_DISCOUNT_EXEMPT_FLAG"
                          "VOL_DISCOUNT_EXEMPT_FLAG",
                       "A115"."BUYER_ID" "BUYER_ID",
                       "A115"."DEFAULT_LOT_STATUS_ID" "DEFAULT_LOT_STATUS_ID",
                       "A115"."SUBSTITUTION_WINDOW_DAYS"
                          "SUBSTITUTION_WINDOW_DAYS",
                       "A115"."SEGMENT2" "SEGMENT2",
                       "A115"."RESTRICT_SUBINVENTORIES_CODE"
                          "RESTRICT_SUBINVENTORIES_CODE",
                       "A115"."FIXED_LOT_MULTIPLIER" "FIXED_LOT_MULTIPLIER",
                       "A115"."EXPENSE_BILLABLE_FLAG" "EXPENSE_BILLABLE_FLAG",
                       "A115"."SOURCE_TYPE" "SOURCE_TYPE",
                       "A115"."WH_UPDATE_DATE" "WH_UPDATE_DATE",
                       "A115"."VMI_MINIMUM_DAYS" "VMI_MINIMUM_DAYS",
                       "A115"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
                       "A115"."CONFIG_ORGS" "CONFIG_ORGS",
                       "A115"."ATTRIBUTE1" "ATTRIBUTE1",
                       "A115"."PURCHASING_ITEM_FLAG" "PURCHASING_ITEM_FLAG",
                       "A115"."SERVICE_DURATION_PERIOD_CODE"
                          "SERVICE_DURATION_PERIOD_CODE",
                       "A115"."MINIMUM_LICENSE_QUANTITY"
                          "MINIMUM_LICENSE_QUANTITY",
                       "A115"."CONFIG_MODEL_TYPE" "CONFIG_MODEL_TYPE",
                       "A115"."SEGMENT8" "SEGMENT8",
                       "A115"."ATTRIBUTE_CATEGORY" "ATTRIBUTE_CATEGORY",
                       "A115"."ENG_ITEM_FLAG" "ENG_ITEM_FLAG",
                       "A115"."QTY_RCV_TOLERANCE" "QTY_RCV_TOLERANCE",
                       "A115"."ONT_PRICING_QTY_SOURCE"
                          "ONT_PRICING_QTY_SOURCE",
                       "A115"."ENGINEERING_DATE" "ENGINEERING_DATE",
                       "A115"."PRICE_TOLERANCE_PERCENT"
                          "PRICE_TOLERANCE_PERCENT",
                       "A115"."DEFAULT_INCLUDE_IN_ROLLUP_FLAG"
                          "DEFAULT_INCLUDE_IN_ROLLUP_FLAG",
                       "A115"."OPERATION_SLACK_PENALTY"
                          "OPERATION_SLACK_PENALTY",
                       "A115"."IB_ITEM_INSTANCE_CLASS"
                          "IB_ITEM_INSTANCE_CLASS",
                       "A115"."SERIAL_TAGGING_FLAG" "SERIAL_TAGGING_FLAG",
                       "A115"."PRIMARY_UOM_CODE" "PRIMARY_UOM_CODE",
                       "A115"."AUTO_CREATED_CONFIG_FLAG"
                          "AUTO_CREATED_CONFIG_FLAG",
                       "A115"."VMI_FIXED_ORDER_QUANTITY"
                          "VMI_FIXED_ORDER_QUANTITY",
                       "A115"."ORDER_COST" "ORDER_COST",
                       "A115"."SECONDARY_DEFAULT_IND" "SECONDARY_DEFAULT_IND",
                       "A115"."SEGMENT4" "SEGMENT4",
                       "A115"."ATTRIBUTE12" "ATTRIBUTE12",
                       "A115"."VOLUME_UOM_CODE" "VOLUME_UOM_CODE",
                       "A115"."SEGMENT15" "SEGMENT15",
                       "A115"."CUM_MANUFACTURING_LEAD_TIME"
                          "CUM_MANUFACTURING_LEAD_TIME",
                       "A115"."CHILD_LOT_VALIDATION_FLAG"
                          "CHILD_LOT_VALIDATION_FLAG",
                       "A115"."START_DATE_ACTIVE" "START_DATE_ACTIVE",
                       "A115"."MATURITY_DAYS" "MATURITY_DAYS",
                       "A115"."SECONDARY_UOM_CODE" "SECONDARY_UOM_CODE",
                       "A115"."ENGINEERING_ECN_CODE" "ENGINEERING_ECN_CODE",
                       "A115"."COLLATERAL_FLAG" "COLLATERAL_FLAG",
                       "A115"."CUSTOMER_ORDER_FLAG" "CUSTOMER_ORDER_FLAG",
                       "A115"."MATERIAL_BILLABLE_FLAG"
                          "MATERIAL_BILLABLE_FLAG",
                       "A115"."ATTRIBUTE10" "ATTRIBUTE10",
                       "A115"."GLOBAL_ATTRIBUTE32" "GLOBAL_ATTRIBUTE32",
                       "A115"."EAM_ACTIVITY_CAUSE_CODE"
                          "EAM_ACTIVITY_CAUSE_CODE",
                       "A115"."ENGINEERING_ITEM_ID" "ENGINEERING_ITEM_ID",
                       "A115"."ITEM_TYPE" "ITEM_TYPE",
                       "A115"."INDIVISIBLE_FLAG" "INDIVISIBLE_FLAG",
                       "A115"."UNIT_WIDTH" "UNIT_WIDTH",
                       "A115"."EAM_ACTIVITY_SOURCE_CODE"
                          "EAM_ACTIVITY_SOURCE_CODE",
                       "A115"."ATTRIBUTE21" "ATTRIBUTE21",
                       "A115"."BASE_ITEM_ID" "BASE_ITEM_ID",
                       "A115"."UNDER_RETURN_TOLERANCE"
                          "UNDER_RETURN_TOLERANCE",
                       "A115"."COPY_LOT_ATTRIBUTE_FLAG"
                          "COPY_LOT_ATTRIBUTE_FLAG",
                       "A115"."CREATION_DATE" "CREATION_DATE",
                       "A115"."ASN_AUTOEXPIRE_FLAG" "ASN_AUTOEXPIRE_FLAG",
                       "A115"."EVENT_FLAG" "EVENT_FLAG",
                       "A115"."WEB_STATUS" "WEB_STATUS",
                       "A115"."SUMMARY_FLAG" "SUMMARY_FLAG",
                       "A115"."START_AUTO_SERIAL_NUMBER"
                          "START_AUTO_SERIAL_NUMBER",
                       "A115"."UNIT_VOLUME" "UNIT_VOLUME",
                       "A115"."LAST_SUBMITTED_NIR_ID" "LAST_SUBMITTED_NIR_ID",
                       "A115"."INTERNAL_ORDER_ENABLED_FLAG"
                          "INTERNAL_ORDER_ENABLED_FLAG",
                       "A115"."INVENTORY_ITEM_STATUS_CODE"
                          "INVENTORY_ITEM_STATUS_CODE",
                       "A115"."GLOBAL_ATTRIBUTE23" "GLOBAL_ATTRIBUTE23",
                       "A115"."GLOBAL_ATTRIBUTE30" "GLOBAL_ATTRIBUTE30",
                       "A115"."SAFETY_STOCK_BUCKET_DAYS"
                          "SAFETY_STOCK_BUCKET_DAYS",
                       "A115"."GLOBAL_ATTRIBUTE13" "GLOBAL_ATTRIBUTE13",
                       "A115"."RECOVERED_PART_DISP_CODE"
                          "RECOVERED_PART_DISP_CODE",
                       "A115"."DIVERGENCE" "DIVERGENCE",
                       "A115"."GLOBAL_ATTRIBUTE15" "GLOBAL_ATTRIBUTE15",
                       "A115"."MCC_TRACKING_CODE" "MCC_TRACKING_CODE",
                       "A115"."STD_LOT_SIZE" "STD_LOT_SIZE",
                       "A115"."CONTINOUS_TRANSFER" "CONTINOUS_TRANSFER",
                       "A115"."RECEIPT_REQUIRED_FLAG" "RECEIPT_REQUIRED_FLAG",
                       "A115"."FIXED_LEAD_TIME" "FIXED_LEAD_TIME",
                       "A115"."GLOBAL_ATTRIBUTE17" "GLOBAL_ATTRIBUTE17",
                       "A115"."SEGMENT1" "SEGMENT1",
                       "A115"."MAX_WARRANTY_AMOUNT" "MAX_WARRANTY_AMOUNT",
                       "A115"."BOM_ENABLED_FLAG" "BOM_ENABLED_FLAG",
                       "A115"."STYLE_ITEM_FLAG" "STYLE_ITEM_FLAG",
                       "A115"."SUBCONTRACTING_COMPONENT"
                          "SUBCONTRACTING_COMPONENT",
                       "A115"."INTERNAL_VOLUME" "INTERNAL_VOLUME",
                       "A115"."INTERNAL_ORDER_FLAG" "INTERNAL_ORDER_FLAG",
                       "A115"."FIXED_DAYS_SUPPLY" "FIXED_DAYS_SUPPLY",
                       "A115"."MCC_CLASSIFICATION_TYPE"
                          "MCC_CLASSIFICATION_TYPE",
                       "A115"."ATTRIBUTE6" "ATTRIBUTE6",
                       "A115"."CONTAINER_TYPE_CODE" "CONTAINER_TYPE_CODE",
                       "A115"."EAM_ACT_SHUTDOWN_STATUS"
                          "EAM_ACT_SHUTDOWN_STATUS",
                       "A115"."CONTAINER_ITEM_FLAG" "CONTAINER_ITEM_FLAG",
                       "A115"."PROCESS_SUPPLY_LOCATOR_ID"
                          "PROCESS_SUPPLY_LOCATOR_ID",
                       "A115"."SERV_REQ_ENABLED_CODE" "SERV_REQ_ENABLED_CODE",
                       "A115"."TRACKING_QUANTITY_IND" "TRACKING_QUANTITY_IND",
                       "A115"."ALLOW_EXPRESS_DELIVERY_FLAG"
                          "ALLOW_EXPRESS_DELIVERY_FLAG",
                       "A115"."ATTRIBUTE16" "ATTRIBUTE16",
                       "A115"."ATTRIBUTE20" "ATTRIBUTE20",
                       "A115"."UNIT_HEIGHT" "UNIT_HEIGHT",
                       "A115"."CONVERGENCE" "CONVERGENCE",
                       "A115"."UNIT_WEIGHT" "UNIT_WEIGHT",
                       "A115"."PREPROCESSING_LEAD_TIME"
                          "PREPROCESSING_LEAD_TIME",
                       "A115"."PROGRAM_APPLICATION_ID"
                          "PROGRAM_APPLICATION_ID",
                       "A115"."VMI_FORECAST_TYPE" "VMI_FORECAST_TYPE",
                       "A115"."SERIAL_STATUS_ENABLED" "SERIAL_STATUS_ENABLED",
                       "A115"."DEFAULT_SO_SOURCE_TYPE"
                          "DEFAULT_SO_SOURCE_TYPE",
                       "A115"."ASSET_CATEGORY_ID" "ASSET_CATEGORY_ID",
                       "A115"."GLOBAL_ATTRIBUTE2" "GLOBAL_ATTRIBUTE2",
                       "A115"."SERV_IMPORTANCE_LEVEL" "SERV_IMPORTANCE_LEVEL",
                       "A115"."ATP_COMPONENTS_FLAG" "ATP_COMPONENTS_FLAG",
                       "A115"."GLOBAL_ATTRIBUTE4" "GLOBAL_ATTRIBUTE4",
                       "A115"."SEGMENT18" "SEGMENT18",
                       "A115"."ATTRIBUTE4" "ATTRIBUTE4",
                       "A115"."EAM_ITEM_TYPE" "EAM_ITEM_TYPE",
                       "A115"."SHIPPABLE_ITEM_FLAG" "SHIPPABLE_ITEM_FLAG",
                       "A115"."SERVICEABLE_PRODUCT_FLAG"
                          "SERVICEABLE_PRODUCT_FLAG",
                       "A115"."EAM_ACT_NOTIFICATION_FLAG"
                          "EAM_ACT_NOTIFICATION_FLAG",
                       "A115"."LIST_PRICE_PER_UNIT" "LIST_PRICE_PER_UNIT",
                       "A115"."GLOBAL_ATTRIBUTE39" "GLOBAL_ATTRIBUTE39",
                       "A115"."INVENTORY_ASSET_FLAG" "INVENTORY_ASSET_FLAG",
                       "A115"."PARENT_CHILD_GENERATION_FLAG"
                          "PARENT_CHILD_GENERATION_FLAG",
                       "A115"."PROGRAM_UPDATE_DATE" "PROGRAM_UPDATE_DATE",
                       "A115"."INSPECTION_REQUIRED_FLAG"
                          "INSPECTION_REQUIRED_FLAG",
                       "A115"."WIP_SUPPLY_SUBINVENTORY"
                          "WIP_SUPPLY_SUBINVENTORY",
                       "A115"."DAYS_MAX_INV_SUPPLY" "DAYS_MAX_INV_SUPPLY",
                       "A115"."ALLOW_UNORDERED_RECEIPTS_FLAG"
                          "ALLOW_UNORDERED_RECEIPTS_FLAG",
                       "A115"."SHELF_LIFE_CODE" "SHELF_LIFE_CODE",
                       "A115"."REPAIR_PROGRAM" "REPAIR_PROGRAM",
                       "A115"."DEFAULT_MATERIAL_STATUS_ID"
                          "DEFAULT_MATERIAL_STATUS_ID",
                       "A115"."GLOBAL_ATTRIBUTE31" "GLOBAL_ATTRIBUTE31",
                       "A115"."VARIABLE_LEAD_TIME" "VARIABLE_LEAD_TIME",
                       "A115"."CHILD_LOT_FLAG" "CHILD_LOT_FLAG",
                       "A115"."ATP_RULE_ID" "ATP_RULE_ID",
                       "A115"."ACCOUNTING_RULE_ID" "ACCOUNTING_RULE_ID",
                       "A115"."UNIT_LENGTH" "UNIT_LENGTH",
                       "A115"."INVOICE_CLOSE_TOLERANCE"
                          "INVOICE_CLOSE_TOLERANCE",
                       "A115"."ACCEPTABLE_RATE_INCREASE"
                          "ACCEPTABLE_RATE_INCREASE",
                       "A115"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                       "A115"."PLANNING_TIME_FENCE_CODE"
                          "PLANNING_TIME_FENCE_CODE",
                       "A115"."PLANNING_MAKE_BUY_CODE"
                          "PLANNING_MAKE_BUY_CODE",
                       "A115"."MAX_MINMAX_QUANTITY" "MAX_MINMAX_QUANTITY",
                       "A115"."GLOBAL_ATTRIBUTE38" "GLOBAL_ATTRIBUTE38",
                       "A115"."COSTING_ENABLED_FLAG" "COSTING_ENABLED_FLAG",
                       "A115"."GLOBAL_ATTRIBUTE19" "GLOBAL_ATTRIBUTE19",
                       "A115"."VENDOR_WARRANTY_FLAG" "VENDOR_WARRANTY_FLAG",
                       "A115"."VMI_MAXIMUM_DAYS" "VMI_MAXIMUM_DAYS",
                       "A115"."CONSIGNED_FLAG" "CONSIGNED_FLAG",
                       "A115"."MTL_TRANSACTIONS_ENABLED_FLAG"
                          "MTL_TRANSACTIONS_ENABLED_FLAG",
                       "A115"."SHRINKAGE_RATE" "SHRINKAGE_RATE",
                       "A115"."ATO_FORECAST_CONTROL" "ATO_FORECAST_CONTROL",
                       "A115"."LIFECYCLE_ID" "LIFECYCLE_ID",
                       "A115"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                       "A115"."ALLOWED_UNITS_LOOKUP_CODE"
                          "ALLOWED_UNITS_LOOKUP_CODE",
                       "A115"."INVOICING_RULE_ID" "INVOICING_RULE_ID",
                       "A115"."REPLENISH_TO_ORDER_FLAG"
                          "REPLENISH_TO_ORDER_FLAG",
                       "A115"."PRODUCT_FAMILY_ITEM_ID"
                          "PRODUCT_FAMILY_ITEM_ID",
                       "A115"."EAM_ACTIVITY_TYPE_CODE"
                          "EAM_ACTIVITY_TYPE_CODE",
                       "A115"."ALLOW_SUBSTITUTE_RECEIPTS_FLAG"
                          "ALLOW_SUBSTITUTE_RECEIPTS_FLAG",
                       "A115"."ELECTRONIC_FLAG" "ELECTRONIC_FLAG",
                       "A115"."DUAL_UOM_DEVIATION_HIGH"
                          "DUAL_UOM_DEVIATION_HIGH",
                       "A115"."ATTRIBUTE17" "ATTRIBUTE17",
                       "A115"."ATTRIBUTE2" "ATTRIBUTE2",
                       "A115"."BOM_ITEM_TYPE" "BOM_ITEM_TYPE",
                       "A115"."IB_ITEM_TRACKING_LEVEL"
                          "IB_ITEM_TRACKING_LEVEL",
                       "A115"."ATTRIBUTE23" "ATTRIBUTE23",
                       "A115"."EXPENSE_ACCOUNT" "EXPENSE_ACCOUNT",
                       "A115"."TAX_CODE" "TAX_CODE",
                       "A115"."GLOBAL_ATTRIBUTE14" "GLOBAL_ATTRIBUTE14",
                       "A115"."GLOBAL_ATTRIBUTE12" "GLOBAL_ATTRIBUTE12",
                       "A115"."STYLE_ITEM_ID" "STYLE_ITEM_ID",
                       "A115"."COUPON_EXEMPT_FLAG" "COUPON_EXEMPT_FLAG",
                       "A115"."PROCESS_YIELD_LOCATOR_ID"
                          "PROCESS_YIELD_LOCATOR_ID",
                       "A115"."DESCRIPTION" "DESCRIPTION",
                       "A115"."POSITIVE_MEASUREMENT_ERROR"
                          "POSITIVE_MEASUREMENT_ERROR",
                       "A115"."DAYS_MAX_INV_WINDOW" "DAYS_MAX_INV_WINDOW"
                  FROM "INV"."MTL_SYSTEM_ITEMS_B" "A115") "A113"
         WHERE     "A113"."INVENTORY_ITEM_ID" = "A114"."INVENTORY_ITEM_ID"
               AND "A113"."ORGANIZATION_ID" = "A114"."ORGANIZATION_ID"
               AND "A114"."LANGUAGE" = USERENV ('LANG')) "A2",
       "XXPB"."INVMKTI001INN" "A1"
 WHERE     1 = 1
       AND "A7"."ORGANIZATION_ID"(+) = "A2"."ORGANIZATION_ID"
       AND "A7"."INVENTORY_ITEM_ID"(+) = "A2"."INVENTORY_ITEM_ID"
       AND "A4"."ORGANIZATION_ID"(+) = "A2"."ORGANIZATION_ID"
       AND "A4"."INVENTORY_ITEM_ID"(+) = "A2"."INVENTORY_ITEM_ID"
       AND "A5"."ORGANIZATION_ID"(+) = "A2"."ORGANIZATION_ID"
       AND "A5"."INVENTORY_ITEM_ID"(+) = "A2"."INVENTORY_ITEM_ID"
       AND "A6"."ORGANIZATION_ID"(+) = "A2"."ORGANIZATION_ID"
       AND "A6"."INVENTORY_ITEM_ID"(+) = "A2"."INVENTORY_ITEM_ID"
       AND TRUNC (NVL ("A3"."INACTIVE_DATE", SYSDATE)) >= TRUNC (SYSDATE)
       AND "A2"."GLOBAL_ATTRIBUTE1" = "A3"."CLASSIFICATION_CODE"(+)
       AND (   "A2"."ATTRIBUTE4" = '0'
            OR "A2"."ATTRIBUTE4" = '1'
            OR "A2"."ATTRIBUTE4" = '3')
       AND "A2"."INVENTORY_ITEM_ID" = "A1"."INVENTORY_ITEM_ID"(+)
       AND "A2"."ORGANIZATION_ID" = "A1"."ORGANIZATION_ID"(+)
       AND "A2"."ORGANIZATION_ID" =
              ANY (SELECT DISTINCT
                          "A8"."MASTER_ORGANIZATION_ID"
                             "MASTER_ORGANIZATION_ID"
                     FROM "INV"."MTL_PARAMETERS" "A8")
AND ''
       || (SELECT "A18"."DESCRIPTION" "DESCRIPTION"
             FROM (SELECT "A85"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                          "A85"."CONTROL_LEVEL" "CONTROL_LEVEL",
                          "A85"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                          "A85"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                          "A85"."CREATION_DATE" "CREATION_DATE",
                          "A85"."CREATED_BY" "CREATED_BY",
                          "A85"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
                          "A85"."REQUEST_ID" "REQUEST_ID",
                          "A85"."PROGRAM_APPLICATION_ID"
                             "PROGRAM_APPLICATION_ID",
                          "A85"."PROGRAM_ID" "PROGRAM_ID",
                          "A85"."PROGRAM_UPDATE_DATE" "PROGRAM_UPDATE_DATE",
                          "A86"."CATEGORY_SET_NAME" "CATEGORY_SET_NAME",
                          "A86"."DESCRIPTION" "DESCRIPTION"
                     FROM "INV"."MTL_CATEGORY_SETS_TL" "A86",
                          "INV"."MTL_CATEGORY_SETS_B" "A85"
                    WHERE     "A85"."CATEGORY_SET_ID" =
                                 "A86"."CATEGORY_SET_ID"
                          AND "A86"."LANGUAGE" = USERENV ('LANG')) "A20",
                  (SELECT "A91"."INVENTORY_ITEM_ID" "INVENTORY_ITEM_ID",
                          "A91"."ORGANIZATION_ID" "ORGANIZATION_ID",
                          "A91"."CATEGORY_SET_ID" "CATEGORY_SET_ID",
                          "A91"."CATEGORY_ID" "CATEGORY_ID",
                          "A91"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                          "A91"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                          "A91"."CREATION_DATE" "CREATION_DATE",
                          "A91"."CREATED_BY" "CREATED_BY",
                          "A91"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
                          "A91"."REQUEST_ID" "REQUEST_ID",
                          "A91"."PROGRAM_APPLICATION_ID"
                             "PROGRAM_APPLICATION_ID",
                          "A91"."PROGRAM_ID" "PROGRAM_ID",
                          "A91"."PROGRAM_UPDATE_DATE" "PROGRAM_UPDATE_DATE",
                          "A87"."SEGMENT1" "SEGMENT1",
                          "A87"."SEGMENT2" "SEGMENT2",
                          "A87"."SEGMENT3" "SEGMENT3",
                          "A87"."SEGMENT4" "SEGMENT4",
                          "A87"."SEGMENT5" "SEGMENT5",
                          "A87"."SEGMENT6" "SEGMENT6",
                          "A87"."SEGMENT7" "SEGMENT7",
                          "A87"."SEGMENT8" "SEGMENT8",
                          "A87"."SEGMENT9" "SEGMENT9",
                          "A87"."SEGMENT10" "SEGMENT10",
                          "A87"."SEGMENT11" "SEGMENT11",
                          "A87"."SEGMENT12" "SEGMENT12",
                          "A87"."SEGMENT13" "SEGMENT13",
                          "A87"."SEGMENT14" "SEGMENT14",
                          "A87"."SEGMENT15" "SEGMENT15",
                          "A87"."SEGMENT16" "SEGMENT16",
                          "A87"."SEGMENT17" "SEGMENT17",
                          "A87"."SEGMENT18" "SEGMENT18",
                          "A87"."SEGMENT19" "SEGMENT19",
                          "A87"."SEGMENT20" "SEGMENT20",
                          "A87"."SUMMARY_FLAG" "SUMMARY_FLAG",
                          "A87"."ENABLED_FLAG" "ENABLED_FLAG"
                     FROM "INV"."MTL_ITEM_CATEGORIES" "A91",
                          "INV"."MTL_CATEGORY_SETS_TL" "A90",
                          "INV"."MTL_CATEGORY_SETS_B" "A89",
                          (SELECT "A92"."LOOKUP_TYPE" "LOOKUP_TYPE",
                                  TO_NUMBER ("A92"."LOOKUP_CODE")
                                     "LOOKUP_CODE",
                                  "A92"."MEANING" "MEANING",
                                  "A92"."DESCRIPTION" "DESCRIPTION",
                                  "A92"."ENABLED_FLAG" "ENABLED_FLAG",
                                  "A92"."START_DATE_ACTIVE"
                                     "START_DATE_ACTIVE",
                                  "A92"."END_DATE_ACTIVE" "END_DATE_ACTIVE",
                                  "A92"."CREATED_BY" "CREATED_BY",
                                  "A92"."CREATION_DATE" "CREATION_DATE",
                                  "A92"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                                  "A92"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                                  "A92"."LAST_UPDATE_LOGIN"
                                     "LAST_UPDATE_LOGIN"
                             FROM "APPLSYS"."FND_LOOKUP_VALUES" "A92"
                            WHERE     "A92"."LANGUAGE" = USERENV ('LANG')
                                  AND "A92"."VIEW_APPLICATION_ID" = 700
                                  AND "A92"."SECURITY_GROUP_ID" = 0) "A88",
                          (SELECT "A93"."CATEGORY_ID" "CATEGORY_ID",
                                  "A93"."SEGMENT2" "SEGMENT2",
                                  "A93"."SEGMENT19" "SEGMENT19",
                                  "A93"."REQUEST_ID" "REQUEST_ID",
                                  "A93"."ATTRIBUTE1" "ATTRIBUTE1",
                                  "A93"."ATTRIBUTE6" "ATTRIBUTE6",
                                  "A93"."LAST_UPDATE_LOGIN"
                                     "LAST_UPDATE_LOGIN",
                                  "A93"."ATTRIBUTE15" "ATTRIBUTE15",
                                  "A93"."SEGMENT1" "SEGMENT1",
                                  "A93"."ATTRIBUTE13" "ATTRIBUTE13",
                                  "A93"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                                  "A93"."SEGMENT7" "SEGMENT7",
                                  "A93"."SEGMENT8" "SEGMENT8",
                                  "A93"."SEGMENT20" "SEGMENT20",
                                  "A93"."ATTRIBUTE5" "ATTRIBUTE5",
                                  "A93"."ATTRIBUTE7" "ATTRIBUTE7",
                                  "A93"."PROGRAM_APPLICATION_ID"
                                     "PROGRAM_APPLICATION_ID",
                                  "A93"."PROGRAM_UPDATE_DATE"
                                     "PROGRAM_UPDATE_DATE",
                                  "A93"."SEGMENT13" "SEGMENT13",
                                  "A93"."SEGMENT5" "SEGMENT5",
                                  "A93"."SEGMENT11" "SEGMENT11",
                                  "A93"."ATTRIBUTE3" "ATTRIBUTE3",
                                  "A93"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                                  "A93"."CREATED_BY" "CREATED_BY",
                                  "A93"."SEGMENT12" "SEGMENT12",
                                  "A93"."ATTRIBUTE4" "ATTRIBUTE4",
                                  "A93"."ATTRIBUTE8" "ATTRIBUTE8",
                                  "A93"."ATTRIBUTE9" "ATTRIBUTE9",
                                  "A93"."SEGMENT9" "SEGMENT9",
                                  "A93"."SUMMARY_FLAG" "SUMMARY_FLAG",
                                  "A93"."ATTRIBUTE11" "ATTRIBUTE11",
                                  "A93"."WEB_STATUS" "WEB_STATUS",
                                  "A93"."DESCRIPTION" "DESCRIPTION",
                                  "A93"."SEGMENT15" "SEGMENT15",
                                  "A93"."ATTRIBUTE10" "ATTRIBUTE10",
                                  "A93"."ATTRIBUTE14" "ATTRIBUTE14",
                                  "A93"."SEGMENT6" "SEGMENT6",
                                  "A93"."END_DATE_ACTIVE" "END_DATE_ACTIVE",
                                  "A93"."ATTRIBUTE2" "ATTRIBUTE2",
                                  "A93"."ENABLED_FLAG" "ENABLED_FLAG",
                                  "A93"."ATTRIBUTE12" "ATTRIBUTE12",
                                  "A93"."SEGMENT4" "SEGMENT4",
                                  "A93"."SEGMENT10" "SEGMENT10",
                                  "A93"."SEGMENT14" "SEGMENT14",
                                  "A93"."SEGMENT16" "SEGMENT16",
                                  "A93"."SEGMENT3" "SEGMENT3",
                                  "A93"."SEGMENT17" "SEGMENT17",
                                  "A93"."ATTRIBUTE_CATEGORY"
                                     "ATTRIBUTE_CATEGORY",
                                  "A93"."CREATION_DATE" "CREATION_DATE",
                                  "A93"."PROGRAM_ID" "PROGRAM_ID",
                                  "A93"."SEGMENT18" "SEGMENT18",
                                  "A93"."START_DATE_ACTIVE"
                                     "START_DATE_ACTIVE"
                             FROM "INV"."MTL_CATEGORIES_B" "A93") "A87"
                    WHERE     "A91"."CATEGORY_SET_ID" =
                                 "A89"."CATEGORY_SET_ID"
                          AND "A89"."CATEGORY_SET_ID" =
                                 "A90"."CATEGORY_SET_ID"
                          AND "A90"."LANGUAGE" = USERENV ('LANG')
                          AND "A91"."CATEGORY_ID" = "A87"."CATEGORY_ID"
                          AND "A89"."CONTROL_LEVEL" = "A88"."LOOKUP_CODE"
                          AND "A88"."LOOKUP_TYPE" = 'ITEM_CONTROL_LEVEL_GUI') "A19",
                  (SELECT "A94"."FLEX_VALUE_SET_ID" "FLEX_VALUE_SET_ID",
                          "A94"."FLEX_VALUE" "FLEX_VALUE",
                          "A94"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
                          "A94"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
                          "A94"."CREATION_DATE" "CREATION_DATE",
                          "A94"."CREATED_BY" "CREATED_BY",
                          "A94"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
                          "A94"."ENABLED_FLAG" "ENABLED_FLAG",
                          "A94"."SUMMARY_FLAG" "SUMMARY_FLAG",
                          "A94"."START_DATE_ACTIVE" "START_DATE_ACTIVE",
                          "A94"."END_DATE_ACTIVE" "END_DATE_ACTIVE",
                          "A94"."ATTRIBUTE1" "ATTRIBUTE1",
                          "A94"."ATTRIBUTE2" "ATTRIBUTE2",
                          "A94"."ATTRIBUTE3" "ATTRIBUTE3",
                          "A94"."ATTRIBUTE4" "ATTRIBUTE4",
                          "A94"."ATTRIBUTE5" "ATTRIBUTE5",
                          "A94"."ATTRIBUTE6" "ATTRIBUTE6",
                          "A94"."ATTRIBUTE7" "ATTRIBUTE7",
                          "A94"."ATTRIBUTE8" "ATTRIBUTE8",
                          "A94"."ATTRIBUTE9" "ATTRIBUTE9",
                          "A94"."ATTRIBUTE10" "ATTRIBUTE10",
                          "A94"."ATTRIBUTE11" "ATTRIBUTE11",
                          "A94"."ATTRIBUTE12" "ATTRIBUTE12",
                          "A94"."ATTRIBUTE13" "ATTRIBUTE13",
                          "A94"."ATTRIBUTE14" "ATTRIBUTE14",
                          "A94"."ATTRIBUTE15" "ATTRIBUTE15",
                          "A94"."ATTRIBUTE16" "ATTRIBUTE16",
                          "A94"."ATTRIBUTE17" "ATTRIBUTE17",
                          "A94"."ATTRIBUTE18" "ATTRIBUTE18",
                          "A94"."ATTRIBUTE19" "ATTRIBUTE19",
                          "A94"."ATTRIBUTE20" "ATTRIBUTE20",
                          "A94"."ATTRIBUTE21" "ATTRIBUTE21",
                          "A94"."ATTRIBUTE22" "ATTRIBUTE22",
                          "A94"."ATTRIBUTE23" "ATTRIBUTE23",
                          "A94"."ATTRIBUTE24" "ATTRIBUTE24",
                          "A94"."ATTRIBUTE25" "ATTRIBUTE25",
                          "A94"."ATTRIBUTE26" "ATTRIBUTE26",
                          "A94"."ATTRIBUTE27" "ATTRIBUTE27",
                          "A94"."ATTRIBUTE28" "ATTRIBUTE28",
                          "A94"."ATTRIBUTE29" "ATTRIBUTE29",
                          "A94"."ATTRIBUTE30" "ATTRIBUTE30",
                          "A95"."DESCRIPTION" "DESCRIPTION"
                     FROM "APPLSYS"."FND_FLEX_VALUES_TL" "A95",
                          "APPLSYS"."FND_FLEX_VALUES" "A94"
                    WHERE     "A94"."FLEX_VALUE_ID" = "A95"."FLEX_VALUE_ID"
                          AND "A95"."LANGUAGE" = USERENV ('LANG')) "A18"
            WHERE     "A20"."CATEGORY_SET_NAME" = 'Marca do Item'
                  AND "A19"."CATEGORY_SET_ID" = "A20"."CATEGORY_SET_ID"
                  AND "A18"."FLEX_VALUE" = "A19"."SEGMENT1"
                  AND "A19"."INVENTORY_ITEM_ID" = "A2"."INVENTORY_ITEM_ID"
                  AND "A19"."ORGANIZATION_ID" = "A2"."ORGANIZATION_ID"
                  AND "A18"."FLEX_VALUE_SET_ID" =
                         (SELECT "A36"."FLEX_VALUE_SET_ID"
                                    "FLEX_VALUE_SET_ID"
                            FROM "APPLSYS"."FND_FLEX_VALUE_SETS" "A36"
                           WHERE "A36"."FLEX_VALUE_SET_NAME" = 'GL_PB_MARCA'))
           = 'POINTER' ;


COMMENT ON MATERIALIZED VIEW APPS.CONSULTA_PRODUTO_PT_V IS 'snapshot table for snapshot APPS.CONSULTA_PRODUTO_PT_V';

CREATE OR REPLACE SYNONYM APPSR.CONSULTA_PRODUTO_PT_V FOR APPS.CONSULTA_PRODUTO_PT_V;

CREATE OR REPLACE SYNONYM XXPB.CONSULTA_PRODUTO_PT_V FOR APPS.CONSULTA_PRODUTO_PT_V;

GRANT SELECT ON APPS.CONSULTA_PRODUTO_PT_V TO XXPB WITH GRANT OPTION;

GRANT SELECT ON APPS.CONSULTA_PRODUTO_PT_V TO APPSR WITH GRANT OPTION;
