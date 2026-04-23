/******************** Creating a Sequence *******************/
CREATE SEQUENCE employee_id_seq
START WITH 207
INCREMENT BY 1;

/************************ Example 1 *************************/
BEGIN
    FOR i IN 1..10 LOOP
        INSERT INTO employees_copy
            (employee_id, first_name, last_name, email, hire_date, job_id, salary)
        VALUES
            (employee_id_seq.nextval, 'employee#' || employee_id_seq.nextval, 'temp_emp', 'abc@xmail.com', sysdate, 'IT_PROG', 1000);
    END LOOP;
END;

/************************ Example 2 *************************/
DECLARE
    v_seq_num   NUMBER;
BEGIN
    SELECT employee_id_seq.nextval
    INTO v_seq_num
    FROM dual;

    dbms_output.put_line(v_seq_num);
END;

/************************ Example 3 *************************/
DECLARE
    v_seq_num NUMBER;
BEGIN
    SELECT employee_id_seq.nextval
    INTO v_seq_num
    FROM employees_copy
    WHERE rownum = 1;

    dbms_output.put_line(v_seq_num);
END;

/************************ Example 4 *************************/
DECLARE
    v_seq_num NUMBER;
BEGIN
    v_seq_num := employee_id_seq.nextval;
    dbms_output.put_line(v_seq_num);
END;

/************************ Example 5 *************************/
BEGIN
    dbms_output.put_line(employee_id_seq.nextval);
END;

/************************ Example 5 *************************/
BEGIN
    dbms_output.put_line(employee_id_seq.currval);
END;