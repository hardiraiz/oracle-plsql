Membangun arsitektur *Event-Driven* murni di dalam Oracle Database menggunakan **TxEventQ** adalah langkah yang sangat cerdas. Anda menggabungkan keandalan transaksi database (ACID) dengan kecepatan pemrosesan asinkron tanpa perlu infrastruktur tambahan seperti Kafka atau RabbitMQ.

Mari kita bedah secara mendalam, terurut, dan detail agar Anda bisa langsung mengimplementasikan *best practice*-nya.

---

## 0. APEX Background Process vs TXEventQ vs Workflow

1. **APEX Background Process** (DBMS_SCHEDULER)

    - Karakteristik: Eksekusi asinkron sederhana di dalam lingkup APEX/Database.
    - Kapan digunakan: Tugas berat yang mengunci UI (misal: generate report jutaan baris), logika murni PL/SQL, butuh native UI feedback (progress bar).
    - Kelemahan: Sulit diintegrasikan dengan sistem eksternal, bukan untuk event-driven architecture, tidak memiliki state management kompleks.

2. **Oracle TxEventQ** (Event-Driven)

    - Karakteristik: Antrean pesan persisten, mendukung Pub/Sub, integrasi eksternal (Kafka, JMS).
    - Kapan digunakan: Microservices, integrasi dengan aplikasi non-Oracle (Node.js, Java), high throughput, fire-and-forget dengan reliability tinggi, satu aksi memicu banyak proses berbeda di berbagai sistem.
    - Kelemahan: Membutuhkan infrastruktur tambahan (Kafka Connect) untuk integrasi eksternal, kurva belajar lebih tinggi, tidak menyediakan UI state management bawaan APEX.

3. **APEX Workflow** (State Machine/Business Process)

    - Karakteristik: Mengelola siklus hidup proses bisnis yang panjang, melibatkan interaksi manusia, persetujuan multi-level.
    - Kapan digunakan: Proses bisnis dengan tahapan yang jelas (misal: pengajuan cuti, onboarding karyawan), membutuhkan approval manual, penundaan berbasis waktu yang lama (menunggu respon user), pemantauan status proses (state machine).
    - Kelemahan: Bukan untuk tugas komputasi background kecepatan tinggi atau fire-and-forget ke sistem eksternal tanpa state management.

---

## 1. Konsep Dasar yang Wajib Dipahami

Sebelum menulis kode, Anda harus memahami istilah-istilah ini dalam konteks TxEventQ:

* **Producer:** Pihak (Prosedur/Aplikasi) yang melempar/membuat event (pesan).
* **Consumer / Listener:** Pihak yang mengambil dan memproses event tersebut.
* **Topic vs Queue:**
* **Queue (Point-to-Point):** 1 pesan hanya dibaca oleh 1 Consumer. Selesai.
* **Topic (Publish/Subscribe):** 1 pesan bisa dibaca oleh *banyak* Consumer secara independen.


* **Subscriber**
Subscriber adalah "Pendaftar". Jika Anda menggunakan model *Topic*, sebuah pesan tidak akan dikirim ke mana-mana jika tidak ada yang mendaftar. Anda mendaftarkan "Subscriber A" (misal: Layanan Notifikasi) dan "Subscriber B" (Layanan Poin). Ketika Producer mengirim 1 event, Oracle akan otomatis membuatkan salinan (secara logis) agar Subscriber A dan B bisa mengambil pesan tersebut di waktu mereka masing-masing tanpa saling mengganggu.

---

## 2. Paradigma Listener: Harus Jalan Terus Menerus?

Ini adalah inti dari pertanyaan Anda. Ada dua cara untuk membuat Listener di Oracle:

**Metode 1: Polling (Loop Terus Menerus) - Kurang Ideal**
Seperti yang Anda lihat pada panduan sebelumnya (menggunakan `DBMS_SCHEDULER` dan `LOOP`), prosedurnya jalan terus dan menggunakan instruksi `DBMS_AQ.FOREVER`.

* **Kelebihan:** Sangat cepat (mikrodetik).
* **Kekurangan:** Menahan 1 *session* database secara permanen. Jika Anda punya 100 antrean, Anda butuh 100 sesi yang menyala terus menerus.

**Metode 2: PL/SQL Notifications (Event-Driven Asli) - BEST PRACTICE**
Oracle memiliki fitur di mana Listener **tidur total**. Oracle Database sendiri yang akan "membangunkan" (men-trigger) prosedur PL/SQL *hanya pada saat* ada pesan baru masuk ke antrean.

* **Kelebihan:** Tidak memakan resource saat tidak ada pesan. Sangat hemat dan elegan. Skalabel.
* **Kekurangan:** Ada jeda waktu (sekian milidetik) bagi Oracle untuk melakukan *spawn job* saat pesan tiba.

