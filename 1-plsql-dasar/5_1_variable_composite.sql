-- ===== D. TIPE DATA COMPOSITE =====
-- Tipe data composite dapat menyimpan lebih dari satu nilai dalam satu variabel dan memiliki struktur kompleks

/*
  1. Record, seperti struktur dalam bahasa pemrograman lain
  Example Case : Menyimpan data karyawan dalam satu variabel menggunakan RECORD
*/
DECLARE
  -- Mendefinisikan RECORD untuk menyimpan data karyawan
  TYPE emp_record IS RECORD (
    emp_id NUMBER,
    emp_name VARCHAR2(100),
    emp_salary NUMBER
  );

  -- Variabel dengan tipe RECORD
  v_employee emp_record;
BEGIN
  -- Mengisi data ke dalam RECORD
  v_employee.emp_id := 101;
  v_employee.emp_name := 'John Doe';
  v_employee.emp_salary := 5000;

  -- Menampilkan hasil
  DBMS_OUTPUT.PUT_LINE('ID: ' || v_employee.emp_id);
  DBMS_OUTPUT.PUT_LINE('Nama: ' || v_employee.emp_name);
  DBMS_OUTPUT.PUT_LINE('Gaji: ' || v_employee.emp_salary);
END;
/
-- Kapan Menggunakan?
-- ✅ Jika ingin menyimpan data dari beberapa kolom dalam satu variabel.
-- ✅ Jika ingin membaca data satu baris dari tabel ke dalam variabel.

-- Example Case : Membaca data karyawan dari tabel menggunakan %ROWTYPE
-- Membuat tabel (Gunakan ini jika belum ada di database)
CREATE TABLE EMPLOYEES (
  EMPLOYEE_ID   NUMBER PRIMARY KEY,
  FIRST_NAME    VARCHAR2(50),
  SALARY        NUMBER,
  DEPARTMENT_ID NUMBER
);

-- Menambahkan contoh data
INSERT INTO employees VALUES (101, 'Alice', 7000, 10);
COMMIT;

-- Menggunakan RECORD untuk menyimpan satu baris dari tabel
DECLARE
  v_employee employees%ROWTYPE;  -- RECORD berdasarkan struktur tabel
BEGIN
  -- Mengambil data dari tabel ke dalam RECORD (Hanya Bisa untuk 1 row)
  SELECT * INTO v_employee FROM employees WHERE EMPLOYEE_ID = 101;

  -- Menampilkan hasil
  DBMS_OUTPUT.PUT_LINE('ID: ' || v_employee.employee_id);
  DBMS_OUTPUT.PUT_LINE('Nama: ' || v_employee.first_name);
  DBMS_OUTPUT.PUT_LINE('Gaji: ' || v_employee.salary);
END;
/

-- Cara lain menggunakan RECORD untuk menyimpan data karyawan dari tabel
DECLARE
  TYPE t_emp IS RECORD (
    emp_id NUMBER,
    emp_name employees.first_name%TYPE,
    emp_salary employees.salary%TYPE
  );

  r_emp t_emp;
BEGIN
  SELECT employee_id, first_name, salary
  INTO r_emp
  FROM employees
  WHERE employee_id = 101;

  DBMS_OUTPUT.PUT_LINE('ID: ' || r_emp.emp_id);
  DBMS_OUTPUT.PUT_LINE('Nama: ' || r_emp.emp_name);
  DBMS_OUTPUT.PUT_LINE('Gaji: ' || r_emp.emp_salary);
END;
/

-- Menggunakan RECORD untuk INSERT data ke dalam tabel
CREATE TABLE retired_employees AS SELECT * FROM employees WHERE 1=1; -- Membuat tabel kosong dengan struktur sama
/
DECLARE
  r_emp employees%ROWTYPE;
BEGIN
  SELECT * INTO r_emp FROM employees WHERE employee_id = 101;

  r_emp.salary        := 0;
  r_emp.department_id := 0;

  INSERT INTO retired_employees VALUES r_emp;
  COMMIT;
END;
/
SELECT * FROM retired_employees;
/

-- Mengunakan RECORD untuk UPDATE data di tabel
DECLARE
  r_emp employees%ROWTYPE;
BEGIN
  SELECT * INTO r_emp FROM employees WHERE employee_id = 101;

  r_emp.salary        := r_emp.salary + 1000;
  r_emp.department_id := 20;

  UPDATE retired_employees SET row = r_emp WHERE employee_id = 101;
  COMMIT;
END;
/
SELECT * FROM retired_employees WHERE employee_id = 101;
/
DELETE FROM retired_employees;
COMMIT;
/
-- Kapan Menggunakan?
-- ✅ Jika ingin menyimpan satu baris data dari tabel tanpa mendefinisikan struktur RECORD secara manual.


/* 
  2. Collection, digunakan untuk menyimpan kumpulan data
  Example Case : Menyimpan beberapa nama karyawan dalam Nested Table dan menampilkan isinya.
*/
DECLARE
  -- Mendefinisikan Nested Table untuk menyimpan daftar nama
  TYPE emp_table IS TABLE OF VARCHAR2(100);
  v_emps emp_table := emp_table();  -- Inisialisasi collection
BEGIN
  -- Menambahkan data ke dalam Nested Table
  v_emps.EXTEND(3);  -- Menambah kapasitas 3 elemen
  v_emps(1) := 'John';
  v_emps(2) := 'Alice';
  v_emps(3) := 'Bob';

  -- Menampilkan isi Nested Table
  FOR i IN 1..v_emps.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Karyawan: ' || v_emps(i));
  END LOOP;
END;
/
-- Kapan Menggunakan?
-- ✅ Jika ingin menyimpan kumpulan data dalam satu variabel dengan jumlah elemen yang bisa bertambah dinamis.

-- Example Case : Menyimpan 3 kode produk dalam VARRAY.
DECLARE
  -- Mendefinisikan VARRAY dengan kapasitas maksimum 5
  TYPE product_array IS VARRAY(5) OF VARCHAR2(50);
  v_products product_array := product_array();  -- Inisialisasi collection
BEGIN
  -- Menambahkan elemen ke dalam VARRAY
  v_products.EXTEND(3);
  v_products(1) := 'Laptop';
  v_products(2) := 'Mouse';
  v_products(3) := 'Keyboard';

  -- Menampilkan isi VARRAY
  FOR i IN 1..v_products.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Produk: ' || v_products(i));
  END LOOP;
END;
/
-- Kapan Menggunakan?
-- ✅ Jika ingin menyimpan jumlah data terbatas dengan indeks yang tetap.

-- Example Case : Menyimpan daftar gaji karyawan berdasarkan ID menggunakan Associative Array.
DECLARE
  -- Mendefinisikan Associative Array
  TYPE salary_table IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_salaries salary_table;  -- Deklarasi variabel array
BEGIN
  -- Menambahkan data dengan indeks sebagai ID karyawan
  v_salaries(101) := 5000;
  v_salaries(102) := 7000;
  v_salaries(103) := 6000;

  -- Menampilkan data berdasarkan ID karyawan
  DBMS_OUTPUT.PUT_LINE('Gaji ID 101: ' || v_salaries(101));
  DBMS_OUTPUT.PUT_LINE('Gaji ID 102: ' || v_salaries(102));
  DBMS_OUTPUT.PUT_LINE('Gaji ID 103: ' || v_salaries(103));
END;
/
-- Kapan Menggunakan?
-- ✅ Jika ingin menyimpan dan mengambil data secara cepat dengan indeks tertentu.
-- ✅ Lebih fleksibel dibanding VARRAY karena tidak ada batasan jumlah elemen.
