/*************** The Complete PL/SQL Bootcamp ***************
 * Author  : Oracle Master Training                         *
 * Course  : The Complete Oracle PL/SQL Bootcamp            *
 * Lecture : CASE Expressions                               *
 ************************************************************/
 
/****************** Simple Case Expression ******************/
DECLARE
  v_job_code        VARCHAR2(10) := 'SA_MAN';
  v_salary_increase NUMBER;
BEGIN
  v_salary_increase :=  CASE v_job_code 
                         WHEN 'SA_MAN' THEN 0.2
                         WHEN 'SA_REP' THEN 0.3
                        ELSE 0
                        END;
  dbms_output.put_line('Your salary increase is : '|| v_salary_increase);
END;
/************************************************************/
 
/****************** Searched Case Expression ****************/
DECLARE
  v_job_code        VARCHAR2(10) := 'IT_PROG';
  v_department      VARCHAR2(10) := 'IT';
  v_salary_increase NUMBER;
BEGIN
  v_salary_increase := CASE
                         WHEN v_job_code   = 'SA_MAN' THEN 0.2
                         WHEN v_department = 'IT' AND v_job_code = 'IT_PROG' THEN 0.3
                       ELSE 0
                     END;
  dbms_output.put_line('Your salary increase is : '|| v_salary_increase);
END;
/************************************************************/
 
/********************* CASE Statements **********************/
DECLARE
  v_job_code        VARCHAR2(10) := 'IT_PROG';
  v_department      VARCHAR2(10) := 'IT';
  v_salary_increase NUMBER;
BEGIN
  CASE
    WHEN v_job_code = 'SA_MAN' THEN
      v_salary_increase := 0.2;
      dbms_output.put_line('The salary increase for a Sales Manager is: '|| v_salary_increase);
    WHEN v_department = 'IT' AND v_job_code = 'IT_PROG' THEN
      v_salary_increase := 0.3;
      dbms_output.put_line('The salary increase for an IT Programmer is: '|| v_salary_increase);
    ELSE
      v_salary_increase := 0;
      dbms_output.put_line('The salary increase for this job code is: '|| v_salary_increase);
  END CASE;
END;
/************************************************************/