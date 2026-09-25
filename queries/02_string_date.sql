-- ============================================================
-- 02_string_date.sql
-- Chủ đề: Xử lý chuỗi và ngày tháng
-- Hệ CSDL: MySQL 8.0+
-- Nguồn: Q5, Q9, Q10, Q11, Q13, Q35, Q46
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- Q5. Lấy first name từ cột full_names
-- ------------------------------------------------------------
-- Ý tưởng:
--   full_names = "FirstName LastName". Tách chuỗi tại dấu cách đầu tiên
--   để lấy phần trước (first name).
--
-- Cách 1: SUBSTRING_INDEX(str, delim, count)
--   - Ưu: Hàm MySQL built-in, ngắn gọn.
--   - Nhược: Không có trong SQL chuẩn / PostgreSQL (dùng SPLIT_PART).
--   - Dùng khi: MySQL — lấy phần trước dấu phân cách.
--
-- Cách thay thế PostgreSQL: SPLIT_PART(full_names, ' ', 1)
--
-- Độ phức tạp: O(n) — scan từng chuỗi.
-- ============================================================
SELECT DISTINCT SUBSTRING_INDEX(full_names, ' ', 1) AS first_name
FROM user_name;

-- ============================================================
-- Q9. In first_name bằng chữ HOA
-- ------------------------------------------------------------
-- Ý tưởng:
--   Hàm UPPER() chuyển toàn bộ ký tự trong chuỗi sang uppercase.
--   Bài toán kiểm tra kiến thức string functions cơ bản.
--
-- Cách 1: UPPER(col)
--   - Ưu: Chuẩn SQL ANSI, tất cả CSDL đều có.
--   - Nhược: Không thay đổi dữ liệu gốc, chỉ hiển thị.
--   - Dùng khi: Chuẩn hóa hiển thị, hoặc so sánh case-insensitive.
--
-- Độ phức tạp: O(n) — áp dụng hàm từng ký tự.
-- ============================================================
SELECT UPPER(first_name) AS first_name_upper
FROM Employee;

-- ============================================================
-- Q10. Ghép first_name và last_name
-- ------------------------------------------------------------
-- Ý tưởng:
--   Dùng CONCAT() để nối chuỗi, thêm khoảng trắng giữa hai tên.
--
-- Cách 1: CONCAT(col1, ' ', col2)
--   - Ưu: Chuẩn, rõ ràng; CONCAT trả về NULL nếu bất kỳ argument nào là NULL.
--   - Nhược: Nếu first_name hoặc last_name là NULL thì kết quả NULL.
--   - Dùng khi: Kết hợp nhiều cột text thành một cột hiển thị.
--
-- Cách xử lý NULL: CONCAT(COALESCE(first_name,''), ' ', COALESCE(last_name,''))
--
-- Độ phức tạp: O(n) — tạo chuỗi mới từng dòng.
-- ============================================================
SELECT CONCAT(first_name, ' ', last_name) AS full_name
FROM Employee;

-- ============================================================
-- Q11. Nhân viên tên 'Jennifer' hoặc 'James'
-- ------------------------------------------------------------
-- Ý tưởng:
--   Lọc theo danh sách giá trị bằng IN() — tương đương OR nhưng gọn hơn.
--
-- Cách 1: WHERE col IN (val1, val2)
--   - Ưu: Ngắn gọn hơn nhiều OR; dễ mở rộng thêm giá trị.
--   - Nhược: Danh sách quá dài (>1000 giá trị) có thể chậm; dùng JOIN với bảng.
--   - Dùng khi: Lọc theo tập giá trị rời rạc nhỏ hoặc vừa.
--
-- Cách thay thế: WHERE first_name = 'Jennifer' OR first_name = 'James'
--
-- Độ phức tạp: O(n) — full scan hoặc O(log n) nếu có index trên first_name.
-- ============================================================
SELECT *
FROM Employee
WHERE first_name IN ('Jennifer', 'James');

-- ============================================================
-- Q13. Nhân viên gia nhập tháng 1/2017
-- ------------------------------------------------------------
-- Ý tưởng:
--   Lọc theo điều kiện ngày tháng: YEAR = 2017 AND MONTH = 1.
--   LƯU Ý: Dùng YEAR()/MONTH() trực tiếp trên cột sẽ phá index.
--   Thay bằng RANGE condition để giữ index.
--
-- Cách 1: YEAR() + MONTH() (đơn giản, dễ đọc)
--   - Ưu: Rõ ràng ý định lọc theo tháng.
--   - Nhược: Hàm trên cột phá index trên joining_date → full scan.
--   - Dùng khi: Bảng nhỏ, không cần tối ưu index.
--
-- Cách 2 (khuyên dùng): WHERE joining_date >= '2017-01-01' AND joining_date < '2017-02-01'
--   - Ưu: Dùng được range scan trên index.
--   - Nhược: Cú pháp dài hơn.
--   - Dùng khi: Bảng lớn, có index trên joining_date.
--
-- Độ phức tạp: O(n) Cách 1, O(log n + k) Cách 2 với index.
-- ============================================================
SELECT first_name, last_name, joining_date
FROM Employee
WHERE YEAR(joining_date) = 2017
  AND MONTH(joining_date) = 1;

-- ============================================================
-- Q35. Distinct first name từ full name
-- ------------------------------------------------------------
-- Ý tưởng:
--   Giống Q5 — tách first name từ full_names, lấy DISTINCT để loại trùng.
--   DISTINCT quan trọng khi nhiều user có cùng first name.
--
-- Cách 1: DISTINCT + SUBSTRING_INDEX
--   - Ưu: Kết hợp 2 thao tác trong 1 query.
--   - Nhược: Không portable (MySQL only).
--   - Dùng khi: Muốn danh sách tên phân biệt.
--
-- Độ phức tạp: O(n log n) — DISTINCT cần sort hoặc hash.
-- ============================================================
SELECT DISTINCT SUBSTRING_INDEX(full_names, ' ', 1) AS first_name
FROM user_name;

-- ============================================================
-- Q46. User đăng nhập trong 30 ngày gần nhất
-- ------------------------------------------------------------
-- Ý tưởng:
--   JOIN user với lịch sử đăng nhập, lọc theo thời gian 30 ngày gần nhất,
--   nhóm theo user để lấy lần login cuối cùng.
--
-- Cách 1: JOIN + WHERE date_range + GROUP BY
--   - Ưu: Trả về thông tin user kèm lần login cuối.
--   - Nhược: Phụ thuộc bảng user và userhistory (không có trong schema gốc).
--   - Dùng khi: Báo cáo active users theo khoảng thời gian.
--
-- Lưu ý DATE_SUB vs PostgreSQL:
--   MySQL:      DATE_SUB(CURDATE(), INTERVAL 30 DAY)
--   PostgreSQL: CURRENT_DATE - INTERVAL '30 days'
--
-- Độ phức tạp: O(n log n) — JOIN + GROUP BY.
-- ============================================================
SELECT u.name, u.phone_num, MAX(uh.date) AS last_login
FROM user u
JOIN userhistory uh ON u.user_id = uh.user_id
WHERE uh.action = 'logged_on'
  AND uh.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY u.user_id, u.name, u.phone_num;
