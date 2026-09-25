-- ============================================================
-- 01_basic.sql (PostgreSQL Port)
-- Chủ đề: Truy vấn cơ bản, aggregate, sắp xếp
-- Hệ CSDL: PostgreSQL 12+
-- ============================================================

-- ------------------------------------------------------------
-- Q1. Tìm mức lương cao thứ n (ví dụ: cao thứ 3)
-- ------------------------------------------------------------
-- Cách 1: DISTINCT + LIMIT ... OFFSET (PostgreSQL Standard)
SELECT DISTINCT salary
FROM Employee
ORDER BY salary DESC
LIMIT 1 OFFSET 2;   -- bỏ qua 2 bản ghi, lấy 1

-- Cách 2: Subquery đếm số mức lương lớn hơn
SELECT DISTINCT e1.salary
FROM Employee e1
WHERE 3 = (
    SELECT COUNT(DISTINCT e2.salary)
    FROM Employee e2
    WHERE e2.salary >= e1.salary
)
ORDER BY e1.salary DESC;

-- ------------------------------------------------------------
-- Q2. Lấy top n bản ghi (ví dụ: top 5 theo lương)
-- ------------------------------------------------------------
SELECT *
FROM Employee
ORDER BY salary DESC
LIMIT 5;

-- ------------------------------------------------------------
-- Q3. Đếm số nhân viên phòng 'Admin'
-- ------------------------------------------------------------
SELECT COUNT(*) AS admin_count
FROM Employee
WHERE department = 'Admin';

-- ------------------------------------------------------------
-- Q4. Đếm nhân viên theo phòng ban, sắp xếp giảm dần
-- ------------------------------------------------------------
SELECT department, COUNT(*) AS employee_count
FROM Employee
GROUP BY department
ORDER BY employee_count DESC;

-- ------------------------------------------------------------
-- Q15. Liệt kê tất cả phòng ban kèm số người
-- ------------------------------------------------------------
SELECT department, COUNT(*) AS num_employees
FROM Employee
GROUP BY department
ORDER BY num_employees DESC;

-- ------------------------------------------------------------
-- Q16. Lấy bản ghi cuối cùng của bảng
-- ------------------------------------------------------------
SELECT *
FROM Employee
WHERE employee_id = (SELECT MAX(employee_id) FROM Employee);

-- ------------------------------------------------------------
-- Q17. Lấy bản ghi đầu tiên của bảng
-- ------------------------------------------------------------
SELECT *
FROM Employee
WHERE employee_id = (SELECT MIN(employee_id) FROM Employee);

-- ------------------------------------------------------------
-- Q18. Lấy 5 bản ghi cuối, sắp xếp tăng dần theo id
-- ------------------------------------------------------------
SELECT *
FROM (
    SELECT * FROM Employee ORDER BY employee_id DESC LIMIT 5
) AS last5
ORDER BY employee_id ASC;

-- ------------------------------------------------------------
-- Q19. Nhân viên có lương cao nhất trong mỗi phòng ban
-- ------------------------------------------------------------
SELECT first_name, last_name, department, salary
FROM (
    SELECT *,
           RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk
    FROM Employee
) t
WHERE rnk = 1;

-- ------------------------------------------------------------
-- Q20. Lấy ba mức lương cao nhất (không trùng)
-- ------------------------------------------------------------
SELECT DISTINCT salary
FROM Employee
ORDER BY salary DESC
LIMIT 3;

-- ------------------------------------------------------------
-- Q21. Tổng lương theo từng phòng ban
-- ------------------------------------------------------------
SELECT department, SUM(salary) AS total_salary
FROM Employee
GROUP BY department
ORDER BY total_salary DESC;

-- ------------------------------------------------------------
-- Q22. Nhân viên có lương cao nhất toàn công ty
-- ------------------------------------------------------------
SELECT first_name, last_name, salary
FROM Employee
WHERE salary = (SELECT MAX(salary) FROM Employee);
