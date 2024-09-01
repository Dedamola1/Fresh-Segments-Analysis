USE fresh_segments;

-- Interests have been present in all month_year dates
SELECT 
	  COUNT(DISTINCT month_year) AS unique_month_year_count, 
	  COUNT(DISTINCT interest_id) AS unique_interest_id_count
FROM fresh_segments.interest_metrics;

WITH interest_cte AS (
SELECT 
	  interest_id, 
	  COUNT(DISTINCT month_year) AS total_months
FROM fresh_segments.interest_metrics
WHERE month_year IS NOT NULL
GROUP BY interest_id
)
SELECT 
	  total_months,
	  COUNT(DISTINCT interest_id) AS total_interests_present
FROM interest_cte 
WHERE total_months = 14
GROUP BY total_months;

-- Cumulative percentage of all records starting at 14 months which total_months value passes the 90% cumulative percentage value
WITH cte_interest_months AS (
	SELECT
		interest_id,
	    COUNT(DISTINCT month_year) AS total_months 
	FROM fresh_segments.interest_metrics
	WHERE interest_id IS NOT NULL
	GROUP BY interest_id
),
cte_interest_counts AS (
	SELECT
		total_months,
		COUNT(DISTINCT interest_id) AS interest_count
	FROM cte_interest_months
	GROUP BY total_months
    ORDER BY total_months DESC
),
cumulative_data AS(
SELECT 
	total_months,
    ROUND(100 * SUM(interest_count) OVER (ORDER BY total_months DESC) / (SUM(interest_count) OVER ()),2) AS cumulative_perc
FROM cte_interest_counts
)
SELECT *
FROM cumulative_data
WHERE cumulative_perc > 90;

-- Removing all interest_id values which are lower than the total_months value above
WITH interest_cte AS(
	SELECT 
		  interest_id, 
		  COUNT(DISTINCT month_year) AS total_months
	FROM fresh_segments.interest_metrics
	WHERE month_year IS NOT NULL
	GROUP BY interest_id
)
SELECT COUNT(*) AS removed_data_points
FROM interest_cte
WHERE total_months > 6;

--  How many unique interests are there for each month after removing these interests?
WITH interest_cte AS(
	SELECT 
		  interest_id, 
		  COUNT(DISTINCT month_year) AS total_months
	FROM fresh_segments.interest_metrics
	WHERE month_year IS NOT NULL 
	GROUP BY interest_id
)
SELECT total_months,
		CASE WHEN total_months <= 6 THEN COUNT(DISTINCT interest_id) ELSE 0 END AS unique_interest_count
FROM interest_cte
GROUP BY total_months;

