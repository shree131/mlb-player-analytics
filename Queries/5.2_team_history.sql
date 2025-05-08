WITH career_info AS (
    SELECT playerid, birthyear, birthmonth, birthday, namegiven, debut, finalgame, 
           EXTRACT(YEAR FROM debut) AS debut_year,
           EXTRACT(YEAR FROM finalgame) AS final_year
    FROM players
)
SELECT *,
           FIRST_VALUE(teamid) OVER (PARTITION BY playerid ORDER BY yearid) AS debut_team,
           FIRST_VALUE(teamid) OVER (PARTITION BY playerid ORDER BY yearid DESC) AS final_team,
           ROW_NUMBER() OVER (PARTITION BY playerid ORDER BY yearid ASC) AS row_num
    FROM (
        SELECT ci.playerid, ci.namegiven, ci.debut_year, ci.final_year, s.yearid, s.teamid
        FROM career_info AS ci
        LEFT JOIN salaries AS s
          ON ci.playerid = s.playerid
        WHERE s.teamid IS NOT NULL
    )
    ORDER BY playerid, yearid;