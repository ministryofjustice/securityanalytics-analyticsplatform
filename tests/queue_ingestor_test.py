from unittest.mock import MagicMock, patch, call
import pytest
import os
import itertools
from test_utils.test_utils import coroutine_of
from utils.time_utils import iso_date_string_from_timestamp
from utils.scan_results import ResultsContext
from utils.json_serialisation import dumps


TEST_ENV = {
    "REGION": "eu-west-wood",
    "STAGE": "door",
    "APP_NAME": "me-once",
    "TASK_NAME": "me-twice",
}
TEST_DIR = "./tests/results_parser/"

auth_mock = MagicMock()

with patch.dict(os.environ, TEST_ENV), \
     patch("boto3.client") as boto_client, \
        patch('aioboto3.client') as aioboto_client, \
        patch("utils.json_serialisation.stringify_all"), \
        patch("requests_aws4auth.AWS4Auth") as auth_constructor_mock:
    # ensure each client is a different mock
    boto_client.side_effect = (MagicMock() for _ in itertools.count())
    aioboto_client.side_effect = (MagicMock() for _ in itertools.count())
    auth_constructor_mock.return_value = auth_mock
    from queue_ingestor import queue_ingestor


@patch.dict(os.environ, TEST_ENV)
def ssm_return_vals():
    stage = os.environ["STAGE"]
    app_name = os.environ["APP_NAME"]
    ssm_prefix = f"/{app_name}/{stage}"
    return coroutine_of({
        "Parameters": [
            {"Name": f"{ssm_prefix}/analytics/elastic/es_endpoint/url", "Value": "elastic.url.com"}
        ]
    })


@patch("requests.post", return_value=MagicMock())
@pytest.mark.unit
def test_no_msg_attributes_simple_post(post_mock):
    queue_ingestor.ssm_client.get_parameters.return_value = ssm_return_vals()
    post_mock.return_value = response_mock = MagicMock()
    response_mock.json.return_value = {}

    test_event = {
        "Records": [
            {
                "body": dumps(
                    {
                        "Subject": "my_scan",
                        "Message": dumps({"some_field": "some_value"})
                    }
                )
            }
        ]
    }
    queue_ingestor.ingest(test_event, MagicMock())

    # in the simple (no msg attributes) mode, the subject is used as the index name and the whole message
    # is used as the data
    post_mock.assert_called_with(
        "https://elastic.url.com/my_scan/_doc",
        auth=auth_mock,
        data=dumps({"some_field": "some_value"}),
        headers={"content-type": "application/json"}
    )


@patch("requests.post", return_value=MagicMock())
@pytest.mark.unit
def test_exception_on_error_response(post_mock):
    queue_ingestor.ssm_client.get_parameters.return_value = ssm_return_vals()

    # mock response contains error
    post_mock.return_value = response_mock = MagicMock()
    response_mock.json.return_value = {"error": "I'm Aled Jones, it's all gone wrong for me"}
    response_mock.text = "Air"

    test_event = {
        "Records": [
            {
                "body": dumps(
                    {
                        "Subject": "my_scan",
                        "Message": dumps({"some_field": "some_value"})
                    }
                )
            }
        ]
    }

    with pytest.raises(RuntimeError, match="I'm Aled Jones, it's all gone wrong for me"):
        queue_ingestor.ingest(test_event, MagicMock())

    post_mock.assert_called_with(
        "https://elastic.url.com/my_scan/_doc",
        auth=auth_mock,
        data=dumps({"some_field": "some_value"}),
        headers={"content-type": "application/json"}
    )


@patch("requests.post", return_value=MagicMock())
@pytest.mark.unit
def test_exception_on_no_parent_key(post_mock):
    queue_ingestor.ssm_client.get_parameters.return_value = ssm_return_vals()

    # mock response contains error
    post_mock.return_value = response_mock = MagicMock()
    response_mock.json.return_value = {}
    response_mock.text = "Walk"

    test_event = {
        "Records": [
            {
                "body": dumps(
                    {
                        "Subject": "my_scan",
                        "Message": dumps({"some_field": "some_value"}),
                        "MessageAttributes": {
                            "TemporalKey": {
                                "Value": ResultsContext._hash_of(iso_date_string_from_timestamp(5)),
                                "DataType": "String"
                            }
                        }
                    }
                )
            }
        ]
    }

    with pytest.raises(ValueError, match="Analytics ingestor requires the ParentKey message attribute be present"):
        queue_ingestor.ingest(test_event, MagicMock())


