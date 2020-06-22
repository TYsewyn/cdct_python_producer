#!/bin/bash
set -x

CURRENT_DIR="$( pwd )"

SC_CONTRACT_DOCKER_VERSION="${SC_CONTRACT_DOCKER_VERSION:-FOO}"
APP_IP="$( ./whats_my_ip.sh )"
APP_PORT="${APP_PORT:-8000}"
APPLICATION_BASE_URL="http://${APP_IP}:${APP_PORT}"
PROJECT_GROUP="${PROJECT_GROUP:-group}"
PROJECT_NAME="${PROJECT_NAME:-application}"
PROJECT_VERSION="${PROJECT_VERSION:-0.0.1-SNAPSHOT}"

# fixture setup
docker run --rm --name rabbit -d -p 5672:5672 -p 15672:15672 rabbitmq:3.6-management-alpine

echo "Waiting for 5 seconds for rabbit to boot properly"
sleep 5

# python3 test_hook.py &
# HOOK_ID=$!
gunicorn -w 4 --bind 0.0.0.0 main:app &
APP_PID=$!

echo "SC Contract Version [${SC_CONTRACT_DOCKER_VERSION}]"
echo "Application URL [${APPLICATION_BASE_URL}]"
echo "Project Version [${PROJECT_VERSION}]"

docker run  --rm \
--name verifier \
-e "SPRING_RABBITMQ_HOST=${APP_IP}" \
-e "VERIFIER_MESSAGING_TYPE=rabbit" \
-e "PUBLISH_STUBS_TO_SCM=false" \
-e "PUBLISH_ARTIFACTS=false" \
-e "APPLICATION_BASE_URL=${APPLICATION_BASE_URL}" \
-e "PROJECT_NAME=${PROJECT_NAME}" \
-e "PROJECT_GROUP=${PROJECT_GROUP}" \
-e "PROJECT_VERSION=${PROJECT_VERSION}" \
-e "EXTERNAL_CONTRACTS_REPO_WITH_BINARIES_URL=git://https://github.com/marcingrzejszczak/cdct_python_contracts.git" \
-e "EXTERNAL_CONTRACTS_ARTIFACT_ID=${PROJECT_NAME}" \
-e "EXTERNAL_CONTRACTS_GROUP_ID=${PROJECT_GROUP}" \
-e "EXTERNAL_CONTRACTS_VERSION=${PROJECT_VERSION}" \
-e "GENERATE_STUBS=true" \
-v "${CURRENT_DIR}/build/spring-cloud-contract/output:/spring-cloud-contract-output/" \
springcloud/spring-cloud-contract:"${SC_CONTRACT_DOCKER_VERSION}"

docker stop verifier
docker stop rabbit
kill $HOOK_ID
kill $APP_PID
