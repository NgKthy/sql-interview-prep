-- ============================================================
-- 17_advanced_analytics.sql
-- Chủ đề: Cohort, Funnel, RFM Analysis
-- Nguồn: Mode Analytics SQL Tutorial
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- PHẦN 1: COHORT RETENTION
-- ============================================================

-- ------------------------------------------------------------
-- CO1. Chuẩn bị dữ liệu user activity
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- CO2. Cohort retention theo tháng
-- ------------------------------------------------------------
WITH user_cohort AS (
    -- Tháng đầu tiên user signup
    SELECT
        user_id,
        DATE_FORMAT(MIN(event_date), '%Y-%m-01') AS cohort_month
    FROM user_events
    WHERE event_type = 'signup'
    GROUP BY user_id
),
monthly_activity AS (
    -- Các tháng user có hoạt động
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(event_date, '%Y-%m-01') AS activity_month
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
    TIMESTAMPDIFF(
        MONTH,
        STR_TO_DATE(uc.cohort_month, '%Y-%m-%d'),
        STR_TO_DATE(ma.activity_month, '%Y-%m-%d')
    ) AS month_number,
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

-- ------------------------------------------------------------
-- FN1. Dữ liệu funnel e-commerce
-- ------------------------------------------------------------
DROP TABLE IF EXISTS funnel_events;
CREATE TABLE funnel_events (
    user_id     INT,
    step        VARCHAR(20),
    event_time  DATETIME
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

-- ------------------------------------------------------------
-- FN2. Funnel conversion rate theo từng bước
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- FN3. Funnel với điều kiện: chỉ đếm user đã hoàn thành bước trước
-- ------------------------------------------------------------
SELECT
    'visit'    AS step, COUNT(DISTINCT user_id) AS users FROM funnel_events WHERE step = 'visit'
UNION ALL
SELECT
    'signup',
    COUNT(DISTINCT user_id) FROM funnel_events
    WHERE step = 'signup' AND user_id IN (SELECT user_id FROM funnel_events WHERE step = 'visit')
UNION ALL
SELECT
    'add_cart',
    COUNT(DISTINCT user_id) FROM funnel_events
    WHERE step = 'add_cart' AND user_id IN (SELECT user_id FROM funnel_events WHERE step = 'signup')
UNION ALL
SELECT
    'checkout',
    COUNT(DISTINCT user_id) FROM funnel_events
    WHERE step = 'checkout' AND user_id IN (SELECT user_id FROM funnel_events WHERE step = 'add_cart')
UNION ALL
SELECT
    'purchase',
    COUNT(DISTINCT user_id) FROM funnel_events
    WHERE step = 'purchase' AND user_id IN (SELECT user_id FROM funnel_events WHERE step = 'checkout');

-- ============================================================
-- PHẦN 3: RFM ANALYSIS
-- ============================================================

-- ------------------------------------------------------------
-- RFM1. Dữ liệu giao dịch
-- ------------------------------------------------------------
DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
    trans_id    INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    trans_date  DATE,
    amount      DECIMAL(10,2)
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

-- ------------------------------------------------------------
-- RFM2. Tính R, F, M cho từng customer
-- ------------------------------------------------------------
WITH rfm_raw AS (
    SELECT
        customer_id,
        DATEDIFF('2023-06-01', MAX(trans_date)) AS recency_days,
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
        -- R: càng gần đây càng tốt → điểm cao
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        -- F: càng nhiều giao dịch càng tốt
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        -- M: càng chi nhiều càng tốt
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
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

-- ------------------------------------------------------------
-- RFM3. Tổng hợp doanh thu theo segment
-- ------------------------------------------------------------
WITH rfm_raw AS (
    SELECT
        customer_id,
        DATEDIFF('2023-06-01', MAX(trans_date)) AS recency_days,
        COUNT(*) AS frequency,
        SUM(amount) AS monetary
    FROM transactions
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id, recency_days, frequency, monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)     AS m_score
    FROM rfm_raw
),
segmented AS (
    SELECT
        customer_id, monetary,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
            ELSE 'Others'
        END AS segment
    FROM rfm_scores
)
SELECT
    segment,
    COUNT(*) AS num_customers,
    SUM(monetary) AS total_revenue,
    ROUND(AVG(monetary), 2) AS avg_revenue_per_customer,
    ROUND(SUM(monetary) * 100.0 / (SELECT SUM(monetary) FROM segmented), 2) AS pct_revenue
FROM segmented
GROUP BY segment
ORDER BY total_revenue DESC;
