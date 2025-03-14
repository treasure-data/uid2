WITH tbl AS (
  SELECT ROW_NUMBER() OVER (ORDER BY src_data) AS rec_num, * 
  FROM (SELECT DISTINCT src_typ, src_Data 
          from  ${td_uid2_env.db}.ttd_uid2_ids
         WHERE is_current = 0
           AND src_typ = 'EMAIL'
          --  AND bucket_id  = 'PENDING' -- Focus on these first then we can remove
           AND regexp_like(src_Data,'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')  -- Only Valid Emails!
       )X 
)
-- Batch size 10,000
-- Changed to 15K 02/26
-- Changed to 25K 03/04
-- Due to Size Restriction set to 20K
, grp AS (
  SELECT FLOOR(rec_num/20000)+1 AS rnk_num, * FROM tbl
)
-- SEND DISTINCT KV:02/05/2025
SELECT 'EMAIL' AS src_typ, rnk_num, '{"email":['||ARRAY_JOIN(ARRAY_DISTINCT(ARRAY_AGG('"'||src_data||'"')), ',', '')||'],"optout_check":1}' AS ttd_uid2_rqst
FROM grp
GROUP By rnk_num;
