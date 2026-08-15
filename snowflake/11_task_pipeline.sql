-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Food Safety & Quality Compliance
-- ============================================================================
USE DATABASE FOOD_SAFETY;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_PARSE_INSPECTIONS
  WAREHOUSE = FOOD_WH
  SCHEDULE = 'USING CRON 0 7 * * * UTC'
  COMMENT = 'Parse new inspection report PDFs with AI_PARSE_DOCUMENT'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_REFRESH_COMPLIANCE
  WAREHOUSE = FOOD_WH
  AFTER APP.TASK_PARSE_INSPECTIONS
  COMMENT = 'Recalculate facility compliance scores and recall risk'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_CHECK_ALERTS
  WAREHOUSE = FOOD_WH
  SCHEDULE = 'USING CRON 0 */1 * * * UTC'
  COMMENT = 'Check for critical pathogen detections and CCP deviations'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_CHECK_ALERTS RESUME;
ALTER TASK APP.TASK_REFRESH_COMPLIANCE RESUME;
ALTER TASK APP.TASK_PARSE_INSPECTIONS RESUME;
