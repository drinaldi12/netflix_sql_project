CREATE DATABASE netflixdb;

DROP TABLE netflix;
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

LOAD DATA LOCAL INFILE 'C:/Users/jacks/OneDrive/Desktop/External Data Analyst Learning/Data Analyst Roadmap/Projects/Netflix Movies and TV/netflix_titles.csv'
INTO TABLE netflix
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT * FROM netflix
