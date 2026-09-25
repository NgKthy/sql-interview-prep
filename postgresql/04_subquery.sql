-- ============================================================
-- 04_subquery.sql  (PostgreSQL port)
-- Chủ đề: Subquery, IN / NOT IN / EXISTS
-- Nguồn: Q7, Q44, Q47
-- Khác biệt vs MySQL: EXCEPT thay cho NOT IN (an toàn hơn); EXCEPT chuẩn SQL:1999.
-- ============================================================

-- ============================================================
-- Q7. Nhân viên có bản ghi bonus
-- ------------------------------------------------------------
-- PostgreSQL note: Cú pháp IN và EXISTS hoàn toàn giống MySQL.
-- Độ phức tạp: O(n*m).
-- ============================================================

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

-- ============================================================
-- Q44. Salesperson KHÔNG có order với Samsonic
-- ------------------------------------------------------------
-- PostgreSQL note: NOT IN hoạt động như MySQL — cảnh báo NULL vẫn áp dụng.
-- Cách thay thế tốt hơn trong PG: LEFT JOIN IS NULL hoặc NOT EXISTS.
-- Độ phức tạp: O(n*m).
-- ============================================================
SELECT s.name
FROM salesperson s
WHERE s.id NOT IN (
    SELECT o.salesperson_id
    FROM orders o
    JOIN customer c ON o.cust_id = c.id
    WHERE c.name = 'Samsonic'
);

-- Cách 2: LEFT JOIN + IS NULL (an toàn với NULL, hiệu suất tốt hơn)
SELECT s.name
FROM salesperson s
LEFT JOIN orders o ON s.id = o.salesperson_id
LEFT JOIN customer c ON o.cust_id = c.id AND c.name = 'Samsonic'
WHERE o.salesperson_id IS NULL;

-- ============================================================
-- Q47. user_id trong User nhưng KHÔNG có trong UserHistory
-- ------------------------------------------------------------
-- PostgreSQL note: LEFT JOIN IS NULL giống MySQL.
-- PG cũng hỗ trợ EXCEPT (chuẩn SQL:1999) — khác MySQL cũ không hỗ trợ.
--
-- Cách thay thế PG-specific: EXCEPT
--   SELECT user_id FROM "user"
--   EXCEPT
--   SELECT user_id FROM userhistory;
--
-- Độ phức tạp: O(n + m).
-- ============================================================
SELECT u.user_id
FROM "user" u                          -- "user" là reserved word trong PG → cần dấu ngoặc kép
LEFT JOIN userhistory uh ON u.user_id = uh.user_id
WHERE uh.user_id IS NULL;
