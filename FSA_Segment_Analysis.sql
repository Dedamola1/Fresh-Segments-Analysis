USE fresh_segments;

--  Top 10 and bottom 10 interests which have the largest composition values in any month_year
WITH filtered_interest_cte AS (
    SELECT *
    FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL 
      AND interest_id NOT IN (
			SELECT interest_id
			FROM fresh_segments.interest_metrics
			WHERE month_year IS NOT NULL 
			GROUP BY interest_id
			HAVING COUNT(DISTINCT month_year) < 6
      )
),
MaxCompositions AS (
    SELECT 
        interest_id,
        MAX(composition) AS max_composition_value
    FROM filtered_interest_cte
    GROUP BY interest_id
)
-- Top 10 Interests
(SELECT
    fic.month_year,
    fic.interest_id,
    ROUND(mc.max_composition_value, 2) AS max_composition_value,
    'Top' AS position
FROM filtered_interest_cte fic
JOIN MaxCompositions mc
	ON fic.interest_id = mc.interest_id
		AND fic.composition = mc.max_composition_value
ORDER BY mc.max_composition_value DESC
LIMIT 10)

UNION ALL

-- Bottom 10 Interests
(SELECT
    fic.month_year,
    fic.interest_id,
    ROUND(mc.max_composition_value, 2) AS max_composition_value,
    'Bottom' AS position
FROM filtered_interest_cte fic
JOIN MaxCompositions mc
	ON fic.interest_id = mc.interest_id
		AND fic.composition = mc.max_composition_value
ORDER BY mc.max_composition_value ASC
LIMIT 10);

-- Which 5 interests had the lowest average ranking value
WITH filtered_interest_cte AS (
    SELECT *
    FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL 
      AND interest_id NOT IN (
			SELECT interest_id
			FROM fresh_segments.interest_metrics
			WHERE month_year IS NOT NULL 
			GROUP BY interest_id
			HAVING COUNT(DISTINCT month_year) < 6
      )
)
SELECT interest_id,
		ROUND(AVG(ranking),2) AS avg_ranking_value
FROM filtered_interest_cte
GROUP BY interest_id
ORDER BY avg_ranking_value DESC
LIMIT 5;

-- Which 5 interests had the largest standard deviation in their percentile_ranking value
WITH filtered_interest_cte AS (
    SELECT *
    FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL 
      AND interest_id NOT IN (
			SELECT interest_id
			FROM fresh_segments.interest_metrics
			WHERE month_year IS NOT NULL 
			GROUP BY interest_id
			HAVING COUNT(DISTINCT month_year) < 6
      )
)
SELECT interest_id,
		ROUND(STDDEV_SAMP(percentile_ranking), 2) AS stddev_percentile_ranking
FROM filtered_interest_cte
GROUP BY interest_id
ORDER BY stddev_percentile_ranking DESC
LIMIT 5;

-- Minimum and maximum percentile_ranking values for each interest above and its corresponding year_month
WITH filtered_interest_cte AS (
    SELECT *
    FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL 
      AND interest_id NOT IN (
			SELECT interest_id
			FROM fresh_segments.interest_metrics
			WHERE month_year IS NOT NULL 
			GROUP BY interest_id
			HAVING COUNT(DISTINCT month_year) < 6
      )
),
percentile_ranking_cte AS (
	SELECT interest_id,
			ROUND(STDDEV_SAMP(percentile_ranking), 2) AS stddev_percentile_ranking
	FROM filtered_interest_cte
	GROUP BY interest_id
	ORDER BY stddev_percentile_ranking DESC
	LIMIT 5
)
SELECT 
    prc.interest_id,
    ROUND(MIN(fic.percentile_ranking), 2) AS min_percentile_ranking,
    (SELECT fic1.month_year 
	 FROM filtered_interest_cte fic1 
     WHERE fic1.interest_id = prc.interest_id 
		AND fic1.percentile_ranking = MIN(fic.percentile_ranking)) AS min_month_year,
    ROUND(MAX(fic.percentile_ranking), 2) AS max_percentile_ranking,
    (SELECT fic2.month_year 
	 FROM filtered_interest_cte fic2 
     WHERE fic2.interest_id = prc.interest_id 
		AND fic2.percentile_ranking = MAX(fic.percentile_ranking)) AS max_month_year
FROM filtered_interest_cte fic
JOIN percentile_ranking_cte prc
	ON prc.interest_id = fic.interest_id
GROUP BY prc.interest_id
ORDER BY max_percentile_ranking DESC;

-- Customers in this segment based off their composition and ranking values
WITH filtered_interest_cte AS (
    SELECT *
    FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL 
      AND interest_id NOT IN (
			SELECT interest_id
			FROM fresh_segments.interest_metrics
			WHERE month_year IS NOT NULL 
			GROUP BY interest_id
			HAVING COUNT(DISTINCT month_year) < 6
      )
)
SELECT fic.interest_id,
		ROUND(AVG(fic.ranking),2) AS avg_ranking_value,
        ROUND(MAX(fic.composition),2) AS max_composition,
        im.interest_name
FROM filtered_interest_cte fic
JOIN fresh_segments.interest_map im
	ON im.id = fic.interest_id
GROUP BY fic.interest_id, im.interest_name
ORDER BY avg_ranking_value ASC
;
