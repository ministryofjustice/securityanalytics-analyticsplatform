[![CircleCI](https://circleci.com/gh/ministryofjustice/securityanalytics-analyticsplatform.svg?style=svg)](https://circleci.com/gh/ministryofjustice/securityanalytics-analyticsplatform)

# Analytics platform

This provisions an elastic search instance, adds permissions for it and kibana access via the Cognito user pools and sets up a queue and a lambda that takes json from the queue and puts it into elastic.

## Documents vs Document Collections

The Lambda that picks up events from the analytics platform's input queue will process it in one of two ways.

 - Single Document Mode
 - Document Collection Mode
 
 ### Single Document Mode
 
 If the message received has no MessageAttributes set, then it is interpreted as a single document. The lambda takes the whole message body to be the json payload, uses the subject as the name of the elastic index to insert into and submits the whole payload as a single document.
 
 ### Document Collection Mode
 
 This mode is activated if the following message attributes are observed:
 
 - ParentKey
 - TemporalKey
 
 If they are, then document collection mode is activated and the data ingestor will try and maintain two separate indexes for each document type in the collection, one containing the latest snapshot of data and the other containing the full history. Having separate history and snapshot indexes makes using Kibana much easier.
 
 The concept is that a single scanner performing a single scan might output a collection of documents relating to that scan e.g. an nmap scan will produce a host document, and several port documents.
 
 The ResultContext class should always be used to construct a document collection, trying to do so manually can be error prone. Each document has an associated NonTemporalKey.
 
 As an example, lets say we scan host 12.34.56.78 at 9am on 6th of March 2018, and discover 2 ports, the results Context will produce a document collection with structure that can be though of like this (the real structure is a bit different):
 
 ```
 {
    "ParentKey": "12.34.56.78",
    "TemporalKey": "2019-03-06T09:00:00Z",
    "Documents": [
        {
            "NonTemporalKey": {"host": "12.34.56.78"},
            "Data": {...}
        },
        {
            "NonTemporalKey": {"host": "12.34.56.78", "port": "443"},
            "Data": {...}
        },
        {
            "NonTemporalKey": {"host": "12.34.56.78", "port": "80"},
            "Data": {...}
        }
    ]
 }
 ```

Given such a document collection, the analytic ingestion lambda will do the following:

 1. It will find and delete any elastic documents previously written in the snapshot collection for the same ParentKey
     -  This ensures that if last time we scanned a host and it had 4 ports and this time it has 3, the snapshot collection will only contain 3 values.
 2. For each document in the collection it will write both a history and a snapshot version of it to elastic.
 
 ## DynamoDB to Elastic (diffing) sync
 
 The analytics project provides a module that can be used to synchronise any dynamodb table with elastic search. This is achieved using dynamodb streams. 
 
 Please note, there is a diffing sync version of this module. This allows you to add an ite,s added and items removed field to the elastic index that contains the difference between the current dynamodb data and the previous values. This is used to e.g. determine which new IP addresses resolve to a host since last scan.
 
 ## Dead Letter Reporter
 
 This lambda ensures that any dead letters that are reported are ingested as entries in elastic so that they can be observed in the dashboards.