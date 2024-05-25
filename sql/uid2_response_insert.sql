SELECT DISTINCT
  src_db
  , src_tbl
  , src_id_col
  , src_id
  , src_col
  , src_typ
  , src_data
  , ttd_uid2_resp.advertising_id AS advertising_id
  , ttd_uid2_resp.bucket_id AS bucket_id
  -- is_current will be 1 for current UID2 records in [ttd_uid2_ids] table
  --    and -1 for archive UID2 records in [ttd_uid2_ids_archive] table
  , ${is_current} AS is_current
FROM ${td_uid2_env.db}.ttd_uid2_ids
JOIN ttd_uid2_resp ON ttd_uid2_resp.identifier = ${td_uid2_env.db}.ttd_uid2_ids.src_data
;
