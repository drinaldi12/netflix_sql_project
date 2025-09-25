-- Answering Business Questions

-- 1. Count the number of Movies vs TV Shows.
SELECT 
	type, 
	COUNT(*) as number_of_projects
FROM netflix
GROUP BY type;

-- 2. Find the most common rating for movies and TV shows.
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

-- 3 . List all movies released in a specific year (e.g., 2018).
SELECT 
	title,
    release_year
FROM netflix
WHERE 
	release_year = '2018'
	AND type = 'Movie';
    
-- 4. Find the top 5 countries with the most content on Netflix.
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
    
-- 5. Identify the longest movie.
SELECT *
FROM netflix
WHERE type = 'Movie'
  AND duration IS NOT NULL
  AND duration <> ''
ORDER BY CAST(TRIM(REPLACE(duration, ' min', '')) AS UNSIGNED) DESC
LIMIT 1;

-- 6. Find content added in the last 7 years.
SELECT *
FROM netflix
WHERE STR_TO_DATE(date_added, '%M %d, %Y') >= DATE_SUB(curdate(), INTERVAL 7 YEAR);

-- 7. Find all the movies/TV shows by director 'Greg MacGillivray'.
SELECT *
FROM netflix
WHERE director LIKE '%Greg MacGillivray%';

-- 8. List all TV shows with more than 5 seasons.
SELECT 
	title,
	TRIM(SUBSTRING_INDEX(duration, ' ', 1)) AS seasons
FROM netflix
WHERE type = 'TV Show'
	AND duration > 5;

-- 9. Count the number of content items in each genre.
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

-- 10. For each year, find the percentage of content released in the United States compared to all other countries 
-- on Netflix. Return the top 3 years with highest average content release.
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


-- 11. List all movies that are comedies.
SELECT title, listed_in
FROM netflix
WHERE listed_in LIKE '%Comedies%';

select count(*) FROM netflix
WHERE listed_in LIKE '%Comedies%';

-- 12. Find all content without a director.
SELECT title, director
FROM netflix
WHERE 
	director = ''
	OR director IS NULL;
    
-- 13. Find how many movies actress 'Kristen Bell' appeared in last 10 years.
SELECT COUNT(*) AS total_movies
FROM netflix
WHERE 
    cast LIKE '%Kristen Bell%'
    AND type = 'Movie'
    AND CAST(release_year AS UNSIGNED) >= YEAR(CURDATE()) - 10;

-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in the United States.
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


-- 15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field. Label content containing these
-- keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each category.

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










