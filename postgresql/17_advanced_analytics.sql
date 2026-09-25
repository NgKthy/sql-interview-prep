-- ============================================================
-- 17_advanced_analytics.sql  (PostgreSQL port)
-- Chủ đề: Cohort, Funnel, RFM Analysis trong PostgreSQL
-- Nguồn: Mode Analytics SQL Tutorial
-- Khác biệt vs MySQL:
--   - DATE_FORMAT() → TO_CHAR() hoặc DATE_TRUNC('month', date)
--   - TIMESTAMPDIFF() → AGE() hoặc phép trừ DATE
--   - DATEDIFF(d1, d2) → d1::DATE - d2::DATE
--   - AUTO_INCREMENT → SERIAL PRIMARY KEY
-- ============================================================

-- ============================================================
-- PHẦN 1: COHORT RETENTION
-- ============================================================

DROP TABLE IF EXISTS user_events;
CREATE TABLE user_events (
    user_id     INT,
    event_date  DATE,
    event_type  VARCHAR(20)
);

INSERT INTO user_events VALUES
(1, '2023-01-05', 'signup'), (1, '2023-01-06', 'login'),
(1, '2023-01-10', 'purchase'), (1, '2023-02-05', 'login'),
(1, '2023-03-05', 'login'),
(2, '2023-01-15', 'signup'), (2, '2023-01-16', 'login'),
(2, '2023-02-15', 'login'),
(3, '2023-01-20', 'signup'), (3, '2023-02-20', 'login'),
(3, '2023-03-20', 'login'), (3, '2023-04-20', 'login'),
(4, '2023-02-01', 'signup'), (4, '2023-02-02', 'login'),
(4, '2023-03-01', 'login'),
(5, '2023-02-10', 'signup'), (5, '2023-03-10', 'login'),
(6, '2023-03-01', 'signup'), (6, '2023-03-15', 'login'),
(6, '2023-04-01', 'login');

-- Cohort retention theo tháng
WITH user_cohort AS (
    SELECT
        user_id,
        DATE_TRUNC('month', MIN(event_date))::DATE AS cohort_month
    FROM user_events
    WHERE event_type = 'signup'
    GROUP BY user_id
),
monthly_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('month', event_date)::DATE AS activity_month
    FROM user_events
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT user_id) AS total_users
    FROM user_cohort
    GROUP BY cohort_month
)
SELECT
    uc.cohort_month,
    ma.activity_month,
    (EXTRACT(YEAR FROM AGE(ma.activity_month, uc.cohort_month)) * 12 +
     EXTRACT(MONTH FROM AGE(ma.activity_month, uc.cohort_month)))::INT AS month_number,
    COUNT(DISTINCT ma.user_id) AS active_users,
    cs.total_users,
    ROUND(COUNT(DISTINCT ma.user_id) * 100.0 / cs.total_users, 2) AS retention_rate
FROM user_cohort uc
JOIN monthly_activity ma ON uc.user_id = ma.user_id
JOIN cohort_size cs ON uc.cohort_month = cs.cohort_month
GROUP BY uc.cohort_month, ma.activity_month, cs.total_users
ORDER BY uc.cohort_month, month_number;

-- ============================================================
-- PHẦN 2: FUNNEL ANALYSIS
-- ============================================================

DROP TABLE IF EXISTS funnel_events;
CREATE TABLE funnel_events (
    user_id     INT,
    step        VARCHAR(20),
    event_time  TIMESTAMP
);

INSERT INTO funnel_events VALUES
(1, 'visit',    '2023-03-01 10:00:00'),
(1, 'signup',   '2023-03-01 10:05:00'),
(1, 'add_cart', '2023-03-01 10:10:00'),
(1, 'checkout', '2023-03-01 10:15:00'),
(2, 'visit',    '2023-03-01 11:00:00'),
(2, 'signup',   '2023-03-01 11:05:00'),
(2, 'add_cart', '2023-03-01 11:10:00'),
(3, 'visit',    '2023-03-01 12:00:00'),
(3, 'signup',   '2023-03-01 12:05:00'),
(4, 'visit',    '2023-03-02 09:00:00'),
(5, 'visit',    '2023-03-02 10:00:00'),
(5, 'signup',   '2023-03-02 10:02:00'),
(5, 'add_cart', '2023-03-02 10:05:00'),
(5, 'checkout', '2023-03-02 10:10:00'),
(5, 'purchase', '2023-03-02 10:12:00');

WITH step_counts AS (
    SELECT
        step,
        COUNT(DISTINCT user_id) AS users,
        CASE step
            WHEN 'visit'    THEN 1
            WHEN 'signup'   THEN 2
            WHEN 'add_cart' THEN 3
            WHEN 'checkout' THEN 4
            WHEN 'purchase' THEN 5
        END AS step_order
    FROM funnel_events
    GROUP BY step
)
SELECT
    step,
    users,
    LAG(users) OVER (ORDER BY step_order) AS prev_users,
    ROUND(users * 100.0 / FIRST_VALUE(users) OVER (ORDER BY step_order), 2) AS pct_of_visit,
    ROUND(users * 100.0 / LAG(users) OVER (ORDER BY step_order), 2) AS step_conversion_rate
FROM step_counts
ORDER BY step_order;

-- ============================================================
-- PHẦN 3: RFM ANALYSIS
-- ============================================================

DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
    trans_id    SERIAL PRIMARY KEY,
    customer_id INT,
    trans_date  DATE,
    amount      NUMERIC(10,2)
);

INSERT INTO transactions (customer_id, trans_date, amount) VALUES
(1, '2023-01-10', 100), (1, '2023-02-15', 150), (1, '2023-03-20', 200),
(1, '2023-04-25', 250),
(2, '2023-01-05',  50), (2, '2023-03-10',  75),
(3, '2023-02-20', 500),
(4, '2023-01-15', 100), (4, '2023-02-20', 120), (4, '2023-03-25', 130),
(4, '2023-04-20', 140), (4, '2023-05-15', 150),
(5, '2023-05-01',  80),
(6, '2023-03-15', 300), (6, '2023-04-15', 350);

WITH rfm_raw AS (
    SELECT
        customer_id,
        '2023-06-01'::DATE - MAX(trans_date) AS recency_days,
        COUNT(*) AS frequency,
        SUM(amount) AS monetary
    FROM transactions
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    (r_score || f_score || m_score) AS rfm_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Others'
    END AS segment
FROM rfm_scores
ORDER BY rfm_score DESC;
