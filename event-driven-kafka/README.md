# Studi Kasus: Oracle TxEventQ + Kafka Connect + Bun.js

Panduan ini memakai pendekatan **native** menggunakan container Kafka, Kafka Connect, Zookeeper, dan Oracle Database Free 23ai. Oracle cukup menulis/membaca pesan ke "kotak surat" internal (TxEventQ), dan **Kafka Connect** yang bertugas menjembatani kotak surat itu ke topic Kafka sungguhan, otomatis dan dua arah.

**NOTE**: Jalankan sintaks dibawah untuk running ulang container secara bertahap setelah selesai install dan konfigurasi
```bash
docker start manual-db && sleep 20 && \
docker start zookeeper && sleep 20 && \
docker start kafka && sleep 10 && \
docker start kafka-connect

```

---

## 0. Konsep Dasar (Baca ini dulu sebelum eksekusi)

**TxEventQ** adalah antrian pesan yang hidup *di dalam* Oracle Database (fitur ini sebelumnya bernama Advanced Queuing/AQ, di-rebrand jadi TxEventQ mulai Oracle 21c). Bayangkan seperti kotak surat: PL/SQL bisa "memasukkan surat" (`DBMS_AQ.ENQUEUE`) atau "mengambil surat" (`DBMS_AQ.DEQUEUE`). Karena kotak surat ini bagian dari database, mengirim pesan sama seperti melakukan `INSERT` biasa — otomatis ikut transaksi bisnis, otomatis rollback kalau transaksi gagal. Tidak ada tabel outbox terpisah yang perlu dikelola manual seperti pendekatan sebelumnya.

**Kafka Connect** adalah "penerjemah" yang berjalan sebagai proses terpisah (container `kafka-connect`). Dia punya dua jenis plugin:
- **Source Connector**: mengambil pesan dari TxEventQ → menaruhnya ke topic Kafka.
- **Sink Connector**: mengambil pesan dari topic Kafka → menaruhnya ke TxEventQ.

Karena Oracle sudah menyediakan library resmi (`aqapi.jar`) yang membuat TxEventQ "terlihat" seperti antrian JMS standar, kita bisa memakai **konektor JMS generik dari Confluent** (`kafka-connect-jms` dan `kafka-connect-jms-sink`) tanpa menulis kode Java sama sekali — cukup konfigurasi JSON.

**Kenapa ini lebih sederhana:** PL/SQL Anda hanya berurusan dengan `DBMS_AQ.ENQUEUE`/`DBMS_AQ.DEQUEUE` (API native Oracle, sudah ada puluhan tahun, stabil). Tidak ada ACL, tidak ada `UTL_HTTP`, tidak ada endpoint ORDS yang perlu diamankan. Kompleksitas jembatan ke Kafka dipindahkan seluruhnya ke Kafka Connect — komponen yang memang dirancang untuk itu.

---

## 1. Studi Kasus yang Akan Dibangun

**Skenario: Notifikasi Transaksi Nasabah.**

1. Nasabah melakukan transaksi → PL/SQL mencatatnya → PL/SQL **ENQUEUE** event `TRANSACTION_CREATED` ke `OUT_Q`.
2. Kafka Connect **Source Connector** memindahkan pesan itu ke topic Kafka `transaksi.events`.
3. Bun.js **consumer** membaca topic itu, "mengirim notifikasi" (kita simulasikan dengan `console.log`), lalu Bun.js **producer** mem-publish event balasan `NOTIFICATION_SENT` ke topic Kafka `notifikasi.events`.
4. Kafka Connect **Sink Connector** memindahkan pesan balasan itu ke `IN_Q`.
5. PL/SQL **listener** (yang sedang "menunggu" di `IN_Q`) langsung mengambil pesan itu dan meng-`UPDATE` status transaksi jadi `'NOTIFIED'`.

Ini menutup siklus penuh: Oracle sebagai Producer dan Listener, Bun.js sebagai Consumer dan Producer.

---

## 2. Persiapan Lingkungan Docker (Kafka + Kafka Connect)

Kita akan membangun infrastruktur dari nol dan menghubungkannya ke container oracle database free 23.26 dengan nama `manual-db` . 

### 2.1. Prasyarat

```bash
docker --version
docker compose version   # pastikan Docker Compose v2 tersedia
docker ps                # pastikan manual-db dan manual-ords memang masih berjalan

```

### 2.2. Buat Network Bersama & Sambungkan Container yang Sudah Ada

Container baru nanti dibuat lewat `docker compose` (punya network sendiri secara default). Supaya semuanya bisa saling memanggil lewat nama container, buat satu network eksternal:

