-- ==========================================================
-- DATA CLEANING PROJECT
-- ==========================================================

-- View the original dataset
SELECT *
FROM layoffs;

-- View the table structure
DESCRIBE layoffs;

-- ==========================================================
-- STEP 1: CREATE A STAGING TABLE
-- (Never clean the raw data directly)
-- ==========================================================

CREATE TABLE layoffs_staging
LIKE layoffs;

-- Verify the staging table
SELECT *
FROM layoffs_staging;

-- Copy all data into the staging table
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- Verify the copied data
SELECT *
FROM layoffs;

-- ==========================================================
-- STEP 2: IDENTIFY DUPLICATE RECORDS
-- ==========================================================

-- Assign a row number to identify duplicates
SELECT *,
ROW_NUMBER() OVER (
    PARTITION BY company,
                 industry,
                 total_laid_off,
                 percentage_laid_off,
                 `date`
) AS row_num
FROM layoffs_staging;

-- Find duplicate rows using all relevant columns
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
    PARTITION BY company,
                 location,
                 industry,
                 total_laid_off,
                 percentage_laid_off,
                 `date`,
                 stage,
                 country,
                 funds_raised
) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Check duplicate records for a specific company
SELECT *
FROM layoffs_staging
WHERE company = 'Amazon';

-- Note:
-- MySQL does not allow DELETE directly from a CTE.
-- Create a new table with row numbers instead.

-- ==========================================================
-- STEP 3: CREATE SECOND STAGING TABLE
-- ==========================================================

CREATE TABLE layoffs_staging2 (
    company TEXT,
    location TEXT,
    total_laid_off TEXT,
    `date` TEXT,
    percentage_laid_off TEXT,
    industry TEXT,
    source TEXT,
    stage TEXT,
    funds_raised INT DEFAULT NULL,
    country TEXT,
    date_added TEXT,
    row_num INT
);

-- Verify the new table
SELECT *
FROM layoffs_staging2;

-- Insert data while assigning row numbers
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (
    PARTITION BY company,
                 location,
                 total_laid_off,
                 `date`,
                 percentage_laid_off,
                 industry,
                 source,
                 stage,
                 funds_raised,
                 country,
                 date_added
) AS row_num
FROM layoffs_staging;

-- View duplicate rows
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Disable Safe Updates (Workbench)
SET SQL_SAFE_UPDATES = 0;

-- Remove duplicate records
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Verify duplicates have been removed
SELECT *
FROM layoffs_staging2;

-- ==========================================================
-- STEP 4: STANDARDIZE DATA
-- ==========================================================

-- Remove leading/trailing spaces from company names
SELECT DISTINCT TRIM(company), company
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Check unique industries
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- View Crypto variations
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Standardize industry names
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- View locations
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- Remove trailing periods from country names
SELECT DISTINCT country,
TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- ==========================================================
-- STEP 5: FORMAT DATE COLUMN
-- ==========================================================

-- Preview date conversion
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Convert text to DATE format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Verify conversion
SELECT `date`
FROM layoffs_staging2;

-- Change column datatype to DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- ==========================================================
-- STEP 6: HANDLE NULLS AND BLANKS
-- ==========================================================

-- Find rows with no layoff information
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Convert blank strings to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2
SET total_laid_off = NULL
WHERE total_laid_off = '';

UPDATE layoffs_staging2
SET percentage_laid_off = NULL
WHERE percentage_laid_off = '';

-- Find missing industries
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Example company with missing industry
SELECT *
FROM layoffs_staging2
WHERE company = 'Appsmith';

-- View all industries
SELECT DISTINCT industry
FROM layoffs_staging2;

-- Find matching companies with valid industry values
SELECT t1.industry,
       t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Fill missing industries using matching records
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- ==========================================================
-- STEP 7: REMOVE USELESS ROWS
-- ==========================================================

-- Find rows with no layoff information
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off IS NULL
AND total_laid_off IS NULL;

-- Delete those rows
DELETE
FROM layoffs_staging2
WHERE percentage_laid_off IS NULL
AND total_laid_off IS NULL;

-- Verify results
SELECT *
FROM layoffs_staging2;

-- ==========================================================
-- STEP 8: REMOVE HELPER COLUMN
-- ==========================================================

-- Remove the temporary row number column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final cleaned dataset
SELECT *
FROM layoffs_staging2;
