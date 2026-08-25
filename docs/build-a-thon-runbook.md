# Build-a-Thon Runbook

## Session Goal

Build a working Prohibited Medication Classification Agent using real Medpace data sources, live in Cortex Code Desktop.

## Pre-Session Checklist

- [ ] Scott has Cortex Code Desktop installed (private preview or GA)
- [ ] This repo is cloned locally
- [ ] DrugBank data share is accessible in the target Snowflake account
- [ ] FDA data source decision made (marketplace listing vs. direct load)
- [ ] Scott has a role with CREATE DATABASE, CREATE SCHEMA, CREATE CORTEX SEARCH SERVICE, CREATE SEMANTIC VIEW, CREATE CORTEX AGENT privileges (or SYSADMIN)
- [ ] EDC medication sample data is available (even a small extract works)

## Session Agenda

### Phase 1: Orient (10 min)

1. Review `docs/requirements.md` together
2. Scott updates open questions with real answers:
   - Actual DrugBank share schema and table names
   - EDC system details and data format
   - Where protocol prohibition rules live
   - Security/access requirements
3. Align on scope for the session

### Phase 2: Data Layer (20 min)

1. Open `templates/01-data-model.sql` in CoCo
2. Replace `TODO` placeholders with real references:
   - Point to actual DrugBank share tables
   - Create `PROTOCOL_PROHIBITED_CLASSES` with real protocol rules
   - Create `DRUG_SYNONYMS` if one doesn't already exist
3. Execute DDL to create the schema

### Phase 3: Cortex Search (15 min)

1. Open `templates/02-cortex-search.sql`
2. Configure the search service over the drug names/synonyms corpus
3. Test with sample medication entries from EDC
4. Verify fuzzy matching works for their naming patterns

### Phase 4: Semantic Views (20 min)

1. Open `templates/03-semantic-views.sql`
2. Define entities, relationships, and metrics over the actual tables
3. Add verified queries (VQRs) for their most common questions
4. Validate the semantic view compiles and answers test questions

### Phase 5: Agent (15 min)

1. Open `templates/04-agent.sql`
2. Create the agent with semantic views + cortex search as tools
3. Configure system prompt for their specific workflow
4. Test end-to-end with real questions

### Phase 6: Validate & Iterate (10 min)

1. Test the full flow: EDC entry → name resolution → classification → answer
2. Identify gaps (missing drug mappings, incorrect classifications)
3. Discuss next steps: production hardening, access controls, integration

## Fallback Plan

If a component isn't working:
- **DrugBank share not ready** → Use a small manually-created drug table with 20-30 drugs for the session
- **EDC data not available** → Create a handful of test medication entries by hand
- **Protocol rules not structured** → Pick one protocol, manually encode 5-10 prohibited classes
- **Cortex Search issues** → Skip to semantic views (name resolution can be added later)

## Post-Session Deliverables

- [ ] Working agent in Medpace's Snowflake account (even if limited scope)
- [ ] List of gaps/open items to resolve before production
- [ ] Clear next steps and owners
- [ ] This repo updated with Medpace-specific customizations (committed by Scott)
