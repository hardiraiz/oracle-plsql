-- Harus dimulai dengan huruf
-- Bisa memiliki spesial karakter seperti _ # $
-- Bisa memiliki karakter maksimal 30 karakter
-- Tidak dapat memiliki kata yang telah digunakan oracle sql

DECLARE
    -- VARIABLE
    v_variable_name     VARCHAR2(10);
    v_max_salary        NUMBER;
    
    -- CURSOR
    cur_cursor_name     NUMBER;
    cur_employees       VARCHAR2(2);

    -- EXCEPTION
    e_exception_name    VARCHAR2(2);
    e_procedure         VARCHAR2(2);

    -- PROCEDURE
    p_procedure_name    VARCHAR2(2);
    p_calculate_salary  VARCHAR2(2);

    -- BIND VARIABLE
    b_bind_name         VARCHAR2(2);
    b_emp_id            NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Contoh penamaan variabel pada PLSQL');
END;