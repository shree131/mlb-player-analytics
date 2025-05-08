SELECT sd.state, COUNT(DISTINCT playerid) AS num_players
FROM schools AS s
LEFT JOIN school_details AS sd
ON s.schoolid = sd.schoolid
GROUP BY sd.state
ORDER BY num_players DESC
LIMIT 5;