```bash
docker network create integration-net
docker network connect integration-net manual-db

```

Verifikasi keduanya sudah masuk (abaikan error jika muncul peringatan "endpoint already exists"):

```bash
docker network inspect integration-net --format '{{range .Containers}}{{.Name}} {{end}}'

```

### 2.3. Struktur Folder Project

```bash
mkdir -p kafka-infra/oracle-jms-jars && cd kafka-infra

```

Target struktur akhir:

```text
kafka-infra/
├── docker-compose.yml
├── Dockerfile.kafka-connect
└── oracle-jms-jars/
    ├── aqapi-23.9.0.0.jar
    ├── ojdbc11-23.9.0.25.07.jar
    └── jta-1.1.jar

```

### 2.4. Unduh 3 Jar Dependency Oracle

Jar ini membuat Kafka Connect bisa "berbicara" ke TxEventQ lewat JMS.

```bash
cd oracle-jms-jars

# Cek versi terbaru di masing-masing repositori Maven jika diperlukan
curl -O https://repo1.maven.org/maven2/com/oracle/database/messaging/aqapi/23.9.0.0/aqapi-23.9.0.0.jar
curl -O https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc11/23.9.0.25.07/ojdbc11-23.9.0.25.07.jar
curl -O https://repo1.maven.org/maven2/javax/transaction/jta/1.1/jta-1.1.jar

cd ..

```

**NOTE**: Kafka Connect sebagai jembatan dua arah (karena sangat real-time berbasis event-push), arsitektur dengan tipe data JMS_TYPE sudah merupakan best-practice untuk ekosistem Confluent / Kafka standar.


### 2.5. `Dockerfile.kafka-connect` — Image Custom dengan Plugin Bawaan

Dengan image custom ini, plugin JMS Source/Sink Connector beserta ke-3 file `.jar` Oracle sudah otomatis menyatu di dalam container.

Buat file `Dockerfile.kafka-connect`:

```dockerfile
FROM confluentinc/cp-kafka-connect:7.5.0

USER root

RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jms:latest \
 && confluent-hub install --no-prompt confluentinc/kafka-connect-jms-sink:latest

COPY oracle-jms-jars/*.jar /usr/share/confluent-hub-components/confluentinc-kafka-connect-jms/lib/
COPY oracle-jms-jars/*.jar /usr/share/confluent-hub-components/confluentinc-kafka-connect-jms-sink/lib/

```

### 2.6. `docker-compose.yml`

Buat file `docker-compose.yml`:

```yaml
networks:
  integration-net:
    external: true

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: zookeeper
    mem_limit: 256m
    networks: [integration-net]
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
      KAFKA_HEAP_OPTS: "-Xms128m -Xmx192m"
    ports:
      - "2181:2181"

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: kafka
    mem_limit: 768m
    networks: [integration-net]
    depends_on: [zookeeper]
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      # INTERNAL dipakai container lain di network yang sama (Kafka Connect, dsb)
      # HOST dipakai untuk akses dari mesin lokal (mis. Bun.js yang jalan di host)
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,HOST:PLAINTEXT
      KAFKA_LISTENERS: INTERNAL://0.0.0.0:29092,HOST://0.0.0.0:9092
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka:29092,HOST://localhost:9092
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_HEAP_OPTS: "-Xms256m -Xmx512m"

  kafka-connect:
    build:
      context: .
      dockerfile: Dockerfile.kafka-connect
    container_name: kafka-connect
    mem_limit: 1024m
    networks: [integration-net]
    depends_on: [kafka]
    ports:
      - "8083:8083"
    environment:
      CONNECT_BOOTSTRAP_SERVERS: "kafka:29092"
      CONNECT_REST_ADVERTISED_HOST_NAME: "kafka-connect"
      CONNECT_GROUP_ID: "connect-cluster"
      CONNECT_CONFIG_STORAGE_TOPIC: "connect-configs"
      CONNECT_OFFSET_STORAGE_TOPIC: "connect-offsets"
      CONNECT_STATUS_STORAGE_TOPIC: "connect-status"
      CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_STATUS_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_KEY_CONVERTER: "org.apache.kafka.connect.json.JsonConverter"
      CONNECT_VALUE_CONVERTER: "org.apache.kafka.connect.json.JsonConverter"
      CONNECT_PLUGIN_PATH: "/usr/share/java,/usr/share/confluent-hub-components"
      CONNECT_CONFLUENT_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_HEAP_OPTS: "-Xms384m -Xmx768m"

```

### 2.7. Build & Jalankan

```bash
docker compose up -d --build

```

