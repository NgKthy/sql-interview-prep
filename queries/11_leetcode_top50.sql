-- ============================================================
-- 11_leetcode_top50.sql
-- LeetCode SQL 50 — Lời giải tham khảo (MySQL)
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- 1757. Recyclable and Low Fat Products
-- ------------------------------------------------------------
-- Ý tưởng: Lọc sản phẩm thỏa cả 2 điều kiện boolean.
--   - Hai điều kiện AND: cả hai cột đều phải là 'Y'.
--   - Đây là bài nhập môn — kiểm tra hiểu WHERE compound condition.
-- Độ phức tạp: O(n).
-- ============================================================
SELECT product_id
FROM Products
WHERE low_fats = 'Y' AND recyclable = 'Y';

-- ============================================================
-- 584. Find Customer Referee
-- ------------------------------------------------------------
-- Ý tưởng: Tìm customer không được giới thiệu bởi người có id=2.
--   Cạm bẫy: referee_id IS NULL → phải dùng OR IS NULL vì
--   NULL <> 2 không trả về TRUE mà là UNKNOWN trong SQL.
--   WHERE referee_id <> 2 sẽ BỎ SÓT dòng có referee_id = NULL!
--
-- Cách 1: WHERE col <> val OR col IS NULL
--   - Ưu: Xử lý đúng NULL.
--   - Dùng khi: So sánh cột nullable với giá trị cụ thể.
-- Độ phức tạp: O(n).
-- ============================================================
SELECT name
FROM Customer
WHERE referee_id IS NULL OR referee_id <> 2;

-- ============================================================
-- 595. Big Countries
-- ------------------------------------------------------------
-- Ý tưởng: Tìm quốc gia "lớn" theo 1 trong 2 tiêu chí.
--   OR: ít nhất 1 điều kiện đúng → nước lớn theo diện tích HOẶC dân số.
--   Phân biệt rõ OR vs AND trong bài toán lọc đa điều kiện.
-- Độ phức tạp: O(n).
-- ============================================================
SELECT name, population, area
FROM World
WHERE area >= 3000000 OR population >= 25000000;

-- ============================================================
-- 1148. Article Views I
-- ------------------------------------------------------------
-- Ý tưởng: Tìm tác giả đã xem bài viết của CHÍNH HỌ.
--   author_id = viewer_id → người xem chính là người viết.
--   DISTINCT vì 1 tác giả có thể tự xem nhiều bài.
-- Độ phức tạp: O(n log n) — DISTINCT + ORDER BY.
-- ============================================================
SELECT DISTINCT author_id AS id
FROM Views
WHERE author_id = viewer_id
ORDER BY id;

-- ============================================================
-- 1683. Invalid Tweets
-- ------------------------------------------------------------
-- Ý tưởng: Tweet hợp lệ có <= 15 ký tự; invalid = > 15 ký tự.
--   CHAR_LENGTH() đếm số ký tự (multi-byte safe) thay LENGTH() đếm bytes.
--   Quan trọng với dữ liệu Unicode (emoji, tiếng Nhật...).
-- Độ phức tạp: O(n).
-- ============================================================
SELECT tweet_id
FROM Tweets
WHERE CHAR_LENGTH(content) > 15;

-- ============================================================
-- 1378. Replace Employee ID With The Unique Identifier
-- ------------------------------------------------------------
-- Ý tưởng: LEFT JOIN để giữ tất cả nhân viên dù không có unique_id.
--   Nhân viên không có mapping → unique_id = NULL (giữ nguyên trong output).
--   Bài này kiểm tra LEFT JOIN vs INNER JOIN.
--
-- Cách 1: LEFT JOIN (giữ tất cả employee)
--   - Ưu: Không mất dữ liệu nhân viên dù không có unique ID.
--   - INNER JOIN sẽ loại bỏ nhân viên không có mapping → sai.
-- Độ phức tạp: O(n log m) — JOIN với index trên id.
-- ============================================================
SELECT u.unique_id, e.name
FROM Employees e
LEFT JOIN EmployeeUNI u ON e.id = u.id;

-- ============================================================
-- 1068. Product Sales Analysis I
-- ------------------------------------------------------------
-- Ý tưởng: INNER JOIN Sales và Product để lấy product_name.
--   Mỗi sale record có product_id → JOIN để lấy tên sản phẩm.
--   INNER JOIN đủ vì mọi sale đều có sản phẩm tương ứng.
-- Độ phức tạp: O(n log m) — JOIN với index trên product_id.
-- ============================================================
SELECT p.product_name, s.year, s.price
FROM Sales s
JOIN Product p ON s.product_id = p.product_id;

-- ============================================================
-- 1581. Customer Who Visited but Did Not Make Any Transactions
-- ------------------------------------------------------------
-- Ý tưởng: Tìm visit không có transaction nào → anti-join pattern.
--   LEFT JOIN Visits → Transactions; dòng không match → transaction_id = NULL.
--   COUNT(*) đếm số lần visit không mua → chỉ tiêu hành vi quan trọng.
--
-- Cách 1: LEFT JOIN + WHERE IS NULL + GROUP BY + COUNT
--   - Ưu: Anti-join chuẩn; COUNT đếm số lần browse-without-buy.
--   - Nhược: Nếu customer có cả visit có và không có transaction → vẫn đếm đúng.
-- Độ phức tạp: O(n log m) — LEFT JOIN + GROUP BY.
-- ============================================================
SELECT v.customer_id, COUNT(*) AS count_no_trans
FROM Visits v
LEFT JOIN Transactions t ON v.visit_id = t.visit_id
WHERE t.transaction_id IS NULL
GROUP BY v.customer_id;

