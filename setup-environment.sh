#!/bin/bash

# This script sets up the k8s environment and updates the knative source for running the tests succesfully.

#--- Common Functions ---

SSH_ARGS="-i /etc/secret-volume/ssh-key -o MACs=hmac-sha2-256 -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null"

# Check if the Hosts file is provided as an argument
if [ -z "$1" ]; then
    echo "host file not provided"
    exit 1
fi

# exit if CI_JOB is not set
if [ -z ${CI_JOB} ]
then
    echo "Missing CI_JOB variable"
    exit 1
fi

while IFS= read -r line; do
    scp ${SSH_ARGS} /etc/secret-volume/config.json root@${line}:/var/lib/kubelet/config.json
done < "$1"

create_registry_secrets_in_serving(){
    kubectl create ns knative-serving
    kubectl -n knative-serving create secret generic registry-creds --from-file=config.json=/tmp/config.json
    kubectl -n knative-serving create secret generic registry-certs --from-file=ssl.crt=/tmp/ssl.crt
}

install_contour(){
    # TODO: remove yq dependency
    wget https://github.com/mikefarah/yq/releases/download/v4.25.3/yq_linux_amd64 -P /tmp
    chmod +x /tmp/yq_linux_amd64

    echo "Contour is being installed..."

    envoy_replacement=icr.io/upstream-k8s-registry/knative/maistra/envoy:v2.4
    ISTIO_RELEASE=knative-v1.13.1

     # install istio-crds
    curl --connect-timeout 10 --retry 5 -sL https://github.com/knative-sandbox/net-istio/releases/download/${ISTIO_RELEASE}/istio.yaml | \
    /tmp/yq_linux_amd64 '. | select(.kind == "CustomResourceDefinition"), select(.kind == "Namespace")' | kubectl apply -f -

    # install contour
    curl --connect-timeout 10 --retry 5 -sL https://raw.githubusercontent.com/knative/serving/release-1.1/third_party/contour-latest/contour.yaml | \
    sed 's!\(image: \).*docker.io.*!\1'$envoy_replacement'!g' | kubectl apply -f -
    kubectl apply -f https://raw.githubusercontent.com/knative/serving/main/third_party/contour-latest/net-contour.yaml
    echo "Waiting until all pods under contour-external are ready..."
    kubectl wait --timeout=5m pod --for=condition=Ready -n contour-external -l '!job-name'
}

#------------------------

echo "Setting up access to k8s cluster...."

curl --connect-timeout 10 --retry 5 -sL https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml | sed '/.*--metric-resolution.*/a\        - --kubelet-insecure-tls' | kubectl apply -f -

# TODO: merge with patching conditional code below?
if [[ ${CI_JOB} =~ client-* ]]
then
    create_registry_secrets_in_serving &> /dev/null
    install_contour &> /dev/null
elif [[ ${CI_JOB} =~ operator-* ]]
then
    install_contour &> /dev/null
elif [[ ${CI_JOB} =~ contour-* || ${CI_JOB} =~ kourier-* ]]
then
    create_registry_secrets_in_serving &> /dev/null
elif [[ ${CI_JOB} =~ plugin_event-* ]]
then
    create_registry_secrets_in_serving &> /dev/null
fi

echo 'Cluster setup successfully'
echo 'Patching source code with ppc64le specific changes....'
KNATIVE_COMPONENT=$(echo ${CI_JOB} | cut -d '-' -f1)
RELEASE=$(echo ${CI_JOB} | cut -d '-' -f2-)
K_BRANCH_NAME=$(echo ${CI_JOB} | rev | cut -d'-' -f1 | rev)

if [[ ${CI_JOB} =~ contour-* || ${CI_JOB} =~ kourier-* ]]
then
    cp adjust/serving/${KNATIVE_COMPONENT}/${RELEASE}/* /tmp/
elif [[ ${CI_JOB} =~ eventing_rekt-* ]]
then
    cp adjust/eventing/main/* /tmp/
elif [[ ${CI_JOB} =~ eventing_kafka-broker-* ]]
then
    cp adjust/eventing_kafka_broker/${K_BRANCH_NAME}/* /tmp/
    if [[ ${K_BRANCH_NAME} = "main" ]]
    then
        scp ${SSH_ARGS} ${SSH_USER}@${SSH_HOST}:/root/cluster-pool/pool/k8s/kbpatch /tmp
        kubectl create cm kb-patch -n default --from-file=/tmp/kbpatch
    elif [[ ${K_BRANCH_NAME} = "114" ]]
    then
        scp ${SSH_ARGS} ${SSH_USER}@${SSH_HOST}:/root/cluster-pool/pool/k8s/kbpatch114 /tmp
        kubectl create cm kb-patch114 -n default --from-file=/tmp/kbpatch114
    elif [[ ${K_BRANCH_NAME} = "115" ]]
    then
        scp ${SSH_ARGS} ${SSH_USER}@${SSH_HOST}:/root/cluster-pool/pool/k8s/kbpatch113 /tmp
        kubectl create cm kb-patch115 -n default --from-file=/tmp/kbpatch113
    fi
else
    cp adjust/${KNATIVE_COMPONENT}/${RELEASE}/* /tmp/
fi

## Fetch & run adjust.sh script to patch the source code with image replacements and other fixes
## Introducing CI_JOB var which can be used to fetch adjust script based on repo-tag
## $CI_JOB needs to be set in knative upstream job configurations

chmod +x /tmp/adjust.sh
