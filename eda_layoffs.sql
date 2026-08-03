-- ==========================================================
-- EXPLORATORY DATA ANALYSIS (EDA)
-- ==========================================================

-- View the cleaned dataset
SELECT *
FROM layoffs_staging2;

-- Find the maximum number of employees laid off
-- and the maximum percentage laid off
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- View companies that laid off 100% of their workforce
-- Ordered by funds raised
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised DESC;

-- Calculate the total number of layoffs by company
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER  BY  2 DESC;

-- Find the earliest and latest layoff dates
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Calculate total layoffs by country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER  BY  2 DESC;

-- Calculate total layoffs by industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER  BY  2 DESC;

-- View the cleaned dataset
SELECT *
FROM layoffs_staging2;

-- Calculate total layoffs by company stage
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER  BY  2 DESC;

-- Calculate the average percentage of layoffs for each company
SELECT company, AVG(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER  BY  2 DESC;

-- Calculate total layoffs for each month
SELECT SUBSTRING(`date`,1,7) AS `MONTH`,SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`;

-- Calculate the rolling (cumulative) total of layoffs by month
WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`,SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_off,
SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- Calculate total layoffs by company
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Calculate total layoffs by company and year
SELECT company,YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company,YEAR(`date`)
ORDER BY 3 DESC;

-- Rank companies by total layoffs within each year
WITH Company_Year(company, years, total_laid_off) AS
(
SELECT company,YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company,YEAR(`date`)
), Company_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
-- Display the top 5 companies with the most layoffs each year
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
