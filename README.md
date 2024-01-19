# cp4ba-process-federation-server

<i>Last update: 2024-01-10</i> use '<b>1.0.0-stable</b>'

```
> main always unstable

> branch 1.0.0-stable
```

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

Please use '-stable' versions, the main branch may contain untested functionality.

See '[Prerequisites](#Prerequisites)' section before deploying PFS servers.

All examples make use of dynamic storage, the presence of a storage class for dynamic volume allocation is required.

The tools '<i>oc</i>' and '<i>jq</i>' are required.

The '<i>openssl</i>' tool is required only for the integration scenario with external services protected by TLS transports.

All examples and scripts are only available for Linux boxes with <i>bash</i> shell.

<b>WARNING</b>: before run any command please update configuration files with your values.

## Description of configuration files and variables

PFS configuration file variables
```
CP4BA_INST_PFS_NAME=<name-of-cr> # any name k8s compatible
CP4BA_INST_PFS_NAMESPACE=<target-namespace> # any name k8s compatible
CP4BA_INST_PFS_STORAGE_CLASS=<name-of-file-type-storage-class> # select one available from your OCP cluster
CP4BA_INST_PFS_APP_VER=<cp4ba-version-number> (eg: 23.0.2)
CP4BA_INST_PFS_ADMINUSER=<admin-user-name> # any user in your IDP/LDAP configuration (eg: "cpadmin")
```

## Prerequisites

To continue with the deployment examples, the following prerequisites must be met:

- The destination namespace must contain at least a running Foundation deployment (a starter deployment configuration is enough).

- Before creating the PFS deployment verify the presence of 'elasticsearch' in 'shared_configuration.sc_optional_components'. The PFS operator will wait undefinitely if 'elasticsearch' is not set.

## Create process federation server

```
cd ./scripts
time ./pfs-deploy.sh -c ../configs/pfs1.properties

# used for PFS-BAW-WFPS demos
cd ./scripts
time ./pfs-deploy.sh -c ../configs/demo-wfps-baw.properties
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
Planning for a CP4BA Process Federation Server production deployment
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-planning-cp4ba-process-federation-server-production

Installing a CP4BA Process Federation Server production deployment
[https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployments-installing-cp4ba-process-federation-server-production-deployment](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployments-installing-cp4ba-process-federation-server-production-deployment)

Other useful informations about PFS when used with BAW
[https://community.ibm.com/community/user/automation/blogs/zhili-guan/2023/08/24/topology-of-baw-on-containers-2301](https://community.ibm.com/community/user/automation/blogs/zhili-guan/2023/08/24/topology-of-baw-on-containers-2301)

[https://community.ibm.com/community/user/automation/blogs/julien-carnec/2023/03/10/federating-on-prem-baw-from-pfs-on-containers](https://community.ibm.com/community/user/automation/blogs/julien-carnec/2023/03/10/federating-on-prem-baw-from-pfs-on-containers)

Administering and operating IBM Process Federation Server Containers
[https://github.com/icp4a/process-federation-server-containers](https://github.com/icp4a/process-federation-server-containers)


TOOLS

Openshift CLI
[https://docs.openshift.com/container-platform/4.14/cli_reference/openshift_cli/getting-started-cli.html](https://docs.openshift.com/container-platform/4.14/cli_reference/openshift_cli/getting-started-cli.html)

JQ
[https://jqlang.github.io/jq](https://jqlang.github.io/jq)


# Notes
```
# openapi web page
https://<host-name>/pfs/rest/bpm/federated/openapi/index.html

# launchable entities from all federated servers
https://<host-name>/pfs/rest/bpm/federated/v1/launchableEntities

# tasks
https://<host-name>/pfs/rest/bpm/federated/v1/tasks?interaction=all

# processes
https://<host-name>/pfs/rest/bpm/federated/v1/instances?size=10&offset=10


# active federated systems
https://<host-name>/pfs/rest/bpm/federated/v1/systems
```

## active federated systems - output samples
```
# no federated servers
{
  "exceptionType":"NoFederatedsystemException",
  "errorMessage":"CWMFS4021E: There is no federated system declared in Process Federation Server configuration.","errorMessageParameters":[],
  "errorNumber":"CWMFS4021E",
  "status":500
}

# one or more federated servers
{
  "federationResult": [
    {
      "restUrlPrefix": "https:\/\/cpd-cp4ba-wfps-runtime1.apps.......cloud.techzone.ibm.com\/wfps-t1-wfps\/rest\/bpm\/wle",
      "systemID": "5c160893-9087-42f8-9b31-8485fbaeea2f",
      "displayName": "5c160893-9087-42f8-9b31-8485fbaeea2f",
      "systemType": "SYSTEM_TYPE_WLE",
      "id": "5c160893-9087-42f8-9b31-8485fbaeea2f",
      "taskCompletionUrlPrefix": "https:\/\/cpd-cp4ba-wfps-runtime1.apps......cloud.techzone.ibm.com\/wfps-t1-wfps\/teamworks",
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
