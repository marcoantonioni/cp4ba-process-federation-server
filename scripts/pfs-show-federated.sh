#!/bin/bash

_me=$(basename "$0")

_DETAILS=false

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
  echo "usage: $_me -c path-of-config-file -d [optional, display full details] "
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
showFederatedServers () {
  _URL=${PFS_URL_REST}""
  _CRED="-u ${CP4BA_INST_PFS_ADMINUSER}:${PFS_ADMINPASSWORD}"
  RESPONSE=$(curl -sk -H "Authorization: Bearer ${ZEN_TK}" -H 'accept: application/json'  -X GET "${PFS_URL_REST}/v1/systems")

  if [[ "${RESPONSE}" == *"Error"* ]]; then
    echo "ERROR: "$RESPONSE
  else
    # count only non-null systemID
    _NUM_SRVS=$(echo ${RESPONSE} | jq 'del(.systems[] | select(.systemID==null)) | .systems | length')

    echo -n "Process Federation Server '${CP4BA_INST_PFS_NAME}' has "${_NUM_SRVS}" federated servers ready"
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
echo "****************************************"
echo "****** PFS Show Federated Servers ******"
echo "****************************************"
echo "Using config file: "${CONFIG_FILE}

source ${CONFIG_FILE}

verifyAllParams
getPfsAdminInfo
getTokens ${CP4BA_INST_PFS_NAMESPACE}
showFederatedServers