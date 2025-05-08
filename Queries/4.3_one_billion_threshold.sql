WITH team_annual AS (
    SELECT teamid, yearid, SUM(salary) AS total_spend_yr
    FROM salaries
    GROUP BY teamid, yearid
),
team_cumulative AS (
	SELECT teamid, yearid, 
			ROUND(SUM(total_spend_yr) OVER 
			(PARTITION BY teamid ORDER BY yearid) / 1000000, 1) AS cumulative_sum_in_mil
	FROM team_annual
),
year_ranking AS (
	SELECT *, FIRST_VALUE(yearid) OVER (PARTITION BY teamid ORDER BY yearid) AS yr_1_bil
	FROM team_cumulative
	WHERE cumulative_sum_in_mil > 1000
	ORDER BY teamid, yearid)

SELECT teamid, yr_1_bil, ROUND(cumulative_sum_in_mil / 1000, 2) AS cumulative_sum_in_bil
FROM year_ranking
WHERE yearid = yr_1_bil;