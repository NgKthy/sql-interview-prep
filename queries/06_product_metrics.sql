-- ============================================================
-- 06_product_metrics.sql
-- Chủ đề: Product metrics (CTR, retention, acceptance, fraud)
-- Nguồn: Q26-Q32, Q36-Q39, Q41, Q42
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- Q26. % học sinh đi học đúng ngày sinh nhật
-- ------------------------------------------------------------
-- Ý tưởng:
--   Đếm số sự kiện điểm danh mà ngày diễn ra trùng tháng và ngày
--   sinh nhật của học sinh, chia cho tổng số sự kiện.
--
-- Cách 1: JOIN + MONTH/DAY comparison + subquery tổng
--   - Ưu: Rõ logic; MONTH() và DAY() đơn giản hóa so sánh ngày.
--   - Nhược: Không dùng được index trên date_event / date_of_birth (hàm trên cột).
--   - Dùng khi: Bảng nhỏ; phân tích birthday engagement.
--
-- Lưu ý: Tử số đếm cả 'absent' và 'present' nếu không lọc attendance.
--   Nếu chỉ muốn đếm đi học: thêm AND ae.attendance = 'present'.
--
-- Độ phức tạp: O(n*m) — JOIN students + attendance; không có index bitmap ngày sinh.
-- ============================================================
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

-- ============================================================
-- Q27. User active đủ 7 ngày trong tuần (mobile)
-- ------------------------------------------------------------
-- Ý tưởng:
--   Lọc login trong 7 ngày (10-16/08), đếm số ngày DISTINCT mỗi user đã login.
--   Chỉ giữ user có đúng 7 ngày khác nhau.
--
-- Cách 1: GROUP BY user_id + HAVING COUNT(DISTINCT DATE(login_time)) = 7
--   - Ưu: Gọn; COUNT(DISTINCT DATE()) đảm bảo tính ngày, không tính lần.
--   - Nhược: Hàm DATE() trên login_time phá index; bảng lớn nên tạo cột date riêng.
--   - Dùng khi: Đo daily active users (DAU) hoặc weekly active users (WAU).
--
-- Lưu ý: BETWEEN '2017-08-10' AND '2017-08-16' bao gồm cả 2 đầu mút = 7 ngày.
--
-- Độ phức tạp: O(n log n) — GROUP BY + HAVING.
-- ============================================================
SELECT COUNT(*) AS active_all_7_days
FROM (
    SELECT user_id
    FROM login_info
    WHERE login_time BETWEEN '2017-08-10' AND '2017-08-16'
    GROUP BY user_id
    HAVING COUNT(DISTINCT DATE(login_time)) = 7
) t;

