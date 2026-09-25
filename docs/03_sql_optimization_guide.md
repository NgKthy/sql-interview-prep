# SQL Optimization Guide

> Query chạy đúng chưa đủ — phải chạy **nhanh**. File này tổng hợp các kỹ thuật tối ưu và anti-patterns phổ biến.

---

## 1. Đọc Execution Plan với EXPLAIN

### 1.1. EXPLAIN cơ bản

```sql
EXPLAIN
SELECT * FROM Employee WHERE department = 'Admin';
```

Kết quả có các cột quan trọng:

| Cột | Ý nghĩa |
|---|---|
| `type` | Cách truy cập bảng (xem bảng dưới) |
| `possible_keys` | Index có thể dùng |
| `key` | Index thực tế dùng |
| `rows` | Số dòng ước tính phải scan |
| `filtered` | % dòng giữ lại sau WHERE |
| `Extra` | Thông tin thêm (Using filesort, temporary...) |

### 1.2. Thứ tự `type` từ tốt -> tệ

```
const  -> eq_ref -> ref -> range -> index -> ALL
(tốt)                                  (tệ)
```

| Type | Ý nghĩa |
|---|---|
| `system` | Bảng chỉ có 1 dòng |
| `const` | Khớp đúng 1 dòng qua PRIMARY/UNIQUE |
| `eq_ref` | JOIN 1-1 qua PRIMARY/UNIQUE |
| `ref` | JOIN qua index không unique |
| `range` | WHERE dùng index với khoảng (`>`, `<`, `BETWEEN`) |
| `index` | Scan toàn bộ index (không dùng để filter) |
| `ALL` | **Full table scan — tệ nhất** |

### 1.3. EXPLAIN ANALYZE — chạy thật và đo thời gian

```sql
EXPLAIN ANALYZE
SELECT department, COUNT(*)
FROM Employee
GROUP BY department;
```

Khác `EXPLAIN`: **thực sự chạy query** và hiển thị thời gian thật từng bước.

### 1.4. EXPLAIN FORMAT=JSON

```sql
EXPLAIN FORMAT=JSON
SELECT e.first_name, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id
WHERE e.department = 'Admin';
```

Cho chi tiết sâu hơn (cost, used_columns, attached_condition).

### 1.5. Extra — các cảnh báo

| Extra | Ý nghĩa | Xử lý |
|---|---|---|
| `Using filesort` | Sort không dùng index | Thêm index cho ORDER BY |
| `Using temporary` | Tạo bảng tạm | Thường do GROUP BY không index |
| `Using where` | Lọc sau khi scan | Bình thường |
| `Using index` | Covering index | Tốt |
| `Using index condition` | Index condition pushdown | Tốt |
| `Using join buffer` | JOIN không có index | Thêm index cho cột JOIN |

---

## 2. Index — khi nào và cách tạo

### 2.1. Index đơn

```sql
CREATE INDEX idx_employee_department ON Employee(department);
```

**Dùng khi**: WHERE, JOIN, ORDER BY thường xuyên trên 1 cột.

### 2.2. Composite index (index nhiều cột)

```sql
CREATE INDEX idx_employee_dept_salary ON Employee(department, salary);
```

**Quy tắc prefix**: index dùng được cho các query bắt đầu bằng **cột đầu tiên**:

| Query | Dùng được index? |
|---|---|
| `WHERE department = 'X'` | Có |
| `WHERE department = 'X' AND salary > 1000` | Có |
| `WHERE salary > 1000` | Không (thiếu prefix) |
| `WHERE salary > 1000 AND department = 'X'` | Có (optimizer tự sắp) |

**Quy tắc chọn thứ tự cột**: 
1. Cột trong WHERE đẳng thức (`=`) trước.
2. Cột trong ORDER BY / range sau.
3. Cột có cardinality cao (nhiều giá trị khác nhau) trước.

### 2.3. Covering index

Index chứa **hết các cột cần thiết** -> query không cần đọc bảng.

```sql
CREATE INDEX idx_covering ON Employee(department, employee_id, first_name, last_name);

-- Query này chỉ đọc index, không đọc bảng
EXPLAIN
SELECT employee_id, first_name, last_name
FROM Employee
WHERE department = 'Admin';
-- Extra: Using index  <- dấu hiệu covering index hoạt động
```

### 2.4. Index cho JOIN

Foreign key **không tự động có index** ở một số hệ CSDL (MySQL InnoDB tự động, PostgreSQL thì không).

```sql
CREATE INDEX idx_bonus_emp_ref ON Bonus(employee_ref_id);
```

### 2.5. Index cho ORDER BY

```sql
CREATE INDEX idx_employee_salary_desc ON Employee(salary DESC);
```

Nếu không có index, `ORDER BY ... LIMIT` sẽ dùng **filesort** — chậm với bảng lớn.

### 2.6. Partial index (PostgreSQL, SQL Server)

Chỉ index một phần dữ liệu — tiết kiệm dung lượng, nhanh hơn.

