SET @DATABASE_NAME = 'PAMS';
SELECT  CONCAT('ALTER TABLE `', table_name, '` ENGINE=NDBCLUSTER;') AS sql_statements
FROM    information_schema.tables AS tb
WHERE   table_schema = @DATABASE_NAME
AND     `ENGINE` = 'InnoDB'
AND     `TABLE_TYPE` = 'BASE TABLE'
ORDER BY table_name DESC;

SET @DATABASE_NAME = 'Audit_Trail_Daily';
SELECT  CONCAT('DROP TABLE `', table_name, '`;') AS sql_statements
FROM    information_schema.tables AS tb
WHERE   table_schema = @DATABASE_NAME
AND     `TABLE_TYPE` = 'BASE TABLE'
AND		`TABLE_NAME` like '%2015-10%'
ORDER BY table_name DESC;

select * from information_schema.tables;

select * from information_schema.key_column_usage;

SELECT concat('ALTER TABLE ', TABLE_NAME, ' DROP FOREIGN KEY ', CONSTRAINT_NAME, ';') FROM information_schema.key_column_usage WHERE CONSTRAINT_SCHEMA = 'PAMS' AND referenced_table_name IS NOT NULL;

SHOW STATUS WHERE `variable_name` = 'Threads_connected';

select concat('KILL ',id,';') from information_schema.processlist where Command='Sleep';

SELECT B.table_name FROM (SELECT * FROM PAMS.AUDIT_TRAIL_NEW) A
INNER JOIN (SELECT table_name FROM information_schema.tables
WHERE table_schema='Audit_Trail_Daily') B ON A = B.table_name;

SELECT * FROM PAMS.AUDIT_TRAIL_NEW AS PATN
INNER JOIN (SELECT table_name FROM information_schema.tables
WHERE table_schema='Audit_Trail_Daily') AS ATD ON PATN.MSISDN
WHERE EVENT_DATE='2015-10-12';

SELECT @create := CONCAT('CREATE TABLE `', 'AUDIT_TRAIL', '_' ,SUBDATE(CURDATE(),1), '` LIKE PAMS.AUDIT_TRAIL_NEW');
PREPARE STMT FROM @create;
EXECUTE STMT;

SELECT @table := CONCAT('INSERT INTO `', 'AUDIT_TRAIL', '_' ,SUBDATE(CURDATE(),1), '` SELECT * FROM PAMS.AUDIT_TRAIL_NEW 
	WHERE EVENT_DATE = SUBDATE(CURDATE(),1)');
PREPARE STMT FROM @table;
EXECUTE STMT;

DELETE FROM PAMS.AUDIT_TRAIL_NEW
WHERE EVENT_DATE = current_date() - 1;
