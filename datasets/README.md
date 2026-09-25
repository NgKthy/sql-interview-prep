# 📦 Sample CSV Datasets

Thư mục này chứa **toàn bộ dữ liệu mẫu** dạng CSV tương ứng với 3 database trong repo.  
Các file CSV được trích xuất trực tiếp từ các câu lệnh `INSERT INTO` trong thư mục `schemas/`, đảm bảo dữ liệu khớp 100% với schema.

---

## 📂 Cấu trúc file theo Database

### 🗄️ `sql_interview_prep` — Schema: `schemas/01_original_employees.sql`

| File CSV | Bảng | Mô tả |
|---|---|---|
| `employees.csv` | `Employee` | 8 nhân viên với lương, phòng ban, manager |
| `bonus.csv` | `Bonus` | Bonus của nhân viên theo đợt |
| `title.csv` | `Title` | Chức danh: Manager, Executive, Lead... |
| `user_name.csv` | `user_name` | Full name dùng cho bài tách first name |
| `messages_detail.csv` | `messages_detail` | Số tin nhắn gửi mỗi user |
| `dialoglog.csv` | `DIALOGLOG` | Log impression/click theo app — dùng tính CTR |
| `user_details.csv` | `user_details` | Session log của user |
| `event_session_details.csv` | `event_session_details` | Chi tiết session: time spent |
| `login_info.csv` | `login_info` | Lịch sử đăng nhập (dùng tính DAU/WAU) |
| `user_action.csv` | `USER_ACTION` | Hành động kết bạn: sent/accepted/rejected |
| `all_students.csv` | `all_students` | Danh sách học sinh với ngày sinh |
| `attendance_events.csv` | `attendance_events` | Điểm danh học sinh |
| `ad_accounts.csv` | `ad_accounts` | Tài khoản quảng cáo: active/fraud/close |
| `friend_request.csv` | `friend_request` | Lời mời kết bạn đã gửi |
| `request_accepted.csv` | `request_accepted` | Lời mời đã chấp nhận (có duplicate) |
| `new_request_accepted.csv` | `new_request_accepted` | Lời mời chấp nhận (đã dedup) |
| `count_request.csv` | `count_request` | Request gửi theo quốc gia (có cột % dạng string) |
| `confirmation_no.csv` | `confirmation_no` | SĐT đã gửi mã xác nhận |
| `confirmed_no.csv` | `confirmed_no` | SĐT đã xác nhận thành công |
| `user_interaction.csv` | `user_interaction` | Tương tác 2 chiều giữa user |
| `salesperson.csv` | `salesperson` | Danh sách nhân viên bán hàng |
| `customer.csv` | `customer` | Danh sách khách hàng |
| `orders.csv` | `orders` | Đơn hàng liên kết salesperson ↔ customer |
| `event_log.csv` | `event_log` | Log event theo Unix timestamp |

### 🗄️ `product_analytics` — Schema: `schemas/02_product_analytics.sql`

> File có prefix `pa_` để phân biệt với `orders.csv` của `sql_interview_prep`.

| File CSV | Bảng | Mô tả |
|---|---|---|
| `pa_users.csv` | `users` | 6 user với ngày đăng ký |
| `pa_events.csv` | `events` | Click/impression event theo app |
| `pa_orders.csv` | `orders` | Đơn hàng với status (completed/cancelled) |

### 🗄️ `social_network` — Schema: `schemas/03_social_network.sql`

> File có prefix `sn_` để phân biệt.

| File CSV | Bảng | Mô tả |
|---|---|---|
| `sn_friendships.csv` | `friendships` | Quan hệ bạn bè (directed graph) |
| `sn_page_likes.csv` | `page_likes` | User like page nào |

---

## 🚀 Cách import dữ liệu

### Cách 1 — Script PowerShell (Khuyên dùng, Windows)

Script sẽ tự động:
1. Áp 3 schema (tạo DB + bảng)
2. Import toàn bộ CSV theo đúng thứ tự FK

```powershell
# Chạy từ thư mục gốc của repo
.\scripts\import_csv.ps1 -User root -Password "yourpassword"

# Nếu MySQL không cần password
.\scripts\import_csv.ps1 -User root -Password ""

# Tùy chỉnh host/port
.\scripts\import_csv.ps1 -User root -Password "pass" -Host 127.0.0.1 -Port 3306
```

> **Yêu cầu:** MySQL client (`mysql`) phải có trong PATH.  
> Kiểm tra: `mysql --version`

### Cách 2 — LOAD DATA LOCAL INFILE (thủ công)

```sql
-- Bật local infile (cần quyền GLOBAL)
SET GLOBAL local_infile = 1;

USE sql_interview_prep;

-- Ví dụ import bảng Employee
LOAD DATA LOCAL INFILE '/absolute/path/to/datasets/employees.csv'
INTO TABLE Employee
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(EMPLOYEE_ID, FIRST_NAME, LAST_NAME, SALARY, JOINING_DATE, DEPARTMENT, MANAGER_ID);
```

> ⚠️ Phải thay `/absolute/path/to/datasets/` bằng đường dẫn thực trên máy bạn.  
> Trên Windows: `C:/Users/asus/Downloads/J/sql-interview-prep/datasets/employees.csv`

### Cách 3 — MySQL Workbench (GUI)

1. Mở MySQL Workbench → chọn đúng connection
2. Vào **Server → Data Import**
3. Chọn **Import from Self-Contained File** → chọn file schema `.sql`
4. Sau khi có bảng, dùng **Table Data Import Wizard** cho từng CSV

### Cách 4 — Docker (môi trường CI/CD)

```bash
# Áp schema
mysql -h 127.0.0.1 -u root -proot sql_interview_prep < schemas/01_original_employees.sql

# Import CSV (yêu cầu --local-infile=1)
mysql --local-infile=1 -h 127.0.0.1 -u root -proot sql_interview_prep -e "
LOAD DATA LOCAL INFILE 'datasets/employees.csv'
INTO TABLE Employee
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"
```

---

## ⚠️ Lưu ý quan trọng

### Thứ tự import (FK dependency)

Phải import theo thứ tự sau để tránh lỗi Foreign Key:

```
1. Employee           ← không có FK
2. Bonus              ← FK → Employee
3. Title              ← FK → Employee
4. all_students       ← không có FK
5. attendance_events  ← FK → all_students
(các bảng còn lại không có FK, import theo thứ tự tùy ý)
```

### Bật local_infile

MySQL 8.0 tắt `local_infile` theo mặc định. Cần bật trước khi dùng `LOAD DATA LOCAL INFILE`:

```sql
-- Phía server (cần quyền SUPER)
SET GLOBAL local_infile = 1;

-- Phía client (thêm flag khi kết nối)
mysql --local-infile=1 -u root -p
```

### Line endings

Các file CSV trong repo dùng **LF** (`\n`). Nếu bạn dùng Windows và gặp lỗi import:
- Thay `LINES TERMINATED BY '\n'` thành `LINES TERMINATED BY '\r\n'`
- Hoặc convert file: `(Get-Content file.csv) | Set-Content -NoNewline file_unix.csv`

### Cột % dạng string (count_request.csv)

File `count_request.csv` có cột `percent_of_request_sent_failed` lưu dạng `"5.2%"` (có ký tự `%`).  
Đây là thiết kế cố ý để minh họa bài Q39 xử lý data quality bằng `REPLACE + CAST`.
