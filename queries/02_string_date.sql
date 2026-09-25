-- ============================================================
-- 02_string_date.sql
-- Chủ đề: Xử lý chuỗi và ngày tháng
-- Hệ CSDL: MySQL 8.0+
-- Nguồn: Q5, Q9, Q10, Q11, Q13, Q35, Q46
-- ============================================================

USE sql_interview_prep;

-- ------------------------------------------------------------
-- Q5. Lấy first name từ cột full_names
-- ------------------------------------------------------------
SELECT DISTINCT SUBSTRING_INDEX(full_names, ' ', 1) AS first_name
FROM user_name;

-- ------------------------------------------------------------
-- Q9. In first_name bằng chữ HOA
-- ------------------------------------------------------------
SELECT UPPER(first_name) AS first_name_upper
FROM Employee;

-- ------------------------------------------------------------
-- Q10. Ghép first_name và last_name
-- ------------------------------------------------------------
SELECT CONCAT(first_name, ' ', last_name) AS full_name
FROM Employee;

-- ------------------------------------------------------------
-- Q11. Nhân viên tên 'Jennifer' hoặc 'James'
-- ------------------------------------------------------------
SELECT *
FROM Employee
WHERE first_name IN ('Jennifer', 'James');

-- ------------------------------------------------------------
-- Q13. Nhân viên gia nhập tháng 1/2017
-- ------------------------------------------------------------
SELECT first_name, last_name, joining_date
FROM Employee
WHERE YEAR(joining_date) = 2017
  AND MONTH(joining_date) = 1;

-- ------------------------------------------------------------
-- Q35. Distinct first name từ full name
-- ------------------------------------------------------------
SELECT DISTINCT SUBSTRING_INDEX(full_names, ' ', 1) AS first_name
FROM user_name;

-- ------------------------------------------------------------
-- Q46. User đăng nhập trong 30 ngày gần nhất
-- ------------------------------------------------------------
SELECT u.name, u.phone_num, MAX(uh.date) AS last_login
FROM user u
JOIN userhistory uh ON u.user_id = uh.user_id
WHERE uh.action = 'logged_on'
  AND uh.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY u.user_id, u.name, u.phone_num;
