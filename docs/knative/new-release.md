# Job Configuration Guide for new release

This document explains how to create and configure Knative periodic job tests on ppc64le.

## 1. Fork the Repo

Fork the [test-infra](https://github.com/ppc64le-cloud/test-infra/) repo.

## 2. Job Structure

For each component, we enable 2 jobs:
  - One for the `main` release.
  - Another for the latest stable `N` release.

### Job Naming Convention
All jobs should follow the naming convention:
```
knative-<component>-<release>-periodic
```
#### Example Names:
- `knative-client-main-periodic`
- `knative-client-release-1.17-periodic`

### Adding Configuration Files
Depending on the component you are enabling, add the configuration files either in [knative](https://github.com/ppc64le-cloud/test-infra/tree/master/config/jobs/periodic/knative) or [knative-extensions](https://github.com/ppc64le-cloud/test-infra/tree/master/config/jobs/periodic/knative-extensions) directory:

The following components fall under **Knative** and **Knative Extensions**:

| Knative Components                              | Knative Extensions                        |
|------------------------------------------------|-------------------------------------------|
| `client`, `eventing`, `operator`, `serving-kourier` | `eventing-kafka-broker`, `kn-plugin-event` |

## 3. Example Job Configuration

Below is an example configuration for **Knative Client main branch tests** on ppc64le. This configuration should be added to:
```
config/jobs/periodic/knative/client/main/client-main.gen.yaml
```

```yaml
periodics:
  - name: knative-client-main-periodic
    labels:
      preset-knative-powervs: "true"
    decorate: true
    cron: "0 2 * * *"
    extra_refs:
      - base_ref: main
        org: ppc64le-cloud
        repo: knative-tkn-upstream-ci
        workdir: true
      - base_ref: main
        org: knative
        repo: client
    spec:
      containers:
        - image: quay.io/powercloud/knative-prow-tests:latest
          resources:
            requests:
              cpu: "1500m"
            limits:
              cpu: "1500m"
          command:
            - runner.sh
          args:
            - bash
            - -c
            - |
              set -o errexit
              set -o nounset
              set -o pipefail
              set -o xtrace

              TIMESTAMP=$(date +%s)
              K8S_BUILD_VERSION=$(curl https://storage.googleapis.com/k8s-release-dev/ci/latest.txt)
              ORIGINAL_DIR=$(pwd)

              trap 'pushd $ORIGINAL_DIR; source cluster-setup.sh delete' EXIT

              source cluster-setup.sh create
              pushd $GOPATH/src/github.com/$ORG/$KNATIVE_REPO
              . /tmp/adjust.sh
              ./test/e2e-tests.sh --run-tests
              popd

          env:
            - name: ORG
              value: knative
            - name: KNATIVE_REPO
              value: client
            - name: KNATIVE_RELEASE
              value: main
            - name: INGRESS_CLASS
              value: contour.ingress.networking.knative.dev
            - name: SSL_CERT_FILE
              value: /etc/ssl/certs/ca-certificates.crt
```
- **`ORG`**, **`KNATIVE_REPO`**, and **`KNATIVE_RELEASE`** will change based on the component and version being tested.
- These variables are used in the `setup-environment.sh` script to fetch the correct adjustment script.

For reference, see PR [#532](https://github.com/ppc64le-cloud/test-infra/pull/532).

## 4. Modify Adjustment Scripts
Refer this [doc](./adjustment-scripts.md) to add or modify adjustment scripts required by each component.

## 5. Test Locally & Raise a PR
To test your changes locally, follow the instructions in this [doc](./testing-local.md). Once tests are successful, raise a PR with your changes.
---