-- ============================================================
-- 197. Rising Temperature
-- ------------------------------------------------------------
-- Ý tưởng: Tìm ngày có nhiệt độ cao hơn ngày hôm trước.
--   Self-join Weather với điều kiện DATEDIFF = 1 (w1 sau w2 đúng 1 ngày).
--   WHERE w1.temp > w2.temp lọc ngày tăng nhiệt.
--
-- Cách 1: Self JOIN + DATEDIFF
--   - Ưu: Rõ logic so sánh 2 ngày liên tiếp.
--   - Nhược: DATEDIFF trên toàn bảng → tạo Cartesian product rồi lọc.
--     Cách tốt hơn: LAG(temperature) OVER (ORDER BY recordDate).
--
-- Cách 2 (hiệu quả hơn): Window function LAG
--   SELECT id FROM (SELECT id, temperature,
--     LAG(temperature) OVER (ORDER BY recordDate) AS prev_temp,
--     LAG(recordDate)  OVER (ORDER BY recordDate) AS prev_date
--   FROM Weather) t
--   WHERE temperature > prev_temp AND DATEDIFF(recordDate, prev_date) = 1;
-- Độ phức tạp: O(n²) Cách 1, O(n log n) Cách 2.
-- ============================================================
SELECT w1.id
FROM Weather w1
JOIN Weather w2
  ON DATEDIFF(w1.recordDate, w2.recordDate) = 1
WHERE w1.temperature > w2.temperature;

-- ============================================================
-- 1661. Average Time of Process per Machine
-- ------------------------------------------------------------
-- Ý tưởng:
--   Mỗi process có 2 dòng: 'start' và 'end'.
--   Bước 1: Pivot để lấy start_time và end_time cùng dòng (GROUP BY machine, process).
--   Bước 2: Tính AVG(end - start) cho từng machine.
--
-- Cách 1: Subquery pivot bằng CASE + GROUP BY
--   - Ưu: Chuẩn SQL; hoạt động mà không cần PIVOT syntax.
--   - Nhược: Phải biết trước các giá trị của activity_type.
-- Độ phức tạp: O(n log n) — GROUP BY 2 cấp.
-- ============================================================
SELECT
    machine_id,
    ROUND(AVG(end_time - start_time), 3) AS processing_time
FROM (
    SELECT machine_id, process_id,
           MAX(CASE WHEN activity_type = 'start' THEN timestamp END) AS start_time,
           MAX(CASE WHEN activity_type = 'end'   THEN timestamp END) AS end_time
    FROM Activity
    GROUP BY machine_id, process_id
) t
GROUP BY machine_id;

-- ============================================================
-- 577. Employee Bonus
-- ------------------------------------------------------------
-- Ý tưởng: Lấy nhân viên có bonus < 1000 HOẶC chưa có bonus (NULL).
--   LEFT JOIN vì không phải nhân viên nào cũng có bonus.
--   Cạm bẫy: WHERE b.bonus < 1000 bỏ sót nhân viên không có bonus (NULL).
--   Phải thêm OR b.bonus IS NULL để xử lý trường hợp không có bonus.
-- Độ phức tạp: O(n log m) — LEFT JOIN + filter.
-- ============================================================
SELECT e.name, b.bonus
FROM Employee e
LEFT JOIN Bonus b ON e.empId = b.empId
WHERE b.bonus < 1000 OR b.bonus IS NULL;

-- ============================================================
-- 1280. Students and Examinations
-- ------------------------------------------------------------
-- Ý tưởng:
--   Cần tạo CARTESIAN PRODUCT tất cả (student, subject) để không bỏ sót
--   môn có 0 kỳ thi. LEFT JOIN Examinations để đếm số kỳ thi thực tế.
--   COUNT(e.subject_name) tự bỏ qua NULL (không thi) → trả về 0 khi không có.
--
-- Cách 1: CROSS JOIN + LEFT JOIN + COUNT
--   - Ưu: CROSS JOIN tạo mọi tổ hợp (student, subject) → không bỏ sót.
--   - Nhược: Nếu nhiều student và subject → Cartesian product lớn.
-- Lưu ý: COUNT(*) sẽ trả về 1 thay vì 0 khi không thi — phải COUNT(col từ LEFT JOIN).
-- Độ phức tạp: O(S * Sub * E) — S: students, Sub: subjects, E: examinations.
-- ============================================================
SELECT
    s.student_id, s.student_name, sub.subject_name,
    COUNT(e.subject_name) AS attended_exams
FROM Students s
CROSS JOIN Subjects sub
LEFT JOIN Examinations e
  ON s.student_id = e.student_id
 AND sub.subject_name = e.subject_name
GROUP BY s.student_id, s.student_name, sub.subject_name
ORDER BY s.student_id, sub.subject_name;

-- ============================================================
-- 176. Second Highest Salary
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tìm mức lương cao thứ 2 (không trùng).
--   Dùng scalar subquery trong SELECT để trả về NULL thay vì 0 dòng
--   khi không tồn tại mức lương thứ 2.
--
-- Cách 1: Scalar subquery + LIMIT OFFSET
--   - Ưu: Trả về NULL (không phải 0 dòng) khi không có giá trị — yêu cầu của LeetCode.
--   - Nhược: Nếu dùng trực tiếp LIMIT sẽ trả về 0 dòng — SIGO yêu cầu 1 dòng NULL.
--
-- Lưu ý: Đây là cạm bẫy quan trọng: bao subquery trong SELECT để buộc trả về NULL.
-- Độ phức tạp: O(n log n) — sort để DISTINCT + OFFSET.
-- ============================================================
SELECT (
    SELECT DISTINCT salary
    FROM Employee
    ORDER BY salary DESC
    LIMIT 1 OFFSET 1
) AS SecondHighestSalary;
