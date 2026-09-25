-- ============================================================
-- 05_joins.sql  (PostgreSQL port)
-- Chủ đề: JOIN nhiều bảng
-- Nguồn: Q12, Q23, Q24, Q43, Q45
-- Khác biệt vs MySQL:
--   - LIMIT 1 → giống nhau (PG cũng dùng LIMIT)
--   - Cú pháp JOIN hoàn toàn chuẩn SQL, không đổi
-- ============================================================

-- ============================================================
-- Q12. Nhân viên lương trong khoảng 100k - 500k
-- ------------------------------------------------------------
-- PostgreSQL note: BETWEEN hoàn toàn giống MySQL.
-- Độ phức tạp: O(log n + k) với index trên salary.
-- ============================================================
SELECT first_name, last_name, salary
FROM Employee
WHERE salary BETWEEN 100000 AND 500000;

-- ============================================================
-- Q23. Recommend pages dựa trên pages mà bạn bè đã like
-- ------------------------------------------------------------
-- PostgreSQL note: Cú pháp giống MySQL.
-- Cải thiện: dùng EXCEPT thay NOT IN để an toàn với NULL.
-- Độ phức tạp: O(F * P).
-- ============================================================

-- Cách 1: NOT IN (giống MySQL, cảnh báo NULL)
SELECT DISTINCT pl.page_id
FROM page_likes pl
JOIN friendships f ON pl.user_id = f.friend_id
WHERE f.user_id = 1
  AND pl.page_id NOT IN (
      SELECT page_id FROM page_likes WHERE user_id = 1
  );

-- Cách 2 (PG idiomatic): EXCEPT
SELECT pl.page_id
FROM page_likes pl
JOIN friendships f ON pl.user_id = f.friend_id
WHERE f.user_id = 1
EXCEPT
SELECT page_id FROM page_likes WHERE user_id = 1;

-- ============================================================
-- Q24. Nhân viên có bonus cao nhất (kèm department)
-- ------------------------------------------------------------
-- PostgreSQL note: LIMIT 1 giống MySQL.
-- Độ phức tạp: O(n log n).
-- ============================================================
SELECT e.first_name, e.last_name, e.department, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id
ORDER BY b.bonus_amount DESC
LIMIT 1;

-- ============================================================
-- Q43. Salesperson có order với Samsonic
-- ------------------------------------------------------------
-- PostgreSQL note: Cú pháp INNER JOIN giống MySQL.
-- Độ phức tạp: O(n*m).
-- ============================================================
SELECT DISTINCT s.name
FROM salesperson s
JOIN orders o   ON s.id = o.salesperson_id
JOIN customer c ON o.cust_id = c.id
WHERE c.name = 'Samsonic';

-- ============================================================
-- Q45. Salesperson có từ 2 order trở lên
-- ------------------------------------------------------------
-- PostgreSQL note: GROUP BY + HAVING hoàn toàn chuẩn SQL.
-- Độ phức tạp: O(n log n).
-- ============================================================
SELECT s.name AS salesperson, COUNT(o.number) AS num_orders
FROM salesperson s
JOIN orders o ON s.id = o.salesperson_id
GROUP BY s.id, s.name
HAVING COUNT(o.number) >= 2;
