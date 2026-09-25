-- ============================================================
-- 03_self_join.sql
-- Chủ đề: Self join
-- Nguồn: Q6, Q14, Q25
-- ============================================================

USE sql_interview_prep;

-- ------------------------------------------------------------
-- Q6. Nhân viên đồng thời là quản lý
-- ------------------------------------------------------------
SELECT e1.first_name, e1.last_name
FROM Employee e1
JOIN Employee e2 ON e1.employee_id = e2.manager_id;

-- ------------------------------------------------------------
-- Q14. Nhân viên có cùng mức lương
-- ------------------------------------------------------------
SELECT e1.first_name, e1.last_name, e1.salary
FROM Employee e1
JOIN Employee e2
  ON e1.salary = e2.salary
 AND e1.employee_id <> e2.employee_id;

-- ------------------------------------------------------------
-- Q25. Nhân viên có cùng mức lương (bao gồm salary trong output)
-- ------------------------------------------------------------
SELECT DISTINCT e1.first_name, e1.last_name, e1.salary
FROM Employee e1
JOIN Employee e2
  ON e1.salary = e2.salary
 AND e1.employee_id <> e2.employee_id
ORDER BY e1.salary DESC;