SAMPLE_DOC_COLLECTION = dumps({
    "scan_id": "scan_2",
    "scan_start_time": iso_date_string_from_timestamp(4),
    "scan_end_time": iso_date_string_from_timestamp(5),
    "__docs": {
        "port_info": [
            {
                "NonTemporalKey": ResultsContext._hash_of({
                    "address": "123.456.123.456",
                    "port": "22"
                }),
                "Data": {
                    "address": "123.456.123.456",
                    "port": "22",
                    "open": "false",
                    "__ParentKey": ResultsContext._hash_of({"address": "123.456.123.456"}),
                }
            },
            {
                "NonTemporalKey": ResultsContext._hash_of({
                    "address": "123.456.123.456",
                    "port": "80"
                }),
                "Data": {
                    "address": "123.456.123.456",
                    "port": "80",
                    "open": "true",
                    "__ParentKey": ResultsContext._hash_of({"address": "123.456.123.456"}),
                }
            }
        ],
        "vuln_info": [
            {
                "NonTemporalKey": ResultsContext._hash_of({
                    "address": "123.456.123.456",
                    "port": "22",
                    "vulnerability": "cve4"
                }),
                "Data": {
                    "address": "123.456.123.456",
                    "port": "22",
                    "vulnerability": "cve4",
                    "severity": "5",
                    "__ParentKey": ResultsContext._hash_of({"address": "123.456.123.456"}),
                }
            },
            {
                "NonTemporalKey": ResultsContext._hash_of({
                    "address": "123.456.123.456",
                    "port": "22",
                    "vulnerability": "cve5"
                }),
                "Data": {
                    "address": "123.456.123.456",
                    "port": "22",
                    "vulnerability": "cve5",
                    "severity": "2",
                    "__ParentKey": ResultsContext._hash_of({"address": "123.456.123.456"}),
                }
            }
        ],
        "host_info": [
            {
                "NonTemporalKey": ResultsContext._hash_of({
                    "address": "123.456.123.456",
                }),
                "Data": {
                    "address": "123.456.123.456",
                    "uptime": "1234567",
                    "__ParentKey": ResultsContext._hash_of({"address": "123.456.123.456"}),
                }
            }
        ]
    }
})


