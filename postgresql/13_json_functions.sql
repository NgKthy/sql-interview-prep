-- ============================================================
-- 13_json_functions.sql  (PostgreSQL port)
-- Chủ đề: JSON / JSONB functions trong PostgreSQL
-- Khác biệt lớn vs MySQL:
--   MySQL JSON    → PostgreSQL có 2 loại: JSON và JSONB
--   JSONB (Binary JSON): index được, operators phong phú hơn → ưu tiên dùng
--
-- Mapping hàm MySQL → PostgreSQL:
--   col -> '$.key'          → col -> 'key'          (JSON object field by key)
--   col ->> '$.key'         → col ->> 'key'          (text)
--   JSON_EXTRACT(col, path) → col -> 'key'
--   JSON_CONTAINS(col, val) → col @> val::jsonb       (JSONB containment)
--   JSON_LENGTH(col, path)  → jsonb_array_length(col -> 'key')
--   JSON_TABLE(col, ...)    → jsonb_to_recordset() hoặc LATERAL + jsonb_array_elements()
--   JSON_SET(col, path, v)  → jsonb_set(col, '{key}', '"val"')
--   JSON_REMOVE(col, path)  → col - 'key'
--   JSON_ARRAY_APPEND(...)  → col || jsonb_build_array(val)
-- ============================================================

-- Tạo bảng mẫu — dùng JSONB (khuyên dùng trong PG)
DROP TABLE IF EXISTS user_profiles;
CREATE TABLE user_profiles (
    user_id   SERIAL PRIMARY KEY,
    profile   JSONB,
    metadata  JSONB
);

INSERT INTO user_profiles (user_id, profile, metadata) VALUES
(1, '{"name": "Alice", "age": 28, "city": "Hanoi", "skills": ["SQL", "Python"]}',
    '{"signup_source": "web", "plan": "premium"}'),
(2, '{"name": "Bob", "age": 34, "city": "Saigon", "skills": ["Java"]}',
    '{"signup_source": "mobile", "plan": "free"}'),
(3, '{"name": "Charlie", "age": 22, "city": "Danang", "skills": ["SQL", "R", "Tableau"]}',
    '{"signup_source": "web", "plan": "premium"}');

-- ============================================================
-- J1. Trích xuất giá trị đơn giản từ JSONB
-- ------------------------------------------------------------
-- MySQL:  profile -> '$.name'  (với dấu $.)
-- PG:     profile -> 'name'    (không có $.; -> trả về JSONB, ->> trả về TEXT)
-- ============================================================
SELECT
    user_id,
    profile -> 'name'              AS name_jsonb,   -- JSONB: "Alice"
    profile ->> 'name'             AS name_text,    -- TEXT:  Alice
    profile ->> 'age'              AS age_text,     -- TEXT:  28
    (profile ->> 'age')::INT       AS age_int       -- INT cast
FROM user_profiles;

-- ============================================================
-- J2. Lọc theo giá trị trong JSONB
-- ------------------------------------------------------------
-- MySQL:  WHERE profile ->> '$.city' = 'Hanoi'
-- PG:     WHERE profile ->> 'city' = 'Hanoi'
--   Hoặc dùng containment operator @>:
--   WHERE profile @> '{"city": "Hanoi"}'
-- ============================================================

-- Cách 1: ->> comparison
SELECT user_id, profile ->> 'name' AS name
FROM user_profiles
WHERE profile ->> 'city' = 'Hanoi';

-- Cách 2: @> containment (JSONB only, có thể dùng GIN index)
SELECT user_id, profile ->> 'name' AS name
FROM user_profiles
WHERE profile @> '{"city": "Hanoi"}';

-- ============================================================
-- J3. Kiểm tra key tồn tại
-- ------------------------------------------------------------
-- MySQL:  JSON_CONTAINS_PATH(col, 'one', '$.skills')
-- PG:     col ? 'key'  (operator ? kiểm tra key tồn tại trong JSONB object)
--         col -> 'arr' IS NOT NULL (kiểm tra path tồn tại)
-- ============================================================
SELECT user_id,
    (profile ? 'skills') AS has_skills    -- ? operator: JSONB only
FROM user_profiles;

-- ============================================================
-- J4. Đếm số phần tử trong array JSONB
-- ------------------------------------------------------------
-- MySQL:  JSON_LENGTH(col, '$.skills')
-- PG:     jsonb_array_length(col -> 'key')
-- ============================================================
SELECT
    user_id,
    profile ->> 'name' AS name,
    jsonb_array_length(profile -> 'skills') AS num_skills
