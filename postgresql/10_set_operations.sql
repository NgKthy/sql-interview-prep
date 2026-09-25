-- ============================================================
-- 10_set_operations.sql  (PostgreSQL port)
-- Chủ đề: UNION / INTERSECT / EXCEPT
-- Nguồn: S1-S4
-- Khác biệt vs MySQL:
--   - INTERSECT và EXCEPT có trong PostgreSQL từ phiên bản đầu
--     (MySQL chỉ hỗ trợ từ 8.0.31)
--   - PostgreSQL hỗ trợ EXCEPT ALL và INTERSECT ALL (MySQL chưa có)
--   - Không cần 'Có bonus' mà có thể dùng ký tự Unicode bình thường
-- ============================================================

-- ============================================================
-- S1. UNION — gộp kết quả từ 2 bảng, loại trùng
-- ------------------------------------------------------------
-- PostgreSQL note: UNION cú pháp giống MySQL.
-- Độ phức tạp: O(n log n).
-- ============================================================
SELECT department AS dept FROM Employee
UNION
SELECT 'Co bonus' FROM Bonus;

-- ============================================================
-- S2. INTERSECT — giao của 2 tập
-- ------------------------------------------------------------
-- PostgreSQL note: INTERSECT đã có từ rất lâu trong PG (MySQL chỉ từ 8.0.31).
-- PG còn hỗ trợ INTERSECT ALL (giữ duplicate) — MySQL chưa có.
-- Độ phức tạp: O(n log n + m log m).
-- ============================================================
SELECT employee_ref_id FROM Bonus
INTERSECT
SELECT employee_ref_id FROM Title WHERE employee_title = 'Manager';

-- ============================================================
-- S3. EXCEPT — hiệu của 2 tập (A trừ B)
-- ------------------------------------------------------------
-- PostgreSQL note:
--   - EXCEPT thay cho MINUS (Oracle) và là tên chuẩn SQL.
--   - PG hỗ trợ EXCEPT ALL — giữ duplicate trong hiệu.
-- Độ phức tạp: O(n log n + m log m).
-- ============================================================
SELECT employee_ref_id FROM Title
EXCEPT
SELECT employee_ref_id FROM Bonus;

-- Bonus: EXCEPT ALL — giữ duplicate (PG only, MySQL chưa hỗ trợ)
-- SELECT employee_ref_id FROM Title
-- EXCEPT ALL
-- SELECT employee_ref_id FROM Bonus;

-- ============================================================
-- S4. UNION ALL — gộp tất cả, GIỮ trùng lặp
-- ------------------------------------------------------------
-- PostgreSQL note: UNION ALL cú pháp giống MySQL — O(n + m).
-- ============================================================
SELECT user_1 AS user_id FROM user_interaction
UNION ALL
SELECT user_2 AS user_id FROM user_interaction;
