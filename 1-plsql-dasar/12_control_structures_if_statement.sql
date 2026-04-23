/*************** The Complete PL/SQL Bootcamp ***************
 * Author  : Oracle Master Training                         *
 * Course  : The Complete Oracle PL/SQL Bootcamp            *
 * Lecture : IF Statements                                  *
 ************************************************************/
 
/************************ Example 1 *************************/
SET SERVEROUTPUT ON;
DECLARE
  v_number NUMBER := 30;
BEGIN
  IF v_number < 10 THEN
    dbms_output.put_line('I am smaller than 10');
  ELSIF v_number < 20 THEN
    dbms_output.put_line('I am smaller than 20');
  ELSIF v_number < 30 THEN
    dbms_output.put_line('I am smaller than 30');
  ELSE
    dbms_output.put_line('I am equal or greater than 30');
  END IF;
END;
 
/************************ Example 2 *************************/
DECLARE
  v_number NUMBER       := 5;
  v_name   VARCHAR2(30) := 'Adam';
BEGIN
  IF v_number < 10 OR v_name = 'Carol' THEN
    dbms_output.put_line('HI');
    dbms_output.put_line('I am smaller than 10');
  ELSIF v_number < 20 THEN
    dbms_output.put_line('I am smaller than 20');
  ELSIF v_number < 30 THEN
    dbms_output.put_line('I am smaller than 30');
  ELSE
    IF v_number IS NULL THEN
      dbms_output.put_line('The number is null..');
    ELSE
      dbms_output.put_line('I am equal or greater than 30');
    END IF;
  END IF;
END;
/************************************************************/