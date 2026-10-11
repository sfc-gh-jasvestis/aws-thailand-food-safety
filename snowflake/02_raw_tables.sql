-- Synthetic line-day HACCP observations for the processing lines of a
-- fictional Thai food processor; no seeded predictions or invented line counts.
-- Randomness is HASH-seeded so every rebuild is reproducible yet varied:
-- per-line deviation propensity and age, shift patterns, hygiene drift between
-- sanitation verification rounds, missed rounds, variable CCP hold times,
-- line-type-weighted deviation causes and two plant-wide power dips.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.PROCESSING_LINES AS
WITH line_seq AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS LINE_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 24))
), draws AS (
  SELECT LINE_INDEX,
         MOD(ABS(HASH(LINE_INDEX, 'thfs-ccp-plantcity')), 1000000) / 1e6 AS U_REGION,
         MOD(ABS(HASH(LINE_INDEX, 'thfs-ccp-sttype')), 1000000) / 1e6 AS U_CATEGORY,
         MOD(ABS(HASH(LINE_INDEX, 'thfs-ccp-age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(LINE_INDEX, 'thfs-ccp-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(LINE_INDEX, 'thfs-ccp-shift')), 1000000) / 1e6 AS U_SHIFT,
         MOD(ABS(HASH(LINE_INDEX, 'thfs-ccp-pm')), 1000000) / 1e6 AS U_PM,
         MOD(ABS(HASH(LINE_INDEX, 'thfs-ccp-discipline')), 1000000) / 1e6 AS U_DISCIPLINE
  FROM line_seq
)
SELECT 'LINE-' || LPAD(LINE_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic line ' || LPAD(LINE_INDEX::VARCHAR, 4, '0') AS NAME,
       CASE WHEN U_REGION < 0.24 THEN 'Samut Sakhon' WHEN U_REGION < 0.42 THEN 'Chonburi'
            WHEN U_REGION < 0.58 THEN 'Nakhon Pathom' WHEN U_REGION < 0.74 THEN 'Songkhla'
            WHEN U_REGION < 0.88 THEN 'Chiang Mai' ELSE 'Surat Thani' END AS REGION,
       CASE WHEN U_CATEGORY < 0.30 THEN 'Seafood Cooking Line' WHEN U_CATEGORY < 0.52 THEN 'Poultry Chilling Line'
            WHEN U_CATEGORY < 0.80 THEN 'Ready Meal Packing Line' ELSE 'Blast Freezing Line' END AS CATEGORY,
       LINE_INDEX,
       ROUND(1 + U_AGE * 12, 1) AS AGE_YEARS,
       -- Base daily deviation probability 0.4%-4.6% (skewed); ~10% of lines are chronic (x3).
       (0.004 + U_RATE * U_RATE * 0.042) * IFF(U_RATE > 0.90, 3, 1) AS BASE_DEVIATION_RATE,
       IFF(U_SHIFT < 0.60, 20, 16) AS SHIFT_HOURS,
       7 * (1 + FLOOR(U_PM * 3)) AS SANITATION_INTERVAL_DAYS,
       0.52 + U_DISCIPLINE * 0.46 AS SANITATION_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.CCP_READINGS AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), outages AS (
  -- Two plant-wide power dips in the window (cold rooms and cookers on hold).
  SELECT * FROM VALUES (31, 'Songkhla', 3.5), (67, 'Samut Sakhon', 2.0) AS o(DAY_INDEX, REGION, HOURS)
), base AS (
  SELECT m.ID AS ENTITY_ID, m.LINE_INDEX, m.CATEGORY, m.REGION, m.AGE_YEARS,
         m.BASE_DEVIATION_RATE, m.SANITATION_INTERVAL_DAYS, m.SANITATION_COMPLETION_PROB, d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         IFF(MOD(d.DAY_INDEX, 7) = 6, 8.0, m.SHIFT_HOURS) AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + m.LINE_INDEX * 5, m.SANITATION_INTERVAL_DAYS) AS DAYS_SINCE_SANITATION,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thfs-ccp-deviate')), 1000000) / 1e6 AS U_FAIL,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thfs-ccp-hold')), 1000000) / 1e6 + 1e-6 AS U_HOLD,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thfs-ccp-cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thfs-ccp-pmdone')), 1000000) / 1e6 AS U_PMDONE,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thfs-ccp-jobs')), 1000000) / 1e6 AS U_UNITS,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thfs-ccp-noise')), 1000000) / 1e6 AS U_NOISE,
         o.HOURS AS OUTAGE_HOURS
  FROM RAW.PROCESSING_LINES m CROSS JOIN days d
  LEFT JOIN outages o ON o.DAY_INDEX = d.DAY_INDEX AND o.REGION = m.REGION
), pm AS (
  SELECT *,
         IFF(DAYS_SINCE_SANITATION = 0, 1, 0) AS SANITATION_DUE,
         IFF(DAYS_SINCE_SANITATION = 0 AND U_PMDONE < SANITATION_COMPLETION_PROB, 1, 0) AS SANITATION_DONE,
         -- Hygiene drift rises between verification rounds; weak discipline adds carry-over.
         DAYS_SINCE_SANITATION / SANITATION_INTERVAL_DAYS + (1 - SANITATION_COMPLETION_PROB) AS WEAR,
         -- Hot, humid stretch (days 30-74 of the window) stresses poultry chiller water temperature.
         IFF(CATEGORY = 'Poultry Chilling Line' AND DAY_INDEX BETWEEN 30 AND 74, 1.40, 1.0) AS HEAT_FACTOR
  FROM base
), failures AS (
  SELECT *,
         LEAST(0.6, BASE_DEVIATION_RATE * (0.4 + 1.6 * WEAR) * (1 + AGE_YEARS / 25) * HEAT_FACTOR) AS P_FAIL
  FROM pm
), events AS (
  SELECT *,
         CASE WHEN OUTAGE_HOURS IS NOT NULL THEN 1
              WHEN U_FAIL < P_FAIL / 4 THEN 2
              WHEN U_FAIL < P_FAIL THEN 1 ELSE 0 END AS DEVIATION_COUNT
  FROM failures
), timed AS (
  SELECT *,
         -- Exponential CCP hold durations; mean depends on line type.
         CASE WHEN DEVIATION_COUNT = 0 THEN 0.0
              WHEN OUTAGE_HOURS IS NOT NULL THEN OUTAGE_HOURS
              ELSE LEAST(PLANNED_HOURS - 0.5, ROUND(DEVIATION_COUNT * (0.4 - LN(U_HOLD) *
                     CASE CATEGORY WHEN 'Poultry Chilling Line' THEN 3.5 WHEN 'Seafood Cooking Line' THEN 2.5
                                   WHEN 'Ready Meal Packing Line' THEN 1.5 ELSE 2.0 END), 1)) END AS HOLD_HOURS
  FROM events
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, HOLD_HOURS,
       PLANNED_HOURS - HOLD_HOURS AS OPERATING_HOURS,
       DEVIATION_COUNT,
       CASE WHEN DEVIATION_COUNT = 0 THEN 'None'
            WHEN OUTAGE_HOURS IS NOT NULL THEN 'Plant power dip'
            WHEN CATEGORY = 'Seafood Cooking Line' THEN IFF(U_CAUSE < 0.45, 'Cook core temp below limit', IFF(U_CAUSE < 0.8, 'Steam pressure drop', 'Cook belt speed drift'))
            WHEN CATEGORY = 'Poultry Chilling Line' THEN IFF(U_CAUSE < 0.5, 'Chiller water above limit', IFF(U_CAUSE < 0.8, 'Chlorine dosing out of range', 'Chiller dwell time short'))
            WHEN CATEGORY = 'Ready Meal Packing Line' THEN IFF(U_CAUSE < 0.55, 'Metal detector reject', IFF(U_CAUSE < 0.85, 'Seal integrity fail', 'Allergen label mismatch'))
            ELSE IFF(U_CAUSE < 0.5, 'Freezer exit temp above limit', IFF(U_CAUSE < 0.8, 'Evaporator icing', 'Probe calibration drift')) END AS ROOT_CAUSE,
       SANITATION_DUE, SANITATION_DONE,
       ROUND(OPERATING_HOURS * (24 + U_UNITS * 24)) AS TOTAL_PACKS,
       FLOOR(ROUND(OPERATING_HOURS * (24 + U_UNITS * 24)) *
             LEAST(0.995, GREATEST(0.84, 0.986 - 0.032 * WEAR - 0.028 * DEVIATION_COUNT - 0.012 * U_NOISE))) AS RELEASED_PACKS,
       100.0 * (PLANNED_HOURS - HOLD_HOURS) / PLANNED_HOURS AS KPI_LINE_AVAILABILITY,
       -- ATP hygiene swab (relative light units) and product temperature at the CCP exit.
       ROUND(120 + 380 * WEAR + 160 * DEVIATION_COUNT + U_NOISE * 60) AS ATP_RLU,
       ROUND(1.2 + 1.8 * WEAR + IFF(HEAT_FACTOR > 1, 1.5, 0) + U_NOISE * 0.8, 1) AS CHILL_TEMP_C,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM timed;

CREATE TABLE RAW.VERIFICATION_KITS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Seafood Cooking Line' THEN 'Core temperature probe set' WHEN 'Poultry Chilling Line' THEN 'Chlorine test kit'
                     WHEN 'Ready Meal Packing Line' THEN 'Metal detector test pieces' ELSE 'Reference thermometer' END AS KIT_TYPE,
       1 + MOD(ABS(HASH(ID, 'thfs-ccp-req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'thfs-ccp-hand')), 5) AS ON_HAND_QTY,
       IFF(MOD(ABS(HASH(ID, 'thfs-ccp-hand')), 5) < 1 + MOD(ABS(HASH(ID, 'thfs-ccp-req')), 4),
           MOD(ABS(HASH(ID, 'thfs-ccp-order')), 3), 0) AS ON_ORDER_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.PROCESSING_LINES;
