CREATE TEMPORARY TABLE IF NOT EXISTS career_info AS (
	SELECT playerid, birthyear, birthmonth, birthday, namegiven, debut, finalgame, 
			EXTRACT(YEAR FROM debut) AS debut_year,
			EXTRACT(YEAR FROM finalgame) AS final_year
	FROM players);
	
SELECT playerid, namegiven, final_year - debut_year AS career_length,
		debut_year - birthyear AS start_age,
		final_year - birthyear AS end_age
FROM career_info
WHERE final_year - debut_year IS NOT NULL AND debut_year - birthyear > 0
ORDER BY career_length DESC;