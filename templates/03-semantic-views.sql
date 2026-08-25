----------------------------------------------------------------------
-- 03: Semantic Views — Business Logic for Prohibition Classification
----------------------------------------------------------------------
-- These semantic views encode the relationships and rules that the
-- Cortex Agent uses to answer prohibition questions.
----------------------------------------------------------------------

-- TODO: Ensure you're in the correct database/schema
USE DATABASE PROHIBITED_MED_AGENT;
USE SCHEMA CLASSIFICATION;

----------------------------------------------------------------------
-- SEMANTIC VIEW 1: Drug Classification
----------------------------------------------------------------------
-- Purpose: Answer "What class does Drug X belong to?"
-- Entities: drugs, categories, drug_categorizations
-- TODO: Adjust table/column names to match your actual DrugBank share schema

CREATE OR REPLACE SEMANTIC VIEW DRUG_CLASSIFICATION_SV
  AS
    -- TODO: Replace with your actual table references and column names
    TABLES (
        DRUGS
            WITH COLUMNS (
                DRUGBANK_ID DESCRIPTION 'Unique DrugBank identifier (e.g., DB00945)',
                NAME DESCRIPTION 'Canonical drug name (e.g., Atorvastatin)'
                -- TODO: Add other relevant columns from your DrugBank share
            ),
        CATEGORIES
            WITH COLUMNS (
                CATEGORY_ID DESCRIPTION 'DrugBank category identifier',
                TITLE DESCRIPTION 'Therapeutic category name (e.g., HMG-CoA Reductase Inhibitors)',
                CATEGORIZATION_KIND DESCRIPTION 'Type: therapeutic, pharmacological, or indexing'
                -- TODO: Add ATC_CODE if available
            ),
        DRUG_CATEGORIZATIONS
            WITH COLUMNS (
                DRUG_ID DESCRIPTION 'References DRUGS.DRUGBANK_ID',
                CATEGORY_ID DESCRIPTION 'References CATEGORIES.CATEGORY_ID'
            )
    )
    RELATIONSHIPS (
        DRUG_CATEGORIZATIONS (DRUG_ID) REFERENCES DRUGS (DRUGBANK_ID),
        DRUG_CATEGORIZATIONS (CATEGORY_ID) REFERENCES CATEGORIES (CATEGORY_ID)
    )

    -- TODO: Add verified queries for common questions
    -- VERIFIED QUERIES (
    --   'What therapeutic class does Atorvastatin belong to?' AS
    --     'SELECT d.NAME, c.TITLE AS therapeutic_class
    --      FROM DRUGS d
    --      JOIN DRUG_CATEGORIZATIONS dc ON dc.DRUG_ID = d.DRUGBANK_ID
    --      JOIN CATEGORIES c ON c.CATEGORY_ID = dc.CATEGORY_ID
    --      WHERE d.NAME = ''Atorvastatin''
    --      AND c.CATEGORIZATION_KIND = ''therapeutic''',
    --
    --   'What drugs are in the SSRI class?' AS
    --     'SELECT d.NAME, d.DRUGBANK_ID
    --      FROM DRUGS d
    --      JOIN DRUG_CATEGORIZATIONS dc ON dc.DRUG_ID = d.DRUGBANK_ID
    --      JOIN CATEGORIES c ON c.CATEGORY_ID = dc.CATEGORY_ID
    --      WHERE c.TITLE ILIKE ''%Selective Serotonin Reuptake%'''
    -- )
;

----------------------------------------------------------------------
-- SEMANTIC VIEW 2: Protocol Prohibition Rules
----------------------------------------------------------------------
-- Purpose: Answer "What is prohibited in Protocol X and why?"
-- Entities: clinical_protocols, protocol_prohibited_classes, categories

