# Container images for ppc64le

This directory contains list of images which don't have power support and are used in knative testing. The images are expected to be available in IBM Container registry( **icr.io/upstream-k8s-registry/knative**). The image values are used in adjust scripts for image replacements during tests.

|Image|Replacement|Used In|
|:-:|:-:|:-:|
|`projectcontour/contour:v1.29.0`|`icr.io/upstream-k8s-registry/knative/contour:v1.29.0`|`serving`|
|`ghcr.io/openzipkin/zipkin:2`|`icr.io/upstream-k8s-registry/knative/openzipkin/zipkin:test`|`eventing`,`eventing-kafka-broker`|
|`docker.io/envoyproxy/envoy:v1.28.0`|`icr.io/upstream-k8s-registry/knative/maistra/envoy:v2.4`|`eventing`,`plugin-event`|
|`ghcr.io/pierdipi/sacura/sacura-7befbbbc92911c6727467cfbf23af88f`|`icr.io/upstream-k8s-registry/knative/bootstrap/sacura:latest`|`eventing-kafka-broker`|
|`docker.io/edenhill/kafkacat:1.6.0`|`icr.io/upstream-k8s-registry/knative/kafkacat:v1.6.0`|`eventing-kafka-broker`|
|`ghcr.io/kedacore/keda-admission-webhooks:2.10.1`|`icr.io/upstream-k8s-registry/knative/keda-webhook:v2.11.2`|`eventing-kafka-broker`|
|`ghcr.io/kedacore/keda-metrics-apiserver:2.10.1`|`icr.io/upstream-k8s-registry/knative/keda-adapter:v2.11.2`|`eventing-kafka-broker`|
|`ghcr.io/kedacore/keda:2.10.1`|`icr.io/upstream-k8s-registry/knative/keda-main:v2.11.2`|`eventing-kafka-broker`|