FROM user_profiles;

-- ============================================================
-- J5. Tìm user có skill cụ thể trong array
-- ------------------------------------------------------------
-- MySQL:  JSON_CONTAINS(profile -> '$.skills', '"SQL"')
-- PG:     profile -> 'skills' @> '"SQL"'  (array containment)
-- ============================================================
SELECT user_id, profile ->> 'name' AS name
FROM user_profiles
WHERE profile -> 'skills' @> '"SQL"';    -- '"SQL"' là JSON string literal

-- ============================================================
-- J6. Mở rộng array JSONB thành nhiều dòng
-- ------------------------------------------------------------
-- MySQL:  JSON_TABLE(col -> '$.skills', '$[*]' COLUMNS (...))
-- PG:     jsonb_array_elements_text(col -> 'key') — trả về setof text
--         jsonb_array_elements(col -> 'key')       — trả về setof jsonb
-- ============================================================
SELECT
    up.user_id,
    up.profile ->> 'name' AS name,
    skill
FROM user_profiles up,
     jsonb_array_elements_text(up.profile -> 'skills') AS skill;   -- LATERAL expand

-- ============================================================
-- J7. Tổng hợp: đếm số user theo từng skill
-- ------------------------------------------------------------
-- PG: dùng jsonb_array_elements_text + GROUP BY
-- ============================================================
SELECT skill, COUNT(DISTINCT up.user_id) AS num_users
FROM user_profiles up,
     jsonb_array_elements_text(up.profile -> 'skills') AS skill
GROUP BY skill
ORDER BY num_users DESC;

-- ============================================================
-- J8. Cập nhật một key trong JSONB
-- ------------------------------------------------------------
-- MySQL:  JSON_SET(col, '$.age', 29)
-- PG:     jsonb_set(col, '{age}', '29')
--   Path là text array: '{key}' hoặc '{nested, key}'
-- ============================================================
UPDATE user_profiles
SET profile = jsonb_set(profile, '{age}', '29')
WHERE user_id = 1;

-- ============================================================
-- J9. Thêm phần tử vào array JSONB
-- ------------------------------------------------------------
-- MySQL:  JSON_ARRAY_APPEND(col, '$.skills', 'Airflow')
-- PG:     col || jsonb_build_array('Airflow')  — concatenation operator
--   Hoặc: jsonb_set(col, '{skills}', (col -> 'skills') || '"Airflow"')
-- ============================================================
UPDATE user_profiles
SET profile = jsonb_set(
    profile,
    '{skills}',
    (profile -> 'skills') || '"Airflow"'::jsonb    -- append element
)
WHERE user_id = 2;

-- ============================================================
-- J10. Xóa key khỏi JSONB
-- ------------------------------------------------------------
-- MySQL:  JSON_REMOVE(col, '$.signup_source')
-- PG:     col - 'key'  (operator - xóa key khỏi JSONB object)
-- ============================================================
UPDATE user_profiles
SET metadata = metadata - 'signup_source'    -- operator - : xóa key
WHERE user_id = 3;

-- ============================================================
-- J11. Flatten JSONB thành các cột quan hệ
-- ------------------------------------------------------------
-- MySQL:  JSON_TABLE(col, '$' COLUMNS (...))
-- PG:     jsonb_to_record(col) AS t(col1 TYPE, col2 TYPE, ...)
--   Hoặc: jsonb_populate_record() nếu có composite type
-- ============================================================
SELECT
    up.user_id,
    p.name,
    p.age,
    p.city,
    m.plan
FROM user_profiles up,
     jsonb_to_record(up.profile)   AS p(name TEXT, age INT, city TEXT),
     jsonb_to_record(up.metadata)  AS m(plan TEXT)
WHERE m.plan = 'premium';

-- ============================================================
-- Bonus: GIN Index cho JSONB — tối ưu tìm kiếm
-- ------------------------------------------------------------
-- Tạo GIN index để tăng tốc @>, ?, ?|, ?& operators:
CREATE INDEX IF NOT EXISTS idx_user_profiles_profile_gin
    ON user_profiles USING GIN (profile);

-- Sau khi có index, query J2 Cách 2 và J5 sẽ dùng index scan thay full scan.
-- ============================================================
