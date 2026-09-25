-- ============================================================
-- 01_basic.sql
-- Chủ đề: Truy vấn cơ bản, aggregate, sắp xếp
-- Hệ CSDL: MySQL 8.0+
-- Nguồn: Aafreen29/SQL-Interview-Prep-Question (Q1-Q4, Q15-Q22, Q34, Q48)
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- Q1. Tìm mức lương cao thứ n (ví dụ: cao thứ 3)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Loại bỏ trùng lặp salary, sắp xếp giảm dần, bỏ qua (n-1) bản đầu
--   rồi lấy bản ghi tiếp theo.
--
-- Cách 1: DISTINCT + LIMIT offset
--   - Ưu: Ngắn gọn, MySQL tối ưu tốt, viết nhanh.
--   - Nhược: Cú pháp LIMIT m,n khó đọc; không portable (SQL Server không có).
--   - Dùng khi: MySQL / PostgreSQL, cần viết nhanh.
--
-- Cách 2: Correlated subquery đếm
--   - Ưu: Portable sang mọi hệ CSDL (Oracle, SQL Server).
--   - Nhược: O(n²) nếu không có index trên salary; khó đọc.
--   - Dùng khi: Phỏng vấn cần giải thích logic tường minh, hoặc db không có LIMIT.
--
-- Độ phức tạp: O(n log n) Cách 1 (sort), O(n²) Cách 2.
-- ============================================================

-- Cách 1: DISTINCT + LIMIT (đơn giản, dễ hiểu)
SELECT DISTINCT salary
FROM Employee
ORDER BY salary DESC
LIMIT 2, 1;   -- bỏ qua 2 bản ghi, lấy 1

-- Cách 2: Subquery đếm số mức lương lớn hơn (portable hơn)
SELECT DISTINCT e1.salary
FROM Employee e1
WHERE 3 = (
    SELECT COUNT(DISTINCT e2.salary)
    FROM Employee e2
    WHERE e2.salary >= e1.salary
)
ORDER BY e1.salary DESC;

-- ============================================================
-- Q2. Lấy top n bản ghi (ví dụ: top 5 theo lương)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Sắp xếp bảng theo cột cần thiết, giới hạn số dòng trả về bằng LIMIT.
--
-- Cách 1: ORDER BY + LIMIT
--   - Ưu: Đơn giản, index trên salary giúp tránh full sort.
--   - Nhược: Nếu muốn top-n theo nhiều tiêu chí cần mở rộng ORDER BY.
--   - Dùng khi: Mọi trường hợp cần lấy "top n" nhanh.
--
-- Độ phức tạp: O(n log n) khi sort, O(n) nếu có index.
-- ============================================================
SELECT *
FROM Employee
ORDER BY salary DESC
LIMIT 5;

-- ============================================================
-- Q3. Đếm số nhân viên phòng 'Admin'
-- ------------------------------------------------------------
-- Ý tưởng:
--   Lọc theo điều kiện WHERE, dùng hàm tổng hợp COUNT(*).
--
-- Cách 1: WHERE + COUNT(*)
--   - Ưu: Đơn giản, hiệu quả; index trên department tăng tốc.
--   - Nhược: Chỉ đếm một phòng; nếu cần nhiều phòng dùng GROUP BY.
--   - Dùng khi: Cần đếm nhanh một nhóm cụ thể.
--
-- Độ phức tạp: O(n) hoặc O(log n) nếu có index trên department.
-- ============================================================
SELECT COUNT(*) AS admin_count
FROM Employee
WHERE department = 'Admin';

-- ============================================================
-- Q4. Đếm nhân viên theo phòng ban, sắp xếp giảm dần
-- ------------------------------------------------------------
-- Ý tưởng:
--   GROUP BY phân nhóm, COUNT(*) tổng hợp, ORDER BY sắp xếp kết quả.
--
-- Cách 1: GROUP BY + COUNT + ORDER BY
--   - Ưu: Rõ ràng, chuẩn SQL, phù hợp mọi hệ CSDL.
--   - Nhược: Không có gì, đây là cách duy nhất hợp lý.
--   - Dùng khi: Muốn thấy phân phối nhân viên theo từng phòng.
--
-- Độ phức tạp: O(n log n) — GROUP BY cần sort hoặc hash.
-- ============================================================
SELECT department, COUNT(*) AS employee_count
FROM Employee
GROUP BY department
ORDER BY employee_count DESC;

-- ============================================================
-- Q15. Liệt kê tất cả phòng ban kèm số người
-- ------------------------------------------------------------
-- Ý tưởng:
--   Giống Q4, GROUP BY department để đếm nhân viên từng phòng.
--   Đây thực chất là cùng query với Q4.
--
-- Độ phức tạp: O(n log n).
-- ============================================================
SELECT department, COUNT(*) AS num_employees
FROM Employee
GROUP BY department
ORDER BY num_employees DESC;

