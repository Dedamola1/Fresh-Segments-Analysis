USE fresh_segments;

-- Top 10 interests by the average composition for each month
WITH AvgCompositionCTE AS (
    SELECT
        month_year,
        interest_id,
        ROUND(SUM(composition / index_value), 2) AS avg_composition
    FROM fresh_segments.interest_metrics
    WHERE index_value != 0 AND month_year IS NOT NULL 
    GROUP BY month_year, interest_id
)
SELECT
    month_year,
    interest_id,
    avg_composition
FROM AvgCompositionCTE
ORDER BY avg_composition DESC
LIMIT 10;

-- Average of the average composition for the top 10 interests for each month
WITH AvgCompositionCTE AS (
    SELECT
        month_year,
        interest_id,
        ROUND(SUM(composition / index_value), 2) AS avg_composition
    FROM fresh_segments.interest_metrics
    WHERE index_value != 0 AND month_year IS NOT NULL 
    GROUP BY month_year, interest_id
),
Top10AvgComposition AS (
    SELECT
        month_year,
        interest_id,
        avg_composition
    FROM AvgCompositionCTE
    ORDER BY month_year, avg_composition DESC
    LIMIT 10
)
SELECT
    ROUND(AVG(avg_composition), 2) AS avg_of_top10_avg_compositions
FROM Top10AvgComposition;

-- 3 month rolling average of the max average composition value from September 2018 to August 2019 
WITH AvgCompositionCTE AS (
    SELECT
        im.month_year,
        im.interest_id,
        mp.interest_name,
        ROUND(SUM(im.composition / im.index_value), 2) AS avg_composition
    FROM fresh_segments.interest_metrics im
    JOIN fresh_segments.interest_map mp 
        ON mp.id = im.interest_id
    WHERE im.index_value != 0 AND im.month_year IS NOT NULL
    GROUP BY im.month_year, im.interest_id, mp.interest_name
),
MaxAvgCompositionPerMonth AS (
    SELECT
        month_year,
        interest_name,
        ROUND(MAX(avg_composition), 2) AS max_avg_composition
    FROM AvgCompositionCTE
    GROUP BY month_year, interest_name
),
MaxIndexCompositions AS (
    SELECT
        month_year,
        interest_name,
        max_avg_composition,
        ROW_NUMBER() OVER (PARTITION BY month_year ORDER BY max_avg_composition DESC) AS rn
    FROM MaxAvgCompositionPerMonth
),
FinalMaxIndexComposition AS (
	SELECT
		month_year,
		interest_name,
		max_avg_composition AS max_index_composition,
		ROUND(AVG(max_avg_composition) 
			  OVER (ORDER BY month_year 
			  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_avg_3_months
	FROM MaxIndexCompositions
	WHERE rn = 1 
	ORDER BY month_year
)
SELECT *
FROM FinalMaxIndexComposition
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01';

