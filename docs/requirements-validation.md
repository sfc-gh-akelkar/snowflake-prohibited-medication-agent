# Requirements Validation Questionnaire

Use this document to validate our assumptions with the Medpace team.
Walk through each section interactively — answers will update the requirements doc and templates.

---

## Section 1: Data Sources & Plumbing

### 1.1 EDC System
What EDC system are you using for medication data?
- Rave Medidata (common for CROs like Medpace)
- Veeva Vault CDMS
- Oracle InForm
- Custom / home-built
- Other

### 1.2 DrugBank Share Details
What does your DrugBank data share include?
- Which database/schema does the share land in?
- Which tables are available? (drugs, categories, drug_categorizations, products, synonyms?)
- Is it the US Drug Products package, Biomedical Knowledge, or both?
- How often does the share refresh?

### 1.3 EDC Data Pipeline
How does medication data get from EDC into Snowflake?
- Real-time streaming
- Scheduled ETL (how often?)
- Manual extract/load
- Not in Snowflake yet (needs to be set up)

### 1.4 FDA Label Data
Where should FDA drug label data come from?
- Install the FDA DailyMed marketplace listing (auto-refreshing, zero ETL)
- Already have FDA data loaded somewhere in Snowflake
- Pull from FDA OpenFDA API
- Not needed for initial version

### 1.5 Protocol Prohibition Rules
Where do prohibition rules live today?
- Structured in a database table
- In protocol documents (PDF/Word)
- In the heads of clinical ops staff (tribal knowledge)
- In a separate clinical trial management system (CTMS)
- Combination of the above

---

## Section 2: Business Logic (Critical — Changes the Data Model)

### 2.1 Prohibition Granularity
Are prohibitions defined at the therapeutic class level, individual drug level, or both?
- Always class-level (e.g., "all SSRIs are prohibited")
- Sometimes individual drugs (e.g., "Warfarin specifically, but other anticoagulants are OK")
- Both — classes are the norm but exceptions exist for specific drugs
- Varies by protocol

WHY THIS MATTERS: If individual drug exceptions exist within a prohibited class, we need an exceptions table, not just class-level rules.

