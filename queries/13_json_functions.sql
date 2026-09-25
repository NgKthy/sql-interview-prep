-- ============================================================
-- 13_json_functions.sql
-- Chủ đề: JSON functions trong MySQL 8.0+
-- Nguồn: MySQL 8.0 Reference Manual — JSON Functions
-- ============================================================

USE sql_interview_prep;

-- ------------------------------------------------------------
-- Tạo bảng mẫu chứa JSON
-- ------------------------------------------------------------
DROP TABLE IF EXISTS user_profiles;
CREATE TABLE user_profiles (
    user_id   INT PRIMARY KEY,
    profile   JSON,
    metadata  JSON
);

INSERT INTO user_profiles (user_id, profile, metadata) VALUES
(1, '{"name": "Alice", "age": 28, "city": "Hanoi", "skills": ["SQL", "Python"]}',
    '{"signup_source": "web", "plan": "premium"}'),
(2, '{"name": "Bob", "age": 34, "city": "Saigon", "skills": ["Java"]}',
    '{"signup_source": "mobile", "plan": "free"}'),
(3, '{"name": "Charlie", "age": 22, "city": "Danang", "skills": ["SQL", "R", "Tableau"]}',
    '{"signup_source": "web", "plan": "premium"}');

-- ------------------------------------------------------------
-- J1. Trích xuất giá trị đơn giản từ JSON
-- ------------------------------------------------------------
-- Dùng -> trả về JSON, ->> trả về string
SELECT
    user_id,
    profile -> '$.name'         AS name_json,
    profile ->> '$.name'        AS name_str,
    profile ->> '$.age'         AS age_str,
    CAST(profile ->> '$.age' AS UNSIGNED) AS age_int
FROM user_profiles;

-- ------------------------------------------------------------
-- J2. Lọc theo giá trị trong JSON
-- ------------------------------------------------------------
SELECT user_id, profile ->> '$.name' AS name
FROM user_profiles
WHERE profile ->> '$.city' = 'Hanoi';

-- ------------------------------------------------------------
-- J3. Kiểm tra key tồn tại
-- ------------------------------------------------------------
SELECT user_id, JSON_CONTAINS_PATH(profile, 'one', '$.skills') AS has_skills
FROM user_profiles;

-- ------------------------------------------------------------
-- J4. Đếm số phần tử trong array JSON
-- ------------------------------------------------------------
SELECT
    user_id,
    profile ->> '$.name' AS name,
    JSON_LENGTH(profile, '$.skills') AS num_skills
FROM user_profiles;

-- ------------------------------------------------------------
-- J5. Tìm user có skill cụ thể trong array
-- ------------------------------------------------------------
SELECT user_id, profile ->> '$.name' AS name
FROM user_profiles
WHERE JSON_CONTAINS(profile -> '$.skills', '"SQL"');

-- ------------------------------------------------------------
-- J6. Mở rộng array JSON thành nhiều dòng (JSON_TABLE)
-- ------------------------------------------------------------
SELECT
    up.user_id,
    up.profile ->> '$.name' AS name,
    jt.skill
FROM user_profiles up,
     JSON_TABLE(
         up.profile -> '$.skills',
         '$[*]' COLUMNS (skill VARCHAR(50) PATH '$')
     ) AS jt;

-- ------------------------------------------------------------
-- J7. Tổng hợp: đếm số user theo từng skill
-- ------------------------------------------------------------
SELECT jt.skill, COUNT(DISTINCT up.user_id) AS num_users
FROM user_profiles up,
     JSON_TABLE(
         up.profile -> '$.skills',
         '$[*]' COLUMNS (skill VARCHAR(50) PATH '$')
     ) AS jt
GROUP BY jt.skill
ORDER BY num_users DESC;

-- ------------------------------------------------------------
-- J8. Cập nhật một key trong JSON
-- ------------------------------------------------------------
UPDATE user_profiles
SET profile = JSON_SET(profile, '$.age', 29)
WHERE user_id = 1;

-- ------------------------------------------------------------
-- J9. Thêm phần tử vào array JSON
-- ------------------------------------------------------------
UPDATE user_profiles
SET profile = JSON_ARRAY_APPEND(profile, '$.skills', 'Airflow')
WHERE user_id = 2;

-- ------------------------------------------------------------
-- J10. Xóa key khỏi JSON
-- ------------------------------------------------------------
UPDATE user_profiles
SET metadata = JSON_REMOVE(metadata, '$.signup_source')
WHERE user_id = 3;

-- ------------------------------------------------------------
-- J11. Trích xuất nhiều cột từ JSON_TABLE (flatten)
-- ------------------------------------------------------------
SELECT
    jt.user_id,
    jt.name,
    jt.age,
    jt.city,
    jt.plan
FROM user_profiles up,
     JSON_TABLE(
         up.profile, '$'
         COLUMNS (
             name VARCHAR(50)  PATH '$.name',
             age  INT          PATH '$.age',
             city VARCHAR(50)  PATH '$.city'
         )
     ) AS jt,
     JSON_TABLE(
         up.metadata, '$'
         COLUMNS (plan VARCHAR(20) PATH '$.plan')
     ) AS jt2
WHERE jt2.plan = 'premium';
