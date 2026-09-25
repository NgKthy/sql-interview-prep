-- ============================================================
-- 12_datalemur.sql
-- DataLemur SQL Interview Questions — MySQL port
-- ============================================================

-- Cities With Completed Trades
SELECT u.city, COUNT(*) AS completed_trades
FROM trades t
JOIN users u ON t.user_id = u.user_id
WHERE t.status = 'Completed'
GROUP BY u.city
ORDER BY completed_trades DESC
LIMIT 3;

-- Page With No Likes
SELECT p.page_id
FROM pages p
LEFT JOIN page_likes pl ON p.page_id = pl.page_id
WHERE pl.user_id IS NULL
ORDER BY p.page_id;

-- Teams Power Users
SELECT sender_id, COUNT(*) AS message_count
FROM messages
WHERE DATE(sent_date) BETWEEN '2022-08-01' AND '2022-08-31'
GROUP BY sender_id
ORDER BY message_count DESC
LIMIT 2;

-- Histogram of Tweets
SELECT tweet_count AS tweet_bucket, COUNT(*) AS user_count
FROM (
    SELECT user_id, COUNT(*) AS tweet_count
    FROM tweets
    WHERE YEAR(tweet_date) = 2022
    GROUP BY user_id
) t
GROUP BY tweet_count
ORDER BY tweet_bucket;

-- Data Science Skills
SELECT candidate_id
FROM candidates
WHERE skill IN ('Python', 'Tableau', 'PostgreSQL')
GROUP BY candidate_id
HAVING COUNT(DISTINCT skill) = 3
ORDER BY candidate_id;
