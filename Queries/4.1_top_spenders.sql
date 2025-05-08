CREATE TEMPORARY TABLE IF NOT EXISTS team_annual AS (
	SELECT teamid, yearid, SUM(salary) AS total_spend_yr
	FROM salaries
	GROUP BY teamid, yearid
	ORDER BY teamid, yearid);

WITH avg_spend_tiles AS (
	SELECT teamid,
			AVG(total_spend_yr) AS avg_yearly_spend,
			NTILE(5) OVER (ORDER BY ROUND(AVG(total_spend_yr)) DESC) AS spend_pct
	FROM team_annual
	GROUP BY teamid)

SELECT teamid AS team, ROUND(avg_yearly_spend / 1000000, 1) AS avg_spend_in_mil
FROM avg_spend_tiles
WHERE spend_pct = 1;