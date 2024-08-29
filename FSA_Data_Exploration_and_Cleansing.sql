-- Updating the interest_metrics table by modifying the month_year column to be a date data type
ALTER TABLE fresh_segments.interest_metrics
ADD COLUMN month_year_backup VARCHAR(255);

ALTER TABLE fresh_segments.interest_metrics
MODIFY COLUMN month_year VARCHAR(20);

UPDATE fresh_segments.interest_metrics
SET month_year_backup = CONCAT('01-', month_year);

UPDATE fresh_segments.interest_metrics 
SET month_year = STR_TO_DATE(month_year_backup, '%d-%m-%Y');

#UPDATE fresh_segments.interest_metrics
#SET month_year_backup = DATE_FORMAT(STR_TO_DATE(month_year_backup, '%d-%m-%Y'), '%m/%d/%Y');

#UPDATE fresh_segments.interest_metrics 
#SET month_year_backup = DATE_FORMAT(STR_TO_DATE(month_year_backup, '%m/%d/%Y'), '%d-%m-%Y');

ALTER TABLE fresh_segments.interest_metrics
MODIFY COLUMN month_year DATE;

ALTER TABLE fresh_segments.interest_metrics
DROP COLUMN month_year_backup;

-- Count of records for each month_year value sorted in chronological order (earliest to latest)
SELECT month_year, 
	   COUNT(*) AS count_of_records
FROM Fresh_segments.interest_metrics
GROUP BY month_year
ORDER BY month_year IS NULL DESC;

-- Null percentage in interest metrics table
SELECT 
  ROUND(100 * (SUM(CASE WHEN interest_id IS NULL THEN 1 END) * 1.0 / COUNT(*)),2) AS null_perc
FROM fresh_segments.interest_metrics;

DELETE FROM fresh_segments.interest_metrics
WHERE interest_id IS NULL;

-- Interest_id values present in interest_metrics table but not in the interest_map table and vice-versa
SELECT COUNT(DISTINCT im.interest_id) AS missing_interest_ids
FROM Fresh_segments.interest_metrics im
LEFT JOIN Fresh_segments.interest_map mp
ON im.interest_id = mp.id
WHERE mp.id IS NULL;

SELECT COUNT(DISTINCT mp.id) AS missing_ids
FROM Fresh_segments.interest_map mp
LEFT JOIN Fresh_segments.interest_metrics im
ON mp.id = im.interest_id
WHERE im.interest_id IS NULL;

-- id values in the interest_map by its total record count in this table
SELECT id, 
	   interest_name,
	   COUNT(*) AS total_count
FROM fresh_segments.interest_map mp
JOIN fresh_segments.interest_metrics im
  ON mp.id = im.interest_id
GROUP BY id, interest_name
ORDER BY total_count DESC, id;

-- Joined output including all columns from interest_metrics and all columns from interest_map except from the id column.
SELECT im.*,
		mp.interest_name,
        mp.interest_summary,
        mp.created_at,
        mp.last_modified
FROM Fresh_segments.interest_metrics im
INNER JOIN Fresh_segments.interest_map mp
ON im.interest_id = mp.id
WHERE interest_id = 21246 AND month_year IS NOT NULL;

-- Records in the joined table where the month_year value is before the created_at value from the interest_map table
SELECT *
FROM fresh_segments.interest_map mp
INNER JOIN fresh_segments.interest_metrics im
  ON mp.id = im.interest_id
WHERE im.month_year < mp.created_at;

