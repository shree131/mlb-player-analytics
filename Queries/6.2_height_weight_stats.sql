WITH avg_hw AS (
	SELECT FLOOR(EXTRACT(YEAR FROM debut) / 10) * 10 AS decade, 
			ROUND(AVG(height)) AS avg_height_inches, ROUND(AVG(weight)) AS avg_weight_lbs
	FROM players
	GROUP BY FLOOR(EXTRACT(YEAR FROM debut) / 10) * 10)

SELECT  decade::INT, avg_height_inches,
		avg_height_inches - LAG(avg_height_inches) OVER (ORDER BY decade) AS height_diff,
		avg_weight_lbs,
		avg_weight_lbs - LAG(avg_weight_lbs) OVER (ORDER BY decade) AS weight_diff
FROM avg_hw
WHERE decade IS NOT NULL
ORDER BY decade;