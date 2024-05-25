DELETE FROM ttd_uid2_ids
WHERE ttd_uid2_ids.bucket_id IN (SELECT bucket_id FROM ttd_bucket_resp)
AND is_current=1
;
