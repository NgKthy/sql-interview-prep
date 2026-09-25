-- ============================================================
-- 12_datalemur.sql  (PostgreSQL port)
-- DataLemur SQL Interview Questions — PostgreSQL
-- Khác biệt vs MySQL:
--   DATE(col)     → col::DATE hoặc DATE_TRUNC('month', col)
--   YEAR(col)     → EXTRACT(YEAR FROM col)
--   LIMIT n       → giống
-- ============================================================

-- ============================================================
-- Cities With Completed Trades (Bloomberg/Robinhood)
-- ------------------------------------------------------------
-- PostgreSQL note: Cú pháp giống MySQL.
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
-- PostgreSQL note: LEFT JOIN + IS NULL giống MySQL.
-- ============================================================
SELECT p.page_id
FROM pages p
LEFT JOIN page_likes pl ON p.page_id = pl.page_id
WHERE pl.user_id IS NULL
ORDER BY p.page_id;

-- ============================================================
-- Teams Power Users (Microsoft)
-- ------------------------------------------------------------
-- MySQL:       DATE(sent_date) BETWEEN '2022-08-01' AND '2022-08-31'
-- PostgreSQL:  sent_date::DATE BETWEEN '2022-08-01' AND '2022-08-31'
--   Hoặc:      sent_date >= '2022-08-01' AND sent_date < '2022-09-01'
-- ============================================================
SELECT sender_id, COUNT(*) AS message_count
FROM messages
WHERE sent_date::DATE BETWEEN '2022-08-01' AND '2022-08-31'
GROUP BY sender_id
ORDER BY message_count DESC
LIMIT 2;

-- ============================================================
-- Histogram of Tweets (Twitter/X)
-- ------------------------------------------------------------
-- MySQL:       YEAR(tweet_date) = 2022
-- PostgreSQL:  EXTRACT(YEAR FROM tweet_date) = 2022
--   Hoặc:      DATE_PART('year', tweet_date) = 2022
--   Hoặc:      tweet_date >= '2022-01-01' AND tweet_date < '2023-01-01'  (index-friendly)
-- ============================================================
SELECT tweet_count AS tweet_bucket, COUNT(*) AS user_count
FROM (
    SELECT user_id, COUNT(*) AS tweet_count
    FROM tweets
    WHERE EXTRACT(YEAR FROM tweet_date) = 2022    -- PG: EXTRACT thay YEAR()
    GROUP BY user_id
) t
GROUP BY tweet_count
ORDER BY tweet_bucket;

-- ============================================================
-- Data Science Skills (LinkedIn)
-- ------------------------------------------------------------
-- PostgreSQL note: Cú pháp giống MySQL.
-- ============================================================
SELECT candidate_id
FROM candidates
WHERE skill IN ('Python', 'Tableau', 'PostgreSQL')
GROUP BY candidate_id
HAVING COUNT(DISTINCT skill) = 3
ORDER BY candidate_id;
