#!/bin/bash
set -e

trap "exit 1" SIGINT SIGTERM

IP=$(getent hosts server | awk '{ print $1 }')
echo "IP: $IP"

if test -z "${IP}"; then
    echo -e "\e[31mServer not found\e[0m"
    exit 1
else
    TIME_BEGIN=$(date +%s)
    MAX_FAILS=15
    SLEEP=10
    FAILS=0
    while true; do
        if ! nc -z -w 1 ${IP} 8080; then
            FAILS=$[FAILS + 1]
            if test ${FAILS} -gt ${MAX_FAILS}; then
                echo -e "Server boot failed (timeout)"
                exit 1
            fi
            TIME_PASSED="$[$(date +%s) - $TIME_BEGIN]"
            echo -e "Waiting for server boot... | ${TIME_PASSED}s (${FAILS}/${MAX_FAILS})"
            sleep ${SLEEP}
            continue
        fi
        echo -e "Server booted"
        break
    done
fi
sleep 1

PROJECT_URL="http://${IP}:8080/v1/projects"
echo "Project URL: ${PROJECT_URL}"

PROJECT_JSON=$(curl -sS "${PROJECT_URL}" --header "Content-Type:application/json")
echo "Project response:"
echo "${PROJECT_JSON}" | python -m json.tool

TOKEN_URL=$(echo "${PROJECT_JSON}" | python -c 'import json,sys; print json.load(sys.stdin)["data"][0]["links"]["registrationTokens"]')
echo "Token URL: ${TOKEN_URL}"

TOKEN_JSON=$(curl -sS -X POST "http://${IP}:8080/v1/projects/1a5/registrationTokens" --header "Content-Type:application/json")
echo "Token response:"
echo "${TOKEN_JSON}" | python -m json.tool

ACTIVATION_URL=$(echo "${TOKEN_JSON}" | python -c 'import json,sys; print json.load(sys.stdin)["actions"]["activate"]')
echo "Activation URL: ${ACTIVATION_URL}"

TIME_BEGIN=$(date +%s)
MAX_FAILS=15
SLEEP=1
FAILS=0
while true; do
    ACTIVATION_JSON=$(curl -sS "${ACTIVATION_URL}" --header "Content-Type:application/json")
    STATE=$(echo "${ACTIVATION_JSON}" | python -c 'import json,sys; print json.load(sys.stdin)["state"]')
    if test "active" != "${STATE}"; then
        FAILS=$[FAILS + 1]
        if test ${FAILS} -gt ${MAX_FAILS}; then
            echo -e "Host activation failed (timeout)"
            exit 1
        fi
        TIME_PASSED="$[$(date +%s) - $TIME_BEGIN]"
        echo -e "Waiting for host activation... | ${TIME_PASSED}s (${FAILS}/${MAX_FAILS})"
        sleep ${SLEEP}
        continue
    fi
    break
done

echo "Activation response:"
echo "${ACTIVATION_JSON}" | python -m json.tool

REGISTRATION_URL=$(echo "${ACTIVATION_JSON}" | python -c 'import json,sys; print json.load(sys.stdin)["registrationUrl"]')
echo "Registration URL: ${REGISTRATION_URL}"

bash /run.sh "${REGISTRATION_URL}"