Pada studi kasus di bawah, kita akan menggunakan **Metode 2 (PL/SQL Notification)** karena ini adalah *best practice* untuk aplikasi *enterprise*.

---

## 3. Tips & Trick (Best Practices) TxEventQ

1. **Idempotency (Tahan Ganda):** Desain kode Listener Anda agar aman jika secara tidak sengaja memproses pesan yang sama dua kali. Gunakan status (misal: `if status = 'PROCESSED' then exit;`).
2. **Exception Queue (Dead Letter Queue):** Jika Listener Anda error saat memproses pesan (misal, datanya korup), pesan itu tidak boleh menyumbat antrean. Secara *default*, Oracle akan mencoba beberapa kali (retry), lalu memindahkan pesan yang gagal ke *Exception Queue* agar antrean utama tetap jalan.
3. **Satu Transaksi (Atomic):** Saat Producer membuat event, pastikan `INSERT` ke tabel utama dan `DBMS_AQ.ENQUEUE` diakhiri dengan satu perintah `COMMIT`. Ini mencegah *data loss*.

---

## 4. Studi Kasus: Sistem Registrasi User (Event-Driven)

**Skenario:**
Saat ada User baru mendaftar (`INSERT` ke tabel `USERS`), sistem tidak boleh langsung mengirim email atau menambah poin anggota saat itu juga, karena akan membuat proses registrasi menjadi lambat (menunggu API email).
Sebagai gantinya, proses registrasi hanya melempar event `USER_REGISTERED` ke TxEventQ.
Nanti, ada dua proses *background* (Subscriber) yang akan bekerja secara mandiri:

1. **Email_Service:** Mengirim email selamat datang.
2. **Point_Service:** Memberikan 50 poin pendaftaran.

### Tahap 1: Persiapan Tabel dan TxEventQ

Pastikan Anda *login* dengan *user* yang memiliki akses `AQ_ADMINISTRATOR_ROLE`.

```sql
-- 1. Buat tabel utama
CREATE TABLE tb_users (
    user_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    email VARCHAR2(100),
    points NUMBER DEFAULT 0,
    status VARCHAR2(20) DEFAULT 'ACTIVE'
);

-- 2. Buat tabel log untuk membuktikan Listener berjalan asinkron
CREATE TABLE tb_email_logs (
    log_id NUMBER GENERATED BY DEFAULT AS IDENTITY,
    email_target VARCHAR2(100),
    pesan VARCHAR2(200),
    waktu_kirim TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- 3. Buat TxEventQ (Model Topic / Pub-Sub) menggunakan JSON
BEGIN
    DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
        queue_name          => 'USER_EVENT_Q',
        multiple_consumers  => TRUE, -- Ini wajib TRUE untuk Topic/Subscriber
        queue_payload_type  => 'JSON'
    );
    DBMS_AQADM.START_QUEUE(queue_name => 'USER_EVENT_Q');
END;
/

```

### Tahap 2: Mendaftarkan Subscriber

Kita beritahu Oracle bahwa antrean ini memiliki dua *audience*.

```sql
BEGIN
    -- Mendaftarkan Subscriber 1: Layanan Email
    DBMS_AQADM.ADD_SUBSCRIBER(
        queue_name => 'USER_EVENT_Q',
        subscriber => SYS.AQ$_AGENT('EMAIL_SERVICE', NULL, 0)
    );

    -- Mendaftarkan Subscriber 2: Layanan Poin
    DBMS_AQADM.ADD_SUBSCRIBER(
        queue_name => 'USER_EVENT_Q',
        subscriber => SYS.AQ$_AGENT('POINT_SERVICE', NULL, 0)
    );
END;
/

```

### Tahap 3: Membuat Prosedur Listener (PL/SQL Callback)

Prosedur ini **tidak menggunakan LOOP**. Strukturnya harus menggunakan 5 parameter standar yang diwajibkan Oracle untuk fitur notifikasi. Oracle akan mengirim ID Pesan (`descr.msg_id`) melalui parameter, dan kita tinggal men-`DEQUEUE` pesan tersebut.

**A. Listener untuk Email Service:**