-- ============================================================
-- Q16. Lấy bản ghi cuối cùng của bảng
-- ------------------------------------------------------------
-- Ý tưởng:
--   "Bản ghi cuối" thường được hiểu là bản ghi có ID lớn nhất.
--   Dùng subquery lấy MAX(employee_id) rồi WHERE để lọc.
--
-- Cách 1: WHERE employee_id = MAX subquery
--   - Ưu: Chính xác, không phụ thuộc thứ tự vật lý trong bảng.
--   - Nhược: Subquery chạy thêm 1 lần; thay bằng ORDER BY DESC LIMIT 1 nhanh hơn.
--   - Dùng khi: Cần bản ghi có ID lớn nhất (không nhất thiết là cuối vật lý).
--
-- Cách thay thế nhanh hơn: SELECT * FROM Employee ORDER BY employee_id DESC LIMIT 1;
--
-- Độ phức tạp: O(1) nếu có index trên employee_id (PRIMARY KEY).
-- ============================================================
SELECT *
FROM Employee
WHERE employee_id = (SELECT MAX(employee_id) FROM Employee);

-- ============================================================
-- Q17. Lấy bản ghi đầu tiên của bảng
-- ------------------------------------------------------------
-- Ý tưởng:
--   Bản ghi đầu tiên = có employee_id nhỏ nhất.
--   Tương tự Q16 nhưng dùng MIN thay vì MAX.
--
-- Độ phức tạp: O(1) nếu có index trên employee_id.
-- ============================================================
SELECT *
FROM Employee
WHERE employee_id = (SELECT MIN(employee_id) FROM Employee);

-- ============================================================
-- Q18. Lấy 5 bản ghi cuối, sắp xếp tăng dần theo id
-- ------------------------------------------------------------
-- Ý tưởng:
--   Bước 1: Lấy 5 bản ghi có ID lớn nhất (subquery ORDER BY DESC LIMIT 5).
--   Bước 2: Sắp xếp lại kết quả đó theo chiều tăng dần.
--
-- Cách 1: Subquery + ORDER BY ngoài
--   - Ưu: Hai bước rõ ràng, dễ hiểu.
--   - Nhược: MySQL không đảm bảo thứ tự từ subquery nếu không có ORDER BY ngoài.
--   - Dùng khi: Cần "5 bản ghi mới nhất" hiển thị theo thứ tự thời gian.
--
-- Độ phức tạp: O(n) — scan để tìm 5 phần tử cuối nếu có index.
-- ============================================================
SELECT *
FROM (
    SELECT * FROM Employee ORDER BY employee_id DESC LIMIT 5
) AS last5
ORDER BY employee_id ASC;

-- ============================================================
-- Q19. Nhân viên có lương cao nhất trong mỗi phòng ban
-- ------------------------------------------------------------
-- Ý tưởng:
--   Với mỗi phòng ban, tìm salary = MAX(salary) trong phòng đó.
--   LƯU Ý: GROUP BY department + SELECT first_name là SAI khi
--   bật ONLY_FULL_GROUP_BY (mặc định MySQL 8) vì first_name
--   không nằm trong GROUP BY hay hàm tổng hợp.
--
-- Cách 1: Correlated subquery
--   - Ưu: Portable, dễ hiểu logic.
--   - Nhược: O(n²) nếu không có composite index (department, salary).
--   - Dùng khi: Cần hiểu rõ; hoặc CSDL không có window functions.
--
-- Cách 2: Window function RANK()
--   - Ưu: O(n log n), viết 1 lần scan; chuẩn SQL:2003.
--   - Nhược: Cần MySQL 8+ / PostgreSQL / SQL Server 2005+.
--   - Dùng khi: Hiệu suất quan trọng, CSDL hỗ trợ window functions.
--
-- Độ phức tạp: O(n²) Cách 1, O(n log n) Cách 2.
-- ============================================================

-- Cách 1: Correlated subquery
SELECT e.first_name, e.last_name, e.department, e.salary
FROM Employee e
WHERE e.salary = (
    SELECT MAX(e2.salary)
    FROM Employee e2
    WHERE e2.department = e.department
);

-- Cách 2: Window function (MySQL 8+)
SELECT first_name, last_name, department, salary
FROM (
    SELECT *,
           RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk
    FROM Employee
) t
WHERE rnk = 1;

