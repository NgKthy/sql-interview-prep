-- ============================================================
-- 09_cte_recursive.sql
-- Chủ đề: CTE và Recursive CTE (MỚI)
-- Hệ CSDL: MySQL 8.0+
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- C1. CTE cơ bản — nhân viên lương cao hơn TB phòng ban
-- ------------------------------------------------------------
-- Ý tưởng:
--   CTE (Common Table Expression) giúp tách logic phức tạp thành bước nhỏ.
--   Bước 1: Tính avg_salary từng phòng (dept_avg CTE).
--   Bước 2: JOIN với Employee, lọc salary > avg của phòng đó.
--
-- Cách 1: WITH ... AS (...) + JOIN
--   - Ưu: Code dễ đọc, dễ debug từng bước; CTE có thể dùng lại nhiều lần.
--   - Nhược: MySQL thực thi CTE như subquery — không tạo index tạm.
--   - Dùng khi: Query cần tham chiếu kết quả aggregate trong SELECT chính.
--
-- Cách thay thế: Correlated subquery — WHERE salary > (SELECT AVG...)
--   - Nhược: O(n²) vì subquery chạy cho từng dòng.
--
-- Độ phức tạp: O(n log n) — CTE GROUP BY + JOIN.
-- ============================================================
WITH dept_avg AS (
    SELECT department, AVG(salary) AS avg_salary
    FROM Employee
    GROUP BY department
)
SELECT
    e.first_name, e.last_name, e.department, e.salary, d.avg_salary
FROM Employee e
JOIN dept_avg d ON e.department = d.department
WHERE e.salary > d.avg_salary;

-- ============================================================
-- C2. Nhiều CTE — lọc nhân viên Admin lương cao hơn TB
-- ------------------------------------------------------------
-- Ý tưởng:
--   Dùng 2 CTE nối tiếp: admin_avg tính TB lương Admin,
--   admin_emp lọc danh sách nhân viên Admin.
--   Outer query kết hợp: chỉ giữ người lương > TB Admin.
--
-- Cách 1: Multi-CTE với SELECT từ CTE scalar
--   - Ưu: Mỗi CTE có mục đích rõ ràng, code tự tài liệu hóa.
--   - Nhược: admin_avg trả về 1 dòng nhưng vẫn phải dùng subquery SELECT.
--     Tốt hơn: lưu avg_salary vào biến hoặc dùng HAVING.
--   - Dùng khi: Query phức tạp nhiều bước, cần tái sử dụng kết quả trung gian.
--
-- Lưu ý: MySQL 8.0 hỗ trợ multi-CTE. Mỗi CTE có thể tham chiếu CTE trước nó.
--
-- Độ phức tạp: O(n) — 2 CTE scan bảng, outer query 1 lần.
-- ============================================================
WITH admin_avg AS (
    SELECT AVG(salary) AS avg_salary
    FROM Employee
    WHERE department = 'Admin'
),
admin_emp AS (
    SELECT * FROM Employee WHERE department = 'Admin'
)
SELECT *
FROM admin_emp
WHERE salary > (SELECT avg_salary FROM admin_avg);

-- ============================================================
-- C3. Recursive CTE — sinh dãy số 1..10
-- ------------------------------------------------------------
-- Ý tưởng:
--   Recursive CTE gồm 2 phần kết hợp bằng UNION ALL:
--   - Anchor: điểm bắt đầu (SELECT 1 AS n).
--   - Recursive: bước lặp (SELECT n+1 WHERE n < 10).
--   MySQL tự dừng khi điều kiện WHERE sai.
--
-- Cách 1: WITH RECURSIVE + UNION ALL
--   - Ưu: Tạo dãy số mà không cần bảng lookup; portable (SQL:1999).
--   - Nhược: MySQL mặc định giới hạn 1000 vòng lặp (cte_max_recursion_depth).
--   - Dùng khi: Tạo calendar table, date range, số thứ tự, fill missing rows.
--
-- Cách tăng giới hạn: SET SESSION cte_max_recursion_depth = 10000;
--
-- Độ phức tạp: O(n) — n vòng lặp đệ quy.
-- ============================================================
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10
)
SELECT * FROM seq;

-- ============================================================
-- C4. Recursive CTE — tính giai thừa
-- ------------------------------------------------------------
-- Ý tưởng:
--   Mở rộng C3: mỗi vòng lặp mang theo 2 cột: n và n!.
--   Recursive step: n+1, (n+1) * factorial_hiện_tại.
--   Kết quả: bảng giai thừa từ 1! đến 10!.
--
-- Cách 1: WITH RECURSIVE + carry-forward accumulated value
--   - Ưu: Minh họa cách dùng CTE để tích lũy giá trị qua các bước.
--   - Nhược: Giai thừa tăng rất nhanh → overflow nếu n > 20 (BIGINT max ~9.2*10^18 = 20!).
--   - Dùng khi: Tính toán tích lũy, Fibonacci, running product.
--
-- Lưu ý thực tế: Giai thừa thường tính ngoài SQL (Python, app layer).
--   Trong phỏng vấn, bài này kiểm tra hiểu biết về recursive CTE structure.
--
-- Độ phức tạp: O(n) — n bước đệ quy.
-- ============================================================
WITH RECURSIVE fact AS (
    SELECT 1 AS n, 1 AS factorial
    UNION ALL
    SELECT n + 1, (n + 1) * factorial FROM fact WHERE n < 10
)
SELECT * FROM fact;
