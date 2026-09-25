# Advanced Joins — Hiểu sâu về JOIN

> JOIN là chủ đề số 1 trong mọi buổi phỏng vấn SQL. File này đào sâu vào từng loại JOIN, pitfalls, và cách chọn đúng loại.

---

## 1. Bảng so sánh 6 loại JOIN

Giả sử có 2 bảng:

**A** = {1, 2, 3, 4}
**B** = {3, 4, 5, 6}

| JOIN | Kết quả | Ý nghĩa |
|---|---|---|
| `A INNER JOIN B` | {3, 4} | Chỉ dòng khớp cả 2 bên |
| `A LEFT JOIN B` | {1, 2, 3, 4} | Tất cả A, NULL nếu B không khớp |
| `A RIGHT JOIN B` | {3, 4, 5, 6} | Tất cả B, NULL nếu A không khớp |
| `A FULL OUTER JOIN B` | {1, 2, 3, 4, 5, 6} | Tất cả 2 bên |
| `A CROSS JOIN B` | 4 × 4 = 16 dòng | Tích Descartes |
| `A LEFT JOIN B WHERE B.key IS NULL` | {1, 2} | Dòng chỉ có ở A |

---

## 2. INNER JOIN — chỉ lấy phần chung

```sql
SELECT e.first_name, b.bonus_amount
FROM Employee e
INNER JOIN Bonus b ON e.employee_id = b.employee_ref_id;
```

**Kết quả**: chỉ nhân viên **có** bonus.

**Dùng khi**: bạn chỉ quan tâm dòng khớp cả 2 bên.

---

## 3. LEFT JOIN — giữ tất cả bảng trái

```sql
SELECT e.first_name, b.bonus_amount
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id;
```

**Kết quả**: tất cả nhân viên; ai không có bonus thì `bonus_amount = NULL`.

**Dùng khi**: cần liệt kê tất cả bản ghi của bảng chính, bất kể có dữ liệu liên quan hay không.

### Bẫy 1 — WHERE trên bảng phải biến LEFT JOIN thành INNER JOIN

```sql
-- WHERE loại bỏ NULL -> thực chất là INNER JOIN
SELECT e.first_name, b.bonus_amount
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
WHERE b.bonus_amount > 3000;
-- Nhân viên không có bonus (NULL) bị loại

-- Điều kiện phải nằm trong ON (Hợp lệ)
SELECT e.first_name, b.bonus_amount
FROM Employee e
LEFT JOIN Bonus b
  ON e.employee_id = b.employee_ref_id
 AND b.bonus_amount > 3000;
-- Nhân viên không có bonus vẫn xuất hiện, bonus_amount = NULL
```

### Bẫy 2 — COUNT trên bảng phải

```sql
-- Sai: COUNT(*) đếm cả dòng có b NULL
SELECT e.department, COUNT(*) AS num
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
GROUP BY e.department;

-- Đúng: COUNT(cột của bảng phải) — bỏ qua NULL
SELECT e.department, COUNT(b.employee_ref_id) AS num
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
GROUP BY e.department;
```

**Quy tắc**: khi LEFT JOIN, dùng `COUNT(b.col)` thay vì `COUNT(*)` nếu muốn đếm số dòng khớp.

---

## 4. RIGHT JOIN — hiếm dùng, thường đảo thành LEFT JOIN

```sql
-- RIGHT JOIN
SELECT e.first_name, b.bonus_amount
FROM Employee e
RIGHT JOIN Bonus b ON e.employee_id = b.employee_ref_id;

-- Tương đương (khuyến nghị viết lại)
SELECT e.first_name, b.bonus_amount
FROM Bonus b
LEFT JOIN Employee e ON e.employee_id = b.employee_ref_id;
```

**Khuyến nghị**: luôn viết dạng LEFT JOIN để dễ đọc — sắp bảng theo thứ tự "chính -> phụ".

---

## 5. FULL OUTER JOIN — cả 2 bên

```sql
SELECT e.first_name, b.bonus_amount
FROM Employee e
FULL OUTER JOIN Bonus b ON e.employee_id = b.employee_ref_id;
```

**Kết quả**:
- Nhân viên có bonus -> hiển thị cả 2.
- Nhân viên không có bonus -> bonus NULL.
- Bonus không có nhân viên -> first_name NULL.

**MySQL**: không hỗ trợ FULL OUTER JOIN. Phải mô phỏng:

```sql
SELECT e.first_name, b.bonus_amount
FROM Employee e LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
UNION
SELECT e.first_name, b.bonus_amount
FROM Employee e RIGHT JOIN Bonus b ON e.employee_id = b.employee_ref_id;
```

---

## 6. CROSS JOIN — tích Descartes

```sql
-- Mọi cặp nhân viên × phòng ban
SELECT e.first_name, d.department
FROM Employee e
CROSS JOIN (SELECT DISTINCT department FROM Employee) d;
```

