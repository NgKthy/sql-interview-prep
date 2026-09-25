# Window Functions Cheatsheet

> Window functions là dạng câu hỏi phổ biến nhất trong phỏng vấn Data Analyst từ 2020 trở đi. Nắm chắc file này là bạn xử lý được gần hết.

---

## 1. Cú pháp tổng quát

```sql
<function>() OVER (
    [PARTITION BY col1, col2]
    [ORDER BY col3 [ASC|DESC]]
    [ROWS|RANGE BETWEEN <start> AND <end>]
)
```

**3 thành phần:**

| Thành phần | Ý nghĩa | Bắt buộc? |
|---|---|---|
| `PARTITION BY` | Chia dữ liệu thành nhóm con | Không — nếu bỏ, window = toàn bảng |
| `ORDER BY` | Sắp xếp trong mỗi nhóm | Không — nhưng bắt buộc cho ranking/LAG |
| `ROWS/RANGE` | Cửa sổ trượt (frame) | Không — mặc định tùy function |

---

## 2. Ranking Functions — so sánh

Giả sử có dãy salary: **100, 100, 90, 80**

| Function | Kết quả | Quy tắc |
|---|---|---|
| `ROW_NUMBER()` | 1, 2, 3, 4 | Số thứ tự duy nhất, không trùng |
| `RANK()` | 1, 1, 3, 4 | Cùng giá trị -> cùng rank, **có khoảng trống** |
| `DENSE_RANK()` | 1, 1, 2, 3 | Cùng giá trị -> cùng rank, **không khoảng trống** |
| `NTILE(n)` | Chia thành n nhóm đều | Ví dụ NTILE(4) -> 1, 1, 2, 2 (với 4 dòng) |
| `PERCENT_RANK()` | (rank - 1) / (total - 1) | Giá trị từ 0 -> 1 |
| `CUME_DIST()` | Số dòng <= giá trị hiện tại / tổng | Giá trị từ 0 -> 1 |

### Ví dụ so sánh

```sql
SELECT
    employee_id,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
    RANK()       OVER (ORDER BY salary DESC) AS rnk,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk,
    NTILE(3)     OVER (ORDER BY salary DESC) AS tertile
FROM Employee;
```

Kết quả với salary: 500k, 500k, 300k, 200k, 100k:

| salary | row_num | rnk | dense_rnk | tertile |
|---|---|---|---|---|
| 500k | 1 | 1 | 1 | 1 |
| 500k | 2 | 1 | 1 | 1 |
| 300k | 3 | 3 | 2 | 2 |
| 200k | 4 | 4 | 3 | 2 |
| 100k | 5 | 5 | 4 | 3 |

**Khi nào dùng cái nào?**
- **ROW_NUMBER**: cần đúng 1 dòng mỗi nhóm (dù có trùng).
- **RANK**: cần xếp hạng kiểu thể thao (nhì đồng hạng -> người tiếp theo là 4).
- **DENSE_RANK**: cần xếp hạng không có khoảng trống (nhì đồng hạng -> người tiếp theo là 3).
- **NTILE**: chia thành n nhóm đều (phân tứ phân vị, tam phân vị).

---

## 3. Analytic Functions — LAG / LEAD / FIRST / LAST / NTH

| Function | Trả về |
|---|---|
| `LAG(col, offset, default)` | Giá trị dòng **trước** |
| `LEAD(col, offset, default)` | Giá trị dòng **sau** |
| `FIRST_VALUE(col)` | Giá trị **đầu tiên** trong window |
| `LAST_VALUE(col)` | Giá trị **cuối cùng** trong window |
| `NTH_VALUE(col, n)` | Giá trị **thứ n** trong window |

### Ví dụ LAG/LEAD

```sql
SELECT
    month,
    revenue,
    LAG(revenue)  OVER (ORDER BY month) AS prev_month,
    LEAD(revenue) OVER (ORDER BY month) AS next_month,
    revenue - LAG(revenue) OVER (ORDER BY month) AS diff,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
        2
    ) AS pct_change
FROM monthly_sales;
```

