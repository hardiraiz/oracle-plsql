# Studi Kasus: Oracle TxEventQ + Kafka Connect + Bun.js

Panduan ini memakai pendekatan **native** karena container yang sudah Anda jalankan (Kafka, Kafka Connect, Zookeeper, dan Oracle Database Free 23ai) sudah lengkap untuk ini. Bedanya dengan pendekatan sebelumnya (outbox table + `APEX_WEB_SERVICE`): kali ini **PL/SQL tidak perlu tahu apa-apa soal HTTP atau Kafka** — Oracle cukup menulis/membaca pesan ke "kotak surat" internal (TxEventQ), dan **Kafka Connect** yang bertugas menjembatani kotak surat itu ke topic Kafka sungguhan, otomatis dan dua arah.

NOTE: Jalankan sintaks dibawah untuk running ulang container secara bertahap setelah selesai install dan konfigurasi
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

Kita akan membangun infrastruktur dari nol dan menghubungkannya ke `manual-db` dan `manual-ords` yang sudah ada. 

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
docker network connect integration-net manual-ords

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
CREATE USER dev IDENTIFIED BY "GantiPasswordIni123";
GRANT CONNECT, RESOURCE, AQ_ADMINISTRATOR_ROLE TO dev;
GRANT EXECUTE ON DBMS_AQ TO dev;
GRANT EXECUTE ON DBMS_AQADM TO dev;
ALTER USER dev QUOTA UNLIMITED ON USERS;

```

### 3.2. Buat Dua TxEventQ (Antrian Keluar dan Masuk)

Login sebagai `dev`, lalu eksekusi script ini:

```sql
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

```

Berikut sintaks untuk membatalkan sintaks diatas
```sql
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

```

### 4.3. Uji Coba Manual

```sql
EXEC dev.producer_pkg.catat_transaksi('1234567890', 500000);
SELECT * FROM AQ$OUT_Q; -- Memastikan pesan masuk antrian

```

---

## 5. Bagian Listener — PL/SQL Dequeue dari TxEventQ

Supaya Oracle senantiasa "mendengarkan" pesan baru yang masuk, kita membuat `LOOP` yang berjalan terus-menerus menggunakan `DBMS_SCHEDULER`.

### 5.1. Package Listener

```sql
CREATE OR REPLACE PACKAGE dev.listener_pkg AS
    PROCEDURE process_event(p_payload IN VARCHAR2);
    PROCEDURE listen_loop;
END listener_pkg;
/

CREATE OR REPLACE PACKAGE BODY dev.listener_pkg AS

    PROCEDURE process_event(p_payload IN VARCHAR2) IS
        v_no_rekening VARCHAR2(20);
    BEGIN
        -- Parsing JSON sederhana
        v_no_rekening := JSON_VALUE(p_payload, '$.noRekening');

        UPDATE transaksi
        SET status = 'NOTIFIED'
        WHERE no_rekening = v_no_rekening
          AND status = 'CREATED';

        COMMIT;
    END process_event;

    PROCEDURE listen_loop IS
        dequeue_options    DBMS_AQ.DEQUEUE_OPTIONS_T;
        message_properties DBMS_AQ.MESSAGE_PROPERTIES_T;
        message_handle     RAW(16);
        msg                SYS.AQ$_JMS_TEXT_MESSAGE;
        v_text             VARCHAR2(32767);
    BEGIN
        dequeue_options.wait := DBMS_AQ.FOREVER; -- Tunggu pesan baru selamanya

        LOOP
            DBMS_AQ.DEQUEUE(
                queue_name         => 'dev.in_q',
                dequeue_options    => dequeue_options,
                message_properties => message_properties,
                payload            => msg,
                msgid              => message_handle
            );

            msg.get_text(v_text);

            BEGIN
                process_event(v_text);
            EXCEPTION
                WHEN OTHERS THEN
                    ROLLBACK;
                    NULL; -- Log error di sini jika di environment produksi
            END;
        END LOOP;
    END listen_loop;

END listener_pkg;
/

```

### 5.2. Jalankan Sebagai Job Background

Berikan akses user *dev* melalui sintaks berikut
```sql
-- 1. Hak akses utama untuk membuat dan mengelola Scheduler Job di skema dev
GRANT CREATE JOB TO dev;

-- 2. Hak akses eksekusi package DBMS_SCHEDULER 
-- (Secara default Oracle memberikan ini ke PUBLIC, namun perlu di-grant jika dibatasi)
GRANT EXECUTE ON DBMS_SCHEDULER TO dev;

```

Setelah memberikan akses jalankan sintaks berikut
```sql
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