```sql
CREATE OR REPLACE PROCEDURE cb_email_service(
    context  RAW,
    reginfo  SYS.AQ$_REG_INFO,
    descr    SYS.AQ$_DESCRIPTOR,
    payload  RAW,
    payloadl NUMBER
) AS
    v_dequeue_options    DBMS_AQ.DEQUEUE_OPTIONS_T;
    v_message_props      DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_msg_id             RAW(16);
    v_payload            JSON;
    v_email              VARCHAR2(100);
BEGIN
    -- Beritahu Oracle bahwa kita mendequeue sebagai EMAIL_SERVICE
    v_dequeue_options.consumer_name := 'EMAIL_SERVICE';
    -- Kita hanya mengambil pesan dengan ID yang diberikan oleh trigger Oracle
    v_dequeue_options.msgid         := descr.msg_id;

    DBMS_AQ.DEQUEUE(
        queue_name         => descr.queue_name,
        dequeue_options    => v_dequeue_options,
        message_properties => v_message_props,
        payload            => v_payload,
        msgid              => v_msg_id
    );

    -- Ekstrak JSON
    v_email := JSON_VALUE(v_payload, '$.email');

    -- LOGIKA BISNIS: Simulasikan pengiriman email dengan insert ke tabel log
    INSERT INTO tb_email_logs (email_target, pesan) 
    VALUES (v_email, 'Selamat datang di sistem kami!');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- Dalam production, Anda bisa mencatat error di sini
END cb_email_service;
/

```

**B. Listener untuk Point Service:**

```sql
CREATE OR REPLACE PROCEDURE cb_point_service(
    context  RAW,
    reginfo  SYS.AQ$_REG_INFO,
    descr    SYS.AQ$_DESCRIPTOR,
    payload  RAW,
    payloadl NUMBER
) AS
    v_dequeue_options    DBMS_AQ.DEQUEUE_OPTIONS_T;
    v_message_props      DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_msg_id             RAW(16);
    v_payload            JSON;
    v_user_id            NUMBER;
BEGIN
    -- Beritahu Oracle bahwa kita mendequeue sebagai POINT_SERVICE
    v_dequeue_options.consumer_name := 'POINT_SERVICE';
    v_dequeue_options.msgid         := descr.msg_id;

    DBMS_AQ.DEQUEUE(
        queue_name         => descr.queue_name,
        dequeue_options    => v_dequeue_options,
        message_properties => v_message_props,
        payload            => v_payload,
        msgid              => v_msg_id
    );

    -- Ekstrak JSON
    v_user_id := JSON_VALUE(v_payload, '$.user_id');

    -- LOGIKA BISNIS: Tambahkan 50 poin ke user tersebut
    UPDATE tb_users 
    SET points = points + 50 
    WHERE user_id = v_user_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END cb_point_service;
/

```

### Tahap 4: Mengaktifkan Trigger (Mendaftarkan Callback)

Ini adalah langkah krusial. Kita menghubungkan Queue + Subscriber dengan Prosedur yang baru kita buat. Ketika ada pesan masuk, Oracle akan otomatis memanggil prosedur terkait.

```sql
BEGIN
    -- Binding Subscriber Email ke Prosedur cb_email_service
    DBMS_AQ.REGISTER(
        SYS.AQ$_REG_INFO_LIST(
            SYS.AQ$_REG_INFO(
                'USER_EVENT_Q:EMAIL_SERVICE', -- Format: NAMA_QUEUE:NAMA_SUBSCRIBER
                DBMS_AQ.NAMESPACE_AQ,
                'plsql://cb_email_service',   -- Prosedur yang dipanggil
                HEXTORAW('FF')
            )
        ),
        1
    );

    -- Binding Subscriber Point ke Prosedur cb_point_service
    DBMS_AQ.REGISTER(
        SYS.AQ$_REG_INFO_LIST(
            SYS.AQ$_REG_INFO(
                'USER_EVENT_Q:POINT_SERVICE', 
                DBMS_AQ.NAMESPACE_AQ,
                'plsql://cb_point_service', 
                HEXTORAW('FF')
            )
        ),
        1
    );
END;
/

```

### Tahap 5: Membuat Producer

Kita bungkus logika pembuatan user dan pelemparan event ke dalam satu prosedur.

```sql
CREATE OR REPLACE PROCEDURE register_user(p_email IN VARCHAR2) AS
    v_user_id          NUMBER;
    v_enqueue_options  DBMS_AQ.ENQUEUE_OPTIONS_T;
    v_msg_props        DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_msg_id           RAW(16);
    v_payload          JSON;
BEGIN
    -- 1. Insert ke tabel (Proses Sinkron)
    INSERT INTO tb_users (email) 
    VALUES (p_email) 
    RETURNING user_id INTO v_user_id;

    -- 2. Siapkan Event Data
    v_payload := JSON('{' ||
                      '"event":"USER_REGISTERED",' ||
                      '"user_id":' || v_user_id || ',' ||
                      '"email":"' || p_email || '"' ||
                      '}');

    -- 3. Publish Event ke TxEventQ (Proses Asinkron)
    DBMS_AQ.ENQUEUE(
        queue_name         => 'USER_EVENT_Q',
        enqueue_options    => v_enqueue_options,
        message_properties => v_msg_props,
        payload            => v_payload,
        msgid              => v_msg_id
    );

    -- 4. Sahkan Transaksi
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Registrasi berhasil, event dikirim dengan ID: ' || RAWTOHEX(v_msg_id));
END;
/

```

