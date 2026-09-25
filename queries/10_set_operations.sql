-- ============================================================
-- 10_set_operations.sql
-- Chủ đề: UNION / INTERSECT / EXCEPT (MỚI)
-- Hệ CSDL: MySQL 8.0.31+
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- S1. UNION — gộp kết quả từ 2 bảng, loại trùng
-- ------------------------------------------------------------
-- Ý tưởng:
--   UNION = hợp 2 tập, tự động loại bỏ dòng trùng lặp.
--   Ở đây: hiển thị tất cả phòng ban + nhãn 'Có bonus' (demo cú pháp).
--
-- Quy tắc UNION:
--   - Số cột phải bằng nhau giữa 2 SELECT.
--   - Kiểu dữ liệu phải tương thích.
--   - Tên cột lấy từ SELECT đầu tiên.
--
-- Cách 1: UNION (loại trùng)
--   - Ưu: Tự động deduplicate; phổ biến để merge danh sách.
--   - Nhược: Tốn thêm bước sort/hash để loại trùng; chậm hơn UNION ALL.
--   - Dùng khi: Gộp 2 tập có thể chứa dòng giống nhau.
--
-- UNION vs UNION ALL:
--   UNION:     loại bỏ duplicate → O(n log n)
--   UNION ALL: giữ tất cả       → O(n) — nhanh hơn, dùng khi chắc không trùng.
--
-- Độ phức tạp: O(n log n) — sort để loại trùng.
-- ============================================================
SELECT department AS dept FROM Employee
UNION
SELECT 'Có bonus' FROM Bonus;

-- ============================================================
-- S2. INTERSECT — giao của 2 tập
-- ------------------------------------------------------------
-- Ý tưởng:
--   INTERSECT trả về các giá trị xuất hiện trong CẢ HAI tập.
--   Tìm employee_ref_id có cả trong Bonus VÀ có title Manager.
--
-- Cách 1: INTERSECT (MySQL 8.0.31+)
--   - Ưu: Cú pháp rõ ràng, thể hiện đúng "phép giao" logic.
--   - Nhược: MySQL 8.0.31+ mới hỗ trợ; trước đó dùng INNER JOIN hoặc IN.
--   - Dùng khi: Tìm phần tử chung giữa 2 danh sách.
--
-- Cách thay thế (MySQL cũ): 
--   SELECT employee_ref_id FROM Bonus
--   WHERE employee_ref_id IN (SELECT employee_ref_id FROM Title WHERE employee_title='Manager')
--
-- Độ phức tạp: O(n log n + m log m) — sort 2 tập rồi merge.
-- ============================================================
SELECT employee_ref_id FROM Bonus
INTERSECT
SELECT employee_ref_id FROM Title WHERE employee_title = 'Manager';

-- ============================================================
-- S3. EXCEPT — hiệu của 2 tập (A trừ B)
-- ------------------------------------------------------------
-- Ý tưởng:
--   EXCEPT trả về các giá trị có trong tập A nhưng KHÔNG có trong tập B.
--   Tìm nhân viên có title nhưng không có bonus — "bị bỏ quên" khi phát thưởng.
--
-- Cách 1: EXCEPT (MySQL 8.0.31+)
--   - Ưu: Cú pháp tường minh cho phép "A - B".
--   - Nhược: MySQL 8.0.31+; cũ hơn dùng NOT IN hoặc LEFT JOIN IS NULL.
--   - Dùng khi: Tìm phần tử trong A nhưng không có trong B — anti-join qua set op.
--
-- Cách thay thế an toàn hơn (xử lý NULL): LEFT JOIN + IS NULL
--   SELECT t.employee_ref_id FROM Title t
--   LEFT JOIN Bonus b ON t.employee_ref_id = b.employee_ref_id
--   WHERE b.employee_ref_id IS NULL AND t.employee_title = ... -- nếu cần
--
-- Lưu ý: EXCEPT loại trùng (tương đương EXCEPT DISTINCT).
--   EXCEPT ALL (nếu có) giữ duplicates — MySQL chưa hỗ trợ.
--
-- Độ phức tạp: O(n log n + m log m) — sort 2 tập rồi so sánh.
-- ============================================================
SELECT employee_ref_id FROM Title
EXCEPT
SELECT employee_ref_id FROM Bonus;

-- ============================================================
-- S4. UNION ALL — gộp tất cả, GIỮ trùng lặp
-- ------------------------------------------------------------
-- Ý tưởng:
--   UNION ALL = multiset union, không loại bỏ duplicate.
--   Dùng để gộp user_1 và user_2 thành 1 danh sách duy nhất.
--   Giữ nguyên duplicate vì mỗi lần xuất hiện là 1 interaction riêng biệt.
--
-- Cách 1: UNION ALL
--   - Ưu: O(n) — không cần sort/hash để loại trùng; nhanh hơn UNION.
--   - Nhược: Có duplicate — đúng với bài toán này nhưng không phù hợp khi cần unique.
--   - Dùng khi: Gộp dữ liệu từ nhiều nguồn, cần giữ mọi occurrence.
--
-- Dùng sau với GROUP BY để đếm interaction mỗi user:
--   SELECT user_id, COUNT(*) FROM (...UNION ALL...) GROUP BY user_id
--
-- Độ phức tạp: O(n + m) — concatenate 2 tập, không sort.
-- ============================================================
SELECT user_1 AS user_id FROM user_interaction
UNION ALL
SELECT user_2 AS user_id FROM user_interaction;
