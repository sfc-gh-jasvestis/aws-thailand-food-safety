# Demo Script: Food Safety & Quality Compliance
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake parses inspection reports with AI, indexes Thai FDA regulations for instant search, detects compliance anomalies, and auto-alerts quality teams — replacing paper-based food safety with AI-native compliance"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Dr. Pimchanok Vongsiri** | VP Food Safety & Quality | React App (SPCS) | Compliance rates, recall risk, audit readiness, cost of non-compliance |
| **Suthep Kruengsakul** | Quality Control Manager | Amazon QuickSight | Microbial test results, HACCP CCP monitoring, chemical residue levels, traceability |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 8 tables | FACILITIES (45), INSPECTION_REPORTS (680), LAB_RESULTS (120000), CCP_MONITORING (500000), CORRECTIVE_ACTIONS (4500), FOOD_REGULATIONS (300), TRACEABILITY (200000), THAI_FOOD_INDUSTRY (10) |
| **CURATED** | 4 Dynamic Tables | FACILITY_COMPLIANCE_SCORE, CCP_DEVIATION_TRENDS, RECALL_RISK_INDEX, REGULATION_COMPLIANCE_GAP |
| **ML** | ML.FORECAST + ML.ANOMALY_DETECTION | Forecasting + anomaly detection |
| **AI** | AI_PARSE_DOCUMENT, AI_CLASSIFY, SUMMARIZE | Classification + extraction |
| **Search** | Cortex Search | 300 documents indexed |
| **Agent** | FOOD_SAFETY_AGENT | Semantic View + Search tools |


---

## The Story

Thailand exports ฿1.1 trillion in food annually — but 6 of 45 processing facilities are below compliance threshold, generating ฿420M in non-compliance costs. Paper-based inspection tracking and manual regulation lookup mean violations are caught too late. AI-native food safety monitoring closes the gap from weeks to hours.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "Overall compliance rate: 91.4% — target is 98%. Six facilities below threshold."

**Action**: Point at compliance rate gauge (91.4% vs 98% target)

### [0:45–1:30] CCP MONITORING

**Show**: CCP Monitoring tab

> "500K CCP monitoring records — thermal processing, metal detection, chemical limits."

**Action**: Show CCP dashboard with status indicators

### [1:30–2:15] REGULATORY INTELLIGENCE

**Show**: Regulatory Intelligence tab

> "Cortex Search indexes 300 regulatory documents — Thai FDA, CODEX, EU, Japan, US FDA."

**Action**: Demo Cortex Search on food regulations

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Dr. Pimchanok asks: 'Which facilities are at highest recall risk right now?'"

**Action**: Type: 'Facilities ranked by recall risk score'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Seven Snowflake capabilities, six AWS services."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **AI_PARSE_DOCUMENT on Thai FDA inspection reports** — Only demo extracting structured compliance data from Thai-language food safety documents
2. **Cortex Search on food regulations (Thai + international)** — Natural language search across Thai FDA, CODEX, EU, Japan, and US regulations
3. **Real-time CCP monitoring with ML.ANOMALY_DETECTION** — Anomaly detection on HACCP critical control points detecting systematic drift
4. **Thai food industry context** — 45 facilities producing seafood, poultry, and prepared meals for export markets
5. **Recall risk prediction** — Composite risk scoring combining lab results, CCP deviations, and inspection findings
6. **Multi-market regulatory compliance** — Simultaneous compliance checking against Thai, EU, Japan, and US food safety standards


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM FOOD_SAFETY.RAW.CCP_MONITORING` → 500000
- [ ] `SELECT COUNT(*) FROM FOOD_SAFETY.RAW.INSPECTION_REPORTS` → 680
- [ ] `SELECT COUNT(*) FROM FOOD_SAFETY.CURATED.FACILITY_COMPLIANCE_SCORE WHERE COMPLIANCE_RATE < 0.98` → 6

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM FOOD_SAFETY.ML.CCP_DEVIATION_FORECAST_RESULTS` → >0
- [ ] `SELECT SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) FROM FOOD_SAFETY.ML.LAB_RESULT_ANOMALY_RESULTS` → >=10

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM FOOD_SAFETY.AI.PARSED_INSPECTION_FINDINGS` → >600

