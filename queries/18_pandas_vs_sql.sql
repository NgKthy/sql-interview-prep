-- ============================================================
-- 18_pandas_vs_sql.sql
-- Chủ đề: So sánh SQL và Pandas cho cùng một bài toán
-- ============================================================

USE sql_interview_prep;

-- P1. Đếm nhân viên theo phòng ban
SELECT department, COUNT(*) AS num_employees
FROM Employee
GROUP BY department
ORDER BY num_employees DESC;
-- Pandas: df.groupby('department').size().reset_index(name='num_employees')

-- P2. Lọc + sắp xếp
SELECT first_name, last_name, salary
FROM Employee
WHERE department = 'Admin' AND salary > 100000
ORDER BY salary DESC;
-- Pandas: df[(df.department=='Admin') & (df.salary>100000)].sort_values('salary', ascending=False)

-- P3. JOIN 2 bảng
SELECT e.first_name, e.last_name, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id;
-- Pandas: emp.merge(bon, left_on='employee_id', right_on='employee_ref_id')

-- P4. LEFT JOIN + xử lý NULL
SELECT e.first_name, COALESCE(b.bonus_amount, 0) AS bonus
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id;
-- Pandas: emp.merge(bon, how='left').fillna({'bonus_amount': 0})

-- P5. Window function — RANK
SELECT
    employee_id, first_name, department, salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk
FROM Employee;
-- Pandas: df.groupby('department')['salary'].rank(method='min', ascending=False)

-- P6. LAG / LEAD
SELECT
    employee_id, joining_date, salary,
    LAG(salary) OVER (ORDER BY joining_date) AS prev_salary
FROM Employee;
-- Pandas: df.sort_values('joining_date')['salary'].shift(1)

-- P7. Running total
SELECT
    employee_id, joining_date, salary,
    SUM(salary) OVER (ORDER BY joining_date
                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM Employee;
-- Pandas: df.sort_values('joining_date')['salary'].cumsum()

-- P8. Pivot table
SELECT
    department,
    SUM(CASE WHEN salary >= 300000 THEN 1 ELSE 0 END) AS high_salary,
    SUM(CASE WHEN salary < 300000 THEN 1 ELSE 0 END)  AS low_salary
FROM Employee
GROUP BY department;
-- Pandas: df.pivot_table(index='department', values='salary', aggfunc=...)

-- P9. Tìm bản ghi mới nhất mỗi nhóm
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY department ORDER BY joining_date DESC) AS rn
    FROM Employee
) t
WHERE rn = 1;
-- Pandas: df.sort_values('joining_date', ascending=False).groupby('department').head(1)

-- P10. Self join — nhân viên cùng lương
SELECT DISTINCT e1.first_name, e1.salary
FROM Employee e1
JOIN Employee e2 ON e1.salary = e2.salary AND e1.employee_id <> e2.employee_id;
-- Pandas: df[df.duplicated('salary', keep=False)]
