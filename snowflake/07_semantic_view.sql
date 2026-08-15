-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Food Safety & Quality Compliance
-- ============================================================================
USE DATABASE FOOD_SAFETY;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.FOOD_SAFETY_ANALYTICS
  COMMENT = 'Food safety compliance, lab results, and recall risk analytics'
AS
  TABLES (
    CURATED.FACILITY_COMPLIANCE_SCORE AS facility_compliance_score,CURATED.CCP_DEVIATION_TRENDS AS ccp_deviation_trends,CURATED.RECALL_RISK_INDEX AS recall_risk_index,CURATED.REGULATION_COMPLIANCE_GAP AS regulation_compliance_gap
  );
