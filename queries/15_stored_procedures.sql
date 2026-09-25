-- ============================================================
-- 15_stored_procedures.sql
-- Chủ đề: Stored Procedure, Function, Trigger
-- Nguồn: MySQL 8.0 Reference Manual
-- ============================================================

USE sql_interview_prep;

-- Cần quyền CREATE ROUTINE. Nếu lỗi, chạy:
-- SET GLOBAL log_bin_trust_function_creators = 1;

DELIMITER $$

-- ============================================================
-- PHẦN 1: STORED PROCEDURE
-- ============================================================

-- ------------------------------------------------------------
-- SP1. Procedure đơn giản — đếm nhân viên theo phòng ban
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_count_employees_by_dept $$
CREATE PROCEDURE sp_count_employees_by_dept(IN p_dept VARCHAR(25))
BEGIN
    SELECT COUNT(*) AS employee_count
    FROM Employee
    WHERE department = p_dept;
END $$

-- Gọi:
-- CALL sp_count_employees_by_dept('Admin');

-- ------------------------------------------------------------
-- SP2. Procedure với OUT parameter
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_avg_salary $$
CREATE PROCEDURE sp_avg_salary(
    IN  p_dept     VARCHAR(25),
    OUT p_avg_sal  DECIMAL(15,2)
)
BEGIN
    SELECT AVG(salary) INTO p_avg_sal
    FROM Employee
    WHERE department = p_dept;
END $$

-- Gọi:
-- CALL sp_avg_salary('Admin', @avg);
-- SELECT @avg;

-- ------------------------------------------------------------
-- SP3. Procedure có logic IF/ELSE
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_employee_level $$
CREATE PROCEDURE sp_employee_level(IN p_emp_id INT)
BEGIN
    DECLARE v_salary INT;

    SELECT salary INTO v_salary
    FROM Employee
    WHERE employee_id = p_emp_id;

    IF v_salary IS NULL THEN
        SELECT 'Employee not found' AS result;
    ELSEIF v_salary >= 400000 THEN
        SELECT 'Senior' AS level;
    ELSEIF v_salary >= 200000 THEN
        SELECT 'Mid' AS level;
    ELSE
        SELECT 'Junior' AS level;
    END IF;
END $$

-- Gọi:
-- CALL sp_employee_level(1);

-- ------------------------------------------------------------
-- SP4. Procedure với LOOP và CURSOR
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_list_departments $$
CREATE PROCEDURE sp_list_departments()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_dept VARCHAR(25);
    DECLARE cur CURSOR FOR SELECT DISTINCT department FROM Employee;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DROP TEMPORARY TABLE IF EXISTS tmp_depts;
    CREATE TEMPORARY TABLE tmp_depts (dept VARCHAR(25));

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_dept;
        IF done THEN
            LEAVE read_loop;
        END IF;
        INSERT INTO tmp_depts VALUES (v_dept);
    END LOOP;
    CLOSE cur;

    SELECT * FROM tmp_depts;
END $$

-- Gọi:
-- CALL sp_list_departments();

-- ============================================================
-- PHẦN 2: STORED FUNCTION
-- ============================================================

-- ------------------------------------------------------------
-- FN1. Function tính thâm niên (năm)
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_tenure_years $$
CREATE FUNCTION fn_tenure_years(p_hire_date DATE)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, p_hire_date, CURDATE());
END $$

-- Dùng:
-- SELECT first_name, joining_date, fn_tenure_years(joining_date) AS tenure
-- FROM Employee;

-- ------------------------------------------------------------
-- FN2. Function phân loại mức lương
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_salary_band $$
CREATE FUNCTION fn_salary_band(p_salary INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_band VARCHAR(20);
    IF p_salary >= 400000 THEN SET v_band = 'High';
    ELSEIF p_salary >= 200000 THEN SET v_band = 'Medium';
    ELSE SET v_band = 'Low';
    END IF;
    RETURN v_band;
END $$

-- Dùng:
-- SELECT first_name, salary, fn_salary_band(salary) AS band FROM Employee;

-- ============================================================
-- PHẦN 3: TRIGGER
-- ============================================================

-- ------------------------------------------------------------
-- TR1. Tạo bảng audit log
-- ------------------------------------------------------------
DROP TABLE IF EXISTS employee_audit;
CREATE TABLE employee_audit (
    audit_id     INT AUTO_INCREMENT PRIMARY KEY,
    employee_id  INT,
    old_salary   INT,
    new_salary   INT,
    changed_at   DATETIME,
    changed_by   VARCHAR(50)
);

-- ------------------------------------------------------------
-- TR2. Trigger AFTER UPDATE — ghi log khi lương thay đổi
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_employee_salary_update $$
CREATE TRIGGER trg_employee_salary_update
AFTER UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF OLD.salary <> NEW.salary THEN
        INSERT INTO employee_audit
            (employee_id, old_salary, new_salary, changed_at, changed_by)
        VALUES
            (OLD.employee_id, OLD.salary, NEW.salary, NOW(), USER());
    END IF;
END $$

-- Test:
-- UPDATE Employee SET salary = 110000 WHERE employee_id = 1;
-- SELECT * FROM employee_audit;

-- ------------------------------------------------------------
-- TR3. Trigger BEFORE INSERT — validate dữ liệu
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_employee_before_insert $$
CREATE TRIGGER trg_employee_before_insert
BEFORE INSERT ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary cannot be negative';
    END IF;
END $$

-- Test:
-- INSERT INTO Employee (first_name, salary) VALUES ('Test', -100);
-- → Lỗi: Salary cannot be negative

DELIMITER ;

-- ============================================================
-- PHẦN 4: VIEW — đóng gói logic phức tạp
-- ============================================================

DROP VIEW IF EXISTS v_employee_summary;
CREATE VIEW v_employee_summary AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.department,
    e.salary,
    fn_salary_band(e.salary) AS salary_band,
    fn_tenure_years(e.joining_date) AS tenure_years,
    COUNT(b.employee_ref_id) AS num_bonuses
FROM Employee e
LEFT JOIN Bonus b ON e.employee_id = b.employee_ref_id
GROUP BY e.employee_id, e.first_name, e.last_name,
         e.department, e.salary, e.joining_date;

-- Dùng:
-- SELECT * FROM v_employee_summary WHERE salary_band = 'High';
