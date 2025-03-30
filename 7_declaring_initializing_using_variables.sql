-- Declaring & Initializing & Using Variables
-- General Usage:
-- NAME [COSNTANT] datatype [NOT NULL] [:= DEFAULT value|expression];

DECLARE
    v_first VARCHAR2(50) NOT NULL DEFAULT 'Hello'; 
    v_second VARCHAR2(50) NOT NULL := 'Welcome';   
    v_number NUMBER NOT NULL := 50.42867891;
BEGIN
    v_first := 'PL/SQL';
    DBMS_OUTPUT.PUT_LINE('First : ' || v_first);
    DBMS_OUTPUT.PUT_LINE('Second : ' || v_second);
    DBMS_OUTPUT.PUT_LINE('Number : ' || ROUND(v_number, 2));
    DBMS_OUTPUT.PUT_LINE('Contoh deklarasi dan inisiasi dan penggunaan variabel');
END;

-----------------------===================-----------------------
-----------------------DECLARING VARIABLES-----------------------
-----------------------===================-----------------------
SET SERVEROUTPUT ON;
DECLARE 
    v varchar2(20) := 2 + 25 * 3;
BEGIN
    dbms_output.put_line(v);
END;
-----------------------===================-----------------------
DECLARE 
    v_text varchar2(50) NOT NULL DEFAULT 'Hello';
    v_number1 number := 50;
    v_number2 number(2) := 50.42;
    v_number3 number(10,2) := 50.42;
    v_number4 PLS_INTEGER := 50; -- performa lebih baik akan tetapi hanya bilangan bulat
    v_number5 BINARY_float := 50.42;
    v_DATE1 DATE := '22-NOV-18 12:01:32';
    v_DATE2 timestamp := systimestamp;
    v_DATE3 timestamp(9) WITH TIME ZONE := systimestamp; -- menyimpan dengan timezone hingga 9 digit desimal untuk detik (nanodetik)
    v_DATE4 interval day(4) to second (3) := '124 02:05:21.012 ';
    v_DATE5 interval year to month := '12-3';
BEGIN
    V_TEXT := 'PL/SQL' || 'Course';
    DBMS_OUTPUT.PUT_LINE(V_TEXT);
    DBMS_OUTPUT.PUT_LINE(v_number1);
    DBMS_OUTPUT.PUT_LINE(v_number2);
    DBMS_OUTPUT.PUT_LINE(v_number3);
    DBMS_OUTPUT.PUT_LINE(v_number4);
    DBMS_OUTPUT.PUT_LINE(v_number5);
    DBMS_OUTPUT.PUT_LINE(v_DATE1);
    DBMS_OUTPUT.PUT_LINE(v_DATE2);
    DBMS_OUTPUT.PUT_LINE(v_DATE3);
    DBMS_OUTPUT.PUT_LINE(v_DATE4);
    DBMS_OUTPUT.PUT_LINE(v_DATE5);
    END;
----------------==================================---------------
----------------USING BOOLEAN DATA TYPE in PL/SQL----------------
----------------==================================---------------
DECLARE
    v_boolean boolean := true;
BEGIN
    dbms_output.put_line(sys.diutil.bool_to_int(v_boolean));
END;
----------------==================================---------------