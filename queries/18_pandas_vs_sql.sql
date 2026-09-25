-- ============================================================
-- 18_pandas_vs_sql.sql
-- Chủ đề: So sánh SQL và Pandas cho cùng một bài toán
-- Mục đích: Giúp Data Analyst chuyển đổi linh hoạt giữa 2 công cụ
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- BÀI TOÁN 1: Đếm nhân viên theo phòng ban
-- ============================================================

-- SQL
SELECT department, COUNT(*) AS num_employees
FROM Employee
GROUP BY department
ORDER BY num_employees DESC;

/*
Pandas:
    import pandas as pd
    df = pd.read_sql("SELECT * FROM Employee", conn)
    result = (df.groupby('department')
                .size()
                .reset_index(name='num_employees')
                .sort_values('num_employees', ascending=False))
*/

-- ============================================================
-- BÀI TOÁN 2: Lọc + sắp xếp
-- ============================================================

-- SQL
SELECT first_name, last_name, salary
FROM Employee
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

-- SQL
SELECT e.first_name, e.last_name, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id;

/*
Pandas:
    emp = pd.read_sql("SELECT * FROM Employee", conn)
    bon = pd.read_sql("SELECT * FROM Bonus", conn)
    result = emp.merge(bon, left_on='employee_id', right_on='employee_ref_id',
                       how='inner')[['first_name', 'last_name', 'bonus_amount']]
*/

-- ============================================================
-- BÀI TOÁN 4: LEFT JOIN + xử lý NULL
-- ============================================================

-- SQL
SELECT e.first_name, COALESCE(b.bonus_amount, 0) AS bonus
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id;

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

-- SQL
SELECT
    employee_id, first_name, department, salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk
FROM Employee;

/*
Pandas:
    df['rnk'] = (df.groupby('department')['salary']
                   .rank(method='min', ascending=False)
                   .astype(int))
*/

-- ============================================================
-- BÀI TOÁN 6: LAG / LEAD
-- ============================================================

-- SQL
SELECT
    employee_id, joining_date, salary,
    LAG(salary) OVER (ORDER BY joining_date) AS prev_salary
FROM Employee;

/*
Pandas:
    df = df.sort_values('joining_date')
    df['prev_salary'] = df['salary'].shift(1)
*/

-- ============================================================
-- BÀI TOÁN 7: Running total
-- ============================================================

-- SQL
SELECT
    employee_id, joining_date, salary,
    SUM(salary) OVER (ORDER BY joining_date
                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM Employee;

/*
Pandas:
    df = df.sort_values('joining_date')
    df['running_total'] = df['salary'].cumsum()
*/

-- ============================================================
-- BÀI TOÁN 8: Pivot table
-- ============================================================

-- SQL (MySQL không có PIVOT, dùng CASE)
SELECT
    department,
    SUM(CASE WHEN salary >= 300000 THEN 1 ELSE 0 END) AS high_salary,
    SUM(CASE WHEN salary < 300000 THEN 1 ELSE 0 END)  AS low_salary
FROM Employee
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

-- SQL (dùng ROW_NUMBER)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY department ORDER BY joining_date DESC) AS rn
    FROM Employee
) t
WHERE rn = 1;

/*
Pandas:
    result = (df.sort_values('joining_date', ascending=False)
                .groupby('department')
                .head(1))
*/

-- ============================================================
-- BÀI TOÁN 10: Self join — nhân viên cùng lương
-- ============================================================

-- SQL
SELECT DISTINCT e1.first_name, e1.salary
FROM Employee e1
JOIN Employee e2 ON e1.salary = e2.salary AND e1.employee_id <> e2.employee_id;

/*
Pandas:
    # Cách 1: dùng merge
    result = (df.merge(df, on='salary', suffixes=('_1', '_2'))
                .query('employee_id_1 != employee_id_2')
                [['first_name_1', 'salary']]
                .drop_duplicates())

    # Cách 2: dùng groupby + filter
    result = df[df.duplicated('salary', keep=False)]
*/

-- ============================================================
-- BẢNG CHUYỂN ĐỔI NHANH SQL ↔ PANDAS
-- ============================================================
/*
| SQL                        | Pandas                                  |
|----------------------------|-----------------------------------------|
| SELECT col1, col2          | df[['col1', 'col2']]                    |
| WHERE col > x              | df[df['col'] > x]                       |
| WHERE col IN (a, b)        | df[df['col'].isin([a, b])]              |
| WHERE col IS NULL          | df[df['col'].isna()]                    |
| GROUP BY col               | df.groupby('col')                       |
| COUNT(*)                   | df.size() hoặc df['col'].count()        |
| SUM(col)                   | df['col'].sum()                         |
| AVG(col)                   | df['col'].mean()                        |
| MIN/MAX(col)               | df['col'].min() / .max()                |
| ORDER BY col DESC          | df.sort_values('col', ascending=False)  |
| LIMIT n                    | df.head(n)                              |
| JOIN                       | df.merge(other, on='key')               |
| LEFT JOIN                  | df.merge(other, on='key', how='left')   |
| UNION ALL                  | pd.concat([df1, df2])                   |
| DISTINCT                   | df.drop_duplicates()                    |
| HAVING                     | df.groupby().filter(lambda x: ...)      |
| ROW_NUMBER() OVER (...)    | df.groupby().cumcount() + 1             |
| RANK() OVER (...)          | df.groupby().rank()                     |
| LAG/LEAD                   | df['col'].shift(1) / .shift(-1)         |
| Running total              | df['col'].cumsum()                      |
*/