### Tahap 6: Eksekusi dan Pembuktian

Sekarang jalankan pendaftaran user (Producer):

```sql
EXEC register_user('budi@example.com');

```

**Apa yang terjadi di belakang layar?**

1. Data masuk ke `tb_users` (point = 0).
2. Pesan JSON masuk ke `USER_EVENT_Q`.
3. Karena `register_user` sudah selesai, session Anda langsung bebas.
4. Di *background* (hampir seketika), fitur Notification Oracle mendeteksi pesan baru.
5. Oracle menjalankan `cb_email_service` dan `cb_point_service` secara paralel.
6. `cb_email_service` mendequeue pesannya, membaca email, dan melakukan INSERT ke `tb_email_logs`.
7. `cb_point_service` mendequeue pesannya (salinannya sendiri), membaca user_id, dan melakukan UPDATE poin di `tb_users`.

**Cara membuktikannya (tunggu 1-2 detik lalu jalankan query ini):**

```sql
-- Cek apakah poin bertambah jadi 50 (Bukti cb_point_service jalan)
SELECT * FROM tb_users;

-- Cek apakah log email terbuat (Bukti cb_email_service jalan)
SELECT * FROM tb_email_logs;

```

Jika semuanya tereksekusi dengan benar, Anda baru saja menciptakan sistem *microservices event-driven* murni 100% menggunakan PL/SQL tanpa server *middleware* eksternal. Infrastruktur ini bisa menangani ribuan transaksi per detik tanpa memblokir aplikasi utama.

---

## 5. Mekanisme Retry Failed Event

Memastikan tidak ada satupun pesan (event) yang terlewat atau hilang (Zero Data Loss) adalah hal penting dalam Arsitektur Event-Driven.

Di dalam Oracle TxEventQ, sebuah pesan umumnya mengalami dua jenis kegagalan:

- **Gagal (Menjadi EXPIRED)**: Pesan berhasil diambil oleh Consumer/Listener, namun terjadi error (misal: gagal koneksi API, salah format, dsb) sehingga prosedur melakukan Rollback. Oracle akan mencoba ulang, dan jika gagal terus, pesan dipindahkan ke Exception Queue (Dead Letter Queue).

- **Nyangkut (Tetap READY)**: Pesan tidak pernah disentuh sama sekali. Biasanya karena Listener mati, trigger notifikasi rusak, atau server down.


Berikut adalah penyelesaian apabila terdapat event yang gagal di deliver, mencakup **penyiapan infrastruktur**, **penerapan Idempotency pada Listener**, **prosedur otomatis pengiriman ulang (Reprocess)**, serta **Job Sweeper otomatis** menggunakan PL/SQL dan payload JSON.

`Idempoten artinya:` Sebuah pesan bisa diproses berkali-kali, namun hasil di database tetap sama seperti diproses satu kali.

### Alur Sistem Penanganan Error

```text
[ Producer ] ──> ( USER_EVENT_Q )
                        │
                        ▼
             [ Listener / Callback ]
                        │
       ┌────────────────┴────────────────┐
       │ Cek Idempotency                 │
       ├─────────────────────────────────┤
       │ True: Abaikan (Sudah pernah)    │
       │ False: Eksekusi Logika Bisnis   │
       └────────────────┬────────────────┘
                        │
         ┌──────────────┴──────────────┐
      [ Sukses ]                   [ Gagal ]
         │                             │
         ▼                             ▼
 Catat ke Table             Catat ke Table
 tb_processed_events        tb_failed_events
                                       │
                                       ▼
                       [ Automatic Sweeper Job ]
                                       │
                    ┌──────────────────┴──────────────────┐
               Retry < Max                       Retry >= Max
                    │                                     │
                    ▼                                     ▼
           Re-Enqueue ke Queue               Set Status: DEAD_LETTER

```

---

### Langkah 1: Buat Tabel Pendukung (Idempotency & Failure Tracking)

Jalankan skrip DDL ini:

```sql
-- 1. Tabel Idempotency (Mencegah eksekusi ganda saat retry)
CREATE TABLE tb_processed_events (
    msg_id        RAW(16),
    consumer_name VARCHAR2(50),
    processed_at  TIMESTAMP DEFAULT SYSTIMESTAMP,
    PRIMARY KEY (msg_id, consumer_name)
);

-- 2. Tabel Log Event Gagal (Dead Letter & Retry Queue)
CREATE TABLE tb_failed_events (
    fail_id       NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    queue_name    VARCHAR2(50),
    consumer_name VARCHAR2(50),
    msg_id        RAW(16),
    payload       JSON,
    error_msg     VARCHAR2(4000),
    retry_count   NUMBER DEFAULT 0,
    max_retry     NUMBER DEFAULT 3,
    status        VARCHAR2(20) DEFAULT 'FAILED', -- FAILED, RETRIED, DEAD_LETTER, ALARM
    created_at    TIMESTAMP DEFAULT SYSTIMESTAMP,
    updated_at    TIMESTAMP DEFAULT SYSTIMESTAMP
);

```

