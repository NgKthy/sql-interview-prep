-- ============================================================
-- 14_performance_tuning.sql
-- Chủ đề: Index, EXPLAIN, query optimization
-- Nguồn: Use The Index, Luke + MySQL Performance Blog
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- PHẦN 1: EXPLAIN — đọc execution plan
-- ============================================================

-- ------------------------------------------------------------
-- P1. EXPLAIN cơ bản
-- ------------------------------------------------------------
EXPLAIN
SELECT * FROM Employee WHERE department = 'Admin';

-- Các cột cần chú ý:
--   type: ALL (full scan, tệ) < index < range < ref < eq_ref < const (tốt)
--   possible_keys: index có thể dùng
--   key: index thực tế dùng
--   rows: số dòng ước tính phải scan
--   Extra: "Using filesort" / "Using temporary" là dấu hiệu xấu

-- ------------------------------------------------------------
-- P2. EXPLAIN ANALYZE — chạy thật và đo thời gian
-- ------------------------------------------------------------
EXPLAIN ANALYZE
SELECT department, COUNT(*)
FROM Employee
GROUP BY department;

-- ------------------------------------------------------------
-- P3. EXPLAIN FORMAT=JSON — chi tiết hơn
-- ------------------------------------------------------------
EXPLAIN FORMAT=JSON
SELECT e.first_name, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id
WHERE e.department = 'Admin';

-- ============================================================
-- PHẦN 2: INDEX — khi nào và cách tạo
-- ============================================================

-- ------------------------------------------------------------
-- P4. Tạo index đơn
-- ------------------------------------------------------------
CREATE INDEX idx_employee_department ON Employee(department);

-- Sau khi tạo, chạy lại EXPLAIN P1 → type sẽ là "ref", rows giảm mạnh.

-- ------------------------------------------------------------
-- P5. Composite index (index nhiều cột)
-- ------------------------------------------------------------
-- Thứ tự cột quan trọng: prefix phải khớp WHERE
CREATE INDEX idx_employee_dept_salary ON Employee(department, salary);

-- Index này dùng được cho:
--   WHERE department = 'Admin'
--   WHERE department = 'Admin' AND salary > 100000
-- KHÔNG dùng được cho:
--   WHERE salary > 100000   (thiếu prefix department)

-- ------------------------------------------------------------
-- P6. Covering index — index chứa hết cột cần thiết
-- ------------------------------------------------------------
CREATE INDEX idx_employee_covering
    ON Employee(department, employee_id, first_name, last_name);

-- Query sau sẽ dùng covering index, không cần đọc bảng:
EXPLAIN
SELECT employee_id, first_name, last_name
FROM Employee
WHERE department = 'Admin';

-- ------------------------------------------------------------
-- P7. Index cho JOIN
-- ------------------------------------------------------------
-- Foreign key thường nên có index để JOIN nhanh
CREATE INDEX idx_bonus_emp_ref ON Bonus(employee_ref_id);

EXPLAIN
SELECT e.first_name, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id;

-- ------------------------------------------------------------
-- P8. Index cho ORDER BY
-- ------------------------------------------------------------
CREATE INDEX idx_employee_salary_desc ON Employee(salary DESC);

EXPLAIN
SELECT * FROM Employee ORDER BY salary DESC LIMIT 10;
-- Nếu không có index, Extra hiển thị "Using filesort"
-- Sau khi tạo index, Extra biến mất

-- ============================================================
-- PHẦN 3: Anti-patterns — viết query chậm
-- ============================================================

-- ------------------------------------------------------------
-- P9. TRÁNH: hàm trên cột trong WHERE → mất index
-- ------------------------------------------------------------
-- ❌ Chậm (không dùng được index trên joining_date)
SELECT * FROM Employee WHERE YEAR(joining_date) = 2017;

-- ✅ Nhanh (dùng được index)
SELECT * FROM Employee
WHERE joining_date >= '2017-01-01'
  AND joining_date <  '2018-01-01';

-- ------------------------------------------------------------
-- P10. TRÁNH: SELECT * khi chỉ cần vài cột
-- ------------------------------------------------------------
-- ❌ Chậm (đọc toàn bộ cột)
SELECT * FROM Employee WHERE department = 'Admin';

-- ✅ Nhanh hơn (chỉ đọc cột cần)
SELECT employee_id, first_name, last_name
FROM Employee
WHERE department = 'Admin';

-- ------------------------------------------------------------
-- P11. TRÁNH: NOT IN với subquery lớn
-- ------------------------------------------------------------
-- ❌ Chậm
SELECT * FROM Employee
WHERE employee_id NOT IN (SELECT employee_ref_id FROM Bonus);

-- ✅ Nhanh hơn với LEFT JOIN ... IS NULL
SELECT e.*
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
WHERE b.employee_ref_id IS NULL;

-- ------------------------------------------------------------
-- P12. TRÁNH: OR trên nhiều cột không index
-- ------------------------------------------------------------
-- ❌ Chậm
SELECT * FROM Employee
WHERE department = 'Admin' OR salary > 400000;

-- ✅ Nhanh hơn với UNION (nếu cả 2 đều có index)
SELECT * FROM Employee WHERE department = 'Admin'
UNION
SELECT * FROM Employee WHERE salary > 400000;

-- ------------------------------------------------------------
-- P13. LIMIT + OFFSET lớn — phân trang kém hiệu quả
-- ------------------------------------------------------------
-- ❌ Chậm khi OFFSET lớn (vẫn phải scan OFFSET dòng)
SELECT * FROM Employee ORDER BY employee_id LIMIT 10 OFFSET 1000000;

-- ✅ Keyset pagination — dùng giá trị cuối cùng
SELECT * FROM Employee
WHERE employee_id > 1000000
ORDER BY employee_id
LIMIT 10;

-- ------------------------------------------------------------
-- P14. Xóa index khi không cần
-- ------------------------------------------------------------
-- SHOW INDEX FROM Employee;
-- DROP INDEX idx_employee_department ON Employee;
