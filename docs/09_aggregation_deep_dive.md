# Aggregation Deep Dive — GROUP BY nâng cao

> Docs 04 chỉ có 1 mẫu COUNT. File này đào sâu GROUP BY, HAVING, ROLLUP, CUBE, GROUPING SETS, FILTER, và các hàm aggregate nâng cao.

---

## 1. GROUP BY — Nhắc lại cơ bản

```sql
SELECT department, COUNT(*) AS num, AVG(salary) AS avg_sal
FROM Employee
GROUP BY department;
```

**Quy tắc**:
- Mọi cột trong SELECT **không phải aggregate** phải có trong GROUP BY.
- Aggregate (COUNT, SUM, AVG, MIN, MAX) không cần GROUP BY.

---

## 2. HAVING — lọc sau group

```sql
SELECT department, COUNT(*) AS num
FROM Employee
GROUP BY department
HAVING COUNT(*) > 1;
```

**Khác WHERE**:

| | WHERE | HAVING |
|---|---|---|
| Chạy khi | Trước GROUP BY | Sau GROUP BY |
| Lọc | Dòng | Nhóm |
| Dùng aggregate | Không | Có |

### Kết hợp WHERE + HAVING

```sql
SELECT department, COUNT(*) AS num
FROM Employee
WHERE salary > 50000       -- lọc dòng trước
GROUP BY department
HAVING COUNT(*) > 1;       -- lọc nhóm sau
```

---

## 3. COUNT — 3 biến thể

```sql
-- COUNT(*): đếm tất cả dòng (kể cả NULL)
SELECT COUNT(*) FROM Employee;

-- COUNT(col): đếm dòng có col != NULL
SELECT COUNT(manager_id) FROM Employee;

-- COUNT(DISTINCT col): đếm giá trị distinct, bỏ NULL
SELECT COUNT(DISTINCT department) FROM Employee;
```

### Ví dụ tổng hợp

```sql
SELECT
    department,
    COUNT(*)                       AS total_rows,
    COUNT(manager_id)              AS has_manager,
    COUNT(DISTINCT manager_id)     AS unique_managers,
    COUNT(DISTINCT salary)         AS unique_salaries
FROM Employee
GROUP BY department;
```

### COUNT với nhiều cột

```sql
-- Đếm cặp distinct (user_id, product_id)
SELECT COUNT(DISTINCT user_id, product_id) FROM orders;

-- PostgreSQL
SELECT COUNT(DISTINCT (user_id, product_id)) FROM orders;
```

---

## 4. SUM / AVG — bẫy NULL

```sql
-- Bảng: [10, 20, NULL, 30]

SELECT
    SUM(col),              -- 60
    AVG(col),              -- 20 (60/3, không phải 60/4)
    SUM(col) / COUNT(*),   -- 15 (60/4) <- nếu muốn chia cho tổng dòng
    SUM(col) / COUNT(col); -- 20 (60/3)
```

**Quy tắc**:
- `AVG(col)` = `SUM(col) / COUNT(col)` — bỏ NULL.
- Nếu muốn `SUM(col) / COUNT(*)` — phải viết tường minh.

---

## 5. GROUP_CONCAT / STRING_AGG — gộp chuỗi

### MySQL

```sql
SELECT
    department,
    GROUP_CONCAT(first_name SEPARATOR ', ') AS names
FROM Employee
GROUP BY department;
```

**Options**: `SEPARATOR`, `DISTINCT`, `ORDER BY`.

```sql
SELECT
    department,
    GROUP_CONCAT(DISTINCT first_name ORDER BY first_name SEPARATOR ', ') AS names
FROM Employee
GROUP BY department;
```

**Lưu ý**: `group_concat_max_len` mặc định 1024 — vượt sẽ bị cắt.

```sql
SET SESSION group_concat_max_len = 1000000;
```

### PostgreSQL

```sql
SELECT
    department,
    STRING_AGG(first_name, ', ' ORDER BY first_name) AS names
FROM Employee
GROUP BY department;
```

