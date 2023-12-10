#!/bin/bash

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

  isParamSet $PFS_STORAGE_CLASS}
  if [ $? -eq 0 ]; then
      echo "ERROR: PFS_STORAGE_CLASS not set"
      exit 1
  fi

  isParamSet ${PFS_NAME}
  if [ $? -eq 0 ]; then
      echo "ERROR: PFS_NAME not set"
      exit 1
  fi

  isParamSet ${PFS_NAMESPACE}
  if [ $? -eq 0 ]; then
      echo "ERROR: PFS_NAMESPACE not set"
      exit 1
  fi

  isParamSet ${PFS_APP_VER}
  if [ $? -eq 0 ]; then
      echo "ERROR: PFS_APP_VER not set"
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

  echo -n "Wait for resource '$3' in namespace '$1' created"
  while [ true ]
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

    echo -n "Wait for pfs '$2' in namespace '$1' to be READY"
    while [ true ]
    do
      _PFS_COMPONENTS=$(oc get pfs -n $1 $2 -o jsonpath='{.status.components.pfs}')
      _pfsDeployment=$(echo $_PFS_COMPONENTS | jq .pfsDeployment | sed 's/"//g' )
      _pfsService=$(echo $_PFS_COMPONENTS | jq .pfsService | sed 's/"//g' )
      _pfsZenIntegration=$(echo $_PFS_COMPONENTS | jq .pfsZenIntegration | sed 's/"//g' )
      if [[ "${_pfsDeployment}" = "Ready" ]] && [[ "${_pfsService}" = "Ready" ]] && [[ "${_pfsZenIntegration}" = "Ready" ]]; then
          echo ""
          echo "pfs '$2' in namespace '$1' is READY"
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
    echo "  url base: "${PFS_URL_BASE}
    echo "  url rest: "${PFS_URL_REST}
    echo "  url openapi explorer: "${PFS_URL_OPENAPI}
}

#--------------------------------------------------------
getPfsAdminInfo () {
  # $1: boolean skip urls 
  PFS_ADMINUSER=$(oc get secrets -n ${PFS_NAMESPACE} platform-auth-idp-credentials -o jsonpath='{.data.admin_username}' | base64 -d)
  PFS_ADMINPASSWORD=$(oc get secrets -n ${PFS_NAMESPACE} platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d)
  if [[ -z "${PFS_ADMINUSER}" ]]; then
    echo "ERROR cannot get admin user name from secret"
    exit 1
  fi
  if [[ -z "${PFS_ADMINPASSWORD}" ]]; then
    echo "ERROR cannot get admin password from secret"
    exit 1
  fi
  if [[ ! "$1" = "true" ]]; then
    resourceExist ${PFS_NAMESPACE} pfs ${PFS_NAME}
    if [ $? -eq 1 ]; then
      getPFSUrls ${PFS_NAMESPACE} ${PFS_NAME}
    else
      echo "WARNING: pfs '${PFS_NAME}' not present in namespace '${PFS_NAMESPACE}'"
    fi
  fi
}