Tunggu hingga proses build selesai, lalu pastikan semuanya berstatus `Up` dengan perintah `docker compose ps`.

### 2.8. Verifikasi Infrastruktur

Pastikan Kafka broker hidup:

```bash
docker exec -it kafka kafka-topics --bootstrap-server localhost:9092 --list

```

Pastikan plugin JMS terpasang di Kafka Connect:

```bash
curl -s localhost:8083/connector-plugins | grep -i jms

```

Pastikan `kafka-connect` bisa menghubungi database:

```bash
docker exec -it kafka-connect bash -c "cat < /dev/null > /dev/tcp/manual-db/1521 && echo 'OK: port 1521 terjangkau'"

```

### 2.9. Troubleshooting Setup Docker

| Gejala | Kemungkinan Penyebab |
| --- | --- |
| `docker compose up --build` gagal di tahap `confluent-hub install` | Container tidak punya akses internet keluar saat build, atau rate-limit dari Confluent Hub — coba ulang beberapa saat lagi. |
| `kafka-connect` restart terus-menerus | Cek log (`docker compose logs kafka-connect`). Biasanya salah satu `CONNECT_*` typo, atau Kafka belum siap saat Connect mencoba konek. |
| `manual-db` tidak terjangkau meski sudah `network connect` | Pastikan port `1521` di-listen di dalam container (`docker exec -it manual-db lsnrctl status`). |
| Port `9092`/`8083`/`2181` sudah dipakai proses lain | Ganti pemetaan port di `docker-compose.yml` (misal `"19092:9092"`), lalu sesuaikan referensi `localhost` di kode Bun.js nantinya. |

---

## 3. Setup TxEventQ di Oracle

### 3.1. Buat User Khusus & Hak Akses

Jalankan sebagai `SYSTEM` atau `SYS` di dalam `manual-db`:

```sql
GRANT CONNECT, RESOURCE, AQ_ADMINISTRATOR_ROLE TO dev;
GRANT EXECUTE ON DBMS_AQ TO dev;
GRANT EXECUTE ON DBMS_AQADM TO dev;
ALTER USER dev QUOTA UNLIMITED ON USERS;

```

### 3.2. Buat Empat Antrian TxEventQ

Kita akan membuat empat antrian 2 antrian utama untuk pesan keluar dan masuk dalam tipe data JSON dan 2 antrian jembatan masuk dan keluar ke Kafka dengan tipe data JMS

Login sebagai `dev`, lalu eksekusi script ini:

```sql
BEGIN
    -- 1. Antrean Utama Keluar Aplikasi (Tipe JSON)
    DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
        queue_name         => 'dev.out_q', 
        multiple_consumers => TRUE, 
        queue_payload_type => 'JSON'
    );
    DBMS_AQADM.START_QUEUE(queue_name => 'dev.out_q');
    
    -- 2. Antrean Jembatan keluar Kafka (Tipe JMS)
    DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
        queue_name         => 'dev.kafka_out_q', 
        multiple_consumers => FALSE, 
        queue_payload_type => DBMS_AQADM.JMS_TYPE
    );
    DBMS_AQADM.START_QUEUE(queue_name => 'dev.kafka_out_q');

    -- 3. Antrean Utama Masuk Aplikasi (Tipe JSON)
    DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
        queue_name         => 'dev.in_q', 
        multiple_consumers => TRUE, 
        queue_payload_type => 'JSON'
    );
    DBMS_AQADM.START_QUEUE(queue_name => 'dev.in_q');

    -- 4. Antrean Jembatan masuk Kafka (Tipe JMS)
    DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
        queue_name         => 'dev.kafka_in_q', 
        multiple_consumers => TRUE, 
        queue_payload_type => DBMS_AQADM.JMS_TYPE
    );
    DBMS_AQADM.START_QUEUE(queue_name => 'dev.kafka_in_q');
END;
/

```

Berikut sintaks untuk membatalkan sintaks diatas
```sql
BEGIN
    DBMS_AQADM.STOP_QUEUE(
        queue_name => 'dev.out_q'
    );
    DBMS_AQADM.DROP_QUEUE(
        queue_name => 'dev.out_q'
    );

    DBMS_AQADM.STOP_QUEUE(
        queue_name => 'dev.in_q'
    );
    DBMS_AQADM.DROP_QUEUE(
        queue_name => 'dev.in_q'
    );

    DBMS_AQADM.STOP_QUEUE(
        queue_name => 'dev.kafka_in_q'
    );
    DBMS_AQADM.DROP_QUEUE(
        queue_name => 'dev.kafka_in_q'
    );

    DBMS_AQADM.STOP_QUEUE(
        queue_name => 'dev.kafka_out_q'
    );
    DBMS_AQADM.DROP_QUEUE(
        queue_name => 'dev.kafka_out_q'
    );
END;
/

```

