-- ============================================================
-- 16_recursive_org_chart.sql
-- Chủ đề: Recursive CTE — Org chart, Bill of Materials
-- Nguồn: LeetCode 1270 + MySQL 8.0 Recursive CTE
-- ============================================================

USE sql_interview_prep;

-- ============================================================
-- PHẦN 1: ORG CHART
-- ============================================================

-- ------------------------------------------------------------
-- OC1. Chuẩn bị dữ liệu: bảng nhân viên có manager_id
-- ------------------------------------------------------------
DROP TABLE IF EXISTS org_chart;
CREATE TABLE org_chart (
    emp_id     INT PRIMARY KEY,
    emp_name   VARCHAR(50),
    manager_id INT,
    title      VARCHAR(50),
    salary     INT
);

INSERT INTO org_chart VALUES
(1,  'CEO An',        NULL, 'CEO',              500000),
(2,  'VP Binh',       1,    'VP Engineering',   350000),
(3,  'VP Chi',        1,    'VP Sales',         320000),
(4,  'Dir Dung',      2,    'Director Backend', 280000),
(5,  'Dir Em',        2,    'Director Frontend',270000),
(6,  'Mgr Phuong',    4,    'Manager Backend',  200000),
(7,  'Mgr Giang',     5,    'Manager Frontend', 195000),
(8,  'Eng Hoang',     6,    'Senior Engineer',  150000),
(9,  'Eng Inh',       6,    'Engineer',         120000),
(10, 'Eng Khanh',     7,    'Senior Engineer',  155000),
(11, 'Sales Lam',     3,    'Sales Lead',       180000),
(12, 'Sales Minh',    11,   'Sales Rep',        110000);

-- ------------------------------------------------------------
-- OC2. Liệt kê toàn bộ cây từ CEO (top-down)
-- ------------------------------------------------------------
WITH RECURSIVE org AS (
    -- Anchor: bắt đầu từ CEO (manager_id IS NULL)
    SELECT
        emp_id, emp_name, manager_id, title, salary,
        1 AS level,
        CAST(emp_name AS CHAR(500)) AS path,
        emp_id AS root_id
    FROM org_chart
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive: nối con vào cha
    SELECT
        e.emp_id, e.emp_name, e.manager_id, e.title, e.salary,
        o.level + 1,
        CONCAT(o.path, ' > ', e.emp_name),
        o.root_id
    FROM org_chart e
    JOIN org o ON e.manager_id = o.emp_id
)
SELECT
    emp_id,
    CONCAT(LPAD(' ', (level - 1) * 2, ' '), emp_name) AS indented_name,
    title,
    salary,
    level,
    path
FROM org
ORDER BY path;

-- ------------------------------------------------------------
-- OC3. Tìm cấp bậc của từng nhân viên (bottom-up)
-- ------------------------------------------------------------
WITH RECURSIVE chain AS (
    SELECT
        emp_id,
        emp_name,
        manager_id,
        1 AS depth_from_self,
        CAST(emp_name AS CHAR(500)) AS chain_path
    FROM org_chart

    UNION ALL

    SELECT
        c.emp_id,
        c.emp_name,
        m.manager_id,
        c.depth_from_self + 1,
        CONCAT(c.chain_path, ' -> ', m.emp_name)
    FROM chain c
    JOIN org_chart m ON c.manager_id = m.emp_id
)
SELECT emp_id, emp_name, MAX(depth_from_self) AS level_from_top
FROM chain
GROUP BY emp_id, emp_name
ORDER BY level_from_top;

-- ------------------------------------------------------------
-- OC4. Tìm tất cả cấp dưới của một manager cụ thể
-- ------------------------------------------------------------
WITH RECURSIVE subordinates AS (
    SELECT emp_id, emp_name, manager_id, title, 1 AS depth
    FROM org_chart
    WHERE emp_id = 2   -- VP Binh

    UNION ALL

    SELECT e.emp_id, e.emp_name, e.manager_id, e.title, s.depth + 1
    FROM org_chart e
    JOIN subordinates s ON e.manager_id = s.emp_id
)
SELECT * FROM subordinates WHERE depth > 1 ORDER BY depth, emp_name;

-- ------------------------------------------------------------
-- OC5. Tính tổng lương của mỗi nhánh (subtree)
-- ------------------------------------------------------------
WITH RECURSIVE subtree AS (
    SELECT emp_id AS root_id, emp_id, salary
    FROM org_chart
    UNION ALL
    SELECT s.root_id, e.emp_id, e.salary
    FROM subtree s
    JOIN org_chart e ON e.manager_id = s.emp_id
)
SELECT
    oc.emp_name AS manager_name,
    SUM(st.salary) AS subtree_total_salary
FROM subtree st
JOIN org_chart oc ON st.root_id = oc.emp_id
GROUP BY oc.emp_id, oc.emp_name
ORDER BY subtree_total_salary DESC;

-- ============================================================
-- PHẦN 2: BILL OF MATERIALS (BOM)
-- ============================================================

-- ------------------------------------------------------------
-- BOM1. Bảng cấu trúc sản phẩm
-- ------------------------------------------------------------
DROP TABLE IF EXISTS bom;
CREATE TABLE bom (
    parent_id   VARCHAR(20),
    child_id    VARCHAR(20),
    quantity    INT
);

INSERT INTO bom VALUES
('Bike',  'Frame',   1),
('Bike',  'Wheel',   2),
('Bike',  'Handle',  1),
('Frame', 'Tube',    4),
('Frame', 'Weld',    10),
('Wheel', 'Tire',    1),
('Wheel', 'Spoke',   32),
('Handle','Grip',    2);

-- ------------------------------------------------------------
-- BOM2. Mở rộng BOM — tất cả component của Bike
-- ------------------------------------------------------------
WITH RECURSIVE explode AS (
    SELECT
        parent_id,
        child_id,
        quantity,
        1 AS level,
        CAST(quantity AS UNSIGNED) AS total_qty,
        CAST(CONCAT(parent_id, ' > ', child_id) AS CHAR(500)) AS path
    FROM bom
    WHERE parent_id = 'Bike'

    UNION ALL

    SELECT
        b.parent_id,
        b.child_id,
        b.quantity,
        e.level + 1,
        e.total_qty * b.quantity,
        CONCAT(e.path, ' > ', b.child_id)
    FROM bom b
    JOIN explode e ON b.parent_id = e.child_id
)
SELECT
    level,
    child_id AS component,
    total_qty AS quantity_needed,
    path
FROM explode
ORDER BY path;

-- ------------------------------------------------------------
-- BOM3. Tổng số nguyên liệu cần để sản xuất 100 chiếc Bike
-- ------------------------------------------------------------
WITH RECURSIVE explode AS (
    SELECT
        parent_id, child_id, quantity,
        CAST(quantity AS UNSIGNED) AS total_qty
    FROM bom
    WHERE parent_id = 'Bike'

    UNION ALL

    SELECT b.parent_id, b.child_id, b.quantity,
           e.total_qty * b.quantity
    FROM bom b
    JOIN explode e ON b.parent_id = e.child_id
)
SELECT
    child_id AS raw_material,
    SUM(total_qty) AS qty_per_bike,
    SUM(total_qty) * 100 AS qty_for_100_bikes
FROM explode
WHERE child_id NOT IN (SELECT DISTINCT parent_id FROM bom)
GROUP BY child_id
ORDER BY qty_for_100_bikes DESC;
