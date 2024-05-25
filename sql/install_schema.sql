CREATE TABLE IF NOT EXISTS ttd_wf_log (
  time BIGINT
  , script_name VARCHAR
  , func VARCHAR
  , event_code VARCHAR
  , event_sub_code VARCHAR
  , message VARCHAR
);
CREATE TABLE IF NOT EXISTS ttd_bucket_resp (
  time BIGINT
  , bucket_id VARCHAR
  , last_updated VARCHAR
);
CREATE TABLE IF NOT EXISTS ttd_uid2_ids (
  time BIGINT
  , src_db VARCHAR
  , src_tbl VARCHAR
  , src_id_col VARCHAR
  , src_id VARCHAR
  , src_col VARCHAR
  , src_typ VARCHAR
  , src_data VARCHAR
  , advertising_id VARCHAR
  , bucket_id VARCHAR
  , is_current INT
);
CREATE TABLE IF NOT EXISTS ttd_uid2_ids_archive (
  time BIGINT
  , src_db VARCHAR
  , src_tbl VARCHAR
  , src_id_col VARCHAR
  , src_id VARCHAR
  , src_col VARCHAR
  , src_typ VARCHAR
  , src_data VARCHAR
  , advertising_id VARCHAR
  , bucket_id VARCHAR
  , is_current INT
);
