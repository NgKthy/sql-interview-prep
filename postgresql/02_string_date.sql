-- ============================================================
-- 02_string_date.sql (PostgreSQL Port)
-- Chủ đề: Xử lý chuỗi và ngày tháng
-- Hệ CSDL: PostgreSQL 12+
-- ============================================================

-- ------------------------------------------------------------
-- Q5. Lấy first name từ cột full_names
-- ------------------------------------------------------------
SELECT DISTINCT SPLIT_PART(full_names, ' ', 1) AS first_name
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
WHERE EXTRACT(YEAR FROM joining_date) = 2017
  AND EXTRACT(MONTH FROM joining_date) = 1;

-- ------------------------------------------------------------
-- Q35. Distinct first name từ full name
-- ------------------------------------------------------------
SELECT DISTINCT SPLIT_PART(full_names, ' ', 1) AS first_name
FROM user_name;

-- ------------------------------------------------------------
-- Q46. User đăng nhập trong 30 ngày gần nhất
-- ------------------------------------------------------------
SELECT u.name, u.phone_num, MAX(uh.date) AS last_login
FROM "user" u
JOIN userhistory uh ON u.user_id = uh.user_id
WHERE uh.action = 'logged_on'
  AND uh.date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY u.user_id, u.name, u.phone_num;
