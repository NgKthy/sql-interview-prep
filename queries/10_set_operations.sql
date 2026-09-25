-- ============================================================
-- 10_set_operations.sql
-- Chủ đề: UNION / INTERSECT / EXCEPT (MỚI)
-- Hệ CSDL: MySQL 8.0.31+
-- ============================================================

USE sql_interview_prep;

-- ------------------------------------------------------------
-- S1. UNION — danh sách phòng ban xuất hiện trong Employee và Bonus
-- ------------------------------------------------------------
SELECT department AS dept FROM Employee
UNION
SELECT 'Có bonus' FROM Bonus;

-- ------------------------------------------------------------
-- S2. INTERSECT — nhân viên vừa có bonus vừa có title Manager
-- ------------------------------------------------------------
SELECT employee_ref_id FROM Bonus
INTERSECT
SELECT employee_ref_id FROM Title WHERE employee_title = 'Manager';

-- ------------------------------------------------------------
-- S3. EXCEPT — nhân viên có title nhưng không có bonus
-- ------------------------------------------------------------
SELECT employee_ref_id FROM Title
EXCEPT
SELECT employee_ref_id FROM Bonus;

-- ------------------------------------------------------------
-- S4. UNION ALL — danh sách tất cả user (không loại trùng)
-- ------------------------------------------------------------
SELECT user_1 AS user_id FROM user_interaction
UNION ALL
SELECT user_2 AS user_id FROM user_interaction;
