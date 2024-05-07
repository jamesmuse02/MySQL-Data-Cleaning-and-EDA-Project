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
The objective of this section is to identify patterns within the data, which will facilitate the extraction of valuable insights.

Building upon the progress made in the data cleaning phase, we will proceed using the layoff_staging2 table. In this table, our focus will primarily be on analyzing the `total_laid_off` and `percentage_laid_off` columns to uncover patterns within the data.
### Data Timeframe
To begin, we'll examine the timeframe covered by the dataset. Analyzing this timeframe can provide valuable context for understanding the events that occurred during that period. Considering these factors may offer deeper insights into the dataset.
```sql
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;
```
The dataset spans from March 2020 to March 2023, a period significantly shaped by the aftermath of the COVID-19 pandemic. Given this information, it's reasonable to deduce that the pandemic played a major role in causing these layoffs.
### Percentage Laid Off
Examining the `percentage_laid_off` column reveals that a value of 1 signifies that all employees of the respective companies were laid off. Regrettably, without access to the total number of employees per company, our analysis possibilities are constrained. Nonetheless, I managed to extract data on companies that had the highest number of employees laid off in their entirety, as well as those that received the highest funding but terminated all their employees.

```sql
-- 1 in percentage_laid_off is 100%
-- companies that had the highest number of employees and dropped all of them
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- companies that had the highest funding and dropped all their employees
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
```
From the data retrieved in the queries, several patterns and insights emerge, especially when considering the effects of the pandemic. Here is a summary:
- **Global Impact**: The data reveals widespread layoffs across various industries and countries, highlighting the global reach of the economic repercussions of the COVID-19 pandemic.

- **Funding Disparity**: Despite differences in funding amounts, companies of varying sizes were affected, indicating that factors beyond financial resources contributed to the layoffs, such as market dynamics and operational challenges.

- **Temporal Influence**: The layoffs occurred over a period from 2020 to 2023, aligning with the pandemic's onset and aftermath, suggesting a correlation between the timing of the layoffs and the severity of the pandemic's effects on businesses.

### Total Laid Off
By examining the "total_laid_off" column, we can observe the number of employees laid off across various parameters. Throughout this endeavor, I computed the total layoffs according to the `company`, `industry`, `country`, `year`, and `stage` columns. These metrics provide valuable avenues for extracting insights from the dataset.

```sql
-- total laid off by company
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;
```
Here are some initial observations based on the total number of employees laid off by different companies:
- Established tech giants such as Amazon, Google, Meta, Salesforce, and Microsoft experienced substantial layoffs during the period, reflecting challenges even for large corporations.
- Companies in the technology sector, including Ericsson and Dell, witnessed significant workforce reductions, indicating broader industry trends or internal restructuring efforts.
- The presence of companies like Uber and Booking.com among the top 10 indicates the widespread impact of the COVID-19 pandemic on sectors like transportation and travel, leading to significant layoffs despite their prominence in their respective industries.

```sql
-- total laid off by industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
```
Here are some observations based on the total number of employees laid off by industry:
- Industries heavily reliant on consumer spending, such as Consumer, Retail, and Transportation, experienced the highest total layoffs, indicating the profound impact of economic downturns on sectors directly tied to consumer behavior.
- Sectors like Finance, Healthcare, and Real Estate also saw significant layoffs, possibly reflecting broader economic uncertainties and shifts in demand during the pandemic period.
- Emerging sectors such as Crypto and Fin-Tech, while experiencing layoffs, showed comparatively lower numbers, suggesting some resilience or adaptability to market challenges during this period.

```sql
-- total laid off by country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
```
Here are the summarized insights from the total laid off by country:

- **United States Dominance**: The United States had the highest total number of laid-off employees, totaling 256,559. This suggests significant economic turbulence within the U.S. job market during the period under consideration.

- **Global Distribution**: Layoffs were not limited to one country, indicating a global economic impact. India, the Netherlands, Sweden, and Brazil also experienced substantial job losses, each with tens of thousands of laid-off employees.

- **Varied Impact**: While some countries faced significant layoffs, others experienced comparatively fewer job losses. Countries like Switzerland, Lithuania, and Malaysia had lower numbers of laid-off employees, possibly indicating a relatively better economic resilience or different industry compositions.

