#!/bin/bash

_me=$(basename "$0")

#--------------------------------------------------------
# read command line params
while getopts c: flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file"
  exit
fi

export CONFIG_FILE=${_CFG}

source ./pfs-utils.sh


#-------------------------------
# get common values
getTokens () {

  # get admin URL
  CONSOLE_HOST="https://"$(oc get route -n $1 cp-console -o jsonpath="{.spec.host}")
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
  curl -sk -H "Authorization: Bearer ${ZEN_TK}" -H 'accept: application/json'  -X GET "${PFS_URL_REST}/v1/systems" | jq .
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
getTokens ${PFS_NAMESPACE}
showFederatedServers