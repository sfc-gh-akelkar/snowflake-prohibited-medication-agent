----------------------------------------------------------------------
-- 02: Cortex Search Service — Medication Name Resolution
----------------------------------------------------------------------
-- This creates a search service over drug names and synonyms.
-- It enables fuzzy matching from free-text EDC entries to canonical DrugBank IDs.
----------------------------------------------------------------------

-- TODO: Ensure you're in the correct database/schema
USE DATABASE PROHIBITED_MED_AGENT;
USE SCHEMA CLASSIFICATION;

----------------------------------------------------------------------
-- STEP 1: Create a search corpus table
----------------------------------------------------------------------
-- This flattens drug canonical names + all synonyms into a single searchable corpus.
-- Each row represents one searchable term pointing to a DrugBank ID.

CREATE OR REPLACE TABLE DRUG_SEARCH_CORPUS AS
SELECT
    DRUGBANK_ID,
    SYNONYM AS SEARCHABLE_NAME,
    SYNONYM_TYPE AS NAME_TYPE
FROM DRUG_SYNONYMS

UNION ALL

-- Also include the canonical drug names from DrugBank
SELECT
    DRUGBANK_ID,
    NAME AS SEARCHABLE_NAME,
    'canonical' AS NAME_TYPE
FROM DRUGS;  -- TODO: adjust if your DrugBank view has a different name

-- TODO: If you have PRODUCTS with brand names, add them too:
-- UNION ALL
-- SELECT DRUG_ID, NAME, 'product' FROM PRODUCTS;

----------------------------------------------------------------------
-- STEP 2: Create the Cortex Search Service
----------------------------------------------------------------------
-- TODO: Adjust warehouse name if needed

CREATE OR REPLACE CORTEX SEARCH SERVICE MEDICATION_RESOLVER
  ON DRUG_SEARCH_CORPUS
  WAREHOUSE = -- TODO: your warehouse name
  TARGET_LAG = '1 hour'
  AS (
    SELECT
        SEARCHABLE_NAME,
        DRUGBANK_ID,
        NAME_TYPE
    FROM DRUG_SEARCH_CORPUS
  );

-- The search service indexes SEARCHABLE_NAME for fuzzy text matching
-- and returns DRUGBANK_ID + NAME_TYPE as metadata columns.

----------------------------------------------------------------------
-- STEP 3: Test the search service
----------------------------------------------------------------------
-- Run these queries to verify name resolution works:

-- Test 1: Brand name
-- SELECT PARSE_JSON(
--   SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
--     'MEDICATION_RESOLVER',
--     '{"query": "lipitor", "columns": ["SEARCHABLE_NAME", "DRUGBANK_ID", "NAME_TYPE"], "limit": 3}'
--   )
-- ) AS results;

-- Test 2: Abbreviation
-- SELECT PARSE_JSON(
--   SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
--     'MEDICATION_RESOLVER',
--     '{"query": "ASA", "columns": ["SEARCHABLE_NAME", "DRUGBANK_ID", "NAME_TYPE"], "limit": 3}'
--   )
-- ) AS results;

-- Test 3: Misspelling
-- SELECT PARSE_JSON(
--   SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
--     'MEDICATION_RESOLVER',
--     '{"query": "metforman", "columns": ["SEARCHABLE_NAME", "DRUGBANK_ID", "NAME_TYPE"], "limit": 3}'
--   )
-- ) AS results;

----------------------------------------------------------------------
-- NOTES
----------------------------------------------------------------------
-- - TARGET_LAG controls how often the index refreshes (1 hour is fine for drug reference data)
-- - The search service handles: fuzzy matching, partial matches, typo tolerance
-- - Results include a relevance score — use the top result for high-confidence matches
-- - For combination products (e.g., "Advair"), you may need custom handling
--   to resolve to multiple DrugBank IDs (one per active ingredient)
