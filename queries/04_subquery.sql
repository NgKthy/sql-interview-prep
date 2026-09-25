-- ============================================================
-- 04_subquery.sql
-- Chủ đề: Subquery, IN / NOT IN / EXISTS
-- Nguồn: Q7, Q44, Q47
-- ============================================================

USE sql_interview_prep;

-- ------------------------------------------------------------
-- Q7. Nhân viên có bản ghi bonus
-- ------------------------------------------------------------
-- Cách 1: IN
SELECT *
FROM Employee
WHERE employee_id IN (SELECT employee_ref_id FROM Bonus);

-- Cách 2: EXISTS (thường nhanh hơn với bảng lớn)
SELECT *
FROM Employee e
WHERE EXISTS (
    SELECT 1 FROM Bonus b WHERE b.employee_ref_id = e.employee_id
);

-- ------------------------------------------------------------
-- Q44. Salesperson KHÔNG có order với Samsonic
-- ------------------------------------------------------------
SELECT s.name
FROM salesperson s
WHERE s.id NOT IN (
    SELECT o.salesperson_id
    FROM orders o
    JOIN customer c ON o.cust_id = c.id
    WHERE c.name = 'Samsonic'
);

-- ------------------------------------------------------------
-- Q47. user_id trong User nhưng KHÔNG có trong UserHistory
-- (không dùng MINUS/EXCEPT)
-- ------------------------------------------------------------
SELECT u.user_id
FROM user u
LEFT JOIN userhistory uh ON u.user_id = uh.user_id
WHERE uh.user_id IS NULL;
