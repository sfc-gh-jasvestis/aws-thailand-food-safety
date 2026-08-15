-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Food Safety & Quality Compliance
-- ============================================================================
USE DATABASE FOOD_SAFETY;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.FOOD_SAFETY_AGENT
  COMMENT = 'Food Safety & Quality Compliance AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'FOOD_SAFETY.APP.FOOD_SAFETY_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'FOOD_SAFETY.SEARCH.FOOD_REGULATION_SEARCH', TOOL_DESCRIPTION => 'Search documents for Food & Agribusiness information')
  )
  SYSTEM_PROMPT = 'You are the Food Safety Intelligence Agent for 45 food processing facilities in Thailand, monitoring compliance with Thai FDA, CODEX, and export market regulations.';
