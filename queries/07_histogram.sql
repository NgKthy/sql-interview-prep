-- ============================================================
-- 07_histogram.sql
-- Chủ đề: Histogram / Bucketing
-- Nguồn: Q40, Q49
-- ============================================================

USE sql_interview_prep;

-- ------------------------------------------------------------
-- Q40. Histogram thời lượng session (bucket 500s)
-- ------------------------------------------------------------
SELECT
    FLOOR(timespend_sec / 500) * 500 AS bucket_start,
    COUNT(DISTINCT user_id) AS num_users
FROM event_session_details
GROUP BY bucket_start
ORDER BY bucket_start;

-- ------------------------------------------------------------
-- Q49. User insert 1000-2000 ảnh
-- ------------------------------------------------------------
SELECT COUNT(*) AS num_users
FROM (
    SELECT user_id, COUNT(*) AS image_count
    FROM event_log
    GROUP BY user_id
) t
WHERE image_count BETWEEN 1001 AND 1999;
