import base64
import os
import sys
import inspect
import time
import json
import pandas as pd
from pandas import json_normalize

os.system(f"{sys.executable} -m pip install requests")
import requests
os.system(f"{sys.executable} -m pip install pycryptodomex")
from Cryptodome.Cipher import AES
os.system(f"{sys.executable} -m pip install -U pytd==1.0.0")
import pytd
import pytd.pandas_td as td


def post_uid2_requests(db, url, mod_div, mod_idx):
   logevt(db, 'UID2', 'INTL', f'{url}')
   client = pytd.Client(database=db)
   engine = td.create_engine(f"presto:{db}")
   # DELETE all the old TTD UID2 responses
   df_rqst = td.read_td_query("DELETE FROM ttd_uid2_resp WHERE 1=1", engine)
   # SELECT all the TTD UID2 requests matching mod params for this parallel operation
   qry = f"""
   WITH rqst_lst AS (SELECT * , ROW_NUMBER() OVER (ORDER BY src_typ, rnk_num) AS rec_num FROM ttd_uid2_rqst ORDER BY rnk_num)
   SELECT src_typ, rnk_num, ttd_uid2_rqst, time  --  , rec_num
   FROM rqst_lst WHERE (rec_num % {mod_div}) = {mod_idx} ORDER BY rec_num   
   """
   df_rqst = td.read_td_query(qry, engine)
   df_rqst = df_rqst.reset_index()
   logevt(db, 'RQST', 'LOAD', f"[{int(int(df_rqst.size) / 5)}] with MOD({mod_div}, {mod_idx})")
   for idx, row in df_rqst.iterrows():
      logevt(db, 'RQST', 'POST', f"{row['src_typ']} - {row['rnk_num']}")
      json_resp = ttd_post_rqst(url, row['ttd_uid2_rqst'])
      json_resp = json_resp['body']
      df_resp = json_normalize(json_resp['mapped'])
      logevt(db, 'RESP', 'RCV', f"{(int(int(df_resp.size) / 3))}")
      chunk_sz = 10000
      for sdx in range(0, int((int(df_resp.size) / 3)) + chunk_sz, chunk_sz):
         df_resp_chunk = df_resp.iloc[sdx:sdx+chunk_sz]
         logevt(db, 'RESP', 'CHUNK', f'{sdx} - {(int(int(df_resp_chunk.size) / 3))}')
         if (0 < df_resp_chunk.size):
            client.load_table_from_dataframe(df_resp_chunk, 'ttd_uid2_resp', writer='bulk_import', if_exists='append')
   logevt(db, 'UID2', 'FINL', f'{url}')


def post_bucket_requests(since_ts, db, url):
   logevt(db, 'BUCKETS', 'INTL', f'{url}')
   logevt(db, 'RQST', 'SINCE', f"{since_ts}")
   client = pytd.Client(database=db)
   engine = td.create_engine(f"presto:{db}")
   # Delete all the old expired buckets
   df_rqst = td.read_td_query("DELETE FROM ttd_bucket_resp WHERE 1=1", engine)
   # Request all rotated buckets since_ts
   timestamp = datetime.fromisoformat(since_ts.replace('Z', '+00:00'))
    
    dt_utc = timestamp.astimezone(timezone.utc)
    dt_utc_without_tz = dt_utc.replace(tzinfo=None)
    print(dt_utc_without_tz.isoformat())
    str_rqst = '{"since_timestamp": "'+dt_utc_without_tz.isoformat()+'"}'
   print(str_rqst) 
   json_resp = ttd_post_rqst(url, str_rqst)
   df_resp = json_normalize(json_resp['body'])
   logevt(db, 'RESP', 'RCV', f'{int(int(df_resp.size) / 2)}')
   chunk_sz = 50000
   for sdx in range(0, int((int(df_resp.size) / 2)) + chunk_sz, chunk_sz):
      df_resp_chunk = df_resp.iloc[sdx:sdx+chunk_sz]
      logevt(db, 'RESP', 'CHUNK', f'{sdx} - {int(int(df_resp_chunk.size) / 2)}')
      if (0 < df_resp_chunk.size):
        client.load_table_from_dataframe(df_resp_chunk, 'ttd_bucket_resp', writer='bulk_import', if_exists='append')
   logevt(db, 'BUCKETS', 'FINL', f'{url}')


# Not Used
def ttd_post_refresh():
   logevt(db, 'REFRESH', 'INTL', f'{url}')
   refresh_token=os.environ["TDD_REFRESH_TOKEN"]
   refresh_response_key=os.environ["TDD_REFRESH_RESPONSE_KEY"]
   secret = b64decode(refresh_response_key, "refresh_response_key")
   logevt(db, 'REFRESH', 'POST', f'{url}')
   http_response = requests.post(url, refresh_token)
   ttd_decrypt(http_response, secret, 1) # 1 - IS refresh token
   logevt(db, 'REFRESH', 'FINL', f'{url}')


