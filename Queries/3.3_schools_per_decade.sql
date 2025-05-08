SELECT (FLOOR(yearid/10) * 10)::INT AS decade, COUNT(DISTINCT schoolid) AS num_schools
FROM schools
GROUP BY decade
ORDER BY decade;