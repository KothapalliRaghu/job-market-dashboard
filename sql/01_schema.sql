CREATE DATABASE JobMarket;
GO
USE JobMarket;
GO

CREATE TABLE fact_jobs(
job_id BIGINT NOT NULL PRIMARY KEY,
job_title NVARCHAR(300) NULL,
company NVARCHAR(300) NULL,
location NVARCHAR(300) NULL,
city NVARCHAR(200) NULL,
state NVARCHAR(100) NULL,
industry NVARCHAR(100) NULL,
role_family NVARCHAR(100) NULL,
exp_level NVARCHAR(100) NULL,
exp_level_order TINYINT NULL,
work_type NVARCHAR(100) NULL,
remote_allowed TINYINT NULL,
salary_min DECIMAL(12,2) NULL,
salary_max DECIMAL(12,2) NULL,
salary_mid DECIMAL(12,2) NULL,
posted_date DATE NULL
);
GO

CREATE TABLE job_skills(
job_id BIGINT NOT NULL,
skill NVARCHAR(100) NOT NULL
CONSTRAINT PK_job_skills PRIMARY KEY(job_id,skill)
CONSTRAINT FK_job_skills_jobs FOREIGN KEY(job_id) REFERENCES fact_jobs(job_id)
);
GO

CREATE INDEX fact_city on fact_jobs(city);
CREATE INDEX fact_state on fact_jobs(state);
CREATE INDEX fact_role_family on fact_jobs(role_family);
CREATE INDEX skills_skill on job_skills(skill);
GO