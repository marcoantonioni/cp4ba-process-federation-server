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


#--------------------------------------------------------
createPfs () {

cat <<EOF | oc create -f -
apiVersion: icp4a.ibm.com/v1
kind: ProcessFederationServer
metadata:
  name: ${PFS_NAME}
  namespace: ${PFS_NAMESPACE}
spec:
  appVersion: ${PFS_APP_VER}
  license:
    accept: true
  shared_configuration: 
    sc_deployment_license: production
    storage_configuration:
      sc_medium_file_storage_classname: ${PFS_STORAGE_CLASS}
      sc_slow_file_storage_classname: ${PFS_STORAGE_CLASS}
  pfs_configuration:
    admin_user_id:
      - ${PFS_ADMINUSER}
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

storageClassExist ${PFS_STORAGE_CLASS}
if [ $? -eq 0 ]; then
    echo "ERROR: Storage class not found"
    exit
fi

getPfsAdminInfo true
# createPfs
# waitForResourceCreated ${PFS_NAMESPACE} pfs ${PFS_NAME} 10
waitForPfsReady ${PFS_NAMESPACE} ${PFS_NAME} 5
showPFSUrls ${PFS_NAMESPACE} ${PFS_NAME}
