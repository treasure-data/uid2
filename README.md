# UID2 Converter

This workflow is designed to take DII (Directly Identifying Information) such as Emails and Phone Numbers and turn them into UID2s following the UID2 Framework. 

### High Level Workflow 
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
The UID2 Service Operator TD WF is grouped into two main sections:


1. Secrets: Hidden keys that are stored in the Project-level “Secrets” tab
2. Configuration: Two YML Files used to configure 1) top-level parameters and 2) TD Tables for Export to UID2 Service Operator

| Secrets | README |
| ------ | ------ |
| pytd.apikey | TD Master API Key for pytd SDK to query & update tables. A  UID2 Specific service-account API Key with limited access to  UID2 related databases & tables is recommended (principle of least privilege). <br>*NOTE– This must be in pure TDI API Key format “nnnnn/xxxxxxxxxxxxxxxxxxxxxxxxx" (without quotes), NOT HTTP Authorization Header format “TD1 nnnnn/xxxxxxxxxxxxxxxxxxxxxxxxx"* |
| ttd.apikey | TTD API Key, provided by The Trade Desk as `{UID2 Integ Keys > api_key}` |
| ttd.clientsecret | TTD API Key, provided by The Trade Desk as `{UID2 Integ Keys > v2_secret}` |
