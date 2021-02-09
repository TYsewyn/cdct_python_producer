#!/bin/bash
set -x

CURRENT_DIR="$( pwd )"

export SC_CONTRACT_DOCKER_VERSION="${SC_CONTRACT_DOCKER_VERSION:-3.0.0-SNAPSHOT}"
export APP_IP="$( ./whats_my_ip.sh )"
export APP_PORT="${APP_PORT:-8000}"
export APPLICATION_BASE_URL="http://${APP_IP}:${APP_PORT}"
export PROJECT_GROUP="${PROJECT_GROUP:-group}"
export PROJECT_NAME="${PROJECT_NAME:-application}"
export PROJECT_VERSION="${PROJECT_VERSION:-0.0.1-SNAPSHOT}"
export PRODUCER_STUBS_CLASSIFIER="${PRODUCER_STUBS_CLASSIFIER:-stubs}"
export FAIL_ON_NO_CONTRACTS="${FAIL_ON_NO_CONTRACTS:-false}"
export CONTRACT_TEST="true"

yes | docker-compose kill || echo "Nothing running"
docker-compose up -d rabbitmq zookeeper
sleep 5
echo "Waiting for 5 seconds for brokers to boot properly"
docker-compose up -d kafka
sleep 1

echo "SC Contract Version [${SC_CONTRACT_DOCKER_VERSION}]"
echo "Application URL [${APPLICATION_BASE_URL}]"
echo "Project Version [${PROJECT_VERSION}]"

function runContractTests() {
    local messagingType="${1}"
    MESSAGING_TYPE="${messagingType}"
    docker run  --rm \
                --name verifier \
                -e "SPRING_RABBITMQ_ADDRESSES=${APP_IP}:5672" \
                -e "SPRING_KAFKA_BOOTSTRAP_SERVERS=${APP_IP}:9092" \
                -e "MESSAGING_TYPE=${messagingType}" \
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
                -v "${CURRENT_DIR}/build/spring-cloud-contract/output:/spring-cloud-contract-output/" \
                springcloud/spring-cloud-contract:"${SC_CONTRACT_DOCKER_VERSION}"
}

# export MESSAGING_TYPE="rabbit"
# gunicorn -w 4 --bind 0.0.0.0 main:app &
# APP_PID=$!
# runContractTests "rabbit"
# kill $APP_PID

export MESSAGING_TYPE="kafka"
gunicorn -w 4 --bind 0.0.0.0 main:app &
APP_PID=$!
runContractTests "kafka"
kill $APP_PID

yes | docker-compose kill