*(Verifikasi queue aktif: `SELECT name, queue_type, enqueue_enabled, dequeue_enabled FROM user_queues;`)*

---

## 4. Bagian Producer — PL/SQL Enqueue ke TxEventQ

### 4.1. Tabel Transaksi (Untuk Studi Kasus)

```sql
CREATE TABLE transaksi (
    no_rekening   VARCHAR2(20),
    nominal       NUMBER,
    status        VARCHAR2(20) DEFAULT 'CREATED',
    created_at    TIMESTAMP DEFAULT SYSTIMESTAMP
);

```

### 4.2. Package Producer

`DBMS_AQ.ENQUEUE` ini setara dengan `KafkaProducer.send()` di sisi Oracle.

```sql
create or replace PACKAGE producer_pkg AS
    PROCEDURE catat_transaksi(p_no_rekening IN VARCHAR2, p_nominal IN NUMBER);
END producer_pkg;
/

create or replace PACKAGE BODY producer_pkg AS

    PROCEDURE catat_transaksi(p_no_rekening IN VARCHAR2, p_nominal IN NUMBER) IS
        enqueue_options    DBMS_AQ.ENQUEUE_OPTIONS_T;
        message_properties DBMS_AQ.MESSAGE_PROPERTIES_T;
        message_handle     RAW(16);
        msg                SYS.AQ$_JMS_TEXT_MESSAGE;
        v_payload          JSON;
    BEGIN
        -- 1. Logika bisnis utama
        INSERT INTO transaksi (no_rekening, nominal)
        VALUES (p_no_rekening, p_nominal);

        -- 2. Susun payload JSON sederhana
        v_payload := JSON('{"eventType":"TRANSACTION_CREATED","noRekening":"' || p_no_rekening || '","nominal":' || p_nominal || '}');

        -- 3. ENQUEUE -- ini yang membuat Oracle jadi Producer
        DBMS_AQ.ENQUEUE(
            queue_name         => 'dev.out_q',
            enqueue_options    => enqueue_options,
            message_properties => message_properties,
            payload            => v_payload,
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

```

### 4.3. Uji Coba Manual

```sql
EXEC dev.producer_pkg.catat_transaksi('000001', 100001);
SELECT * FROM AQ$OUT_Q; -- Memastikan pesan masuk antrian

```

---

## 5. Tambahkan Logika Jembatan

Buat prosedur *Listener* baru yang otomatis menerjemahkan JSON ke JMS dan sebaliknya.

Buat table untuk menampung event yang gagal di distribusikan
``` sql
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
/

```

Tambahkan procedure jembatan keluar berikut
```sql
create or replace PROCEDURE cb_bridge_out(
    context  RAW,
    reginfo  SYS.AQ$_REG_INFO,
    descr    SYS.AQ$_DESCRIPTOR,
    payload  RAW,
    payloadl NUMBER
) AS
    -- Variabel Dequeue (Membaca JSON)
    v_deq_opt          DBMS_AQ.DEQUEUE_OPTIONS_T;
    v_msg_props_in     DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_msg_id_in        RAW(16);
    v_payload_json     JSON;
    v_json_string      VARCHAR2(4000);

    -- Variabel Enqueue (Mengirim JMS)
    v_enq_opt          DBMS_AQ.ENQUEUE_OPTIONS_T;
    v_msg_props_out    DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_msg_id_out       RAW(16);
    v_payload_jms      SYS.AQ$_JMS_TEXT_MESSAGE;

    v_error_msg        VARCHAR2(4000);
    v_queue_name       VARCHAR2(128);
BEGIN
    -- 1. DEQUEUE dari antrean JSON
    v_deq_opt.consumer_name := 'BRIDGE_OUT_SVC';
    v_deq_opt.msgid         := descr.msg_id;

    DBMS_AQ.DEQUEUE(
        queue_name         => descr.queue_name, -- Ini akan bernilai 'dev.out_q'
        dequeue_options    => v_deq_opt,
        message_properties => v_msg_props_in,
        payload            => v_payload_json,
        msgid              => v_msg_id_in
    );

    -- 2. KONVERSI (JSON -> VARCHAR2 -> SYS.AQ$_JMS_TEXT_MESSAGE)
    v_json_string := JSON_SERIALIZE(v_payload_json);
    v_payload_jms := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
    v_payload_jms.set_text(v_json_string);

    -- 3. ENQUEUE ke antrean jembatan JMS untuk dibaca Kafka Connect
    DBMS_AQ.ENQUEUE(
        queue_name         => 'dev.kafka_out_q',
        enqueue_options    => v_enq_opt,
        message_properties => v_msg_props_out,
        payload            => v_payload_jms,
        msgid              => v_msg_id_out
    );

    -- 4. SAHKAN TRANSAKSI
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        v_error_msg  := SUBSTR('Error di Bridge Out: ' || SQLERRM, 1, 4000);
        v_queue_name := descr.queue_name;

        INSERT INTO dev.tb_failed_events (queue_name, consumer_name, error_msg)
        VALUES (v_queue_name, 'BRIDGE_OUT_SVC', v_error_msg);

        COMMIT;
END cb_bridge_out;
/

```

