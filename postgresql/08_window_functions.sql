-- ============================================================
-- 08_window_functions.sql  (PostgreSQL port)
-- Chủ đề: Window Functions
-- Nguồn: W1-W5
-- Khác biệt vs MySQL:
--   - Cú pháp window function hoàn toàn chuẩn SQL:2003 — giống nhau
--   - ROUND() trả về NUMERIC trong PG, không phải DOUBLE như MySQL
-- ============================================================

-- ============================================================
-- W1. Xếp hạng nhân viên theo lương trong từng phòng ban
-- ------------------------------------------------------------
-- PostgreSQL note: RANK, DENSE_RANK, ROW_NUMBER là SQL chuẩn — giống MySQL.
-- Độ phức tạp: O(n log n).
-- ============================================================
SELECT
    employee_id, first_name, last_name, department, salary,
    RANK()       OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dense_rank,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS row_num
FROM Employee;

-- ============================================================
-- W2. So sánh lương với người cùng phòng (LAG/LEAD)
-- ------------------------------------------------------------
-- PostgreSQL note: LAG/LEAD là SQL chuẩn — giống MySQL.
-- Độ phức tạp: O(n log n).
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
-- PostgreSQL note:
--   - ROWS BETWEEN frame clause là SQL chuẩn — giống MySQL.
--   - ROUND(val, 2) trả về NUMERIC trong PG — ổn với mọi context.
-- Độ phức tạp: O(n log n) sort + O(n) sliding window.
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
-- PostgreSQL note:
--   - Chia số nguyên trong PG cần CAST: salary::NUMERIC / AVG(salary)
--   - MySQL tự cast sang DOUBLE; PG cần tường minh với INTEGER.
-- Độ phức tạp: O(n).
-- ============================================================
SELECT
    employee_id, first_name, department, salary,
    ROUND(salary::NUMERIC / AVG(salary) OVER (PARTITION BY department) * 100, 2) AS pct_of_dept_avg
FROM Employee;

-- ============================================================
-- W5. Top 2 nhân viên lương cao nhất mỗi phòng
-- ------------------------------------------------------------
-- PostgreSQL note: Cú pháp giống MySQL — DENSE_RANK + subquery là SQL chuẩn.
-- Độ phức tạp: O(n log n).
-- ============================================================
SELECT *
FROM (
    SELECT
        employee_id, first_name, department, salary,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk
    FROM Employee
) t
WHERE rnk <= 2;
