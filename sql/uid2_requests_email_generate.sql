WITH tbl AS (
  SELECT ROW_NUMBER() OVER (ORDER BY src_data) AS rec_num, * 
  FROM ${td_uid2_env.db}.ttd_uid2_ids
  WHERE is_current = 0
  AND src_typ = 'EMAIL'
  -- LIMIT nnn -- FOR TESTING
)
-- Batch size 10,000
, grp AS (
  SELECT FLOOR(rec_num/10000)+1 AS rnk_num, * FROM tbl
  ORDER BY rec_num  
)

SELECT 'EMAIL' AS src_typ, rnk_num, '{"email":['||ARRAY_JOIN(ARRAY_AGG('"'||src_data||'"'), ',', '')||'],"optout_check":1}' AS ttd_uid2_rqst
FROM grp
GROUP By rnk_num
ORDER BY rnk_num
;