---

### Langkah 2: Implementasi Listener Tangguh

Ubah prosedur *Callback Listener* Anda (contoh: `cb_point_service`) agar menerapkan **Idempotency** dan **Graceful Error Catching**.


```sql
CREATE OR REPLACE PROCEDURE cb_point_service(
    context  RAW,
    reginfo  SYS.AQ$_REG_INFO,
    descr    SYS.AQ$_DESCRIPTOR,
    payload  RAW,
    payloadl NUMBER
) AS
    v_dequeue_options    DBMS_AQ.DEQUEUE_OPTIONS_T;
    v_message_props      DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_msg_id             RAW(16);
    v_payload            JSON;
    v_user_id            NUMBER;
    v_already_processed  NUMBER := 0;
    v_error_msg          VARCHAR2(4000);
BEGIN
    -- 1. Dequeue Pesan
    v_dequeue_options.consumer_name := 'POINT_SERVICE';
    v_dequeue_options.msgid         := descr.msg_id;

    DBMS_AQ.DEQUEUE(
        queue_name         => descr.queue_name,
        dequeue_options    => v_dequeue_options,
        message_properties => v_message_props,
        payload            => v_payload,
        msgid              => v_msg_id
    );

    -- 2. CEK IDEMPOTENCY
    SELECT COUNT(*) INTO v_already_processed
    FROM tb_processed_events
    WHERE msg_id = v_msg_id AND consumer_name = 'POINT_SERVICE';

    IF v_already_processed > 0 THEN
        COMMIT; 
        RETURN;
    END IF;

    -- 3. LOGIKA BISNIS DENGAN ERROR HANDLING
    BEGIN
        v_user_id := JSON_VALUE(v_payload, '$.user_id');

        -- Eksekusi update
        UPDATE tb_users 
        SET points = points + 50 
        WHERE user_id = v_user_id;

        -- Jika tidak ada baris ter-update
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'User ID ' || v_user_id || ' tidak ditemukan di tb_users.');
        END IF;

        -- Catat bahwa pesan ini SUKSES
        INSERT INTO tb_processed_events (msg_id, consumer_name) 
        VALUES (v_msg_id, 'POINT_SERVICE');

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK; 
            
            -- Tangkap pesan error ke variabel lokal terlebih dahulu (Best Practice)
            v_error_msg := SUBSTR(SQLERRM, 1, 4000);
            
            -- Pindahkan pesan yang gagal ke tb_failed_events
            -- PASTIKAN STRUKTUR TABEL tb_failed_events SESUAI (Ada kolom queue_name, consumer_name, dll)
            INSERT INTO tb_failed_events (
                queue_name, 
                consumer_name, 
                msg_id, 
                payload, 
                error_msg, 
                status
            ) VALUES (
                descr.queue_name, 
                'POINT_SERVICE', 
                v_msg_id, 
                v_payload, 
                v_error_msg, 
                'FAILED'
            );
            
            COMMIT; 
    END;
END cb_point_service;
/

```

---

### Langkah 3: Mekanisme Pengiriman Ulang Event Gagal (Reprocess / Re-Enqueue)

Prosedur ini berfungsi mengambil data dari `tb_failed_events` yang berstatus `'FAILED'` dan **mengirimkannya kembali ke TxEventQ** sebagai pesan baru. Jika batas *retry* telah tercapai, status diubah menjadi `'DEAD_LETTER'`.

```sql
CREATE OR REPLACE PROCEDURE sp_reprocess_failed_events AS
    v_enqueue_options   DBMS_AQ.ENQUEUE_OPTIONS_T;
    v_message_props     DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_new_msg_id        RAW(16);
    v_reprocessed_count NUMBER := 0;
BEGIN
    FOR rec IN (
        SELECT fail_id, queue_name, payload, retry_count, max_retry
        FROM tb_failed_events
        WHERE status = 'FAILED'
        FOR UPDATE SKIP LOCKED -- Mencegah bentrokan jika dijalankan bersamaan
    ) LOOP
        -- Jika percobaan sudah mencapai batas maksimal, tandai sebagai DEAD_LETTER
        IF rec.retry_count >= rec.max_retry THEN
            UPDATE tb_failed_events
            SET status = 'DEAD_LETTER',
                updated_at = SYSTIMESTAMP
            WHERE fail_id = rec.fail_id;
        ELSE
            -- Kirim ulang (Re-Enqueue) payload JSON ke antrean utama
            DBMS_AQ.ENQUEUE(
                queue_name         => rec.queue_name,
                enqueue_options    => v_enqueue_options,
                message_properties => v_message_props,
                payload            => rec.payload,
                msgid              => v_new_msg_id
            );

            -- Perbarui status event
            UPDATE tb_failed_events
            SET retry_count = retry_count + 1,
                status      = 'RETRIED',
                updated_at  = SYSTIMESTAMP
            WHERE fail_id = rec.fail_id;

            v_reprocessed_count := v_reprocessed_count + 1;
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Total event dikirim ulang: ' || v_reprocessed_count);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_reprocess_failed_events;
/

```

