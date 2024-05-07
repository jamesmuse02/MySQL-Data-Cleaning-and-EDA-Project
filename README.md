# Introduction
This project aims to showcase proficiency in data cleaning and exploratory data analysis techniques. Through various methodologies, the data was meticulously cleansed and scrutinized to unveil valuable patterns. An array of tools was leveraged throughout the project to accomplish these tasks effectively.

Check out the SQL queries here: [Query folder](/Query/)

# Background
The dataset utilized in this project is a CSV file containing records of company layoffs worldwide from March 2020 to March 2023, a period deeply influenced by the repercussions of the COVID-19 pandemic. The dataset encompasses information such as company names, locations (city), industries, total count of laid-off employees, percentage of layoffs relative to total company workforce, dates of layoffs, company stage (e.g., Series A funding, post-IPO), country of operation, and funds raised in million dollars.

You can access the raw data from the [csv_file folder](/csv_file/).

### Goals for this project:

1. **Demonstrate Proficiency:** Showcase adeptness in data cleaning and exploratory data analysis techniques, highlighting the ability to extract meaningful insights from raw datasets.
2. **Identify Patterns and Trends:** Utilize various analytical tools and methodologies to uncover notable patterns and trends within the dataset, particularly focusing on the impact of the COVID-19 pandemic on global layoffs between March 2020 and March 2023.
3. **Inform Decision-Making:** Provide actionable insights for stakeholders by presenting clear and concise findings regarding company layoffs, including factors such as industry, location, company stage, and fundraising, to facilitate informed decision-making processes.


# Tools I Used
During my thorough exploration of this data cleaning and exploratory data analysis endeavor, I utilized several essential tools to extract insights efficiently. These tools encompassed:

- **MySQL**: Serving as the cornerstone of my analysis, MySQL empowered me to query the database and unveil invaluable insights pivotal for my project's success.
  
- **Visual Studio Code**: Serving as my favored code editor, I utilized Visual Studio Code for adeptly managing databases and executing MySQL queries with precision and efficiency.
  
- **Git & GitHub**: Essential for version control and fostering collaboration, Git and GitHub facilitated seamless sharing of MySQL scripts and analyses, ensuring effective project tracking and collaborative workflows.

# Data Cleaning
The data cleaning phase of this project adhered to a structured four-step process. These steps were meticulously executed to ensure comprehensive consideration and implementation of crucial data cleaning procedures. The steps are as follows:

1. Eliminate Duplicate Entries
2. Standardize Data
3. Handle Null and Empty Values
4. Eliminate Redundant Rows or Columns

Before commencing the aforementioned four-step procedure, it was imparative to initially create a staging table for executing all queries. This step is highly important. Working directly with raw data is not recommended. It is essential to have a duplicate dataset available for manipulation in case of any errors or mishaps.

```sql
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * FROM layoffs_staging;

-- insert the data from the raw table into the staging table
INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT * FROM layoffs_staging;
;
```
From here, I made use of the newly created layoffs_staging table, as opposed to the original layoffs table in the database.

### 1. Eliminate Duplicate Entries
In order to remove the duplicate  entries, a two-step process is followed. Firstly, we need to identify the duplicates, then we delete them from the table.

In order to identify the duplicates, I added a new column to the table called `row_num`. This row_num column assigns a unique sequential number to each row based on specific criteria such as company, location, industry, total laid off, percentage laid off, date, stage, country, and funds raised in millions. This numbering allows for easy identification and referencing of rows within the dataset. I did this using the `ROW_NUMBER()` function which is a window function used to assign a unique sequential integer to each row within a partition of a result set. The `OVER()` clause defines the partitioning and ordering of the rows.

Utilizing this approach, it became apparent that duplicate entries are identified by having a `row_num` value greater than 1. With this insight, I could efficiently filter out and eliminate these redundant values.

It's important to highlight that I established a new table `layoffs_staging2` to accommodate the `ROW_NUMBER()` query. This facilitates the process of filtering and removing duplicates. Subsequently, throughout the remainder of the project, I used this newly created table for further analysis. 

