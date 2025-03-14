-- Custom for YUM, Some PHone have starting with 0 , response is coming with Zero stripped, So have it back during comparison.
-- The below was specific to YUM but we have to follow similar to other clients, Check the length etc, 
-- For Phone so adjust the same accordingly If all phone numbers are 10 characters in the DB
-- But we received only 9 from Response due to 0 then Append Zero back! 
-- Amend the Phone logic accordingly, If the Original Phone has + then we may not need to do LPAD but simply use identifier but Suggest we amend it as needed
SELECT DISTINCT
  src_db
  , src_tbl
  , src_id_col
  , src_id
  , src_col
  , src_typ
  , src_data
  , Resp.advertising_id AS advertising_id
  , Resp.bucket_id AS bucket_id
  -- is_current will be 1 for current UID2 records in [ttd_uid2_ids] table
  --    and -1 for archive UID2 records in [ttd_uid2_ids_archive] table
  , ${is_current} AS is_current
FROM ${td_uid2_env.db}.ttd_uid2_ids Uid
JOIN (SELECT DISTINCT advertising_id, bucket_id , 
             CASE WHEN regexp_like(identifier, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' ) THEN identifier  -- Email
                  WHEN NOT regexp_like(identifier, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' ) AND TRIM(LPAD(identifier,10,'0')) = 10 THEN identifier  -- Phone
              END as Identifier 
        FROM ttd_uid2_resp) as Resp
   ON Resp.identifier = Uid.src_data
;