### SQL Server (2017+)

```sql
SELECT
    department,
    STRING_AGG(first_name, ', ') WITHIN GROUP (ORDER BY first_name) AS names
FROM Employee
GROUP BY department;
```

### Bảng so sánh

| Hệ CSDL | Hàm |
|---|---|
| MySQL | `GROUP_CONCAT(x SEPARATOR ',')` |
| PostgreSQL | `STRING_AGG(x, ',')` |
| SQL Server | `STRING_AGG(x, ',')` |
| Oracle | `LISTAGG(x, ',') WITHIN GROUP (ORDER BY ...)` |

---

## 6. ARRAY_AGG — gộp thành mảng (PostgreSQL)

```sql
SELECT
    department,
    ARRAY_AGG(first_name ORDER BY first_name) AS names
FROM Employee
GROUP BY department;
```

**Kết quả**: `{James, Alex}` — mảng PostgreSQL.

**Dùng khi**: cần dữ liệu dạng mảng thay vì chuỗi (ví dụ: export JSON).

---

## 7. FILTER clause — aggregate có điều kiện (PostgreSQL, SQLite)

```sql
-- PostgreSQL: gọn hơn CASE WHEN
SELECT
    department,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE salary > 100000) AS high_earners,
    COUNT(*) FILTER (WHERE gender = 'F')    AS females,
    AVG(salary) FILTER (WHERE gender = 'F') AS avg_female_salary
FROM Employee
GROUP BY department;
```

**MySQL tương đương** — dùng `SUM(CASE WHEN ...)`:

```sql
SELECT
    department,
    COUNT(*) AS total,
    SUM(CASE WHEN salary > 100000 THEN 1 ELSE 0 END) AS high_earners,
    SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END)    AS females,
    AVG(CASE WHEN gender = 'F' THEN salary END)      AS avg_female_salary
FROM Employee
GROUP BY department;
```

**Lưu ý**: `AVG(CASE WHEN gender = 'F' THEN salary END)` — không có ELSE -> mặc định NULL -> AVG bỏ qua NULL.

---

## 8. ROLLUP — tổng theo nhiều cấp

Tạo thêm dòng tổng phụ và tổng cuối.

```sql
SELECT
    department,
    gender,
    COUNT(*) AS num
FROM Employee
GROUP BY department, gender WITH ROLLUP;
```

**Kết quả**:

| department | gender | num |
|---|---|---|
| Admin | F | 2 |
| Admin | M | 2 |
| Admin | NULL | 4 |  <- tổng Admin (subtotal) |
| HR | F | 1 |
| HR | M | 1 |
| HR | NULL | 2 |  <- tổng HR |
| NULL | NULL | 6 |  <- tổng toàn bộ (grand total) |

**NULL ở cột nào** = đã gộp ở cột đó.

### ROLLUP với 1 cột

```sql
SELECT department, COUNT(*) FROM Employee
GROUP BY department WITH ROLLUP;
-- Trả về:
-- Admin | 4
-- HR    | 2
-- NULL  | 6  <- grand total
```

### PostgreSQL — dùng GROUPING SETS

PostgreSQL không có `WITH ROLLUP` trực tiếp trong GROUP BY cũ, nhưng có:

```sql
SELECT department, gender, COUNT(*)
FROM Employee
GROUP BY ROLLUP(department, gender);
```

---

## 9. CUBE — tổng mọi tổ hợp

Khác ROLLUP: CUBE tạo tổng cho **mọi tổ hợp** của các cột.

```sql
SELECT
    department,
    gender,
    COUNT(*) AS num
FROM Employee
GROUP BY department, gender WITH CUBE;
```

**Kết quả**: giống ROLLUP + thêm dòng tổng theo gender (không có department).

