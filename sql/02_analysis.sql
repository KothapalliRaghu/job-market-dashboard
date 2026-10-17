-- Q1: Market overview
SELECT COUNT(*) AS total_jobs,
	   COUNT(DISTINCT company) AS companies,
	   COUNT(DISTINCT city) AS cities,
	   CAST(ROUND(100.0 * COUNT(salary_mid)/COUNT(*),1) AS DECIMAL(5,1)) AS salary_pct
FROM fact_jobs;
-- there are total 2318 jobs with salary percentage of 31.1%.

-- Q2: Which skills are most demanded?
SELECT skill,
	   COUNT(DISTINCT job_id) AS jobs,
	   CAST(ROUND(100.0 * COUNT(DISTINCT job_id)/
			(SELECT COUNT(*) FROM fact_jobs),1) AS DECIMAL(5,1)) AS demand_pct
FROM job_skills
GROUP BY skill
ORDER BY jobs DESC;
-- SQL appears in 50.85 of postings.

-- Q3: Skill demand within each role family
SELECT ft.role_family,
	   js.skill,
	   COUNT(DISTINCT js.job_id) AS jobs,
	   CAST(ROUND(100.0 * COUNT(DISTINCT js.job_id)/t.n,1) AS DECIMAL(5,1)) AS dem_pct
FROM fact_jobs AS ft
JOIN job_skills AS js ON ft.job_id = js.job_id
JOIN (SELECT role_family,COUNT(*) AS n
		FROM fact_jobs
		GROUP BY role_family) AS t ON ft.role_family = t.role_family
GROUP BY ft.role_family,js.skill,t.n
ORDER BY role_family,jobs DESC;
-- SQL plays key role in Business / BI Analyst,Data Analyst,Data Engineer.

-- Q4: Which cities have the most jobs?
SELECT TOP 10 city,
			  COUNT(*) AS jobs,
			  CAST(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(),1) AS DECIMAL(5,1)) AS share_pct
FROM fact_jobs
WHERE city IS NOT NULL
GROUP BY city
ORDER BY jobs DESC;
-- Nwe York have the most jobs with 5.3 share percent.

-- Q5a: Median salary by state
SELECT state,jobs_with_salary,median_salary
FROM ( SELECT DISTINCT state,
			  COUNT(salary_mid) OVER(PARTITION BY state) AS jobs_with_salary,
			  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary_mid)
				OVER(PARTITION BY state) AS median_salary
		FROM fact_jobs
		WHERE salary_mid IS NOT NULL AND state IS NOT NULL
		) AS t
WHERE jobs_with_salary >= 30
ORDER BY median_salary DESC;
-- WA have the highest median salary of 150800.

--Q5b: Median salary by city
SELECT city,jobs_with_salary,median_salary
FROM ( SELECT DISTINCT city,
			  COUNT(salary_mid) OVER(PARTITION BY city) AS jobs_with_salary,
			  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary_mid)
				OVER(PARTITION BY city) AS median_salary
		FROM fact_jobs
		WHERE salary_mid IS NOT NULL AND city IS NOT NULL
		) AS t
WHERE jobs_with_salary >= 10
ORDER BY median_salary DESC;
-- Seattle has the highest salary which is 165250.

--Q6: Which skills go with higher pay?
SELECT js.skill,
	   COUNT(*) AS jobs_with_salary,
	   CAST(AVG(ft.salary_mid) AS DECIMAL(10,2)) AS avg_salary
FROM job_skills AS js
JOIN fact_jobs AS ft ON js.job_id = ft.job_id
WHERE ft.salary_mid IS NOT NULL
GROUP BY js.skill
HAVING COUNT(*) >= 30
ORDER BY avg_salary DESC;
-- TensorFlow/PyTorch is the high paying skill.

--Q7a: Which industries hire the most?
WITH ind AS(
	SELECT industry,
			COUNT(*) AS jobs,
			SUM(CASE WHEN exp_level IN ('Internship','Entry level') THEN 1 ELSE 0 END) AS entry_jobs
	FROM fact_jobs
	WHERE industry IS NOT NULL
	GROUP BY industry
	)
SELECT TOP 15 industry,jobs,
			CAST(ROUND(100.0 * jobs/SUM(jobs) OVER(),1) AS DECIMAL(10,2)) AS share_pct,
			CAST(ROUND(100.0 * entry_jobs/jobs,1) AS DECIMAL(10,2))AS entry_level_pct
FROM ind
ORDER BY jobs DESC;
-- IT Services and IT Consulting hires the most.

--Q7b: How much does pay rise between experience levels?
WITH med AS (
	SELECT DISTINCT exp_level,
		CASE exp_level WHEN 'Internship' THEN 1
					   WHEN 'Entry level' THEN 2
					   WHEN 'Associate' THEN 3
					   WHEN 'Mid-Senior level' THEN 4
					   WHEN 'Director' THEN 5
					   WHEN 'Executive' THEN 6 END AS lvl,
		COUNT(salary_mid) OVER(PARTITION BY exp_level) AS jobs_with_salary,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary_mid)
		OVER(PARTITION BY exp_level) AS median_salary
		FROM fact_jobs
		WHERE  salary_mid IS NOT NULL
		AND exp_level IN ('Internship','Entry level','Associate','Mid-Senior level','Director','Executive')
		)
SELECT exp_level,jobs_with_salary,median_salary,
		median_salary - LAG(median_salary) OVER(ORDER BY lvl) AS step_up
FROM med
ORDER BY lvl;
-- Entry level to Associate is a negative step (-11,036), which is a result worth a comment. 
-- Internship and Executive have very few jobs

--Q8: Top 3 hiring companies per industry
SELECT industry,company,jobs,rnk
 FROM (SELECT industry,
	   company,
	   COUNT(*) AS jobs,
	   SUM(COUNT(*) ) OVER(PARTITION BY industry) AS industry_jobs,
	   DENSE_RANK() OVER(PARTITION BY industry ORDER BY COUNT(*) DESC) AS rnk
FROM fact_jobs
WHERE industry IS NOT NULL AND company IS NOT NULL
GROUP BY industry,company
) AS t
WHERE rnk <= 3 AND industry_jobs >= 50
ORDER BY industry,rnk;

--Q9: Which skills appear together?
SELECT TOP 15 a.skill AS skill_1,
	   b.skill AS skill_2,
		COUNT(*) AS jobs
FROM job_skills AS a
JOIN job_skills AS b ON a.job_id = b.job_id AND a.skill < b.skill
GROUP BY a.skill,b.skill
ORDER BY jobs DESC;
-- Python and SQL skill set have the highest jobs of 682.

--Q10: Where are the entry-level jobs?
SELECT state,
	   COUNT(*) AS jobs,
	   SUM(CASE WHEN exp_level IN ('Internship','Entry level') THEN 1 ELSE 0 END) AS entry_level_jobs,
	   CAST(ROUND(100.0 * SUM(CASE WHEN exp_level IN ('Internship','Entry level') THEN 1 ELSE 0 END)/
				COUNT(*),1) AS DECIMAL(10,2)) AS entry_level_pct
FROM fact_jobs
WHERE state IS NOT NULL
GROUP BY state
HAVING COUNT(*) >= 50
ORDER BY entry_level_pct DESC;
-- State VA have highest entry-level_percentage of 30.02%.