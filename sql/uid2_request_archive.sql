-- KV: 03/01/2025, Archiving the Request table as leaving the data in that table is causing slow down
--  and we are probably using same data, So to avoid old data picked up archive the data and clean up
-- Create table If not exitss
create table if not exists ${td_uid2_env.db}.ttd_uid2_rqst_archive
as
select * from ${td_uid2_env.db}.ttd_uid2_rqst;

-- Archvie the Response Too !!
-- Keep the Response clean moved from the Python to here
-- KV: 03/01/2025
create table if not exists ${td_uid2_env.db}.ttd_uid2_resp_archive
as
select * from ${td_uid2_env.db}.ttd_uid2_resp;

-- If tble exists Insert into the archive
INSERT INTO ${td_uid2_env.db}.ttd_uid2_rqst_archive
select * 
from ${td_uid2_env.db}.ttd_uid2_rqst;

INSERT INTO ${td_uid2_env.db}.ttd_uid2_resp_archive
select * 
from ${td_uid2_env.db}.ttd_uid2_resp;

-- Now clean the table, So we only process new data!
delete from ${td_uid2_env.db}.ttd_uid2_rqst where 1=1;

-- Delete from Response too
delete from ${td_uid2_env.db}.ttd_uid2_resp where 1=1;