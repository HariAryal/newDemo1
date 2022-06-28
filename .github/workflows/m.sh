#!/bin/bash

  set -ex

  API_KEY='682487009884c26f'
  INTEGRATIONS_API_URL='https://3000-qualitiai-qualitiapi-to9p1rb8rrp.ws-us47.gitpod.io'
  PROJECT_ID='3'
  CLIENT_ID='3aa63dc213389ae3d11876c261ae95b8'
  SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
  API_URL='https://3000-qualitiai-qualitiapi-f7dl5n54uwn.ws-us47.gitpod.io/public/api'
  INTEGRATION_JWT_TOKEN='35620beeb7cefa07d29bd548a40b1abb65763474ff835d1cf77df9aee8522ea1e4f5654319540e0c2a87c3527b2688f3372149d551c28b977b236a7ab8d520faf42698f61c6240480a4dcec1f3c654dca362b0901e4597650636f62bf625acb9c3ad1329de3d8e4be21b8c932d491ca318c23a46961f9ae489751aaee27f339b6aa960b63cab1c8abb8b3fdbb7113bbc41fc35918cde90a136beef8424e1da3d5b4d31742fff048459c585cf47e2cfc8238d9e9d099f842fc4ff84bec02c491f2379464870692ebada351719f171ea16905926f0b738d19030719bfb479180ae4bc180879a47e909a8a281100f07931775da48c60b36d46ec103da210ff517f1b28bcbc023c9b2fdc1d872cb01aa6758|039e8e5797be302b191ba29c0404286d|8f9432f712350b5809530763f23d23f6'

  sudo apt-get update -y
  sudo apt-get install -y jq

  #Trigger test run
  TEST_RUN_ID="$( \
    curl -X POST -G ${INTEGRATIONS_API_URL}/integrations/github/${PROJECT_ID}/events \
      -d 'token='$INTEGRATION_JWT_TOKEN''\
      -d 'triggerType=Deploy'\
    | jq -r '.test_run_id')"

  AUTHORIZATION_TOKEN="$( \
    curl -X POST -G ${API_URL}/auth/token \
    -H 'x-api-key: '${API_KEY}'' \
    -H 'client_id: '${CLIENT_ID}'' \
    -H 'scopes: '${SCOPES}'' \
    | jq -r '.token')"

  # Wait until the test run has finished
  TOTAL_ITERATION=200
  I=1
  while : ; do
     RESULT="$( \
     curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
     -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
     -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].finished')"
    if [ "$RESULT" != null ]; then
      break;
    if [ "$I" -ge "$TOTAL_ITERATION" ]; then
      echo "Exit qualiti execution for taking too long time.";
      exit 1;
    fi
    fi
      sleep 15;
  done

  # # Once finished, verify the test result is created and that its passed
  TEST_RUN_RESULT="$( \
    curl -X GET ${API_URL}/test-results?test_run_id=${TEST_RUN_ID}\&project_id=${PROJECT_ID} \
      -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
      -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].status' \
  )"
  echo "Qualiti E2E Tests ${TEST_RUN_RESULT}"
  if [ "$TEST_RUN_RESULT" = "Passed" ]; then
    exit 0;
  fi
  exit 1;
  
