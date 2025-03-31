-- Basic Loops
DECLARE
    v_counter NUMBER(2) := 1;
BEGIN
    LOOP
        dbms_output.put_line('My counter is : ' || v_counter);
        v_counter := v_counter + 1;
        -- IF v_counter = 10 THEN
        --     dbms_output.put_line('Now I reached : ' || v_counter);
        --     EXIT;
        -- END IF;
        EXIT WHEN v_counter > 10;
    END LOOP;
END;

-- While Loops
DECLARE
    v_counter NUMBER(2) := 1;
BEGIN
    WHILE v_counter <= 10 LOOP
        dbms_output.put_line('My counter : ' || v_counter);
        v_counter :=  v_counter + 1;
        -- EXIT WHEN v_counter > 3
    END LOOP;
END;

-- For Loops
BEGIN
    FOR i IN REVERSE 1..3 LOOP
        dbms_output.put_line('My Counter Is : ' || i);
    END LOOP;
END;

-- Nested Loops
DECLARE
    v_inner NUMBER := 1;
BEGIN
    FOR v_outer IN 1..5 LOOP
        dbms_output.put_line('My outer value is : ' || v_outer);
        v_inner := 1;
        LOOP
            v_inner := v_inner + 1;
            dbms_output.put_line('  My inner value is : ' || v_inner);
            EXIT WHEN v_inner * v_outer >= 15;
        END LOOP;
    END LOOP;
END;

-- Nested Loops with Labels
DECLARE
    v_inner NUMBER := 1;
BEGIN
    <<outer_loop>>
    FOR v_outer IN 1..5 LOOP
        dbms_output.put_line('My outer value is : ' || v_outer );
        v_inner := 1;
        <<inner_loop>>
        LOOP
            v_inner := v_inner + 1;
            dbms_output.put_line('  My inner value is : ' || v_inner);
            EXIT outer_loop WHEN v_inner * v_outer >= 16;
            EXIT WHEN v_inner * v_outer >= 15;
        END LOOP inner_loop;
    END LOOP outer_loop;
END;

-- Continue Statement
DECLARE
    v_inner NUMBER :=  1;
BEGIN
    FOR v_outer IN 1..10 LOOP
        dbms_output.put_line('My outer value is : ' || v_outer);
        v_inner := 1;
        WHILE v_inner * v_outer < 15 LOOP
            v_inner := v_inner + 1;
            CONTINUE WHEN MOD(v_inner * v_outer, 3) = 0;
            dbms_output.put_line('  My inner value is : ' || v_inner);
        END LOOP;
    END LOOP;
END;