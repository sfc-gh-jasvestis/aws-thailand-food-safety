-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Food Safety & Quality Compliance
-- ============================================================================
USE DATABASE FOOD_SAFETY;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.FOOD_REGULATION_SEARCH
  ON REGULATION_TEXT
  ATTRIBUTES REGULATION_SOURCE, CATEGORY, EXPORT_MARKET
  WAREHOUSE = FOOD_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.FOOD_REGULATIONS
);
