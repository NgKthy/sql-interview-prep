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

-- ============================================================
-- J1. Trích xuất giá trị đơn giản từ JSON
-- ------------------------------------------------------------
-- Ý tưởng:
--   MySQL lưu JSON dạng chuỗi có cấu trúc. Dùng toán tử -> và ->> để truy cập.
--
-- Phân biệt -> và ->>:
--   ->  : Trả về JSON value (có dấu nháy kép "Alice") — kiểu JSON.
--   ->> : Trả về unquoted string (Alice) — kiểu VARCHAR.
--   CAST(->> AS UNSIGNED): Chuyển string số thành INT.
--
-- Cách 1: Toán tử -> / ->> (MySQL 5.7.9+)
--   - Ưu: Ngắn gọn; tương đương JSON_EXTRACT / JSON_UNQUOTE.
--   - Nhược: Không portable (PostgreSQL dùng -> trả về JSONB, ->> trả về text).
--   - Dùng khi: Truy cập field đơn giản trong JSON object.
--
-- Cách thay thế: JSON_EXTRACT(profile, '$.name') và JSON_UNQUOTE(...)
--
-- Độ phức tạp: O(n) — parse JSON từng dòng.
-- ============================================================
SELECT
    user_id,
    profile -> '$.name'         AS name_json,
    profile ->> '$.name'        AS name_str,
    profile ->> '$.age'         AS age_str,
    CAST(profile ->> '$.age' AS UNSIGNED) AS age_int
FROM user_profiles;

-- ============================================================
-- J2. Lọc theo giá trị trong JSON
-- ------------------------------------------------------------
-- Ý tưởng:
--   Dùng ->> trong WHERE để so sánh JSON field với literal string.
--   MySQL so sánh string thông thường sau khi unquote.
--
-- Cách 1: WHERE profile ->> '$.city' = 'Hanoi'
--   - Ưu: Trực quan; MySQL tự unquote trước khi so sánh.
--   - Nhược: Không dùng được index thông thường — cần Generated Column + index.
--   - Dùng khi: Bảng nhỏ; hoặc đã tạo functional index trên JSON field.
--
-- Tối ưu với Generated Column:
--   ALTER TABLE user_profiles ADD city VARCHAR(50) GENERATED ALWAYS AS (profile->>'$.city');
--   CREATE INDEX idx_city ON user_profiles(city);
--
-- Độ phức tạp: O(n) — full scan + JSON parse mỗi dòng.
-- ============================================================
SELECT user_id, profile ->> '$.name' AS name
FROM user_profiles
WHERE profile ->> '$.city' = 'Hanoi';

-- ============================================================
-- J3. Kiểm tra key tồn tại
-- ------------------------------------------------------------
-- Ý tưởng:
--   JSON_CONTAINS_PATH(json, one/all, path...) kiểm tra path có tồn tại không.
--   'one': trả về 1 nếu ÍT NHẤT 1 path tồn tại.
--   'all': trả về 1 nếu TẤT CẢ path đều tồn tại.
--
-- Cách 1: JSON_CONTAINS_PATH(col, 'one', '$.key')
--   - Ưu: Tường minh; phân biệt key không tồn tại vs key có giá trị NULL.
--   - Nhược: Không portable (PostgreSQL dùng ? operator cho JSONB).
--   - Dùng khi: Schema linh hoạt — không phải object nào cũng có field đó.
--
-- Độ phức tạp: O(n) — check path trong JSON mỗi dòng.
-- ============================================================
SELECT user_id, JSON_CONTAINS_PATH(profile, 'one', '$.skills') AS has_skills
FROM user_profiles;

-- ============================================================
-- J4. Đếm số phần tử trong array JSON
-- ------------------------------------------------------------
-- Ý tưởng:
--   JSON_LENGTH(json, path) đếm số phần tử tại path.
--   Nếu path là array → đếm số phần tử; nếu là object → đếm số key.
--
-- Cách 1: JSON_LENGTH(col, '$.array_field')
--   - Ưu: Đơn giản, trực tiếp.
--   - Nhược: Trả về NULL nếu path không tồn tại — nên dùng COALESCE.
--   - Dùng khi: Đếm số item trong JSON array lồng ghép.
--
-- Độ phức tạp: O(n) — duyệt array trong JSON mỗi dòng.
-- ============================================================
SELECT
    user_id,
    profile ->> '$.name' AS name,
    JSON_LENGTH(profile, '$.skills') AS num_skills