-- ============================================================
-- Q28. Tỷ lệ chấp nhận lời mời kết bạn trong ngày 2018-05-24
-- ------------------------------------------------------------
-- Ý tưởng:
--   Trong ngày 24/05, đếm số hành động 'accepted' chia cho tổng hành động.
--   Dùng conditional aggregation (CASE WHEN) thay vì 2 subquery riêng.
--
-- Cách 1: SUM(CASE WHEN) / COUNT(*) — conditional aggregation
--   - Ưu: 1 lần scan bảng; dễ mở rộng thêm nhiều điều kiện.
--   - Nhược: DATE(date_action) phá index; nên WHERE date_action = DATETIME range.
--   - Dùng khi: Tính tỷ lệ / proportion trong 1 query.
--
-- Cách thay thế: AVG(action = 'accepted') — MySQL trick, trả về 0/1.
--   SELECT ROUND(AVG(action = 'accepted') * 100, 2) FROM user_action WHERE ...
--
-- Độ phức tạp: O(n) — một lần scan với filter ngày.
-- ============================================================
SELECT
    ROUND(
        SUM(CASE WHEN action = 'accepted' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS acceptance_rate
FROM user_action
WHERE DATE(date_action) = '2018-05-24';

-- ============================================================
-- Q29. Tổng user follow ít nhất 1 sport account
-- ------------------------------------------------------------
-- Ý tưởng:
--   JOIN follow_relation với sport_accounts để tìm follower của tài khoản thể thao.
--   COUNT(DISTINCT) đảm bảo mỗi user chỉ tính 1 lần dù follow nhiều tài khoản.
--
-- Cách 1: JOIN + COUNT(DISTINCT follower_id)
--   - Ưu: Đơn giản, 1 lần scan 2 bảng.
--   - Nhược: Nếu bảng follow_relation rất lớn, DISTINCT tốn bộ nhớ.
--   - Dùng khi: Đo reach / audience size của một category.
--
-- Cách thay thế: EXISTS subquery — cho từng follower kiểm tra có follow sport không.
--
-- Độ phức tạp: O(n log n) — JOIN + DISTINCT.
-- ============================================================
SELECT COUNT(DISTINCT fr.follower_id) AS total_sport_followers
FROM follow_relation fr
JOIN sport_accounts sa ON fr.target_id = sa.sport_player_id;

-- ============================================================
-- Q30. Số active user follow từng môn thể thao
-- ------------------------------------------------------------
-- Ý tưởng:
--   Kết hợp 3 bảng: follow_relation → sport_accounts (lấy category)
--   → all_users (lọc active). GROUP BY sport_category đếm follower active.
--
-- Cách 1: 3-bảng JOIN + WHERE active + GROUP BY
--   - Ưu: Rõ ràng logic phễu: follow → sport → active.
--   - Nhược: 3 JOIN có thể tốn kém; cần index trên FK và active_last_month.
--   - Dùng khi: Phân tích engagement theo category.
--
-- Độ phức tạp: O(n*m*k) — 3 bảng JOIN; tối ưu với index.
-- ============================================================
SELECT sa.sport_category, COUNT(DISTINCT fr.follower_id) AS active_followers
FROM follow_relation fr
JOIN sport_accounts sa ON fr.target_id = sa.sport_player_id
JOIN all_users u       ON fr.follower_id = u.user_id
WHERE u.active_last_month = 1
GROUP BY sa.sport_category;

-- ============================================================
-- Q31. % tài khoản active bị fraud
-- ------------------------------------------------------------
-- Ý tưởng:
--   Đếm số account distinct có status 'fraud', chia cho số account distinct 'active'.
--   Hai subquery độc lập — mỗi subquery scan bảng 1 lần.
--
-- Cách 1: Hai subquery inline
--   - Ưu: Dễ đọc; COUNT(DISTINCT) đảm bảo không đếm trùng account.
--   - Nhược: Scan bảng 2 lần; dùng NULLIF để tránh chia cho 0.
--   - Dùng khi: Tính tỷ lệ fraud — bài toán trust & safety phổ biến.
--
-- Cách thay thế: Dùng SUM(CASE WHEN)/COUNT — 1 lần scan nhưng phức tạp hơn.
--
-- Lưu ý: Phân biệt "account bị fraud" vs "account active". Nếu 1 account có cả
--   hai trạng thái (nhiều row), DISTINCT xử lý đúng.
--
-- Độ phức tạp: O(n) — 2 lần scan bảng.
-- ============================================================
SELECT
    ROUND(
        (SELECT COUNT(DISTINCT account_id) FROM ad_accounts WHERE account_status = 'fraud') * 100.0
        / (SELECT COUNT(DISTINCT account_id) FROM ad_accounts WHERE account_status = 'active'),
        2
    ) AS percent_active_fraud;

-- ============================================================
-- Q32. Số account trở thành fraud LẦN ĐẦU trong hôm nay
-- ------------------------------------------------------------
-- Ý tưởng:
--   Account "lần đầu fraud hôm nay" = account có đúng 1 record fraud
--   VÀ record fraud duy nhất đó là hôm nay.
--   Dùng conditional HAVING để kiểm tra cả 2 điều kiện sau GROUP BY.
--
-- Cách 1: GROUP BY + HAVING với 2 điều kiện CASE WHEN
--   - Ưu: Tất cả logic gói trong GROUP BY + HAVING, không cần JOIN thêm.
--   - Nhược: Phức tạp khi đọc; cần hiểu SUM(CASE) = đếm có điều kiện.
--   - Dùng khi: Bài toán "first-time event" — phổ biến trong fraud detection.
--
-- Logic HAVING:
--   SUM(CASE WHEN fraud THEN 1) = 1 → chỉ có 1 lần fraud
--   MAX(CASE WHEN fraud THEN date) = CURDATE() → lần fraud đó là hôm nay
--
-- Độ phức tạp: O(n log n) — GROUP BY + HAVING.
-- ============================================================
SELECT COUNT(*) AS first_time_fraud_today
FROM (
    SELECT account_id
    FROM ad_accounts
    GROUP BY account_id
    HAVING SUM(CASE WHEN account_status = 'fraud' THEN 1 ELSE 0 END) = 1
       AND MAX(CASE WHEN account_status = 'fraud' THEN date END) = CURDATE()
) t;

-- ============================================================
-- Q33. Thời gian sử dụng trung bình mỗi user mỗi ngày
-- ------------------------------------------------------------
-- Ý tưởng:
--   GROUP BY (ngày, user_id) để tính AVG time_spent mỗi user mỗi ngày.
--   DATE(date) chuyển DATETIME → DATE để nhóm theo ngày.
--
-- Cách 1: GROUP BY DATE(date), user_id + AVG
--   - Ưu: Đơn giản; ROUND để làm tròn kết quả.
--   - Nhược: DATE() trên cột phá index; với bảng lớn nên có cột date riêng.
--   - Dùng khi: Tính daily average time — metric phổ biến trong product analytics.
--
-- Độ phức tạp: O(n log n) — GROUP BY 2 cột.
-- ============================================================
SELECT
    DATE(date) AS day,
    user_id,
    ROUND(AVG(timespend_sec), 2) AS avg_time_spent
FROM event_session_details
GROUP BY DATE(date), user_id
ORDER BY day, user_id;

-- ============================================================
-- Q36. CTR theo từng app
-- ------------------------------------------------------------
-- Ý tưởng:
--   CTR = clicks / impressions. Dùng conditional aggregation để tính
--   cả clicks và impressions trong 1 lần scan, tránh 2 subquery riêng.
--   NULLIF tránh chia cho 0 khi app không có impression.
--
-- Cách 1: SUM(CASE) / NULLIF(SUM(CASE), 0) — conditional aggregation
--   - Ưu: 1 lần scan bảng; NULLIF xử lý chia cho 0 an toàn.
--   - Nhược: Cú pháp hơi dài; có thể dùng AVG(type='click') trong MySQL.
--   - Dùng khi: Tính tỷ lệ từ 2 loại event trong cùng bảng.
--
-- Công thức: CTR = total_clicks / total_impressions (không phải per-user CTR)
--
-- Độ phức tạp: O(n) — một lần scan DIALOGLOG.
-- ============================================================
SELECT
    app_id,
    ROUND(
        SUM(CASE WHEN type = 'click' THEN 1 ELSE 0 END) * 1.0
        / NULLIF(SUM(CASE WHEN type = 'impression' THEN 1 ELSE 0 END), 0),
        4
    ) AS ctr
FROM DIALOGLOG
GROUP BY app_id;

-- ============================================================
-- Q37. Tỷ lệ chấp nhận lời mời kết bạn tổng thể
-- ------------------------------------------------------------
-- Ý tưởng:
--   Acceptance rate = unique accepted pairs / unique sent requests.
--   Cần DISTINCT vì có thể có duplicate request hoặc acceptance.
--
-- Cách 1: 2 subquery đếm DISTINCT pairs
--   - Ưu: Tường minh, đảm bảo đúng nghĩa "unique pairs".
--   - Nhược: Cú pháp phức tạp; scan 2 bảng; NULLIF tránh chia 0.
--   - Dùng khi: Bài toán graph-based social network metrics.
--
-- Lưu ý: Kết quả < 1.0 (tỷ lệ), không phải % — nhân 100 để ra phần trăm.
--
-- Độ phức tạp: O(n + m) — n: request_accepted, m: friend_request.
-- ============================================================
SELECT
    ROUND(
        (SELECT COUNT(*) FROM (SELECT DISTINCT acceptor_id, requestor_id FROM request_accepted) a)
        / NULLIF((SELECT COUNT(*) FROM (SELECT DISTINCT requestor_id, sent_to_id FROM friend_request) b), 0),
        4
    ) AS acceptance_rate;

-- ============================================================
-- Q38. User có nhiều bạn nhất
-- ------------------------------------------------------------
-- Ý tưởng:
--   Tình bạn là 2 chiều: cả requestor lẫn acceptor đều là "bạn" của nhau.
--   UNION ALL để gộp cả 2 chiều, sau đó đếm và lấy top-1.
--
-- Cách 1: UNION ALL 2 chiều + GROUP BY + LIMIT 1
--   - Ưu: Xử lý đúng đồ thị vô hướng (undirected graph); UNION ALL nhanh hơn UNION.
--   - Nhược: Nếu có tie (2 người cùng số bạn), chỉ lấy 1 người — không nhất quán.
--   - Dùng khi: Tìm most-connected node trong social network.
--
-- Cách xử lý tie: Thay LIMIT 1 bằng HAVING friend_count = MAX(friend_count).
--
-- Độ phức tạp: O(n log n) — UNION ALL + GROUP BY + sort.
-- ============================================================
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

-- ============================================================
-- Q39. Tổng request gửi và gửi thất bại theo quốc gia
-- ------------------------------------------------------------
-- Ý tưởng:
--   Cột percent_of_request_sent_failed lưu dạng TEXT ('5.2%').
--   Cần REPLACE để loại '%', CAST để chuyển số, rồi tính tổng/trung bình.
--
-- Cách 1: REPLACE + CAST + GROUP BY country_code
--   - Ưu: Xử lý data quality issue (lưu % dạng string) ngay trong query.
--   - Nhược: REPLACE + CAST tốn CPU; nên chuẩn hóa cột về kiểu DECIMAL.
--   - Dùng khi: Data đến dạng chuỗi có ký tự đặc biệt (%), cần parse inline.
--
-- Lưu ý thiết kế: Nên lưu percent_failed là DECIMAL(5,2), không phải CHAR.
--
-- Độ phức tạp: O(n) — một lần scan + GROUP BY.
-- ============================================================
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

-- ============================================================
-- Q41. % số điện thoại xác nhận thành công
-- ------------------------------------------------------------
-- Ý tưởng:
--   confirmation_no: tất cả SĐT đã gửi mã xác nhận.
--   confirmed_no: SĐT đã xác nhận thành công.
--   LEFT JOIN để giữ tất cả SĐT gốc; COUNT(cn.phone_number) chỉ đếm dòng matched.
--
-- Cách 1: LEFT JOIN + COUNT(matched col) / subquery tổng
--   - Ưu: LEFT JOIN giúp giữ tất cả SĐT gốc; COUNT(cn.col) tự bỏ qua NULL.
--   - Nhược: Subquery COUNT(*) chạy thêm 1 lần; có thể tối ưu bằng window function.
--   - Dùng khi: Tính tỷ lệ thành công của một pipeline.
--
-- Lưu ý: COUNT(cn.phone_number) chỉ đếm dòng có match (không NULL) — đây là trick
--   quan trọng khi dùng LEFT JOIN để đếm.
--
-- Độ phức tạp: O(n log m) — LEFT JOIN + subquery.
-- ============================================================
SELECT
    ROUND(
        COUNT(cn.phone_number) * 100.0
        / (SELECT COUNT(*) FROM confirmation_no),
        2
    ) AS confirm_percent
FROM confirmation_no conf
LEFT JOIN confirmed_no cn ON cn.phone_number = conf.phone_number;

-- ============================================================
-- Q42. User có >= 4 interaction ngày 2019-03-23
-- ------------------------------------------------------------
-- Ý tưởng:
--   user_interaction lưu cặp (user_1, user_2) — mỗi interaction liên quan 2 user.
--   Cần đếm interaction của từng user từ CẢ 2 cột (user_1 và user_2).
--   UNION ALL để gộp 2 chiều, rồi GROUP BY user_id + HAVING.
--
-- Cách 1: UNION ALL 2 chiều + GROUP BY + HAVING >= 4
--   - Ưu: Đúng ngữ nghĩa "interaction" của user (cả gửi và nhận).
--   - Nhược: Scan bảng 2 lần (2 nhánh UNION ALL).
--   - Dùng khi: Bảng edge list (undirected graph) — mỗi cạnh liên quan 2 đỉnh.
--
-- Cách thay thế: Dùng UNPIVOT (SQL Server) hoặc VALUES / LATERAL JOIN.
--
-- Độ phức tạp: O(n log n) — 2 scan + GROUP BY + HAVING.
-- ============================================================
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
