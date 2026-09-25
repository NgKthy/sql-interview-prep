-- ============================================================
-- 03_social_network.sql
-- Schema cho bài toán mạng xã hội: friendship, recommendations
-- Hệ CSDL: MySQL 8.0+
-- ============================================================

DROP DATABASE IF EXISTS social_network;
CREATE DATABASE social_network CHARACTER SET utf8mb4;
USE social_network;

CREATE TABLE friendships (
    user_id       INT,
    friend_id     INT,
    accepted_date DATE,
    PRIMARY KEY (user_id, friend_id)
);

CREATE TABLE page_likes (
    user_id INT,
    page_id INT,
    liked_date DATE,
    PRIMARY KEY (user_id, page_id)
);

INSERT INTO friendships (user_id, friend_id, accepted_date) VALUES
    (1, 2, '2023-01-10'), (1, 3, '2023-01-15'),
    (2, 3, '2023-01-20'), (2, 4, '2023-02-01'),
    (3, 5, '2023-02-10'), (4, 5, '2023-02-15'),
    (1, 4, '2023-02-20');

INSERT INTO page_likes (user_id, page_id, liked_date) VALUES
    (1, 100, '2023-01-05'),
    (1, 101, '2023-01-06'),
    (2, 100, '2023-01-11'),
    (2, 102, '2023-01-12'),
    (3, 101, '2023-01-16'),
    (3, 103, '2023-01-17'),
    (4, 102, '2023-02-02'),
    (5, 103, '2023-02-11');
