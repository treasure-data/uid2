SELECT TO_ISO8601(FROM_UNIXTIME(COALESCE(MIN(time), TD_TIME_PARSE(CAST(CURRENT_TIMESTAMP AS VARCHAR)))) - INTERVAL '1' DAY) AS since_timestamp
FROM ttd_bucket_resp