```sql
-- PostgreSQL
CREATE INDEX idx_active_users ON users(email) WHERE status = 'active';
```

### 2.7. Khi nào **không** nên tạo index?

- Cột ít được dùng trong WHERE/JOIN.
- Bảng nhỏ (< 1000 dòng) — full scan còn nhanh hơn.
- Cột có cardinality thấp (ví dụ: `gender` với 2 giá trị).
- Bảng ghi nhiều hơn đọc (INSERT/UPDATE chậm vì phải update index).

### 2.8. Xem và xóa index

```sql
-- Xem index của bảng
SHOW INDEX FROM Employee;

-- Xóa
DROP INDEX idx_employee_department ON Employee;
```

---

## 3. Anti-patterns — viết query chậm

### 3.1. Hàm trên cột trong WHERE -> mất index

```sql
-- Chậm (không dùng được index)
SELECT * FROM Employee WHERE YEAR(joining_date) = 2017;

-- Nhanh (dùng được index)
SELECT * FROM Employee
WHERE joining_date >= '2017-01-01'
  AND joining_date <  '2018-01-01';
```

**Quy tắc**: cột ở **bên trái** của phép so sánh phải là cột **nguyên bản**, không bọc hàm.

Các hàm hay gây lỗi: `YEAR()`, `MONTH()`, `DATE()`, `UPPER()`, `LOWER()`, `SUBSTRING()`.

### 3.2. SELECT * khi chỉ cần vài cột

```sql
-- Chậm (đọc toàn bộ cột)
SELECT * FROM Employee WHERE department = 'Admin';

-- Nhanh hơn (chỉ đọc cột cần)
SELECT employee_id, first_name, last_name
FROM Employee
WHERE department = 'Admin';
```

**Lợi ích**:
- Giảm I/O.
- Có thể dùng covering index.
- Query ổn định khi schema thay đổi.

### 3.3. NOT IN với subquery lớn

```sql
-- Chậm với bảng lớn, và bị NULL ảnh hưởng
SELECT * FROM Employee
WHERE employee_id NOT IN (SELECT employee_ref_id FROM Bonus);

-- Nhanh hơn với LEFT JOIN + IS NULL
SELECT e.*
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
WHERE b.employee_ref_id IS NULL;

-- Nhanh hơn với NOT EXISTS
SELECT * FROM Employee e
WHERE NOT EXISTS (
    SELECT 1 FROM Bonus b WHERE b.employee_ref_id = e.employee_id
);
```

### 3.4. OR trên nhiều cột không index

```sql
-- Chậm
SELECT * FROM Employee
WHERE department = 'Admin' OR salary > 400000;

-- Nhanh hơn nếu cả 2 đều có index
SELECT * FROM Employee WHERE department = 'Admin'
UNION
SELECT * FROM Employee WHERE salary > 400000;
```

### 3.5. LIMIT + OFFSET lớn — phân trang kém

```sql
-- Chậm khi OFFSET lớn (vẫn phải scan OFFSET dòng)
SELECT * FROM Employee ORDER BY employee_id LIMIT 10 OFFSET 1000000;

-- Keyset pagination
SELECT * FROM Employee
WHERE employee_id > 1000000
ORDER BY employee_id
LIMIT 10;
```

### 3.6. JOIN không có index

```sql
-- Full scan cả 2 bảng
SELECT * FROM orders o
JOIN customers c ON o.cust_id = c.id;

-- Tạo index trước
CREATE INDEX idx_orders_cust ON orders(cust_id);
CREATE INDEX idx_customers_id ON customers(id);  -- thường đã có (PK)
```

### 3.7. DISTINCT thay cho GROUP BY không cần thiết

```sql
-- DISTINCT sau JOIN gây sort toàn bộ
SELECT DISTINCT e.department
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id;

-- Dùng EXISTS — không cần DISTINCT
SELECT e.department
FROM Employee e
WHERE EXISTS (
    SELECT 1 FROM Bonus b WHERE b.employee_ref_id = e.employee_id
);
```

### 3.8. Subquery trong SELECT (correlated)

```sql
-- Chạy subquery 1 lần / dòng
SELECT
    e.first_name,
    (SELECT COUNT(*) FROM Bonus b WHERE b.employee_ref_id = e.employee_id) AS num_bonuses
FROM Employee e;

-- Dùng LEFT JOIN + GROUP BY
SELECT e.first_name, COUNT(b.employee_ref_id) AS num_bonuses
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
GROUP BY e.employee_id, e.first_name;
```

### 3.9. UNION thay vì UNION ALL

```sql
-- UNION sort + loại trùng (chậm)
SELECT user_id FROM table_a
UNION
SELECT user_id FROM table_b;

-- UNION ALL nếu biết chắc không trùng
SELECT user_id FROM table_a
UNION ALL
SELECT user_id FROM table_b;
```

### 3.10. LIKE bắt đầu bằng %

```sql
-- Không dùng được index (B-tree)
SELECT * FROM users WHERE email LIKE '%@gmail.com';

-- Dùng được index
SELECT * FROM users WHERE email LIKE 'john%';

-- Nếu thật sự cần full-text: dùng FULLTEXT index (MySQL) hoặc GIN (PostgreSQL)
```

