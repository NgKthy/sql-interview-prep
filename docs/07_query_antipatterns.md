# Query Anti-patterns — 20 lỗi thường gặp

> Docs 03 nói về **tốc độ**. File này nói về **tính đúng đắn** và **khả năng đọc hiểu**. Nhiều query chạy nhanh nhưng sai kết quả — đó là anti-pattern nguy hiểm hơn.

---

## 1. Anti-pattern về tính đúng đắn

### 1.1. NOT IN với NULL

```sql
-- Lỗi: Nếu subquery có NULL -> kết quả rỗng
SELECT * FROM Employee
WHERE employee_id NOT IN (SELECT manager_id FROM Employee);
-- manager_id có NULL (CEO) -> NOT IN trả về FALSE cho mọi dòng

-- Đúng: Dùng NOT EXISTS
SELECT e.* FROM Employee e
WHERE NOT EXISTS (
    SELECT 1 FROM Employee m WHERE m.manager_id = e.employee_id
);
```

**Giải thích**: `x NOT IN (1, NULL)` = `x <> 1 AND x <> NULL` = `x <> 1 AND UNKNOWN` = UNKNOWN -> không match.

### 1.2. COUNT(*) sau LEFT JOIN

```sql
-- Lỗi: Đếm cả dòng không khớp (NULL)
SELECT e.department, COUNT(*) AS num_with_bonus
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
GROUP BY e.department;

-- Đúng: Đếm cột bảng phải
SELECT e.department, COUNT(b.employee_ref_id) AS num_with_bonus
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
GROUP BY e.department;
```

### 1.3. WHERE trên bảng phải của LEFT JOIN

```sql
-- Lỗi: WHERE biến LEFT JOIN thành INNER JOIN
SELECT * FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
WHERE b.bonus_amount > 3000;

-- Đúng: Điều kiện nằm trong ON
SELECT * FROM Employee e
LEFT JOIN Bonus b
  ON e.employee_id = b.employee_ref_id
 AND b.bonus_amount > 3000;
```

### 1.4. GROUP BY thiếu cột (ONLY_FULL_GROUP_BY)

```sql
-- Lỗi trên MySQL 8 / PostgreSQL
SELECT department, first_name, MAX(salary)
FROM Employee
GROUP BY department;

-- Đúng: Dùng window function
SELECT department, first_name, salary
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rn
    FROM Employee
) t WHERE rn = 1;
```

### 1.5. So sánh với NULL bằng `=`

```sql
-- Lỗi: Không bao giờ match
SELECT * FROM Employee WHERE manager_id = NULL;

-- Đúng: Dùng IS NULL
SELECT * FROM Employee WHERE manager_id IS NULL;
```

### 1.6. Hàm trên cột trong WHERE

```sql
-- Lỗi: Không dùng được index
SELECT * FROM Employee WHERE YEAR(joining_date) = 2017;

-- Đúng: Dùng range
SELECT * FROM Employee
WHERE joining_date >= '2017-01-01'
  AND joining_date <  '2018-01-01';
```

### 1.7. Dùng HAVING thay WHERE

```sql
-- Lỗi: Lọc sau khi group -> chậm
SELECT department, COUNT(*)
FROM Employee
GROUP BY department
HAVING department = 'Admin';

-- Đúng: Lọc trước khi group
SELECT department, COUNT(*)
FROM Employee
WHERE department = 'Admin'
GROUP BY department;
```

### 1.8. Self join thiếu điều kiện loại chính mình

```sql
-- Lỗi: Mỗi nhân viên tự so với chính mình
SELECT e1.first_name FROM Employee e1
JOIN Employee e2 ON e1.salary = e2.salary;

-- Đúng: Loại chính mình
SELECT e1.first_name FROM Employee e1
JOIN Employee e2
  ON e1.salary = e2.salary
 AND e1.employee_id <> e2.employee_id;
```

### 1.9. CROSS JOIN ngoài ý muốn

```sql
-- Lỗi: Thiếu ON -> tích Descartes
SELECT * FROM Employee, Bonus;

-- Đúng: Có ON
SELECT * FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id;
```

### 1.10. LIMIT không có ORDER BY

```sql
-- Lỗi: Kết quả không xác định
SELECT * FROM Employee LIMIT 10;

-- Đúng: Có ORDER BY
SELECT * FROM Employee ORDER BY employee_id LIMIT 10;
```

---

## 2. Anti-pattern về hiệu năng

### 2.1. SELECT *

```sql
-- Chậm: Đọc toàn bộ cột
SELECT * FROM Employee WHERE department = 'Admin';

-- Nhanh: Chỉ cột cần
SELECT employee_id, first_name, last_name
FROM Employee WHERE department = 'Admin';
```

