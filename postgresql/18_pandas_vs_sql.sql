-- ============================================================
-- 18_pandas_vs_sql.sql  (PostgreSQL port)
-- Chủ đề: So sánh PostgreSQL và Pandas cho cùng một bài toán
-- Mục đích: Giúp Data Analyst / Data Engineer chuyển đổi linh hoạt giữa 2 công cụ
-- ============================================================

-- ============================================================
-- BÀI TOÁN 1: Đếm nhân viên theo phòng ban
-- ============================================================

-- PostgreSQL
SELECT department, COUNT(*) AS num_employees
FROM employee
GROUP BY department
ORDER BY num_employees DESC;

/*
Pandas:
    import pandas as pd
    df = pd.read_sql("SELECT * FROM employee", conn)
    result = (df.groupby('department')
                .size()
                .reset_index(name='num_employees')
                .sort_values('num_employees', ascending=False))
*/

-- ============================================================
-- BÀI TOÁN 2: Lọc + sắp xếp
-- ============================================================

-- PostgreSQL
SELECT first_name, last_name, salary
FROM employee
WHERE department = 'Admin' AND salary > 100000
ORDER BY salary DESC;

/*
Pandas:
    result = (df[(df['department'] == 'Admin') & (df['salary'] > 100000)]
                [['first_name', 'last_name', 'salary']]
                .sort_values('salary', ascending=False))
*/

-- ============================================================
-- BÀI TOÁN 3: JOIN 2 bảng
-- ============================================================

-- PostgreSQL
SELECT e.first_name, e.last_name, b.bonus_amount
FROM employee e
JOIN bonus b ON e.employee_id = b.employee_ref_id;

/*
Pandas:
    emp = pd.read_sql("SELECT * FROM employee", conn)
    bon = pd.read_sql("SELECT * FROM bonus", conn)
    result = emp.merge(bon, left_on='employee_id', right_on='employee_ref_id',
                       how='inner')[['first_name', 'last_name', 'bonus_amount']]
*/

-- ============================================================
-- BÀI TOÁN 4: LEFT JOIN + xử lý NULL
-- ============================================================

-- PostgreSQL
SELECT e.first_name, COALESCE(b.bonus_amount, 0) AS bonus
FROM employee e
LEFT JOIN bonus b ON e.employee_id = b.employee_ref_id;

/*
Pandas:
    result = emp.merge(bon, left_on='employee_id', right_on='employee_ref_id',
                       how='left')
    result['bonus_amount'] = result['bonus_amount'].fillna(0)
    result = result[['first_name', 'bonus_amount']]
*/

-- ============================================================
-- BÀI TOÁN 5: Window function — RANK
-- ============================================================

-- PostgreSQL
SELECT
    employee_id, first_name, department, salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk
FROM employee;

/*
Pandas:
    df['rnk'] = (df.groupby('department')['salary']
                   .rank(method='min', ascending=False)
                   .astype(int))
*/

-- ============================================================
-- BÀI TOÁN 6: LAG / LEAD
-- ============================================================

-- PostgreSQL
SELECT
    employee_id, joining_date, salary,
    LAG(salary) OVER (ORDER BY joining_date) AS prev_salary
FROM employee;

/*
Pandas:
    df = df.sort_values('joining_date')
    df['prev_salary'] = df['salary'].shift(1)
*/

-- ============================================================
-- BÀI TOÁN 7: Running total
-- ============================================================

-- PostgreSQL
SELECT
    employee_id, joining_date, salary,
    SUM(salary) OVER (ORDER BY joining_date
                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM employee;

/*
Pandas:
    df = df.sort_values('joining_date')
    df['running_total'] = df['salary'].cumsum()
*/

-- ============================================================
-- BÀI TOÁN 8: Pivot table (PostgreSQL CASE WHEN hoặc crosstab)
-- ============================================================

-- PostgreSQL (CASE WHEN chuẩn SQL)
SELECT
    department,
    SUM(CASE WHEN salary >= 300000 THEN 1 ELSE 0 END) AS high_salary,
    SUM(CASE WHEN salary < 300000 THEN 1 ELSE 0 END)  AS low_salary
FROM employee
GROUP BY department;

/*
Pandas:
    result = df.pivot_table(
        index='department',
        values='salary',
        aggfunc=[
            ('high_salary', lambda x: (x >= 300000).sum()),
            ('low_salary',  lambda x: (x < 300000).sum())
        ]
    )
*/

-- ============================================================
-- BÀI TOÁN 9: Tìm bản ghi mới nhất mỗi nhóm
-- ============================================================

-- PostgreSQL (Có thể dùng DISTINCT ON - cú pháp cực gọn chỉ PG có)
SELECT DISTINCT ON (department) *
FROM employee
ORDER BY department, joining_date DESC;

/*
Pandas:
    result = (df.sort_values('joining_date', ascending=False)
                .groupby('department')
                .head(1))
*/

-- ============================================================
-- BÀI TOÁN 10: Self join — nhân viên cùng lương
-- ============================================================

-- PostgreSQL
SELECT DISTINCT e1.first_name, e1.salary
FROM employee e1
JOIN employee e2 ON e1.salary = e2.salary AND e1.employee_id <> e2.employee_id;

/*
Pandas:
    result = df[df.duplicated('salary', keep=False)]
*/
