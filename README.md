# 🗃️ SQL Interview Prep — Data Analyst / Data Engineer / Data Scientist

[![Test SQL Queries](https://github.com/NgKthy/sql-interview-prep/actions/workflows/test.yml/badge.svg)](https://github.com/NgKthy/sql-interview-prep/actions/workflows/test.yml)
![MySQL Version](https://img.shields.io/badge/MySQL-8.0%2B-blue?logo=mysql)
![PostgreSQL Version](https://img.shields.io/badge/PostgreSQL-14%2B-slategray?logo=postgresql)
![License](https://img.shields.io/badge/License-MIT-green)

Bộ tài liệu tổng hợp và luyện tập **SQL Interview** đầy đủ dành cho các vị trí **Data Analyst (DA), Data Scientist (DS), Data Engineer (DE)** và **Business Analyst (BA)**. 

Tài liệu được thiết kế bám sát thực tế các bài test và vòng phỏng vấn kỹ thuật từ các công ty công nghệ tên tuổi (**Meta, Visa, Wayfair, FAANG**) cũng như các nền tảng phỏng vấn hàng đầu như **LeetCode Top 50 SQL** và **DataLemur**.

---

## 🌟 Tính Năng Nổi Bật

- 📱 **Giao diện Web tương tác (`index.html`):** Tra cứu query trực quan, hỗ trợ highlight cú pháp (Highlight.js Atom One Dark), tìm kiếm theo từ khóa real-time và sao chép 1-click.
- 🔄 **Hỗ trợ 2 Hệ Quản Trị CSDL Phổ Biến (MySQL & PostgreSQL):** Mọi chủ đề đều có phiên bản MySQL gốc và bản port tương thích 100% với PostgreSQL.
- 📊 **Phủ rộng từ Cơ Bản đến Nâng Cao:** Tích hợp đầy đủ các chủ đề quan trọng nhất trong phỏng vấn: *Window Functions, Recursive CTE, JSON parsing, Performance Tuning, Cohort Analysis, RFM Segmentation, Funnel Analysis, Stored Procedures*.
- 🐍 **So sánh SQL vs Pandas (`18_pandas_vs_sql.sql`):** Giúp Data Analyst / Scientist dễ dàng chuyển đổi tư duy giữa SQL và Python.
- ⚙️ **Tự động kiểm thử với GitHub Actions (CI/CD):** Mỗi commit đều được kiểm tra tính đúng đắn của cú pháp SQL trên môi trường MySQL thật.

---

## 📂 Cấu Trúc Thư Mục Project

```text
sql-interview-prep/
├── index.html                   # Giao diện Web tra cứu SQL interactive
├── manifest.json                # Định cấu hình danh mục & ánh xạ file SQL cho Web UI
├── README.md                    # Tài liệu hướng dẫn sử dụng repository
│
├── queries/                     # 18 Module SQL cho MySQL 8.0+
│   ├── 00_original_queries.sql  # Tổng hợp bài tập phỏng vấn gốc (Visa, Wayfair, Meta, v.v.)
│   ├── 01_basic.sql             # Aggregate, GROUP BY, ORDER BY, HAVING, Top N
│   ├── 02_string_date.sql       # Hàm xử lý chuỗi (CONCAT, SUBSTRING) & Ngày tháng (DATEDIFF)
│   ├── 03_self_join.sql         # Self Join, so sánh nhân viên - quản lý, sự kiện liên tiếp
│   ├── 04_subquery.sql          # Subquery, Correlated Subquery, EXISTS vs IN vs JOIN
│   ├── 05_joins.sql             # INNER, LEFT, RIGHT, FULL OUTER, CROSS JOIN
│   ├── 06_product_metrics.sql   # Product metrics: CTR, Retention, User Fraud, Acceptance Rate
│   ├── 07_histogram.sql         # Phân bố dữ liệu (Histogram & Bucketing)
│   ├── 08_window_functions.sql  # ROW_NUMBER, RANK, DENSE_RANK, LAG/LEAD, Moving Average
│   ├── 09_cte_recursive.sql     # CTE (WITH clause) & Recursive CTE căn bản
│   ├── 10_set_operations.sql    # UNION, UNION ALL, INTERSECT, EXCEPT
│   ├── 11_leetcode_top50.sql    # Lời giải các bài SQL phổ biến trên LeetCode Top 50
│   ├── 12_datalemur.sql         # Lời giải các bài phỏng vấn FAANG trên DataLemur
│   ├── 13_json_functions.sql    # Xử lý dữ liệu bán cấu trúc JSON (JSON_EXTRACT, JSON_TABLE)
│   ├── 14_performance_tuning.sql# Đọc EXPLAIN, tạo INDEX, Covering Index & fix Anti-patterns
│   ├── 15_stored_procedures.sql # Stored Procedure, Stored Function, Trigger & View
│   ├── 16_recursive_org_chart.sql# Cấu trúc hình cây: Sơ đồ tổ chức (Org Chart) & Bill of Materials
│   ├── 17_advanced_analytics.sql # Analytics nâng cao: Cohort Analysis, Conversion Funnel, RFM
│   └── 18_pandas_vs_sql.sql     # So sánh cú pháp trực tiếp giữa SQL & Python Pandas
│
├── postgresql/                  # Bản port toàn bộ 18 module sang PostgreSQL 14+
│   ├── 01_basic.sql
│   ├── ...
│   └── 18_pandas_vs_sql.sql
│
├── schemas/                     # Các file khởi tạo Schema & Insert Data mẫu
│   ├── 00_original_schema.sql   # Schema cho danh sách câu hỏi phỏng vấn gốc
│   ├── 01_original_employees.sql# Schema mở rộng: Employee, Bonus, Title, Products, User Actions...
│   ├── 02_product_analytics.sql # Schema cho phân tích sản phẩm (CTR, Funnel, Conversions)
│   └── 03_social_network.sql    # Schema mạng xã hội (Friendships, Page Likes, Messages)
│
├── scripts/                     # Kịch bản hỗ trợ phát triển local
│   ├── serve.ps1                # PowerShell script khởi chạy Web Server nhanh cho local
│   └── import_csv.ps1           # Script import tự động dữ liệu từ CSV vào MySQL
│
└── .github/workflows/
    └── test.yml                 # Workflow CI/CD kiểm thử SQL tự động trên GitHub Actions
```

---

## 📚 Danh Mục Bài Học & Bài Tập SQL

| STT | Module Topic | Mô Tả Nội Dung | MySQL File | PostgreSQL File |
| :---: | :--- | :--- | :---: | :---: |
| **00** | **Original Questions** | Các câu hỏi phỏng vấn thực tế từ Visa, Wayfair, Meta, Startups | [`00_original_queries.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/00_original_queries.sql) | — |
| **01** | **Basic SQL** | Aggregate functions, GROUP BY, HAVING, ORDER BY, Top N | [`01_basic.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/01_basic.sql) | [`01_basic.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/01_basic.sql) |
| **02** | **String & Date** | Hàm xử lý chuỗi (`LIKE`, `REGEX`, `SUBSTR`) & Ngày tháng | [`02_string_date.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/02_string_date.sql) | [`02_string_date.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/02_string_date.sql) |
| **03** | **Self Join** | Ghép bảng với chính nó, so sánh nhân viên vs quản lý | [`03_self_join.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/03_self_join.sql) | [`03_self_join.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/03_self_join.sql) |
| **04** | **Subqueries** | Subquery lồng nhau, Correlated Subquery, `EXISTS` vs `IN` | [`04_subquery.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/04_subquery.sql) | [`04_subquery.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/04_subquery.sql) |
| **05** | **Joins Master** | Thấu hiểu INNER, LEFT, RIGHT, FULL OUTER, CROSS JOIN | [`05_joins.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/05_joins.sql) | [`05_joins.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/05_joins.sql) |
| **06** | **Product Metrics** | Phân tích Chỉ số Sản Phẩm: CTR, Retention Rate, User Fraud | [`06_product_metrics.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/06_product_metrics.sql) | [`06_product_metrics.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/06_product_metrics.sql) |
| **07** | **Histogram** | Gom nhóm dữ liệu dạng dải (Bucketing / Binning) | [`07_histogram.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/07_histogram.sql) | [`07_histogram.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/07_histogram.sql) |
| **08** | **Window Functions** | `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`/`LEAD`, Moving Avg | [`08_window_functions.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/08_window_functions.sql) | [`08_window_functions.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/08_window_functions.sql) |
| **09** | **CTE & Recursive** | Common Table Expressions và kỹ thuật Recursive CTE cơ bản | [`09_cte_recursive.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/09_cte_recursive.sql) | [`09_cte_recursive.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/09_cte_recursive.sql) |
| **10** | **Set Operations** | Thao tác tập hợp: `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT` | [`10_set_operations.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/10_set_operations.sql) | [`10_set_operations.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/10_set_operations.sql) |
| **11** | **LeetCode Top 50** | Tuyển tập lời giải chi tiết cho 50 bài SQL phổ biến nhất | [`11_leetcode_top50.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/11_leetcode_top50.sql) | [`11_leetcode_top50.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/11_leetcode_top50.sql) |
| **12** | **DataLemur** | Lời giải các bài toán SQL phỏng vấn FAANG nổi tiếng | [`12_datalemur.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/12_datalemur.sql) | [`12_datalemur.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/12_datalemur.sql) |
| **13** | **JSON Functions** | Truy vấn dữ liệu JSON (`JSON_EXTRACT`, `JSON_TABLE`, `jsonb`) | [`13_json_functions.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/13_json_functions.sql) | [`13_json_functions.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/13_json_functions.sql) |
| **14** | **Performance Tuning** | Tối ưu truy vấn: Đọc `EXPLAIN`, tạo Index, Covering Index | [`14_performance_tuning.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/14_performance_tuning.sql) | [`14_performance_tuning.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/14_performance_tuning.sql) |
| **15** | **Stored Procedures** | Lập trình CSDL: Procedure, Function, Trigger, Views | [`15_stored_procedures.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/15_stored_procedures.sql) | [`15_stored_procedures.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/15_stored_procedures.sql) |
| **16** | **Recursive Org Chart** | Duyệt cây đệ quy: Sơ đồ tổ chức (Org Chart), Bill of Materials | [`16_recursive_org_chart.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/16_recursive_org_chart.sql) | [`16_recursive_org_chart.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/16_recursive_org_chart.sql) |
| **17** | **Advanced Analytics** | Phân tích kinh doanh: Cohort Analysis, Funnel, RFM | [`17_advanced_analytics.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/17_advanced_analytics.sql) | [`17_advanced_analytics.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/17_advanced_analytics.sql) |
| **18** | **Pandas vs SQL** | Bảng đối chiếu cú pháp 1-1 giữa SQL và Python Pandas | [`18_pandas_vs_sql.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/queries/18_pandas_vs_sql.sql) | [`18_pandas_vs_sql.sql`](file:///c:/Users/asus/Downloads/J/sql-interview-prep/postgresql/18_pandas_vs_sql.sql) |

---

## 💻 Trải Nghiệm Giao Diện Web Viewer (`index.html`)

Dự án cung cấp một **Web Application** chạy hoàn toàn trên Client-side, cho phép bạn học và tra cứu câu hỏi một cách trực quan.

### 🚀 Khởi chạy Web Viewer ở Local

Do trình duyệt chặn các yêu cầu `fetch()` khi mở trực tiếp file `file://`, bạn cần khởi chạy qua local HTTP server:

#### Cách 1: Sử dụng PowerShell script có sẵn (Khuyên dùng)
Mở PowerShell tại thư mục repo và chạy:
```powershell
.\scripts\serve.ps1
```
*(Script sẽ tự động phát hiện Python, Node.js (`npx serve`) hoặc gợi ý Live Server để mở `http://localhost:8000`)*

#### Cách 2: Sử dụng Python
```bash
python -m http.server 8000
```
Sau đó truy cập: `http://localhost:8000`

#### Cách 3: Sử dụng VS Code Live Server
Chuột phải vào file `index.html` -> Chọn **Open with Live Server**.

---

## 🛠️ Hướng Dẫn Thực Hành Trực Tiếp Trên CSDL

### 🐬 Đối với MySQL (Version 8.0 trở lên)

1. **Kết nối vào MySQL Client:**
   ```bash
   mysql -u root -p
   ```
2. **Tạo Database và nạp Schemas:**
   ```sql
   CREATE DATABASE sql_interview_prep;
   USE sql_interview_prep;
   
   SOURCE schemas/00_original_schema.sql;
   SOURCE schemas/01_original_employees.sql;
   SOURCE schemas/02_product_analytics.sql;
   SOURCE schemas/03_social_network.sql;
   ```
3. **Thực thi file bài tập mong muốn:**
   ```bash
   mysql -u root -p sql_interview_prep < queries/08_window_functions.sql
   ```

### 🐘 Đối với PostgreSQL (Version 14 trở lên)

1. **Kết nối vào psql:**
   ```bash
   psql -U postgres
   ```
2. **Tạo Database và nạp Schemas:**
   ```sql
   CREATE DATABASE sql_interview_prep;
   \c sql_interview_prep;
   
   \i schemas/00_original_schema.sql
   \i schemas/01_original_employees.sql
   \i schemas/02_product_analytics.sql
   \i schemas/03_social_network.sql
   ```
3. **Thực thi file bài tập tương ứng trong thư mục `postgresql/`:**
   ```bash
   psql -U postgres -d sql_interview_prep -f postgresql/08_window_functions.sql
   ```

---

## ⚙️ CI/CD Verification Workflow

Mọi quy trình thay đổi code trong repo này đều được giám sát tự động bởi GitHub Actions (`.github/workflows/test.yml`). 

Mỗi khi push hoặc mở Pull Request, hệ thống CI sẽ khởi chạy một Container MySQL 8.0 thật, tự động nạp toàn bộ Schema và nạp lần lượt 19 file `.sql` trong thư mục `queries/` để đảm bảo không có bất kỳ lỗi cú pháp nào.

---

## 🤝 Đóng Góp & Phản Hồi (Contributing)

Mọi ý kiến đóng góp, bổ sung thêm các dạng bài phỏng vấn mới hoặc tối ưu hóa cách viết SQL đều được hoan nghênh!
- Đóng góp bài toán mới: Vui lòng mở **Pull Request** kèm theo lời giải và test case.
- Báo lỗi cú pháp/hành vi: Vui lòng mở **Issue** trên GitHub Repository.

*Chúc bạn ôn tập hiệu quả và đạt kết quả cao nhất trong các vòng phỏng vấn SQL!* 🚀
