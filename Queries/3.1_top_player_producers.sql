SELECT sd.name_full AS school_name, COUNT(DISTINCT s.playerid) AS players_produced
FROM schools AS s
JOIN school_details AS sd ON s.schoolid = sd.schoolid
GROUP BY sd.name_full
ORDER BY players_produced DESC
LIMIT 5;