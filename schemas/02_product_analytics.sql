-- ============================================================
-- 02_product_analytics.sql
-- Schema cho bài toán sản phẩm: users, events, orders, retention
-- Hệ CSDL: MySQL 8.0+
-- ============================================================

DROP DATABASE IF EXISTS product_analytics;
CREATE DATABASE product_analytics CHARACTER SET utf8mb4;
USE product_analytics;

CREATE TABLE users (
    user_id     INT PRIMARY KEY,
    username    VARCHAR(50),
    signup_date DATE,
    city        VARCHAR(50)
);

CREATE TABLE events (
    event_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id    INT,
    event_name VARCHAR(50),
    event_time DATETIME,
    app_id     VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE orders (
    order_id   INT PRIMARY KEY,
    user_id    INT,
    order_date DATE,
    amount     DECIMAL(10,2),
    status     VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO users (user_id, username, signup_date) VALUES
    (1, 'alice',   '2023-01-05'),
    (2, 'bob',     '2023-01-20'),
    (3, 'charlie', '2023-02-01'),
    (4, 'diana',   '2023-02-15'),
    (5, 'eve',     '2023-03-01'),
    (6, 'frank',   '2023-03-10');

INSERT INTO events (user_id, event_name, event_time, app_id) VALUES
    (1, 'impression', '2023-03-01 10:00:00', 'app_a'),
    (1, 'click',      '2023-03-01 10:00:05', 'app_a'),
    (2, 'impression', '2023-03-01 11:00:00', 'app_a'),
    (3, 'impression', '2023-03-02 09:00:00', 'app_b'),
    (3, 'click',      '2023-03-02 09:00:10', 'app_b'),
    (3, 'click',      '2023-03-02 09:00:15', 'app_b'),
    (4, 'impression', '2023-03-03 14:00:00', 'app_b'),
    (5, 'impression', '2023-03-04 15:00:00', 'app_c'),
    (5, 'click',      '2023-03-04 15:01:00', 'app_c'),
    (6, 'impression', '2023-03-05 16:00:00', 'app_c');

INSERT INTO orders (order_id, user_id, order_date, amount, status) VALUES
    (101, 1, '2023-03-01', 100.00, 'completed'),
    (102, 1, '2023-03-05', 200.00, 'completed'),
    (103, 2, '2023-03-02',  50.00, 'completed'),
    (104, 3, '2023-03-03', 300.00, 'cancelled'),
    (105, 3, '2023-03-06', 150.00, 'completed'),
    (106, 4, '2023-03-07',  75.00, 'completed'),
    (107, 5, '2023-03-08', 120.00, 'completed');
