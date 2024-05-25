# UID2 Converter

This workflow is designed to take DII (Directly Identifying Information) such as Emails and Phone Numbers and turn them into UID2s following the UID2 Framework. 

## High Level Workflow 
The following steps provide a high-level outline of the workflow intended for organizations that collect user data and push it to DSPs—for example, advertisers, identity graph providers, and third-party data providers.

The following steps are an example of how an advertiser can integrate with UID2:

1. Treasure Data sends a user’s directly identifying information (DII) to the UID2 Operator.

2. The UID2 Operator generates and returns a raw UID2 and salt bucket ID.

3. Treasure Data stores the UID2 and salt bucket ID and sends the UID2-based first-party and third-party audience segments to the DSP.

The following process occurs in the background:

1. Treasure Data monitors the UID2 Operator for rotated salt buckets and updates UID2s as needed.


## Concepts
### UID2 Definition

From TTD: https://unifiedid.com/docs/intro
>UID2 is a framework that enables deterministic identity for advertising opportunities on the open internet for many participants across the advertising ecosystem. The UID2 framework enables logged-in experiences from publisher websites, mobile apps, and Connected TV (CTV) apps to monetize through programmatic workflows. Built as an open-source, standalone solution with its own unique namespace, the framework offers the user transparency and privacy controls designed to meet local market requirements.

** SEE the UID2 Reference Documentation section at the end of this page for reference diagrams and links

### DII
DII is Directly Identifying Information, currently Email Addresses and Phone Numbers. 

### UID2
The unencrypted alphanumeric identifier created from a user’s email address. A UID2 is the actual value that DSPs, data providers, and advertisers will store, but this value should never enter the bid stream.

This value is created by a UID2 operator (see below) by adding a secret salt to the email address and then passing that value through a hashing function.

### UID2 Operator
Organizations that operate the infrastructure required to generate and manage UID2s and UID2 tokens.

Operators will receive salts and encryption keys from the UID2 Administrator. They will also operate an API that participants can call to receive UID2s or UID2 tokens.

### DII Normalization
DII (email address & phone numbers) will be normalized by the UID2 Operator. 

>If intending to use hashed email and phones, they must be normalized before hashing to the expected format per Normalization Standards. All DII will be mapped by a UID2 Service Operator as long as it is in the expected format as detailed below. Note that the UID2 Service Operator will map any email address or phone number as long as it is in the expected format, the email/phone does not need to be an actual live or working DII.

> ** This workflow has only been tested with unhashed emails/phones

> email addresses must be normalized per Email Normalization Standard.
phone numbers must be in E.164 format.
timestamps must be in ISO 8601 format.

### Salt Bucket Rotation
UID2 values are kept encrypted within UID2 Service Operator systems, and the Salt values are rotated on average once per year on a fairly even basis. This means that roughly 1/365th of UID2 Salt Buckets will get rotated per day. In other words, if a customer has 80M DII ↔︎ UID2 mappings, then on average 219,178 UID2 Salt Buckets will get rotated every day. When a Salt Bucket gets rotated, then the associated UID2 values are no longer valid and must be re-mapped.

The design and implementation of this workflow includes Salt Bucket Rotation functionality every time the WF runs:

The UID2 Mapping records include a column for the Salt Bucket ID of the corresponding UID2

The WF uses the Bucket API [/v2/identity/buckets] to check for all rotated Salt Buckets since the last WF run.

The WF re-maps all UID2 values associated with any stale Salt Buckets

## Background 

### Source DII Data Collection
The WF can map DII from any source database/tables in the TD instance, including Unification and/or Audience databases. The source tables are configured per the td_uid2_src_lst variable in the config/td_uid2_src_lst.yaml file, as many tables can be configured for collection as desired; details are listed in the [CONFIGURATION] section below.

New DII sources can be added at any time and will be included in the next WF run.

If an existing DII source is removed then it will no longer be collected going forward, but the existing DII ↔︎ UID2 mappings from that source will NOT be deleted by the WF. They can be manually selected and deleted per the ttd_uid2_ids.src_db and ttd_uid2_ids.src_tbl columns.

### Workflow Code
Please contact Treasure Data Solution Engineering for details.

## Workflow Installation
The UID2 Coverter Workflow is grouped into two main sections that need to be configured before running the workflow:

1. Secrets: Secret keys that need to be configured in the Project-level “Secrets” tab
2. Configuration: Two YML Files used to configure 1) top-level parameters and 2) TD Tables and columns containing DII for Export to UID2 Service Operator

### Secrets
| Secrets | README |
| ------ | ------ |
| pytd.apikey | TD Master API Key for pytd SDK to query & update tables. A  UID2 Specific service-account API Key with limited access to  UID2 related databases & tables is recommended (principle of least privilege). <br>*NOTE– This must be in pure TDI API Key format “nnnnn/xxxxxxxxxxxxxxxxxxxxxxxxx" (without quotes), NOT HTTP Authorization Header format “TD1 nnnnn/xxxxxxxxxxxxxxxxxxxxxxxxx"* |
| ttd.apikey | TTD API Key, provided by The Trade Desk as `{UID2 Integ Keys > api_key}` |
| ttd.clientsecret | TTD API Key, provided by The Trade Desk as `{UID2 Integ Keys > v2_secret}` |

