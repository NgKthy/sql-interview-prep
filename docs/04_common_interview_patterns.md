# 20 mẫu câu hỏi SQL phỏng vấn thường gặp

> Đây là bộ pattern lặp đi lặp lại trong 90% buổi phỏng vấn Data Analyst. Học thuộc 20 mẫu này là bạn xử lý được gần hết vòng technical.

---

## 1. Tìm N giá trị cao nhất

### Dạng 1.1 — Top N bản ghi

```sql
SELECT * FROM Employee ORDER BY salary DESC LIMIT 5;
```

### Dạng 1.2 — Top N giá trị distinct

```sql
-- Mức lương cao thứ 3
SELECT DISTINCT salary
FROM Employee
ORDER BY salary DESC
LIMIT 2, 1;   -- hoặc LIMIT 1 OFFSET 2 (PostgreSQL)

-- Portable (mọi hệ CSDL)
SELECT DISTINCT e1.salary
FROM Employee e1
WHERE 3 = (
    SELECT COUNT(DISTINCT e2.salary)
    FROM Employee e2
    WHERE e2.salary >= e1.salary
);
```

### Dạng 1.3 — Top N mỗi nhóm (phổ biến nhất)

```sql
SELECT * FROM (
    SELECT
        employee_id, department, salary,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rn
    FROM Employee
) t
WHERE rn <= 3;
```

---

## 2. Tìm bản ghi mới nhất / cũ nhất mỗi nhóm

```sql
-- Dùng ROW_NUMBER
SELECT * FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) AS rn
    FROM orders
) t
WHERE rn = 1;

-- Hoặc correlated subquery (portable)
SELECT o.*
FROM orders o
WHERE o.created_at = (
    SELECT MAX(o2.created_at)
    FROM orders o2
    WHERE o2.user_id = o.user_id
);
```

---

## 3. Đếm số bản ghi theo nhóm

```sql
-- Đơn giản
SELECT department, COUNT(*) AS num
FROM Employee
GROUP BY department;

-- Có filter trong aggregate (MySQL/PG)
SELECT
    department,
    COUNT(*) AS total,
    SUM(CASE WHEN salary > 100000 THEN 1 ELSE 0 END) AS high_earners
FROM Employee
GROUP BY department;

-- PostgreSQL: dùng FILTER gọn hơn
SELECT
    department,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE salary > 100000) AS high_earners
FROM Employee
GROUP BY department;
```

---

## 4. Tìm bản ghi trùng lặp

```sql
-- Tìm email trùng
SELECT email, COUNT(*) AS cnt
FROM users
GROUP BY email
HAVING COUNT(*) > 1;

-- Chi tiết các bản ghi trùng
SELECT * FROM users
WHERE email IN (
    SELECT email FROM users GROUP BY email HAVING COUNT(*) > 1
)
ORDER BY email;

-- Hoặc dùng window function
SELECT * FROM (
    SELECT *, COUNT(*) OVER (PARTITION BY email) AS cnt
    FROM users
) t
WHERE cnt > 1;
```

---

## 5. Xóa bản ghi trùng, giữ lại 1

```sql
-- MySQL: dùng self-join
DELETE u1 FROM users u1
JOIN users u2
  ON u1.email = u2.email
 AND u1.id > u2.id;

-- PostgreSQL: dùng CTE
WITH dups AS (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY id) AS rn
    FROM users
)
DELETE FROM users WHERE id IN (SELECT id FROM dups WHERE rn > 1);
```

---

## 6. Running total / lũy kế

```sql
SELECT
    order_date,
    amount,
    SUM(amount) OVER (ORDER BY order_date) AS running_total
FROM orders;
```

**Bài toán thực tế**: tính số dư tài khoản sau mỗi giao dịch.

```sql
SELECT
    transaction_id,
    transaction_date,
    CASE WHEN type = 'credit' THEN amount ELSE -amount END AS delta,
    SUM(CASE WHEN type = 'credit' THEN amount ELSE -amount END)
        OVER (ORDER BY transaction_date) AS balance
FROM transactions;
```

---

## 7. So sánh với kỳ trước

```sql
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
    revenue - LAG(revenue) OVER (ORDER BY month) AS diff,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
        2
    ) AS pct_change
FROM monthly_sales;
```

---

## 8. Pivot — hàng thành cột

MySQL không có `PIVOT`, dùng `CASE`:

```sql
SELECT
    department,
    SUM(CASE WHEN year = 2022 THEN revenue ELSE 0 END) AS rev_2022,
    SUM(CASE WHEN year = 2023 THEN revenue ELSE 0 END) AS rev_2023,
    SUM(CASE WHEN year = 2024 THEN revenue ELSE 0 END) AS rev_2024
FROM sales
GROUP BY department;
```

