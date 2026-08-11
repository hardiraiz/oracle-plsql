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