```

*(Statusnya akan menunjukkan `RUNNING` terus-menerus karena ini job listener: `SELECT job_name, state FROM user_scheduler_jobs;`)*

---

## 6. Menjembatani TxEventQ ⇄ Kafka dengan Kafka Connect

Berkat setup di Bagian 2, plugin dan `.jar` sudah otomatis terpasang. Anda cukup meluncurkan konfigurasi Source & Sink Connector lewat REST API-nya.

### 6.1. Konfigurasi Source Connector (TxEventQ → Kafka)

Simpan file di mesin host dengan nama `source-connector.json`. Perhatikan bahwa `confluent.topic.bootstrap.servers` kini mengarah ke `kafka:29092` (sesuai network internal Docker).

```json
{
  "name": "txeventq-source",
  "config": {
    "connector.class": "io.confluent.connect.jms.JmsSourceConnector",
    "kafka.topic": "transaksi.events",
    "jms.destination.name": "out_q",
    "jms.destination.type": "queue",
    "java.naming.factory.initial": "oracle.jms.AQjmsInitialContextFactory",
    "java.naming.provider.url": "jdbc:oracle:thin:@//manual-db:1521/FREEPDB1",
    "db_url": "jdbc:oracle:thin:@//manual-db:1521/FREEPDB1",
    "java.naming.security.principal": "dev",
    "java.naming.security.credentials": "KatasandiKuat123!",
    "confluent.license": "",
    "confluent.topic.bootstrap.servers": "kafka:29092",
    "confluent.topic.replication.factor": "1"
  }
}

```

Muat via `curl`:

```bash
curl -X POST -H "Content-Type: application/json" \
  --data @source-connector.json \
  http://localhost:8083/connectors

```

### 6.2. Konfigurasi Sink Connector (Kafka → TxEventQ)

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
    "jndi.connection.factory": "javax.jms.XAQueueConnectionFactory",
    "jms.destination.type": "queue",
    "jms.destination.name": "in_q",
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

### 6.3. Cek Status Kedua Connector

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

## 7. Bun.js: Consumer + Producer

### 7.1. Setup Project

```bash
mkdir notif-service && cd notif-service
bun init -y
bun add kafkajs

```

### 7.2. Kode Lengkap (`index.ts`)

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
      const event = JSON.parse(message.value?.toString() ?? "{}");
      console.log(`[notif] Transaksi diterima:`, event);

      // Simulasi pengiriman notifikasi ke nasabah
      console.log(`[notif] Mengirim notifikasi ke rekening ${event.noRekening}...`);

      // Publish event balasan (Produce)
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

## 8. Uji Coba End-to-End

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


**Hasilnya harus menunjukkan status = `'NOTIFIED'**`. Hal ini membuktikan siklus penuh (Oracle → Kafka Connect → Kafka → Bun.js → Kafka Connect → Oracle) telah berjalan sempurna.

---

## 9. Troubleshooting Umum

| Gejala | Kemungkinan penyebab |
| --- | --- |
| `ORA-24065` / Privilege error saat ENQUEUE/DEQUEUE | Grant di Bab 3.1 belum lengkap, atau script dijalankan dengan user yang salah. |
| Connector status `FAILED` (JNDI class not found) | File `.jar` Oracle tidak ada di path plugin. Cek ulang `Dockerfile` dan pastikan container dibangun dengan benar. |
| Connector error koneksi ke `manual-db` | Container `manual-db` belum digabungkan ke network `integration-net` (Kembali ke Langkah 2.2). |
| Bun.js tidak menerima pesan sama sekali | Source connector belum `RUNNING` atau topic belum terbuat otomatis di broker. Cek via `curl localhost:8083/connectors/txeventq-source/status`. |
| Status transaksi tidak pernah berubah jadi `NOTIFIED` | Job listener (`listener_job`) belum `enabled`, Sink Connector mati, atau ada error parsing JSON di `process_event`. Cek `user_scheduler_job_run_details`. |

---

## 10. Perbandingan Singkat dengan Pendekatan Sebelumnya

| Aspek | Outbox + REST Proxy (Panduan Pertama) | TxEventQ + Kafka Connect (Panduan Ini) |
| --- | --- | --- |
| **Kompleksitas PL/SQL** | Perlu tabel outbox, ACL, `APEX_WEB_SERVICE` | Cukup API native `DBMS_AQ.ENQUEUE`/`DEQUEUE` |
| **Kompatibilitas Oracle** | Berjalan di versi lama (12c ke atas) | Butuh TxEventQ (21c+), sangat optimal di 23ai |
| **Komponen Tambahan** | Hanya butuh job `DBMS_SCHEDULER` | Butuh Kafka Connect + JMS Connector |
| **Paling Cocok Untuk** | Environment legacy / arsitektur lama | Arsitektur modern yang sudah berbasis event (seperti setup Docker Anda saat ini) |