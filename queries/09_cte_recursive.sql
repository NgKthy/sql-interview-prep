-- ============================================================
-- 09_cte_recursive.sql
-- Chủ đề: CTE và Recursive CTE (MỚI)
-- Hệ CSDL: MySQL 8.0+
-- ============================================================

USE sql_interview_prep;

-- ------------------------------------------------------------
-- C1. CTE cơ bản — lương trung bình theo phòng ban
-- ------------------------------------------------------------
WITH dept_avg AS (
    SELECT department, AVG(salary) AS avg_salary
    FROM Employee
    GROUP BY department
)
SELECT
    e.first_name, e.last_name, e.department, e.salary, d.avg_salary
FROM Employee e
JOIN dept_avg d ON e.department = d.department
WHERE e.salary > d.avg_salary;

-- ------------------------------------------------------------
-- C2. Nhiều CTE — lọc nhân viên Admin lương cao hơn TB
-- ------------------------------------------------------------
WITH admin_avg AS (
    SELECT AVG(salary) AS avg_salary
    FROM Employee
    WHERE department = 'Admin'
),
admin_emp AS (
    SELECT * FROM Employee WHERE department = 'Admin'
)
SELECT *
FROM admin_emp
WHERE salary > (SELECT avg_salary FROM admin_avg);

-- ------------------------------------------------------------
-- C3. Recursive CTE — sinh dãy số 1..10
-- ------------------------------------------------------------
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10
)
SELECT * FROM seq;

-- ------------------------------------------------------------
-- C4. Recursive CTE — tính giai thừa
-- ------------------------------------------------------------
WITH RECURSIVE fact AS (
    SELECT 1 AS n, 1 AS factorial
    UNION ALL
    SELECT n + 1, (n + 1) * factorial FROM fact WHERE n < 10
)
SELECT * FROM fact;
