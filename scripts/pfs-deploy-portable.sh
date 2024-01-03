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
  CP4BA_INST_PFS_ADMINUSER=$(oc get secrets -n ${CP4BA_INST_PFS_NAMESPACE} platform-auth-idp-credentials -o jsonpath='{.data.admin_username}' | base64 -d)
  PFS_ADMINPASSWORD=$(oc get secrets -n ${CP4BA_INST_PFS_NAMESPACE} platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d)
  if [[ -z "${CP4BA_INST_PFS_ADMINUSER}" ]]; then
    echo "ERROR cannot get admin user name from secret"
    exit 1
  fi
  if [[ -z "${PFS_ADMINPASSWORD}" ]]; then
    echo "ERROR cannot get admin password from secret"
    exit 1
  fi
  if [[ ! "$1" = "true" ]]; then
    resourceExist ${CP4BA_INST_PFS_NAMESPACE} pfs ${CP4BA_INST_PFS_NAME}
    if [ $? -eq 1 ]; then
      getPFSUrls ${CP4BA_INST_PFS_NAMESPACE} ${CP4BA_INST_PFS_NAME}
    else
      echo "WARNING: pfs '${CP4BA_INST_PFS_NAME}' not present in namespace '${CP4BA_INST_PFS_NAMESPACE}'"
    fi
  fi
}

#--------------------------------------------------------
createPfs () {

cat <<EOF | oc create -f -
apiVersion: icp4a.ibm.com/v1
kind: ProcessFederationServer
metadata:
  name: ${CP4BA_INST_PFS_NAME}
  namespace: ${CP4BA_INST_PFS_NAMESPACE}
spec:
  appVersion: ${CP4BA_INST_PFS_APP_VER}
  license:
    accept: true
  shared_configuration: 
    sc_deployment_license: production
    storage_configuration:
      sc_medium_file_storage_classname: ${CP4BA_INST_PFS_STORAGE_CLASS}
      sc_slow_file_storage_classname: ${CP4BA_INST_PFS_STORAGE_CLASS}
  pfs_configuration:
    admin_user_id:
      - ${CP4BA_INST_PFS_ADMINUSER}
    replicas: 1
EOF

}

#==========================================
echo ""
echo "*************************************"
echo "****** PFS Runtime Deployment ******"
echo "*************************************"
echo "Using config file: "${CONFIG_FILE}

source ${CONFIG_FILE}

verifyAllParams

storageClassExist ${CP4BA_INST_PFS_STORAGE_CLASS}
if [ $? -eq 0 ]; then
    echo "ERROR: Storage class not found"
    exit
fi

getPfsAdminInfo true
resourceExist ${CP4BA_INST_PFS_NAMESPACE} pfs ${CP4BA_INST_PFS_NAME}
if [ $? -eq 0 ]; then
  echo "Ready to install..."
  createPfs
  waitForResourceCreated ${CP4BA_INST_PFS_NAMESPACE} pfs ${CP4BA_INST_PFS_NAME} 5
else
  echo ${CP4BA_INST_PFS_NAME}" already installed..."
fi
waitForPfsReady ${CP4BA_INST_PFS_NAMESPACE} ${CP4BA_INST_PFS_NAME} 5
showPFSUrls ${CP4BA_INST_PFS_NAMESPACE} ${CP4BA_INST_PFS_NAME}
exit 0