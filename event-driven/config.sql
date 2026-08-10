CREATE USER dev IDENTIFIED BY "GantiPasswordIni123";
GRANT CONNECT, RESOURCE, AQ_ADMINISTRATOR_ROLE TO dev;
GRANT EXECUTE ON DBMS_AQ TO dev;
GRANT EXECUTE ON DBMS_AQADM TO dev;
ALTER USER dev QUOTA UNLIMITED ON USERS;
/

BEGIN
    -- Queue keluar: Oracle Producer -> Kafka Connect Source -> Kafka
    DBMS_AQADM.CREATE_SHARDED_QUEUE(
        queue_name          => 'dev.out_q',
        multiple_consumers  => FALSE,
        queue_payload_type  => DBMS_AQADM.JMS_TYPE
    );
    DBMS_AQADM.START_QUEUE(queue_name => 'dev.out_q');

    -- Queue masuk: Kafka -> Kafka Connect Sink -> Oracle Listener
    DBMS_AQADM.CREATE_SHARDED_QUEUE(
        queue_name          => 'dev.in_q',
        multiple_consumers  => FALSE,
        queue_payload_type  => DBMS_AQADM.JMS_TYPE
    );
    DBMS_AQADM.START_QUEUE(queue_name => 'dev.in_q');
END;
/

BEGIN
    -- 1. Hentikan dan Hapus Queue Keluar (dev.out_q)
    DBMS_AQADM.STOP_QUEUE(
        queue_name => 'dev.out_q'
    );
    DBMS_AQADM.DROP_QUEUE(
        queue_name => 'dev.out_q'
    );

    -- 2. Hentikan dan Hapus Queue Masuk (dev.in_q)
    DBMS_AQADM.STOP_QUEUE(
        queue_name => 'dev.in_q'
    );
    DBMS_AQADM.DROP_QUEUE(
        queue_name => 'dev.in_q'
    );
END;
/

SELECT name, queue_type, enqueue_enabled, dequeue_enabled FROM user_queues;
/

CREATE TABLE transaksi (
    no_rekening   VARCHAR2(20),
    nominal       NUMBER,
    status        VARCHAR2(20) DEFAULT 'CREATED',
    created_at    TIMESTAMP DEFAULT SYSTIMESTAMP
);
/

DELETE transaksi;
COMMIT;
/

CREATE OR REPLACE PACKAGE dev.producer_pkg AS
    PROCEDURE catat_transaksi(p_no_rekening IN VARCHAR2, p_nominal IN NUMBER);
END producer_pkg;
/

CREATE OR REPLACE PACKAGE BODY dev.producer_pkg AS

    PROCEDURE catat_transaksi(p_no_rekening IN VARCHAR2, p_nominal IN NUMBER) IS
        enqueue_options    DBMS_AQ.ENQUEUE_OPTIONS_T;
        message_properties DBMS_AQ.MESSAGE_PROPERTIES_T;
        message_handle     RAW(16);
        msg                SYS.AQ$_JMS_TEXT_MESSAGE;
        v_payload          VARCHAR2(4000);
    BEGIN
        -- 1. Logika bisnis utama
        INSERT INTO transaksi (no_rekening, nominal)
        VALUES (p_no_rekening, p_nominal);

        -- 2. Susun payload JSON sederhana
        v_payload := '{"eventType":"TRANSACTION_CREATED","noRekening":"' || p_no_rekening ||
                      '","nominal":' || p_nominal || '}';

        -- 3. ENQUEUE -- ini yang membuat Oracle jadi Producer
        msg := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
        msg.set_text(v_payload);

        DBMS_AQ.ENQUEUE(
            queue_name         => 'dev.out_q',
            enqueue_options    => enqueue_options,
            message_properties => message_properties,
            payload            => msg,
            msgid              => message_handle
        );

        COMMIT;  -- INSERT transaksi dan ENQUEUE event commit bersama, atomic
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END catat_transaksi;

END producer_pkg;
/

EXEC dev.producer_pkg.catat_transaksi('1234567890', 500000);
/

SELECT * FROM AQ$OUT_Q; -- Memastikan pesan masuk antrian
/

CREATE OR REPLACE PACKAGE dev.listener_pkg AS

    PROCEDURE process_event(
        p_payload IN VARCHAR2
    );

    PROCEDURE listen_loop;

END listener_pkg;
/