Tambahkan procedure jembatan masuk berikut
```sql
create or replace PROCEDURE cb_bridge_in(
    context  RAW, 
    reginfo  SYS.AQ$_REG_INFO, 
    descr    SYS.AQ$_DESCRIPTOR,
    payload  RAW, 
    payloadl NUMBER
) AS
    v_deq_opt          DBMS_AQ.DEQUEUE_OPTIONS_T;
    v_msg_props_in     DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_msg_id_in        RAW(16);

    v_payload_jms      SYS.AQ$_JMS_TEXT_MESSAGE;
    v_json_string      VARCHAR2(32767);

    v_enq_opt          DBMS_AQ.ENQUEUE_OPTIONS_T;
    v_msg_props_out    DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_msg_id_out       RAW(16);
    v_payload_json     JSON;

    v_error_msg        VARCHAR2(4000);
    v_queue_name       VARCHAR2(128);
BEGIN
    -- 1. Dequeue dari JMS
    v_deq_opt.consumer_name := 'BRIDGE_IN_SVC';
    v_deq_opt.msgid         := descr.msg_id;

    DBMS_AQ.DEQUEUE('dev.kafka_in_q', v_deq_opt, v_msg_props_in, v_payload_jms, v_msg_id_in);

    IF v_payload_jms IS NULL THEN COMMIT; RETURN; END IF;

    -- 2. Ekstrak string JMS
    v_json_string := v_payload_jms.text_vc;
    IF v_json_string IS NULL AND v_payload_jms.text_lob IS NOT NULL THEN
        v_json_string := DBMS_LOB.SUBSTR(v_payload_jms.text_lob, 4000, 1);
    END IF;

    IF v_json_string IS NULL THEN COMMIT; RETURN; END IF;

    -- 3. Konversi ke native JSON
    v_payload_json := JSON(v_json_string);

    -- 4. Enqueue ke in_q
    DBMS_AQ.ENQUEUE(
        queue_name         => 'dev.in_q',
        enqueue_options    => v_enq_opt,
        message_properties => v_msg_props_out, 
        payload            => v_payload_json,
        msgid              => v_msg_id_out
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        v_error_msg  := SUBSTR('Error di Bridge In: ' || SQLERRM, 1, 4000);
        v_queue_name := descr.queue_name;

        INSERT INTO dev.tb_failed_events (queue_name, consumer_name, error_msg)
        VALUES (v_queue_name, 'BRIDGE_IN_SVC', v_error_msg);

        COMMIT;
END cb_bridge_in;
/

```

---

## 6. Bagian Listener — PL/SQL Dequeue dari TxEventQ

PL/SQL Notifications (Event-Driven Asli) - BEST PRACTICE
Oracle memiliki fitur di mana Listener tidur total. Oracle Database sendiri yang akan "membangunkan" (men-trigger) prosedur PL/SQL hanya pada saat ada pesan baru masuk ke antrean.

- Kelebihan: Tidak memakan resource saat tidak ada pesan. Sangat hemat dan elegan. Skalabel.
- Kekurangan: Ada jeda waktu (sekian milidetik) bagi Oracle untuk melakukan spawn job saat pesan tiba.

### 6.1. Package Listener

