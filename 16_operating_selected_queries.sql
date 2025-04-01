-- Example 1
DECLARE
    v_name      VARCHAR2(50);
    v_salary    employees.salary%type;
BEGIN
    SELECT first_name || ' ' || last_name, salary
    INTO v_name, v_salary
    FROM employees
    WHERE employee_id = 130;

    dbms_output.put_line('The salary of ' || v_name || ' is : ' || v_salary);
END;

-- Example 2
DECLARE
    v_name      VARCHAR2(50);
    sysdates    employees.hire_date%type;
BEGIN
    SELECT first_name || ' ' || last_name, sysdate
    INTO v_name, sysdates
    FROM employees
    WHERE employee_id = 130;

    dbms_output.put_line('The salary of ' || v_name || ' is : ' || sysdates);
END;

-- Example 3
DECLARE
    v_name      VARCHAR2(50);
    v_sysdate   employees.hire_date%type;
BEGIN
    SELECT first_name || ' ' || last_name, sysdate
    INTO v_name, v_sysdate
    FROM employees
    WHERE employee_id = employee_id;

    dbms_output.put_line('The salary of ' || v_name || ' is : ' || v_sysdate);
END;

-- Example 4
DECLARE
    v_name          VARCHAR2(50);
    v_salary        employees.salary%type;
    v_employee_id   employees.employee_id%type := 130;
BEGIN
    SELECT first_name || ' ' || last_name, salary
    INTO v_name, v_salary
    FROM employees
    WHERE employee_id = v_employee_id;

    dbms_output.put_line('The salary of ' || v_name || ' is : ' || v_salary);
END;