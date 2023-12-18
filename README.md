# cp4ba-process-federation-server

This repository contains a series of examples and tools for creating and configuring containerized Process Federation Servers in IBM Cloud Pak for Business Automation deployment.

<b>**WARNING**</b>:

++++++++++++++++++++++++++++++++++++++++++++++++
<br>
<i>
This software and the configurations contained in the repository MUST be considered as examples for educational purposes.
<br>
Do not use in a production environment without making your own necessary modifications.
</i>
<br>
++++++++++++++++++++++++++++++++++++++++++++++++


<b>WARNING</b>: before run any command please update configuration files with your values

## Create process federation server
```
cd ./scripts
time ./pfs-deploy.sh -c ../configs/pfs1.properties

# BAStudio dev env
time ./pfs-deploy.sh -c ../configs/pfs-bastudio.properties

```

## Show federated servers
```
# only names
./pfs-show-federated.sh -c ../configs/pfs1.properties

# all details
./pfs-show-federated.sh -c ../configs/pfs1.properties -d
```

## Show federated contents
```
# only tasks
./pfs-show-contents.sh -c ../configs/pfs1.properties -t

# only processes
./pfs-show-contents.sh -c ../configs/pfs1.properties -p

# only launchable entities
./pfs-show-contents.sh -c ../configs/pfs1.properties -l

# all
./pfs-show-contents.sh -c ../configs/pfs1.properties -a

# you may combine any parameters but -a
```

# References

Installing a CP4BA Process Federation Server production deployment
[https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployments-installing-cp4ba-process-federation-server-production-deployment](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployments-installing-cp4ba-process-federation-server-production-deployment)

### notes
```

#-----------------------------------------

# openapi
https://cpd-cp4ba-wfps-federated.apps.654892a90ae5f40017a3834c.cloud.techzone.ibm.com/pfs/rest/bpm/federated/openapi/index.html

# launchable entities from all federated servers
https://cpd-cp4ba-wfps-federated.apps.654892a90ae5f40017a3834c.cloud.techzone.ibm.com/pfs/rest/bpm/federated/v1/launchableEntities

# tasks
https://cpd-cp4ba-wfps-federated.apps.654892a90ae5f40017a3834c.cloud.techzone.ibm.com/pfs/rest/bpm/federated/v1/tasks?interaction=all

# processes
https://cpd-cp4ba-wfps-federated.apps.654892a90ae5f40017a3834c.cloud.techzone.ibm.com/pfs/rest/bpm/federated/v1/instances?size=10&offset=10


# configurazione federazione
https://cpd-cp4ba-wfps-federated.apps.654892a90ae5f40017a3834c.cloud.techzone.ibm.com/pfs/rest/bpm/federated/v1/systems

# nessun server federato
{
  "exceptionType":"NoFederatedsystemException",
  "errorMessage":"CWMFS4021E: There is no federated system declared in Process Federation Server configuration.","errorMessageParameters":[],
  "errorNumber":"CWMFS4021E",
  "status":500
}

# almeno un server federato
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

