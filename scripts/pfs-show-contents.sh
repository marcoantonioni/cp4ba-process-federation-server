#!/bin/bash

#set -euo pipefail


_me=$(basename "$0")

_TSK=false
_PRO=false
_LAU=false
_ALL=false

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#----------------------------------------------------
_SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${_SCRIPT_PATH}" ]; do
  _SCRIPT_DIR="$(cd -P "$(dirname "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  _SCRIPT_PATH="$(readlink "${_SCRIPT_PATH}")"
  [[ ${_SCRIPT_PATH} != /* ]] && _SCRIPT_PATH="${_SCRIPT_DIR}/${_SCRIPT_PATH}"
done
_SCRIPT_PATH="$(readlink -f "${_SCRIPT_PATH}")"
_SCRIPT_DIR="$(cd -P "$(dirname -- "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"

#----------------------------------------------------
if [[ ! -f "$_SCRIPT_DIR/../../cp4ba-logger/scripts/logger.sh" ]]; then
  echo "Error, log package not found !"
  echo "Clone it alongside with other cp4ba-..."
  echo "use the command: git clone https://github.com/marcoantonioni/cp4ba-logger"
  exit 1
fi
source $_SCRIPT_DIR/../../cp4ba-logger/scripts/logger.sh
if [[ -z "${CP4BA_LOGGING_ENABLED}" ]]; then 
  export CP4BA_LOGGING_ENABLED=true
fi
if [[ -z "${CP4BA_LOG_LEVEL}" ]]; then 
  export CP4BA_LOG_LEVEL="INFO"
fi
if [[ -z "${CP4BA_LOG_TO_CONSOLE}" ]]; then 
  export CP4BA_LOG_TO_CONSOLE=true
fi
if [[ -z "${CP4BA_LOG_TO_FILE}" ]]; then 
  export CP4BA_LOG_TO_FILE=false
fi
if [[ -z "${CP4BA_LOG_FILE}" ]]; then 
  export CP4BA_LOG_FILE=""
fi
if [[ -z "${CP4BA_LOG_MAX_SIZE}" ]]; then 
  export CP4BA_LOG_MAX_SIZE=$((10 * 1024 * 1024))
fi
if [[ -z "${CP4BA_LOG_BACKUP_COUNT}" ]]; then 
  export CP4BA_LOG_BACKUP_COUNT=5
fi

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
  exit 1
fi

if [[ ! -f "${_CFG}" ]]; then
  log_error "${_CLR_RED}Configuration file not found '${_CLR_YELLOW}${_CFG}${_CLR_RED}'${_CLR_NC}"
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
  _ROUTE_NAME="cp-console"
  if [ $(oc get routes -n $1 $_ROUTE_NAME --no-headers 2> /dev/null | wc -l) -lt 1 ]; then
    _ROUTE_NAME="platform-id-provider"
  fi

  # get admin URL
  CONSOLE_HOST="https://"$(oc get route -n $1 ${_ROUTE_NAME} -o jsonpath="{.spec.host}")
  PAK_HOST="https://"$(oc get route -n $1 cpd -o jsonpath="{.spec.host}")

  # get IAM access token
  IAM_ACCESS_TK=$(curl -sk -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
        -d "grant_type=password&username=${CP4BA_INST_PFS_ADMINUSER}&password=${PFS_ADMINPASSWORD}&scope=openid" \
        ${CONSOLE_HOST}/idprovider/v1/auth/identitytoken | jq -r .access_token)

  ZEN_TK=$(curl -sk "${PAK_HOST}/v1/preauth/validateAuth" -H "username:${CP4BA_INST_PFS_ADMINUSER}" -H "iam-token: ${IAM_ACCESS_TK}" | jq -r .accessToken)
}


#--------------------------------------------------------
showTasks () {
  log_info "${_CLR_YELLOW}--------------------------------------------------------------${_CLR_NC}"
  log_info "${_CLR_GREEN}Task list from Process Federation Server '${_CLR_YELLOW}${CP4BA_INST_PFS_NAME}${_CLR_GREEN}'${_CLR_NC}"
  _URL=${PFS_URL_REST}""
  _CRED="-u ${CP4BA_INST_PFS_ADMINUSER}:${PFS_ADMINPASSWORD}"
  RESPONSE=$(curl -sk -H "Authorization: Bearer ${ZEN_TK}" -H 'accept: application/json' -X GET "${PFS_URL_REST}/v1/tasks?interaction=all")
  _ITEMS=$(echo ${RESPONSE} | jq .items)
  if [[ ! -z "${_ITEMS}" && "${_ITEMS}" != "null" ]]; then
    echo "${_ITEMS}"
  fi
  _NUM_TASKS=$(echo $RESPONSE | jq .size)
  if [[ "${_NUM_TASKS}" = "null" ]]; then
    _NUM_TASKS="0"
  fi
  log_info "${_CLR_GREEN}Total tasks: '${_CLR_YELLOW}${_NUM_TASKS}${_CLR_GREEN}'${_CLR_NC}"

}

#--------------------------------------------------------
showProcesses () {
  log_info "${_CLR_YELLOW}--------------------------------------------------------------${_CLR_NC}"
  log_info "${_CLR_GREEN}Process list from Process Federation Server '${_CLR_YELLOW}${CP4BA_INST_PFS_NAME}${_CLR_GREEN}'${_CLR_NC}"
  _URL=${PFS_URL_REST}""
  _CRED="-u ${CP4BA_INST_PFS_ADMINUSER}:${PFS_ADMINPASSWORD}"
  RESPONSE=$(curl -sk -X 'PUT' ${PFS_URL_REST}/v1/instances \
      -H 'accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Bearer ${ZEN_TK}" \
      -d '{ "shared": true, "teams": [ ], "interaction": "all", "size": 25, "name": "MySavedSearch", "sort": [ { "field": "instanceDueDate", "order": "ASC" } ], "conditions": [ ], "fields": [ "instanceDueDate", "instanceName", "instanceId", "instanceStatus", "instanceProcessApp", "instanceSnapshot", "bpdName" ]}')
  _ITEMS=$(echo ${RESPONSE} | jq .items)
  if [[ ! -z "${_ITEMS}" && "${_ITEMS}" != "null" ]]; then
    echo "${_ITEMS}"
  fi
  _NUM_PROCESSES=$(echo $RESPONSE | jq .size)
  if [[ "${_NUM_PROCESSES}" = "null" ]]; then
    _NUM_PROCESSES="0"
  fi
  log_info "${_CLR_GREEN}Total processes: '${_CLR_YELLOW}${_NUM_PROCESSES}${_CLR_GREEN}'${_CLR_NC}"

}

#--------------------------------------------------------
showLaunchableEntities () {
  log_info "${_CLR_YELLOW}--------------------------------------------------------------${_CLR_NC}"
  log_info "${_CLR_GREEN}Launchable entities list from Process Federation Server '${_CLR_YELLOW}${CP4BA_INST_PFS_NAME}${_CLR_GREEN}'${_CLR_NC}"
  _URL=${PFS_URL_REST}""
  _CRED="-u ${CP4BA_INST_PFS_ADMINUSER}:${PFS_ADMINPASSWORD}"
  RESPONSE=$(curl -sk -H "Authorization: Bearer ${ZEN_TK}" -H 'accept: application/json'  -X GET "${PFS_URL_REST}/v1/launchableEntities")
  _ITEMS=$(echo ${RESPONSE} | jq .items)
  if [[ ! -z "${_ITEMS}" && "${_ITEMS}" != "null" ]]; then
    echo "${_ITEMS}"
  fi
  _NUM_ENTS=$(echo ${RESPONSE} | jq '.items | length')
  if [[ "${_NUM_ENTS}" = "null" ]]; then
    _NUM_ENTS="0"
  fi
  log_info "${_CLR_GREEN}Total launchable entities: '${_CLR_YELLOW}${_NUM_ENTS}${_CLR_GREEN}'${_CLR_NC}"

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

log_info "${_CLR_GREEN}****************************************"
log_info "${_CLR_GREEN}********** ${_CLR_YELLOW}PFS Show Contents${_CLR_GREEN} ***********"
log_info "${_CLR_GREEN}****************************************"
log_info "${_CLR_GREEN}Using config file: '${_CLR_YELLOW}${CONFIG_FILE}${_CLR_GREEN}'${_CLR_NC}"

source ${CONFIG_FILE}

verifyAllParams

if [[ "${_TSK}" = "false" ]] && [[ "${_PRO}" = "false" ]] && [[ "${_LAU}" = "false" ]] && [[ "${_ALL}" = "false" ]]; then
  log_error "${_CLR_RED}ERROR add one of the following params:"
  log_error "  -t [display task list]"
  log_error "  -p [display process list]"
  log_error "  -l [display launchable entities]"
  log_error "  -a [display all]${_CLR_NC}"
  exit 1
fi

getPfsAdminInfo
getTokens ${CP4BA_INST_PFS_NAMESPACE}

showContents

exit 0