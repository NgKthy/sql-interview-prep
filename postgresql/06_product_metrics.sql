-- ============================================================
-- 06_product_metrics.sql (PostgreSQL Port)
-- Chủ đề: Product metrics (CTR, retention, acceptance, fraud)
-- Hệ CSDL: PostgreSQL 12+
-- ============================================================

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
WHERE EXTRACT(MONTH FROM ae.date_event) = EXTRACT(MONTH FROM s.date_of_birth)
  AND EXTRACT(DAY FROM ae.date_event)   = EXTRACT(DAY FROM s.date_of_birth);

-- ------------------------------------------------------------
-- Q27. User active đủ 7 ngày trong tuần (mobile)
-- ------------------------------------------------------------
SELECT COUNT(*) AS active_all_7_days
FROM (
    SELECT user_id
    FROM login_info
    WHERE login_time BETWEEN '2017-08-10' AND '2017-08-16'
    GROUP BY user_id
    HAVING COUNT(DISTINCT login_time::date) = 7
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
WHERE date_action::date = '2018-05-24';

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
       AND MAX(CASE WHEN account_status = 'fraud' THEN date END) = CURRENT_DATE
) t;

-- ------------------------------------------------------------
-- Q33. Thời gian sử dụng trung bình mỗi user mỗi ngày
-- ------------------------------------------------------------
SELECT
    date::date AS day,
    user_id,
    ROUND(AVG(timespend_sec), 2) AS avg_time_spent
FROM event_session_details
GROUP BY date::date, user_id
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
