#!/bin/bash

_me=$(basename "$0")

_TSK=false
_PRO=false
_LAU=false
_ALL=false

#--------------------------------------------------------
# read command line params
while getopts c:tpla flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        t) _TSK=true;;
        p) _PRO=true;;
        l) _LAU=true;;
        a) _ALL=true;;
    esac
done

if [[ "${_ALL}" = "true" ]]; then
  _TSK=true
  _PRO=true
  _LAU=true
fi

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file -t [display task list] -p [display process list] -l [display launchable entities] -a [display all]"
  exit
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "Configuration file not found: "${_CFG}
  exit 1
fi

export CONFIG_FILE=${_CFG}

_SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${_SCRIPT_PATH}" ]; do
  _SCRIPT_DIR="$(cd -P "$(dirname "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  _SCRIPT_PATH="$(readlink "${_SCRIPT_PATH}")"
  [[ ${_SCRIPT_PATH} != /* ]] && _SCRIPT_PATH="${_SCRIPT_DIR}/${_SCRIPT_PATH}"
done
_SCRIPT_PATH="$(readlink -f "${_SCRIPT_PATH}")"
_SCRIPT_DIR="$(cd -P "$(dirname -- "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"

source $_SCRIPT_DIR/pfs-utils.sh


#-------------------------------
# get common values
getTokens () {

  # get admin URL
  CONSOLE_HOST="https://"$(oc get route -n $1 cp-console -o jsonpath="{.spec.host}")
  PAK_HOST="https://"$(oc get route -n $1 cpd -o jsonpath="{.spec.host}")

  # get IAM access token
  IAM_ACCESS_TK=$(curl -sk -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
        -d "grant_type=password&username=${CP4BA_INST_PFS_ADMINUSER}&password=${PFS_ADMINPASSWORD}&scope=openid" \
        ${CONSOLE_HOST}/idprovider/v1/auth/identitytoken | jq -r .access_token)

  echo ""
  ZEN_TK=$(curl -sk "${PAK_HOST}/v1/preauth/validateAuth" -H "username:${CP4BA_INST_PFS_ADMINUSER}" -H "iam-token: ${IAM_ACCESS_TK}" | jq -r .accessToken)
}


#--------------------------------------------------------
showTasks () {
  echo "--------------------------------------------------------------"
  echo "Task list from Process Federation Server '${CP4BA_INST_PFS_NAME}'"
  _URL=${PFS_URL_REST}""
  _CRED="-u ${CP4BA_INST_PFS_ADMINUSER}:${PFS_ADMINPASSWORD}"
  RESPONSE=$(curl -sk -H "Authorization: Bearer ${ZEN_TK}" -H 'accept: application/json' -X GET "${PFS_URL_REST}/v1/tasks?interaction=all")
  echo ${RESPONSE} | jq .items
  _NUM_TASKS=$(echo $RESPONSE | jq .size)
  echo "Total tasks: "${_NUM_TASKS}

}

#--------------------------------------------------------
showProcesses () {
  echo "--------------------------------------------------------------"
  echo "Process list from Process Federation Server '${CP4BA_INST_PFS_NAME}'"
  _URL=${PFS_URL_REST}""
  _CRED="-u ${CP4BA_INST_PFS_ADMINUSER}:${PFS_ADMINPASSWORD}"
  RESPONSE=$(curl -sk -X 'PUT' ${PFS_URL_REST}/v1/instances \
      -H 'accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Bearer ${ZEN_TK}" \
      -d '{ "shared": true, "teams": [ ], "interaction": "all", "size": 25, "name": "MySavedSearch", "sort": [ { "field": "instanceDueDate", "order": "ASC" } ], "conditions": [ ], "fields": [ "instanceDueDate", "instanceName", "instanceId", "instanceStatus", "instanceProcessApp", "instanceSnapshot", "bpdName" ]}')
  echo ${RESPONSE} | jq .items
  _NUM_PROCESSES=$(echo $RESPONSE | jq .size)
  echo "Total processes: "${_NUM_PROCESSES}

}

#--------------------------------------------------------
showLaunchableEntities () {
  echo "--------------------------------------------------------------"
  echo "Launchable entities from Process Federation Server '${CP4BA_INST_PFS_NAME}'"
  _URL=${PFS_URL_REST}""
  _CRED="-u ${CP4BA_INST_PFS_ADMINUSER}:${PFS_ADMINPASSWORD}"
  RESPONSE=$(curl -sk -H "Authorization: Bearer ${ZEN_TK}" -H 'accept: application/json'  -X GET "${PFS_URL_REST}/v1/launchableEntities")
  echo ${RESPONSE} | jq .items
  _NUM_ENTS=$(echo ${RESPONSE} | jq '.items | length')
  echo "Total launchable entities: "${_NUM_ENTS}

}

#--------------------------------------------------------
showContents () {
  if [[ "${_TSK}" = "true" ]]; then
    showTasks
  fi
  if [[ "${_PRO}" = "true" ]]; then
    showProcesses
  fi
  if [[ "${_LAU}" = "true" ]]; then
    showLaunchableEntities
  fi
  echo ""
}

#==========================================
echo ""
echo "****************************************"
echo "****** PFS Show Contents ******"
echo "****************************************"
echo "Using config file: "${CONFIG_FILE}

source ${CONFIG_FILE}

verifyAllParams
getPfsAdminInfo
getTokens ${CP4BA_INST_PFS_NAMESPACE}

showContents

if [[ "${_TSK}" = "false" ]] && [[ "${_PRO}" = "false" ]] && [[ "${_LAU}" = "false" ]] && [[ "${_ALL}" = "false" ]]; then
  echo "ERROR: add one of the following params:"
  echo "  -t [display task list]"
  echo "  -p [display process list]"
  echo "  -l [display launchable entities]"
  echo "  -a [display all]"
  exit 1
fi