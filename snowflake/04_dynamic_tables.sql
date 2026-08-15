-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Food Safety & Quality Compliance
-- ============================================================================
USE DATABASE FOOD_SAFETY;
USE SCHEMA CURATED;

-- FACILITY_COMPLIANCE_SCORE: Real-time compliance scoring by facility based on inspections and lab results
-- Source: FACILITIES, INSPECTION_REPORTS, LAB_RESULTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.FACILITY_COMPLIANCE_SCORE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = FOOD_WH
AS
SELECT * FROM RAW.FACILITIES;
-- TODO: Replace with actual join/aggregation logic per demo

-- CCP_DEVIATION_TRENDS: CCP deviation frequency and severity trending
-- Source: CCP_MONITORING
CREATE OR REPLACE DYNAMIC TABLE CURATED.CCP_DEVIATION_TRENDS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = FOOD_WH
AS
SELECT * FROM RAW.CCP_MONITORING;
-- TODO: Replace with actual join/aggregation logic per demo

-- RECALL_RISK_INDEX: Predictive recall risk score by product and facility
-- Source: LAB_RESULTS, CCP_MONITORING, CORRECTIVE_ACTIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.RECALL_RISK_INDEX
  TARGET_LAG = '5 minutes'
  WAREHOUSE = FOOD_WH
AS
SELECT * FROM RAW.LAB_RESULTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- REGULATION_COMPLIANCE_GAP: Gap analysis between current performance and regulatory limits
-- Source: LAB_RESULTS, FOOD_REGULATIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.REGULATION_COMPLIANCE_GAP
  TARGET_LAG = '5 minutes'
  WAREHOUSE = FOOD_WH
AS
SELECT * FROM RAW.LAB_RESULTS;
-- TODO: Replace with actual join/aggregation logic per demo

