#!/bin/bash

#set -euo pipefail


_me=$(basename "$0")

_DETAILS=false

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#--------------------------------------------------------
# read command line params
while getopts c:d flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        d) _DETAILS=true;;
    esac
done


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

source $_SCRIPT_DIR/pfs-utils.sh

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file -d [optional, display full details]"
  exit 1
fi

if [[ ! -f "${_CFG}" ]]; then
  log_error "${_CLR_GREEN}Configuration file not found '${_CLR_YELLOW}${_CFG}${_CLR_GREEN}'${_CLR_NC}"
  exit 1
fi

export CONFIG_FILE=${_CFG}

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
        -d "grant_type=password&username=${PFS_ADMINUSER}&password=${PFS_ADMINPASSWORD}&scope=openid" \
        ${CONSOLE_HOST}/idprovider/v1/auth/identitytoken | jq -r .access_token)

  ZEN_TK=$(curl -sk "${PAK_HOST}/v1/preauth/validateAuth" -H "username:${PFS_ADMINUSER}" -H "iam-token: ${IAM_ACCESS_TK}" | jq -r .accessToken)

}


#--------------------------------------------------------
showFederatedServers () {
  _URL=${PFS_URL_REST}""
  _CRED="-u ${PFS_ADMINUSER}:${PFS_ADMINPASSWORD}"

  RESPONSE=$(curl -sk -H "Authorization: Bearer ${ZEN_TK}" -H 'accept: application/json'  -X GET "${PFS_URL_REST}/v1/systems")

  if [[ "${RESPONSE}" == *"error"* ]]; then
    log_error "ERROR $RESPONSE${_CLR_NC}"
  else
    # count only non-null systemID
    _NUM_SRVS=$(echo ${RESPONSE} | jq 'del(.systems[] | select(.systemID==null)) | .systems | length')

    log_info "Process Federation Server '${_CLR_YELLOW}${CP4BA_INST_PFS_NAME}${_CLR_GREEN}' has ${_CLR_YELLOW}${_NUM_SRVS}${_CLR_GREEN} federated servers ready${_CLR_NC}"
    if [[ "${_NUM_SRVS}" != "0" ]]; then
      if [[ "${_DETAILS}" = "true" ]]; then
        echo ${RESPONSE} | jq .
      else
        log_info " (use -d parameter for detailed output)"
        echo ${RESPONSE} | jq 'del(.systems[] | select(.systemID==null)) | .systems[] | .hostname' | sed 's/"//g'
      fi
    fi
  fi

  echo
}

#==========================================

log_info "${_CLR_GREEN}****************************************"
log_info "${_CLR_GREEN}****** ${_CLR_YELLOW}PFS Show Federated Servers${_CLR_GREEN} ******"
log_info "${_CLR_GREEN}****************************************"
log_info "${_CLR_GREEN}Using config file '${_CLR_YELLOW}${CONFIG_FILE}${_CLR_GREEN}'"

source ${CONFIG_FILE} 2> /dev/null 1> /dev/null 

verifyAllParams
getPfsAdminInfo
getTokens ${CP4BA_INST_PFS_NAMESPACE}
showFederatedServers
