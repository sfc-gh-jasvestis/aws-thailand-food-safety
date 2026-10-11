# Food Safety CCP Monitor

**Thailand - Food Processing**
Use case: HACCP Critical Control Point Monitoring

> CCP monitoring for 24 synthetic food processing lines (seafood cooking, poultry chilling, ready meal packing, blast freezing) at a fictional food processor in six Thai plant cities. Dynamic tables, a holdout-evaluated CCP deviation risk classifier, a CCP hold hours forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile line KPIs from RAW CCP readings, with checks in `run_core.py`
- **CCP deviation risk classification** gives a holdout-evaluated next-7-day deviation risk per line
- **CCP hold forecast** projects 14 days of plant-network CCP hold hours with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations. The memo is written by Cortex AI_COMPLETE (Snowflake build) or Amazon Bedrock (AWS build).
- **Live ingestion**: `APP.SIMULATE_TELEMETRY` in the Snowflake build, or IoT Core to S3 to Snowpipe auto-ingest in the AWS build, then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.PROCESSING_LINES` (24 rows) |
| Fact table | `RAW.CCP_READINGS` (2,160 line-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `DEVIATION_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.DEVIATION_RISK_SCORES`, `ML.DEVIATION_RISK_HOLDOUT_METRICS`, `ML.HOLD_FORECAST`, `ML.ATP_ANOMALIES` |

Plant cities: Samut Sakhon, Chonburi, Nakhon Pathom, Songkhla, Chiang Mai, Surat Thani.
Line types: Seafood Cooking Line, Poultry Chilling Line, Ready Meal Packing Line, Blast Freezing Line.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value in a fresh build |
|---|---|
| Line Availability | 98.9% (98.92%) |
| CCP Deviations | 176 |
| Hours Between Deviations | 207.6 hrs |
| Lines Monitored | 24 |
| Kits on Order | 15 |
| Verification Kit Coverage | 72.4% |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded.

## Demo flow

1. Executive Cockpit (Siriporn Chaiwattana): KPIs, daily line availability and CCP hold hours by deviation cause; metal detector rejects lead the hours on hold
2. Predictive (Nattapong Srisuk): holdout metrics, risk bands, 14-day CCP hold hours forecast, ATP swab anomalies
3. HACCP Planning: verification kit coverage, sanitation verification completion against first-pass release, then Generate a memo written from Snowflake tables only
4. Live IoT: run `CALL APP.SIMULATE_TELEMETRY(20)` (Snowflake build) or `python aws/publish_telemetry.py --count 20` (AWS build; messages arrive about 20-60 s later through IoT Core, S3 and Snowpipe). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build only): the same Snowflake tables through DIRECT_QUERY; risk and IoT visuals
7. Architecture: both diagrams, the current build first

## Talking points

- Availability ranges from 94.39% to 100% by line, and Chiang Mai is the lowest plant city at 97.34%. CCP hold hours are concentrated in a few lines.
- Ready meal packing lines lose the most hours (176.6 h); metal detector rejects (82.2 h) and cook core temperatures below limit (72.0 h) are the top two causes.
- The risk model is evaluated on a time-based holdout: precision 0.67 and recall 0.53 at 0.5, against a 0.30 base rate. Present it as triage, not a guarantee.
- Plant power dips (Songkhla and Samut Sakhon) are excluded from deviation labels.
- SOPs and limits are illustrative demo content, not a regulatory HACCP plan.

## Business impact

Use only the sourced references in `README.md` (Business Impact).

---
Hand-maintained.
