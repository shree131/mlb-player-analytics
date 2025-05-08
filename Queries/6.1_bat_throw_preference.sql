WITH sum_stats AS (
    SELECT 
        s.teamid,
        COUNT(DISTINCT CASE WHEN p.bats = 'B' THEN p.playerid ELSE NULL END) AS bat_both,
        COUNT(DISTINCT CASE WHEN p.bats = 'L' THEN p.playerid ELSE NULL END) AS bat_left,
        COUNT(DISTINCT CASE WHEN p.bats = 'R' THEN p.playerid ELSE NULL END) AS bat_right,
        COUNT(DISTINCT CASE WHEN p.throws = 'L' THEN p.playerid ELSE NULL END) AS throw_left,
        COUNT(DISTINCT CASE WHEN p.throws = 'R' THEN p.playerid ELSE NULL END) AS throw_right,
        COUNT(DISTINCT p.playerid) * 1.0 AS total
    FROM players AS p
    LEFT JOIN salaries AS s ON p.playerid = s.playerid
    WHERE teamid IS NOT NULL
    GROUP BY s.teamid
)

SELECT COALESCE(teamid, 'N/A') AS team,
		ROUND(bat_both/total * 100, 2) AS bat_both_pct,
		ROUND(bat_left/total * 100, 2) AS bat_left_pct,
		ROUND(bat_right/total * 100, 2) AS bat_right_pct,
		ROUND(throw_left/total * 100, 2) AS throw_left_pct,
		ROUND(throw_right/total * 100, 2) throw_right_pct
FROM sum_stats;