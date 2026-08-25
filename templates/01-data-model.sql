----------------------------------------------------------------------
-- 01: Data Model — Prohibited Medication Classification Agent
----------------------------------------------------------------------
-- Execute this first. Replace all TODO placeholders with your actual values.
----------------------------------------------------------------------

-- TODO: Set your target database and schema
CREATE DATABASE IF NOT EXISTS PROHIBITED_MED_AGENT;
USE DATABASE PROHIBITED_MED_AGENT;
CREATE SCHEMA IF NOT EXISTS CLASSIFICATION;
USE SCHEMA CLASSIFICATION;

----------------------------------------------------------------------
-- STEP 1: Reference your DrugBank data share
----------------------------------------------------------------------
-- TODO: Replace with your actual DrugBank share database/schema
-- These are views or references pointing to your DrugBank share tables.
-- If your share has different table/column names, adjust accordingly.

-- Example: If DrugBank share lands in DRUGBANK_SHARE.PUBLIC
-- CREATE OR REPLACE VIEW DRUGS AS SELECT * FROM DRUGBANK_SHARE.PUBLIC.DRUGS;
-- CREATE OR REPLACE VIEW CATEGORIES AS SELECT * FROM DRUGBANK_SHARE.PUBLIC.CATEGORIES;
-- CREATE OR REPLACE VIEW DRUG_CATEGORIZATIONS AS SELECT * FROM DRUGBANK_SHARE.PUBLIC.DRUG_CATEGORIZATIONS;

-- TODO: Uncomment and adjust these views to point at your share
/*
CREATE OR REPLACE VIEW DRUGS AS
SELECT
    drugbank_id,
    name,
    description,
    cas_number,
    state
FROM <TODO_DRUGBANK_DATABASE>.<TODO_SCHEMA>.DRUGS;

CREATE OR REPLACE VIEW CATEGORIES AS
SELECT
    id AS category_id,
    title,
    categorization_kind,    -- therapeutic, pharmacological, indexing
    -- TODO: confirm if ATC codes are in category_mappings or directly on categories
    NULL AS atc_code
FROM <TODO_DRUGBANK_DATABASE>.<TODO_SCHEMA>.CATEGORIES;

CREATE OR REPLACE VIEW DRUG_CATEGORIZATIONS AS
SELECT
    drug_id,
    category_id
FROM <TODO_DRUGBANK_DATABASE>.<TODO_SCHEMA>.DRUG_CATEGORIZATIONS;
*/

----------------------------------------------------------------------
-- STEP 2: Drug synonyms table (for Cortex Search)
----------------------------------------------------------------------
-- This table feeds the Cortex Search index for medication name resolution.
-- Populate with brand names, abbreviations, and common shorthand.
-- If DrugBank share includes synonyms, union them in.

CREATE OR REPLACE TABLE DRUG_SYNONYMS (
    DRUGBANK_ID    VARCHAR(10)   NOT NULL,   -- e.g., DB00945
    SYNONYM        VARCHAR(200)  NOT NULL,   -- e.g., "Lipitor", "ASA", "baby aspirin"
    SYNONYM_TYPE   VARCHAR(50),              -- brand, abbreviation, common_name, international, canonical
    SOURCE         VARCHAR(50)               -- drugbank, manual, fda_label
);

-- TODO: Populate from DrugBank share (if synonym data is available)
-- INSERT INTO DRUG_SYNONYMS (DRUGBANK_ID, SYNONYM, SYNONYM_TYPE, SOURCE)
-- SELECT drugbank_id, synonym, 'brand', 'drugbank'
-- FROM <TODO_DRUGBANK_DATABASE>.<TODO_SCHEMA>.DRUG_SYNONYMS;

-- TODO: Add manual entries for known abbreviations your EDC coordinators use
-- INSERT INTO DRUG_SYNONYMS VALUES
--   ('DB00945', 'ASA', 'abbreviation', 'manual'),
--   ('DB00316', 'APAP', 'abbreviation', 'manual'),
--   ('DB00316', 'Tylenol', 'brand', 'manual');

----------------------------------------------------------------------
-- STEP 3: Protocol prohibition rules
----------------------------------------------------------------------
-- This is the novel table — encodes which therapeutic classes are prohibited
-- per clinical trial protocol. This data likely lives in protocol documents
-- or in the heads of clinical ops staff today.

CREATE OR REPLACE TABLE CLINICAL_PROTOCOLS (
    PROTOCOL_ID       VARCHAR(50)   NOT NULL,   -- e.g., MPC-ONC-001
    PROTOCOL_NAME     VARCHAR(200),
    THERAPEUTIC_AREA  VARCHAR(100),              -- Oncology, Cardiology, CNS, etc.
    PHASE             VARCHAR(20),               -- Phase I, II, III, IV
    SPONSOR           VARCHAR(100),
    STATUS            VARCHAR(50),               -- Enrolling, Active, Completed
    PRIMARY KEY (PROTOCOL_ID)
);

