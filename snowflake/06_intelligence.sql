-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-telemetry alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes validated __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05 and aws/setup_aws.py.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic CCP deviation knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.LINE_DOCS AS
WITH causes AS (
  SELECT DISTINCT r.ROOT_CAUSE, m.CATEGORY
  FROM RAW.CCP_READINGS r JOIN RAW.PROCESSING_LINES m ON m.ID = r.ENTITY_ID
  WHERE r.ROOT_CAUSE IS NOT NULL AND r.DEVIATION_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ROOT_CAUSE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ROOT_CAUSE,
  CATEGORY || ' - ' || ROOT_CAUSE || ' CCP deviation response' AS TITLE,
  'Synthetic demo SOP. Line type: ' || CATEGORY || '. Deviation cause: ' || ROOT_CAUSE || '. '
  || 'Step 1: place the line on CCP hold, segregate and tag product made since the last in-limit check, and notify the shift QA lead. '
  || 'Step 2: ' || CASE
       WHEN ROOT_CAUSE ILIKE '%core temp%' OR ROOT_CAUSE ILIKE '%steam%' OR ROOT_CAUSE ILIKE '%belt speed%' THEN 'check steam supply and cooker belt speed, verify core temperature on three units with a calibrated probe and recook or reject held product per the site plan.'
       WHEN ROOT_CAUSE ILIKE '%chiller%' OR ROOT_CAUSE ILIKE '%dwell%' THEN 'check chiller water temperature, ice supply and dwell time, and re-chill held carcasses until the product temperature is back within the site limit.'
       WHEN ROOT_CAUSE ILIKE '%chlorine%' THEN 'test chiller water with the chlorine kit, adjust the dosing pump and record the corrected reading before releasing the line.'
       WHEN ROOT_CAUSE ILIKE '%metal%' THEN 'run the detector with ferrous, non-ferrous and stainless test pieces, rescan held packs and isolate any reject for investigation.'
       WHEN ROOT_CAUSE ILIKE '%seal%' OR ROOT_CAUSE ILIKE '%allergen%' THEN 'check sealer jaw temperature and label artwork against the production order, then re-inspect or relabel held packs.'
       WHEN ROOT_CAUSE ILIKE '%freezer%' OR ROOT_CAUSE ILIKE '%evaporator%' OR ROOT_CAUSE ILIKE '%probe%' THEN 'check freezer exit temperature and defrost status, verify probes against the reference thermometer and refreeze held product before release.'
       WHEN ROOT_CAUSE ILIKE '%power%' THEN 'confirm supply status with the plant electrical lead, check cold room temperature logs and restart lines in the documented sequence.'
       ELSE 'inspect the affected line, record readings and escalate to the HACCP engineer if readings are out of limit.'
     END
  || ' Step 3: if the ATP swab exceeds 600 RLU or product temperature exceeds 5 C after restart, re-clean, re-swab and keep the line on watch. '
  || 'Step 4: record the deviation cause, hold hours, product disposition and corrective action in the HACCP log.' AS CONTENT
FROM causes;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.LINE_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ROOT_CAUSE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ROOT_CAUSE, CONTENT FROM SEARCH.LINE_DOCS);