| department | gender | num |
|---|---|---|
| Admin | F | 2 |
| Admin | M | 2 |
| Admin | NULL | 4 |
| HR | F | 1 |
| HR | M | 1 |
| HR | NULL | 2 |
| NULL | F | 3 |  <- tổng theo gender |
| NULL | M | 3 |  <- tổng theo gender |
| NULL | NULL | 6 |  <- grand total |

---

## 10. GROUPING SETS — chỉ định tổ hợp cụ thể

Linh hoạt hơn ROLLUP/CUBE — chọn đúng tổ hợp mình muốn.

```sql
SELECT
    department,
    gender,
    COUNT(*) AS num
FROM Employee
GROUP BY GROUPING SETS (
    (department, gender),  -- chi tiết
    (department),          -- tổng theo department
    (gender),              -- tổng theo gender
    ()                     -- grand total
);
```

**Kết quả**: gồm 4 tập hợp — tương đương CUBE nhưng có thể bỏ bớt.

Ví dụ chỉ cần chi tiết + tổng theo department:

```sql
GROUP BY GROUPING SETS (
    (department, gender),
    (department)
);
```

---

## 11. GROUPING() — phân biệt NULL thật và NULL do ROLLUP

```sql
SELECT
    department,
    gender,
    COUNT(*) AS num,
    GROUPING(department) AS dept_grouped,
    GROUPING(gender) AS gender_grouped
FROM Employee
GROUP BY department, gender WITH ROLLUP;
```

**Kết quả**:

| department | gender | num | dept_grouped | gender_grouped |
|---|---|---|---|---|
| Admin | F | 2 | 0 | 0 |
| Admin | NULL | 4 | 0 | **1** |  <- gender bị gộp |
| NULL | NULL | 6 | **1** | **1** |  <- cả 2 gộp |

`GROUPING(col) = 1` -> cột bị gộp (NULL là do ROLLUP, không phải dữ liệu).

---

## 12. HAVING với nhiều điều kiện

```sql
SELECT department, AVG(salary) AS avg_sal, COUNT(*) AS num
FROM Employee
GROUP BY department
HAVING AVG(salary) > 100000
   AND COUNT(*) >= 2
   AND SUM(salary) < 1000000;
```

**Thứ tự đánh giá**: từ trái sang phải — đặt điều kiện loại nhiều dòng nhất trước.

---

## 13. Aggregate lồng — không được phép

```sql
-- Lỗi: Invalid use of group function
SELECT department, AVG(COUNT(*))
FROM Employee
GROUP BY department;
```

**Cách sửa**: dùng subquery hoặc CTE.

```sql
-- Đúng: Dùng CTE
WITH dept_counts AS (
    SELECT department, COUNT(*) AS num
    FROM Employee
    GROUP BY department
)
SELECT AVG(num) FROM dept_counts;
```

**Ứng dụng**: "Trung bình số nhân viên mỗi phòng ban là bao nhiêu?"

---

## 14. GROUP BY với biểu thức

```sql
-- Group theo năm
SELECT YEAR(joining_date) AS year, COUNT(*)
FROM Employee
GROUP BY YEAR(joining_date);

-- Group theo CASE
SELECT
    CASE
        WHEN salary >= 400000 THEN 'High'
        WHEN salary >= 200000 THEN 'Medium'
        ELSE 'Low'
    END AS band,
    COUNT(*)
FROM Employee
GROUP BY band;
```

**MySQL**: cho phép alias trong GROUP BY.
**PostgreSQL**: không cho alias — phải lặp biểu thức hoặc dùng subquery.

---

## 15. GROUP BY vs DISTINCT

```sql
-- Đếm số department distinct
SELECT COUNT(DISTINCT department) FROM Employee;

-- Tương đương
SELECT COUNT(*) FROM (SELECT DISTINCT department FROM Employee) t;
```

**Khác biệt**:
- `DISTINCT` — loại trùng, không có aggregate.
- `GROUP BY` — nhóm + có thể tính aggregate.

**Hiệu năng**: `DISTINCT` thường nhanh hơn `GROUP BY` khi chỉ cần distinct.

