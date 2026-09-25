-- ============================================================
-- 07_histogram.sql
-- Chủ đề: Histogram / Bucketing
-- Nguồn: Q40, Q49
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- Q40. Histogram thời lượng session (bucket 500s)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Phân nhóm (bucket) thời lượng session theo khoảng 500 giây.
--   FLOOR(x / bucket_size) * bucket_size tính điểm bắt đầu của bucket.
--   Đếm số user DISTINCT trong mỗi bucket.
--
-- Cách 1: FLOOR(val / width) * width + GROUP BY
--   - Ưu: Kỹ thuật bucketing chuẩn; dễ thay đổi width (500 → 1000).
--   - Nhược: Không tự điền bucket trống (0 user) — cần LEFT JOIN với bảng tham chiếu.
--   - Dùng khi: Phân tích phân phối thời gian, số tiền, tuổi...
--
-- Ví dụ:
--   timespend_sec = 1200 → FLOOR(1200/500)*500 = 1000 (bucket [1000, 1500))
--   timespend_sec = 100  → FLOOR(100/500)*500  = 0    (bucket [0, 500))
--
-- Lưu ý: COUNT(DISTINCT user_id) vs COUNT(*) — đếm user unique hay số session.
--
-- Độ phức tạp: O(n log n) — GROUP BY + sort kết quả.
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
-- Ý tưởng:
--   Đếm số event mỗi user trong event_log (mỗi row = 1 ảnh insert).
--   Lọc user có số lượng ảnh trong khoảng (1001, 1999).
--   Dùng subquery để tính count trước, rồi lọc ở ngoài.
--
-- Cách 1: Subquery + WHERE BETWEEN
--   - Ưu: Rõ 2 bước: tính count, lọc count.
--   - Nhược: BETWEEN 1001 AND 1999 — cẩn thận đầu mút:
--     đề bài nói "1000-2000" nhưng thường hiểu là exclusive (không đếm đúng 1000 hay 2000).
--   - Dùng khi: Bài toán đếm event theo user rồi lọc theo ngưỡng.
--
-- Lưu ý: Điều kiện "1000-2000 ảnh" có thể là:
--   - Strictly between: BETWEEN 1001 AND 1999
--   - Inclusive: BETWEEN 1000 AND 2000
--   Cần hỏi rõ interviewer khi gặp bài này.
--
-- Độ phức tạp: O(n log n) — GROUP BY trong subquery.
-- ============================================================
SELECT COUNT(*) AS num_users
FROM (
    SELECT user_id, COUNT(*) AS image_count
    FROM event_log
    GROUP BY user_id
) t
WHERE image_count BETWEEN 1001 AND 1999;
