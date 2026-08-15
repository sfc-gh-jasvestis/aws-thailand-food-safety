-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Food Safety & Quality Compliance
-- ============================================================================
USE DATABASE FOOD_SAFETY;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_thailand_food_safety_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('jonathan.asvestis@snowflake.com');

-- Alert: PATHOGEN_CRITICAL_ALERT
CREATE OR REPLACE ALERT APP.PATHOGEN_CRITICAL_ALERT
  WAREHOUSE = FOOD_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Critical pathogen detection — immediate hold and investigation'
IF (EXISTS (
  SELECT 1 FROM CURATED.FACILITY_COMPLIANCE_SCORE
  WHERE 1=1 -- Condition: PATHOGEN_DETECTED = TRUE for any critical pathogen (Salmonella, Listeria)
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_thailand_food_safety_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Food Safety & Quality Compliance: Critical pathogen detection — immediate hold and investigation',
    'Critical pathogen detection — immediate hold and investigation'
  );

ALTER ALERT APP.PATHOGEN_CRITICAL_ALERT RESUME;

-- Alert: CCP_DEVIATION_ALERT
CREATE OR REPLACE ALERT APP.CCP_DEVIATION_ALERT
  WAREHOUSE = FOOD_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'CCP deviation threshold exceeded — process review required'
IF (EXISTS (
  SELECT 1 FROM CURATED.FACILITY_COMPLIANCE_SCORE
  WHERE 1=1 -- Condition: CCP_DEVIATION_COUNT > 5 in 24 hours for any CCP
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_thailand_food_safety_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Food Safety & Quality Compliance: CCP deviation threshold exceeded — process review required',
    'CCP deviation threshold exceeded — process review required'
  );

ALTER ALERT APP.CCP_DEVIATION_ALERT RESUME;

