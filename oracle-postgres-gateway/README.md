## A. Install dan Konfigurasi Container PostgreSQL

### Tahap 1: Persiapan Jaringan Docker

Agar container Oracle Anda bisa berkomunikasi dengan container PostgreSQL menggunakan nama (hostname), kita perlu membuat *Docker Network* dan memasukkan container Oracle yang sudah ada ke dalam jaringan tersebut.

Jalankan di terminal Linux/Host Anda:

```bash
# 1. Buat jaringan docker baru bernama 'db-net'
docker network create integration-net

# 2. Hubungkan container Oracle Anda (manual-db) ke jaringan ini
docker network connect integration-net manual-db

```

### Tahap 2: Pembuatan Container PostgreSQL & Data Dummy

Sekarang kita buat database PostgreSQL, lalu masukkan tabel dan data sampel.

Jalankan perintah ini di terminal Host:

```bash
# 1. Jalankan container PostgreSQL
docker run -d \
  --name pg-db \
  --network integration-net \
  -e POSTGRES_USER=pguser \
  -e POSTGRES_PASSWORD='SandiPGKuat123!' \
  -e POSTGRES_DB=pgdatabase \
  -p 5432:5432 \
  postgres:15

# Tunggu sekitar 10 detik agar PostgreSQL selesai inisialisasi

```

Sekarang, masuk ke PostgreSQL untuk membuat tabel dan data dummy:

```bash
# 2. Masuk ke terminal interaktif PostgreSQL (psql)
docker exec -it pg-db psql -U pguser -d pgdatabase

```

Setelah masuk ke *prompt* `pgdatabase=#`, jalankan *script* SQL berikut:

```sql
CREATE TABLE karyawan (
    id SERIAL PRIMARY KEY,
    nama VARCHAR(50),
    departemen VARCHAR(50),
    gaji NUMERIC
);

INSERT INTO karyawan (nama, departemen, gaji) VALUES
('Budi', 'IT', 10000000),
('Siti', 'HR', 8000000),
('Andi', 'Finance', 9000000);

-- Cek apakah data sudah masuk
SELECT * FROM karyawan;

-- Ketik \q lalu tekan Enter untuk keluar dari PostgreSQL
\q

```

---

## B. Install Oracle Gateway

### Prerequest

Pull image Oracle Linux dan jalankan container dengan pemetaan port `1522` ke host (menghindari konflik dengan port 1521 database utama):

```bash
docker pull oraclelinux:9

docker run -d \
  --name oracle-gateway \
  -p 1522:1521 \
  --network integration-net \
  oraclelinux:9 \
  sleep infinity

```

### Langkah 1: Copy File Pre-install ke dalam Container (Terminal Host)

```bash
docker cp oracle-ai-database-preinstall-26ai-1.0-1.el9.x86_64.zip oracle-gateway:/tmp/

```

### Langkah 2: Ekstrak File Pre-install (Di dalam Container sebagai Root)

```bash
docker exec -u 0 -it oracle-gateway bash

cd /tmp
dnf install -y unzip
unzip oracle-ai-database-preinstall-26ai-1.0-1.el9.x86_64.zip

```

### Langkah 3: Install Paket RPM Pre-install (Di dalam Container sebagai Root)

```bash
dnf localinstall -y oracle-ai-database-preinstall-26ai-1.0-1.el9.x86_64.rpm

```

### Langkah 4: Salin File Installer Utama Oracle Gateway (Terminal Host)

```bash
docker cp V1054595-01.zip oracle-gateway:/tmp/

```

### Langkah 5: Siapkan Direktori & Ekstrak (Di dalam Container sebagai Root)

```bash
mkdir -p /u01/app/oracle/product/23/gateway
mkdir -p /tmp/gateway_installer
unzip /tmp/V1054595-01.zip -d /tmp/gateway_installer

chown -R oracle:oinstall /u01
chown -R oracle:oinstall /tmp/gateway_installer
chmod -R 775 /u01

```

### Langkah 6: Atur Limits Sesi & Jalankan Silent Installation (User Oracle)

*Catatan: Perbaikan `sed` dilakukan untuk mencegah error `su: cannot open session` di dalam Docker.*

```bash
# Atur limit sesi untuk user oracle
sed -i 's/oracle/#oracle/g' /etc/security/limits.d/*.conf

# Beralih ke user oracle
su - oracle

# Masuk ke direktori installer (perhatikan folder 'gateways')
cd /tmp/gateway_installer/gateways

# Jalankan instalasi senyap dengan menyertakan komponen hsodbc dan pengabaian kernel warning
./runInstaller -silent -waitforcompletion -ignorePrereqFailure \
  UNIX_GROUP_NAME="oinstall" \
  INVENTORY_LOCATION="/u01/app/oraInventory" \
  ORACLE_BASE="/u01/app/oracle" \
  ORACLE_HOME="/u01/app/oracle/product/23/gateway" \
  oracle.install.tg.customComponents="oracle.rdbms.hsodbc:23.0.0.0.0"

```

