-- ============================================================================
-- Food Safety & Quality Compliance
-- AI-powered food safety compliance for Thailand's ฿3.5T food industry — Textract parses Thai FDA inspection reports, Cortex Search indexes food regulations, and SNS pushes real-time alerts when critical violations are detected.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS FOOD_SAFETY;
CREATE WAREHOUSE IF NOT EXISTS FOOD_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE FOOD_SAFETY;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE FOOD_WH;