-- ---------- Line ATP hygiene swab anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.ATP_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, ATP_RLU::FLOAT AS ATP
FROM RAW.CCP_READINGS;
CREATE OR REPLACE VIEW ML.ATP_TRAIN AS
SELECT * FROM ML.ATP_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.ATP_SERIES);
CREATE OR REPLACE VIEW ML.ATP_DETECT AS
SELECT * FROM ML.ATP_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.ATP_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.ATP_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.ATP_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'ATP',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.ATP_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS ATP, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.ATP_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.ATP_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'ATP'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.FOOD_SAFETY_ANALYTICS
  TABLES (
    lines AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      COMMENT = 'One row per processing line, 90-day totals',
    risk AS ML.DEVIATION_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day CCP deviation probability per line',
    causes AS CURATED.DEVIATION_CAUSES PRIMARY KEY (ROOT_CAUSE)
      COMMENT = 'CCP hold hours by deviation cause, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Plant-network totals per day'
  )
  RELATIONSHIPS (risk_line AS risk (ENTITY_ID) REFERENCES lines)
  FACTS (
    lines.hold_hours_f AS HOLD_HOURS,
    lines.operating_hours_f AS OPERATING_HOURS,
    lines.planned_hours_f AS PLANNED_HOURS,
    lines.failures_f AS ALERT_COUNT,
    risk.deviation_prob_f AS DEVIATION_PROB_7D,
    causes.cause_hours_f AS HOLD_HOURS,
    causes.cause_failures_f AS DEVIATION_COUNT,
    daily.day_operating_f AS OPERATING_HOURS,
    daily.day_planned_f AS PLANNED_HOURS,
    daily.day_failures_f AS DEVIATION_COUNT
  )
  DIMENSIONS (
    lines.line_id AS ENTITY_ID WITH SYNONYMS = ('line', 'processing line', 'entity', 'line id'),
    lines.line_name AS ENTITY_NAME,
    lines.region AS REGION COMMENT = 'Thai plant city',
    lines.line_type AS CATEGORY WITH SYNONYMS = ('line type', 'category'),
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    causes.root_cause AS ROOT_CAUSE,
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    lines.line_count AS COUNT(lines.line_id) WITH SYNONYMS = ('number of lines', 'entities', 'lines monitored'),
    lines.total_hold_hours AS SUM(lines.hold_hours_f),
    lines.ccp_deviations AS SUM(lines.failures_f) WITH SYNONYMS = ('deviations', 'ccp failures'),
    lines.uptime_pct AS 100 * SUM(lines.operating_hours_f) / NULLIF(SUM(lines.planned_hours_f), 0)
      COMMENT = 'Production hours not on CCP hold / planned hours',
    lines.mtbd_hours AS SUM(lines.operating_hours_f) / NULLIF(SUM(lines.failures_f), 0)
      COMMENT = 'Mean production hours between CCP deviations',
    risk.avg_deviation_prob AS AVG(risk.deviation_prob_f),
    causes.cause_hold_hours AS SUM(causes.cause_hours_f),
    causes.cause_deviations AS SUM(causes.cause_failures_f),
    daily.daily_uptime_pct AS 100 * SUM(daily.day_operating_f) / NULLIF(SUM(daily.day_planned_f), 0),
    daily.daily_deviations AS SUM(daily.day_failures_f)
  )
  COMMENT = 'Synthetic Thai food processing CCP monitoring (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.FOOD_SAFETY_AGENT
  COMMENT = 'Food safety assistant over synthetic Thai food processing lines'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give line IDs and numbers with units."
  orchestration: "Use ccp_analyst for metrics, lines, CCP deviation risk and deviation causes. Use sop_search for CCP deviation procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: ccp_analyst
      description: "Processing line CCP hold hours, availability, hours between deviations, deviations, deviation causes and deviation risk scores"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic CCP deviation SOPs by line type and deviation cause"
tool_resources:
  ccp_analyst:
    semantic_view: __DEMO_DB__.APP.FOOD_SAFETY_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.LINE_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-telemetry alert (IoT Core -> S3 -> Snowpipe) ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), LINE_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, ATP_RLU FLOAT, CHILL_TEMP_C FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION TH_FOOD_SAFETY_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALARMS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (LINE_ID, EVENT_TS, ATP_RLU, CHILL_TEMP_C, SOP_HINT)
    SELECT t.LINE_ID, t.EVENT_TS, t.ATP_RLU, t.CHILL_TEMP_C,
           'Check ' || m.CATEGORY || ' SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TELEMETRY t
    JOIN RAW.PROCESSING_LINES m ON m.ID = t.LINE_ID
    LEFT JOIN ML.DEVIATION_RISK_SCORES r ON r.ENTITY_ID = t.LINE_ID
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.LINE_ID = t.LINE_ID AND l.EVENT_TS = t.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('TH_FOOD_SAFETY_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Thai food processing line CCP alarm',
      'New live-telemetry alarms logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ALARM_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TELEMETRY t
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.LINE_ID = t.LINE_ID AND l.EVENT_TS = t.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALARMS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.DEVIATION_CAUSES REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.DEVIATION_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.DEVIATION_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.DEVIATION_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'AGE_YEARS', AGE_YEARS, 'ATP_RLU', ATP_RLU,
             'CHILL_TEMP_C', CHILL_TEMP_C, 'ATP_7D', ATP_7D, 'DEVIATIONS_30D', DEVIATIONS_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, PRED:probability:FAIL::FLOAT AS DEVIATION_PROB_7D,
         CASE WHEN PRED:probability:FAIL::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:FAIL::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
