# Knative & Tekton Upstream CI

## Introduction
This repo hosts automation, configurations, documentation &amp; scripts to enable/support [Knative](https://knative.dev) &amp; [Tekton](https://tekton.dev) upstream CI on ppc64le.

### PPC64le Knative jobs
We've enabled CI for the following Knative components on ppc64le : 
`client`,`eventing`,`eventing-kafka-broker`,`operator`.

Here's the [link](https://prow.ppc64le-cloud.cis.ibm.net/?job=knative-*) to the ppc64le Knative prow jobs. 

This [repo](https://github.com/ppc64le-cloud/test-infra) hosts the configs for prow. We raise a PR here to add/modify/remove any Knative job.

### Knative documentation
Please read the project [documentation](./docs/knative/README.md) to familiarize with the project setup, involved processes, environments and components.

### PPC64le Tekton jobs
We've enabled CI for the following Tekton components on ppc64le : 
`cli`,`operator`,`triggers`.

Here's the [link](https://dashboard.dogfooding.tekton.dev/#/namespaces/bastion-p/pipelineruns) to the ppc64le Tekton jobs. 

This [repo](https://github.com/tektoncd/plumbing) hosts the job configs. We raise a PR here to add/modify/remove any Tekton job.

### Tekton documentation
Please read the project [documentation](./docs/tekton/README.md) to familiarize with the project setup, involved processes, environments and components.