**PostgreSQL**: dùng `crosstab()` từ extension `tablefunc`.

---

## 9. Unpivot — cột thành hàng

```sql
-- Từ bảng có nhiều cột năm -> chuyển thành nhiều dòng
SELECT department, 2022 AS year, rev_2022 AS revenue FROM sales_wide
UNION ALL
SELECT department, 2023 AS year, rev_2023 AS revenue FROM sales_wide
UNION ALL
SELECT department, 2024 AS year, rev_2024 AS revenue FROM sales_wide;
```

**PostgreSQL**: dùng `UNNEST` hoặc `LATERAL`.

---

## 10. Self join — tìm cặp

```sql
-- Cặp nhân viên cùng mức lương
SELECT DISTINCT e1.first_name, e1.salary
FROM Employee e1
JOIN Employee e2
  ON e1.salary = e2.salary
 AND e1.employee_id < e2.employee_id;   -- tránh cặp trùng
```

**Lưu ý**: dùng `<` thay vì `<>` để mỗi cặp chỉ xuất hiện 1 lần.

---

## 11. Tìm nhân viên có lương cao hơn manager

```sql
SELECT e.first_name AS employee, e.salary AS emp_sal,
       m.first_name AS manager, m.salary AS mgr_sal
FROM Employee e
JOIN Employee m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;
```

---

## 12. Cohort Retention

```sql
WITH user_cohort AS (
    SELECT
        user_id,
        DATE_FORMAT(MIN(event_date), '%Y-%m-01') AS cohort_month
    FROM user_events
    WHERE event_type = 'signup'
    GROUP BY user_id
),
monthly_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(event_date, '%Y-%m-01') AS activity_month
    FROM user_events
)
SELECT
    uc.cohort_month,
    ma.activity_month,
    TIMESTAMPDIFF(MONTH,
        STR_TO_DATE(uc.cohort_month, '%Y-%m-%d'),
        STR_TO_DATE(ma.activity_month, '%Y-%m-%d')
    ) AS month_number,
    COUNT(DISTINCT ma.user_id) AS active_users
FROM user_cohort uc
JOIN monthly_activity ma ON uc.user_id = ma.user_id
GROUP BY uc.cohort_month, ma.activity_month
ORDER BY uc.cohort_month, month_number;
```

**Ý tưởng**:
1. Xác định tháng đầu tiên mỗi user hoạt động (cohort).
2. Join lại để xem họ hoạt động những tháng nào.
3. Đếm số user active theo cohort × tháng.

---

## 13. Funnel Analysis

```sql
-- Đếm user ở từng bước funnel (chỉ tính user đã qua bước trước)
SELECT
    'visit'    AS step, COUNT(DISTINCT user_id) AS users FROM funnel_events WHERE step = 'visit'
UNION ALL
SELECT 'signup',
    COUNT(DISTINCT user_id) FROM funnel_events
    WHERE step = 'signup' AND user_id IN (
        SELECT user_id FROM funnel_events WHERE step = 'visit'
    )
UNION ALL
SELECT 'purchase',
    COUNT(DISTINCT user_id) FROM funnel_events
    WHERE step = 'purchase' AND user_id IN (
        SELECT user_id FROM funnel_events WHERE step = 'signup'
    );
```

---

## 14. RFM Analysis

```sql
WITH rfm_raw AS (
    SELECT
        customer_id,
        DATEDIFF('2024-01-01', MAX(order_date)) AS recency,
        COUNT(*) AS frequency,
        SUM(amount) AS monetary
    FROM orders
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id, recency, frequency, monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)  AS m_score
    FROM rfm_raw
)
SELECT
    customer_id,
    CONCAT(r_score, f_score, m_score) AS rfm,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Others'
    END AS segment
FROM rfm_scores;
```

---

## 15. Median / Percentile

**MySQL 8+**:

```sql
SELECT
    department,
    AVG(salary) AS mean_salary,
    (
        SELECT salary
        FROM Employee e2
        WHERE e2.department = e1.department
        ORDER BY salary
        LIMIT 1 OFFSET (SELECT COUNT(*) FROM Employee e3 WHERE e3.department = e1.department) / 2
    ) AS median_salary
FROM Employee e1
GROUP BY department;
```

**Cách dễ hơn** — dùng `PERCENT_RANK`:

```sql
WITH ranked AS (
    SELECT
        department, salary,
        PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) AS pr
    FROM Employee
)
SELECT department, AVG(salary) AS median
FROM ranked
WHERE pr BETWEEN 0.49 AND 0.51
GROUP BY department;
```

---

## 16. Tìm khoảng trống (Gaps) trong dãy số

```sql
-- Tìm ID bị thiếu trong dãy 1..N
SELECT (t1.id + 1) AS gap_start,
       (MIN(t2.id) - 1) AS gap_end
FROM numbers t1
JOIN numbers t2 ON t2.id > t1.id
GROUP BY t1.id
HAVING gap_start < MIN(t2.id);
```

---

## 17. Tìm user không hoạt động

```sql
-- User có signup nhưng chưa từng login
SELECT u.user_id, u.signup_date
FROM users u
LEFT JOIN logins l ON u.user_id = l.user_id
WHERE l.user_id IS NULL;

-- Hoặc NOT EXISTS
SELECT u.user_id FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM logins l WHERE l.user_id = u.user_id
);
```

---

## 18. Đếm số ngày liên tiếp

```sql
-- Gán nhóm cho các ngày liên tiếp, rồi đếm
WITH numbered AS (
    SELECT
        user_id,
        login_date,
        DATE_SUB(login_date, INTERVAL ROW_NUMBER() OVER (
            PARTITION BY user_id ORDER BY login_date
        ) DAY) AS grp
    FROM logins
)
SELECT
    user_id,
    MIN(login_date) AS streak_start,
    MAX(login_date) AS streak_end,
    COUNT(*) AS streak_length
FROM numbered
GROUP BY user_id, grp
HAVING COUNT(*) >= 3;
```

---

## 19. Chuyển đổi giữa các đơn vị thời gian

```sql
-- Giây -> giờ:phút:giây
SELECT
    SEC_TO_TIME(3661) AS formatted;   -- '01:01:01'

-- Ngày -> tuần
SELECT
    order_date,
    DATE_FORMAT(order_date, '%Y-%u') AS year_week
FROM orders;

-- Đếm số ngày giữa 2 mốc
SELECT DATEDIFF('2024-01-01', '2023-12-01') AS days;
```

---

## 20. So sánh tỷ lệ giữa 2 nhóm

```sql
-- So sánh conversion rate giữa 2 version
SELECT
    version,
    COUNT(DISTINCT user_id) AS total_users,
    SUM(CASE WHEN converted = 1 THEN 1 ELSE 0 END) AS converted_users,
    ROUND(
        SUM(CASE WHEN converted = 1 THEN 1 ELSE 0 END) * 100.0
        / COUNT(DISTINCT user_id),
        2
    ) AS conversion_rate
FROM ab_test
GROUP BY version;
```

---

## Bảng tổng hợp — Pattern -> Kỹ thuật

| Pattern | Kỹ thuật chính |
|---|---|
| Top N | `ORDER BY ... LIMIT` |
| Top N mỗi nhóm | `ROW_NUMBER() OVER (PARTITION BY ...)` |
| Bản ghi mới nhất | `ROW_NUMBER` hoặc correlated subquery |
| Đếm theo nhóm | `GROUP BY` |
| Trùng lặp | `GROUP BY ... HAVING COUNT(*) > 1` |
| Running total | `SUM() OVER (ORDER BY ...)` |
| So sánh kỳ trước | `LAG() OVER (ORDER BY ...)` |
| Pivot | `CASE WHEN ... THEN` |
| Unpivot | `UNION ALL` |
| Self join | JOIN bảng với chính nó |
| Quản lý | Self join với manager_id |
| Cohort | CTE + Join theo tháng |
| Funnel | `UNION ALL` + `IN (subquery)` |
| RFM | `NTILE(5)` |
| Median | `PERCENT_RANK()` |
| Gaps | Self join |
| Không hoạt động | `LEFT JOIN ... IS NULL` |
| Streak | `DATE_SUB(date, ROW_NUMBER())` |
| Time format | `DATE_FORMAT`, `DATEDIFF` |
| So sánh nhóm | `GROUP BY` + `CASE WHEN` |

---

## Ghi nhớ cuối cùng

> **Nắm 5 kỹ thuật này là xử lý được 90% câu hỏi:**
> 1. **GROUP BY + HAVING** (đếm, lọc nhóm)
> 2. **JOIN / LEFT JOIN** (kết hợp bảng)
> 3. **ROW_NUMBER / RANK** (xếp hạng, top N)
> 4. **LAG / LEAD** (so sánh kỳ trước)
> 5. **CTE** (tổ chức query phức tạp)