```sql
create or replace PACKAGE     listener_pkg AS
    
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

create or replace PACKAGE BODY listener_pkg AS

    PROCEDURE cb_process_event(
        context  RAW,
        reginfo  SYS.AQ$_REG_INFO,
        descr    SYS.AQ$_DESCRIPTOR,
        payload  RAW,
        payloadl NUMBER
    ) IS
        v_dequeue_options    DBMS_AQ.DEQUEUE_OPTIONS_T;
        v_message_properties DBMS_AQ.MESSAGE_PROPERTIES_T;
        v_message_handle     RAW(16);
        v_payload            JSON;           

        v_no_rekening        VARCHAR2(20);
        v_error_msg          VARCHAR2(4000);
        v_queue_name         VARCHAR2(128);
    BEGIN
        -- 1. Siapkan opsi DEQUEUE berdasarkan trigger yang dikirim Oracle
        v_dequeue_options.msgid         := descr.msg_id;
        v_dequeue_options.consumer_name := descr.consumer_name;

        -- 2. Eksekusi DEQUEUE dari antrean (dev.in_q)
        DBMS_AQ.DEQUEUE(
            queue_name         => descr.queue_name,
            dequeue_options    => v_dequeue_options,
            message_properties => v_message_properties,
            payload            => v_payload,
            msgid              => v_message_handle
        );

        -- 3. Parsing JSON dan Eksekusi Logika Bisnis
        -- Karena v_payload sudah bertipe JSON, kita bisa langsung ekstrak datanya
        v_no_rekening := JSON_VALUE(v_payload, '$.noRekening');

        -- Lakukan Update status pada tabel transaksi
        UPDATE transaksi
        SET status = 'NOTIFIED'
        WHERE no_rekening = v_no_rekening
          AND status = 'CREATED';

        -- 4. SAHKAN TRANSAKSI
        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;

            -- Tangkap error dengan aman
            v_error_msg  := SUBSTR('Error di Listener Utama: ' || SQLERRM, 1, 4000);
            v_queue_name := descr.queue_name;

            -- Catat error ke tabel log agar tidak hilang dan antrean tetap jalan
            INSERT INTO dev.tb_failed_events (queue_name, consumer_name, error_msg)
            VALUES (v_queue_name, descr.consumer_name, v_error_msg);

            COMMIT;
    END cb_process_event;

END listener_pkg;
/

```

### 6.2. Daftarkan Subscriber dan Callback untuk Listener

Jalankan sintaks berikut untuk mendaftarkan subscriber listener
```sql
BEGIN
    -- 1. Minta jembatan keluar mendengarkan out_q
    DBMS_AQADM.ADD_SUBSCRIBER(
        queue_name => 'dev.out_q', 
        subscriber => SYS.AQ$_AGENT('BRIDGE_OUT_SVC', NULL, 0)
    );

    DBMS_AQ.REGISTER(
        SYS.AQ$_REG_INFO_LIST(
            SYS.AQ$_REG_INFO(
                'dev.out_q:BRIDGE_OUT_SVC', 
                DBMS_AQ.NAMESPACE_AQ, 
                'plsql://dev.cb_bridge_out', 
                HEXTORAW('FF')
            )
        ), 
        1
    );

    -- 2. Tambahkan Subscriber khusus untuk Listener Utama
    DBMS_AQADM.ADD_SUBSCRIBER(
        queue_name => 'dev.in_q',
        subscriber => SYS.AQ$_AGENT('MAIN_LISTENER_SVC', NULL, 0)
    );

    DBMS_AQ.REGISTER(
        SYS.AQ$_REG_INFO_LIST(
            SYS.AQ$_REG_INFO(
                'dev.in_q:MAIN_LISTENER_SVC',
                DBMS_AQ.NAMESPACE_AQ,
                'plsql://dev.listener_pkg.cb_process_event',
                HEXTORAW('FF')
            )
        ),
        1
    );

    -- 3. Minta jembatan masuk mendengarkan kafka_in_q
    DBMS_AQADM.ADD_SUBSCRIBER(
        queue_name => 'dev.kafka_in_q',
        subscriber => SYS.AQ$_AGENT('BRIDGE_IN_SVC', NULL, 0)
    );

    DBMS_AQ.REGISTER(
        SYS.AQ$_REG_INFO_LIST(
            SYS.AQ$_REG_INFO(
                'dev.kafka_in_q:BRIDGE_IN_SVC',
                DBMS_AQ.NAMESPACE_AQ,
                'plsql://dev.cb_bridge_in',
                HEXTORAW('FF')
            )
        ),
        1
    );
END;
/

```

**NOTE** : 
1. Dengan menjalankan perintah di atas, mulai detik ini Oracle akan otomatis mengeksekusi cb_process_event di background (invisible) hanya jika ada pesan masuk ke in_q.
2. Apa Keuntungannya Secara Arsitektur?
  - Zero CPU Idle Cost: Saat tidak ada transaksi, listener_pkg tidak berjalan. Tidak memakan daya CPU dan tidak mengunci (lock) session database.
  - Otomatis Skalabel: Jika tiba-tiba ada 100 pesan masuk dari Kafka Connect di detik yang sama, Oracle akan secara otomatis menjalankan banyak instance (proses background EMNC) dari cb_process_event secara paralel untuk menyelesaikan queue tersebut seketika.