**Dùng khi**:
- Tạo tổ hợp (calendar × product).
- Sinh dữ liệu test.
- Cần kiểm tra "mọi user đã làm mọi action chưa".

### Ví dụ — báo cáo có đủ ngày kể cả ngày không có giao dịch

```sql
WITH dates AS (
    SELECT DATE('2024-01-01') + INTERVAL n DAY AS d
    FROM (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3
          UNION SELECT 4 UNION SELECT 5 UNION SELECT 6) t
),
products AS (SELECT DISTINCT product_id FROM orders)
SELECT d.d, p.product_id, COALESCE(SUM(o.amount), 0) AS revenue
FROM dates d
CROSS JOIN products p
LEFT JOIN orders o ON DATE(o.order_date) = d.d AND o.product_id = p.product_id
GROUP BY d.d, p.product_id
ORDER BY d.d, p.product_id;
```

**Tại sao**: nếu không CROSS JOIN, ngày không có đơn hàng sẽ **biến mất** khỏi báo cáo.

---

## 7. SELF JOIN — JOIN bảng với chính nó

### 7.1. Tìm quản lý

```sql
SELECT
    e.first_name AS employee,
    m.first_name AS manager
FROM Employee e
JOIN Employee m ON e.manager_id = m.employee_id;
```

### 7.2. Tìm cặp có cùng thuộc tính

```sql
-- Cặp nhân viên cùng mức lương
SELECT DISTINCT e1.first_name, e2.first_name, e1.salary
FROM Employee e1
JOIN Employee e2
  ON e1.salary = e2.salary
 AND e1.employee_id < e2.employee_id;
```

**Lưu ý**: dùng `<` thay vì `<>` để mỗi cặp chỉ xuất hiện 1 lần (không có (A,B) và (B,A)).

### 7.3. So sánh với dòng trước/sau (khi không có window function)

```sql
-- Nhân viên có lương cao hơn người vào trước
SELECT e1.first_name, e1.salary, e2.first_name AS prev_emp, e2.salary AS prev_salary
FROM Employee e1
JOIN Employee e2
  ON e2.joining_date = (
      SELECT MAX(joining_date)
      FROM Employee e3
      WHERE e3.joining_date < e1.joining_date
  )
WHERE e1.salary > e2.salary;
```

**Khuyến nghị**: dùng `LAG()` thay vì self join cho bài toán này — gọn và nhanh hơn.

```sql
SELECT first_name, salary,
       LAG(first_name) OVER (ORDER BY joining_date) AS prev_emp,
       LAG(salary) OVER (ORDER BY joining_date) AS prev_salary
FROM Employee;
```

---

## 8. JOIN nhiều bảng (3+)

```sql
SELECT
    e.first_name,
    d.dept_name,
    t.title,
    s.salary
FROM Employee e
JOIN dept_emp de ON e.employee_id = de.employee_id
JOIN departments d ON de.dept_no = d.dept_no
JOIN titles t ON e.employee_id = t.employee_id
JOIN salaries s ON e.employee_id = s.employee_id
WHERE de.to_date = '9999-01-01'
  AND t.to_date = '9999-01-01'
  AND s.to_date = '9999-01-01';
```

**Thứ tự JOIN quan trọng**:
- Bảng nhỏ JOIN trước -> giảm số dòng trung gian.
- Bảng filter mạnh (nhiều dòng bị loại) -> JOIN sớm.

---

## 9. JOIN với điều kiện phức tạp

### 9.1. JOIN nhiều điều kiện

```sql
SELECT *
FROM orders o
JOIN products p
  ON o.product_id = p.product_id
 AND o.order_date BETWEEN p.valid_from AND p.valid_to;
```

### 9.2. JOIN với OR

```sql
-- OR trong JOIN thường chậm
SELECT *
FROM a
JOIN b ON a.id = b.id1 OR a.id = b.id2;

-- Đổi thành UNION (khuyên dùng)
SELECT * FROM a JOIN b ON a.id = b.id1
UNION
SELECT * FROM a JOIN b ON a.id = b.id2;
```

### 9.3. Non-equi JOIN

```sql
-- Nhân viên có lương nằm trong khoảng của bảng lương
SELECT e.first_name, e.salary, sg.grade
FROM Employee e
JOIN salary_grades sg
  ON e.salary BETWEEN sg.min_salary AND sg.max_salary;
```

---

## 10. Pitfalls — 5 lỗi JOIN phổ biến

### Lỗi 1 — Fan-out (JOIN làm nhân dòng)

Khi JOIN 1-nhiều, bảng bên "1" bị nhân lên.

```sql
-- Giả sử: 1 employee có 3 bonuses
-- JOIN sẽ tạo 3 dòng cho mỗi employee
SELECT e.employee_id, e.salary, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id;

-- Nếu SUM(salary) -> SAI (salary bị đếm 3 lần)
SELECT e.department, SUM(e.salary) AS total  -- SAI
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id
GROUP BY e.department;
```

