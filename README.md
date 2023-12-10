# cp4ba-process-federation-server

## Create process federation server
```
```

### notes
```

#-----------------------------------------
PFS_NAME="pfs-demo"
TNS="cp4ba-wfps-runtime1"

cat <<EOF | oc create -f -
apiVersion: icp4a.ibm.com/v1
kind: ProcessFederationServer
metadata:
  name: ${PFS_NAME}
  namespace: ${TNS}
spec:
  appVersion: 23.0.1  
  license:
    accept: true
  shared_configuration: 
    sc_deployment_license: production
    storage_configuration:
      sc_medium_file_storage_classname: managed-nfs-storage
      sc_slow_file_storage_classname: managed-nfs-storage
  pfs_configuration:
    admin_user_id:
      - cpadmin
    replicas: 1
EOF

#-----------------------------------------

# openapi

https://cpd-cp4ba-wfps-runtime1.apps.654892a90ae5f40017a3834c.cloud.techzone.ibm.com/pfs/rest/bpm/federated/openapi/index.html

# configurazione federazion
https://cpd-cp4ba.apps.654892a90ae5f40017a3834c.cloud.techzone.ibm.com/pfs/rest/bpm/federated/v1/systems

# nessun server federato
{
  "exceptionType":"NoFederatedsystemException",
  "errorMessage":"CWMFS4021E: There is no federated system declared in Process Federation Server configuration.","errorMessageParameters":[],
  "errorNumber":"CWMFS4021E",
  "status":500
}

# alemno un server federato
{
  "federationResult": [
    {
      "restUrlPrefix": "https:\/\/cpd-cp4ba-wfps-runtime1.apps.654892a90ae5f40017a3834c.cloud.techzone.ibm.com\/wfps-t1-wfps\/rest\/bpm\/wle",
      "systemID": "5c160893-9087-42f8-9b31-8485fbaeea2f",
      "displayName": "5c160893-9087-42f8-9b31-8485fbaeea2f",
      "systemType": "SYSTEM_TYPE_WLE",
      "id": "5c160893-9087-42f8-9b31-8485fbaeea2f",
      "taskCompletionUrlPrefix": "https:\/\/cpd-cp4ba-wfps-runtime1.apps.654892a90ae5f40017a3834c.cloud.techzone.ibm.com\/wfps-t1-wfps\/teamworks",
      "version": "8.6.5.23010",
      "indexRefreshInterval": 2000,
      "statusCode": "200"
    }
  ],
  "systems": [
    {
      "systemID": "5c160893-9087-42f8-9b31-8485fbaeea2f",
      "systemType": "SYSTEM_TYPE_WLE",
      "version": "8.6.5.23010",
      "groupWorkItemsEnabled": false,
      "resources": [
        "tasks",
        "taskTemplates",
        "processes"
      ],
      "taskHistoryEnabled": false,
      "buildLevel": "BPM8600-20230612-130223",
      "substitutionEnabled": false,
      "workBasketsEnabled": false,
      "substitutionManagementRestrictedToAdministrators": false,
      "businessCategoriesEnabled": false,
      "taskSearchEnabled": false,
      "notificationWebMessagingEnabled": true,
      "taskListWebMessagingEnabled": true,
      "hostsTaskFilterService": false,
      "apiVersion": "1.0",
      "supports": null,
      "hostname": "wfps-t1-wfps-service"
    }
  ]
}

```