```sql
-- create row_num column to assign unique sequential number to each row
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, `location`, industry, total_laid_off, percentage_laid_off, `date`
, stage, country, funds_raised_millions) AS row_num 
FROM layoffs_staging;


-- put the above query in a new table and filter the ones greater than 1

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

-- insert prior query into the new table(the one with row_num)
-- we want the results from that query to be the members for this table
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
```

### 2. Standardize Data
Data standardization involves identifying and rectifying existing issues within the dataset. These issues have the potential to influence the outcomes of our exploratory data analysis findings. During this procedure, I conducted a sequence of data corrections followed by table updates.

First, I addressed the presence of blank spaces in the `company` column. This was accomplished using the `Trim()` function.
```sql
-- test the trim and see how that looks
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- now update the table
UPDATE layoffs_staging2
SET company = TRIM(company);
```
Upon examining the `industry` column, it's apparent that "crypto" and "cryptocurrency" represent the same industry but are expressed differently. Correcting this inconsistency is advisable as it could impact the accuracy of our exploratory data analysis. 
```sql
-- when using distinct on industry, we see crypto and crypto currency
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- update all of them to be crypto

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```
In the `country` column, "United States" appears twice due to a period at the end of the second entry. It's necessary to rectify this inconsistency. By employing the `TRIM()` function and specifying `TRAILING`, I successfully resolved this issue.
```sql
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; 

SELECT DISTINCT country, TRIM(TRAILING '.' from country)
from layoffs_staging2
order by 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' from country)
WHERE country LIKE 'United States%';
```
Finally, it's necessary to adjust the data type of the `date` column. Upon loading the data, I observed that MySQL incorrectly assigned the data type for `date` as text. This requires rectification. Initially, I converted the dates in the column to the appropriate SQL format using the `STR_TO_DATE()` function. Subsequently, I modified the table to update the data type using the `ALTER` function.
```sql
-- in the str_to_date() function pass in the column to be affected and what format it is currently in
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')  -- Y here stands for the 4 digit year
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- now it is in a date format

SELECT `date`
FROM layoffs_staging2;

-- use ALTER to change data type

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
```

### 3. Handle Null and Empty Values
Reviewing the null and empty values within the `industry` column, it's feasible to populate the missing values by leveraging information from other entries that share the same or similar company name. This assumption stems from the notion that entries with identical company names should typically belong to the same industry, a trend observed within this dataset.

First of all, I converted all blank values to nulls so it will be easier to work with, then I joined the table onto itself using the company name. 

This query selects all columns from the table `layoffs_staging2`, but with an alias `t1`. It then joins this table with itself, assigning it another alias `t2`, based on the condition that the `company` values in `t1` match those in `t2`.

The `WHERE` clause filters the joined rows, selecting only those where the `industry` column in `t1` is NULL (indicating missing industry information) and the `industry` column in `t2` is NOT NULL (indicating that `t2` contains industry information for the same company).

In summary, this query retrieves rows from `layoffs_staging2` where there is missing industry information in one copy of the table (`t1`), but there is industry information available for the same company in another copy of the table (`t2`). This suggests that the missing industry values in `t1` can potentially be populated using the corresponding values from `t2`.

```sql
SELECT *
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
  ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;
```
After confirming that everything was arranged correctly, I converted the preceding query into an update query to fill in the missing values in the `industry` column. Following the implementation of the update, querying null values from the `industry` column yields no results.
```sql
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;
```
Please be aware that I opted not to modify the remaining null values, as they will either be dealt with at a later stage, are unnecessary, or cannot be filled.

### 4. Eliminate Redundant Rows or Columns
In this concluding phase of data cleaning, we will address redundant rows and columns. After thorough examination of the data and considering the objectives for the exploratory data analysis, I concluded that it is appropriate to eliminate fields where `total_laid_off` and `percentage_laid_off` values are null. Given their significance as key metrics in the exploratory data analysis section, it is irrelevant to retain data entries lacking values for these metrics. For this I made use of the `DELETE` function

```sql
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
```
Lastly, we'll remove the `row_num` column generated during the initial step, as it is no longer necessary. This will be achieved by utilizing the `ALTER TABLE` function along with the `DROP COLUMN` operation.
```sql
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
```
With that, we conclude the data cleaning phase.

# Exploratory Data Analysis


# What I Learned


# Conclusion
### Insight


### Closing Thoughts


