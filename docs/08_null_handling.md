# NULL Handling — Xử lý NULL trong SQL

> NULL là nguồn bug phổ biến nhất trong SQL. Hiểu đúng về NULL là điều kiện bắt buộc để viết query đúng.

---

## 1. NULL là gì?

NULL **không phải** là:
- Số 0
- Chuỗi rỗng `''`
- Chuỗi `'NULL'`
- `FALSE`

NULL là **"không biết"** — giá trị chưa xác định hoặc không tồn tại.

### 3-valued logic

SQL dùng logic 3 giá trị: **TRUE**, **FALSE**, **UNKNOWN**.

| A | B | A AND B | A OR B |
|---|---|---|---|
| TRUE | TRUE | TRUE | TRUE |
| TRUE | FALSE | FALSE | TRUE |
| TRUE | NULL | **UNKNOWN** | TRUE |
| FALSE | FALSE | FALSE | FALSE |
| FALSE | NULL | FALSE | **UNKNOWN** |
| NULL | NULL | **UNKNOWN** | **UNKNOWN** |

**Hệ quả**: WHERE chỉ giữ dòng có kết quả **TRUE**. Dòng có kết quả UNKNOWN bị loại.

---

## 2. So sánh với NULL

### 2.1. Không dùng `=`, `<>` với NULL

```sql
-- Lỗi: Không bao giờ match
SELECT * FROM Employee WHERE manager_id = NULL;
SELECT * FROM Employee WHERE manager_id <> NULL;

-- Đúng: Dùng IS NULL / IS NOT NULL
SELECT * FROM Employee WHERE manager_id IS NULL;
SELECT * FROM Employee WHERE manager_id IS NOT NULL;
```

### 2.2. NULL trong NOT IN

```sql
-- Nếu bất kỳ giá trị nào trong list là NULL -> kết quả rỗng
SELECT * FROM Employee
WHERE employee_id NOT IN (1, 2, NULL);
-- Tương đương: id <> 1 AND id <> 2 AND id <> NULL
-- = ... AND UNKNOWN
-- = UNKNOWN cho mọi dòng -> không dòng nào match

-- Đúng: Dùng NOT EXISTS
SELECT e.* FROM Employee e
WHERE NOT EXISTS (
    SELECT 1 FROM Bonus b WHERE b.employee_ref_id = e.employee_id
);
```

---

## 3. NULL trong aggregate functions

### 3.1. Hầu hết aggregate bỏ qua NULL

```sql
-- Bảng: [1, 2, NULL, 4]
SELECT
    COUNT(*)         AS total,      -- 4 (đếm cả NULL)
    COUNT(col)       AS non_null,   -- 3 (bỏ NULL)
    SUM(col)         AS sum,        -- 7
    AVG(col)         AS avg,        -- 2.33 (7/3, không phải 7/4!)
    MIN(col)         AS min,        -- 1
    MAX(col)         AS max;        -- 4
```

**Lưu ý**: `AVG(col)` chia cho **số dòng non-NULL**, không phải tổng dòng.

### 3.2. COUNT(*) vs COUNT(col)

```sql
-- Đếm tất cả dòng (kể cả NULL)
SELECT COUNT(*) FROM Employee;

-- Đếm dòng có manager_id != NULL
SELECT COUNT(manager_id) FROM Employee;

-- Đếm dòng có manager_id NULL
SELECT COUNT(*) - COUNT(manager_id) FROM Employee;
-- hoặc
SELECT COUNT(*) FROM Employee WHERE manager_id IS NULL;
```

### 3.3. SUM của toàn NULL

```sql
-- Bảng: [NULL, NULL]
SELECT SUM(col) FROM t;   -- NULL (không phải 0)
SELECT AVG(col) FROM t;   -- NULL
SELECT MIN(col) FROM t;   -- NULL
SELECT MAX(col) FROM t;   -- NULL
SELECT COUNT(col) FROM t; -- 0
SELECT COUNT(*) FROM t;   -- 2
```