### Lưu ý `LAST_VALUE` — bẫy thường gặp

`LAST_VALUE` mặc định trả về giá trị **dòng cuối của frame hiện tại**, không phải dòng cuối cả window.

```sql
-- Sai: LAST_VALUE trả về chính dòng hiện tại
SELECT
    month, revenue,
    LAST_VALUE(revenue) OVER (ORDER BY month) AS last_rev
FROM monthly_sales;

-- Đúng: mở rộng frame đến cuối
SELECT
    month, revenue,
    LAST_VALUE(revenue) OVER (
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_rev
FROM monthly_sales;
```

---

## 4. Aggregate Functions dùng như window

`SUM`, `AVG`, `COUNT`, `MIN`, `MAX` thêm `OVER()` là thành window.

### 4.1. Running total

```sql
SELECT
    order_date,
    amount,
    SUM(amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM orders;
```

### 4.2. Moving average 3 kỳ

```sql
SELECT
    month,
    revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3
FROM monthly_sales;
```

### 4.3. % so với tổng

```sql
SELECT
    department, salary,
    ROUND(salary * 100.0 / SUM(salary) OVER (), 2) AS pct_of_total
FROM Employee;
```

### 4.4. % so với nhóm

```sql
SELECT
    department, salary,
    ROUND(salary * 100.0 / SUM(salary) OVER (PARTITION BY department), 2) AS pct_of_dept
FROM Employee;
```

---

## 5. Frame Clauses — ROWS vs RANGE

| Frame | Ý nghĩa |
|---|---|
| `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | Từ đầu đến dòng hiện tại (running total) |
| `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` | 3 dòng: 2 trước + hiện tại (moving avg 3) |
| `ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING` | 3 dòng: trước + hiện tại + sau |
| `ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING` | Từ hiện tại đến cuối |
| `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` | Toàn bộ window |

### ROWS vs RANGE — khác biệt

- **ROWS**: đếm theo **số dòng vật lý**.
- **RANGE**: theo **giá trị** của cột ORDER BY.

```sql
-- ROWS: 3 dòng cụ thể
SUM(x) OVER (ORDER BY d ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)

-- RANGE: các dòng có giá trị d trong khoảng [d-2, d]
SUM(x) OVER (ORDER BY d RANGE BETWEEN 2 PRECEDING AND CURRENT ROW)
```

**Mặc định**: nếu có ORDER BY mà không ghi frame -> mặc định là `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

**Khuyến nghị**: luôn ghi rõ frame để tránh nhầm.

---

## 6. 12 mẫu câu hỏi phỏng vấn thường gặp

### Mẫu 1 — Top N mỗi nhóm

```sql
SELECT * FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
    FROM products
) t
WHERE rn <= 3;
```

### Mẫu 2 — Tìm bản ghi mới nhất mỗi user

```sql
SELECT * FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY event_time DESC) AS rn
    FROM events
) t
WHERE rn = 1;
```

### Mẫu 3 — Xếp hạng trong nhóm

```sql
SELECT
    employee_id, department, salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk
FROM Employee;
```

### Mẫu 4 — So sánh kỳ trước

```sql
SELECT
    month, revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
    revenue - LAG(revenue) OVER (ORDER BY month) AS diff
FROM monthly_sales;
```

### Mẫu 5 — Running total

```sql
SELECT
    order_date, amount,
    SUM(amount) OVER (ORDER BY order_date) AS running_total
FROM orders;
```

### Mẫu 6 — Moving average

```sql
SELECT
    date, price,
    AVG(price) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ma_7
FROM stock_prices;
```

### Mẫu 7 — Tỷ lệ % của nhóm

```sql
SELECT
    department, salary,
    ROUND(salary * 100.0 / SUM(salary) OVER (PARTITION BY department), 2) AS pct
FROM Employee;
```

### Mẫu 8 — Phát hiện dòng trùng

