WITH school_by_decade AS (
    SELECT *, FLOOR(yearid/10) * 10 AS decade
    FROM schools
    ORDER BY decade
),
school_ranking AS (
    SELECT decade, schoolid, COUNT(DISTINCT playerid) AS num_players,
        RANK() OVER (PARTITION BY decade ORDER BY COUNT(DISTINCT playerid) DESC) AS school_rank
    FROM school_by_decade
    GROUP BY decade, schoolid
)

SELECT CONCAT(decade || 's') AS decade, sd.schoolid AS school_name, sr.num_players AS num_players
FROM school_ranking AS sr
LEFT JOIN school_details AS sd ON sr.schoolid = sd.schoolid
WHERE school_rank = 1
ORDER BY sr.decade;