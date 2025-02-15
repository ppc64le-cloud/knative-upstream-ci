### Build instructions for v1.19.1

```bash
git clone https://github.com/projectcontour/contour.git
cd contour
git checkout v1.19.1
make
make check
```

Update docker file with `ARG BUILDPLATFORM=linux/ppc64le`

```diff
diff --git a/Dockerfile b/Dockerfile
index 393c3db8..a79d3208 100644
--- a/Dockerfile
+++ b/Dockerfile
@@ -1,4 +1,4 @@
-ARG BUILDPLATFORM=linux/amd64
+ARG BUILDPLATFORM=linux/ppc64le
ARG BUILD_BASE_IMAGE

FROM --platform=$BUILDPLATFORM $BUILD_BASE_IMAGE AS build
```

Build image

```bash
REGISTRY=registry.apps.a9367076.nip.io VERSION=v1.19.1 make push
```