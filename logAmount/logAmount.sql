set verify OFF
set echo OFF
set termout ON
set feedback OFF
set lines 73
set pages 100

column day format a10 heading 'Tag'
column log_amount heading 'Log amount|per Day (MB)'

break on report
compute max of log_amount on report
ttitle left 'Redo Amount per Day' skip 2

SELECT 
	TO_CHAR(a.day, 'DD.MM.YYYY') DAY, a.log_amount
FROM
	(
		SELECT 
			TRUNC(completion_time, 'DD') DAY,
			ROUND(SUM(blocks * block_size / 1024 / 1024))
			log_amount
		FROM 
			v$archived_log
		WHERE
			completion_time > SYSDATE - 40
		GROUP BY 
			TRUNC(completion_time, 'DD')
	)	a
ORDER BY a.DAY;

ttitle off
