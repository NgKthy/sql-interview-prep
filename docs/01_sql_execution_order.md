# Thứ tự thực thi của SQL

> Hiểu đúng thứ tự này là chìa khóa để viết query đúng ngay từ lần đầu, và trả lời được 80% câu hỏi "tại sao query này lỗi?" trong phỏng vấn.

---

## 1. Viết vs Thực thi

SQL được **viết** theo thứ tự:

```sql
SELECT   ...
FROM     ...
JOIN     ...
WHERE    ...
GROUP BY ...
HAVING   ...
ORDER BY ...
LIMIT    ...
```

Nhưng SQL **thực thi** theo thứ tự hoàn toàn khác:

```
┌─────────────────────────────────────────────────────────┐
│  1. FROM + JOIN     -> tạo tập dữ liệu gốc               │
│  2. WHERE           -> lọc từng dòng                     │
│  3. GROUP BY        -> nhóm dòng                         │
│  4. HAVING          -> lọc nhóm                          │
│  5. SELECT          -> chọn cột, tính toán, alias        │
│  6. DISTINCT        -> loại trùng                        │
│  7. ORDER BY        -> sắp xếp                           │
│  8. LIMIT / OFFSET  -> cắt bớt                           │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Ví dụ minh họa từng bước

Xét query:

```sql
SELECT   department, COUNT(*) AS cnt
FROM     Employee
WHERE    salary > 50000
GROUP BY department
HAVING   COUNT(*) > 1
ORDER BY cnt DESC
LIMIT    3;
```

### Bước 1 — FROM Employee

Database load toàn bộ bảng (hoặc dùng index nếu có). Giả sử có 8 dòng:

| employee_id | first_name | department | salary |
|---|---|---|---|
| 1 | James | HR | 100000 |
| 2 | Jessica | Admin | 80000 |
| 3 | Alex | HR | 300000 |
| 4 | Pratik | Admin | 500000 |
| 5 | Christine | Admin | 500000 |
| 6 | Deepak | Account | 200000 |
| 7 | Jennifer | Account | 75000 |
| 8 | Deepika | Admin | 90000 |

### Bước 2 — WHERE salary > 50000

Lọc từng dòng. Giữ lại các dòng có `salary > 50000` — tất cả 8 dòng đều thỏa.

### Bước 3 — GROUP BY department

Nhóm các dòng theo department:

- **HR**: 2 dòng (James, Alex)
- **Admin**: 4 dòng (Jessica, Pratik, Christine, Deepika)
- **Account**: 2 dòng (Deepak, Jennifer)

### Bước 4 — HAVING COUNT(*) > 1

Lọc nhóm. Cả 3 nhóm đều có > 1 dòng -> giữ hết.

### Bước 5 — SELECT department, COUNT(*)

Tính toán:

| department | cnt |
|---|---|
| HR | 2 |
| Admin | 4 |
| Account | 2 |

### Bước 6 — DISTINCT (không có trong query này)

### Bước 7 — ORDER BY cnt DESC

| department | cnt |
|---|---|
| Admin | 4 |
| HR | 2 |
| Account | 2 |

### Bước 8 — LIMIT 3

Lấy 3 dòng đầu — vẫn cả 3.

---

## 3. Hệ quả thực tế — 6 điều cần nhớ

### 3.1. Alias trong SELECT chưa có ở WHERE

WHERE chạy **trước** SELECT -> alias chưa tồn tại.

```sql
-- Lỗi: Unknown column 'salary_band'
SELECT salary,
       CASE WHEN salary > 100000 THEN 'High' ELSE 'Low' END AS salary_band
FROM Employee
WHERE salary_band = 'High';

-- Lặp lại biểu thức (Hợp lệ)
SELECT salary,
       CASE WHEN salary > 100000 THEN 'High' ELSE 'Low' END AS salary_band
FROM Employee
WHERE CASE WHEN salary > 100000 THEN 'High' ELSE 'Low' END = 'High';

-- Khuyên dùng: bọc trong CTE
WITH t AS (
    SELECT salary,
           CASE WHEN salary > 100000 THEN 'High' ELSE 'Low' END AS salary_band
    FROM Employee
)
SELECT * FROM t WHERE salary_band = 'High';
```

### 3.2. Alias trong SELECT **có thể** dùng ở ORDER BY

ORDER BY chạy **sau** SELECT -> alias đã tồn tại.

```sql
-- Hợp lệ
SELECT department, COUNT(*) AS cnt
FROM Employee
GROUP BY department
ORDER BY cnt DESC;
```

### 3.3. WHERE lọc **trước** GROUP BY

```sql
-- WHERE lọc nhân viên Admin trước, rồi mới đếm
SELECT department, COUNT(*)
FROM Employee
WHERE department = 'Admin'
GROUP BY department;
```

Nếu đặt điều kiện trong HAVING sẽ chạy sau khi đã group -> chậm hơn.

### 3.4. HAVING lọc **sau** GROUP BY — dùng cho aggregate

```sql
-- Đúng: lọc theo COUNT (aggregate)
SELECT department, COUNT(*) AS cnt
FROM Employee
GROUP BY department
HAVING COUNT(*) > 1;

