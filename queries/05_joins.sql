-- ============================================================
-- 05_joins.sql
-- Chủ đề: JOIN nhiều bảng
-- Nguồn: Q12, Q23, Q24, Q43, Q45
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- Q12. Nhân viên lương trong khoảng 100k - 500k
-- ------------------------------------------------------------
-- Ý tưởng:
--   Lọc theo khoảng giá trị liên tục bằng BETWEEN (bao gồm 2 đầu mút).
--
-- Cách 1: WHERE salary BETWEEN a AND b
--   - Ưu: Ngắn gọn, dễ đọc; BETWEEN tương đương >= AND <=.
--   - Nhược: BETWEEN bao gồm cả 2 đầu mút — cần chú ý khi điều kiện cần loại trừ.
--   - Dùng khi: Lọc theo khoảng số hoặc ngày tháng.
--
-- Cách thay thế: WHERE salary >= 100000 AND salary <= 500000 (tường minh hơn)
--
-- Độ phức tạp: O(log n + k) với index trên salary (range scan), k là số kết quả.
-- ============================================================
SELECT first_name, last_name, salary
FROM Employee
WHERE salary BETWEEN 100000 AND 500000;

-- ============================================================
-- Q23. Recommend pages dựa trên pages mà bạn bè đã like
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tìm page mà bạn bè của user=1 đã like nhưng user=1 chưa like.
--   Đây là bài toán recommendation engine cơ bản.
--   Bước 1: Tìm bạn bè của user 1.
--   Bước 2: Tìm page bạn bè đã like.
--   Bước 3: Loại bỏ page user 1 đã like.
--
-- Cách 1: JOIN friendships + page_likes + NOT IN subquery
--   - Ưu: Logic rõ từng bước; dễ đọc.
--   - Nhược: NOT IN subquery; nếu user_id NULL thì NOT IN trả về rỗng.
--   - Dùng khi: Graph-based recommendation đơn giản.
--
-- Cách thay thế: LEFT JOIN + IS NULL thay cho NOT IN để an toàn hơn với NULL.
--
-- Độ phức tạp: O(F * P) — F: số friendship, P: số page_likes; tối ưu với index.
-- ============================================================
SELECT DISTINCT pl.page_id
FROM page_likes pl
JOIN friendships f
  ON pl.user_id = f.friend_id
WHERE f.user_id = 1   -- user cần recommend
  AND pl.page_id NOT IN (
      SELECT page_id FROM page_likes WHERE user_id = 1
  );

-- ============================================================
-- Q24. Nhân viên có bonus cao nhất (kèm department)
-- ------------------------------------------------------------
-- Ý tưởng:
--   JOIN Employee và Bonus, sắp xếp theo bonus giảm dần, lấy 1 bản ghi đầu.
--   LƯU Ý: Query gốc GROUP BY department + SELECT first_name là SAI logic —
--   không nên GROUP BY department khi chỉ muốn 1 người có bonus cao nhất toàn công ty.
--
-- Cách 1: JOIN + ORDER BY bonus DESC + LIMIT 1
--   - Ưu: Đơn giản, đúng ngữ nghĩa "người có bonus cao nhất".
--   - Nhược: Nếu 2 người có cùng bonus cao nhất, chỉ trả về 1 (random tie-breaking).
--   - Dùng khi: Cần top-1 absolute trong toàn bảng.
--
-- Cách xử lý tie: Dùng WHERE bonus_amount = (SELECT MAX(bonus_amount) FROM Bonus).
--
-- Độ phức tạp: O(n log n) — JOIN + sort; O(n) với index trên bonus_amount.
-- ============================================================
SELECT e.first_name, e.last_name, e.department, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id
ORDER BY b.bonus_amount DESC
LIMIT 1;

-- ============================================================
-- Q43. Salesperson có order với Samsonic
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tìm salesperson đã bán hàng cho khách Samsonic qua bảng orders.
--   Đây là bài JOIN 3 bảng: salesperson → orders → customer.
--
-- Cách 1: INNER JOIN 3 bảng + WHERE filter
--   - Ưu: INNER JOIN loại bỏ tự nhiên các salesperson không có order Samsonic.
--   - Nhược: Có thể trùng nếu 1 salesperson có nhiều order với Samsonic → cần DISTINCT.
--   - Dùng khi: Tìm entity có liên kết qua bảng trung gian.
--
-- Độ phức tạp: O(n*m) — 3 bảng JOIN; tối ưu với index trên FK.
-- ============================================================
SELECT DISTINCT s.name
FROM salesperson s
JOIN orders o       ON s.id = o.salesperson_id
JOIN customer c     ON o.cust_id = c.id
WHERE c.name = 'Samsonic';

-- ============================================================
-- Q45. Salesperson có từ 2 order trở lên
-- ------------------------------------------------------------
-- Ý tưởng:
--   Đếm số order của từng salesperson, lọc những người có ít nhất 2 order.
--   Dùng HAVING để lọc sau khi GROUP BY (WHERE chỉ lọc trước GROUP BY).
--
-- Cách 1: JOIN + GROUP BY + HAVING COUNT >= 2
--   - Ưu: Chuẩn SQL; HAVING là cách duy nhất lọc điều kiện trên aggregate.
--   - Nhược: Cần phân biệt rõ WHERE (lọc dòng) vs HAVING (lọc nhóm).
--   - Dùng khi: Lọc nhóm dựa trên hàm tổng hợp (COUNT, SUM, AVG...).
--
-- Lưu ý phỏng vấn: HAVING COUNT(*) vs HAVING COUNT(col) —
--   COUNT(*) đếm tất cả dòng, COUNT(col) bỏ qua NULL.
--
-- Độ phức tạp: O(n log n) — JOIN + GROUP BY sort/hash.
-- ============================================================
SELECT s.name AS salesperson, COUNT(o.number) AS num_orders
FROM salesperson s
JOIN orders o ON s.id = o.salesperson_id
GROUP BY s.id, s.name
HAVING COUNT(o.number) >= 2;