```sql
SELECT * FROM (
    SELECT *,
           COUNT(*) OVER (PARTITION BY email) AS cnt
    FROM users
) t
WHERE cnt > 1;
```

### Mẫu 9 — Chia nhóm theo tứ phân vị

```sql
SELECT
    customer_id, total_spent,
    NTILE(4) OVER (ORDER BY total_spent DESC) AS quartile
FROM customer_totals;
```

### Mẫu 10 — Khoảng cách giữa 2 sự kiện

```sql
SELECT
    user_id, event_time,
    DATEDIFF(
        event_time,
        LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time)
    ) AS days_since_prev
FROM events;
```

### Mẫu 11 — Đếm lũy tiến

```sql
SELECT
    user_id, event_date,
    COUNT(*) OVER (PARTITION BY user_id ORDER BY event_date) AS nth_event
FROM events;
```

### Mẫu 12 — First/Last value mỗi nhóm

```sql
SELECT DISTINCT
    user_id,
    FIRST_VALUE(product) OVER (
        PARTITION BY user_id ORDER BY purchase_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_product,
    LAST_VALUE(product) OVER (
        PARTITION BY user_id ORDER BY purchase_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_product
FROM purchases;
```

---

## 7. Window vs GROUP BY — khi nào dùng cái nào?

| Tình huống | GROUP BY | Window |
|---|---|---|
| Muốn **1 dòng / nhóm** | Co | Khong |
| Muốn **giữ tất cả dòng** + thêm cột tính toán | Khong | Co |
| Tính tổng, đếm theo nhóm | Co | Co |
| Xếp hạng trong nhóm | Khong | Co |
| So sánh với dòng trước/sau | Khong | Co |
| Running total | Khong | Co |

```sql
-- GROUP BY: 3 dòng (1 / phòng)
SELECT department, AVG(salary) FROM Employee GROUP BY department;

-- Window: 8 dòng (giữ chi tiết + thêm cột)
SELECT first_name, department, salary,
       AVG(salary) OVER (PARTITION BY department) AS dept_avg
FROM Employee;
```

---

## 8. Lỗi thường gặp

### Lỗi 1 — Dùng window function trong WHERE

```sql
-- Lỗi
SELECT *, ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn
FROM Employee
WHERE rn <= 3;

-- Đúng: Bọc subquery
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn
    FROM Employee
) t WHERE rn <= 3;
```

### Lỗi 2 — LAG/LEAD không có ORDER BY

```sql
-- Không xác định
LAG(salary) OVER (PARTITION BY dept)

-- Đúng: Có ORDER BY
LAG(salary) OVER (PARTITION BY dept ORDER BY joining_date)
```

### Lỗi 3 — LAST_VALUE không mở rộng frame

Xem mục 3.

### Lỗi 4 — Quên PARTITION khi cần tính theo nhóm

```sql
-- Tính trên toàn bảng
SELECT department, salary, AVG(salary) OVER () AS avg_all
FROM Employee;

-- Tính theo nhóm
SELECT department, salary, AVG(salary) OVER (PARTITION BY department) AS avg_dept
FROM Employee;
```

---

## 9. Hỗ trợ theo hệ CSDL

| Hệ CSDL | Window functions | Ghi chú |
|---|---|---|
| MySQL | 8.0+ | Trước 8.0 không có |
| PostgreSQL | 8.4+ | Đầy đủ nhất |
| SQL Server | 2005+ | Đầy đủ |
| Oracle | 8i+ | Đầy đủ |
| SQLite | 3.25+ | Đầy đủ từ 2018 |
| BigQuery | Co | Đầy đủ |
| Snowflake | Co | Đầy đủ |

---

## 10. Ghi nhớ nhanh

> **"RANK có khoảng trống, DENSE_RANK không.**
> **ROW_NUMBER luôn duy nhất.**
> **LAG nhìn về quá khứ, LEAD nhìn về tương lai.**
> **LAST_VALUE phải mở rộng frame."**
