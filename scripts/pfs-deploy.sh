#!/bin/bash

_me=$(basename "$0")

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

usage () {
  echo ""
  echo -e "${_CLR_GREEN}usage: $_me
    -c full-path-to-config-file
    -e (optional) embedded-run, no wait${_CLR_NC}"
}

_EMBEDDED_INST=false
#--------------------------------------------------------
# read command line params
while getopts c:e flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        e) _EMBEDDED_INST=true;;
    esac
done

if [[ -z "${_CFG}" ]]; then
  usage
  exit 1
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "ERROR: PFS deployment, configuration file not found: "${_CFG}
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


#--------------------------------------------------------
createPfs () {

mkdir -p $_SCRIPT_DIR/../output
OUT_FILE=$_SCRIPT_DIR/../output/${CP4BA_INST_PFS_NAME}.yaml

cat <<EOF > $OUT_FILE
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
    replicas: 2
EOF

oc create -f $OUT_FILE

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
    exit 1
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
if [[ "${_EMBEDDED_INST}" = "false" ]]; then
  waitForPfsReady ${CP4BA_INST_PFS_NAMESPACE} ${CP4BA_INST_PFS_NAME} 5
  showPFSUrls ${CP4BA_INST_PFS_NAMESPACE} ${CP4BA_INST_PFS_NAME}
fi
exit 0