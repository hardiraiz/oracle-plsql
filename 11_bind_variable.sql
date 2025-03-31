/*

Bind variable adalah variable yang dideklarasikan di lingkungan his seperti SQL Plus, SQLcl atau aplikasi lain
dapat digunakan dalam blok PL/SQL

Bind variable memungkinkan pertukaran data  antara PL/SQL dan lingkungan host, 
sehingga berguna untuk efisiensi, keamanan, dan kinerja dalam eksekusi query

Bind variabel memiliki karakteristik:
- Diinterpretasi saat runtime
- Aman dari SQL Injection
- Menggunakan caching lebih cepat dalam eksekusi berulang

*/

--------------------------BIND VARIABLES--------------------------
set serveroutput on
set autoprint on
/
variable var_text varchar2(30);
/
variable var_number NUMBER;
/
variable var_date DATE;
/
declare
    v_text varchar2(30);
begin
    :var_text := 'Hello SQL';
    :var_number := 20;
    v_text := :var_text;
    --dbms_output.put_line(v_text);
    --dbms_output.put_line(:var_text);
end;
/
print var_text
/
variable var_sql number;
/
begin 
  :var_sql := 100;
end;
/
select * from employees where employee_id = :var_sql;

/*------------------------BIND VARIABLES--------------------------
NOTE: When you run a bind variable creation and SELECT statement 
together, SQL Developer may return an error but when you execute 
them separately, there will be no problem.
----------------------------------------------------------------*/