---

## 7. Menjembatani TxEventQ ⇄ Kafka dengan Kafka Connect

Berkat setup di Bagian 2, plugin dan `.jar` sudah otomatis terpasang. Anda cukup meluncurkan konfigurasi Source & Sink Connector lewat REST API-nya.

### 7.1. Konfigurasi Source Connector (TxEventQ → Kafka)

Simpan file di mesin host dengan nama `source-connector.json`. Perhatikan bahwa `confluent.topic.bootstrap.servers` kini mengarah ke `kafka:29092` (sesuai network internal Docker).

```json
{
  "name": "txeventq-source",
  "config": {
    "connector.class": "io.confluent.connect.jms.JmsSourceConnector",
    "kafka.topic": "transaksi.events",
    "jms.destination.name": "kafka_out_q",
    "jms.destination.type": "queue",
    "java.naming.factory.initial": "oracle.jms.AQjmsInitialContextFactory",
    "java.naming.provider.url": "jdbc:oracle:thin:@//manual-db:1521/FREEPDB1",
    "db_url": "jdbc:oracle:thin:@//manual-db:1521/FREEPDB1",
    "java.naming.security.principal": "dev",
    "java.naming.security.credentials": "<<isi dengan password user dev>>",
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
  --data @source-connector.json \
  http://localhost:8083/connectors

```

### 7.2. Konfigurasi Sink Connector (Kafka → TxEventQ)

Simpan sebagai `sink-connector.json`:

```json
{
  "name": "txeventq-sink",
  "config": {
    "connector.class": "io.confluent.connect.jms.JmsSinkConnector",
    "tasks.max": "1",
    "topics": "notifikasi.events",
    "java.naming.factory.initial": "oracle.jms.AQjmsInitialContextFactory",
    "java.naming.provider.url": "jdbc:oracle:thin:@//manual-db:1521/FREEPDB1",
    "db_url": "jdbc:oracle:thin:@//manual-db:1521/FREEPDB1",
    "java.naming.security.principal": "dev",
    "java.naming.security.credentials": "KatasandiKuat123!",
    "jndi.connection.factory": "javax.jms.XATopicConnectionFactory", 
    "jms.destination.type": "topic", 
    "jms.destination.name": "kafka_in_q",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "confluent.topic.bootstrap.servers": "kafka:29092",
    "confluent.topic.replication.factor": "1",
    "confluent.license": ""
  }
}

```

Muat via `curl`:

```bash
curl -X POST -H "Content-Type: application/json" \
  --data @sink-connector.json \
  http://localhost:8083/connectors

```

### 7.3. Cek Status Kedua Connector

```bash
curl -s localhost:8083/connectors/txeventq-source/status
curl -s localhost:8083/connectors/txeventq-sink/status

```

Pastikan `"state": "RUNNING"` di connector dan task-nya.

Apabila `"state": "FAILED"` maka terjadi kesalahan konfigurasi, hapus dan lakukan konfigurasi ulang
```bash
curl -X DELETE localhost:8083/connectors/txeventq-source
curl -X DELETE localhost:8083/connectors/txeventq-sink

```

---

## 8. Bun.js: Consumer + Producer

### 8.1. Setup Project

```bash
mkdir notif-service && cd notif-service
bun init -y
bun add kafkajs

```

### 8.2. Kode Lengkap (`index.ts`)

```typescript
import { Kafka } from "kafkajs";

const kafka = new Kafka({
  clientId: "notif-service",
  brokers: ["localhost:9092"], // Mengakses port mapping dari mesin host
});

const consumer = kafka.consumer({ groupId: "notif-consumer" });
const producer = kafka.producer();

async function run() {
  await producer.connect();
  await consumer.connect();
  await consumer.subscribe({ topic: "transaksi.events", fromBeginning: true });

  await consumer.run({
    eachMessage: async ({ message }) => {
      const wrapper = JSON.parse(message.value?.toString() ?? "{}");

      // dengan schemas.enable=false, teks JMS langsung di wrapper.text (bukan wrapper.payload.text)
      const rawText = wrapper.text;
      if (!rawText) {
        console.error("[notif] Pesan tanpa field text, dilewati:", wrapper);
        return;
      }
      const event = JSON.parse(rawText);

      console.log(`[notif] Transaksi diterima:`, event);
      console.log(`[notif] Mengirim notifikasi ke rekening ${event.noRekening}...`);

      await producer.send({
        topic: "notifikasi.events",
        messages: [{
          value: JSON.stringify({
            eventType: "NOTIFICATION_SENT",
            noRekening: event.noRekening,
          }),
        }],
      });

      console.log(`[notif] Event NOTIFICATION_SENT terkirim balik ke Kafka`);
    },
  });
}

run().catch(console.error);

```