```sql
-- total laid off by year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;
```
Here are some insights from the total laid off by year:
- **Rising Layoffs**: The data illustrates a clear upward trend in layoffs over the past few years. While there was a notable increase from 2020 to 2021, the most significant spike occurred in 2022, with a total of 160,661 individuals laid off. This trend indicates a period of heightened workforce restructuring and organizational changes across industries.

- **COVID-19 Impact**: The sharp increase in layoffs observed in 2020, coinciding with the onset of the COVID-19 pandemic, suggests a direct impact of the global health crisis on employment. The pandemic-induced economic downturn led many companies to implement cost-cutting measures, including layoffs, to navigate the uncertain business landscape and mitigate financial losses.

- **Stabilization Efforts**: While layoffs remained relatively high in 2021 and 2022, the data indicates a gradual decline compared to the peak observed in 2020. This downward trajectory may reflect efforts by businesses to stabilize operations and adapt to the new normal post-pandemic. However, the persistence of layoffs beyond the initial pandemic period suggests ongoing challenges in certain industries and underscores the need for continued resilience and adaptation in the face of economic uncertainties.

```sql
-- total laid off by company stage
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;
```
Here's a summary insight based on the data for total laid off by company stage:

- **Post-IPO companies**: Experience the highest number of layoffs, with a total of 204,132. This suggests that even after going public, companies may undergo restructuring or downsizing.
  
- **Acquired companies**: Follow closely behind with 27,576 layoffs. This indicates that acquisition doesn't always guarantee job security, and integration processes may lead to workforce reductions.

- **Early-stage companies**: Such as those in Series A, B, and C stages, collectively account for a significant number of layoffs. This could be due to various factors like failed fundraising efforts, market challenges, or shifts in strategic priorities.

### Rolling Total Laid Off
This data allows us to track the trend of layoffs month by month from March 2020 to March 2023, providing a critical measure of the situation's evolution. It offers valuable insights into whether the circumstances are getting better or worse, and identifies the specific periods of improvement or deterioration. Armed with this knowledge, informed decisions can be made to address and potentially improve the situation.

I achieved this by constructing a Common Table Expression (CTE) named `Rolling_Total`, containing the month and the aggregated sum of total layoffs represented as `total_off`. For extracting the `MONTH` column, I employed the SUBSTRING function on the date, specifying a range to extract only the year and month information.

The `rolling_total` column is created using a window function SUM(total_off) OVER(ORDER BY MONTH). This function calculates the cumulative sum of `total_off` column as the query progresses through the result set ordered by the "MONTH" column.

```sql
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
```
### Top Layoff Companies for Each Year
This query will help us identify the companies with the highest number of layoffs for each year and rank them accordingly. We aim to identify the top 5 companies for each year.

This query performs the following operations:

- It uses a Common Table Expression (CTE) named `Company_Year` to calculate the total number of layoffs (`total_laid_off`) for each company (`company`) in each year (`years`). This is done by selecting the company name, extracting the year from the date column, and then summing up the total laid off for each combination of company and year. The result is sorted by the total laid off in descending order.

- Another CTE named `Company_Year_Rank` is created based on the previous CTE (`Company_Year`). This CTE adds a ranking (`Ranking`) to each row within each year, based on the total number of layoffs (`total_laid_off`) for each company. The ranking is assigned using the DENSE_RANK() window function, which ranks rows within each partition (year) without any gaps in the ranking values. This means that if multiple companies have the same number of layoffs in a year, they will receive the same rank.

- Finally, the main query selects all columns from the `Company_Year_Rank` CTE where the ranking (`Ranking`) is less than or equal to 5. This effectively filters the results to include only the top 5 companies in terms of layoffs for each year.

Overall, this query allows you to identify the top 5 companies with the highest number of layoffs for each year, along with their respective rankings.

```sql
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
```


# What I Learned

Throughout this project, I've gained valuable insights into analyzing layoff data across various dimensions such as company, industry, country, year, and company stage. Here are some key takeaways:

1. **Impact of Layoffs:** Layoff data provides crucial insights into the economic landscape, reflecting the health of industries, companies, and regions. Analyzing layoffs helps in understanding the dynamics of workforce restructuring and its implications on different sectors.

