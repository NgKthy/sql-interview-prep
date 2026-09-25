-- ============================================================
-- 15_stored_procedures.sql  (PostgreSQL port)
-- Chủ đề: Stored Procedure, PL/pgSQL Function, Trigger trong PostgreSQL
-- Nguồn: PostgreSQL Documentation — PL/pgSQL
-- Khác biệt vs MySQL:
--   - PostgreSQL dùng ngôn ngữ PL/pgSQL ($$ ... $$)
--   - PG hỗ trợ cả FUNCTION và PROCEDURE (từ PG 11+)
--   - Trigger trong PG phải gọi qua Trigger Function (RETURNS TRIGGER)
--   - Báo lỗi trong PG dùng RAISE EXCEPTION thay cho SIGNAL SQLSTATE
-- ============================================================

-- ============================================================
-- PHẦN 1: STORED PROCEDURE / FUNCTION
-- ============================================================

-- ------------------------------------------------------------
-- SP1. Function trả về table / count
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_count_employees_by_dept(p_dept VARCHAR(25))
RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM employee
    WHERE department = p_dept;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Gọi: SELECT fn_count_employees_by_dept('Admin');

-- ------------------------------------------------------------
-- SP2. Stored Procedure với INOUT / OUT parameter (PG 11+)
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_avg_salary(
    p_dept    IN  VARCHAR(25),
    p_avg_sal OUT NUMERIC(15,2)
)
AS $$
BEGIN
    SELECT AVG(salary) INTO p_avg_sal
    FROM employee
    WHERE department = p_dept;
END;
$$ LANGUAGE plpgsql;

-- Gọi trong PG: CALL sp_avg_salary('Admin', NULL);

-- ------------------------------------------------------------
-- SP3. Function với logic IF / ELSIF / ELSE
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_employee_level(p_emp_id INT)
RETURNS TEXT AS $$
DECLARE
    v_salary INT;
BEGIN
    SELECT salary INTO v_salary
    FROM employee
    WHERE employee_id = p_emp_id;

    IF v_salary IS NULL THEN
        RETURN 'Employee not found';
    ELSIF v_salary >= 400000 THEN
        RETURN 'Senior';
    ELSIF v_salary >= 200000 THEN
        RETURN 'Mid';
    ELSE
        RETURN 'Junior';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Gọi: SELECT fn_employee_level(1);

-- ============================================================
-- PHẦN 2: TRIGGER TRONG POSTGRESQL
-- ============================================================

-- ------------------------------------------------------------
-- TR1. Bảng audit log
-- ------------------------------------------------------------
DROP TABLE IF EXISTS employee_audit;
CREATE TABLE employee_audit (
    audit_id    SERIAL PRIMARY KEY,
    employee_id INT,
    old_salary  INT,
    new_salary  INT,
    changed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by  VARCHAR(50) DEFAULT CURRENT_USER
);

-- ------------------------------------------------------------
-- TR2. Trigger Function & Trigger AFTER UPDATE (Audit Log)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_log_salary_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.salary IS DISTINCT FROM NEW.salary THEN
        INSERT INTO employee_audit (employee_id, old_salary, new_salary)
        VALUES (OLD.employee_id, OLD.salary, NEW.salary);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_employee_salary_update ON employee;
CREATE TRIGGER trg_employee_salary_update
AFTER UPDATE ON employee
FOR EACH ROW
EXECUTE FUNCTION fn_log_salary_change();

-- ------------------------------------------------------------
-- TR3. Trigger BEFORE INSERT (Validation)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_validate_employee_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary < 0 THEN
        RAISE EXCEPTION 'Salary cannot be negative: %', NEW.salary;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_employee_before_insert ON employee;
CREATE TRIGGER trg_employee_before_insert
BEFORE INSERT ON employee
FOR EACH ROW
EXECUTE FUNCTION fn_validate_employee_salary();

-- ============================================================
-- PHẦN 3: VIEW & HELPER FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION fn_tenure_years(p_hire_date DATE)
RETURNS INT AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p_hire_date))::INT;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW v_employee_summary AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.department,
    e.salary,
    fn_employee_level(e.employee_id) AS salary_level,
    fn_tenure_years(e.joining_date) AS tenure_years,
    COUNT(b.employee_ref_id) AS num_bonuses
FROM employee e
LEFT JOIN bonus b ON e.employee_id = b.employee_ref_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department, e.salary, e.joining_date;
