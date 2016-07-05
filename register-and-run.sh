#!/bin/bash
set -e

trap "exit 1" SIGINT SIGTERM

if test -z "${RANCHER_AGENT_IMAGE}"; then
    echo -e "\033[1;31;47mThis script will be called from within the agent to register to the server. Please don't call it on your host machine.\033[0m"
    exit 1
fi

echo -e "\033[33mInspecting system\033[0m"
echo "Environment:"
printenv
echo "Hosts:"
getent hosts

echo -e "\033[33mDetecting host\033[0m"
#HOST_IP=$(getent hosts dockerhost | awk '{ print $1 }')
HOST_IP=$(netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}')
if test -z "${HOST_IP}"; then
    echo -e "\033[1;31;47mHost detection failed\033[0m"
    exit 1
fi
echo "Host IP address: ${HOST_IP}"

echo -e "\033[33mResolving server name\033[0m"
SERVER_IP=$(getent hosts rancher-server | awk '{ print $1 }')
if test -z "${SERVER_IP}"; then
    echo -e "\033[1;31;47mServer not found\033[0m"
    exit 1
fi
echo "Server IP address: ${SERVER_IP}"

echo -e "\033[33mWaiting for the server to boot\033[0m"
TIME_BEGIN=$(date +%s)
MAX_FAILS=120
SLEEP=1
FAILS=0
while true; do
    if ! nc -z -w 1 ${SERVER_IP} 8080; then
        FAILS=$[FAILS + 1]
        if test ${FAILS} -gt ${MAX_FAILS}; then
            echo -e "\033[1;31;47mServer boot took too long (timeout)\033[0m"
            exit 1
        fi
        TIME_PASSED="$[$(date +%s) - $TIME_BEGIN]"
        echo -e "\033[2m${TIME_PASSED}s\033[0m"
        sleep ${SLEEP}
        continue
    fi
    break
done
TIME_PASSED="$[$(date +%s) - $TIME_BEGIN]"
echo "Server ready after ${TIME_PASSED} seconds"

echo -e "\033[33mAsking the server API for the default Rancher project\033[0m"
PROJECT_URL="http://${HOST_IP}:8080/v1/projects"
echo "GET ${PROJECT_URL}"
PROJECT_JSON=$(curl -sS "${PROJECT_URL}" --header "Content-Type:application/json")
echo "Response:"
echo "${PROJECT_JSON}" | jq -C '.'

echo -e "\033[33mAsking the server API for a new registration token\033[0m"
TOKEN_URL=$(echo "${PROJECT_JSON}" | jq -r '.data[0].links.registrationTokens')
echo "POST ${TOKEN_URL}"
TOKEN_JSON=$(curl -sS -X POST "${TOKEN_URL}" --header "Content-Type:application/json")
echo "Response:"
echo "${TOKEN_JSON}" | jq -C '.'

echo -e "\033[33mAsking the server API to activate our token\033[0m"
ACTIVATION_URL=$(echo "${TOKEN_JSON}" | jq -r '.actions.activate')
echo "GET ${ACTIVATION_URL}"

TIME_BEGIN=$(date +%s)
MAX_FAILS=15
SLEEP=1
FAILS=0
while true; do
    ACTIVATION_JSON=$(curl -sS "${ACTIVATION_URL}" --header "Content-Type:application/json")
    STATE=$(echo "${ACTIVATION_JSON}" | jq -r '.state')
    if test "active" != "${STATE}"; then
        FAILS=$[FAILS + 1]
        if test ${FAILS} -gt ${MAX_FAILS}; then
            echo -e "\033[1;31;47mActivation failed (timeout)\033[0m"
            exit 1
        fi
        TIME_PASSED="$[$(date +%s) - $TIME_BEGIN]"
        echo -e "\033[2m${TIME_PASSED}s\033[0m"
        sleep ${SLEEP}
        continue
    fi
    break
done
echo "Response:"
echo "${ACTIVATION_JSON}" | jq -C '.'

echo -e "\033[33mGiving the registration url to the original run.sh script\033[0m"
REGISTRATION_URL=$(echo "${ACTIVATION_JSON}" | jq -r '.registrationUrl')
echo "/bin/bash /run.sh ${REGISTRATION_URL}"

bash /run.sh "${REGISTRATION_URL}"
