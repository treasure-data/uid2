WITH tbl AS (
  SELECT ROW_NUMBER() OVER (ORDER BY src_data) AS rec_num, * 
  -- # Append the + sign to the Phone number if there is no Phone
  -- # NOTE This assumes phone is in the E64 format, Only thing we are adding is + and nothing more.
  --  FYI If the Phone number starts with 0 the Response Strips the 0 and sends the data back for our
  --  storage, So we have to append it back and then Join. 
  FROM (SELECT DISTINCT src_typ, CASE WHEN STRPOS(src_data,'+') > 0 THEN src_data ELSE '+' ||src_Data END  as src_data
          from  ${td_uid2_env.db}.ttd_uid2_ids
         WHERE is_current = 0
           AND src_typ = 'PHONE'
          --  AND bucket_id  = 'PENDING' -- Focus on these first then we can remove
       )X
)
-- Batch size 10,000
-- Changed to 15K 02/26
-- Changed to 25K 03/04
, grp AS (
  SELECT FLOOR(rec_num/25000)+1 AS rnk_num, * FROM tbl
  ORDER BY rec_num  
)

SELECT 'PHONE' AS src_typ, rnk_num, '{"phone":['||ARRAY_JOIN(ARRAY_DISTINCT(ARRAY_AGG('"'||src_data||'"')), ',', '')||'],"optout_check":1}' AS ttd_uid2_rqst
FROM grp
GROUP By rnk_num;
