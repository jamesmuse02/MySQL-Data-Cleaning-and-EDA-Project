-- Exploratory Data Analysis

SELECT *
FROM layoffs_staging2;

-- we will be working mostly with the total_laid_off and percentage_laid_off column

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- 1 in percentage_laid_off is 100%
-- we could look at the companies that had the highest number of employees and dropped all of them
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- we could also look at the companies that had the highest funding and dropped all their employees
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- total laid off by company
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- date range is almost exactly 3 years
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- total laid off by industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- total laid off by country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- total laid off by year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- total laid off by funding stage
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;


-- progression of layoffs using rolling total
-- we will use this to see the increase in layoffs by month

SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC  
)
SELECT `MONTH`, total_off, 
SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;


-- we can look at the companies that had the most layoffs per year and put that into a rank for every year

-- this gives us the total layoffs made by the companies for each year
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- put the above query in a cte and add the ranking to the table
-- we want to filter on this rank so we will make it another cte for rank
-- with this we can see top 5 companies with the highest laid off for each year

WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC
), Company_Year_Rank AS
(SELECT *, 
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5
;

















