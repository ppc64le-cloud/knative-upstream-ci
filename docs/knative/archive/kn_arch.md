## Architecture Overview

![knative-tkn-upstream-ci Architecture](data/knative_architecture.png)

1. A periodic job is triggered in the Service cluster based on the prow configuration found at https://github.com/knative/infra . 

2. The Prow Controller Manager, located in the Service cluster, orchestrates the execution of the triggered job by scheduling it into the build cluster  

3. It runs as a Kubernetes Pod with securely mounted GCP secrets from the hidden-bond-3357 project. 

4. Once the pod starts runnings, it tries to ssh into the cluster-pool node 

5. Once it ssh’s into the cluster-pool, it executes the vm-script, which identifies available VMs. With this info, it creates a cluster on the identified VMs and exports the kubeconfig file. 

6. Following the successful execution of the vm-script, the ci-script runs, configuring the testing environment. Specific changes, such as modifying/pulling ppc64le specific images from the registry and adjusting the test suite for ppc64le, are applied.  Once the environment is set, the tests are executed on the ppc64le cluster 


As can be seen from the architectural overview chart there are quite a number of environments and services used by the knative upstream activities, with most of these environments and services interacting in a number of ways. Here's a more detailed breakdown:

### Cloud environments

- Google Cloud : 
  - url: <https://console.cloud.google.com/home/dashboard?project=hidden-bond-335716>
  - shared project: hidden-bond-335716
  - account access: via Google ID (e.g. gmail ID)
- IBM Cloud :
  - url: <https://cloud.ibm.com/>
  - account: IBM Ecosystem CICD (ID: 108655d3ff9e4489b1c29e83df48623d)
  - resource group: tekton-and-knative-upstreamCI-team
  - account access: via IBM W3 ID

### IBM internal services

- IBM GitHub Enterprise _(1)_:
  - url: <https://github.ibm.com/ppc64le-automation/knative-tkn-upstream-ci>
  - organization: ppc64le-automation
  - repository: knative-tkn-upstream-ci
  - account access: via IBM W3 ID
- IBM TaaS (Tools-As-A-Service) Artifactory _(3)_:
  - url: <https://na.artifactory.swg-devops.com/ui/repos/tree/General/sys-linux-power-team-ftp3distro-docker-images-docker-local>
  - team: sys-linux-power-team (<https://self-service.taas.cloud.ibm.com/teams/sys-linux-power-team>)
  - account access: via IBM W3 ID
- IBM Jira _(4)_:
  - url: <https://jsw.ibm.com/secure/RapidBoard.jspa?rapidView=47379&projectKey=OCPADO>
  - project: OpenShift-Addons (OCPADO)
  - board: Serverless
  - labels: CI, knative, upstream, Z
  - account access: via IBM W3 ID

### WWW / external services

- GitHub :
  - urls:
    - <https://github.com/knative>
    - <https://github.com/knative-extensions>
  - account access: via IBM W3 ID / gmail ID (depends on individual setup)
- knative Prow (in Google Kubernetes Engine) _(II)_:
  - url: <https://prow.knative.dev/?job=*ppc64le*>
  - account access: n/a (monitoring / status page not protected)

