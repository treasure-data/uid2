SELECT DISTINCT
  src_db
  , src_tbl
  , src_id_col
  , src_id
  , src_col
  , src_typ
  , src_data
  , advertising_id
  , ${td_uid2_env.db}.ttd_uid2_ids.bucket_id AS bucket_id
  , 0 AS is_current
FROM ${td_uid2_env.db}.ttd_uid2_ids
JOIN ${td_uid2_env.db}.ttd_bucket_resp ON ${td_uid2_env.db}.ttd_bucket_resp.bucket_id = ${td_uid2_env.db}.ttd_uid2_ids.bucket_id
;
