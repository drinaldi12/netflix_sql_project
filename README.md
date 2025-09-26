# Netflix Movies and TV Dataset SQL Analysis

![](https://github.com/drinaldi12/netflix_sql_project/blob/main/netflix%20logo.png)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
-- Create Database
CREATE DATABASE netflixdb;

-- Create Table
CREATE TABLE netflix
	(
    show_id VARCHAR(10),
    type VARCHAR(10),
    title VARCHAR(120),
    director VARCHAR(220),
    cast VARCHAR(800),
    country VARCHAR(150),
    date_added VARCHAR(50),
    release_year INT,
    rating VARCHAR(10),
    duration VARCHAR(20),
    listed_in VARCHAR(80),
    description VARCHAR(250)
	);
    
-- Load the Data
LOAD DATA LOCAL INFILE 'C:/Users/jacks/OneDrive/Desktop/External Data Analyst Learning/Data Analyst Roadmap/Projects/Netflix Movies and TV/netflix_titles.csv'
INTO TABLE netflix
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Testing the Data for Correctness
SELECT * FROM netflix;

SELECT COUNT(*)
FROM netflix;

SELECT DISTINCT(type)
FROM netflix;
```

## Business Problems and Solutions

### 1. Count the number of movies vs TV Shows.

```sql
SELECT 
	type, 
	COUNT(*) as number_of_projects
FROM netflix
GROUP BY type;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the most common rating for movies and TV shows.

```sql
SELECT 
	type,
    rating
FROM
(
SELECT
	type,
    rating,
    COUNT(rating) as total_ratings,
    RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC) as ranking
FROM netflix
GROUP BY type, rating
) as ranking_ratings
WHERE ranking = 1;
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List all movies released in a specific year (e.g., 2018).

```sql
SELECT 
	title,
    release_year
FROM netflix
WHERE 
	release_year = '2018'
	AND type = 'Movie';
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the top 5 countries with the most content on Netflix.

```sql
WITH RECURSIVE split_cte_country AS (
  -- anchor row
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,
    SUBSTRING(country, LENGTH(SUBSTRING_INDEX(country, ',', 1)) + 2) AS other_countries
  FROM netflix
  WHERE country IS NOT NULL AND country <> ''

  UNION ALL
  
  -- recursive section
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(other_countries, ',', 1)) AS country,
    SUBSTRING(other_countries, LENGTH(SUBSTRING_INDEX(other_countries, ',', 1)) + 2) AS other_countries
  FROM split_cte_country
  WHERE other_countries <> ''
)
SELECT country, COUNT(*) AS total
FROM split_cte_country
WHERE country <> ''
GROUP BY country
ORDER BY total DESC
LIMIT 5; 
```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
FROM netflix
WHERE type = 'Movie'
  AND duration IS NOT NULL
  AND duration <> ''
ORDER BY CAST(TRIM(REPLACE(duration, ' min', '')) AS UNSIGNED) DESC
LIMIT 1;
```

**Objective:** Find the movie with the longest duration.

### 6. Find content added in the last 7 years.

```sql
SELECT *
FROM netflix
WHERE STR_TO_DATE(date_added, '%M %d, %Y') >= DATE_SUB(curdate(), INTERVAL 7 YEAR);
```

**Objective:** Retrieve content added to Netflix in the last 7 years.

### 7. Find all the movies/TV shows by director 'Greg MacGillivray'.

```sql
SELECT *
FROM netflix
WHERE director LIKE '%Greg MacGillivray%';
```

**Objective:** List all content directed by 'Greg MacGillivray'.

### 8. List all TV shows with more than 5 seasons.

```sql
SELECT 
	title,
	TRIM(SUBSTRING_INDEX(duration, ' ', 1)) AS seasons
FROM netflix
WHERE type = 'TV Show'
	AND duration > 5;
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
WITH RECURSIVE split_cte_listed_in AS (
  -- anchor row
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
    SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS other_genre
  FROM netflix
  WHERE listed_in IS NOT NULL AND listed_in <> ''

  UNION ALL
  
  -- recursive section
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(other_genre, ',', 1)) AS genre,
    SUBSTRING(other_genre, LENGTH(SUBSTRING_INDEX(other_genre, ',', 1)) + 2) AS other_genre
  FROM split_cte_listed_in
  WHERE other_genre <> ''
)
SELECT genre, COUNT(*) AS total
FROM split_cte_listed_in
WHERE genre <> ''
GROUP BY genre
ORDER BY total DESC;
```

**Objective:** Count the number of content items in each genre.

### 10. For each year, find the percentage of content released in the United States compared to all other countries 
on Netflix. Return the top 3 years with the highest average content released.

```sql
WITH RECURSIVE split_cte_country_two AS (
  -- anchor row
  SELECT 
    show_id,
    date_added,
    YEAR(
      CASE
        WHEN date_added REGEXP '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$'
          THEN STR_TO_DATE(date_added, '%d-%b-%y')
        WHEN date_added REGEXP '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{4}$'
          THEN STR_TO_DATE(date_added, '%d-%b-%Y')
        WHEN date_added REGEXP '^[A-Za-z]+ [0-9]{1,2}, [0-9]{4}$'
          THEN STR_TO_DATE(date_added, '%M %d, %Y')
      END
    ) AS year,
    TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,
    SUBSTRING(country, LENGTH(SUBSTRING_INDEX(country, ',', 1)) + 2) AS other_countries
  FROM netflix
  WHERE country IS NOT NULL AND country <> ''

  UNION ALL
  
  -- recursive part
  SELECT 
    show_id,
    date_added,
    YEAR(
      CASE
        WHEN date_added REGEXP '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$'
          THEN STR_TO_DATE(date_added, '%d-%b-%y')
        WHEN date_added REGEXP '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{4}$'
          THEN STR_TO_DATE(date_added, '%d-%b-%Y')
        WHEN date_added REGEXP '^[A-Za-z]+ [0-9]{1,2}, [0-9]{4}$'
          THEN STR_TO_DATE(date_added, '%M %d, %Y')
      END
    ) AS year,
    TRIM(SUBSTRING_INDEX(other_countries, ',', 1)) AS country,
    SUBSTRING(other_countries, LENGTH(SUBSTRING_INDEX(other_countries, ',', 1)) + 2) AS other_countries
  FROM split_cte_country_two
  WHERE other_countries <> ''
)
SELECT 
	country, 
    year,
	COUNT(show_id) as total,
	ROUND(
		COUNT(show_id)/(SELECT COUNT(show_id) FROM netflix WHERE country = 'United States')* 100, 2)
		AS avg_release_pct