**Hậu quả**: không dùng được covering index, I/O cao, query vỡ khi schema đổi.

### 2.2. OR trên cột không index

```sql
-- Chậm: Full scan
SELECT * FROM Employee
WHERE department = 'Admin' OR salary > 400000;

-- Nhanh: UNION (nếu cả 2 có index)
SELECT * FROM Employee WHERE department = 'Admin'
UNION
SELECT * FROM Employee WHERE salary > 400000;
```

### 2.3. LIKE bắt đầu bằng %

```sql
-- Chậm: Không dùng được index
SELECT * FROM users WHERE email LIKE '%@gmail.com';

-- Nhanh: Dùng được index
SELECT * FROM users WHERE email LIKE 'john%';
```

### 2.4. LIMIT OFFSET lớn

```sql
-- Chậm: Vẫn scan OFFSET dòng
SELECT * FROM Employee ORDER BY id LIMIT 10 OFFSET 1000000;

-- Nhanh: Keyset pagination
SELECT * FROM Employee WHERE id > 1000000 ORDER BY id LIMIT 10;
```

### 2.5. Correlated subquery trong SELECT

```sql
-- Chậm: Chạy subquery 1 lần / dòng
SELECT
    e.first_name,
    (SELECT COUNT(*) FROM Bonus b WHERE b.employee_ref_id = e.employee_id) AS num
FROM Employee e;

-- Nhanh: JOIN + GROUP BY
SELECT e.first_name, COUNT(b.employee_ref_id) AS num
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
GROUP BY e.employee_id, e.first_name;
```

### 2.6. DISTINCT thay cho EXISTS

```sql
-- Chậm: DISTINCT sort toàn bộ
SELECT DISTINCT e.department
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id;

-- Nhanh: EXISTS
SELECT e.department FROM Employee e
WHERE EXISTS (SELECT 1 FROM Bonus b WHERE b.employee_ref_id = e.employee_id);
```

### 2.7. UNION thay UNION ALL

```sql
-- Chậm: UNION sort + loại trùng
SELECT user_id FROM a
UNION
SELECT user_id FROM b;

-- Nhanh: UNION ALL nếu không cần distinct
SELECT user_id FROM a
UNION ALL
SELECT user_id FROM b;
```

---

## 3. Anti-pattern về khả năng đọc hiểu

### 3.1. Subquery lồng nhiều tầng

```sql
-- Khó đọc
SELECT * FROM (
    SELECT * FROM (
        SELECT * FROM (
            SELECT * FROM Employee WHERE department = 'Admin'
        ) t1 WHERE salary > 100000
    ) t2 WHERE joining_date > '2017-01-01'
) t3;

-- Dùng CTE (Khuyên dùng)
WITH admins AS (
    SELECT * FROM Employee WHERE department = 'Admin'
),
high_paid AS (
    SELECT * FROM admins WHERE salary > 100000
)
SELECT * FROM high_paid WHERE joining_date > '2017-01-01';
```

### 3.2. Alias vô nghĩa

```sql
-- Không rõ nghĩa
SELECT a.f1, b.f2 FROM t1 a JOIN t2 b ON a.id = b.id;

-- Rõ nghĩa
SELECT e.first_name, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id;
```

### 3.3. Hardcode giá trị

```sql
-- Khó bảo trì
SELECT * FROM orders WHERE status = 3 AND type = 7;

-- Dùng biến hoặc comment
SET @status_completed = 3;
SET @type_retail = 7;
SELECT * FROM orders
WHERE status = @status_completed AND type = @type_retail;
```

### 3.4. Format lộn xộn

```sql
-- Khó đọc
select first_name,last_name,salary from Employee where department='Admin' and salary>100000 order by salary desc;

-- Mỗi mệnh đề 1 dòng
SELECT first_name, last_name, salary
FROM Employee
WHERE department = 'Admin'
  AND salary > 100000
ORDER BY salary DESC;
```

### 3.5. Comment thừa

```sql
-- Comment vô nghĩa
SELECT first_name,  -- lấy first name
       last_name    -- lấy last name
FROM Employee;      -- từ bảng Employee

-- Comment giải thích "tại sao", không phải "cái gì"
-- Lọc nhân viên Admin để tính lương trung bình phòng
SELECT AVG(salary)
FROM Employee
WHERE department = 'Admin';
```

---

## 4. Anti-pattern về business logic

### 4.1. Lẫn lộn WHERE và HAVING

