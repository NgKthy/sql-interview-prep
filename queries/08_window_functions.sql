-- ============================================================
-- 08_window_functions.sql
-- Chủ đề: Window Functions (MỚI)
-- Hệ CSDL: MySQL 8.0+
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- W1. Xếp hạng nhân viên theo lương trong từng phòng ban
-- ------------------------------------------------------------
-- Ý tưởng:
--   Dùng 3 hàm ranking song song để hiểu rõ sự khác biệt:
--   RANK, DENSE_RANK, ROW_NUMBER — tất cả đều PARTITION BY department.
--
-- Phân biệt 3 hàm ranking:
--   RANK():       Tie → cùng rank, bỏ qua số tiếp theo. VD: 1,1,3
--   DENSE_RANK(): Tie → cùng rank, KHÔNG bỏ qua số tiếp theo. VD: 1,1,2
--   ROW_NUMBER(): Luôn khác nhau, thứ tự ngẫu nhiên khi tie. VD: 1,2,3
--
-- Cách 1: PARTITION BY department + ORDER BY salary DESC
--   - Ưu: 1 lần scan bảng, tính 3 ranking song song — hiệu quả.
--   - Nhược: Nếu nhiều partition lớn, memory sort tốn kém.
--   - Dùng khi: Ranking trong nhóm — bài phổ biến nhất trong phỏng vấn.
--
-- Độ phức tạp: O(n log n) — sort trong mỗi partition.
-- ============================================================
SELECT
    employee_id, first_name, last_name, department, salary,
    RANK()       OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS `dense_rank`,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS row_num
FROM Employee;

-- ============================================================
-- W2. So sánh lương với người cùng phòng (LAG/LEAD)
-- ------------------------------------------------------------
-- Ý tưởng:
--   LAG(col) lấy giá trị của dòng TRƯỚC trong cùng partition/order.
--   LEAD(col) lấy giá trị của dòng SAU.
--   Tính delta = salary - LAG(salary) để thấy chênh lệch giữa các mức.
--
-- Cách 1: LAG + LEAD trong cùng OVER clause
--   - Ưu: Tránh self-join tốn kém; 1 lần scan, truy xuất dòng lân cận.
--   - Nhược: Dòng đầu tiên: LAG = NULL; dòng cuối: LEAD = NULL.
--     Dùng LAG(salary, 1, 0) để đặt giá trị default thay NULL.
--   - Dùng khi: Time-series comparison, period-over-period change.
--
-- Lưu ý: ORDER BY salary (tăng dần) → LAG = người lương thấp hơn kế bên.
--
-- Độ phức tạp: O(n log n) — sort trong partition + 1 lần scan.
-- ============================================================
SELECT
    employee_id, first_name, department, salary,
    LAG(salary)  OVER (PARTITION BY department ORDER BY salary) AS prev_salary,
    LEAD(salary) OVER (PARTITION BY department ORDER BY salary) AS next_salary,
    salary - LAG(salary) OVER (PARTITION BY department ORDER BY salary) AS delta
FROM Employee;

-- ============================================================
-- W3. Lương trung bình động (Moving Average)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Moving average 3 kỳ = AVG của dòng hiện tại + 2 dòng trước.
--   Dùng ROWS BETWEEN frame clause để định nghĩa cửa sổ trượt.
--
-- Cách 1: AVG() OVER (ORDER BY ... ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
--   - Ưu: Tính chính xác moving average với frame window linh hoạt.
--   - Nhược: 2 dòng đầu có cửa sổ nhỏ hơn 3 → AVG dựa trên ít phần tử hơn.
--   - Dùng khi: Làm trơn time series, loại bỏ nhiễu ngắn hạn.
--
-- ROWS vs RANGE:
--   ROWS: đếm dòng vật lý (chính xác).
--   RANGE: đếm theo giá trị ORDER BY (có thể bao gồm nhiều dòng tie).
--
-- Độ phức tạp: O(n) — sliding window sau khi sort O(n log n).
-- ============================================================
SELECT
    employee_id, joining_date, salary,
    ROUND(AVG(salary) OVER (
        ORDER BY joining_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3
FROM Employee;

-- ============================================================
-- W4. Tỷ lệ % lương so với trung bình phòng ban
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tính salary / AVG(salary của phòng ban) * 100 để biết mỗi nhân viên
--   đang ở mức lương cao hay thấp hơn trung bình phòng bao nhiêu %.
--
-- Cách 1: salary / AVG(salary) OVER (PARTITION BY department) * 100
--   - Ưu: Không cần JOIN hay subquery; AVG được tính 1 lần mỗi partition.
--   - Nhược: Tỷ lệ > 100 = cao hơn TB, < 100 = thấp hơn — cần giải thích rõ.
--   - Dùng khi: Benchmarking nhân viên với trung bình nhóm — HR analytics.
--
-- Lưu ý: Nếu muốn % chênh lệch: (salary - AVG) / AVG * 100 → âm/dương.
--
-- Độ phức tạp: O(n) — tính AVG theo partition, 1 lần scan.
-- ============================================================
SELECT
    employee_id, first_name, department, salary,
    ROUND(salary / AVG(salary) OVER (PARTITION BY department) * 100, 2) AS pct_of_dept_avg
FROM Employee;

-- ============================================================
-- W5. Top 2 nhân viên lương cao nhất mỗi phòng
-- ------------------------------------------------------------
-- Ý tưởng:
--   DENSE_RANK() PARTITION BY department → xếp hạng trong phòng.
--   Lọc WHERE rnk <= 2 ở outer query để lấy top-2 mỗi phòng.
--   Dùng DENSE_RANK thay RANK để tránh bỏ sót khi có tie ở rank 2.
--
-- Cách 1: Subquery + DENSE_RANK + WHERE rnk <= 2
--   - Ưu: Xử lý đúng tie; DENSE_RANK đảm bảo không bỏ rank 2 khi có nhiều rank 1.
--   - Nhược: Nếu có nhiều người cùng rank 2, tất cả đều được trả về (có thể > 2 dòng/phòng).
--   - Dùng khi: Top-N per group — bài phỏng vấn phổ biến nhất về window functions.
--
-- Lưu ý: ROW_NUMBER <= 2 → đúng 2 người/phòng (tie-break ngẫu nhiên).
--         DENSE_RANK <= 2 → có thể nhiều hơn 2 nếu tie.
--         RANK <= 2       → giữa ROW_NUMBER và DENSE_RANK về hành vi.
--
-- Độ phức tạp: O(n log n) — DENSE_RANK cần sort trong partition.
-- ============================================================
SELECT *
FROM (
    SELECT
        employee_id, first_name, department, salary,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk
    FROM Employee
) t
WHERE rnk <= 2;
