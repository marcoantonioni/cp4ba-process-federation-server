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

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file -d [optional, display full details]"
  exit 1
fi

if [[ ! -f "${_CFG}" ]]; then
  echo -e "${_CLR_GREEN}Configuration file not found '${_CLR_YELLOW}${_CFG}${_CLR_GREEN}'${_CLR_NC}"
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
    # echo "Using console route name [${_ROUTE_NAME}]"
  fi

  # get admin URL
  CONSOLE_HOST="https://"$(oc get route -n $1 ${_ROUTE_NAME} -o jsonpath="{.spec.host}")
  PAK_HOST="https://"$(oc get route -n $1 cpd -o jsonpath="{.spec.host}")

  # get IAM access token
  IAM_ACCESS_TK=$(curl -sk -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
        -d "grant_type=password&username=${PFS_ADMINUSER}&password=${PFS_ADMINPASSWORD}&scope=openid" \
        ${CONSOLE_HOST}/idprovider/v1/auth/identitytoken | jq -r .access_token)

  echo ""
  ZEN_TK=$(curl -sk "${PAK_HOST}/v1/preauth/validateAuth" -H "username:${PFS_ADMINUSER}" -H "iam-token: ${IAM_ACCESS_TK}" | jq -r .accessToken)

}


#--------------------------------------------------------
showFederatedServers () {
  _URL=${PFS_URL_REST}""
  _CRED="-u ${PFS_ADMINUSER}:${PFS_ADMINPASSWORD}"

  RESPONSE=$(curl -sk -H "Authorization: Bearer ${ZEN_TK}" -H 'accept: application/json'  -X GET "${PFS_URL_REST}/v1/systems")

  if [[ "${RESPONSE}" == *"error"* ]]; then
    echo -e "${_CLR_RED}ERROR: $RESPONSE${_CLR_NC}"
  else
    # count only non-null systemID
    _NUM_SRVS=$(echo ${RESPONSE} | jq 'del(.systems[] | select(.systemID==null)) | .systems | length')

    echo -n -e "Process Federation Server '${_CLR_YELLOW}${CP4BA_INST_PFS_NAME}${_CLR_GREEN}' has ${_CLR_YELLOW}${_NUM_SRVS}${_CLR_GREEN} federated servers ready${_CLR_NC}"
    if [[ "${_NUM_SRVS}" != "0" ]]; then
      if [[ "${_DETAILS}" = "true" ]]; then
        echo ""
        echo ""
        echo ${RESPONSE} | jq .
      else
        echo " (use -d parameter for detailed output)"
        echo ""
        echo ${RESPONSE} | jq 'del(.systems[] | select(.systemID==null)) | .systems[] | .hostname' | sed 's/"//g'
      fi
    fi
  fi

  echo
}

#==========================================
echo ""
echo -e "${_CLR_GREEN}****************************************"
echo -e "${_CLR_GREEN}****** ${_CLR_YELLOW}PFS Show Federated Servers${_CLR_GREEN} ******"
echo -e "${_CLR_GREEN}****************************************"
echo -e "${_CLR_GREEN}Using config file '${_CLR_YELLOW}${CONFIG_FILE}${_CLR_GREEN}'"

source ${CONFIG_FILE} 2> /dev/null 1> /dev/null 

verifyAllParams
getPfsAdminInfo
getTokens ${CP4BA_INST_PFS_NAMESPACE}
showFederatedServers