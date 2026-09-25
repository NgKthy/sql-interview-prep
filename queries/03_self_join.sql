-- ============================================================
-- 03_self_join.sql
-- Chủ đề: Self join
-- Nguồn: Q6, Q14, Q25
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- Q6. Nhân viên đồng thời là quản lý
-- ------------------------------------------------------------
-- Ý tưởng:
--   Một nhân viên là quản lý nếu employee_id của họ xuất hiện
--   trong cột manager_id của nhân viên khác.
--   Self-join: bảng Employee join với chính nó.
--
-- Cách 1: Self JOIN (e1.employee_id = e2.manager_id)
--   - Ưu: Trực quan — "e1 là manager khi e1.id xuất hiện trong e2.manager_id".
--   - Nhược: Trả về trùng lặp nếu 1 manager quản lý nhiều người (cần DISTINCT).
--   - Dùng khi: Tìm record trong bảng xuất hiện vai trò kép.
--
-- Cách thay thế: WHERE employee_id IN (SELECT DISTINCT manager_id FROM Employee)
--   - Ưu: Không cần JOIN, đơn giản hơn.
--   - Nhược: Subquery có thể chậm hơn với bảng lớn.
--
-- Độ phức tạp: O(n²) self-join không có index, O(n log n) với index trên manager_id.
-- ============================================================
SELECT e1.first_name, e1.last_name
FROM Employee e1
JOIN Employee e2 ON e1.employee_id = e2.manager_id;

-- ============================================================
-- Q14. Nhân viên có cùng mức lương
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tìm các cặp nhân viên (khác nhau) có salary bằng nhau.
--   Self-join trên cột salary với điều kiện loại cặp (a,a).
--
-- Cách 1: Self JOIN (e1.salary = e2.salary AND e1.id <> e2.id)
--   - Ưu: Cách kinh điển, rõ logic so sánh từng cặp.
--   - Nhược: Tạo ra cả cặp (A,B) lẫn (B,A); nếu chỉ muốn 1 cặp thêm e1.id < e2.id.
--   - Dùng khi: Tìm duplicate values hoặc so sánh trong cùng bảng.
--
-- Cách thay thế: GROUP BY salary HAVING COUNT(*) > 1 → lấy những salary trùng.
--
-- Độ phức tạp: O(n²) — cross product rồi lọc.
-- ============================================================
SELECT e1.first_name, e1.last_name, e1.salary
FROM Employee e1
JOIN Employee e2
  ON e1.salary = e2.salary
 AND e1.employee_id <> e2.employee_id;

-- ============================================================
-- Q25. Nhân viên có cùng mức lương (bao gồm salary trong output)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Giống Q14 nhưng thêm DISTINCT và sắp xếp theo salary để
--   kết quả sạch hơn, không hiển thị các cặp đối xứng trùng lặp.
--
-- Cách 1: Self JOIN + DISTINCT + ORDER BY
--   - Ưu: DISTINCT loại bỏ kết quả trùng lặp (A,B) và (B,A).
--   - Nhược: DISTINCT tốn thêm bộ nhớ nếu tập kết quả lớn.
--   - Dùng khi: Cần danh sách unique nhân viên cùng lương.
--
-- Cách tốt hơn để tránh pair trùng: AND e1.employee_id < e2.employee_id
--
-- Độ phức tạp: O(n²) — self join + sort cho DISTINCT.
-- ============================================================
SELECT DISTINCT e1.first_name, e1.last_name, e1.salary
FROM Employee e1
JOIN Employee e2
  ON e1.salary = e2.salary
 AND e1.employee_id <> e2.employee_id
ORDER BY e1.salary DESC;