Jalankan:

```bash
bun run index.ts

```

---

## 9. Uji Coba End-to-End

1. Jalankan `bun run index.ts` di terminal terpisah dan biarkan berjalan.

2. Di `sqlplus` sebagai user `dev`, jalankan:
```sql
EXEC producer_pkg.catat_transaksi('9988776655', 250000);

```

3. **Perhatikan terminal Bun.js** — dalam hitungan detik akan muncul log: `[notif] Transaksi diterima` dilanjutkan dengan `[notif] Event NOTIFICATION_SENT terkirim balik ke Kafka`.

4. Kembali ke `sqlplus` dan periksa status transaksi:
```sql
SELECT no_rekening, status FROM transaksi WHERE no_rekening = '9988776655';

```

**Hasilnya harus menunjukkan status = `'NOTIFIED'`**. Hal ini membuktikan siklus penuh (Oracle → Kafka Connect → Kafka → Bun.js → Kafka Connect → Oracle) telah berjalan sempurna.

---

## 10. Troubleshooting Umum

| Gejala | Kemungkinan penyebab |
| --- | --- |
| `ORA-24065` / Privilege error saat ENQUEUE/DEQUEUE | Grant di Bab 3.1 belum lengkap, atau script dijalankan dengan user yang salah. |
| Connector status `FAILED` (JNDI class not found) | File `.jar` Oracle tidak ada di path plugin. Cek ulang `Dockerfile` dan pastikan container dibangun dengan benar. |
| Connector error koneksi ke `manual-db` | Container `manual-db` belum digabungkan ke network `integration-net` (Kembali ke Langkah 2.2). |
| Bun.js tidak menerima pesan sama sekali | Source connector belum `RUNNING` atau topic belum terbuat otomatis di broker. Cek via `curl localhost:8083/connectors/txeventq-source/status`. |
| Status transaksi tidak pernah berubah jadi `NOTIFIED` | Callback Listener gagal tereksekusi. Pastikan antrean in_q di-set multiple_consumers => TRUE saat dibuat. Cek apakah Sink Connector mati, atau ada error parsing JSON di cb_process_event. Anda bisa memverifikasi apakah trigger background error dengan mengecek view DBA_AQ_NOTIFICATIONS atau alert log Oracle. |

---

## 11. Tracing Event

### 11.1. Melalui Oracle DB

Untuk memeriksa apakah Oracle TXEventQ telah berhasil meneruskan message ke Kafka Connect gunakan sintaks berikut
```sql
SELECT msg_id, enq_time, msg_state, consumer_name
FROM dev.AQ$OUT_Q;

```

Memahami kolom msg_state:
  - `READY`: Pesan baru saja dikirim oleh PL/SQL (Producer) dan sedang menunggu Kafka Connect (atau consumer lain) untuk mengambilnya.

  - `PROCESSED`: Pesan telah berhasil diambil dan diteruskan (dalam hal ini, Kafka Connect telah berhasil memindahkannya ke topik Kafka). Oracle menyimpan histori pesan yang sudah diproses selama beberapa waktu sebelum otomatis dihapus (tergantung konfigurasi retention antrean).

  - `EXPIRED`: Pesan tidak diambil dalam batas waktu tertentu (jika ada masa kedaluwarsa).

**Catatan:** Jika Anda menggunakan payload JSON murni, Anda juga bisa men-query kolom payload-nya. Namun, jika menggunakan JMS_TYPE, isi pesan (payload) disandikan sebagai tipe objek khusus.

### 11.2. Melalui Kafka

Jalankan perintah berikut untuk memeriksa message di kafka bahwa pesan telah diterima
```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic transaksi.events \
  --from-beginning

```

Jalankan perintah dibawah untuk melihat apakah pesan telah berhasil diteruskan
```bash
docker exec -it kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --group notif-consumer \
  --describe

```

Perintah tersebut akan menghasilkan tabel log. Perhatikan kolom LAG:
  - Jika LAG = 0, itu adalah bukti nyata bahwa Bun.js telah membaca semua pesan (termasuk JSON transaksi di atas) dan sudah selaras dengan data terbaru di Kafka.

  - Jika LAG > 0 (misal 5, 10), berarti pesan sudah ada di Kafka, tapi Bun.js belum sempat membacanya atau sedang mati (ada pesan yang belum diproses).