---

### Langkah 4: Otomasi dengan Sweeper & Monitoring Job

Buat prosedur *Sweeper* yang akan mendeteksi event tersangkut (`READY` lebih dari 15 menit) sekaligus mengeksekusi reprocess event gagal secara otomatis.

```sql
CREATE OR REPLACE PROCEDURE sp_sweeper_job AS
    v_stuck_count NUMBER := 0;
BEGIN
    -- 1. Jalankan pemrosesan ulang untuk event gagal yang masih memiliki kuota retry
    sp_reprocess_failed_events;

    -- 2. DETEKSI EVENT NYANGKUT: Cek antrean jika ada status READY > 15 menit
    SELECT COUNT(*) INTO v_stuck_count
    FROM AQ$USER_EVENT_Q
    WHERE msg_state = 'READY'
      AND enq_time < SYSTIMESTAMP - INTERVAL '15' MINUTE;

    -- 3. Jika ada event tersangkut, catat peringatan alarm
    IF v_stuck_count > 0 THEN
        INSERT INTO tb_failed_events (
            queue_name, consumer_name, error_msg, status
        ) VALUES (
            'USER_EVENT_Q', 
            'SYSTEM_SWEEPER', 
            'PERINGATAN: Terdapat ' || v_stuck_count || ' event berstatus READY tersangkut lebih dari 15 menit!', 
            'ALARM'
        );
        COMMIT;
    END IF;
END sp_sweeper_job;
/

```

Daftarkan prosedur *Sweeper* ini ke `DBMS_SCHEDULER` agar berjalan otomatis setiap 15 menit:

```sql
-- grant access scheduler ke user dev, jalankan sebagai sys
GRANT CREATE JOB TO dev;
/

-- daftarkan scheduler, jalankan sebagai user dev
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name        => 'JOB_TXEVENTQ_SWEEPER',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'sp_sweeper_job',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=15',
        enabled         => TRUE,
        comments        => 'Otomatis memproses ulang event gagal dan memantau event nyangkut'
    );
END;
/

```

Anda dapat menggunakan sintaks dibawah untuk melihat summary dari masing-masing service
```sql
SELECT
    consumer_name AS "Layanan Tujuan (Subscriber)",
    COUNT(DECODE(msg_state, 'READY', 1)) AS "Antre (Belum Diproses)",
    COUNT(DECODE(msg_state, 'PROCESSED', 1)) AS "Selesai (Menunggu Cleanup)",
    COUNT(DECODE(msg_state, 'EXPIRED', 1)) AS "Kedaluwarsa (Gagal Internal)",
    MIN(CASE WHEN msg_state = 'READY' THEN enq_time ELSE NULL END) AS "Antrean Terlama",
    ROUND((SYSDATE - CAST(MIN(CASE WHEN msg_state = 'READY' THEN enq_time ELSE NULL END) AS DATE)) * 24 * 60, 2) AS "Lama Antrean Terlama (Menit)"
FROM
    dev.AQ$USER_EVENT_Q
WHERE
    consumer_name IS NOT NULL
GROUP BY
    consumer_name
ORDER BY
    "Antre (Belum Diproses)" DESC;

```

---

### Matriks Pengujian dan Hasil

| Skenario Pengujian | Hasil Sistem |
| --- | --- |
| **Normal Execution** | Event terkirim --> Listener sukses --> Data masuk `tb_processed_events` --> Poin ter-update. |
| **Error Sementara (DB Busy / Lock)** | Listener tangkap error --> Data masuk `tb_failed_events` (`status = 'FAILED'`) --> `JOB_TXEVENTQ_SWEEPER` jalan --> Event di-enqueue ulang (`status = 'RETRIED'`). |
| **Error Permanen (Data Korup)** | Event dicoba ulang hingga `retry_count = 3` --> Status diubah menjadi `'DEAD_LETTER'` --> Antrean utama tetap bersih. |
| **Event Duplikat (Retry Berulang)** | Listener cek `tb_processed_events` --> Ditemukan record lama --> Eksekusi dilewati tanpa melakukan `UPDATE` poin ganda (Idempotent). |

---