**Hệ quả**: nếu cần 0 thay vì NULL:

```sql
SELECT COALESCE(SUM(col), 0) FROM t;
```

---

## 4. NULL trong phép toán

Bất kỳ phép toán nào với NULL -> NULL.

```sql
SELECT
    1 + NULL,           -- NULL
    'a' || NULL,        -- NULL (PostgreSQL)
    CONCAT('a', NULL),  -- 'a' (MySQL) — khác PG!
    NULL * 0,           -- NULL (không phải 0!)
    NULL = NULL,        -- NULL (không phải TRUE)
    NULL <> NULL,       -- NULL
    NULL AND TRUE,      -- NULL
    NULL OR TRUE;       -- TRUE
```

**Khác biệt MySQL vs PostgreSQL**:

```sql
-- MySQL
SELECT CONCAT('a', NULL);   -- 'a'

-- PostgreSQL
SELECT 'a' || NULL;         -- NULL
SELECT CONCAT('a', NULL);   -- 'a' (CONCAT bỏ qua NULL)
```

---

## 5. Xử lý NULL — 4 hàm chính

### 5.1. COALESCE — trả về giá trị non-NULL đầu tiên

```sql
SELECT COALESCE(bonus, 0) FROM Employee;
SELECT COALESCE(phone, email, 'unknown') FROM users;
```

**Chuẩn SQL, dùng được trên mọi hệ CSDL.**

### 5.2. IFNULL — chỉ MySQL

```sql
SELECT IFNULL(bonus, 0) FROM Employee;
-- Tương đương COALESCE(bonus, 0)
```

### 5.3. NULLIF — trả về NULL nếu 2 giá trị bằng nhau

```sql
-- Tránh chia cho 0
SELECT clicks / NULLIF(impressions, 0) AS ctr FROM stats;

-- Đổi 'N/A' thành NULL
SELECT NULLIF(status, 'N/A') FROM orders;
```

### 5.4. ISNULL — SQL Server

```sql
SELECT ISNULL(bonus, 0) FROM Employee;
```

### Bảng so sánh

| Hàm | MySQL | PostgreSQL | SQL Server | Chuẩn SQL |
|---|---|---|---|---|
| `COALESCE(a, b)` | Co | Co | Co | Co |
| `IFNULL(a, b)` | Co | Khong | Khong | Khong |
| `ISNULL(a, b)` | Khong | Khong | Co | Khong |
| `NULLIF(a, b)` | Co | Co | Co | Co |

**Khuyến nghị**: dùng `COALESCE` và `NULLIF` — portable mọi hệ CSDL.

---

## 6. NULL trong JOIN

### 6.1. NULL không match NULL

```sql
-- Dòng có col = NULL ở cả 2 bảng sẽ không match (Lỗi)
SELECT * FROM a JOIN b ON a.col = b.col;

-- Dùng IS NOT DISTINCT FROM (PostgreSQL) (Đúng)
SELECT * FROM a JOIN b ON a.col IS NOT DISTINCT FROM b.col;

-- Hoặc COALESCE
SELECT * FROM a JOIN b ON COALESCE(a.col, '') = COALESCE(b.col, '');
```

### 6.2. LEFT JOIN giữ NULL

```sql
-- Dòng không khớp bên phải -> cột bên phải NULL
SELECT e.first_name, b.bonus_amount
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id;
-- Nhân viên không có bonus -> bonus_amount = NULL
```

---

## 7. NULL trong GROUP BY / DISTINCT / ORDER BY

### 7.1. GROUP BY — NULL là 1 nhóm riêng

```sql
-- Bảng: [1, NULL, 1, NULL, 2]
SELECT col, COUNT(*) FROM t GROUP BY col;

-- Kết quả:
-- col = 1    -> 2
-- col = NULL -> 2
-- col = 2    -> 1
```

NULL được nhóm chung thành 1 nhóm.

### 7.2. DISTINCT — NULL là 1 giá trị

