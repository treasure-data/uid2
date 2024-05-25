DELETE FROM ttd_uid2_ids
WHERE ttd_uid2_ids.src_data IN (SELECT identifier FROM ttd_uid2_resp)
AND is_current=0
;