-- Sai: dùng HAVING cho cột không aggregate
SELECT department, COUNT(*) FROM Employee
HAVING department = 'Admin';   -- chạy được nhưng vô nghĩa
```

### 3.5. Không dùng được aggregate trong WHERE

```sql
-- Lỗi: Invalid use of group function
SELECT department, COUNT(*)
FROM Employee
WHERE COUNT(*) > 1
GROUP BY department;

-- Đúng: Dùng HAVING
SELECT department, COUNT(*)
FROM Employee
GROUP BY department
HAVING COUNT(*) > 1;
```

### 3.6. LIMIT không có ORDER BY -> kết quả không xác định

```sql
-- Không xác định — thứ tự tùy DB, tùy index
SELECT * FROM Employee LIMIT 5;

-- Đúng: Luôn kèm ORDER BY
SELECT * FROM Employee ORDER BY employee_id LIMIT 5;
```

---

## 4. Window Functions chạy ở đâu?

Window functions chạy **sau** WHERE, GROUP BY, HAVING nhưng **trước** ORDER BY cuối cùng.

```
FROM -> WHERE -> GROUP BY -> HAVING -> SELECT (window functions) -> DISTINCT -> ORDER BY -> LIMIT
```

Hệ quả: **không dùng được window function trong WHERE**.

```sql
-- Lỗi: window function không được ở WHERE
SELECT employee_id, salary,
       RANK() OVER (ORDER BY salary DESC) AS rnk
FROM Employee
WHERE rnk <= 3;

-- Đúng: Bọc trong subquery hoặc CTE
WITH ranked AS (
    SELECT employee_id, salary,
           RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM Employee
)
SELECT * FROM ranked WHERE rnk <= 3;
```

---

## 5. CASE trong SELECT vs WHERE

CASE trong SELECT chạy ở bước 5. CASE trong WHERE chạy ở bước 2.

```sql
-- CASE trong SELECT: tạo cột mới
SELECT first_name, salary,
       CASE WHEN salary >= 400000 THEN 'Senior' ELSE 'Junior' END AS level
FROM Employee;

-- CASE trong WHERE: dùng để lọc có điều kiện
SELECT * FROM Employee
WHERE CASE WHEN department = 'Admin' THEN salary > 100000
           ELSE salary > 50000 END;
```

---

## 6. Bảng tổng hợp — Bước nào được dùng cái gì

| Bước | Có thể dùng | Không thể dùng |
|---|---|---|
| 1. FROM | Tên bảng, subquery, CTE | Alias của SELECT |
| 2. WHERE | Cột gốc, subquery | Alias SELECT, aggregate, window function |
| 3. GROUP BY | Cột gốc, biểu thức | Alias SELECT (MySQL cho phép, PG không) |
| 4. HAVING | Aggregate, cột GROUP BY | Window function |
| 5. SELECT | Cột, aggregate, window function, alias | — |
| 6. DISTINCT | — | — |
| 7. ORDER BY | Alias SELECT, cột, aggregate | — |
| 8. LIMIT | Số nguyên | Biến (trừ khi dùng prepared statement) |

---

## 7. Bài tập tự kiểm tra

**Câu 1**: Query sau có lỗi không? Vì sao?
```sql
SELECT first_name, salary * 12 AS annual
FROM Employee
WHERE annual > 1000000;
```

<details>
<summary>Đáp án</summary>

Có lỗi. WHERE chạy trước SELECT -> alias `annual` chưa tồn tại. Sửa:

```sql
SELECT * FROM (
    SELECT first_name, salary * 12 AS annual FROM Employee
) t WHERE annual > 1000000;
```

</details>

**Câu 2**: Query sau có lỗi không? Vì sao?
```sql
SELECT department, AVG(salary)
FROM Employee
WHERE AVG(salary) > 100000
GROUP BY department;
```

<details>
<summary>Đáp án</summary>

Có lỗi. WHERE không dùng được aggregate. Sửa:

```sql
SELECT department, AVG(salary)
FROM Employee
GROUP BY department
HAVING AVG(salary) > 100000;
```

</details>

**Câu 3**: Query sau trả về gì?
```sql
SELECT department, COUNT(*) AS cnt
FROM Employee
WHERE salary > 100000
GROUP BY department
HAVING cnt > 1;
```

<details>
<summary>Đáp án</summary>

MySQL: chạy được (MySQL cho phép alias trong HAVING). PostgreSQL: lỗi. Cách portable:

```sql
SELECT department, COUNT(*) AS cnt
FROM Employee
WHERE salary > 100000
GROUP BY department
HAVING COUNT(*) > 1;
```

</details>

---

## 8. Ghi nhớ nhanh

> **"FROM -> WHERE -> GROUP -> HAVING -> SELECT -> DISTINCT -> ORDER -> LIMIT"**

- **WHERE** = lọc **dòng** (trước khi group).
- **HAVING** = lọc **nhóm** (sau khi group).
- **Alias** chỉ dùng được ở **ORDER BY** và **HAVING** (MySQL).
- **Window functions** không được ở WHERE.
- **LIMIT** phải đi kèm **ORDER BY**.