2. **Trend Analysis:** By examining the trends in layoffs over time, we can identify patterns such as seasonal fluctuations, economic downturns, or periods of growth. This allows for better anticipation of future trends and proactive decision-making.

3. **Company Performance:** Analyzing layoffs by company allows us to gauge the performance and stability of individual businesses. Companies experiencing frequent layoffs may indicate underlying issues such as financial instability, strategic shifts, or market challenges.

4. **Geographical Insights:** Understanding the distribution of layoffs across different countries provides valuable insights into global economic trends, regional disparities, and the impact of local factors such as government policies or market conditions.

5. **Industry Dynamics:** Examining layoffs by industry reveals the sectors most affected by workforce reductions. This insight is valuable for stakeholders, policymakers, and investors seeking to understand industry-specific challenges and opportunities.

6. **Company Stage Analysis:** Analyzing layoffs by company stage sheds light on the dynamics of startups, growth-stage companies, and established firms. Differences in layoff patterns at various stages can indicate unique challenges associated with each phase of company development.

7. **Rolling Total Analysis:** Utilizing rolling totals allows for a dynamic view of layoffs over time, enabling trend identification, anomaly detection, and forecasting. This approach provides a comprehensive understanding of layoff dynamics and their evolution.

8. **SQL Proficiency:** Working with SQL queries to retrieve, manipulate, and analyze data has enhanced my proficiency in database management and querying. Understanding advanced SQL functionalities such as window functions, common table expressions (CTEs), and data aggregation techniques has been particularly valuable.

Overall, this project has deepened my understanding of workforce dynamics, data analysis techniques, and the importance of data-driven decision-making in understanding and responding to labor market challenges.

# Conclusion
### Summarized Insight

1. **Company Trends:**
   - Companies like Amazon, Google, and Meta led in total layoffs, indicating challenges in major tech corporations.
   - Post-IPO companies experienced the highest number of layoffs, suggesting potential instability post-public offering.

2. **Industry Impact:**
   - Consumer and retail industries witnessed the highest layoffs, reflecting the economic downturn's effect on consumer spending.
   - Sectors like healthcare and finance also faced significant layoffs, likely due to restructuring and economic uncertainties.

3. **Geographical Patterns:**
   - The United States reported the highest number of layoffs, indicating widespread economic impact.
   - India and European countries like the Netherlands and Sweden also experienced substantial layoffs.

4. **Temporal Analysis:**
   - Layoffs peaked in 2020 and 2023, coinciding with major economic disruptions and recovery phases.
   - Monthly rolling totals revealed fluctuations, offering insights into the progression and severity of layoffs over time.

5. **Data Analysis Techniques:**
   - Utilizing SQL queries, we ranked companies by layoffs annually, providing actionable insights for strategic decision-making.
   - By analyzing trends across industries, geographies, and company stages, we gained valuable insights into the evolving landscape of layoffs.

### Closing Thoughts

In wrapping up this project, it's clear that the foundation of robust data cleaning and thorough exploratory data analysis (EDA) is indispensable. By meticulously cleaning and preparing the data, we laid the groundwork for meaningful analysis and interpretation. From handling missing values to standardizing formats, each step in the data cleaning process was essential for ensuring the accuracy and reliability of our findings.

Throughout the exploratory data analysis phase, we employed a variety of techniques to uncover insights and patterns hidden within the data. From simple summary statistics to more complex visualizations and statistical analyses, we utilized a diverse toolkit to extract actionable insights. This process not only enhanced our understanding of the dataset but also enabled us to formulate informed hypotheses and identify areas for further investigation.

Moreover, this project underscored the importance of context and domain knowledge in interpreting the findings. Understanding the nuances of the industry, economic landscape, and organizational dynamics provided valuable context for our analysis. By combining data-driven insights with qualitative understanding, we were able to derive more meaningful and actionable conclusions.

Looking ahead, the skills and techniques honed in this project—data cleaning, exploratory data analysis, and contextual interpretation—will continue to be invaluable assets in future endeavors. As the volume and complexity of data continue to grow, the ability to extract meaningful insights from raw data will remain a cornerstone of data-driven decision-making.

By embracing a rigorous and systematic approach to data analysis, we can unlock new opportunities, mitigate risks, and drive innovation in diverse domains. As we conclude this project, let us carry forward the lessons learned and apply them to future challenges and opportunities on our data journey.

---