def logevt(db, evtcd, evtsubcd, evtmsg):
   # CONTEXT
   filename = sys.argv[0]
   func = whosdaddy()
   # TO CONSOLE - TODO - Review
   # print(f'{filename} - {func} - {evtcd} - {evtsubcd} - {evtmsg}')   
   # TO DATABASE
   client = pytd.Client(database=db)
   df_evt = pd.DataFrame(data={'script_name':[filename], 'func':[func], 'event_code':[evtcd], 'event_sub_code':[evtsubcd], 'message':[evtmsg]})
   client.load_table_from_dataframe(df_evt, 'ttd_wf_log', writer='insert_into', if_exists='append')


def whoami():
    return inspect.stack()[1][3]


def whosdaddy():
    return inspect.stack()[2][3]


def b64decode(b64string, param):
   try:
      return base64.b64decode(b64string)
   except Exception:
       print(f"Error: <{param}> is not base64 encoded")
       sys.exit()


def ttd_post_rqst(url, payload):
   api_key=os.environ["TTD_API_KEY"]
   client_secret=os.environ["TTD_CLIENT_SECRET"]

   secret = b64decode(client_secret, "client_secret")

   iv = os.urandom(12)
   cipher = AES.new(secret, AES.MODE_GCM, nonce=iv)

   millisec = int(time.time() * 1000)
   request_nonce = os.urandom(8)

   # TODO - Reveiw Logging
   # print(f"\nRequest: Encrypting and sending to {url} : {payload}")
   # print(f"\nRequest: Encrypting and sending to {url}")

   body = bytearray(millisec.to_bytes(8, 'big'))
   body += bytearray(request_nonce)
   body += bytearray(bytes(payload, 'utf-8'))

   ciphertext, tag = cipher.encrypt_and_digest(body)

   envelope = bytearray(b'\x01')
   envelope += bytearray(iv)
   envelope += bytearray(ciphertext)
   envelope += bytearray(tag)
   base64Envelope = base64.b64encode(bytes(envelope)).decode()

   http_response = requests.post(url, base64Envelope, headers={"Authorization": "Bearer " + api_key})
   return ttd_decrypt(http_response, secret, 0) # 0 - NOT refresh token


def ttd_decrypt(http_response, secret, is_refresh):
   response = http_response.content
   if http_response.status_code != 200:
      resp_err = f'Response: Error HTTP status code [{http_response.status_code}]{(", check api_key." if http_response.status_code == 401 else "")}'
      print(resp_err)
      print(response.decode("utf-8"))
      raise Exception(resp_err)
   else:
      resp_bytes = base64.b64decode(response)
      iv = resp_bytes[:12]
      data = resp_bytes[12:len(resp_bytes) - 16]
      tag = resp_bytes[len(resp_bytes) - 16:]

      cipher = AES.new(secret, AES.MODE_GCM, nonce=iv)
      decrypted = cipher.decrypt_and_verify(data, tag)

      if is_refresh != 1:
         json_resp = json.loads(decrypted[16:].decode("utf-8"))
      else:
         json_resp = json.loads(decrypted.decode("utf-8"))

      # print("Response JSON:")
      # print(json.dumps(json_resp, indent=4))
      return json_resp


# 
# LOCAL - COMMAND LINE
#

# NOTE - local_db MUST Match with WF Configs
#
# python3 ./uid2_request_td.py UID2 10 0
#        Use args UID2 10 0 To emulate TTD Workflow with max parallel
#        Use args UID2 1 0 To SELECT all records
#
# python3 ./uid2_request_td.py BUCKETS {SINCE_TS}
#        Use args BUCKETS {SINCE_TS} to fetch stale salt buckets from TTD
#        {SINCE_TS} Must be in ISO-8601 format, e.g. 2023-12-19T00:00:00+0000, for example
#        python3 ./uid2_request_td.py BUCKETS 2023-12-19T00:00:00+0000
#        ** Use a REASONABLE SINCE_TS, ideally not more than one day,
#           TTD will return *hundreds of thousands* of expired salt buckets per day

if len(sys.argv) > 1:
   local_db='cc_ttd_uid2_001'
   if (sys.argv[1] == 'UID2'):
      local_url='https://operator-integ.uidapi.com/v2/identity/map'
      mod_div = sys.argv[2]
      mod_idx = sys.argv[3]
      print(f'LOCAL[{sys.argv[1]}] {local_db} , {local_url}')      
      post_uid2_requests(local_db, local_url, mod_div, mod_idx)
   if (sys.argv[1] == 'BUCKETS'):
      local_url='https://operator-integ.uidapi.com/v2/identity/buckets'
      since_ts = mod_div = sys.argv[2]
      print(f'LOCAL[{sys.argv[1]}], {since_ts} {local_db} , {local_url}')
      post_bucket_requests(since_ts, local_db, local_url)