FROM split_cte_country_two
WHERE COUNTRY = 'United States'
  AND year IS NOT NULL
GROUP BY country, year
ORDER BY total DESC
LIMIT 3;
```

**Objective:** Calculate and rank years by the average number of content releases by the United States.

### 11. List all movies that are comedies.

```sql
SELECT title, listed_in
FROM netflix
WHERE listed_in LIKE '%Comedies%';
```

**Objective:** Retrieve all movies classified as comedies.

### 12. Find All Content Without a Director

```sql
SELECT title, director
FROM netflix
WHERE 
	director = ''
	OR director IS NULL;
```

**Objective:** List content that does not have a director.

### 13. Find how many movies actress 'Kristen Bell' appeared in last 10 years.

```sql
SELECT COUNT(*) AS total_movies
FROM netflix
WHERE 
    cast LIKE '%Kristen Bell%'
    AND type = 'Movie'
    AND CAST(release_year AS UNSIGNED) >= YEAR(CURDATE()) - 10;
```

**Objective:** Count the number of movies featuring 'Kristen Bell' in the last 10 years.

### 14. Find the top 10 actors who have appeared in the highest number of movies produced in the United States.

```sql
WITH RECURSIVE split_cte_cast AS (
  -- anchor row
  SELECT 
    show_id,
    country,
    TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS cast,
    SUBSTRING(cast, LENGTH(SUBSTRING_INDEX(cast, ',', 1)) + 2) AS other_cast
  FROM netflix
  WHERE cast IS NOT NULL AND cast <> ''

  UNION ALL
  
  -- recursive section
  SELECT 
    show_id,
    country,
    TRIM(SUBSTRING_INDEX(other_cast, ',', 1)) AS cast,
    SUBSTRING(other_cast, LENGTH(SUBSTRING_INDEX(other_cast, ',', 1)) + 2) AS other_cast
  FROM split_cte_cast
  WHERE other_cast <> ''
)

SELECT cast, COUNT(*) as number_of_movies
FROM split_cte_cast
WHERE country LIKE '%United States%' 
	AND cast <> ''
GROUP BY cast
ORDER BY number_of_movies DESC
LIMIT 10;

```

**Objective:** Identify the top 10 actors with the most appearances in United States produced movies.

### 15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field. Label content containing these
keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each category.

```sql
SELECT 
	category,
    count(*) AS number_of_media
FROM 
	(
    SELECT 
		*,
        CASE
			WHEN description LIKE '%kill%' OR description LIKE '%violence%'
			THEN 'Bad'
            ELSE 'Good'
		END AS category
    FROM netflix
    ) AS categorized_media
GROUP BY category
```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusions

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by the Untied States highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

## Answers to Questions
### Note: If the answer contains a large amount of data, a count of the data results is provided as the answer instead.
	1. Movies - 6,131; TV Shows - 2,676
	2. Movies - TV-MA; TV Shows - TV-MA
	3. 767 movies released in 2018
	4. United States - 3,960; India - 1,046; United Kingdom - 806; Canada - 445; France - 393
	5. Black Mirror: Bandersnatch
	6. 24 Films and Shows added in the last 7 years
	7. 3 Total Movies
	8. 99 TV Shows
	9. First 3: International Movies - 2,752; Dramas - 2,427; Comedies - 1,674
	10. 2019 - 851 for 30.20%; 2020 - 828 for 29.38%; 2021 - 627 for 22.25%
	11. 2,255 different comedies
	12. 2,634 items (content) without a director
	13. 4 Movies
	14. Tara Strong (22), Samuel L. Jackson (22), Fred Tatasciore (21), Adam Sandler (20), James Franco (19), Nicolas Cage (19), Seth Rogen (18), Morgan Freeman (18), Molly Shannon (17), and Erin Fitzgerald (16)
	15. Good - 8,465; Bad - 342


This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.



## Author - Dominic Rinaldi

This project is part of my portfolio, showcasing the SQL skills essential for data analyst roles. If you have any questions, feedback, or would like to collaborate, feel free to get in touch!

### My Socials

- **LinkedIn**: [Connect with me professionally](https://www.linkedin.com/in/dominicrinaldi)
- **My Portfolio**: [View my Portfolio](https://dominicrinaldi.carrd.co/#)

Thank you for your support, and I look forward to connecting with you!
