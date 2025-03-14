SELECT
  '${td_uid2_src.src_db}' AS src_db
  , '${td_uid2_src.src_tbl}' AS src_tbl
  , '${td_uid2_src.src_id_col}' AS src_id_col
  , CAST(${td_uid2_src.src_id_col} AS VARCHAR) AS src_id
  , '${td_uid2_src.src_dii_col}' AS src_col
  , '${td_uid2_src.src_dii_typ}' AS src_typ
  , ${td_uid2_src.src_dii_col} AS src_data
  , 'PENDING' AS advertising_id
  , 'PENDING' AS bucket_id
  , 0 AS is_current
FROM ${td_uid2_src.src_db}.${td_uid2_src.src_tbl} Src
WHERE NOT EXISTS (SELECT 1 FROM ${td_uid2_env.db}.ttd_uid2_ids  Tgt 
                   WHERE Tgt.src_data = Src.${td_uid2_src.src_dii_col})
AND ${td_uid2_src.src_dii_col} is not null
;
