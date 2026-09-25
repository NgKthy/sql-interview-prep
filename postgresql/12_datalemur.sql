-- ============================================================
-- 12_datalemur.sql  (PostgreSQL port)
-- DataLemur SQL Interview Questions — PostgreSQL
-- ============================================================

-- DL1. Cities With Completed Trades
SELECT u.city, COUNT(*) AS completed_trades
FROM trades t
JOIN users u ON t.user_id = u.user_id
WHERE t.status = 'Completed'
GROUP BY u.city
ORDER BY completed_trades DESC
LIMIT 3;

-- DL2. Page With No Likes
SELECT p.page_id
FROM pages p
LEFT JOIN page_likes pl ON p.page_id = pl.page_id
WHERE pl.user_id IS NULL
ORDER BY p.page_id;

-- DL3. Teams Power Users
SELECT sender_id, COUNT(*) AS message_count
FROM messages
WHERE sent_date::DATE BETWEEN '2022-08-01' AND '2022-08-31'
GROUP BY sender_id
ORDER BY message_count DESC
LIMIT 2;

-- DL4. Histogram of Tweets
SELECT tweet_count AS tweet_bucket, COUNT(*) AS user_count
FROM (
    SELECT user_id, COUNT(*) AS tweet_count
    FROM tweets
    WHERE EXTRACT(YEAR FROM tweet_date) = 2022
    GROUP BY user_id
) t
GROUP BY tweet_count
ORDER BY tweet_bucket;

-- DL5. Laptop vs Mobile Viewership
SELECT
    SUM(CASE WHEN device_type = 'laptop' THEN 1 ELSE 0 END) AS laptop_views,
    SUM(CASE WHEN device_type IN ('tablet', 'phone') THEN 1 ELSE 0 END) AS mobile_views
FROM viewership;

-- DL6. Duplicate Job Listings
SELECT COUNT(*) AS duplicate_companies
FROM (
    SELECT company_id
    FROM job_listings
    GROUP BY company_id, title, description
    HAVING COUNT(*) > 1
) t;
