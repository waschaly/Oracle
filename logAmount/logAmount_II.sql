SELECT 
	trunc(first_time) DAY,
	count(*) NB_SWITCHS,
	trunc(count(*)*log_size/1024) TOTAL_SIZE_KB,
	to_char(count(*)/24,'9999.9') AVG_SWITCHS_PER_HOUR
FROM
	v$loghist,
	(
	SELECT 
		avg(bytes) log_size 
	FROM v$log
	) 
GROUP BY 
	trunc(first_time),log_size
ORDER BY 1 DESC
/
