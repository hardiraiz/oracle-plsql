CREATE USER dev IDENTIFIED BY "GantiPasswordIni123";
GRANT CONNECT, RESOURCE, AQ_ADMINISTRATOR_ROLE TO dev;
GRANT EXECUTE ON DBMS_AQ TO dev;
GRANT EXECUTE ON DBMS_AQADM TO dev;
ALTER USER dev QUOTA UNLIMITED ON USERS;
/

-- MEMBUAT QUEUE DAN START QUEUE
BEGIN
    -- Queue keluar: Oracle Producer -> Kafka Connect Source -> Kafka
    -- (Tetap FALSE karena hanya Kafka Connect yang akan membacanya)
    DBMS_AQADM.CREATE_SHARDED_QUEUE(
        queue_name          => 'dev.out_q',
        multiple_consumers  => FALSE,
        queue_payload_type  => DBMS_AQADM.JMS_TYPE
    );
    DBMS_AQADM.START_QUEUE(queue_name => 'dev.out_q');

    -- Queue masuk: Kafka -> Kafka Connect Sink -> Oracle Listener
    -- (UBAH JADI TRUE agar mendukung model Subscriber/Callback)
    DBMS_AQADM.CREATE_SHARDED_QUEUE(
        queue_name          => 'dev.in_q',
        multiple_consumers  => TRUE, 
        queue_payload_type  => DBMS_AQADM.JMS_TYPE
    );
    DBMS_AQADM.START_QUEUE(queue_name => 'dev.in_q');
END;
/

-- STOP DAN HAPUS QUEUE
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

-- LIHAT LIST ANTRIAN YANG ADA
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

CREATE OR REPLACE PACKAGE dev.listener_pkg AS

    -- Prosedur dengan format standar Oracle AQ Notification
    PROCEDURE cb_process_event(
        context  RAW,
        reginfo  SYS.AQ$_REG_INFO,
        descr    SYS.AQ$_DESCRIPTOR,
        payload  RAW,
        payloadl NUMBER
    );

END listener_pkg;
/

CREATE OR REPLACE PACKAGE BODY dev.listener_pkg AS

    PROCEDURE cb_process_event(
        context  RAW,
        reginfo  SYS.AQ$_REG_INFO,
        descr    SYS.AQ$_DESCRIPTOR,
        payload  RAW,
        payloadl NUMBER
    ) IS
        dequeue_options    DBMS_AQ.DEQUEUE_OPTIONS_T;
        message_properties DBMS_AQ.MESSAGE_PROPERTIES_T;
        message_handle     RAW(16);
        msg                SYS.AQ$_JMS_TEXT_MESSAGE;
        v_text             VARCHAR2(32767);
        v_no_rekening      VARCHAR2(20);
    BEGIN
        -- 1. Beritahu Oracle pesan mana yang mau diambil berdasarkan trigger
        dequeue_options.msgid         := descr.msg_id;
        
        -- 2. Ambil nama Consumer (Subscriber) dari deskriptor otomatis
        dequeue_options.consumer_name := descr.consumer_name;

        -- 3. Eksekusi Dequeue
        DBMS_AQ.DEQUEUE(
            queue_name         => descr.queue_name,
            dequeue_options    => dequeue_options,
            message_properties => message_properties,
            payload            => msg,
            msgid              => message_handle
        );

        -- 4. Ekstrak pesan JMS menjadi teks biasa
        msg.get_text(v_text);

        -- 5. Parsing JSON dan eksekusi logika bisnis (Update Transaksi)
        v_no_rekening := JSON_VALUE(v_text, '$.noRekening');

        UPDATE transaksi
        SET status = 'NOTIFIED'
        WHERE no_rekening = v_no_rekening
          AND status = 'CREATED';

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            -- Penting: Jangan biarkan error menghentikan trigger.
            -- Anda bisa menambahkan fungsi simpan log error di sini.
    END cb_process_event;

END listener_pkg;
/

-- DAFTAR SUBSCRIBER DAN CALLBACK UNTUK LISTENER
BEGIN
    -- 1. Tambahkan Subscriber (Beri nama bebas, misalnya 'TX_UPDATE_SVC')
    DBMS_AQADM.ADD_SUBSCRIBER(
        queue_name => 'dev.in_q',
        subscriber => SYS.AQ$_AGENT('TX_UPDATE_SVC', NULL, 0)
    );

    -- 2. Daftarkan Prosedur PL/SQL sebagai aksi (Callback) saat pesan masuk
    DBMS_AQ.REGISTER(
        SYS.AQ$_REG_INFO_LIST(
            SYS.AQ$_REG_INFO(
                'dev.in_q:TX_UPDATE_SVC', -- Format "nama_queue:nama_subscriber"
                DBMS_AQ.NAMESPACE_AQ,
                'plsql://dev.listener_pkg.cb_process_event', -- Panggil Package
                HEXTORAW('FF')
            )
        ),
        1
    );
END;
/

EXEC producer_pkg.catat_transaksi('000005', 100005);
/

SELECT * FROM aq$out_q;
SELECT * FROM aq$in_q;
/

SELECT msg_id, enq_time, msg_state, consumer_name
FROM dev.AQ$OUT_Q;
/

SELECT no_rekening, status FROM transaksi;
/

-- BLOCK ANONYMOUS UNTUK LISTENER (DEQUEUE + PROCESS_EVENT)
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