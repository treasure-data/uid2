SELECT DISTINCT
  src_db
  , src_tbl
  , src_id_col
  , src_id
  , src_col
  , src_typ
  , src_data
  , advertising_id
  , Uid.bucket_id AS bucket_id
  , 0 AS is_current
FROM ${td_uid2_env.db}.ttd_uid2_ids Uid
JOIN ${td_uid2_env.db}.ttd_bucket_resp Resp
 ON Resp.bucket_id = Uid.bucket_id
;
