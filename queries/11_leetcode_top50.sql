-- ============================================================
-- 11_leetcode_top50.sql
-- LeetCode SQL 50 — Lời giải tham khảo (MySQL)
-- ============================================================

-- 1757. Recyclable and Low Fat Products
SELECT product_id
FROM Products
WHERE low_fats = 'Y' AND recyclable = 'Y';

-- 584. Find Customer Referee
SELECT name
FROM Customer
WHERE referee_id IS NULL OR referee_id <> 2;

-- 595. Big Countries
SELECT name, population, area
FROM World
WHERE area >= 3000000 OR population >= 25000000;

-- 1148. Article Views I
SELECT DISTINCT author_id AS id
FROM Views
WHERE author_id = viewer_id
ORDER BY id;

-- 1683. Invalid Tweets
SELECT tweet_id
FROM Tweets
WHERE CHAR_LENGTH(content) > 15;

-- 1378. Replace Employee ID With The Unique Identifier
SELECT u.unique_id, e.name
FROM Employees e
LEFT JOIN EmployeeUNI u ON e.id = u.id;

-- 1068. Product Sales Analysis I
SELECT p.product_name, s.year, s.price
FROM Sales s
JOIN Product p ON s.product_id = p.product_id;

-- 1581. Customer Who Visited but Did Not Make Any Transactions
SELECT v.customer_id, COUNT(*) AS count_no_trans
FROM Visits v
LEFT JOIN Transactions t ON v.visit_id = t.visit_id
WHERE t.transaction_id IS NULL
GROUP BY v.customer_id;

-- 197. Rising Temperature
SELECT w1.id
FROM Weather w1
JOIN Weather w2
  ON DATEDIFF(w1.recordDate, w2.recordDate) = 1
WHERE w1.temperature > w2.temperature;

-- 1661. Average Time of Process per Machine
SELECT
    machine_id,
    ROUND(AVG(end_time - start_time), 3) AS processing_time
FROM (
    SELECT machine_id, process_id,
           MAX(CASE WHEN activity_type = 'start' THEN timestamp END) AS start_time,
           MAX(CASE WHEN activity_type = 'end'   THEN timestamp END) AS end_time
    FROM Activity
    GROUP BY machine_id, process_id
) t
GROUP BY machine_id;

-- 577. Employee Bonus
SELECT e.name, b.bonus
FROM Employee e
LEFT JOIN Bonus b ON e.empId = b.empId
WHERE b.bonus < 1000 OR b.bonus IS NULL;

-- 1280. Students and Examinations
SELECT
    s.student_id, s.student_name, sub.subject_name,
    COUNT(e.subject_name) AS attended_exams
FROM Students s
CROSS JOIN Subjects sub
LEFT JOIN Examinations e
  ON s.student_id = e.student_id
 AND sub.subject_name = e.subject_name
GROUP BY s.student_id, s.student_name, sub.subject_name
ORDER BY s.student_id, sub.subject_name;

-- 176. Second Highest Salary
SELECT (
    SELECT DISTINCT salary
    FROM Employee
    ORDER BY salary DESC
    LIMIT 1 OFFSET 1
) AS SecondHighestSalary;
