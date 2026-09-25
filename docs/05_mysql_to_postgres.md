# MySQL ↔ PostgreSQL cheat sheet

> Bảng chuyển đổi đầy đủ giữa MySQL 8.0+ và PostgreSQL 14+. Dùng khi port query hoặc khi phỏng vấn hỏi "làm sao chạy trên cả 2?".

---

## 1. Kiểu dữ liệu

| MySQL | PostgreSQL | Ghi chú |
|---|---|---|
| `INT(11)` | `INTEGER` | MySQL 8 bỏ hiển thị độ rộng |
| `BIGINT(20)` | `BIGINT` | — |
| `TINYINT(1)` | `BOOLEAN` | MySQL dùng TINYINT cho bool |
| `SMALLINT` | `SMALLINT` | — |
| `DECIMAL(10,2)` | `NUMERIC(10,2)` | Tương đương |
| `FLOAT` | `REAL` | — |
| `DOUBLE` | `DOUBLE PRECISION` | — |
| `VARCHAR(255)` | `VARCHAR(255)` | — |
| `TEXT` | `TEXT` | — |
| `DATETIME` | `TIMESTAMP` | PG dùng TIMESTAMP không timezone |
| `TIMESTAMP` | `TIMESTAMPTZ` | PG có timezone |
| `DATE` | `DATE` | — |
| `TIME` | `TIME` | — |
| `YEAR` | `SMALLINT` | PG không có YEAR riêng |
| `JSON` | `JSONB` | PG khuyến nghị JSONB (binary, index được) |
| `ENUM('a','b')` | `CREATE TYPE ... AS ENUM` | PG phải tạo type trước |
| `BLOB` | `BYTEA` | — |
| `AUTO_INCREMENT` | `GENERATED ALWAYS AS IDENTITY` | PG dùng identity |
| `UNSIGNED INT` | `INT CHECK (x >= 0)` | PG không có UNSIGNED |

### Ví dụ chuyển đổi bảng