**Cách sửa**:

```sql
-- Cách 1: aggregate trước khi JOIN
WITH bonus_sum AS (
    SELECT employee_ref_id, SUM(bonus_amount) AS total_bonus
    FROM Bonus
    GROUP BY employee_ref_id
)
SELECT e.department, SUM(e.salary) AS total_salary
FROM Employee e
LEFT JOIN bonus_sum b ON e.employee_id = b.employee_ref_id
GROUP BY e.department;

-- Cách 2: dùng DISTINCT
SELECT e.department, SUM(DISTINCT e.salary)  -- cẩn thận nếu có lương trùng
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id
GROUP BY e.department;
```

### Lỗi 2 — Thiếu điều kiện JOIN -> CROSS JOIN ngoài ý muốn

```sql
-- Quên ON -> tích Descartes (SAI)
SELECT * FROM Employee, Bonus;

-- Luôn có ON (ĐÚNG)
SELECT * FROM Employee e JOIN Bonus b ON e.employee_id = b.employee_ref_id;
```

### Lỗi 3 — JOIN trùng khóa

```sql
-- Nếu Bonus có nhiều bản ghi / employee
-- Query sau trả về nhiều dòng hơn mong đợi
SELECT e.first_name, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id;
```

**Kiểm tra**: trước khi JOIN, verify khóa là UNIQUE.

```sql
SELECT employee_ref_id, COUNT(*)
FROM Bonus
GROUP BY employee_ref_id
HAVING COUNT(*) > 1;   -- Nếu có kết quả -> khóa không unique
```

### Lỗi 4 — Dùng WHERE trên bảng phải của LEFT JOIN

Xem mục 3, Bẫy 1.

### Lỗi 5 — NULL trong điều kiện JOIN

```sql
-- NULL không match NULL -> dòng bị mất (SAI)
SELECT * FROM a JOIN b ON a.col = b.col;

-- Dùng IS NOT DISTINCT FROM (PostgreSQL) hoặc COALESCE (ĐÚNG)
SELECT * FROM a JOIN b ON a.col IS NOT DISTINCT FROM b.col;

-- Hoặc
SELECT * FROM a JOIN b ON COALESCE(a.col, '') = COALESCE(b.col, '');
```

---

## 11. Chọn JOIN nào — Decision tree

```
Cần gì?
│
├─ Chỉ dòng khớp cả 2 bên
│   └─ INNER JOIN
│
├─ Tất cả bảng trái + dòng khớp bảng phải
│   └─ LEFT JOIN
│
├─ Tất cả bảng phải + dòng khớp bảng trái
│   └─ RIGHT JOIN (hoặc đảo thành LEFT JOIN)
│
├─ Tất cả 2 bên
│   └─ FULL OUTER JOIN (MySQL: UNION của LEFT + RIGHT)
│
├─ Tổ hợp mọi cặp
│   └─ CROSS JOIN
│
└─ So sánh trong cùng bảng
    └─ SELF JOIN
```

---

## 12. JOIN vs Subquery vs EXISTS — khi nào dùng cái nào?

### 12.1. JOIN — khi cần cột từ cả 2 bảng

```sql
SELECT e.first_name, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id;
```

### 12.2. EXISTS — khi chỉ cần kiểm tra tồn tại

```sql
SELECT e.*
FROM Employee e
WHERE EXISTS (
    SELECT 1 FROM Bonus b WHERE b.employee_ref_id = e.employee_id
);
```

**Ưu**: dừng sớm khi tìm thấy 1 dòng — nhanh hơn JOIN khi bảng phải lớn.

### 12.3. IN — khi danh sách nhỏ

```sql
SELECT * FROM Employee
WHERE employee_id IN (1, 2, 3);
```

**Cảnh báo**: `NOT IN` với subquery có NULL -> trả về rỗng. Dùng `NOT EXISTS`.

### 12.4. Bảng so sánh

| Tình huống | Nên dùng |
|---|---|
| Cần cột từ 2 bảng | JOIN |
| Chỉ cần kiểm tra tồn tại | EXISTS / NOT EXISTS |
| Danh sách giá trị cố định nhỏ | IN |
| NOT IN với subquery | Thay thế bằng NOT EXISTS |
| Cần loại trùng kết quả | EXISTS (không cần DISTINCT) |

---

## 13. Ghi nhớ nhanh

> **"LEFT JOIN + WHERE bảng phải = INNER JOIN."**
> **"COUNT(*) sau LEFT JOIN đếm cả NULL -> dùng COUNT(b.col)."**
> **"JOIN 1-nhiều làm fan-out -> aggregate trước khi JOIN."**
> **"Self join: dùng `<` thay `<>` để tránh cặp trùng."**
> **"NOT IN + NULL = rỗng -> dùng NOT EXISTS."**