CREATE OR REPLACE SEMANTIC VIEW PROHIBITION_RULES_SV
  AS
    TABLES (
        CLINICAL_PROTOCOLS
            WITH COLUMNS (
                PROTOCOL_ID DESCRIPTION 'Unique protocol identifier (e.g., MPC-ONC-001)',
                PROTOCOL_NAME DESCRIPTION 'Full protocol title',
                THERAPEUTIC_AREA DESCRIPTION 'Clinical area: Oncology, Cardiology, CNS, etc.',
                PHASE DESCRIPTION 'Trial phase: Phase I, II, III, IV',
                STATUS DESCRIPTION 'Current status: Enrolling, Active, Completed'
            ),
        PROTOCOL_PROHIBITED_CLASSES
            WITH COLUMNS (
                PROTOCOL_ID DESCRIPTION 'References CLINICAL_PROTOCOLS.PROTOCOL_ID',
                CATEGORY_ID DESCRIPTION 'Prohibited therapeutic category ID',
                CATEGORY_TITLE DESCRIPTION 'Human-readable name of prohibited class',
                PROHIBITION_REASON DESCRIPTION 'Clinical rationale for why this class is prohibited',
                SEVERITY DESCRIPTION 'ABSOLUTE (no exceptions), CONDITIONAL (exceptions possible), CAUTION (monitor closely)',
                EXCEPTION_CRITERIA DESCRIPTION 'Conditions under which the prohibition can be waived'
            )
    )
    RELATIONSHIPS (
        PROTOCOL_PROHIBITED_CLASSES (PROTOCOL_ID) REFERENCES CLINICAL_PROTOCOLS (PROTOCOL_ID)
    )

    -- TODO: Add verified queries
    -- VERIFIED QUERIES (
    --   'What drug classes are prohibited in Protocol MPC-ONC-001?' AS
    --     'SELECT CATEGORY_TITLE, PROHIBITION_REASON, SEVERITY, EXCEPTION_CRITERIA
    --      FROM PROTOCOL_PROHIBITED_CLASSES
    --      WHERE PROTOCOL_ID = ''MPC-ONC-001''
    --      ORDER BY SEVERITY',
    --
    --   'Which protocols prohibit anticoagulants?' AS
    --     'SELECT p.PROTOCOL_ID, p.PROTOCOL_NAME, ppc.PROHIBITION_REASON, ppc.SEVERITY
    --      FROM PROTOCOL_PROHIBITED_CLASSES ppc
    --      JOIN CLINICAL_PROTOCOLS p ON p.PROTOCOL_ID = ppc.PROTOCOL_ID
    --      WHERE ppc.CATEGORY_TITLE ILIKE ''%anticoagulant%'''
    -- )
;

----------------------------------------------------------------------
-- SEMANTIC VIEW 3: EDC Violation Detection (optional, more advanced)
----------------------------------------------------------------------
-- Purpose: Answer "Which EDC medications for participant X are prohibited?"
-- This view combines EDC entries with the drug classification and prohibition rules.
-- NOTE: Name resolution via Cortex Search happens at the agent layer, not here.
-- This view assumes the DRUGBANK_ID has already been resolved.

-- TODO: This is the most complex view — you may want to build a helper table
-- that stores resolved EDC entries (medication_text → drugbank_id) from
-- Cortex Search results, then join that into this semantic view.

-- Placeholder for future implementation:
-- CREATE OR REPLACE SEMANTIC VIEW EDC_VIOLATIONS_SV AS ...

----------------------------------------------------------------------
-- VERIFICATION
----------------------------------------------------------------------
-- After creating semantic views, test them:
--
-- DESCRIBE SEMANTIC VIEW DRUG_CLASSIFICATION_SV;
-- DESCRIBE SEMANTIC VIEW PROHIBITION_RULES_SV;
--
-- Test with Cortex Analyst:
-- SELECT SNOWFLAKE.CORTEX.COMPLETE('claude-3-5-sonnet',
--   'Using semantic view DRUG_CLASSIFICATION_SV, what class does Metformin belong to?'
-- );