```sql
SELECT DISTINCT col FROM t;
-- [1, NULL, 2] — NULL xuất hiện 1 lần
```

### 7.3. ORDER BY — NULL ở đâu?

| Hệ CSDL | NULL ở đâu |
|---|---|
| MySQL | Đầu (ASC), cuối (DESC) |
| PostgreSQL | Cuối (ASC), đầu (DESC) |
| SQL Server | Đầu (ASC) |
| Oracle | Cuối (ASC) |

**Khuyến nghị**: chỉ định rõ:

```sql
-- NULL luôn ở cuối
ORDER BY col ASC NULLS LAST;

-- NULL luôn ở đầu
ORDER BY col ASC NULLS FIRST;

-- Portable
ORDER BY col IS NULL, col;
```

---

## 8. NULL trong CASE

```sql
-- CASE coi NULL như "không match" trong WHEN
SELECT
    CASE
        WHEN col = 1 THEN 'one'
        WHEN col IS NULL THEN 'null'
        ELSE 'other'
    END
FROM t;
```

**Lưu ý**: `WHEN col = NULL` **không bao giờ** match. Phải dùng `WHEN col IS NULL`.

---

## 9. NULL trong UNIQUE constraint

### MySQL / PostgreSQL

Cho phép **nhiều NULL** trong cột UNIQUE:

```sql
CREATE TABLE t (email VARCHAR(100) UNIQUE);
INSERT INTO t VALUES (NULL);   -- OK
INSERT INTO t VALUES (NULL);   -- OK
INSERT INTO t VALUES (NULL);   -- OK
-- 3 dòng NULL — không vi phạm UNIQUE
```

**Hệ quả**: nếu cần "unique nhưng cho phép NULL 1 lần" -> phải dùng partial index.

```sql
-- PostgreSQL
CREATE UNIQUE INDEX idx_email ON t(email) WHERE email IS NOT NULL;
```

### SQL Server

Chỉ cho phép **1 NULL** trong cột UNIQUE.

---

## 10. NULL trong CHECK constraint

```sql
CREATE TABLE t (
    age INT CHECK (age >= 0)
);

INSERT INTO t VALUES (5);     -- OK
INSERT INTO t VALUES (NULL);  -- OK (NULL không vi phạm CHECK)
INSERT INTO t VALUES (-1);    -- Lỗi
```

**Lưu ý**: CHECK constraint coi NULL là hợp lệ (vì NULL >= 0 = UNKNOWN, không phải FALSE).

Nếu muốn chặn NULL:

```sql
CREATE TABLE t (
    age INT NOT NULL CHECK (age >= 0)
);
```

---

## 11. NULL trong NOT NULL constraint

```sql
CREATE TABLE t (
    id INT NOT NULL,
    name VARCHAR(100) NOT NULL
);

INSERT INTO t (id, name) VALUES (1, NULL);  -- Lỗi
```

**Best practice**: cột không nên NULL -> thêm `NOT NULL` + `DEFAULT`.

---

## 12. NULL và DEFAULT

```sql
CREATE TABLE t (
    status VARCHAR(20) DEFAULT 'pending'
);

-- Nếu insert không đề cập status -> 'pending'
INSERT INTO t (id) VALUES (1);

-- Nếu insert NULL tường minh -> NULL (không dùng default)
INSERT INTO t (id, status) VALUES (2, NULL);
```

---

## 13. NULL trong string concatenation

```sql
-- MySQL: CONCAT bỏ qua NULL
SELECT CONCAT('Hello', NULL, 'World');  -- 'HelloWorld'

-- PostgreSQL: || trả về NULL
SELECT 'Hello' || NULL || 'World';      -- NULL

-- PostgreSQL: CONCAT bỏ qua NULL
SELECT CONCAT('Hello', NULL, 'World');  -- 'HelloWorld'
```

**Khuyến nghị**: dùng `COALESCE` trước khi concat.

```sql
SELECT first_name || ' ' || COALESCE(middle_name, '') || ' ' || last_name
FROM users;
```