CREATE OR REPLACE TABLE PROTOCOL_PROHIBITED_CLASSES (
    PROTOCOL_ID         VARCHAR(50)   NOT NULL,
    CATEGORY_ID         VARCHAR(50)   NOT NULL,  -- FK to CATEGORIES (DrugBank category ID or title)
    CATEGORY_TITLE      VARCHAR(200),            -- Human-readable class name (denormalized for clarity)
    PROHIBITION_REASON  TEXT,                    -- Clinical rationale
    SEVERITY            VARCHAR(20)   NOT NULL,  -- ABSOLUTE, CONDITIONAL, CAUTION
    EXCEPTION_CRITERIA  TEXT,                    -- When exceptions are allowed
    PRIMARY KEY (PROTOCOL_ID, CATEGORY_ID)
);

-- TODO: Populate with real protocol prohibition rules
-- Example:
-- INSERT INTO CLINICAL_PROTOCOLS VALUES
--   ('MPC-ONC-001', 'Phase III Solid Tumor Trial', 'Oncology', 'Phase III', 'Medpace', 'Enrolling');
--
-- INSERT INTO PROTOCOL_PROHIBITED_CLASSES VALUES
--   ('MPC-ONC-001', 'DBCAT000123', 'Anticoagulants', 'Bleeding risk with chemotherapy agents', 'ABSOLUTE', NULL),
--   ('MPC-ONC-001', 'DBCAT000456', 'Immunosuppressants', 'Confounds efficacy endpoints', 'ABSOLUTE', NULL),
--   ('MPC-CARD-002', 'DBCAT000789', 'NSAIDs', 'CV risk and fluid retention', 'ABSOLUTE', NULL),
--   ('MPC-CARD-002', 'DBCAT000012', 'Antiplatelets', 'Bleeding risk', 'CONDITIONAL', 'Low-dose aspirin ≤81mg for cardiac prophylaxis allowed with PI approval');

----------------------------------------------------------------------
-- STEP 4: EDC medications (reference or view)
----------------------------------------------------------------------
-- TODO: Point this at wherever EDC medication data lands in Snowflake.
-- If it's already in a table, just create a view. If not, define the target table.

-- Option A: View over existing EDC data
/*
CREATE OR REPLACE VIEW EDC_MEDICATIONS AS
SELECT
    <TODO_entry_id>     AS ENTRY_ID,
    <TODO_protocol_id>  AS PROTOCOL_ID,
    <TODO_subject_id>   AS PARTICIPANT_ID,
    <TODO_med_name>     AS MEDICATION_TEXT,     -- The raw free-text entry
    <TODO_dose>         AS DOSE,
    <TODO_frequency>    AS FREQUENCY,
    <TODO_start_date>   AS START_DATE,
    <TODO_indication>   AS INDICATION_TEXT,
    <TODO_entered_by>   AS ENTERED_BY,
    <TODO_entry_date>   AS ENTRY_DATE
FROM <TODO_EDC_DATABASE>.<TODO_SCHEMA>.<TODO_TABLE>;
*/

-- Option B: Standalone table (if loading a sample extract)
CREATE OR REPLACE TABLE EDC_MEDICATIONS (
    ENTRY_ID         VARCHAR(50)   NOT NULL,
    PROTOCOL_ID      VARCHAR(50)   NOT NULL,
    PARTICIPANT_ID   VARCHAR(50)   NOT NULL,
    MEDICATION_TEXT   VARCHAR(500)  NOT NULL,  -- Raw free-text: "lipitor 20mg po qd"
    DOSE             VARCHAR(100),
    FREQUENCY        VARCHAR(50),
    START_DATE       DATE,
    INDICATION_TEXT  VARCHAR(500),
    ENTERED_BY       VARCHAR(50),
    ENTRY_DATE       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ENTRY_ID)
);

----------------------------------------------------------------------
-- STEP 5: FDA Drug Labels (optional — from marketplace or manual load)
----------------------------------------------------------------------
-- TODO: If using the FDA DailyMed marketplace listing, create a view over it.
-- If loading manually, use this table structure.

-- Option A: View over marketplace listing
-- CREATE OR REPLACE VIEW FDA_DRUG_LABELS AS
-- SELECT * FROM <TODO_FDA_MARKETPLACE_DATABASE>.<TODO_SCHEMA>.<TODO_TABLE>;

-- Option B: Manual table
CREATE OR REPLACE TABLE FDA_DRUG_LABELS (
    LABEL_ID       VARCHAR(50)   NOT NULL,
    DRUG_ID        VARCHAR(10),              -- DrugBank ID if mapped
    DRUG_NAME      VARCHAR(200),
    SECTION_TYPE   VARCHAR(50),              -- CONTRAINDICATIONS, WARNINGS, BOXED_WARNING, PRECAUTIONS
    SECTION_TEXT   TEXT,
    EFFECTIVE_DATE DATE,
    PRIMARY KEY (LABEL_ID, SECTION_TYPE)
);
