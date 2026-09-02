-- Generated from generator/demo_specs/aws-thailand-food-safety.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-thailand-food-safety
-- This is the schema that is actually deployed for THAILAND_FOOD_SAFETY.

-- THAILAND_FOOD_SAFETY  (Food Safety & Quality Compliance)
-- generated from generator/demo_specs/aws-thailand-food-safety.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS THAILAND_FOOD_SAFETY;
CREATE SCHEMA IF NOT EXISTS THAILAND_FOOD_SAFETY.RAW;
CREATE SCHEMA IF NOT EXISTS THAILAND_FOOD_SAFETY.CURATED;
CREATE SCHEMA IF NOT EXISTS THAILAND_FOOD_SAFETY.APP;
USE DATABASE THAILAND_FOOD_SAFETY;

-- 5 real regions; entity names carry their region so the two always agree
