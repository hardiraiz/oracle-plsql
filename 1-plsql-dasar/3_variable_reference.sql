-- ===== B. TIPE DATA REFERENCE =====
-- 1. REF, digunakan untuk menyimpan referensi ke object
-- Example Case : Sebuah perusahaan memiliki tabel DEPARTMENTS 
-- dan kita ingin menyimpan referensi ke manajer (dari tabel EMPLOYEES) dalam bentuk objek.

-- a. Membuat Tipe Objek untuk Menyimpan Data Karyawan
CREATE OR REPLACE TYPE EMP_OBJ AS OBJECT (
  EMP_ID NUMBER,
  EMP_NAME VARCHAR2(50)
)
/
-- b. Membuat Tabel yang Menyimpan Referensi ke Objek Karyawan
CREATE TABLE DEPT_TABLE (
  DEPT_ID NUMBER PRIMARY KEY,
  DEPT_NAME VARCHAR2(50),
  MANAGER REF EMP_OBJ  -- Penyimpanan referensi ke karyawan
)
/
-- c. Menyisipkan Data ke dalam Tabel DEPT_TABLE
DECLARE
  v_emp EMP_OBJ := EMP_OBJ(101, 'Neena Kochhar'); -- Simulasi objek karyawan
BEGIN
  INSERT INTO DEPT_TABLE VALUES (1, 'IT Department', REF(v_emp));
  COMMIT;
END;
/

-- 2. CURSOR, menyimpan referensi ke hasil query dalam PL/SQL

-- Kapan menggunakan Cursor?
-- ✅ Jika kita ingin mengambil data dari tabel secara satu per satu (row-by-row processing).
-- ✅ Berguna jika kita harus melakukan perhitungan atau manipulasi data sebelum mengembalikan hasilnya.
-- ✅ Lebih efisien daripada LOOP langsung di SQL jika ada perhitungan kompleks.

-- Example Case: Menampilkan Data Karyawan dengan Gaji di Atas 5000
DECLARE
  -- Mendeklarasikan Cursor
  CURSOR cur_high_salary IS
    SELECT EMPLOYEE_ID, FIRST_NAME, SALARY FROM EMPLOYEES WHERE SALARY > 5000;

  -- Variabel untuk Menyimpan Data
  v_emp_id EMPLOYEES.EMPLOYEE_ID%TYPE;
  v_name EMPLOYEES.FIRST_NAME%TYPE;
  v_salary EMPLOYEES.SALARY%TYPE;
BEGIN
  -- Membuka Cursor dan Memproses Data
  OPEN cur_high_salary;
  
  LOOP
    FETCH cur_high_salary INTO v_emp_id, v_name, v_salary;
    EXIT WHEN cur_high_salary%NOTFOUND;
    
    -- Menampilkan Hasil
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_emp_id || ' - Name: ' || v_name || ' - Salary: ' || v_salary);
  END LOOP;

  -- Menutup Cursor
  CLOSE cur_high_salary;
END;


-- 3. SYS REFCURSOR, tipe khusus untuk cursor dinamis 
-- atau Cursor Referensi yang Bisa Dikembalikan dari Fungsi atau Prosedur
-- Kapan Menggunakan SYS_REFCURSOR?
-- ✅ Jika kita perlu mengembalikan hasil query sebagai parameter dari prosedur atau fungsi.
-- ✅ Berguna dalam aplikasi berbasis web atau API, di mana query perlu dikembalikan ke client untuk diolah lebih lanjut.
-- ✅ Bisa digunakan untuk query yang dinamis.

-- Example Case : Mengembalikan Data Karyawan Berdasarkan Departemen
DECLARE
  v_cursor SYS_REFCURSOR;
  v_emp_id EMPLOYEES.EMPLOYEE_ID%TYPE;
  v_emp_name EMPLOYEES.FIRST_NAME%TYPE;
BEGIN
  -- Membuka SYS_REFCURSOR untuk mengambil data berdasarkan departemen
  OPEN v_cursor FOR SELECT EMPLOYEE_ID, FIRST_NAME FROM EMPLOYEES WHERE DEPARTMENT_ID = 60;

  -- Loop untuk membaca hasilnya
  LOOP
    FETCH v_cursor INTO v_emp_id, v_emp_name;
    EXIT WHEN v_cursor%NOTFOUND;
    
    -- Menampilkan hasil
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_emp_id || ' - Name: ' || v_emp_name);
  END LOOP;

  -- Menutup cursor
  CLOSE v_cursor;
END;