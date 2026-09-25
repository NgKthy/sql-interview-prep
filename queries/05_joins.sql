-- ============================================================
-- 05_joins.sql
-- Chủ đề: JOIN nhiều bảng
-- Nguồn: Q12, Q23, Q24, Q43, Q45
-- ============================================================

USE sql_interview_prep;

-- ------------------------------------------------------------
-- Q12. Nhân viên lương trong khoảng 100k - 500k
-- ------------------------------------------------------------
SELECT first_name, last_name, salary
FROM Employee
WHERE salary BETWEEN 100000 AND 500000;

-- ------------------------------------------------------------
-- Q23. Recommend pages dựa trên pages mà bạn bè đã like
-- ------------------------------------------------------------
SELECT DISTINCT pl.page_id
FROM page_likes pl
JOIN friendships f
  ON pl.user_id = f.friend_id
WHERE f.user_id = 1   -- user cần recommend
  AND pl.page_id NOT IN (
      SELECT page_id FROM page_likes WHERE user_id = 1
  );

-- ------------------------------------------------------------
-- Q24. Nhân viên có bonus cao nhất (kèm department)
-- LƯU Ý: Query gốc GROUP BY department nhưng select first_name → SAI
-- ------------------------------------------------------------
SELECT e.first_name, e.last_name, e.department, b.bonus_amount
FROM Employee e
JOIN Bonus b ON e.employee_id = b.employee_ref_id
ORDER BY b.bonus_amount DESC
LIMIT 1;

-- ------------------------------------------------------------
-- Q43. Salesperson có order với Samsonic
-- ------------------------------------------------------------
SELECT DISTINCT s.name
FROM salesperson s
JOIN orders o       ON s.id = o.salesperson_id
JOIN customer c     ON o.cust_id = c.id
WHERE c.name = 'Samsonic';

-- ------------------------------------------------------------
-- Q45. Salesperson có từ 2 order trở lên
-- ------------------------------------------------------------
SELECT s.name AS salesperson, COUNT(o.number) AS num_orders
FROM salesperson s
JOIN orders o ON s.id = o.salesperson_id
GROUP BY s.id, s.name
HAVING COUNT(o.number) >= 2;