FROM user_profiles;

-- ============================================================
-- J5. Tìm user có skill cụ thể trong array
-- ------------------------------------------------------------
-- Ý tưởng:
--   JSON_CONTAINS(json_doc, val, path) kiểm tra json_doc có chứa val tại path không.
--   Để tìm "SQL" trong array skills: val = '"SQL"' (string JSON, bao gồm nháy kép).
--
-- Cách 1: JSON_CONTAINS(profile -> '$.skills', '"SQL"')
--   - Ưu: Tìm kiếm trong array JSON mà không cần unnest.
--   - Nhược: Val phải là JSON string ("SQL" với nháy kép), dễ nhầm.
--   - Dùng khi: Tag-based filtering, skill matching.
--
-- Lưu ý: JSON_CONTAINS(json, '"SQL"') khác JSON_CONTAINS(json, 'SQL').
--   Phải dùng '"SQL"' (nháy kép trong chuỗi) hoặc JSON_QUOTE('SQL').
--
-- Độ phức tạp: O(n * k) — k là số phần tử trong array; n là số dòng.
-- ============================================================
SELECT user_id, profile ->> '$.name' AS name
FROM user_profiles
WHERE JSON_CONTAINS(profile -> '$.skills', '"SQL"');

-- ============================================================
-- J6. Mở rộng array JSON thành nhiều dòng (JSON_TABLE)
-- ------------------------------------------------------------
-- Ý tưởng:
--   JSON_TABLE() là table-valued function (MySQL 8.0+) — chuyển JSON array
--   thành bảng quan hệ (1 phần tử = 1 dòng). Tương tự UNNEST trong PostgreSQL.
--
-- Cách 1: FROM ... , JSON_TABLE(col -> '$.arr', '$[*]' COLUMNS (...))
--   - Ưu: Mạnh mẽ; kết hợp được với JOIN, GROUP BY, WHERE.
--   - Nhược: MySQL 8.0+ only; cú pháp phức tạp; chậm với JSON lớn.
--   - Dùng khi: Cần "unnest" JSON array để phân tích từng phần tử.
--
-- Cú pháp quan trọng:
--   '$[*]' — duyệt mọi phần tử trong array.
--   COLUMNS (col TYPE PATH '$') — mapping phần tử thành cột.
--
-- Độ phức tạp: O(n * k) — n dòng, k phần tử array mỗi dòng.
-- ============================================================
SELECT
    up.user_id,
    up.profile ->> '$.name' AS name,
    jt.skill
FROM user_profiles up,
     JSON_TABLE(
         up.profile -> '$.skills',
         '$[*]' COLUMNS (skill VARCHAR(50) PATH '$')
     ) AS jt;

-- ============================================================
-- J7. Tổng hợp: đếm số user theo từng skill
-- ------------------------------------------------------------
-- Ý tưởng:
--   Kết hợp JSON_TABLE với GROUP BY để tạo "skill popularity report".
--   Mỗi skill thành 1 dòng (unnest) → GROUP BY skill → COUNT user.
--
-- Cách 1: JSON_TABLE + GROUP BY + COUNT(DISTINCT)
--   - Ưu: Phân tích multi-value attribute mà không cần bảng pivot riêng.
--   - Nhược: Tốn kém với JSON array dài; cân nhắc denormalize ra bảng riêng.
--   - Dùng khi: Báo cáo phân phối tag/label/skill lưu trong JSON.
--
-- Độ phức tạp: O(n * k * log(n*k)) — unnest + GROUP BY sort.
-- ============================================================
SELECT jt.skill, COUNT(DISTINCT up.user_id) AS num_users
FROM user_profiles up,
     JSON_TABLE(
         up.profile -> '$.skills',
         '$[*]' COLUMNS (skill VARCHAR(50) PATH '$')
     ) AS jt
GROUP BY jt.skill
ORDER BY num_users DESC;

