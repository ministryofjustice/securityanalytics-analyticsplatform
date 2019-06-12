from dynamo_elastic_sync.dynamo_elastic_sync import dynamo_elastic_sync
import os

set_column = os.environ["SET_COLUMN_TO_DIFF"]


class DiffingDynamoDbSync(dynamo_elastic_sync.DynamoElasticSync):
    # This base class does no transformation, but others will
    def transform_record(self, new_record, old_record):
        transformed_record = {}
        transformed_record.update(new_record)
        new_set = new_record[set_column] if set_column in new_record else set()
        old_set = old_record[set_column] if set_column in old_record else set()
        transformed_record[f"{set_column}_added"] = new_set.difference(old_set)
        transformed_record[f"{set_column}_removed"] = old_set.difference(new_set)
        return transformed_record


# For developer test use only
if __name__ == "__main__":
    from dynamo_elastic_sync.diffing_sync import forward_record
    from aws_xray_sdk.core import xray_recorder
    from aws_xray_sdk.core.lambda_launcher import LambdaContext
    from dynamo_elastic_sync.dynamo_elastic_sync import sqs_client, ssm_client
    from asyncio import gather, run

    async def clean_clients():
        return await gather(
            ssm_client.close(),
            sqs_client.close()
        )

    try:
        xray_recorder.configure(context=LambdaContext())
        forward_record({
            "Records": [
                {
                    "dynamodb": {
                        "NewImage": {
                            "a": {'SS': ["foo", "bar"]}
                        },
                        "OldImage": {
                            "a": {'SS': ["bar"]}
                        }
                    }
                 }
            ]},
            type("Context", (), {"loop": None, "aws_request_id": 4})()
        )
    finally:
        run(clean_clients())