### Configuration

#### Main WF Config `ttd_uid2.dig`  

```
_export: 
  # pytd SDK Config
  pytd:
    # TD API Server Endpoint
    apiserver: https://api.treasuredata.com/
  # API Config
  ttd:
    # Max parallel allowed by TTD is 10 (ten); probably will never change
    parallel_max: 10
    # TTD Environment, e.g. Integration, Production, etc.
    environment: operator-integ.uidapi.com
    # UID2 Mapping API Endpoint; probably will never change
    url_map: /v2/identity/map
    # Salt-Bucket Rotation API Endpoint; probably will never change
    url_buckets: /v2/identity/buckets
  # TTD/TD Integration Database
  td_uid2_env:
    # The TD Database to store TTD UID2 Mappings and WF Metadata
    #   Will get created if not exists
    #   All required tables will also get created if not exists
    #   *NO* Initial setup required, simply configure desired database name
    #     and the WF will install and configure itself accordingly
    db: MY_DATABASE_NAME
  # TD Source Tables for DII/UID2 Mapping
  #   Many source tables may be configured
  #   Configure in include file for managability
  #   Configuration design specifications listed below
  !include : config/td_uid2_src_lst.yaml
```
#### Source Tables `config/td_uid2_src_lst.yaml`
```
# List of TD Source Tables
#   3 Tables shown here for example, many tables may be included
#   Tables can be sourced from any TD database, 
#     including Unification and/or Audience databases
td_uid2_src_lst:
    # Database Name
  - src_db: stage_db
    # Table Name
    src_tbl: email_send
    # ID Column if available
    #   If no ID column, use the literal term "null" (w/o quotes)
    src_id_col: td_id
    # The name of the Source DII column, can be any name
    src_dii_col: email_address
    # The type of DII, either "EMAIL" or "PHONE"; Case-Sensitive, w/o quotes
    src_dii_typ: EMAIL

    # Database Name
  - src_db: unification_db
    # Table Name
    src_tbl: ecommerce_orders
    # ID Column if available
    #   If no ID column, use the literal term "null" (w/o quotes)
    src_id_col: td_id
    # The name of the Source DII column, can be any name
    src_dii_col: primary_email
    # The type of DII, either "EMAIL" or "PHONE"; Case-Sensitive, w/o quotes
    src_dii_typ: EMAIL

    # Database Name
  - src_db: audience_db
    # Table Name
    src_tbl: sms_contacts
    # ID Column if available
    #   If no ID column, use the literal term "null" (w/o quotes)
    src_id_col: td_id
    # The name of the Source DII column, can be any name
    src_dii_col: phone_number
    # The type of DII, either "EMAIL" or "PHONE"; Case-Sensitive, w/o quotes
    src_dii_typ: PHONE
```

## Output Tables

