from dynamo_elastic_sync.dynamo_elastic_sync import dynamo_elastic_sync
import os

set_column = os.environ["SET_COLUMN_TO_DIFF"]


class DiffingDynamoDbSync(dynamo_elastic_sync.DynamoElasticSync):
    # This base class does no transformation, but others will
    def transform_record(self, new_record, old_record):
        transformed_record = {}
        transformed_record.update(new_record)
        transformed_record[f"{set_column}_added"] = new_record[set_column].difference(old_record[set_column])
        transformed_record[f"{set_column}_removed"] = old_record[set_column].difference(new_record[set_column])
        return transformed_record
