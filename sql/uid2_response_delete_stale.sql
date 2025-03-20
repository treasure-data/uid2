-- Custom for YUM, Some PHone have starting with 0 , response is coming with Zero stripped, So have it back during comparison.
-- The below was specific to YUM but we have to follow similar to other clients, Check the length etc, 
-- For Phone so adjust the same accordingly If all phone numbers are 10 characters in the DB
-- But we received only 9 from Response due to 0 then Append Zero back! 
-- Amend the Phone logic accordingly, If the Original Phone has + then we may not need to do LPAD but simply use identifier but Suggest we amend it as needed
-- KV: 03/01/2025 
DELETE FROM ttd_uid2_ids
WHERE ttd_uid2_ids.src_data IN (SELECT CASE WHEN regexp_like(identifier, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' ) THEN identifier  -- Email
                  WHEN NOT regexp_like(identifier, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' ) AND TRIM(LPAD(identifier,10,'0')) = 10 THEN identifier  -- Phone
              END as Identifier FROM ttd_uid2_resp)
AND is_current=0
;