**MySQL**:
```sql
CREATE TABLE users (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    profile JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**PostgreSQL**:
```sql
CREATE TABLE users (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    profile JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 2. String functions

| MySQL | PostgreSQL |
|---|---|
| `SUBSTRING_INDEX(s, ' ', 1)` | `SPLIT_PART(s, ' ', 1)` |
| `SUBSTRING_INDEX(s, ' ', -1)` | `SPLIT_PART(s, ' ', -1)` |
| `CONCAT(a, b, c)` | `CONCAT(a, b, c)` hoặc `a || b || c` |
| `GROUP_CONCAT(x)` | `STRING_AGG(x, ',')` |
| `GROUP_CONCAT(DISTINCT x ORDER BY x SEPARATOR ',')` | `STRING_AGG(DISTINCT x, ',' ORDER BY x)` |
| `LOCATE(sub, s)` | `POSITION(sub IN s)` hoặc `STRPOS(s, sub)` |
| `LPAD(s, n, c)` | `LPAD(s, n, c)` |
| `RPAD(s, n, c)` | `RPAD(s, n, c)` |
| `TRIM(s)` | `TRIM(s)` |
| `LTRIM(s)` | `LTRIM(s)` |
| `RTRIM(s)` | `RTRIM(s)` |
| `LEFT(s, n)` | `LEFT(s, n)` |
| `RIGHT(s, n)` | `RIGHT(s, n)` |
| `CHAR_LENGTH(s)` | `LENGTH(s)` |
| `OCTET_LENGTH(s)` | `OCTET_LENGTH(s)` |
| `UPPER(s)` | `UPPER(s)` |
| `LOWER(s)` | `LOWER(s)` |
| `REPLACE(s, a, b)` | `REPLACE(s, a, b)` |
| `REPEAT(s, n)` | `REPEAT(s, n)` |
| `REVERSE(s)` | `REVERSE(s)` |
| `s REGEXP pattern` | `s ~ pattern` (POSIX) |
| `s RLIKE pattern` | `s ~ pattern` |
| `s NOT REGEXP pattern` | `s !~ pattern` |

### Ví dụ chuyển đổi

```sql
-- MySQL: tách first name
SELECT SUBSTRING_INDEX(full_name, ' ', 1) FROM users;

-- PostgreSQL
SELECT SPLIT_PART(full_name, ' ', 1) FROM users;
```

```sql
-- MySQL: gộp tên sản phẩm
SELECT category, GROUP_CONCAT(product_name SEPARATOR ', ') FROM products GROUP BY category;

-- PostgreSQL
SELECT category, STRING_AGG(product_name, ', ') FROM products GROUP BY category;
```

---

## 3. Date / time functions

| MySQL | PostgreSQL |
|---|---|
| `CURDATE()` | `CURRENT_DATE` |
| `CURTIME()` | `CURRENT_TIME` |
| `NOW()` | `NOW()` hoặc `CURRENT_TIMESTAMP` |
| `SYSDATE()` | `CLOCK_TIMESTAMP()` |
| `DATE_SUB(d, INTERVAL 30 DAY)` | `d - INTERVAL '30 days'` |
| `DATE_ADD(d, INTERVAL 1 MONTH)` | `d + INTERVAL '1 month'` |
| `DATE_ADD(d, INTERVAL 1 HOUR)` | `d + INTERVAL '1 hour'` |
| `DATEDIFF(d1, d2)` | `d1 - d2` (trả về integer ngày) |
| `TIMESTAMPDIFF(SECOND, d1, d2)` | `EXTRACT(EPOCH FROM (d2 - d1))::INT` |
| `TIMESTAMPDIFF(DAY, d1, d2)` | `EXTRACT(DAY FROM (d2 - d1))` hoặc `(d2::date - d1::date)` |
| `YEAR(d)` | `EXTRACT(YEAR FROM d)` |
| `MONTH(d)` | `EXTRACT(MONTH FROM d)` |
| `DAY(d)` | `EXTRACT(DAY FROM d)` |
| `HOUR(d)` | `EXTRACT(HOUR FROM d)` |
| `MINUTE(d)` | `EXTRACT(MINUTE FROM d)` |
| `SECOND(d)` | `EXTRACT(SECOND FROM d)` |
| `DAYOFWEEK(d)` | `EXTRACT(DOW FROM d)` (0=CN) |
| `WEEKDAY(d)` | `EXTRACT(ISODOW FROM d)` (1=T2) |
| `WEEK(d)` | `EXTRACT(WEEK FROM d)` |
| `LAST_DAY(d)` | `(DATE_TRUNC('month', d) + INTERVAL '1 month' - INTERVAL '1 day')::DATE` |
| `DATE_FORMAT(d, '%Y-%m-%d')` | `TO_CHAR(d, 'YYYY-MM-DD')` |
| `STR_TO_DATE(s, '%Y-%m-%d')` | `TO_DATE(s, 'YYYY-MM-DD')` |
| `UNIX_TIMESTAMP(d)` | `EXTRACT(EPOCH FROM d)::BIGINT` |
| `FROM_UNIXTIME(ts)` | `TO_TIMESTAMP(ts)` |

### Ví dụ chuyển đổi

```sql
-- MySQL: login trong 30 ngày gần nhất
WHERE login_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

-- PostgreSQL
WHERE login_time >= CURRENT_DATE - INTERVAL '30 days'
```

```sql
-- MySQL: format theo năm-tháng
SELECT DATE_FORMAT(order_date, '%Y-%m') FROM orders;

-- PostgreSQL
SELECT TO_CHAR(order_date, 'YYYY-MM') FROM orders;
```

```sql
-- MySQL: thêm 1 giờ
SELECT DATE_ADD(created_at, INTERVAL 1 HOUR);

-- PostgreSQL
SELECT created_at + INTERVAL '1 hour';
```

---

## 4. NULL & Logic functions

| MySQL | PostgreSQL |
|---|---|
| `IFNULL(x, y)` | `COALESCE(x, y)` |
| `COALESCE(x, y, z)` | `COALESCE(x, y, z)` |
| `NULLIF(a, b)` | `NULLIF(a, b)` |
| `x IS NULL` | `x IS NULL` |
| `x <=> y` (null-safe equal) | `x IS NOT DISTINCT FROM y` |
| `IF(cond, a, b)` | `CASE WHEN cond THEN a ELSE b END` |

---

## 5. JSON functions

| Thao tác | MySQL | PostgreSQL (JSONB) |
|---|---|---|
| Trích xuất thuộc tính | `JSON_EXTRACT(j, '$.name')` hoặc `j->'$.name'` | `j->>'name'` |
| Trích xuất mảng | `JSON_EXTRACT(j, '$[0]')` | `j->0` |
| Mở rộng JSON thành dòng | `JSON_TABLE(...)` | `jsonb_to_recordset()` / `jsonb_array_elements()` |
| Kiểm tra key tồn tại | `JSON_CONTAINS_PATH(j, 'one', '$.key')` | `j ? 'key'` |
| Tạo JSON Object | `JSON_OBJECT('k', v)` | `jsonb_build_object('k', v)` |
| Tạo JSON Array | `JSON_ARRAY(a, b)` | `jsonb_build_array(a, b)` |

---

## 6. Cú pháp & Quy tắc phân trang (Pagination)

| Thao tác | MySQL | PostgreSQL |
|---|---|---|
| Phân trang (Top N) | `LIMIT 10 OFFSET 20` hoặc `LIMIT 20, 10` | `LIMIT 10 OFFSET 20` |
| Đệ quy CTE | `WITH RECURSIVE` (Cần CAST ép kiểu chuỗi) | `WITH RECURSIVE` (Hỗ trợ `::TEXT` linh hoạt) |
| Case Sensitivity | Mặc định case-insensitive tùy OS | Tên bảng & cột mặc định lowercase ngoại trừ dùng `"Quotes"` |
| Tập hợp (Set Operations) | `UNION`, `UNION ALL` | `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT` |

---

## 7. Ghi nhớ nhanh

> **"PostgreSQL dùng COALESCE thay IFNULL, dùng STRING_AGG thay GROUP_CONCAT, dùng SPLIT_PART thay SUBSTRING_INDEX, và dùng IS NOT DISTINCT FROM thay <=>"**
