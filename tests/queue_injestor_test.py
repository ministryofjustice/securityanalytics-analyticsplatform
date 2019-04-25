from unittest import mock
import pytest
import os
import itertools
from test_utils.test_utils import resetting_mocks, serialise_mocks
from utils.json_serialisation import dumps
import datetime
import json
from requests import post
import time
import requests_mock
# TODO

TEST_ENV = {
    'REGION': 'eu-west-wood',
    'STAGE': 'door',
    'APP_NAME': 'me-once',
    'TASK_NAME': 'me-twice',
}


# def test_records(testdata):

#     # create a test record based on current time
#     # returns the record to push to the queue, the query for ES to get the record
#     # and the expected result from ES
#     time = datetime.datetime.now()
#     testdata['date'] = time
#     input_data = {'Records': [{'body': testdata}]}

#     query = ({
#         'query': {
#             'match': {
#                 'date': time.isoformat()
#             }
#         }
#     })
#     response_data = testdata
#     # the ES data will have the time serialised, so modify this in the expected result:
#     response_data['date'] = time.isoformat()
#     return input_data, query, response_data


# with mock.patch.dict(os.environ, TEST_ENV), \
#         mock.patch("boto3.client") as boto_client, \
#         mock.patch("utils.json_serialisation.stringify_all"):
#     # ensure each client is a different mock
#     boto_client.side_effect = (mock.MagicMock() for _ in itertools.count())
#     from queue_injestor import queue_injestor


# @mock.patch.dict(os.environ, TEST_ENV)
# def ssm_return_vals(using_private):
#     stage = os.environ["STAGE"]
#     app_name = os.environ["APP_NAME"]
#     task_name = os.environ["TASK_NAME"]
#     ssm_prefix = f"/{app_name}/{stage}"


# @pytest.mark.unit
# @serialise_mocks()
# @resetting_mocks(
#     queue_injestor.sqs_client,
#     queue_injestor.ssm_client

# )
# # def mock_requests_post(*args, **kwargs):
# #     return MockResponse(None, 404)
# # @mock.patch('requests.post', side_effect=mock_requests_post)
# @requests_mock.Mocker()
# def test_write_one(mocker):

#     # mocker.post('', text='200')
#     # print('--------------running a test')
#     # testdata = {'test_write_one': 'here is some data'}
#     # print(testdata)
#     # queue_injestor.es_url = 'test'
#     # inrec, query, outrec = test_records(testdata)

#     # queue_injestor.injest(inrec, mock.MagicMock())
#     # print('hello')


@pytest.mark.test1
def test_real_es_server():
    # # queue_injestor.ssm_client.get_parameters.return_value = ssm_return_vals(True)

    # inrec, query, outrec = test_records(
    #     {'this is another test': 'here is some data'})
    # print(f'sending {inrec}')
    # queue_injestor.ssm_client.get_parameters.return_value = ssm_return_vals(
    #     True)
    # queue_injestor.injest(inrec, 10)
    # # TODO: query elasticsearch for this record
    # # TODO: get URL of ES
    # # need to wait for ES to have taken in the record before fetching - 5 secs is more than enough
    # print('sleeping 5 seconds')
    # es_url = 'https://search-d-progers-sec-an-es-llytvwd7nqmfijkmjgvfx35lpu.eu-west-2.es.amazonaws.com/' + \
    #     endpoint+'/data/_search'

    # time.sleep(5)
    # print('requesting from ES')
    # # Elasticsearch may return more than one record if the search string is a close match
    # # so search for the record we just put in
    # # TODO: make an index in ES so that fields we search on have exact_match set
    # print(f'query: {query}')
    # headers = {'content-type': 'application/json'}
    # response = requests.get(es_url, data=dumps(query), headers=headers)
    # results = json.loads(response.text)
    # if 'hits' not in results.keys():
    #     pytest.fail('no hits returned from ES for this test')
    # if results['hits']['total'] < 1:
    #     pytest.fail('no hits returned from ES for this test')
    # matched = False
    # for hit in results['hits']['hits']:
    #     if hit['_source'] == outrec:
    #         matched = True
    #         break
    # if not matched:
    #     pytest.fail('no matching hits from the data returned ')
    # # print(f'results from ES:{results}')

    pass


@pytest.mark.integration
def test_nothing_else_either():
    pass


# test_write_one()