CREATE OR REPLACE PACKAGE BODY dev.listener_pkg AS

    PROCEDURE process_event(
        p_payload IN VARCHAR2
    ) IS
        v_no_rekening transaksi.no_rekening%TYPE;
    BEGIN

        v_no_rekening := JSON_VALUE(
            p_payload,
            '$.noRekening'
            RETURNING VARCHAR2(20)
        );

        IF v_no_rekening IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'noRekening tidak ditemukan dalam payload'
            );
        END IF;

        UPDATE transaksi
        SET status = 'NOTIFIED'
        WHERE no_rekening = v_no_rekening
          AND status = 'CREATED';

    END process_event;


    PROCEDURE listen_loop IS

        dequeue_options    DBMS_AQ.DEQUEUE_OPTIONS_T;
        message_properties DBMS_AQ.MESSAGE_PROPERTIES_T;
        message_handle     RAW(16);

        msg                SYS.AQ$_JMS_TEXT_MESSAGE;
        v_text             VARCHAR2(32767);

    BEGIN

        dequeue_options.wait := DBMS_AQ.FOREVER;

        LOOP

            BEGIN

                DBMS_AQ.DEQUEUE(
                    queue_name         => 'DEV.IN_Q',
                    dequeue_options    => dequeue_options,
                    message_properties => message_properties,
                    payload            => msg,
                    msgid              => message_handle
                );

                msg.get_text(v_text);

                process_event(v_text);

                COMMIT;

            EXCEPTION

                WHEN OTHERS THEN

                    ROLLBACK;

                    -- TODO:
                    -- INSERT error ke tabel logging

                    DBMS_OUTPUT.PUT_LINE(
                        'Error: ' || SQLERRM
                    );

            END;

        END LOOP;

    END listen_loop;

END listener_pkg;
/

GRANT CREATE JOB TO dev;
GRANT EXECUTE ON DBMS_SCHEDULER TO dev;

BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'dev.listener_job',
        job_type   => 'STORED_PROCEDURE',
        job_action => 'dev.listener_pkg.listen_loop',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE
    );
    DBMS_SCHEDULER.set_attribute('dev.listener_job', 'restart_on_failure', TRUE);
    DBMS_SCHEDULER.enable('dev.listener_job');
END;
/
BEGIN
    DBMS_SCHEDULER.drop_job(
        job_name => 'dev.listener_job',
        force    => TRUE
    );
END;
/

SELECT job_name, state FROM user_scheduler_jobs;
/

EXEC producer_pkg.catat_transaksi('000003', 100003);
/

SELECT no_rekening, status FROM transaksi;
/

SELECT * FROM aq$out_q;
SELECT * FROM aq$in_q;
/

SELECT job_name, state, failure_count, last_start_date
FROM user_scheduler_jobs 
WHERE job_name = 'LISTENER_JOB';
/

DECLARE
    dequeue_options    DBMS_AQ.DEQUEUE_OPTIONS_T;
    message_properties DBMS_AQ.MESSAGE_PROPERTIES_T;
    message_handle     RAW(16);

    msg                SYS.AQ$_JMS_TEXT_MESSAGE;
    v_text             VARCHAR2(32767);
    v_error_msg        VARCHAR2(4000);

    -- Mendefinisikan exception khusus jika antrean kosong (timeout)
    e_no_messages      EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_no_messages, -25228);

BEGIN
    -- 1. Konfigurasi Dequeue Options
    -- Sangat disarankan untuk tidak menunggu selamanya (DBMS_AQ.FOREVER).
    -- Gunakan NO_WAIT atau set angka (dalam detik, misal 5) agar script tidak hang saat antrean kosong.
    dequeue_options.wait       := DBMS_AQ.NO_WAIT; 
    dequeue_options.navigation := DBMS_AQ.FIRST_MESSAGE;

    -- 2. Proses Dequeue
    DBMS_AQ.DEQUEUE(
        queue_name         => 'DEV.IN_Q',
        dequeue_options    => dequeue_options,
        message_properties => message_properties,
        payload            => msg,
        msgid              => message_handle
    );

    -- 3. Ekstrak dan Proses Payload
    IF msg IS NOT NULL THEN
        msg.get_text(v_text);
        DBMS_OUTPUT.PUT_LINE('Processed payload: ' || v_text);

        -- Memanggil logic bisnis
        listener_pkg.process_event(v_text);

        -- 4. Konfirmasi transaksi jika sukses
        COMMIT;
    END IF;

EXCEPTION
    WHEN e_no_messages THEN
        -- Ini normal terjadi jika antrean sedang kosong.
        DBMS_OUTPUT.PUT_LINE('Antrean kosong, tidak ada pesan baru.');
        
    WHEN OTHERS THEN
        -- Simpan pesan error sebelum rollback (karena SQLERRM bisa berubah)
        v_error_msg := SQLERRM;
        
        -- Batalkan transaksi utama (dequeue dan process_event)
        ROLLBACK;
        
        -- 5. Implementasi Logging
        -- Gunakan Autonomous Transaction pada prosedur logging (jika ada),
        -- ATAU insert langsung dan commit khusus untuk log ini.
        /* 
        INSERT INTO error_log_table (error_date, queue_name, payload, error_message)
        VALUES (SYSDATE, 'DEV.IN_Q', v_text, v_error_msg);
        COMMIT; 
        */

        DBMS_OUTPUT.PUT_LINE('Error: ' || v_error_msg);
END;
/