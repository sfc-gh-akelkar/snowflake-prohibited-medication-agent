# Cortex Code Instructions

This repo contains scaffolding for building a Prohibited Medication Classification Agent.
The templates in `templates/` have TODO placeholders — replace them with real data sources and execute.

## Project Context

- Use case: Determine if a drug is prohibited in a clinical trial protocol
- Pattern: EDC free-text → Cortex Search (resolve name) → SQL joins (drug → category → prohibition rule) → Agent response
- Data sources: DrugBank (share), FDA labels (marketplace or loaded), EDC medications (first party), protocol rules (first party)

## Build Order

Execute templates in numbered order:
1. `templates/01-data-model.sql` — Create schema and tables
2. `templates/02-cortex-search.sql` — Create search service for medication name resolution
3. `templates/03-semantic-views.sql` — Create semantic views encoding business logic
4. `templates/04-agent.sql` — Create the agent with tools

## Conventions

- All objects live in a single database/schema (configurable in step 1)
- SQL templates use `-- TODO:` comments where customization is needed
- Security: apply row access policies and masking after the base objects are created
- The agent should always explain its reasoning, not just return yes/no
