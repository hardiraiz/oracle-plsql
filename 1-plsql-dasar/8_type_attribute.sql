-- %TYPE digunakan untuk mewarisi tipe data dari kolom tabel atau variabel lain
-- Kita bisa memastikan bahwa variabel yang dideklarasikan selalu memiliki tipe data yang sama dengan sumbernya.

-- Contoh : mewarisi tipe data dari kolom tabel
DECLARE
    v_emp_name employees.last_name%TYPE; -- Menggunakan tipe data dari kolom employees.last_name
BEGIN
    SELECT last_name INTO v_emp_name FROM employees WHERE employee_id = 100;
    DBMS_OUTPUT.PUT_LINE('Employee Name: ' || v_emp_name);
END;
/

-- Contoh : mewarisi tipe data dari variabel lain
DECLARE
    v_salary NUMBER(8,2) := 5000.00;
    v_bonus v_salary%TYPE;  -- v_bonus akan memiliki tipe NUMBER(8,2)
BEGIN
    v_bonus := v_salary * 0.1;
    DBMS_OUTPUT.PUT_LINE('Bonus: ' || v_bonus);
END;
/

-- Contoh : menggunakan %TYPE untuk parameter dalam prosedur
CREATE OR REPLACE PROCEDURE give_raise (
    p_emp_id employees.employee_id%TYPE,
    p_amount employees.salary%TYPE
) AS
BEGIN
    UPDATE employees
    SET salary = salary + p_amount
    WHERE employee_id = p_emp_id;
END;
/

-- Kesimpulan
-- a. %TYPE menghemat waktu dan menccegah kesalahan tipe data
-- b. Cocok digunakan untuk variabel yang mengambil data dari tabel atau mengikuti tipe variabel lain
-- c. Jika tipe data di table berubah kode PL/SQL tetap valid tanpa modifikasi manual

