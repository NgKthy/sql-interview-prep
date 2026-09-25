-- ============================================================
-- 08_window_functions.sql
-- Chủ đề: Window Functions (MỚI)
-- Hệ CSDL: MySQL 8.0+
-- ============================================================

USE sql_interview_prep;

-- ------------------------------------------------------------
-- W1. Xếp hạng nhân viên theo lương trong từng phòng ban
-- ------------------------------------------------------------
SELECT
    employee_id, first_name, last_name, department, salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dense_rank,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS row_num
FROM Employee;

-- ------------------------------------------------------------
-- W2. So sánh lương với người cùng phòng (LAG/LEAD)
-- ------------------------------------------------------------
SELECT
    employee_id, first_name, department, salary,
    LAG(salary)  OVER (PARTITION BY department ORDER BY salary) AS prev_salary,
    LEAD(salary) OVER (PARTITION BY department ORDER BY salary) AS next_salary,
    salary - LAG(salary) OVER (PARTITION BY department ORDER BY salary) AS delta
FROM Employee;

-- ------------------------------------------------------------
-- W3. Lương trung bình động
-- ------------------------------------------------------------
SELECT
    employee_id, joining_date, salary,
    ROUND(AVG(salary) OVER (
        ORDER BY joining_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3
FROM Employee;

-- ------------------------------------------------------------
-- W4. Tỷ lệ % lương so với trung bình phòng ban
-- ------------------------------------------------------------
SELECT
    employee_id, first_name, department, salary,
    ROUND(salary / AVG(salary) OVER (PARTITION BY department) * 100, 2) AS pct_of_dept_avg
FROM Employee;

-- ------------------------------------------------------------
-- W5. Top 2 nhân viên lương cao nhất mỗi phòng
-- ------------------------------------------------------------
SELECT *
FROM (
    SELECT
        employee_id, first_name, department, salary,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk
    FROM Employee
) t
WHERE rnk <= 2;