---

## 14. NULL trong comparison operators

| Phép so sánh | Kết quả |
|---|---|
| `NULL = NULL` | NULL |
| `NULL <> NULL` | NULL |
| `NULL > 5` | NULL |
| `NULL BETWEEN 1 AND 10` | NULL |
| `NULL IN (1, 2, 3)` | NULL |
| `NULL LIKE '%a%'` | NULL |

**Hệ quả**: mọi filter với NULL -> dòng bị loại.

---

## 15. NULL-safe comparison — bảng tổng hợp

| Cách | MySQL | PostgreSQL | SQL Server | Chuẩn |
|---|---|---|---|---|
| `a = b` | NULL nếu có NULL | NULL | NULL | NULL |
| `a <=> b` | Co (NULL-safe) | Khong | Khong | Khong |
| `a IS NOT DISTINCT FROM b` | Khong | Co | Co | Co |
| `COALESCE(a, '') = COALESCE(b, '')` | Co | Co | Co | Co |

---

## 16. Ví dụ thực tế — Đếm user có / không có bonus

```sql
-- Bảng Bonus có thể có nhiều bonus / employee
-- Đếm:
--   - Số employee có ít nhất 1 bonus
--   - Số employee không có bonus nào

SELECT
    COUNT(DISTINCT CASE WHEN b.employee_ref_id IS NOT NULL THEN e.employee_id END) AS has_bonus,
    COUNT(DISTINCT CASE WHEN b.employee_ref_id IS NULL THEN e.employee_id END)     AS no_bonus
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id;
```

---

## 17. Ví dụ thực tế — Tính CTR an toàn

```sql
-- CTR = clicks / impressions
-- Nếu impressions = 0 -> chia cho 0
-- Nếu impressions NULL -> kết quả NULL

SELECT
    app_id,
    COALESCE(
        SUM(CASE WHEN type = 'click' THEN 1 ELSE 0 END) * 1.0
        / NULLIF(SUM(CASE WHEN type = 'impression' THEN 1 ELSE 0 END), 0),
        0
    ) AS ctr
FROM dialoglog
GROUP BY app_id;
```

**Giải thích**:
- `NULLIF(x, 0)` -> NULL nếu x = 0, tránh chia cho 0.
- `COALESCE(..., 0)` -> đổi NULL thành 0 nếu không có impression.

---

## 18. Checklist xử lý NULL

Khi viết query, tự hỏi:

- [ ] Cột có thể NULL không? -> dùng `IS NULL` / `IS NOT NULL`.
- [ ] Phép so sánh có thể gặp NULL không? -> dùng `COALESCE`.
- [ ] `NOT IN` có subquery có NULL không? -> đổi `NOT EXISTS`.
- [ ] `COUNT(*)` hay `COUNT(col)` — cái nào đúng ý?
- [ ] `SUM` / `AVG` có thể gặp toàn NULL không? -> dùng `COALESCE`.
- [ ] Chia cho cột có thể = 0 hoặc NULL? -> dùng `NULLIF`.
- [ ] JOIN có thể match NULL không? -> dùng `IS NOT DISTINCT FROM`.
- [ ] ORDER BY có NULL không? -> chỉ định `NULLS FIRST` / `NULLS LAST`.
- [ ] String concat với cột có thể NULL? -> dùng `COALESCE`.
- [ ] CASE có `WHEN col = NULL` không? -> đổi `WHEN col IS NULL`.

---

## 19. Ghi nhớ nhanh

> **"NULL = NULL -> NULL, không phải TRUE."**
> **"NOT IN + NULL = rỗng -> NOT EXISTS."**
> **"COUNT(*) đếm cả NULL, COUNT(col) bỏ NULL."**
> **"SUM toàn NULL = NULL, không phải 0 -> COALESCE."**
> **"Chia cho 0 -> NULLIF."**
> **"AVG chia cho số non-NULL, không phải tổng."**
> **"ORDER BY NULL: chỉ định NULLS FIRST / LAST."**
