-- PART I: SCHOOL ANALYSIS
-- 1. View the schools and school details tables
-- 2. In each decade, how many schools were there that produced players?
-- 3. What are the names of the top 5 schools that produced the most players?
-- 4. For each decade, what were the names of the top schools that produced the most players?

-- 1. Get to know the data
SELECT * FROM players LIMIT 10;
SELECT * FROM salaries LIMIT 10;
SELECT * FROM school_details LIMIT 10;
SELECT * FROM schools LIMIT 10;

-- 2a. Top 5 schools that produced MLB players
SELECT sd.name_full AS school_name, s.players_produced
FROM school_details AS sd
RIGHT JOIN (
	SELECT schoolid, COUNT(DISTINCT playerid) AS players_produced
	FROM schools
	GROUP BY schoolid) AS s
ON sd.schoolid = s.schoolid
ORDER BY s.players_produced DESC
LIMIT 5;

-- 2b. What states (Top 3) produced the most players?
SELECT sd.state, COUNT(DISTINCT playerid) AS num_players
FROM schools AS s
LEFT JOIN school_details AS sd
ON s.schoolid = sd.schoolid
GROUP BY sd.state
ORDER BY num_players DESC
LIMIT 3;

-- 3. Number of schools that produced players within each decade.
SELECT FLOOR(yearid/10) * 10 AS decade, COUNT(DISTINCT schoolid) AS num_schools
FROM schools
GROUP BY decade
ORDER BY decade;

-- 4. What were the top schools that produced the most players for each decade.
WITH school_by_decade AS (
	 SELECT *, FLOOR(yearid/10) * 10 AS decade
	 FROM schools
	 ORDER BY decade
),
school_ranking AS (
	 SELECT decade, schoolid, COUNT(DISTINCT playerid) AS num_players,
			ROW_NUMBER() OVER (PARTITION BY decade ORDER BY COUNT(DISTINCT playerid) DESC) AS school_rank
	 FROM school_by_decade
	 GROUP BY decade, schoolid
)

SELECT CONCAT(sr.decade, 's') AS decade, 
	   sd.name_full AS school_name, sr.num_players AS num_players
FROM school_ranking AS sr
LEFT JOIN school_details AS sd ON sr.schoolid = sd.schoolid
WHERE school_rank =1
ORDER BY sr.decade DESC;

-- PART II: SALARY ANALYSIS
-- 1. View the salaries table
-- 2. Return the top 20% of teams in terms of average annual spending
-- 3. For each team, show the cumulative sum of spending over the years
-- 4. Return the first year that each team's cumulative spending surpassed 1 billion

-- 1. 
SELECT * FROM salaries LIMIT 10;

-- 2a. Total Annual spending for each team
CREATE TEMPORARY TABLE IF NOT EXISTS team_annual AS (
	SELECT teamid, yearid, SUM(salary) AS total_spend_yr
	FROM salaries
	GROUP BY teamid, yearid
	ORDER BY teamid, yearid);

-- 2b. Average annual spending by team
WITH avg_spend_tiles AS (
	SELECT teamid,
			AVG(total_spend_yr) AS avg_yearly_spend,
			NTILE(5) OVER (ORDER BY ROUND(AVG(total_spend_yr)) DESC) AS spend_pct
	FROM team_annual
	GROUP BY teamid)

-- 2c. Top 20% of teams in terms of average annual spending
SELECT teamid, ROUND(avg_yearly_spend / 1000000, 1) AS avg_spend_in_mil
FROM avg_spend_tiles
WHERE spend_pct = 1;

-- 3. For each team, show the cumulative sum of spending over the years
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

-- 4. Return the first year that each team's cumulative spending surpassed 1 billion
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


-- PART III: PLAYER CAREER ANALYSIS
-- 1. View the players table and find the number of players in the table
-- 2. For each player, calculate their age at their first game, their last game, and their career length (all in years). Sort from longest career to shortest career.
-- 3. What team did each player play on for their starting and ending years?
-- 4. How many players started and ended on the same team and also played for over a decade?

-- 1a.
SELECT playerid, birthyear, birthmonth, birthday, namegiven, debut, finalgame
FROM players;

-- 1b. There are 18,589 players present in the table
SELECT COUNT(DISTINCT(playerid))
FROM players;

/* Intend to answer the following questions:
	1a. View fields of interest: playerid, birthyear, namegiven, debut, finalgame
	1b. Number of players
	2. Career length, Age when they started and ended career 
	3. Teams played by each player over the years (particularly 1st and last)
	4. Players that started and ended on the same team and played for over a decade */

-- 2. 
CREATE TEMPORARY TABLE IF NOT EXISTS career_info AS (
	SELECT playerid, birthyear, birthmonth, birthday, namegiven, debut, finalgame, 
			EXTRACT(YEAR FROM debut) AS debut_year,
			EXTRACT(YEAR FROM finalgame) AS final_year
	FROM players);
	
SELECT playerid, namegiven, final_year - debut_year AS career_length,
		debut_year - birthyear AS start_age,
		final_year - birthyear AS end_age
FROM career_info
WHERE final_year - debut_year IS NOT NULL
ORDER BY career_length DESC;