---

## 4. Kỹ thuật tối ưu nâng cao

### 4.1. Materialized view (PostgreSQL)

Lưu kết quả của query phức tạp thành bảng vật lý:

```sql
CREATE MATERIALIZED VIEW mv_dept_stats AS
SELECT department, COUNT(*) AS num, AVG(salary) AS avg_sal
FROM Employee
GROUP BY department;

-- Refresh khi cần
REFRESH MATERIALIZED VIEW mv_dept_stats;
```

### 4.2. Partitioning

Chia bảng lớn thành nhiều phần theo cột (thường là ngày):

```sql
-- MySQL
CREATE TABLE orders (
    order_id INT,
    order_date DATE,
    amount DECIMAL(10,2)
)
PARTITION BY RANGE (YEAR(order_date)) (
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025)
);
```

Query `WHERE order_date >= '2023-01-01'` chỉ scan partition `p2023`, `p2024`.

### 4.3. Query rewrite — tránh self-join không cần thiết

```sql
-- Self-join để tìm nhân viên lương cao hơn manager
SELECT e.first_name
FROM Employee e
JOIN Employee m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;

-- Dùng window function (nếu logic phức tạp hơn)
WITH t AS (
    SELECT
        employee_id, first_name, salary, manager_id,
        FIRST_VALUE(salary) OVER (PARTITION BY manager_id) AS mgr_salary
    FROM Employee
)
SELECT first_name FROM t WHERE salary > mgr_salary;
```

### 4.4. Force index (MySQL) — chỉ khi cần

```sql
SELECT * FROM Employee FORCE INDEX (idx_department) WHERE department = 'Admin';
```

**Hạn chế dùng** — optimizer thường đúng. Chỉ dùng khi chắc chắn optimizer chọn sai.

---

## 5. Công cụ đo performance

### 5.1. MySQL — profiling

```sql
SET profiling = 1;
SELECT ...;  -- query cần đo
SHOW PROFILES;
SHOW PROFILE FOR QUERY 1;
```

### 5.2. MySQL — slow query log

Bật trong `my.cnf`:

```ini
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 1
```

### 5.3. PostgreSQL — EXPLAIN ANALYZE BUFFERS

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...;
```

`BUFFERS` hiển thị số block đọc từ cache / disk.

### 5.4. PostgreSQL — pg_stat_statements

```sql
CREATE EXTENSION pg_stat_statements;

SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

---

## 6. Checklist tối ưu query

Trước khi deploy query lên production, hỏi:

- [ ] WHERE có dùng index không? (`EXPLAIN` -> `type` không phải `ALL`)
- [ ] Có hàm bọc cột trong WHERE không? (nếu có -> sửa)
- [ ] JOIN có index ở cột join không?
- [ ] Có `SELECT *` không cần thiết không?
- [ ] ORDER BY có index không? (tránh `Using filesort`)
- [ ] GROUP BY có index không? (tránh `Using temporary`)
- [ ] LIMIT có ORDER BY không?
- [ ] Có NOT IN với subquery lớn không? -> đổi NOT EXISTS
- [ ] Có OR trên cột không index không? -> đổi UNION
- [ ] Có correlated subquery trong SELECT không? -> đổi JOIN

---

## 7. Ví dụ thực tế — từ 30s xuống 0.1s

### Query gốc (chậm)

```sql
SELECT c.name, COUNT(o.id) AS num_orders
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
WHERE YEAR(o.created_at) = 2023
GROUP BY c.id, c.name
ORDER BY num_orders DESC;
```

**Vấn đề**:
1. `YEAR(o.created_at)` — không dùng được index.
2. `LEFT JOIN` nhưng `WHERE` trên bảng phải -> thực chất là `INNER JOIN`.
3. Không có index trên `orders.customer_id` và `orders.created_at`.

### Query đã tối ưu

```sql
-- Tạo index
CREATE INDEX idx_orders_cust_date ON orders(customer_id, created_at);

-- Sửa query
SELECT c.name, COUNT(o.id) AS num_orders
FROM customers c
JOIN orders o ON c.id = o.customer_id
WHERE o.created_at >= '2023-01-01'
  AND o.created_at <  '2024-01-01'
GROUP BY c.id, c.name
ORDER BY num_orders DESC;
```

**Cải thiện**:
1. Index `(customer_id, created_at)` phục vụ cả JOIN và WHERE.
2. `>=` + `<` thay vì `YEAR()` -> dùng được index.
3. `INNER JOIN` thay vì `LEFT JOIN` -> optimizer rõ ràng hơn.

---

## 8. Ghi nhớ nhanh

> **"Index ở cột, không index ở hàm."**
> **"EXPLAIN trước, sửa sau."**
> **"SELECT * là kẻ thù của covering index."**
> **"NOT IN -> NOT EXISTS."**
> **"LIMIT phải đi kèm ORDER BY."**
