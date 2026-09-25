-- ============================================================
-- 07_histogram.sql  (PostgreSQL port)
-- Chủ đề: Histogram / Bucketing
-- Nguồn: Q40, Q49
-- Khác biệt vs MySQL:
--   - FLOOR() giống MySQL
--   - GROUP BY alias: MySQL cho phép GROUP BY bucket_start;
--     PostgreSQL CŨNG cho phép alias trong GROUP BY (khác SQL Server)
-- ============================================================

-- ============================================================
-- Q40. Histogram thời lượng session (bucket 500s)
-- ------------------------------------------------------------
-- PostgreSQL note:
--   - FLOOR() chuẩn SQL, giống MySQL.
--   - PostgreSQL cho phép GROUP BY alias trong SELECT list.
-- Độ phức tạp: O(n log n).
-- ============================================================
SELECT
    FLOOR(timespend_sec / 500) * 500 AS bucket_start,
    COUNT(DISTINCT user_id) AS num_users
FROM event_session_details
GROUP BY bucket_start
ORDER BY bucket_start;

-- ============================================================
-- Q49. User insert 1000-2000 ảnh
-- ------------------------------------------------------------
-- PostgreSQL note: Cú pháp hoàn toàn giống MySQL.
-- Độ phức tạp: O(n log n).
-- ============================================================
SELECT COUNT(*) AS num_users
FROM (
    SELECT user_id, COUNT(*) AS image_count
    FROM event_log
    GROUP BY user_id
) t
WHERE image_count BETWEEN 1001 AND 1999;
