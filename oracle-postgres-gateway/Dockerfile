# 1. Menggunakan Oracle Linux 9 sesuai dengan syarat file preinstall (.el9)
FROM oraclelinux:9

# 2. Install dependensi (unixODBC-devel diambil dari repo CodeReady Builder)
RUN dnf install -y unzip tar make gcc gcc-c++ unixODBC postgresql-odbc libnsl && \
    dnf install -y --enablerepo=ol9_codeready_builder unixODBC-devel && \
    dnf clean all

# 3. Copy file Preinstall RPM, Installer ZIP, dan Response File ke direktori sementara
COPY oracle-ai-database-preinstall-26ai-1.0-1.el9.x86_64.rpm /tmp/
COPY V1054595-01.zip /tmp/
COPY gateway.rsp /tmp/

# 4. Eksekusi Preinstall RPM
RUN dnf localinstall -y /tmp/oracle-ai-database-preinstall-26ai-1.0-1.el9.x86_64.rpm && \
    rm -f /tmp/oracle-ai-database-preinstall-*.rpm

# 5. Persiapkan direktori dengan hak akses user oracle yang baru saja dibuat
RUN mkdir -p /opt/oracle/product/23ai/gateway && \
    mkdir -p /opt/oracle/oraInventory && \
    chown -R oracle:oinstall /opt/oracle && \
    chmod -R 775 /opt/oracle

# 6. Pindah ke user oracle untuk melakukan instalasi
USER oracle
WORKDIR /tmp

# 7. Ekstrak dan Jalankan Installer (Silent Mode)
RUN unzip -q V1054595-01.zip -d /tmp/installer && \
    /tmp/installer/gateways/runInstaller -silent -noconfig -responseFile /tmp/gateway.rsp -ignorePrereqFailure -waitForCompletion || true

# 8. LANGKAH KRUSIAL: Force-Link dg4odbc
RUN export ORACLE_HOME=/opt/oracle/product/23ai/gateway && \
    export PATH=$ORACLE_HOME/bin:$PATH && \
    cd $ORACLE_HOME/hs/lib && make -f ins_hs.mk dg4odbc || true

# 9. Pindah ke root untuk menjalankan script pasca-instalasi dan bersih-bersih
USER root
RUN /opt/oracle/oraInventory/orainstRoot.sh || true && \
    /opt/oracle/product/23ai/gateway/root.sh || true && \
    rm -rf /tmp/installer /tmp/V1054595-01.zip /tmp/gateway.rsp

# 10. Finalisasi Image
USER oracle
WORKDIR /home/oracle
ENV ORACLE_HOME=/opt/oracle/product/23ai/gateway
ENV PATH=$ORACLE_HOME/bin:$PATH

EXPOSE 1521
CMD ["bash"]