-- ============================================================
-- J8. Cập nhật một key trong JSON
-- ------------------------------------------------------------
-- Ý tưởng:
--   JSON_SET(json, path, new_value) — cập nhật hoặc thêm key nếu chưa có.
--   Khác JSON_REPLACE (chỉ cập nhật nếu key đã tồn tại).
--
-- Phân biệt JSON mutation functions:
--   JSON_SET:     Thêm hoặc cập nhật key.
--   JSON_INSERT:  Chỉ thêm nếu key CHƯA tồn tại (không ghi đè).
--   JSON_REPLACE: Chỉ cập nhật nếu key ĐÃ tồn tại (không thêm mới).
--   JSON_REMOVE:  Xóa key khỏi JSON.
--
-- Cách 1: UPDATE SET col = JSON_SET(col, path, val)
--   - Ưu: Atomic update — không cần đọc, sửa, ghi lại từ app layer.
--   - Nhược: Cập nhật cột JSON ảnh hưởng hiệu năng; không selective index.
--   - Dùng khi: Cập nhật 1 field trong JSON mà không muốn overwrite toàn bộ.
--
-- Độ phức tạp: O(n) — parse + serialize JSON, n là số dòng update.
-- ============================================================
UPDATE user_profiles
SET profile = JSON_SET(profile, '$.age', 29)
WHERE user_id = 1;

-- ============================================================
-- J9. Thêm phần tử vào array JSON
-- ------------------------------------------------------------
-- Ý tưởng:
--   JSON_ARRAY_APPEND(json, path, val) thêm val vào CUỐI array tại path.
--   Không replace array — chỉ append element mới.
--
-- Cách 1: JSON_ARRAY_APPEND(col, '$.arr_field', new_element)
--   - Ưu: Append không cần đọc array, xử lý, ghi lại từ application.
--   - Nhược: Không kiểm tra trùng lặp — có thể append duplicate.
--   - Dùng khi: Thêm tag/skill/label vào danh sách trong JSON.
--
-- Độ phức tạp: O(k) — k là số phần tử hiện tại trong array.
-- ============================================================
UPDATE user_profiles
SET profile = JSON_ARRAY_APPEND(profile, '$.skills', 'Airflow')
WHERE user_id = 2;

-- ============================================================
-- J10. Xóa key khỏi JSON
-- ------------------------------------------------------------
-- Ý tưởng:
--   JSON_REMOVE(json, path) xóa field/element tại path.
--   Không lỗi nếu path không tồn tại — idempotent.
--
-- Cách 1: JSON_REMOVE(col, '$.key')
--   - Ưu: An toàn — không lỗi khi key không tồn tại.
--   - Nhược: Không kiểm tra key có tồn tại hay không trước khi xóa.
--   - Dùng khi: GDPR compliance — xóa PII field từ JSON; cleanup obsolete fields.
--
-- Độ phức tạp: O(n) — rebuild JSON object sau khi xóa key.
-- ============================================================
UPDATE user_profiles
SET metadata = JSON_REMOVE(metadata, '$.signup_source')
WHERE user_id = 3;

-- ============================================================
-- J11. Trích xuất nhiều cột từ JSON_TABLE (flatten toàn bộ)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Dùng 2 JSON_TABLE song song (lateral join style) để flatten cả profile lẫn metadata
--   thành bảng quan hệ phẳng. Lọc theo metadata.plan = 'premium'.
--
-- Cách 1: 2 JSON_TABLE trong FROM clause
--   - Ưu: Chuyển semi-structured JSON thành relational table trong 1 query.
--   - Nhược: Cú pháp phức tạp; mỗi JSON_TABLE tạo 1 "virtual table".
--   - Dùng khi: ETL in-database, cần flatten JSON ra bảng để báo cáo.
--
-- Lưu ý: Tên alias jt và jt2 phải khác nhau.
--   jt.user_id trong SELECT phải có trong COLUMNS của jt — query này thiếu user_id
--   trong COLUMNS của jt (bug nhỏ: nên thêm COLUMNS (user_id INT PATH '$' ERROR ON ERROR)).
--
-- Độ phức tạp: O(n) — 1 lần scan bảng, parse 2 JSON columns mỗi dòng.
-- ============================================================
SELECT
    jt.user_id,
    jt.name,
    jt.age,
    jt.city,
    jt2.plan
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
