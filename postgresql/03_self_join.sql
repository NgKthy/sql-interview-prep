-- ============================================================
-- 03_self_join.sql  (PostgreSQL port)
-- Chủ đề: Self join
-- Nguồn: Q6, Q14, Q25
-- Khác biệt vs MySQL: Không có USE; tên bảng lowercase theo convention PG.
-- ============================================================

-- ============================================================
-- Q6. Nhân viên đồng thời là quản lý
-- ------------------------------------------------------------
-- Ý tưởng:
--   Self-join: bảng Employee join với chính nó qua manager_id.
--   Một nhân viên là manager khi employee_id xuất hiện trong cột manager_id.
--
-- PostgreSQL note: Hoàn toàn giống MySQL — self-join là cú pháp SQL chuẩn.
-- Độ phức tạp: O(n²) không có index, O(n log n) với index trên manager_id.
-- ============================================================
SELECT e1.first_name, e1.last_name
FROM Employee e1
JOIN Employee e2 ON e1.employee_id = e2.manager_id;

-- ============================================================
-- Q14. Nhân viên có cùng mức lương
-- ------------------------------------------------------------
-- PostgreSQL note: Cú pháp giống MySQL. <> là chuẩn SQL, != cũng được PG chấp nhận.
-- Độ phức tạp: O(n²) — cross product rồi lọc.
-- ============================================================
SELECT e1.first_name, e1.last_name, e1.salary
FROM Employee e1
JOIN Employee e2
  ON e1.salary = e2.salary
 AND e1.employee_id <> e2.employee_id;

-- ============================================================
-- Q25. Nhân viên có cùng mức lương (DISTINCT + ORDER BY)
-- ------------------------------------------------------------
-- PostgreSQL note: Cú pháp giống MySQL.
-- Độ phức tạp: O(n²) + sort cho DISTINCT.
-- ============================================================
SELECT DISTINCT e1.first_name, e1.last_name, e1.salary
FROM Employee e1
JOIN Employee e2
  ON e1.salary = e2.salary
 AND e1.employee_id <> e2.employee_id
ORDER BY e1.salary DESC;