```sql
-- Lỗi: Lọc dòng bằng HAVING
SELECT department, COUNT(*) FROM Employee
GROUP BY department
HAVING department = 'Admin';

-- Đúng: Dùng WHERE
SELECT department, COUNT(*) FROM Employee
WHERE department = 'Admin'
GROUP BY department;
```

### 4.2. Quên xử lý NULL trong tính toán

```sql
-- Sai: Nếu salary NULL -> kết quả NULL
SELECT salary * 12 AS annual FROM Employee;

-- Đúng: Xử lý NULL
SELECT COALESCE(salary, 0) * 12 AS annual FROM Employee;
```

### 4.3. Chia cho 0

```sql
-- Lỗi chia cho 0
SELECT clicks / impressions AS ctr FROM stats;

-- Đúng: Dùng NULLIF
SELECT clicks / NULLIF(impressions, 0) AS ctr FROM stats;
```

### 4.4. So sánh ngày không đúng timezone

```sql
-- Sai: Nếu created_at là UTC, so sánh với giờ local sẽ sai
SELECT * FROM orders WHERE DATE(created_at) = CURDATE();

-- Đúng: Convert timezone trước
SELECT * FROM orders
WHERE DATE(CONVERT_TZ(created_at, '+00:00', '+07:00')) = CURDATE();
```

### 4.5. Đếm user nhưng đếm cả session

```sql
-- Sai: Nếu 1 user có 3 session -> đếm 3
SELECT COUNT(*) AS num_users FROM sessions;

-- Đúng: Đếm distinct user
SELECT COUNT(DISTINCT user_id) AS num_users FROM sessions;
```

---

## 5. Anti-pattern về transaction / concurrency

### 5.1. Không dùng transaction cho multi-step

```sql
-- Sai: Nếu bước 2 fail -> dữ liệu không nhất quán
INSERT INTO orders (...) VALUES (...);
UPDATE inventory SET qty = qty - 1 WHERE ...;

-- Đúng: Wrap trong transaction
START TRANSACTION;
INSERT INTO orders (...) VALUES (...);
UPDATE inventory SET qty = qty - 1 WHERE ...;
COMMIT;
-- Nếu lỗi: ROLLBACK;
```

### 5.2. Không dùng lock phù hợp

```sql
-- Sai: Race condition khi nhiều process cùng đọc/ghi
SELECT qty FROM inventory WHERE product_id = 1;
-- ... xử lý ...
UPDATE inventory SET qty = qty - 1 WHERE product_id = 1;

-- Đúng: SELECT FOR UPDATE
START TRANSACTION;
SELECT qty FROM inventory WHERE product_id = 1 FOR UPDATE;
UPDATE inventory SET qty = qty - 1 WHERE product_id = 1;
COMMIT;
```

---

## 6. Checklist review query — 15 điểm

Trước khi submit query, kiểm tra:

- [ ] Có `SELECT *` không? -> đổi thành cột cụ thể.
- [ ] Có hàm trên cột trong WHERE không? -> đổi thành range.
- [ ] LEFT JOIN có điều kiện ở WHERE trên bảng phải không? -> chuyển vào ON.
- [ ] COUNT(*) sau LEFT JOIN có đúng ý không? -> dùng COUNT(b.col).
- [ ] Có NOT IN với subquery không? -> đổi NOT EXISTS.
- [ ] Có LIMIT mà không ORDER BY không? -> thêm ORDER BY.
- [ ] Có chia cho cột có thể = 0 không? -> dùng NULLIF.
- [ ] Có cột NULL trong phép toán không? -> dùng COALESCE.
- [ ] GROUP BY có đủ cột không? -> kiểm tra ONLY_FULL_GROUP_BY.
- [ ] Self join có loại chính mình không? -> thêm `<>` hoặc `<`.
- [ ] JOIN có ON đầy đủ không? -> tránh CROSS JOIN ngoài ý muốn.
- [ ] UNION có cần DISTINCT không? -> đổi UNION ALL nếu không.
- [ ] Subquery lồng có nên đổi thành CTE không? -> cải thiện readability.
- [ ] Alias có rõ nghĩa không? -> đổi `a`, `b` thành `emp`, `bonus`.
- [ ] Query có chạy đúng trên edge case không? -> test với bảng rỗng, NULL, duplicate.

---

## 7. Ghi nhớ nhanh

> **"NOT IN + NULL = rỗng -> NOT EXISTS."**
> **"LEFT JOIN + WHERE bảng phải = INNER JOIN."**
> **"COUNT(*) sau LEFT JOIN đếm cả NULL."**
> **"LIMIT không ORDER BY = kết quả random."**
> **"Chia cho 0 -> NULLIF."**
> **"1 user nhiều session -> COUNT(DISTINCT)."**
