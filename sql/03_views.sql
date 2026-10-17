USE JobMarket;
GO

-- 1. skill pair view
GO
CREATE VIEW vw_skill_pairs AS
SELECT a.skill AS skill_1,
	   b.skill AS skill_2,
		COUNT(*) AS jobs
FROM job_skills AS a
JOIN job_skills AS b ON a.job_id = b.job_id AND a.skill < b.skill
GROUP BY a.skill,b.skill;

-- 2. skilll salary view
GO
CREATE VIEW vw_skill_salary AS
SELECT js.skill,
	   COUNT(*) AS jobs_with_salary,
	   CAST(AVG(ft.salary_mid) AS DECIMAL(10,2)) AS avg_salary
FROM job_skills AS js
JOIN fact_jobs AS ft ON js.job_id = ft.job_id
WHERE ft.salary_mid IS NOT NULL
GROUP BY js.skill;

-- 3. entry level by state view
GO
CREATE VIEW vw_entry_level_by_state AS
SELECT state,
	   COUNT(*) AS jobs,
	   SUM(CASE WHEN exp_level IN ('Internship','Entry level') THEN 1 ELSE 0 END) AS entry_level_jobs,
	   CAST(ROUND(100.0 * SUM(CASE WHEN exp_level IN ('Internship','Entry level') THEN 1 ELSE 0 END)/
				COUNT(*),1) AS DECIMAL(10,2)) AS entry_level_pct
FROM fact_jobs
WHERE state IS NOT NULL
GROUP BY state
HAVING COUNT(*) >= 30;

GO
SELECT * FROM vw_skill_pairs
ORDER BY jobs DESC;

SELECT * FROM vw_skill_salary
ORDER BY avg_salary DESC;

SELECT * FROM vw_entry_level_by_state
ORDER BY entry_level_pct DESC;