# Setup the cluster-pool node for Knative Upstream CI

### Prerequisites

- Centos precreated vms at PowerVS. Refer infrastructure [document](infra.md).
- Access to GCP secret manager service. Refer GCP [doc](../gcp-secrets/README.md) for more details.

### Setup automation

Ensure ssh key is added onto bastion to access all nodes and ansible is installed onto bastion.

- Clone the repo in `/opt/` directory on bastion. 
    Cloning the directory at any other loaction will require update in `$BASE_DIR` var in `setup-environment.sh` and in upstream test configurations in [knative/infra](https://github.com/knative/infra).
    ```bash
    cd /opt
    git clone https://github.ibm.com/ppc64le-automation/knative-tkn-upstream-ci
    cd knative-tkn-upstream-ci
    
    # clone k8s automation submodule
    git submodule init
    git submodule update
    ```

- Setup the k8s automation
    - Create `k8s-ansible-automation/hosts.yml` with node details. 
        Refer [k8s-ansible-automation/hosts-sample.yml](https://github.ibm.com/ppc64le-automation/k8s-ansible-automation/blob/main/hosts-sample.yml) file.
    - Create `k8s-ansible-automation/env.yml` with other details. 
        Refer [k8s-ansible-automation/env-sample.yml](https://github.ibm.com/ppc64le-automation/k8s-ansible-automation/blob/main/env-sample.yml) file.

- Trigger a test run to create k8s cluster

  ```bash
  ./k8s-ansible-automation/create-cluster.sh knative
  ```

  ```bash
  $ kubectl get nodes
  NAME              STATUS   ROLES                  AGE     VERSION
  knative-master    Ready    control-plane,master   9m28s   v1.29.0
  knative-worker1   Ready    <none>                 9m6s    v1.29.0
  knative-worker2   Ready    <none>                 9m6s    v1.29.0
  ```

### Configure secrets in GCP

Add/update cluster details on upstream server via GCP. Refer [gcp-secrets](../gcp-secrets/) directory for more details.

### Create upstream jobs 

Refer [adjustment-scripts.md](./adjustment-scripts.md) to add new `adjust.sh` script, [create_job](create_job.md) to add job configurations and [testing](./testing.md) to test the jobs locally.