### 2.2 Combination Products
How should combination products be handled?
- Example: Advair = fluticasone (corticosteroid) + salmeterol (bronchodilator)
- If corticosteroids are prohibited but bronchodilators aren't, is Advair prohibited?
- Options:
  - Prohibited if ANY component is in a prohibited class
  - Prohibited only if the PRIMARY component is prohibited
  - Flag for manual review (don't auto-determine)

### 2.3 Severity Levels
What severity levels do you use for prohibitions?
- Our assumption: ABSOLUTE (never allowed), CONDITIONAL (exceptions possible), CAUTION (monitor)
- Does your system use different terminology?
- Are there more granular levels?

### 2.4 Dose-Dependent Prohibitions
Are any prohibitions dose-dependent?
- Example: "Aspirin 81mg for cardiac prophylaxis is allowed, but aspirin 325mg+ is prohibited"
- Example: "Low-dose corticosteroids (≤10mg prednisone equivalent) allowed, higher doses prohibited"
- If yes: Does the dose threshold vary by protocol?

WHY THIS MATTERS: If dose matters, the agent needs to parse dosage from the EDC entry and compare against thresholds — significantly more complex than class-level yes/no.

### 2.5 Temporal Rules
Do timing considerations affect prohibition status?
- Washout periods: "Drug must be stopped ≥30 days before enrollment"
- Ongoing vs. prior use: "Currently taking" vs. "took it 6 months ago"
- Time-limited prohibitions: "Prohibited during treatment phase only, allowed during follow-up"

WHY THIS MATTERS: If washout periods exist, we need start/stop dates from EDC and date math in the agent's logic.

### 2.6 Rule Changes
Do prohibition rules ever change during a study?
- Locked at protocol finalization (never change)
- Can change via protocol amendments
- If amendments happen: Do we need to track which version of the rules applied at a given time?

---

## Section 3: Edge Cases

### 3.1 Medication Scope
Which medication types are in scope for prohibition checking?
- Prescription medications only
- Prescription + OTC
- Prescription + OTC + supplements/herbals
- Prescription + OTC + supplements + vaccines

### 3.2 Route of Administration
Does route matter?
- Example: Topical corticosteroid cream (local) vs. oral prednisone (systemic)
- If systemic corticosteroids are prohibited, are topical formulations also prohibited?
- Options:
  - All routes treated the same
  - Systemic only (oral, IV, IM) — topical/inhaled excluded
  - Protocol-specific (some protocols exclude topical, others don't)

### 3.3 PRN Medications
How should PRN (as-needed) medications be handled?
- Treated the same as scheduled medications
- Different rules apply (e.g., PRN NSAIDs allowed, scheduled NSAIDs not)
- Flag but don't auto-determine

### 3.4 Unresolvable Entries
What should happen when the agent can't resolve a medication name?
- Flag for human review with a "could not determine" status
- Attempt a best-guess match and flag as low confidence
- Reject and require the site to re-enter with a clearer name

---

## Section 4: Integration & Users

### 4.1 Primary Users
Who will use this agent?
- Data managers (reviewing EDC data quality)
- Clinical operations (study startup, eligibility review)
- Medical monitors (safety oversight)
- Site coordinators (at point of data entry)
- Regulatory/compliance team
- Multiple of the above

### 4.2 Interaction Mode
How should users interact with the agent?
- Natural language via Snowflake Intelligence (ad-hoc questions)
- API integration into an existing application (which one?)
- Batch processing (scan all EDC entries nightly, generate violation report)
- Real-time check at point of EDC entry
- Multiple modes needed

### 4.3 Output Format
What should the agent produce?
- Natural language explanation (conversational)
- Structured determination record (protocol_id, drug, status, reason, severity)
- Both — explanation for humans, structured record for systems
- Formal document suitable for regulatory inspection

### 4.4 Escalation Path
When the agent flags a violation, what happens next?
- Informational only — human makes the final call
- Auto-generates a query to the site
- Triggers a workflow in another system (which?)
- Nothing automated — just available for ad-hoc lookup

---

## Section 5: Security & Compliance

### 5.1 Data Sensitivity
Is participant-level medication data considered PHI?
- Yes — full HIPAA protections required
- Partially — de-identified but still sensitive
- No — medication data is de-identified in Snowflake

### 5.2 Access Control
Who should have access to the agent?
- Anyone with access to the Snowflake account
- Specific roles only (which?)
- Different levels: some see aggregate results, others see participant-level detail
- Protocol-specific access (can only query protocols you're assigned to)

### 5.3 Audit Requirements
Is there a regulatory audit requirement for prohibition determinations?
- Yes — 21 CFR Part 11 applies (need immutable audit trail)
- Yes — but less formal (just need to log who asked what and when)
- No — advisory tool, not a system of record

### 5.4 Data Residency
Any constraints on where data can be processed?
- Must stay in specific Snowflake region
- No constraints
- Specific model restrictions (can't use external LLM providers?)

---

## Section 6: Scale & Performance

### 6.1 Volume
Approximately how many:
- Active protocols with prohibition rules? (5? 50? 500?)
- Medications per participant? (5-10? 20-50?)
- Total EDC medication entries to check? (hundreds? thousands? millions?)

### 6.2 Latency Requirements
How fast does the determination need to be?
- Real-time (< 3 seconds) — for point-of-entry checking
- Near-real-time (< 30 seconds) — for ad-hoc queries
- Batch is fine (minutes/hours) — for periodic reports

---

## After Validation

Once answers are collected:
1. Update `docs/requirements.md` — mark open questions as resolved
2. Adjust `templates/01-data-model.sql` — add/remove columns, tables based on answers
3. Update agent system prompt in `templates/04-agent.sql` — reflect business logic decisions
4. Document any out-of-scope decisions for future phases