# When the temporal key message attribute is present, the more complex approach is taken. The message is a collection
# of documents to add to different indexes. Entries are added to the indexes for the history index for each
# data source and document type. Old snapshots are deleted and new entries are added to the indexes for the
# snapshot index for each data source and document type.
@patch("requests.post", return_value=MagicMock())
@pytest.mark.unit
def test_history_and_snapshot_mode(post_mock):
    queue_ingestor.ssm_client.get_parameters.return_value = ssm_return_vals()
    post_mock.return_value = post_response_mock = MagicMock()
    post_response_mock.json.return_value = {}

    # Using as a sample event the expected output of the test_scan_results.py test
    test_event = {
        "Records": [
            {
                "body": dumps({
                    "Subject": "scan_name",
                    "Message": SAMPLE_DOC_COLLECTION,
                    "MessageAttributes": {
                        "ParentKey": {
                            "Value": ResultsContext._hash_of({"address": "123.456.123.456"}),
                            "DataType": "String"
                        },
                        "TemporalKey": {
                            "Value": ResultsContext._hash_of(iso_date_string_from_timestamp(5)),
                            "DataType": "String"
                        }
                    }
                })
            }
        ]
    }
    queue_ingestor.ingest(test_event, MagicMock())

    # There will be 2 port info, 2 vuln info, and one host info docs posted, for each of the history
    # and snapshot collections
    # There will be 3 delete old snapshot requests made, one for each doc_type, and each using the parent key
    assert post_mock.call_count == 10 + 3

    expected_deletes = {
        doc_type: call(
            f"https://elastic.url.com/scan_name:{doc_type}_snapshot:write/_doc/_delete_by_query?conflicts=proceed",
            auth=auth_mock,
            data=dumps({
                "query": {
                    "term": {
                        "__ParentKey": ResultsContext._hash_of({"address": "123.456.123.456"})
                    }
                }
            }),
            headers={"content-type": "application/json"}
        )
        for doc_type in ["port_info", "vuln_info", "host_info"]
    }

    temporal_key = ResultsContext._hash_of(iso_date_string_from_timestamp(5))
    parent_key = ResultsContext._hash_of({"address": "123.456.123.456"})

    # list of 3 deletes and then 10 updates, added in 5 pairs for history and snapshot
    assert post_mock.call_args_list == [
        # info for port 22 and 80
        expected_deletes["port_info"],
        *_expected_writes(
            "port_info",
            {'address': '123.456.123.456', 'port': '22'},
            auth_mock,
            temporal_key,
            {
                "scan_id": "scan_2",
                "scan_start_time": iso_date_string_from_timestamp(4),
                "scan_end_time": iso_date_string_from_timestamp(5),
                "address": "123.456.123.456",
                "port": "22",
                "open": "false",
                "__ParentKey": parent_key,
            }
        ),
        *_expected_writes(
            "port_info",
            {'address': '123.456.123.456', 'port': '80'},
            auth_mock,
            temporal_key,
            {
                "scan_id": "scan_2",
                "scan_start_time": iso_date_string_from_timestamp(4),
                "scan_end_time": iso_date_string_from_timestamp(5),
                "address": "123.456.123.456",
                "port": "80",
                "open": "true",
                "__ParentKey": parent_key,
            }
        ),
        # info for the two cves
        expected_deletes["vuln_info"],
        *_expected_writes(
            "vuln_info",
            {"address": "123.456.123.456", "port": "22", "vulnerability": "cve4"},
            auth_mock,
            temporal_key,
            {
                "scan_id": "scan_2",
                "scan_start_time": iso_date_string_from_timestamp(4),
                "scan_end_time": iso_date_string_from_timestamp(5),
                "address": "123.456.123.456",
                "port": "22",
                "vulnerability": "cve4",
                "severity": "5",
                "__ParentKey": parent_key,
            }
        ),
        *_expected_writes(
            "vuln_info",
            {"address": "123.456.123.456", "port": "22", "vulnerability": "cve5"},
            auth_mock,
            temporal_key,
            {
                "scan_id": "scan_2",
                "scan_start_time": iso_date_string_from_timestamp(4),
                "scan_end_time": iso_date_string_from_timestamp(5),
                "address": "123.456.123.456",
                "port": "22",
                "vulnerability": "cve5",
                "severity": "2",
                "__ParentKey": parent_key,
            }
        ),
        # Host info
        expected_deletes["host_info"],
        *_expected_writes(
            "host_info",
            {"address": "123.456.123.456"},
            auth_mock,
            temporal_key,
            {
                "scan_id": "scan_2",
                "scan_start_time": iso_date_string_from_timestamp(4),
                "scan_end_time": iso_date_string_from_timestamp(5),
                "address": "123.456.123.456",
                "uptime": "1234567",
                "__ParentKey": parent_key,
            }
        ),
    ]

