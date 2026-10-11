-- Validate the producer contract before building downstream objects.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

EXECUTE IMMEDIATE $$
DECLARE
  violations INTEGER;
  invalid_source EXCEPTION (-20001, 'Synthetic source failed grain or measure validation');
BEGIN
  SELECT COUNT(*) INTO :violations FROM (
    SELECT ENTITY_ID, EVENT_DATE
    FROM RAW.CCP_READINGS
    GROUP BY ENTITY_ID, EVENT_DATE HAVING COUNT(*) <> 1
    UNION ALL
    SELECT observation.ENTITY_ID, observation.EVENT_DATE
    FROM RAW.CCP_READINGS observation
    LEFT JOIN RAW.PROCESSING_LINES pline ON pline.ID = observation.ENTITY_ID
    WHERE pline.ID IS NULL OR observation.PLANNED_HOURS <= 0
       OR observation.OPERATING_HOURS < 0 OR observation.HOLD_HOURS < 0
       OR observation.OPERATING_HOURS + observation.HOLD_HOURS <> observation.PLANNED_HOURS
       OR observation.RELEASED_PACKS < 0 OR observation.RELEASED_PACKS > observation.TOTAL_PACKS
       OR observation.SANITATION_DONE > observation.SANITATION_DUE
  );
  IF (violations > 0) THEN
    RAISE invalid_source;
  END IF;
END;
$$;
