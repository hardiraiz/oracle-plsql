CREATE USER dev IDENTIFIED BY "GantiPasswordIni123";
GRANT CONNECT, RESOURCE, AQ_ADMINISTRATOR_ROLE TO dev;
GRANT EXECUTE ON DBMS_AQ TO dev;
GRANT EXECUTE ON DBMS_AQADM TO dev;
ALTER USER dev QUOTA UNLIMITED ON USERS;
/

EXEC producer_pkg.catat_transaksi('000001', 100001);
/

SELECT * FROM aq$out_q order by msg_id desc;
SELECT * FROM aq$kafka_out_q order by msg_id desc;
SELECT * FROM aq$kafka_in_q order by msg_id desc;
SELECT * FROM aq$in_q order by msg_id desc;
SELECT object_name, status FROM user_objects WHERE object_name = 'CB_BRIDGE_OUT';
/

select * from tb_failed_events where consumer_name = 'BRIDGE_IN_SVC' order by fail_id desc;
/

SELECT no_rekening, status FROM transaksi;
/

DELETE FROM transaksi;
COMMIT;
/