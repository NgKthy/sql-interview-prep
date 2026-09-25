-- ============================================================
-- 06_product_metrics.sql
-- Chủ đề: Product metrics (CTR, retention, acceptance, fraud)
-- Nguồn: Q26-Q32, Q36-Q39, Q41, Q42
-- ============================================================

USE sql_interview_prep;

-- ------------------------------------------------------------
-- Q26. % học sinh đi học đúng ngày sinh nhật
-- ------------------------------------------------------------
SELECT
    ROUND(
        COUNT(ae.student_id) * 100.0
        / (SELECT COUNT(*) FROM attendance_events),
        2
    ) AS percent_attend_on_birthday
FROM attendance_events ae
JOIN all_students s ON s.student_id = ae.student_id
WHERE MONTH(ae.date_event) = MONTH(s.date_of_birth)
  AND DAY(ae.date_event)   = DAY(s.date_of_birth);

-- ------------------------------------------------------------
-- Q27. User active đủ 7 ngày trong tuần (mobile)
-- ------------------------------------------------------------
SELECT COUNT(*) AS active_all_7_days
FROM (
    SELECT user_id
    FROM login_info
    WHERE login_time BETWEEN '2017-08-10' AND '2017-08-16'
    GROUP BY user_id
    HAVING COUNT(DISTINCT DATE(login_time)) = 7
) t;

-- ------------------------------------------------------------
-- Q28. Tỷ lệ chấp nhận lời mời kết bạn trong ngày 2018-05-24
-- ------------------------------------------------------------
SELECT
    ROUND(
        SUM(CASE WHEN action = 'accepted' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS acceptance_rate
FROM user_action
WHERE DATE(date_action) = '2018-05-24';

-- ------------------------------------------------------------
-- Q29. Tổng user follow ít nhất 1 sport account
-- ------------------------------------------------------------
SELECT COUNT(DISTINCT fr.follower_id) AS total_sport_followers
FROM follow_relation fr
JOIN sport_accounts sa ON fr.target_id = sa.sport_player_id;

-- ------------------------------------------------------------
-- Q30. Số active user follow từng môn thể thao
-- ------------------------------------------------------------
SELECT sa.sport_category, COUNT(DISTINCT fr.follower_id) AS active_followers
FROM follow_relation fr
JOIN sport_accounts sa ON fr.target_id = sa.sport_player_id
JOIN all_users u       ON fr.follower_id = u.user_id
WHERE u.active_last_month = 1
GROUP BY sa.sport_category;

-- ------------------------------------------------------------
-- Q31. % tài khoản active bị fraud
-- ------------------------------------------------------------
SELECT
    ROUND(
        (SELECT COUNT(DISTINCT account_id) FROM ad_accounts WHERE account_status = 'fraud') * 100.0
        / (SELECT COUNT(DISTINCT account_id) FROM ad_accounts WHERE account_status = 'active'),
        2
    ) AS percent_active_fraud;

-- ------------------------------------------------------------
-- Q32. Số account trở thành fraud LẦN ĐẦU trong hôm nay
-- ------------------------------------------------------------
SELECT COUNT(*) AS first_time_fraud_today
FROM (
    SELECT account_id
    FROM ad_accounts
    GROUP BY account_id
    HAVING SUM(CASE WHEN account_status = 'fraud' THEN 1 ELSE 0 END) = 1
       AND MAX(CASE WHEN account_status = 'fraud' THEN date END) = CURDATE()
) t;

-- ------------------------------------------------------------
-- Q33. Thời gian sử dụng trung bình mỗi user mỗi ngày
-- ------------------------------------------------------------
SELECT
    DATE(date) AS day,
    user_id,
    ROUND(AVG(timespend_sec), 2) AS avg_time_spent
FROM event_session_details
GROUP BY DATE(date), user_id
ORDER BY day, user_id;

-- ------------------------------------------------------------
-- Q36. CTR theo từng app
-- ------------------------------------------------------------
SELECT
    app_id,
    ROUND(
        SUM(CASE WHEN type = 'click' THEN 1 ELSE 0 END) * 1.0
        / NULLIF(SUM(CASE WHEN type = 'impression' THEN 1 ELSE 0 END), 0),
        4
    ) AS ctr
FROM DIALOGLOG
GROUP BY app_id;

-- ------------------------------------------------------------
-- Q37. Tỷ lệ chấp nhận lời mời kết bạn tổng thể
-- ------------------------------------------------------------
SELECT
    ROUND(
        (SELECT COUNT(*) FROM (SELECT DISTINCT acceptor_id, requestor_id FROM request_accepted) a)
        / NULLIF((SELECT COUNT(*) FROM (SELECT DISTINCT requestor_id, sent_to_id FROM friend_request) b), 0),
        4
    ) AS acceptance_rate;

-- ------------------------------------------------------------
-- Q38. User có nhiều bạn nhất
-- ------------------------------------------------------------
SELECT id
FROM (
    SELECT id, COUNT(*) AS friend_count
    FROM (
        SELECT requestor_id AS id FROM new_request_accepted
        UNION ALL
        SELECT acceptor_id  AS id FROM new_request_accepted
    ) t
    GROUP BY id
    ORDER BY friend_count DESC
    LIMIT 1
) t2;

-- ------------------------------------------------------------
-- Q39. Tổng request gửi và gửi thất bại theo quốc gia
-- ------------------------------------------------------------
SELECT
    country_code,
    SUM(count_of_requests_sent) AS total_requests_sent,
    ROUND(AVG(CAST(REPLACE(percent_of_request_sent_failed, '%', '') AS DECIMAL(5,2))), 2) AS avg_percent_failed,
    ROUND(
        SUM(count_of_requests_sent)
        * AVG(CAST(REPLACE(percent_of_request_sent_failed, '%', '') AS DECIMAL(5,2)))
        / 100,
        0
    ) AS total_failed
FROM count_request
GROUP BY country_code;

-- ------------------------------------------------------------
-- Q41. % số điện thoại xác nhận thành công
-- ------------------------------------------------------------
SELECT
    ROUND(
        COUNT(cn.phone_number) * 100.0
        / (SELECT COUNT(*) FROM confirmation_no),
        2
    ) AS confirm_percent
FROM confirmation_no conf
LEFT JOIN confirmed_no cn ON cn.phone_number = conf.phone_number;

-- ------------------------------------------------------------
-- Q42. User có >= 4 interaction ngày 2013-03-23
-- ------------------------------------------------------------
SELECT user_id, SUM(cnt) AS total_interactions
FROM (
    SELECT user_1 AS user_id, COUNT(*) AS cnt
    FROM user_interaction
    WHERE date = '2019-03-23'
    GROUP BY user_1
    UNION ALL
    SELECT user_2 AS user_id, COUNT(*) AS cnt
    FROM user_interaction
    WHERE date = '2019-03-23'
    GROUP BY user_2
) t
GROUP BY user_id
HAVING SUM(cnt) >= 4;
