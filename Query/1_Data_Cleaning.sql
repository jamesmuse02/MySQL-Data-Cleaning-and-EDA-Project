-- Data Cleaning

SELECT * FROM layoffs;

/* 
Data Cleaning Steps
    1. Remove Duplicates
    2. Standardize Data
    3. Null and blank values
    4. Remove unnecessary rows or columns
*/

-- Let's start by creating a staging table that is a duplicate of the raw table. This is best practice

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * FROM layoffs_staging;

-- insert the data from the raw table into the staging table

INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT * FROM layoffs_staging;

-- going forward we will use this staging database

-- 1. REMOVING DUPLICATES
-- firstly, let's identify the duplicates

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, `location`, industry, total_laid_off, percentage_laid_off, `date`
, stage, country, funds_raised_millions) AS row_num 
FROM layoffs_staging;

-- we want to filter the ones that have row_num > 1(duplicates)
-- we will put the above query in a new table and filter the ones greater than 1

-- create new table
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging2;

-- insert into the new table result from the prior query(the one with row_num)
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, `location`, industry, total_laid_off, percentage_laid_off, `date`
, stage, country, funds_raised_millions) AS row_num 
FROM layoffs_staging;  

-- filter to see the duplicates
SELECT *
FROM layoffs_staging2 
WHERE row_num > 1;

-- delete duplicates
DELETE
FROM layoffs_staging2 
WHERE row_num > 1;



-- 2. STANDARDIZING DATA- Finding issues with the data and fixing it

-- we can start by using trim to remove irrelevant spaces

-- we can test the trim and see how that looks
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- now we can update
UPDATE layoffs_staging2
SET company = TRIM(company);

-- let's look at the industry column
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- we can see that crypto and crypto currency are the same thing but written in different ways
-- we need to correct that because that is something that can affect our exploratory data analysis
-- we will update all of them to be crypto

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- in the country column, united states appears twice because the second one has a period at the end. We need to correct that

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; 

SELECT DISTINCT country, TRIM(TRAILING '.' from country)
from layoffs_staging2
order by 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' from country)
WHERE country LIKE 'United States%';


-- the date column is set as a text data type. We need to change it from a string to a date
-- we will use the str_to_date() function
-- we need to pass in the column to be affected and what format it is currently in
-- it is then converted into the MySQL standard date format

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')  -- Y here stands for the 4 digit year
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- now it is in a date format

SELECT `date`
FROM layoffs_staging2;

-- we still need to change it to a date column data type as it is still a text data type. For that we use ALTER
-- never do this on a raw table. Only do this on a staging table

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Now let's look at our table again and make sure we are set to move to step 3
SELECT *
FROM layoffs_staging2;


-- 3. NULLS AND BLANK VALUES

-- firstly let's look at industry and let's see if we can populate the missing values using info from other entries that have the same or similar company name

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- we will set all the blank values to nulls to make it easier

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- we will use join here to populate industry for fields that have the same company name, but industry is null or blank 
-- we will join that with fields that have the same company name and have industry section filled

SELECT *
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
  ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- now we can transform the above query into an update statement

UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- for the other columns that have null values, we are not able to populate that with the data we have. So we will leave as is


-- 4. REMOVING UNNECESSARY COLUMN AND ROWS

-- for our exploratory data analysis, total_laid_off and percentage_laid_off will be important metrics for us
-- therefore we will be deleting rows that have both of them as  null

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NOT NULL;


DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NOT NULL;

SELECT *
FROM layoffs_staging2;

-- we don't need the row_num column so we can drop it. We will use ALTER

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- This is our finalized cleaned data
SELECT *
FROM layoffs_staging2;
