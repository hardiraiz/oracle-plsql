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
-- b. Buat Object Table (Wajib untuk REF)
CREATE TABLE EMP_TABLE OF EMP_OBJ (
  CONSTRAINT emp_pk PRIMARY KEY (EMP_ID)
);
/
-- c. Membuat Tabel yang Menyimpan Referensi ke Objek Karyawan
CREATE TABLE DEPT_TABLE (
  DEPT_ID NUMBER PRIMARY KEY,
  DEPT_NAME VARCHAR2(50),
  MANAGER REF EMP_OBJ  -- Penyimpanan referensi ke karyawan
)
/
-- d. Insert data karyawan
INSERT INTO EMP_TABLE VALUES (EMP_OBJ(101, 'Hardi Raiz'));
/
-- e. Menyisipkan Data ke dalam Tabel DEPT_TABLE
DECLARE
  v_emp EMP_OBJ := EMP_OBJ(101, 'Neena Kochhar'); -- Simulasi objek karyawan
BEGIN
  INSERT INTO DEPT_TABLE (DEPT_ID, DEPT_NAME, MANAGER)
  SELECT 1, 'IT Department', REF(e)
  FROM EMP_TABLE e
  WHERE e.EMP_ID = 101;

  COMMIT;
END;
/
-- f. Mengambil data (DEREF)
SELECT 
  d.DEPT_ID,
  d.DEPT_NAME,
  DEREF(d.MANAGER).EMP_ID   AS MANAGER_ID,
  DEREF(d.MANAGER).EMP_NAME AS MANAGER_NAME
FROM DEPT_TABLE d;
/
/*
    REF itu fitur yang powerful tapi jarang benar-benar diperlukan di aplikasi modern (termasuk APEX). 
    Dia lebih cocok dipakai kalau kamu memang ingin memanfaatkan object-relational database secara penuh, bukan sekadar relational biasa.

    Kapan waktu yang tepat pakai REF?
      1. Navigasi object (pointer-based access)
        Kalau kamu ingin akses data seperti OOP:
          - dari satu object → langsung ke object lain
          - tanpa join manual
        Mirip pointer di bahasa seperti Java/C++
      2. Struktur data kompleks / graph
        Kalau relasi bukan sekadar foreign key, tapi:
          - hierarki kompleks
          - network / graph
          - object saling menunjuk
      3. Encapsulation + method di object type
        Kalau kamu pakai:
          - OBJECT TYPE + MEMBER FUNCTION
          - dan ingin relasi antar object tetap “natural”
    
    Studi Kasus Nyata:
      1. Sistem Organisasi (Hierarchy / Tree)
        Misalnya:
          - Karyawan punya manager
          - Manager juga karyawan (self-reference)
        Cocok untuk:
          - struktur organisasi kompleks
          - traversal hierarchy
      2. Sistem CAD / Engineering / BOM (Bill of Materials)
        Contoh:
          - Produk terdiri dari komponen
          - Komponen bisa terdiri dari sub-komponen
          - Relasi bisa sangat dalam dan kompleks
        REF dipakai untuk:
          - menunjuk parent/child
          - navigasi struktur tanpa join panjang
      3. Sistem Graph (Social Network / Recommendation)
        Misalnya:
          - User follow user lain
          - Banyak relasi silang 
        Cocok untuk:
          - graph traversal
          - relasi kompleks many-to-many
      4. Object dengan Behavior (Method)
          CREATE TYPE EMP_OBJ AS OBJECT (
            EMP_ID NUMBER,
            EMP_NAME VARCHAR2(50),
            MEMBER FUNCTION get_upper_name RETURN VARCHAR2
          );
          REF membantu menjaga relasi tetap object-oriented   
*/

/*
  2. CURSOR, menyimpan referensi ke hasil query dalam PL/SQL
    Kapan menggunakan Cursor?
      - Jika kita ingin mengambil data dari tabel secara satu per satu (row-by-row processing).
      - Berguna jika kita harus melakukan perhitungan atau manipulasi data sebelum mengembalikan hasilnya.
      - Lebih efisien daripada LOOP langsung di SQL jika ada perhitungan kompleks.
*/
-- Table sample
CREATE TABLE EMPLOYEES (
  EMPLOYEE_ID   NUMBER PRIMARY KEY,
  FIRST_NAME    VARCHAR2(50),
  SALARY        NUMBER,
  DEPARTMENT_ID NUMBER
);

-- Insert sample data
INSERT INTO EMPLOYEES VALUES (100, 'Steven', 10000, 1);
INSERT INTO EMPLOYEES VALUES (101, 'Neena', 8000, 1);
INSERT INTO EMPLOYEES VALUES (102, 'Lex', 4000, 2);
INSERT INTO EMPLOYEES VALUES (103, 'Alexander', 3000, 2);
INSERT INTO EMPLOYEES VALUES (104, 'Bruce', 6000, 3);
INSERT INTO EMPLOYEES VALUES (105, 'David', 2000, 4);

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

/*
  3. SYS REFCURSOR, tipe khusus untuk cursor dinamis 
    atau Cursor Referensi yang Bisa Dikembalikan dari Fungsi atau Prosedur
    Kapan Menggunakan SYS_REFCURSOR?
      - Jika kita perlu mengembalikan hasil query sebagai parameter dari prosedur atau fungsi.
      - Berguna dalam aplikasi berbasis web atau API, di mana query perlu dikembalikan ke client untuk diolah lebih lanjut.
      - Bisa digunakan untuk query yang dinamis.

    Karakteristik:
      - Bisa dikirim ke luar PL/SQL
      - Bisa dipakai di APEX (Report / REST)
      - Lebih fleksibel (dynamic query)
*/
-- Example Case 1 : Mengembalikan Data Karyawan Berdasarkan Departemen
DECLARE
  v_cursor SYS_REFCURSOR;
  v_emp_id EMPLOYEES.EMPLOYEE_ID%TYPE;
  v_emp_name EMPLOYEES.FIRST_NAME%TYPE;
BEGIN
  -- Membuka SYS_REFCURSOR untuk mengambil data berdasarkan departemen
  OPEN v_cursor FOR SELECT EMPLOYEE_ID, FIRST_NAME FROM EMPLOYEES WHERE DEPARTMENT_ID = 2;
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

-- Example Case 2 : Mengembalikan sebagai output data
-- a. Function return row data
CREATE OR REPLACE FUNCTION get_high_salary
  RETURN SYS_REFCURSOR
IS
  rc SYS_REFCURSOR;
BEGIN
  OPEN rc FOR
    SELECT EMPLOYEE_ID, FIRST_NAME, SALARY
    FROM EMPLOYEES
    WHERE SALARY > 5000;

  RETURN rc;
END;
/

-- b. Call Function
DECLARE
  rc SYS_REFCURSOR;
  v_id NUMBER;
  v_name VARCHAR2(50);
  v_salary NUMBER;
BEGIN
  rc := get_high_salary;
  LOOP
    FETCH rc INTO v_id, v_name, v_salary;
    EXIT WHEN rc%NOTFOUND;

    DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ', Name: ' || v_name || ', Salary: ' || v_salary);
  END LOOP;
  CLOSE rc;
END;
/