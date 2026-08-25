----------------------------------------------------------------------
-- 04: Cortex Agent — Prohibited Medication Classification
----------------------------------------------------------------------
-- Creates the agent that ties together:
--   - Cortex Search (medication name resolution)
--   - Semantic Views (drug classification + prohibition rules)
-- into a natural language interface.
----------------------------------------------------------------------

-- TODO: Ensure you're in the correct database/schema
USE DATABASE PROHIBITED_MED_AGENT;
USE SCHEMA CLASSIFICATION;

----------------------------------------------------------------------
-- STEP 1: Create the Agent
----------------------------------------------------------------------

CREATE OR REPLACE CORTEX AGENT PROHIBITED_MED_AGENT
  COMMENT = 'Determines whether a medication is prohibited in a clinical trial protocol'
  -- TODO: Choose your model
  MODEL = 'claude-3-5-sonnet'
  TOOLS = (
    -- Tool 1: Drug classification semantic view
    SEMANTIC_VIEW('DRUG_CLASSIFICATION_SV'),
    -- Tool 2: Prohibition rules semantic view
    SEMANTIC_VIEW('PROHIBITION_RULES_SV'),
    -- Tool 3: Cortex Search for medication name resolution
    CORTEX_SEARCH('MEDICATION_RESOLVER')
    -- TODO: Add EDC violations semantic view when ready
    -- , SEMANTIC_VIEW('EDC_VIOLATIONS_SV')
  )
  SYSTEM_PROMPT = '
You are a Prohibited Medication Classification Agent for clinical trials.

Your job is to determine whether a drug is prohibited in a specific clinical trial protocol.

WORKFLOW:
1. If the user provides a medication name that might be a brand name, abbreviation, or informal name,
   use the MEDICATION_RESOLVER search tool to resolve it to a canonical drug name and DrugBank ID.
2. Once you have the canonical drug name, use DRUG_CLASSIFICATION_SV to find its therapeutic class(es).
3. Use PROHIBITION_RULES_SV to check if any of those classes are prohibited in the specified protocol.

RESPONSE FORMAT:
Always include in your response:
- The resolved drug name and DrugBank ID (if resolved from a brand/informal name)
- The therapeutic class(es) the drug belongs to
- Whether the drug IS or IS NOT prohibited in the specified protocol
- If prohibited: the prohibition reason, severity (ABSOLUTE/CONDITIONAL/CAUTION), and any exception criteria
- If not prohibited: explicit confirmation that none of its classes are in the prohibited list

IMPORTANT RULES:
- If you cannot resolve a medication name, say so clearly rather than guessing
- If a drug belongs to multiple classes, check ALL of them against the prohibition list
- For CONDITIONAL prohibitions, always mention the exception criteria
- Never make up prohibition rules — only report what is in the data
- If no protocol is specified, ask which protocol to check against
'
;

----------------------------------------------------------------------
-- STEP 2: Test the Agent
----------------------------------------------------------------------
-- Run these to verify the agent works end-to-end:

-- Test 1: Direct drug name check
-- SELECT SNOWFLAKE.CORTEX.AGENT(
--   'PROHIBITED_MED_AGENT',
--   'Is Metformin prohibited in Protocol MPC-ONC-001?'
-- );

-- Test 2: Brand name resolution + check
-- SELECT SNOWFLAKE.CORTEX.AGENT(
--   'PROHIBITED_MED_AGENT',
--   'Is Lipitor prohibited in Protocol MPC-CARD-002?'
-- );

-- Test 3: Protocol summary
-- SELECT SNOWFLAKE.CORTEX.AGENT(
--   'PROHIBITED_MED_AGENT',
--   'What drug classes are prohibited in Protocol MPC-CNS-003?'
-- );

-- Test 4: Exception criteria
-- SELECT SNOWFLAKE.CORTEX.AGENT(
--   'PROHIBITED_MED_AGENT',
--   'Can a patient take baby aspirin in Protocol MPC-CARD-002?'
-- );

----------------------------------------------------------------------
-- STEP 3: Grant Access (if sharing with other roles)
----------------------------------------------------------------------
-- TODO: Adjust roles to match your access model

-- GRANT USAGE ON CORTEX AGENT PROHIBITED_MED_AGENT TO ROLE <TODO_ANALYST_ROLE>;
-- GRANT USAGE ON CORTEX SEARCH SERVICE MEDICATION_RESOLVER TO ROLE <TODO_ANALYST_ROLE>;
-- GRANT USAGE ON SEMANTIC VIEW DRUG_CLASSIFICATION_SV TO ROLE <TODO_ANALYST_ROLE>;
-- GRANT USAGE ON SEMANTIC VIEW PROHIBITION_RULES_SV TO ROLE <TODO_ANALYST_ROLE>;

----------------------------------------------------------------------
-- NOTES
----------------------------------------------------------------------
-- - The agent uses Cortex Search as a tool, so it can resolve brand names
--   before querying the semantic views
-- - Semantic views enforce join logic, so the agent can't hallucinate
--   prohibition rules that don't exist in the data
-- - To expose this agent via API (for integration with external apps):
--   CREATE MCP SERVER ... or use the Cortex Agent REST API
-- - To expose via Snowflake Intelligence (natural language in Snowsight):
--   The agent is automatically available once created
