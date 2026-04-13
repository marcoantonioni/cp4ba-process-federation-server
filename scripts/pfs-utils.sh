#!/bin/bash

#set -euo pipefail

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#-------------------------------
isParamSet () {
    if [[ -z "$1" ]];
    then
      return 0
    fi
    return 1
}

#-------------------------------
storageClassExist () {
    if [ $(oc get sc $1 | grep $1 | wc -l) -lt 1 ];
    then
        return 0
    fi
    return 1
}

#-------------------------------
verifyAllParams () {

  isParamSet $CP4BA_INST_PFS_STORAGE_CLASS}
  if [ $? -eq 0 ]; then
      echo "ERROR: CP4BA_INST_PFS_STORAGE_CLASS not set"
      exit 1
  fi

  isParamSet ${CP4BA_INST_PFS_NAME}
  if [ $? -eq 0 ]; then
      echo "ERROR: CP4BA_INST_PFS_NAME not set"
      exit 1
  fi

  isParamSet ${CP4BA_INST_PFS_NAMESPACE}
  if [ $? -eq 0 ]; then
      echo "ERROR: CP4BA_INST_PFS_NAMESPACE not set"
      exit 1
  fi

  isParamSet ${CP4BA_INST_PFS_APP_VER}
  if [ $? -eq 0 ]; then
      echo "ERROR: CP4BA_INST_PFS_APP_VER not set"
      exit 1
  fi

}

#-------------------------------
resourceExist () {
#    echo "namespace name: $1"
#    echo "resource type: $2"
#    echo "resource name: $3"
  if [ $(oc get $2 -n $1 $3 2> /dev/null | grep $3 | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
}

#-------------------------------
waitForResourceCreated () {
#    echo "namespace name: $1"
#    echo "resource type: $2"
#    echo "resource name: $3"
#    echo "time to wait: $4"

  echo -n -e "${_CLR_GREEN}Wait for resource '${_CLR_YELLOW}$3${_CLR_GREEN}' in namespace '${_CLR_YELLOW}$1${_CLR_GREEN}' created...${_CLR_NC}"
  while true 
  do
      resourceExist $1 $2 $3
      if [ $? -eq 0 ]; then
          echo -n "."
          sleep $4
      else
          echo ""
          break
      fi
  done
}

#-------------------------------
waitForPfsReady () {
#    echo "namespace name: $1"
#    echo "resource name: $2"
#    echo "time to wait: $3"
    _TRACE=$4

    echo -n -e "${_CLR_GREEN}Wait for pfs '${_CLR_YELLOW}$2${_CLR_GREEN}' in namespace '${_CLR_YELLOW}$1${_CLR_GREEN}' to be ready...${_CLR_NC}"
    while true 
    do
      _PFS_COMPONENTS=$(oc get pfs -n $1 $2 -o jsonpath='{.status.components.pfs}')
      _pfsDeployment=$(echo $_PFS_COMPONENTS | jq .pfsDeployment | sed 's/"//g' )
      _pfsService=$(echo $_PFS_COMPONENTS | jq .pfsService | sed 's/"//g' )
      _pfsZenIntegration=$(echo $_PFS_COMPONENTS | jq .pfsZenIntegration | sed 's/"//g' )

      [[ ${_TRACE} -eq 1 ]] && echo -e "[DEBUG] PFS readiness: _pfsDeployment[${_CLR_YELLOW}${_pfsDeployment}${_CLR_GREEN}] _pfsService[${_CLR_YELLOW}${_pfsService}${_CLR_GREEN}] _pfsZenIntegration[${_CLR_YELLOW}${_pfsZenIntegration}${_CLR_GREEN}]"

      if [[ "${_pfsDeployment}" = "Ready" ]] && [[ "${_pfsService}" = "Ready" ]] && [[ "${_pfsZenIntegration}" = "Ready" ]]; then
          echo ""
          #echo "pfs '$2' in namespace '$1' is READY"
          return 1
      else
          echo -n "."
          sleep $3
      fi
    done
    return 0
}


#-------------------------------
getPFSUrls() {
    export PFS_URL_BASE=$(oc get pfs -n $1 $2 -o jsonpath='{.status}' | jq '.endpoints[] | select(.type=="Route")' | jq .uri | sed 's/"//g')
    export PFS_URL_REST=${PFS_URL_BASE}"/rest/bpm/federated"
    export PFS_URL_OPENAPI=${PFS_URL_BASE}"/rest/bpm/federated/openapi"
}

#-------------------------------
showPFSUrls() {
    getPFSUrls $1 $2
    echo -e "  url base: ${_CLR_YELLOW}${PFS_URL_BASE}${_CLR_NC}"
    echo -e "  url rest: ${_CLR_YELLOW}${PFS_URL_REST}${_CLR_NC}"
    echo -e "  url openapi explorer: ${_CLR_YELLOW}${PFS_URL_OPENAPI}${_CLR_NC}"
    echo -e "  admin user: ${_CLR_YELLOW}${PFS_ADMINUSER}${_CLR_NC}"
    echo -e "  admin password: ${_CLR_YELLOW}${PFS_ADMINPASSWORD}${_CLR_NC}"
}

#--------------------------------------------------------
getPfsAdminInfo () {
  # $1: boolean skip urls

  if [[ "${CP4BA_INST_PFS_ADMINUSER}" = "cpadmin" ]]; then

    echo -n -e "${_CLR_GREEN}Wait for secret '${_CLR_YELLOW}platform-auth-idp-credentials${_CLR_GREEN}'"
    while true 
    do
      resourceExist ${CP4BA_INST_PFS_NAMESPACE} secrets "platform-auth-idp-credentials"
      if [ $? -eq 0 ]; then
        echo -n "."
        sleep 5
      else
        echo ""
        break
      fi
    done

    export PFS_ADMINUSER=$(oc get secrets -n ${CP4BA_INST_PFS_NAMESPACE} platform-auth-idp-credentials -o jsonpath='{.data.admin_username}' | base64 -d)
    export PFS_ADMINPASSWORD=$(oc get secrets -n ${CP4BA_INST_PFS_NAMESPACE} platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d)
    if [[ -z "${PFS_ADMINUSER}" ]]; then
      echo -e "${_CLR_RED}ERROR cannot get admin user name from secret${_CLR_NC}"
      exit 1
    fi
    if [[ -z "${PFS_ADMINPASSWORD}" ]]; then
      echo -e "${_CLR_RED}ERROR cannot get admin password from secret${_CLR_NC}"
      exit 1
    fi
  else
    export PFS_ADMINUSER="${CP4BA_INST_PFS_ADMINUSER}"
    export PFS_ADMINPASSWORD="${CP4BA_INST_PFS_ADMINPASSW}"
  fi

  if [[ ! "$1" = "true" ]]; then
    resourceExist ${CP4BA_INST_PFS_NAMESPACE} pfs ${CP4BA_INST_PFS_NAME}
    if [ $? -eq 1 ]; then
      getPFSUrls ${CP4BA_INST_PFS_NAMESPACE} ${CP4BA_INST_PFS_NAME}
    else
      echo "${_CLR_GREEN}WARNING: pfs '${_CLR_YELLOW}${CP4BA_INST_PFS_NAME}${_CLR_GREEN}' not present in namespace '${_CLR_YELLOW}${CP4BA_INST_PFS_NAMESPACE}${_CLR_GREEN}'${_CLR_NC}"
    fi
  fi
}