-- ============================================================
-- Q20. Lấy ba mức lương cao nhất (không trùng)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Khác Q1 ở chỗ lấy tất cả 3 mức lương cao nhất (top-3 distinct values)
--   thay vì chỉ lấy đúng mức thứ 3.
--
-- Cách 1: DISTINCT + LIMIT 3
--   - Ưu: Đơn giản, nhanh.
--   - Nhược: Không portable.
--   - Dùng khi: MySQL / PostgreSQL.
--
-- Cách 2: Subquery đếm ngược
--   - Ưu: Portable.
--   - Nhược: O(n²).
--   - Dùng khi: Cần giải thích logic; SQL Server / Oracle.
--
-- Độ phức tạp: O(n log n) Cách 1, O(n²) Cách 2.
-- ============================================================

-- Cách 1
SELECT DISTINCT salary
FROM Employee
ORDER BY salary DESC
LIMIT 3;

-- Cách 2
SELECT DISTINCT e1.salary
FROM Employee e1
WHERE 3 >= (
    SELECT COUNT(DISTINCT e2.salary)
    FROM Employee e2
    WHERE e1.salary <= e2.salary
)
ORDER BY e1.salary DESC;

-- ============================================================
-- Q21. Tổng lương theo từng phòng ban
-- ------------------------------------------------------------
-- Ý tưởng:
--   GROUP BY phòng ban, SUM(salary) tổng hợp, sắp xếp kết quả.
--   Bài toán điển hình của aggregate function.
--
-- Cách 1: GROUP BY + SUM
--   - Ưu: Chuẩn SQL, rõ ràng, hiệu quả với index.
--   - Nhược: Không có cách thay thế ngắn hơn.
--   - Dùng khi: Báo cáo tổng hợp theo nhóm.
--
-- Độ phức tạp: O(n) — một lần scan bảng.
-- ============================================================
SELECT department, SUM(salary) AS total_salary
FROM Employee
GROUP BY department
ORDER BY total_salary DESC;

-- ============================================================
-- Q22. Nhân viên có lương cao nhất toàn công ty
-- ------------------------------------------------------------
-- Ý tưởng:
--   WHERE salary = MAX(salary) — lọc tất cả nhân viên có lương bằng giá trị max.
--   Khác TOP 1: nếu 2 người cùng lương cao nhất thì cả 2 đều xuất hiện.
--
-- Cách 1: WHERE + Subquery MAX
--   - Ưu: Trả về tất cả người chia sẻ mức lương cao nhất.
--   - Nhược: Subquery chạy thêm 1 lần (MySQL có thể cache).
--   - Dùng khi: Muốn giữ tất cả tie (đồng hạng).
--
-- Cách thay thế: ORDER BY salary DESC LIMIT 1 — chỉ lấy 1 người.
--
-- Độ phức tạp: O(1) nếu có index trên salary.
-- ============================================================
SELECT first_name, last_name, salary
FROM Employee
WHERE salary = (SELECT MAX(salary) FROM Employee);

-- ============================================================
-- Q34. Top 10 user gửi nhiều tin nhắn nhất
-- ------------------------------------------------------------
-- Ý tưởng:
--   Sắp xếp messages_sent giảm dần, giới hạn 10 kết quả.
--   Bài toán leaderboard đơn giản.
--
-- Cách 1: ORDER BY DESC + LIMIT
--   - Ưu: Đơn giản, nhanh với index trên messages_sent.
--   - Nhược: Không xử lý tie — nếu vị trí 10 và 11 cùng điểm, kết quả không nhất quán.
--   - Dùng khi: Leaderboard, dashboard nhanh.
--
-- Độ phức tạp: O(n log n) không có index, O(n) với index.
-- ============================================================
SELECT user_id, messages_sent
FROM messages_detail
ORDER BY messages_sent DESC
LIMIT 10;

-- ============================================================
-- Q48. Tìm giá trị lớn nhất mà KHÔNG dùng MAX/MIN
-- ------------------------------------------------------------
-- Ý tưởng:
--   Dùng ORDER BY + LIMIT để lấy giá trị lớn nhất.
--   Kỹ thuật kinh điển trong phỏng vấn để kiểm tra sáng tạo.
--
-- Cách 1: ORDER BY DESC + LIMIT 1
--   - Ưu: Ngắn gọn, dùng được mọi hàm sort.
--   - Nhược: Phụ thuộc LIMIT (không có trong SQL chuẩn ANSI).
--   - Dùng khi: MySQL, PostgreSQL.
--
-- Cách thay thế: Subquery NOT EXISTS — SELECT a FROM t WHERE NOT EXISTS
--   (SELECT 1 FROM t WHERE t.val > a.val) — portable hơn.
--
-- Độ phức tạp: O(n log n) không có index, O(1) với index.
-- ============================================================
SELECT numbers
FROM compare
ORDER BY numbers DESC
LIMIT 1;
