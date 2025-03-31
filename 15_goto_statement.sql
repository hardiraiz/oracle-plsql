/*
GOTO adalah pernyataan dalam PL/SQL yang digunakan untuk melompati eksekusi kode ke bagian lain dalam blok dengan menggunakan label.
Namun, penggunaan GOTO tidak direkomendasikan karena dapat membuat kode sulit dipahami dan sulit dikelola (spaghetti code). 
Sebagai gantinya, disarankan menggunakan loop dan exception handling untuk mengontrol alur program.
*/

DECLARE
    v_searched_number   NUMBER  := 22;
    v_is_prime          BOOLEAN := true;
BEGIN
    FOR x IN 2..v_searched_number-1 LOOP
        IF v_searched_number MOD x = 0 THEN
            dbms_output.put_line(v_searched_number || ' is not a prime number..');
            v_is_prime := false;
            GOTO end_point;
        END IF;
    END LOOP;

    IF v_is_prime THEN
        dbms_output.put_line(v_searched_number || ' is a prime number..');
    END IF;

    <<end_point>>
        dbms_output.put_line('Check complete..');
END;


DECLARE
    v_searched_number   NUMBER  := 32457;
    v_is_prime          BOOLEAN := true;
    x                   NUMBER  := 2;
BEGIN
    <<start_point>>
        IF v_searched_number MOD x = 0 THEN
            dbms_output.put_line(v_searched_number || ' is not a prime number..');
            v_is_prime := false;
            GOTO end_point;
        END IF;

        x := x + 1;
        IF x = v_searched_number THEN
            GOTO prime_point;
        END IF;

        GOTO start_point;
        <<prime_point>>
            IF v_is_prime THEN
                dbms_output.put_line(v_searched_number || ' is a prime number..');
            END IF;

        <<end_point>>
            dbms_output.put_line('Check complete..');
END;