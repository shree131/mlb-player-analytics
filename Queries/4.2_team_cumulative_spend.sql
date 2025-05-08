WITH team_annual AS (
    SELECT teamid, yearid, SUM(salary) AS total_spend_yr
    FROM salaries
    GROUP BY teamid, yearid
)

SELECT teamid AS team, yearid AS year, 
       ROUND(SUM(total_spend_yr) OVER 
             (PARTITION BY teamid ORDER BY yearid) / 1000000, 1) AS cumulative_sum_in_mil
FROM team_annual
ORDER BY teamid, yearid;