## 6. Integrasi TXEventQ (JSON) ke Kafka Connect (JMS)

Tahapan ini adalah tahapan tambahan, jika membuat event-driven di Oracle DB dengan tipe payload JSON kemudian ingin mengintegrasikannya ke Kafka melalui Kafka Connect yang menggunakan tipe payload JMS maka perlu dikonversi terlebih dahulu.

Menggunakan **Skenario Arsitektur Jembatan / Hybrid** adalah salah satu pola desain integrasi (*Integration Design Pattern*) terbaik.

Dengan cara ini, aplikasi inti (Oracle) tetap modern, cepat, dan bersih menggunakan tipe data `JSON`, sementara kebutuhan sistem eksternal (Kafka Connect JMS) tetap terpenuhi tanpa merusak ekosistem yang ada.

Berikut adalah contoh penerapan lengkap beserta sintaks konversinya dari awal hingga akhir.

---

### Tahap 1: Membuat Antrean Khusus Kafka (JMS Type)

Kita buat satu antrean baru yang tugasnya **hanya** sebagai "pintu keluar" menuju Kafka. Antrean ini menggunakan tipe `JMS_TYPE` dan bersifat *Point-to-Point* (karena hanya Kafka Connect yang akan membacanya).

```sql
BEGIN
    -- Membuat Queue Khusus Outbound Kafka (Tipe JMS)
    DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
        queue_name          => 'KAFKA_OUTBOUND_Q',
        multiple_consumers  => FALSE, -- Kafka Connect langsung ambil tanpa perlu langganan
        queue_payload_type  => DBMS_AQADM.JMS_TYPE
    );
    DBMS_AQADM.START_QUEUE(queue_name => 'KAFKA_OUTBOUND_Q');
END;
/

```

### Tahap 2: Mendaftarkan Subscriber Baru di Antrean JSON Utama

Kita tambahkan satu *Subscriber* (pendengar) lagi pada `USER_EVENT_Q` (antrean JSON Anda yang sudah ada).

```sql
BEGIN
    -- Daftarkan agen penjembatan
    DBMS_AQADM.ADD_SUBSCRIBER(
        queue_name => 'USER_EVENT_Q',
        subscriber => SYS.AQ$_AGENT('KAFKA_BRIDGE_SVC', NULL, 0)
    );
END;
/

```

### Tahap 3: Prosedur Listener Konversi (Jembatan JSON --> JMS)

Ini adalah **jantung dari Skenario B**. Prosedur ini akan secara otomatis men-*dequeue* pesan berformat `JSON`, mengubahnya menjadi teks biasa, membungkusnya dalam format `SYS.AQ$_JMS_TEXT_MESSAGE`, lalu men-*enqueue* ke antrean Kafka.

```sql
CREATE OR REPLACE PROCEDURE cb_kafka_bridge(
    context  RAW,
    reginfo  SYS.AQ$_REG_INFO,
    descr    SYS.AQ$_DESCRIPTOR,
    payload  RAW,
    payloadl NUMBER
) AS
    -- Variabel untuk DEQUEUE (Antrean JSON)
    v_deq_opt          DBMS_AQ.DEQUEUE_OPTIONS_T;
    v_msg_props_in     DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_msg_id_in        RAW(16);
    v_payload_json     JSON;           
    v_json_text        VARCHAR2(4000); 

    -- Variabel untuk ENQUEUE (Antrean JMS)
    v_enq_opt          DBMS_AQ.ENQUEUE_OPTIONS_T;
    v_msg_props_out    DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_msg_id_out       RAW(16);
    v_payload_jms      SYS.AQ$_JMS_TEXT_MESSAGE; 
    
    -- Variabel penampung untuk Error Handling
    v_error_msg        VARCHAR2(4000);
    v_queue_name       VARCHAR2(128);
BEGIN
    -- 1. DEQUEUE PESAN DARI ANTREAN JSON (USER_EVENT_Q)
    v_deq_opt.consumer_name := 'KAFKA_BRIDGE_SVC';
    v_deq_opt.msgid         := descr.msg_id;

    DBMS_AQ.DEQUEUE(
        queue_name         => descr.queue_name,
        dequeue_options    => v_deq_opt,
        message_properties => v_msg_props_in,
        payload            => v_payload_json,
        msgid              => v_msg_id_in
    );

    -- 2. PROSES KONVERSI: JSON -> STRING -> JMS_TEXT_MESSAGE
    
    -- A. Ubah tipe native JSON menjadi VARCHAR2
    v_json_text := JSON_SERIALIZE(v_payload_json);

    -- B. Konstruksi / Bangun struktur pesan JMS Oracle
    v_payload_jms := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
    
    -- C. Isi pesan JMS dengan string JSON tadi
    v_payload_jms.set_text(v_json_text);

    -- 3. ENQUEUE PESAN KE ANTREAN KAFKA (KAFKA_OUTBOUND_Q)
    DBMS_AQ.ENQUEUE(
        queue_name         => 'KAFKA_OUTBOUND_Q',
        enqueue_options    => v_enq_opt,
        message_properties => v_msg_props_out,
        payload            => v_payload_jms,
        msgid              => v_msg_id_out
    );

    -- 4. COMMIT!
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        
        -- Tangkap nilai ke variabel skalar sebelum proses INSERT
        v_error_msg  := SUBSTR('Error di Bridge: ' || SQLERRM, 1, 4000);
        v_queue_name := descr.queue_name;
        
        -- Catat ke tabel error menggunakan variabel skalar
        INSERT INTO tb_failed_events (queue_name, consumer_name, error_msg)
        VALUES (v_queue_name, 'KAFKA_BRIDGE_SVC', v_error_msg);
        
        COMMIT;
END cb_kafka_bridge;
/

```

