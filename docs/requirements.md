# Requirements: Prohibited Medication Classification Agent

## Use Case Summary

Automate the determination of whether a drug is prohibited within a clinical trial protocol. Currently requires manual cross-referencing across multiple data sources — slow, error-prone, and blocking for study startup.

## Data Sources

| Source | Type | Owner | Status |
|--------|------|-------|--------|
| DrugBank | Data Share (inbound) | DrugBank / Medpace | Coming via existing share |
| FDA Drug Labels | TBD (Marketplace listing or direct load) | FDA / public | Needs decision |
| EDC Medications | First Party | Medpace | Exists in EDC system |
| Protocol Prohibition Rules | First Party | Medpace clinical ops | May exist in documents, not structured |

### DrugBank (Data Share)

**What we need from it:**
- Drug identifiers (DrugBank ID, name, CAS number)
- Therapeutic category assignments (drug → category mapping)
- Category hierarchy (parent/child relationships between classes)
- ATC codes for cross-referencing

**Open questions:**
- [ ] What schema/database does the DrugBank share land in?
- [ ] Which specific DrugBank tables are included in the share?
- [ ] Is the Biomedical Knowledge package included, or just US Drug Products?
- [ ] Are drug-drug interactions needed for this use case, or just classification?

### FDA Drug Labels

**What we need from it:**
- Contraindication sections (structured text)
- Boxed warnings
- Drug interaction warnings
- Effective dates for label versions

**Open questions:**
- [ ] Install the [FDA DailyMed marketplace listing](https://app.snowflake.com/marketplace/listing/GZ2FWZ5FDBO) or load directly from FDA APIs?
- [ ] Do we need full label text or just specific sections (contraindications, warnings)?
- [ ] Is DailyMed the right source, or does the team already have FDA data elsewhere?

### EDC Medications (First Party)

**What we need from it:**
- Medication name as entered (free text)
- Protocol/study assignment
- Participant identifier
- Dose, frequency, route
- Start/stop dates
- Indication (why the participant takes it)

**Open questions:**
- [ ] What EDC system is in use? (Rave, Veeva, custom?)
- [ ] How does medication data get into Snowflake today? (ETL, streaming, manual?)
- [ ] What does a typical medication entry look like? (brand name? generic? abbreviations?)
- [ ] Are there existing synonym tables or mapping dictionaries?
- [ ] What identifiers link EDC entries back to protocols and participants?

### Protocol Prohibition Rules (First Party)

**What we need from it:**
- Protocol identifier
- Prohibited therapeutic class (or specific drug, if any)
- Prohibition reason (clinical rationale)
- Severity (absolute prohibition vs. conditional/with exceptions)
- Exception criteria (when a prohibited class might be allowed)

**Open questions:**
- [ ] Where do prohibition rules live today? (Protocol documents? Structured database? SME knowledge?)
- [ ] Are prohibitions always at the class level (e.g., "all SSRIs") or sometimes specific drugs?
- [ ] How are exceptions handled? (PI discretion? Sponsor approval? Documented criteria?)
- [ ] How many active protocols have prohibition rules? (Scale of the problem)
- [ ] Do prohibition rules change during a study, or are they fixed at protocol finalization?

---

## Functional Requirements

### Core Query Types

The agent must answer:

1. **Single drug check** — "Is [drug] prohibited in [protocol]?"
2. **Batch participant check** — "Which medications for [participant] in [protocol] are prohibited?"
3. **Protocol summary** — "What drug classes are prohibited in [protocol]?"
4. **Reasoning** — "Why is [drug] prohibited in [protocol]?" (returns class, reason, FDA context)
5. **Exception check** — "Are there exceptions for [drug class] in [protocol]?"

### Name Resolution Requirements

The system must resolve messy free-text medication entries to canonical drug identifiers:

- Brand names → generic (Lipitor → Atorvastatin)
- Abbreviations → full name (ASA → Aspirin, APAP → Acetaminophen)
- Common shorthand → canonical (baby aspirin → Aspirin 81mg)
- Combination products → individual components (Advair → Fluticasone + Salmeterol)
- Misspellings → closest match (metforman → Metformin)

### Response Requirements

Every prohibition determination should include:
- Resolved drug name and identifier
- Therapeutic class(es) the drug belongs to
- Whether any class is prohibited in the specified protocol
- Prohibition reason and severity level
- Exception criteria (if severity is CONDITIONAL)
- Relevant FDA label context (contraindications, warnings)

---

## Non-Functional Requirements

### Security

- [ ] What roles should have access to the agent?
- [ ] Is participant-level EDC data sensitive? (HIPAA, de-identified, or fully identified?)
- [ ] Are there row-access or masking requirements on EDC data?
- [ ] Should the agent be accessible via API (external apps) or only via Snowflake Intelligence?
- [ ] Are there audit requirements for prohibition determinations?

### Performance

- Single drug checks: < 5 seconds response time
- Batch participant checks: < 15 seconds for a typical participant's medication list
- Name resolution: < 1 second per medication entry

### Data Freshness

- DrugBank: updated per share refresh schedule
- FDA labels: depends on source (marketplace listing auto-refreshes; manual load needs a schedule)
- EDC medications: depends on ETL/streaming cadence from EDC system
- Protocol rules: manually maintained (low change frequency)

---

## Components to Build

| # | Component | Purpose | Template |
|---|-----------|---------|----------|
| 1 | Data model tables | Structured prohibition rules + drug synonyms | `templates/01-data-model.sql` |
| 2 | Cortex Search Service | Fuzzy medication name resolution | `templates/02-cortex-search.sql` |
| 3 | Semantic Views | Business logic for classification and violation detection | `templates/03-semantic-views.sql` |
| 4 | Cortex Agent | Natural language interface for prohibition queries | `templates/04-agent.sql` |

## Out of Scope (for now)

- Writeback to EDC system (flagging violations in-place)
- Automated alerting/notification on new violations
- Protocol amendment tracking (rule changes over time)
- Drug-drug interaction checking (separate from prohibition)
- Regulatory submission documentation
