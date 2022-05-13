-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS slg;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS lslg;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iiunlim;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4ib;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst, namelast ASC
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) >= 70
  ORDER BY birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT P.namefirst, P.namelast, H.playerid, H.yearid
  FROM people AS P INNER JOIN HallofFame AS H ON P.playerid = H.playerid
  WHERE H.inducted = 'Y'
  ORDER BY H.yearid DESC, H.playerid ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT P.namefirst, P.namelast, H.playerid, S.schoolid, H.yearid
  FROM Schools AS S
  INNER JOIN CollegePlaying AS C ON S.schoolid = C.schoolid
  INNER JOIN people as P on C.playerid = P.playerid
  INNER JOIN HallofFame as H on P.playerid = H.playerid
  WHERE H.inducted = 'Y' AND S.schoolState LIKE 'CA'
  ORDER BY H.yearid DESC, S.schoolid ASC, H.playerid ASC
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT H.playerid, P.namefirst, P.namelast, S.schoolid
  FROM people P
  INNER JOIN HallofFame H ON P.playerid = H.playerid
  LEFT JOIN CollegePlaying C ON P.playerid = C.playerid
  LEFT JOIN Schools S ON C.schoolid = S.schoolid
  WHERE H.inducted = 'Y'
  ORDER BY H.playerid DESC, S.schoolid ASC
;

-- Question 3i
CREATE VIEW slg(playerid, yearid, AB, slgValue)
AS
  SELECT playerid, yearid, AB, ROUND(CAST((H + H2B + 2*H3B + 3*HR)AS float)/CAST(AB AS float), 4)
  FROM batting
;

CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT P.playerid, P.namefirst, P.namelast, S.yearid, S.slgValue
  FROM people P INNER JOIN slg S ON P.playerid = S.playerid
  WHERE S.AB > 50
  ORDER BY S.slgValue DESC, S.yearid, P.playerid
  LIMIT 10
;

-- Question 3ii
CREATE VIEW lslg(playerid, lslgValue)
AS
  SELECT playerid, ROUND(CAST((SUM(H) + SUM(H2B) + 2*SUM(H3B) + 3*SUM(HR))AS float)/CAST(SUM(AB) AS float), 4)
  FROM batting
  GROUP BY playerid
  HAVING SUM(AB) > 50
;

CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT P.playerid, P.namefirst, P.namelast, L.lslgValue
  FROM people P INNER JOIN lslg L ON P.playerid = L.playerid
  ORDER BY L.lslgValue DESC, P.playerid
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iiunlim(playerid, namefirst, namelast, lslg)
AS
  SELECT P.playerid, P.namefirst, P.namelast, L.lslgValue
  FROM people P INNER JOIN lslg L ON P.playerid = L.playerid
  ORDER BY L.lslgValue DESC, P.playerid
;

CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT p.namefirst, p.namelast, q.lslg
  FROM people p INNER JOIN q3iiunlim q ON p.playerid = q.playerid
  WHERE q.lslg > (
    SELECT lslg
    FROM q3iiunlim
    WHERE playerid = 'mayswi01'
  )
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid
;


-- Helper table for 4ii
DROP TABLE IF EXISTS binids;
CREATE TABLE binids(binid);
INSERT INTO binids VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  SELECT binid, (min + binid*bin) AS low, (min +(bin*(binid + 1))) AS high, COUNT(*)
  FROM (
    SELECT CAST((MAX(salary) - MIN(salary))/10 AS INT) AS bin, MIN(salary) AS min
    FROM salaries
    WHERE yearid = 2016
  ),
  binids,
  (
    SELECT salary
    FROM salaries
    WHERE yearid = 2016
  )
  WHERE salary >= low AND salary <= high
  GROUP BY binid
;

-- Question 4iii
CREATE VIEW q4ib(yearid, min, max, avg)
AS
  SELECT yearid + 1, min, max, avg
  FROM q4i
;

CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT q4i.yearid, q4i.min - q4ib.min, q4i.max - q4ib.max, q4i.avg - q4ib.avg
  FROM q4i INNER JOIN q4ib ON q4i.yearid = q4ib.yearid
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, s.salary, q.yearid
  FROM q4i q
  INNER JOIN salaries s ON q.yearid = s.yearid
  INNER JOIN people p ON p.playerid = s.playerid
  WHERE (q.yearid = 2000 OR q.yearid = 2001) AND (s.salary = q.max)
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT a.teamid, MAX(s.salary) - MIN(s.salary)
  FROM allstarfull a INNER JOIN salaries s ON a.playerid = s.playerid
  WHERE s.yearid = 2016 AND a.yearid = 2016
  GROUP BY a.teamid
;