### Tahap 4: Mengaktifkan Jembatan (Mendaftarkan Callback)

Agar prosedur di atas berjalan otomatis, ikat *Subscriber* dengan prosedurnya.

```sql
BEGIN
    DBMS_AQ.REGISTER(
        SYS.AQ$_REG_INFO_LIST(
            SYS.AQ$_REG_INFO(
                'USER_EVENT_Q:KAFKA_BRIDGE_SVC', -- Antrean Utama JSON
                DBMS_AQ.NAMESPACE_AQ,
                'plsql://cb_kafka_bridge',       -- Panggil prosedur penjembatan
                HEXTORAW('FF')
            )
        ),
        1
    );
END;
/

```

---

### Apa yang Terjadi Sekarang? (Simulasi Alur Kerja)

1. Aplikasi Anda (atau APEX) mengeksekusi `EXEC register_user('andi@example.com');`.
2. Data masuk ke antrean `USER_EVENT_Q` (Tipe JSON).
3. Oracle membuat **tiga** tugas *background* (Callback) secara instan:
* Tugas 1: `cb_email_service` (memproses email dari JSON).
* Tugas 2: `cb_point_service` (memproses poin dari JSON).
* Tugas 3: **`cb_kafka_bridge` (mengubah JSON ke JMS dan melempar ke `KAFKA_OUTBOUND_Q`)**.
4. Ketiganya selesai.

### Tahap 5: Penyesuaian Terakhir di Kafka Connect

Tahapan selanjutnya adalah membuat file `source-connector-bridge.json` di konfigurasi Kafka Connect Anda:
```json
{
  "name": "txeventq-source-bridge", 
  "config": {
    "connector.class": "io.confluent.connect.jms.JmsSourceConnector",
    "kafka.topic": "topik.events.baru", 
    "jms.destination.name": "KAFKA_OUTBOUND_Q", 
    "jms.destination.type": "queue",
    "java.naming.factory.initial": "oracle.jms.AQjmsInitialContextFactory",
    "java.naming.provider.url": "jdbc:oracle:thin:@//manual-db:1521/FREEPDB1",
    "db_url": "jdbc:oracle:thin:@//manual-db:1521/FREEPDB1",
    "java.naming.security.principal": "dev",
    "java.naming.security.credentials": "KatasandiKuat123!",
    "confluent.license": "",
    "confluent.topic.bootstrap.servers": "kafka:29092",
    "confluent.topic.replication.factor": "1",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false"
  }
}

```

Muat via `curl`:

```bash
curl -X POST -H "Content-Type: application/json" \
  --data @source-connector-bridge.json \
  http://localhost:8083/connectors

```

Jalankan perintah dibawah untuk memeriksa connector berhasil berjalan
```bash
curl -s localhost:8083/connectors/txeventq-source-bridge/status

```

Pastikan `"state": "RUNNING"` di connector dan task-nya.

Apabila `"state": "FAILED"` maka terjadi kesalahan konfigurasi, hapus dan lakukan konfigurasi ulang
```bash
curl -X DELETE localhost:8083/connectors/txeventq-source-bridge

```

Periksa pada antrian Oracle bahwa message status telah berubah menjadi PROCESSED
```sql
SELECT msg_id, enq_time, msg_state, consumer_name
FROM dev.AQ$KAFKA_OUTBOUND_Q;

```

Periksa pada antrian bahwa message telah masuk
```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic bridge.events \
  --from-beginning

```

**Selesai!** Dengan desain ini, jika sewaktu-waktu Kafka mati atau Anda ingin mengganti Kafka Connect dengan *tool* lain, logika bisnis utama Anda (Poin, Email, Database) yang menggunakan arsitektur JSON tidak akan tersentuh atau terganggu sama sekali. Ini adalah pemisahan tugas (*Separation of Concerns*) yang sangat elegan.