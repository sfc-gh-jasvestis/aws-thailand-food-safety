-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Food Safety & Quality Compliance
-- Country: THAILAND | Currency: THB
-- ============================================================================
USE DATABASE FOOD_SAFETY;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- FACILITIES: 45 rows — Food processing plants (seafood, chicken, prepared meals, snacks)
-- INSPECTION_REPORTS: 680 rows — Thai FDA and internal audit inspection reports (parsed PDFs)
-- LAB_RESULTS: 120,000 rows — Microbial, chemical, and physical test results
-- CCP_MONITORING: 500,000 rows — HACCP Critical Control Point monitoring data
-- CORRECTIVE_ACTIONS: 4,500 rows — CAPA records from non-conformances
-- FOOD_REGULATIONS: 300 rows — Thai FDA regulations, CODEX standards, export market requirements
-- TRACEABILITY: 200,000 rows — Lot traceability from farm to finished product
-- THAI_FOOD_INDUSTRY: 10 rows — Thailand food export statistics and industry context