#### `ttd_uid2_ids` – Transactional Table – Main TTD UID2 Table
| **COLUMN**       | **TYPE** | **DESCRIPTION**|
| ---------------- | -------- | ----------------------------- |
| `time`           | INTEGER  | Unixtime of record `INSERT` |
| `src_db`         | VARCHAR  | The source database of the DII value |
| `src_tbl`        | VARCHAR  | The source table of the DII value |
| `src_id_col`     | VARCHAR  | The ID column for the source table of the DII value |
| `src_id`         | VARCHAR  | The ID value of the record in the source table of the DII value |
| `src_col`        | VARCHAR  | The Source column in the source table of the DII value |
| `src_typ`        | VARCHAR  | The type of DII, one of `{EMAIL, PHONE}`|
| `src_data`       | VARCHAR  | The source DII value |
| `advertising_id` | VARCHAR  | The UID2 value (Defined as `advertising_id` in Service Operator Service API's) |
| `bucket_id`      | VARCHAR  | The TTD Salt Bucket ID |
| `is_current`     | INTEGER  | Does the UID2 (`advertising_id` column) contain a current UID2 value from a non-expired Salt Bucket? <br> *   `0` (zero) – NO – Indicates that the `ttd_uid2_ids` record is either new, or that the Salt Bucket has expired. In either case, a new UID2 must be fetched from TTD <br> *   `1` (one) – YES – Indicates that the `ttd_uid2_ids` record has a current UID2 in the `advertising_id` column, a new UID2 does _NOT_ need to be fetched from TTD <br> The `is_current` state is managed during each WF run and should always have the value `1` (one) for all records at the completion of every successful WF run. If any records have the value `0` (zero) after the WF run has completed that means that something failed. The two primary causes of DII ↔︎ UID2 Mapping failure are: * <br>   The DII format is not correct and therefore cannot be mapped by the UID2 Service Operator. For example, the email `myname@mysite` is not a valid email format (the domain is missing TLD extension), and cannot be mapped by the Operator. Phone numbers must be in valid [E.164](https://en.wikipedia.org/wiki/E.164) format. Note that the Operator _will_ map any email address or phone number as long as it is in the expected format, the email/phone does not need to be an actual live or working DII. <br> * The TD UID2 Mapping Workflow failed for any reason |

#### `ttd_uid2_ids_archive` – Transactional Table – Main UID2 Table
**Same schema as ttd_uid2_ids table, except that the is_current will always have the value -1 to indicate archive records.

| **COLUMN**       | **TYPE** | **DESCRIPTION**    |
| ---------------- | -------- | -------------------------------------- |
| `time`           | INTEGER  | Unixtime of record `INSERT` |
| `src_db`         | VARCHAR  | The source database of the DII value  |
| `src_tbl`        | VARCHAR  | The source table of the DII value   |
| `src_id_col`     | VARCHAR  | The ID column for the source table of the DII value  |
| `src_id`         | VARCHAR  | The ID value of the record in the source table of the DII value |
| `src_col`        | VARCHAR  | The Source column in the source table of the DII value |
| `src_typ`        | VARCHAR  | The type of DII, one of `{EMAIL, PHONE}`  |
| `src_data`       | VARCHAR  | The source DII value   |
| `advertising_id` | VARCHAR  | The TTD UID2 value (Defined as `advertising_id` in Operator Service API's)     |
| `bucket_id`      | VARCHAR  | The Salt Bucket ID   |
| `is_current`     | INTEGER  | Always has the value `-1` (negative-one) to indicate archived records.   |

#### `ttd_bucket_resp` – Staging Table – For UID Salt Bucket Rotation API Responses
** Important – This table is also used to calculate the since_timestamp for the Salt Bucket rotation API. Even though this table is classified as a staging table, the records should NEVER be manually deleted as they are required for the subsequent WF run to accurately calculate the since_timestamp.

If the records in this table are ever accidentally deleted, then it is recommend to re-map UID2 for ALL records in the ttd_uid2_ids table.

| **COLUMN**     | **TYPE** | **DESCRIPTION**  |
| -------------- | -------- | ------------ |
| `time`   | INTEGER  | Unixtime of record `INSERT`  |
| `bucket_id`    | VARCHAR  | The UID Salt Bucket ID   |
| `last_updated` | VARCHAR  | Timestamp in ISO 8601 format of when this Salt Bucket was last updated by Operator (not used by this WF, for analysis purposes). |

#### `ttd_uid2_rqst` – Staging Table – For UID Map API Requests
| **COLUMN**      | **TYPE** | **DESCRIPTION** |
| --------------- | -------- |-------------- |
| `time`          | INTEGER  | Unixtime of record `INSERT` |
| `rnk_num`       | LONG     | The sequence number of this UID2 Service Operator API batch request |
| `ttd_uid2_rqst` | VARCHAR  | The actual JSON payload for the UID2 Service Operator API batch request. It is logical and valid JSON, stored as `VARCHAR` for simplicity and convenience. It is stored as plain-text unencrypted, the TD Python client script manages all security and encryption/decryption internally. |

#### `ttd_uid2_resp` – Staging Table – For UID2 Map API Responses
| **COLUMN**       | **TYPE** | **DESCRIPTION**                                                                                                   |
| ---------------- | -------- |------ |
| `time`           | INTEGER  | Unixtime of record `INSERT`  |
| `rnk_num`        | LONG     | The sequence number of this UID2 Service Operator API batch request (not used by this WF, for analysis purposes). |
| `identifier`     | VARCHAR  | The DII value, either an Email or Phone |
| `advertising_id` | VARCHAR  | The UID2 value (Defined as `advertising_id` in Operator Service |
| `bucket_id`      | VARCHAR  | The Salt Bucket ID   |

## Additional Resources

https://unifiedid.com/assets/images/UID2Workflows-fb37032af050f36f82905ce67aa18c62.jpg 
https://unifiedid.com/assets/images/advertiser-flow-mermaid-d3b67f69ab9afe0241a56fbd3bbf6389.png 

UID2 Mapping & Salt Bucket Rotation

- https://unifiedid.com/docs/intro
- https://unifiedid.com/docs/guides/advertiser-dataprovider-guide
- https://unifiedid.com/docs/endpoints/post-identity-map
- https://unifiedid.com/docs/getting-started/gs-normalization-encoding#phone-number-normalization
- https://unifiedid.com/docs/endpoints/post-identity-buckets

TTD Export Integration
- https://partner.thetradedesk.com/v3/portal/data/doc/post-data-advertiser-external
- https://partner.thetradedesk.com/v3/portal/data/doc/DataEnvironments
- https://partner.thetradedesk.com/v3/portal/data/doc/DataAuthentication

Treasure Data TTD Export Integration

- htps://docs.treasuredata.com/display/public/INT/The+Trade+Desk+Export+Integration