---

## 16. Aggregate với JOIN

```sql
SELECT
    d.dept_name,
    COUNT(DISTINCT e.employee_id) AS num_employees,
    SUM(s.salary) AS total_salary,
    ROUND(AVG(s.salary), 2) AS avg_salary
FROM departments d
LEFT JOIN dept_emp de ON d.dept_no = de.dept_no
LEFT JOIN Employee e ON de.employee_id = e.employee_id
LEFT JOIN salaries s ON e.employee_id = s.employee_id
WHERE de.to_date = '9999-01-01'
GROUP BY d.dept_no, d.dept_name;
```

**Lưu ý**:
- `COUNT(DISTINCT e.employee_id)` — tránh đếm trùng khi JOIN 1-nhiều.
- `LEFT JOIN` + `COUNT(e.col)` — đếm đúng số dòng khớp.

---

## 17. Top N mỗi nhóm

```sql
-- Top 2 nhân viên lương cao nhất mỗi phòng
SELECT department, first_name, salary
FROM (
    SELECT
        department, first_name, salary,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rn
    FROM Employee
) t
WHERE rn <= 2;
```

**Không dùng GROUP BY được** — vì cần giữ nhiều dòng mỗi nhóm.

---

## 18. So sánh tỷ lệ giữa các nhóm

```sql
SELECT
    department,
    COUNT(*) AS total,
    SUM(CASE WHEN salary > 100000 THEN 1 ELSE 0 END) AS high_earners,
    ROUND(
        SUM(CASE WHEN salary > 100000 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS pct_high_earners
FROM Employee
GROUP BY department
ORDER BY pct_high_earners DESC;
```

---

## 19. Percent of total

```sql
-- % lương của mỗi phòng so với tổng
SELECT
    department,
    SUM(salary) AS dept_salary,
    ROUND(
        SUM(salary) * 100.0 / (SELECT SUM(salary) FROM Employee),
        2
    ) AS pct_of_total
FROM Employee
GROUP BY department;
```

**Hoặc dùng window function** (không cần subquery):

```sql
SELECT DISTINCT
    department,
    SUM(salary) OVER (PARTITION BY department) AS dept_salary,
    ROUND(
        SUM(salary) OVER (PARTITION BY department) * 100.0
        / SUM(salary) OVER (),
        2
    ) AS pct_of_total
FROM Employee;
```

---

## 20. Bảng tổng hợp — chọn cách aggregate phù hợp

| Nhu cầu | Cách dùng |
|---|---|
| Đếm dòng | `COUNT(*)` |
| Đếm giá trị non-NULL | `COUNT(col)` |
| Đếm distinct | `COUNT(DISTINCT col)` |
| Tổng / trung bình | `SUM`, `AVG` |
| Gộp chuỗi | `GROUP_CONCAT` / `STRING_AGG` |
| Gộp mảng | `ARRAY_AGG` (PG) |
| Aggregate có điều kiện | `FILTER` (PG) / `SUM(CASE WHEN)` |
| Tổng nhiều cấp | `ROLLUP` |
| Tổng mọi tổ hợp | `CUBE` |
| Tổ hợp tùy chỉnh | `GROUPING SETS` |
| Top N mỗi nhóm | `ROW_NUMBER() OVER (PARTITION BY)` |

---

## 21. Ghi nhớ nhanh

> **"WHERE lọc dòng, HAVING lọc nhóm."**
> **"COUNT(*) != COUNT(col) khi có NULL."**
> **"AVG(col) = SUM(col) / COUNT(col) — bỏ NULL."**
> **"SUM toàn NULL = NULL -> COALESCE."**
> **"ROLLUP: tổng theo cấp; CUBE: mọi tổ hợp."**
> **"FILTER (PG) = SUM(CASE WHEN) (MySQL)."**
> **"Aggregate lồng -> dùng CTE."**
> **"Top N mỗi nhóm -> ROW_NUMBER, không GROUP BY."**