-- 3. What team did each player play on for their starting and ending years?
-- Also accounting for the fact that final_year is not always in salaries table
CREATE TEMPORARY TABLE IF NOT EXISTS career_team AS (
	SELECT *,
			FIRST_VALUE(teamid) OVER (PARTITION BY playerid ORDER BY yearid) AS debut_team,
			FIRST_VALUE(teamid) OVER (PARTITION BY playerid ORDER BY yearid DESC) AS final_team,
			ROW_NUMBER() OVER (PARTITION BY playerid ORDER BY yearid ASC) AS row_num
	FROM (SELECT ci.playerid, ci.namegiven, ci.debut_year, ci.final_year, s.yearid, s.teamid
		FROM career_info AS ci
		LEFT JOIN salaries AS s
		ON ci.playerid = s.playerid 
		WHERE s.teamid IS NOT NULL)
	ORDER BY playerid, yearid);

SELECT playerid, namegiven, debut_year, debut_team, final_year, final_team
	FROM career_team
WHERE row_num = 1;

-- 4. Players that played for a decade or more and ended up in the same team as their debut
SELECT namegiven, final_year - debut_year AS career_length, 
		debut_year, debut_team, final_year, final_team
	FROM career_team
WHERE row_num = 1 AND debut_team = final_team AND 
		final_year - debut_year > 10
ORDER BY playerid;

-- 4b. Players with highest number of teams switched (15+) in their career
SELECT namegiven, COUNT(DISTINCT teamid) AS teams_num
FROM career_team
GROUP BY namegiven
HAVING COUNT(DISTINCT teamid) >= 15
ORDER BY teams_num DESC;

-- PART IV: PLAYER COMPARISON ANALYSIS
-- 1. View the players table
-- 2. Which players have the same birthday?
-- 3. Create a summary table that shows for each team, what percent of players bat right, left and both
-- 4. How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference?

/* Answer the following questions:
	1. Fields of interest: weight, height, bats, throws, birthday (age group).
	2a. What players are of the same age?
	2b. Age group that players fall under.
	3a. Summary table for each team and percent of players that bat right, left, or both.
	3b. Same as above but for throws.
	4. How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference? 
*/

-- 1.
SELECT playerid, namegiven, birthyear, birthmonth, birthday, weight, height, bats, throws,
		debut, finalgame
FROM players;

-- 2a. Living players that are of the same age
WITH players_info AS (
SELECT playerid, namegiven, (birthyear || '-' || birthmonth || '-' || birthday)::DATE AS birthdate, 
		weight, height, bats, throws, debut, finalgame
FROM players
WHERE deathyear IS NULL)

SELECT EXTRACT(YEAR FROM AGE(birthdate)) AS age, 
		COUNT(*) AS players_num,
		STRING_AGG(namegiven, ' | ' ORDER BY namegiven) AS player_names
FROM players_info
WHERE birthdate IS NOT NULL
GROUP BY EXTRACT(YEAR FROM AGE(birthdate))
HAVING COUNT(*) > 1
ORDER BY age;

/* Maybe more beneficial to look at count of players by age group */
WITH players_info AS (
SELECT playerid, namegiven, (birthyear || '-' || birthmonth || '-' || birthday)::DATE AS birthdate, 
		weight, height, bats, throws, debut, finalgame
FROM players
WHERE deathyear IS NULL),

-- 2b. Group by age group and with atleast 50 players within the age group
players_by_age_group AS (
	SELECT *, FLOOR(EXTRACT(YEAR FROM AGE(birthdate)) / 10) * 10 AS age_group
	FROM players_info
	WHERE birthdate IS NOT NULL)

SELECT CONCAT(age_group || 's') AS age_group, COUNT(*) AS players_num
FROM players_by_age_group
GROUP BY age_group
HAVING COUNT(*) > 50
ORDER BY players_num DESC;

-- 3a. Summary table for each team and percent of players that bat right, left, or both.

-- Join salary (team info) and players (batting preference) table
SELECT p.playerid, p.namegiven, p.bats, s.teamid
FROM players AS p
LEFT JOIN salaries AS s
ON p.playerid = s.playerid;

-- GROUP BY teams and view summary stats for batting preference
WITH sum_stats AS (
	SELECT s.teamid,
			COUNT(DISTINCT CASE WHEN p.bats = 'B' THEN p.playerid ELSE NULL END) AS both,
			COUNT(DISTINCT CASE WHEN p.bats = 'L' THEN p.playerid ELSE NULL END) AS left,
			COUNT(DISTINCT CASE WHEN p.bats = 'R' THEN p.playerid ELSE NULL END) AS right,
			COUNT(DISTINCT p.playerid) * 1.0 AS total
	FROM players AS p
	LEFT JOIN salaries AS s
	ON p.playerid = s.playerid
	GROUP BY s.teamid)

SELECT COALESCE(s.teamid, 'N/A') AS team,
		ROUND(s.both/s.total * 100, 2) || '%' AS both_pct,
		ROUND(s.left/s.total * 100, 2) || '%' AS left_pct,
		ROUND(s.right/s.total * 100, 2) || '%' AS right_pct
FROM sum_stats AS s;

-- 4. How have average height and weight at debut game changed over the years, 
-- and what's the decade-over-decade difference?
WITH avg_hw AS (
	SELECT FLOOR(EXTRACT(YEAR FROM debut) / 10) * 10 AS decade, 
			ROUND(AVG(height)) AS avg_height_inches, ROUND(AVG(weight)) AS avg_weight_lbs
	FROM players
	GROUP BY FLOOR(EXTRACT(YEAR FROM debut) / 10) * 10)

SELECT decade || 's' AS decade, avg_height_inches,
		avg_height_inches - LAG(avg_height_inches) OVER (ORDER BY decade) AS height_diff,
		avg_weight_lbs,
		avg_weight_lbs - LAG(avg_weight_lbs) OVER (ORDER BY decade) AS weight_diff
FROM avg_hw
WHERE decade IS NOT NULL
ORDER BY decade;