[![CircleCI](https://circleci.com/gh/ministryofjustice/securityanalytics-analyticsplatform.svg?style=svg)](https://circleci.com/gh/ministryofjustice/securityanalytics-analyticsplatform)

# Analytics platform

This provisions an elastic search instance, adds permissions for it and kibana access via the cognitor user pools and sets up a queue and a lambda that takes json from the queue and puts it into elastic.
