 # Analytics Platform Design
 
 At present the analytics part of the security analytics platform is 100% based on elastic search and Kibana. Kibana is at present our only UI, it is constrained to a small subset of all of elastic's functionality, and is also pretty static, providing very few tools for dynamic drill downs to enable a user to dissect and investigate data.
 
 Despite these limitations, elastic itself provides a power user some scalable and powerful queries which will satisfy the majority of queries we might want. With a custom UI and not Kibana more use of these features could be made.
 
 The analytics platform, like the other projects in the security analytics platform, expose an input queue for data to be analysed and added to the data set. In future it is conceivable that based on the type of data received the analytics platform will route it to different data stores, which would enable us to add additional services for queries of that data.
 
 ## Athena
 
 One obvious service to add at some point to the platform would be to add Athena. This would enable searching across the raw data in the s3 buckets making the data lake.
 
 ## Nested objects
 
 Elastic has a fantastic capability called nested fields. This can be used to e.g. index all the data about ports in a host document. One document is stored, but you can query for ports, not just hosts. Unfortunately Kibana doesn't have good support for this. 
 
 Instead, to make it easier to make visualisations, we have chosen to have the e.g. nmap scanner report separately the row for the host and N rows for each port. 
 
 N.B. by splitting up the data like this we lose the context established by having one output event from a scanner from each input event.
 
 ## Snapshot and History
 
 The ingestion of data from the input queue into elastic is very simple, the input messages contain a json payload which becomes the entry in the elastic index.
 
 There is one additional feature that has been implemented, which complicates this, but simplifies a very common use case.
 
 Considering e.g. the nmap scanner, there are two types of views you might want. You may want to see the ports open on a specific host right now, for example, or you might want to see how the number of open ports on a host has changed over time.
 
 If the output message from another service entering this one contains message attributes with the names "NonTemporalKey" and "TemporalKey", then these are added as fields into the json message received. In addition the data is written into two elastic indexes. One index uses the temporal key as part of the key and the other doesn't. This leaves us with a history index where each new input is added to the collection which can be used for the time series style queries. The other index is a snapshot index and each update overwrites older data. This is useful for the current state of the world style queries.
 
 N.B. There is actually a problem with the current snapshot 
 
 https://dsdmoj.atlassian.net/browse/SA-155
 
 ### Re-ingestion
 
 Given the data lake approach to this platform, it is possible that we might add new analysis of existing results or similar. In this scenario we would want to re-ingest the raw data and update the data in elastic in-place, overwriting the older version of the same scan's results.
  