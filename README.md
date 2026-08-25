# Prohibited Medication Classification Agent

Snowflake-native solution for automated drug prohibition determination in clinical trials.

## Purpose

This repo is a **build-a-thon scaffolding** — it documents requirements, architecture, and component templates for building a Prohibited Medication Agent on Snowflake. It is designed to be pulled into Cortex Code Desktop and built out collaboratively with real data sources.

## Architecture

![Solution Architecture](docs/architecture-screenshot.jpg)

> Open [`architecture.html`](architecture.html) in a browser for the interactive version with ER diagrams and query flow details.

## Repository Structure

```
├── README.md                      # This file
├── architecture.html              # Interactive architecture diagram
├── COCO.md                        # Instructions for Cortex Code Desktop
├── docs/
│   ├── architecture-screenshot.jpg
│   ├── requirements.md            # Use case requirements and open questions
│   └── build-a-thon-runbook.md    # Session agenda and checklist
└── templates/
    ├── 01-data-model.sql          # Table DDL scaffolding (placeholder columns)
    ├── 02-cortex-search.sql       # Cortex Search Service creation template
    ├── 03-semantic-views.sql      # Semantic View DDL templates
    └── 04-agent.sql               # Cortex Agent creation template
```

## How to Use This Repo

1. **Clone into Cortex Code Desktop** — pull the repo and open it in CoCo
2. **Review requirements** — read `docs/requirements.md`, update with your actual data sources and constraints
3. **Customize templates** — replace `TODO` placeholders in `templates/` with your real table names, columns, and business rules
4. **Build live** — use CoCo to execute each template against your Snowflake account, iterating as you go
5. **Validate** — test the agent with real questions against your real data

## Key Design Decisions

- **No graph database** — 2-3 hop traversal (drug → category → protocol rule) is a SQL join, not a graph problem
- **Cortex Search for name resolution** — handles brand names, abbreviations, misspellings at ~100ms latency
- **Semantic Views for business logic** — declarative rules that can be updated without code changes
- **Zero external dependencies** — all data and compute inside Snowflake

---

Built with [Cortex Code](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code) on Snowflake AI Data Cloud.
