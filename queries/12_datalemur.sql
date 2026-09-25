-- ============================================================
-- 12_datalemur.sql
-- DataLemur SQL Interview Questions — MySQL port
-- ============================================================

-- ============================================================
-- Cities With Completed Trades (Bloomberg/Robinhood)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Đếm số giao dịch 'Completed' theo thành phố của user.
--   JOIN trades → users để lấy city; lọc status; GROUP BY + ORDER BY + LIMIT 3.
--
-- Cách 1: INNER JOIN + WHERE + GROUP BY + LIMIT
--   - Ưu: Đơn giản; INNER JOIN đủ vì mọi trade đều có user.
--   - Nhược: Nếu muốn xử lý trade không có user → LEFT JOIN.
--   - Dùng khi: Top-N aggregation theo category — bài phổ biến trong fintech interview.
--
-- Độ phức tạp: O(n log n) — JOIN + GROUP BY + sort.
-- ============================================================
SELECT u.city, COUNT(*) AS completed_trades
FROM trades t
JOIN users u ON t.user_id = u.user_id
WHERE t.status = 'Completed'
GROUP BY u.city
ORDER BY completed_trades DESC
LIMIT 3;

-- ============================================================
-- Page With No Likes (Meta/Facebook)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tìm page chưa có ai like — anti-join pattern.
--   LEFT JOIN pages → page_likes; nếu page không có like → user_id = NULL.
--
-- Cách 1: LEFT JOIN + WHERE IS NULL (anti-join)
--   - Ưu: Cách chuẩn và hiệu quả nhất cho anti-join.
--   - Nhược: Dễ nhầm sang NOT IN (nguy hiểm với NULL).
--   - Dùng khi: "Tìm A không có trong B" — bài pattern phổ biến nhất.
--
-- Cách thay thế: NOT EXISTS — tương đương, đôi khi optimizer xử lý tốt hơn.
-- Độ phức tạp: O(n log m) — LEFT JOIN + IS NULL filter.
-- ============================================================
SELECT p.page_id
FROM pages p
LEFT JOIN page_likes pl ON p.page_id = pl.page_id
WHERE pl.user_id IS NULL
ORDER BY p.page_id;

-- ============================================================
-- Teams Power Users (Microsoft)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tìm top 2 sender gửi nhiều tin nhắn nhất trong tháng 8/2022.
--   Lọc theo tháng, đếm message mỗi sender, lấy top 2.
--
-- Cách 1: WHERE date range + GROUP BY + ORDER BY + LIMIT
--   - Ưu: Đơn giản; DATE() trên sent_date phá index nhưng bù lại dễ đọc.
--   - Cải thiện: WHERE sent_date >= '2022-08-01' AND sent_date < '2022-09-01' → giữ index.
--   - Dùng khi: Tìm power user / top contributor trong khoảng thời gian.
--
-- Độ phức tạp: O(n log n) — GROUP BY + ORDER BY.
-- ============================================================
SELECT sender_id, COUNT(*) AS message_count
FROM messages
WHERE DATE(sent_date) BETWEEN '2022-08-01' AND '2022-08-31'
GROUP BY sender_id
ORDER BY message_count DESC
LIMIT 2;

-- ============================================================
-- Histogram of Tweets (Twitter/X)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tạo histogram: với mỗi số tweet (1, 2, 3...), đếm có bao nhiêu user có
--   đúng số tweet đó trong năm 2022. Đây là "histogram of a histogram".
--   Bước 1: Đếm tweet mỗi user (subquery).
--   Bước 2: GROUP BY tweet_count đếm số user.
--
-- Cách 1: Subquery đếm per-user + outer GROUP BY per-count
--   - Ưu: Tách 2 bước rõ ràng; dễ hiểu pattern "frequency of frequency".
--   - Nhược: User tweet 0 lần không xuất hiện (không có dòng trong tweets).
--   - Dùng khi: Phân tích phân phối — bài toán histogram phổ biến.
--
-- Độ phức tạp: O(n log n) — 2 lần GROUP BY.
-- ============================================================
SELECT tweet_count AS tweet_bucket, COUNT(*) AS user_count
FROM (
    SELECT user_id, COUNT(*) AS tweet_count
    FROM tweets
    WHERE YEAR(tweet_date) = 2022
    GROUP BY user_id
) t
GROUP BY tweet_count
ORDER BY tweet_bucket;

-- ============================================================
-- Data Science Skills (LinkedIn)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tìm candidate có đủ CẢ BA kỹ năng: Python, Tableau, PostgreSQL.
--   Mỗi skill là 1 dòng riêng → lọc 3 kỹ năng, GROUP BY candidate,
--   HAVING COUNT(DISTINCT skill) = 3 đảm bảo có đủ cả 3.
--
-- Cách 1: WHERE IN + GROUP BY + HAVING COUNT = n
--   - Ưu: Gọn; dễ mở rộng thêm kỹ năng bằng cách thêm vào IN và tăng count.
--   - Nhược: Nếu candidate có duplicate skill rows, DISTINCT bảo vệ kết quả.
--   - Dùng khi: "Set membership" — candidate phải có TẤT CẢ items trong danh sách.
--
-- Lưu ý: COUNT(*) = 3 sẽ sai nếu có duplicate; phải COUNT(DISTINCT skill) = 3.
--
-- Độ phức tạp: O(n log n) — GROUP BY + HAVING.
-- ============================================================
SELECT candidate_id
FROM candidates
WHERE skill IN ('Python', 'Tableau', 'PostgreSQL')
GROUP BY candidate_id
HAVING COUNT(DISTINCT skill) = 3
ORDER BY candidate_id;
