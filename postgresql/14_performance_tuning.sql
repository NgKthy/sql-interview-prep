-- ============================================================
-- 14_performance_tuning.sql  (PostgreSQL port)
-- Chủ đề: Index, EXPLAIN ANALYZE, query optimization trong PostgreSQL
-- Nguồn: Use The Index, Luke + PostgreSQL Documentation
-- Khác biệt vs MySQL:
--   - EXPLAIN trong PG: EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
--   - PG hiển thị Execution Time, Planning Time, Cost, Loop, Buffers hit/read
--   - PostgreSQL hỗ trợ Partial Index, Expression Index
-- ============================================================

-- ============================================================
-- PHẦN 1: EXPLAIN — đọc execution plan trong PostgreSQL
-- ============================================================

-- ------------------------------------------------------------
-- P1. EXPLAIN cơ bản (chỉ ước tính cost, không thực thi)
-- ------------------------------------------------------------
EXPLAIN
SELECT * FROM employee WHERE department = 'Admin';

-- Các thông số cần chú ý trong PG:
--   Seq Scan (Full table scan, tương tự type: ALL trong MySQL)
--   Index Scan / Index Only Scan / Bitmap Index Scan (dùng index)
--   cost=0.00..18.25 (cost ước tính: start..total)
--   rows=N, width=M

-- ------------------------------------------------------------
-- P2. EXPLAIN ANALYZE — thực thi thật + đo thời gian thực tế
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT department, COUNT(*)
FROM employee
GROUP BY department;

-- Buffers: Shared Hit (đọc từ RAM cache), Read (đọc từ đĩa)

-- ------------------------------------------------------------
-- P3. EXPLAIN FORMAT JSON
-- ------------------------------------------------------------
EXPLAIN (FORMAT JSON)
SELECT e.first_name, b.bonus_amount
FROM employee e
JOIN bonus b ON e.employee_id = b.employee_ref_id
WHERE e.department = 'Admin';

-- ============================================================
-- PHẦN 2: INDEX — Tạo và tối ưu trên PostgreSQL
-- ============================================================

-- ------------------------------------------------------------
-- P4. Tạo index đơn (B-tree mặc định)
-- ------------------------------------------------------------
CREATE INDEX idx_employee_department ON employee(department);

-- Sau khi tạo index, PG sẽ chuyển từ Seq Scan sang Index Scan / Bitmap Heap Scan.

-- ------------------------------------------------------------
-- P5. Composite index (Index nhiều cột)
-- ------------------------------------------------------------
CREATE INDEX idx_employee_dept_salary ON employee(department, salary);

-- ------------------------------------------------------------
-- P6. Covering Index (Index Only Scan với INCLUDE - PG 11+)
-- ------------------------------------------------------------
CREATE INDEX idx_employee_covering
    ON employee(department) INCLUDE (employee_id, first_name, last_name);

EXPLAIN
SELECT employee_id, first_name, last_name
FROM employee
WHERE department = 'Admin';
-- PG sẽ sử dụng "Index Only Scan" mà không cần đọc Heap Table.

-- ------------------------------------------------------------
-- P7. Partial Index (Index có điều kiện - Đặc trưng PostgreSQL)
-- ------------------------------------------------------------
-- Chỉ index những nhân viên lương cao > 300,000 để tiết kiệm dung lượng index
CREATE INDEX idx_employee_high_salary ON employee(salary) WHERE salary > 300000;

-- ------------------------------------------------------------
-- P8. Expression Index (Index trên biểu thức - Đặc trưng PostgreSQL)
-- ------------------------------------------------------------
-- Giúp tìm kiếm không phân biệt hoa thường nhanh chóng
CREATE INDEX idx_employee_lower_fname ON employee(LOWER(first_name));

EXPLAIN
SELECT * FROM employee WHERE LOWER(first_name) = 'an';

-- ============================================================
-- PHẦN 3: Anti-patterns & Query Optimization
-- ============================================================

-- ------------------------------------------------------------
-- P9. TRÁNH: dùng hàm trên cột trong WHERE
-- ------------------------------------------------------------
-- Chậm trong PG (mất index scan trừ khi có Expression Index)
SELECT * FROM employee WHERE EXTRACT(YEAR FROM joining_date) = 2017;

-- Nhanh (dùng B-Tree Index chuẩn)
SELECT * FROM employee
WHERE joining_date >= '2017-01-01'
  AND joining_date <  '2018-01-01';

-- ------------------------------------------------------------
-- P10. TRÁNH: NOT IN với NULL
-- ------------------------------------------------------------
-- Trong PG, NOT IN (subquery) trả về 0 dòng nếu subquery chứa NULL
SELECT * FROM employee
WHERE employee_id NOT IN (SELECT employee_ref_id FROM bonus);

-- Dùng EXCEPT hoặc NOT EXISTS / LEFT JOIN
SELECT * FROM employee
EXCEPT
SELECT e.* FROM employee e JOIN bonus b ON e.employee_id = b.employee_ref_id;

-- ------------------------------------------------------------
-- P11. Keyset Pagination (Thay thế OFFSET lớn)
-- ------------------------------------------------------------
SELECT * FROM employee
WHERE employee_id > 1000
ORDER BY employee_id
LIMIT 10;