### Langkah 7: Jalankan Skrip Root untuk Finalisasi (Sebagai Root)

*Keluar dari user `oracle` dengan mengetik `exit`, lalu jalankan:*

```bash
/u01/app/oraInventory/orainstRoot.sh
/u01/app/oracle/product/23/gateway/root.sh

```

### Langkah 8: Bersihkan File Sementara (Sebagai Root)

```bash
rm -rf /tmp/V1054595-01.zip
rm -rf /tmp/gateway_installer

```

---

## C. Konfigurasi Koneksi ke PostgreSQL

### Tahap 1: Persiapan ODBC (Jalankan sebagai Root)

1. **Instal Driver ODBC PostgreSQL:**

```bash
dnf install -y unixODBC postgresql-odbc

```

2. **Konfigurasi File odbc.ini:**

```bash
cat <<EOF > /etc/odbc.ini
[PGDB]
Description = Koneksi ke PostgreSQL Docker
Driver      = PostgreSQL
Servername  = pg-db
Port        = 5432
Database    = pgdatabase
EOF

```

3. **Tes Koneksi ODBC:**

```bash
isql -v PGDB pguser 'SandiPGKuat123!'

```

*(Ketik `quit` lalu Enter jika sudah muncul pesan Connected).*

---

### Tahap 2: Konfigurasi Oracle Gateway (Jalankan sebagai User Oracle)

1. **Beralih ke User Oracle dan Set Environment:**

```bash
su - oracle
export ORACLE_HOME=/u01/app/oracle/product/23/gateway
export PATH=$ORACLE_HOME/bin:$PATH

```

2. **Buat File initPGDB.ora:**

```bash
cat <<EOF > $ORACLE_HOME/hs/admin/initPGDB.ora
HS_FDS_CONNECT_INFO = PGDB
HS_FDS_TRACE_LEVEL = OFF
HS_FDS_SHAREABLE_DIR = /usr/lib64/libodbc.so.2
HS_LANGUAGE = AMERICAN_AMERICA.AL32UTF8
EOF

```

3. **Konfigurasi listener.ora:**

```bash
cat <<EOF > $ORACLE_HOME/network/admin/listener.ora
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
    )
  )

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (SID_NAME = PGDB)
      (ORACLE_HOME = /u01/app/oracle/product/23/gateway)
      (PROGRAM = dg4odbc)
    )
  )
EOF

```

4. **Nyalakan Listener Gateway:**

```bash
lsnrctl start

```

*(Pastikan status menampilkan `Service "PGDB" has 1 instance(s)` saat dicek dengan `lsnrctl status`).*

---

## D. Membuat Databae Link

Sekarang, kita masuk ke tahap terakhir dan paling krusial: **Menghubungkan Database Oracle Utama (`manual-db`) ke Gateway ini**.

Karena container `manual-db` (Oracle 23ai utama Anda) berada di jaringan `integration-net` yang sama, ia bisa langsung menembus ke container `oracle-gateway` melalui hostname `oracle-gateway` di port internal `1521`.

Berikut adalah langkah-langkah di database Oracle utama Anda:

1. **Masuk ke Terminal Container Oracle Utama (manual-db):**
Buka tab terminal baru di komputer Host Anda, lalu masuk ke container `manual-db`:

```bash
docker exec -it manual-db bash

```


2. **Konfigurasi tnsnames.ora:** Menghubungkan TNS ke Gateway.
Buat atau tambahkan konfigurasi TNS di container Oracle utama agar mengenali nama `PGDB`. Jalankan perintah ini (sesuaikan path tnsnames.ora jika diperlukan, atau masukkan ke direktori network/admin Oracle utama):

```bash
cat <<EOF >> \$ORACLE_HOME/network/admin/tnsnames.ora
PGDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = oracle-gateway)(PORT = 1521))
    (CONNECT_DATA =
      (SID = PGDB)
    )
    (HS = OK)
  )
EOF

```


3. **Buat Database Link (DBLINK):** Masuk ke SQL*Plus sebagai pengguna berhak (misal: SYS / SYSTEM).
Masuk ke SQL*Plus:

```bash
sqlplus / as sysdba

```

Lalu buat Database Link dengan perintah SQL berikut (ubah kredensial `pguser` dan password jika diperlukan):

```sql
CREATE DATABASE LINK pg_link 
CONNECT TO "pguser" IDENTIFIED BY "SandiPGKuat123!" 
USING 'PGDB';

```


4. **Tes Kueri Silang (Cross-Database Query):**
Setelah DBLINK berhasil dibuat, Anda sekarang bisa langsung mengambil data dari tabel PostgreSQL langsung dari dalam Oracle! Coba jalankan kueri uji coba:

```sql
SELECT * FROM dual@pg_link;

```

*(Atau query tabel lain yang ada di dalam database `pgdatabase` PostgreSQL Anda).*


Dengan selesainya langkah ini, arsitektur integrasi antara Oracle Database 23ai, Oracle Gateway, dan PostgreSQL Anda sudah terbangun dengan sempurna!