-- ============================================================
-- 04_subquery.sql
-- Chủ đề: Subquery, IN / NOT IN / EXISTS
-- Nguồn: Q7, Q44, Q47
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- Q7. Nhân viên có bản ghi bonus
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tìm nhân viên mà employee_id của họ xuất hiện trong bảng Bonus.
--   Hai cách phổ biến: IN (subquery) và EXISTS (correlated subquery).
--
-- Cách 1: WHERE ... IN (subquery)
--   - Ưu: Đơn giản, dễ đọc.
--   - Nhược: Subquery IN chạy độc lập, không tương quan; nếu subquery
--     trả về NULL thì NOT IN có thể cho kết quả sai (không trả về dòng nào).
--   - Dùng khi: Bảng Bonus nhỏ; không có giá trị NULL trong employee_ref_id.
--
-- Cách 2: EXISTS (correlated subquery)
--   - Ưu: Dừng sớm khi tìm thấy match (short-circuit), thường nhanh hơn IN
--     với bảng lớn; xử lý NULL an toàn hơn.
--   - Nhược: Cú pháp phức tạp hơn một chút.
--   - Dùng khi: Bảng lớn, cần tối ưu hiệu suất; hoặc khi có thể có NULL.
--
-- Độ phức tạp: O(n*m) cả hai — n là Employee, m là Bonus; tối ưu với index.
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
-- Ý tưởng:
--   Tìm salesperson mà ID của họ KHÔNG xuất hiện trong danh sách
--   salesperson_id từ các order với khách Samsonic.
--   Đây là bài toán "anti-join" kinh điển.
--
-- Cách 1: NOT IN với JOIN subquery
--   - Ưu: Dễ đọc, logic rõ ràng.
--   - Nhược: NOT IN với NULL trong subquery sẽ trả về tập rỗng! (cạm bẫy phỏng vấn)
--     Nếu salesperson_id có thể NULL trong orders, phải dùng NOT EXISTS.
--   - Dùng khi: Chắc chắn không có NULL trong salesperson_id.
--
-- Cách thay thế an toàn hơn: LEFT JOIN ... WHERE o.salesperson_id IS NULL
--   - Ưu: Xử lý NULL chính xác, thường nhanh hơn NOT IN.
--
-- Độ phức tạp: O(n*m) — n salesperson, m orders; tối ưu với index trên salesperson_id.
-- ============================================================
SELECT s.name
FROM salesperson s
WHERE s.id NOT IN (
    SELECT o.salesperson_id
    FROM orders o
    JOIN customer c ON o.cust_id = c.id
    WHERE c.name = 'Samsonic'
);

-- ============================================================
-- Q47. user_id trong User nhưng KHÔNG có trong UserHistory
-- (không dùng MINUS/EXCEPT)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tìm user chưa có lịch sử hoạt động — bài toán "orphan record".
--   Không được dùng EXCEPT/MINUS (MySQL không hỗ trợ trước 8.0.31).
--
-- Cách 1: LEFT JOIN + WHERE IS NULL (anti-join pattern)
--   - Ưu: Hiệu suất tốt nhất; xử lý NULL chính xác; phổ biến nhất trong thực tế.
--   - Nhược: Cần hiểu LEFT JOIN để đọc đúng ý nghĩa.
--   - Dùng khi: Tìm "dòng trong A mà không có trong B" — cách chuẩn.
--
-- Cách thay thế: NOT EXISTS — tương đương, đôi khi nhanh hơn với optimizer.
-- Cách thay thế: NOT IN — nguy hiểm nếu subquery có NULL.
--
-- Độ phức tạp: O(n + m) với hash join; O(n log m) với nested loop + index.
-- ============================================================
SELECT u.user_id
FROM user u
LEFT JOIN userhistory uh ON u.user_id = uh.user_id
WHERE uh.user_id IS NULL;
