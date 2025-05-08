SELECT sd.name_full AS school_name, s.players_produced
FROM school_details AS sd
RIGHT JOIN (
    SELECT schoolid, COUNT(DISTINCT playerid) AS players_produced
    FROM schools
    GROUP BY schoolid) AS s
ON sd.schoolid = s.schoolid
ORDER BY s.players_produced DESC
LIMIT 5;