# If a parent key is seen, but no temporal key, then the more advanced mode is used, i.e. a collection
# of docs is processed at the same time for the same parent id, but without the temporal key the history index
# is not written to, only the snapshot one. This is used where we only need the current data e.g. for the info
# about planned scan times for different ip addresses
@patch("requests.post", return_value=MagicMock())
@pytest.mark.unit
def test_snapshot_only_mode(post_mock):
    queue_ingestor.ssm_client.get_parameters.return_value = ssm_return_vals()
    post_mock.return_value = post_response_mock = MagicMock()
    post_response_mock.json.return_value = {}

    # Using as a sample event the expected output of the test_scan_results.py test
    test_event = {
        "Records": [
            {
                "body": dumps({
                    "Subject": "scan_name",
                    "Message": SAMPLE_DOC_COLLECTION,
                    "MessageAttributes": {
                        # N.B. No TemporalKey here
                        "ParentKey": {
                            "Value": ResultsContext._hash_of({"address": "123.456.123.456"}),
                            "DataType": "String"
                        }
                    }
                })
            }
        ]
    }
    queue_ingestor.ingest(test_event, MagicMock())

    # There will be 2 port info, 2 vuln info, and one host info docs posted, but only for the snapshot collections
    # There will be 3 delete old snapshot requests made, one for each doc_type, and each using the parent key
    assert post_mock.call_count == 5 + 3

    expected_deletes = {
        doc_type: call(
            f"https://elastic.url.com/scan_name:{doc_type}_snapshot:write/_doc/_delete_by_query?conflicts=proceed",
            auth=auth_mock,
            data=dumps({
                "query": {
                    "term": {
                        "__ParentKey": ResultsContext._hash_of({"address": "123.456.123.456"})
                    }
                }
            }),
            headers={"content-type": "application/json"}
        )
        for doc_type in ["port_info", "vuln_info", "host_info"]
    }

    parent_key = ResultsContext._hash_of({"address": "123.456.123.456"})

    assert post_mock.call_args_list == [
        # info for port 22 and 80
        expected_deletes["port_info"],
        _expected_snapshot_write(
            "port_info",
            {'address': '123.456.123.456', 'port': '22'},
            auth_mock,
            {
                "scan_id": "scan_2",
                "scan_start_time": iso_date_string_from_timestamp(4),
                "scan_end_time": iso_date_string_from_timestamp(5),
                "address": "123.456.123.456",
                "port": "22",
                "open": "false",
                "__ParentKey": parent_key,
            }
        ),
        _expected_snapshot_write(
            "port_info",
            {'address': '123.456.123.456', 'port': '80'},
            auth_mock,
            {
                "scan_id": "scan_2",
                "scan_start_time": iso_date_string_from_timestamp(4),
                "scan_end_time": iso_date_string_from_timestamp(5),
                "address": "123.456.123.456",
                "port": "80",
                "open": "true",
                "__ParentKey": parent_key,
            }
        ),
        # info for the two cves
        expected_deletes["vuln_info"],
        _expected_snapshot_write(
            "vuln_info",
            {"address": "123.456.123.456", "port": "22", "vulnerability": "cve4"},
            auth_mock,
            {
                "scan_id": "scan_2",
                "scan_start_time": iso_date_string_from_timestamp(4),
                "scan_end_time": iso_date_string_from_timestamp(5),
                "address": "123.456.123.456",
                "port": "22",
                "vulnerability": "cve4",
                "severity": "5",
                "__ParentKey": parent_key,
            }
        ),
        _expected_snapshot_write(
            "vuln_info",
            {"address": "123.456.123.456", "port": "22", "vulnerability": "cve5"},
            auth_mock,
            {
                "scan_id": "scan_2",
                "scan_start_time": iso_date_string_from_timestamp(4),
                "scan_end_time": iso_date_string_from_timestamp(5),
                "address": "123.456.123.456",
                "port": "22",
                "vulnerability": "cve5",
                "severity": "2",
                "__ParentKey": parent_key,
            }
        ),
        # Host info
        expected_deletes["host_info"],
        _expected_snapshot_write(
            "host_info",
            {"address": "123.456.123.456"},
            auth_mock,
            {
                "scan_id": "scan_2",
                "scan_start_time": iso_date_string_from_timestamp(4),
                "scan_end_time": iso_date_string_from_timestamp(5),
                "address": "123.456.123.456",
                "uptime": "1234567",
                "__ParentKey": parent_key,
            }
        ),
    ]


def _expected_writes(doc_type, non_temp_key, auth_mock, temporal_key, data):
    return [
        _expected_history_write(doc_type, non_temp_key, temporal_key, auth_mock, data),
        _expected_snapshot_write(doc_type, non_temp_key, auth_mock, data)
    ]


def _expected_snapshot_write(doc_type, non_temp_key, auth_mock, data):
    return call(
        f"https://elastic.url.com/scan_name:{doc_type}_snapshot:write/_doc/"
        # Doc id for history uses non temporal key only
        f"{ResultsContext._hash_of(non_temp_key)}",
        auth=auth_mock,
        data=dumps(data),
        headers={"content-type": "application/json"}
    )


def _expected_history_write(doc_type, non_temp_key, temporal_key, auth_mock, data):
    return call(
        f"https://elastic.url.com/scan_name:{doc_type}_history:write/_doc/"
        # Doc id for history uses combined hash of non temporal key with hash of temporal key
        f"{ResultsContext._hash_of(non_temp_key)}@{temporal_key}",
        auth=auth_mock,
        data=dumps(data),
        headers={"content-type": "application/json"}
    )


