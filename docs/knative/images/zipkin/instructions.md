# Build openzipkin/zipkin image

[openzipkin/zipkin](https://github.com/openzipkin/zipkin) is dependent on [openzipkin/docker-java](https://github.com/openzipkin/docker-java) which internally requires [openzipkin/docker-alpine](https://github.com/openzipkin/docker-alpine)

## Build openzipkin/alpine image

- [Container Image](https://github.com/orgs/openzipkin/packages/container/package/alpine)
- [Source Code](https://github.com/openzipkin/docker-alpine)
- Commit: `d45731a20d107ec5ae3eb7bb5373e9336c900e0b`

```bash
git clone https://github.com/openzipkin/docker-alpine.git
cd docker-alpine
```

Dockerfile uses old `openzipkin/alpine` images to avoid docker rate limiting. Since old images don't have power support, using original `alpine` image.

```diff
diff --git a/Dockerfile b/Dockerfile
index 7fc2e9d..5558b1b 100644
--- a/Dockerfile
+++ b/Dockerfile
@@ -29,7 +29,7 @@ COPY . /code/

 # See from a previously published version to avoid pulling from Docker Hub (docker.io)
 # This version is only used to install the real version
-FROM ghcr.io/openzipkin/alpine:3.12.1 as install
+FROM alpine:3.12.1 as install

 WORKDIR /code
 # Conditions aren't supported in Dockerfile instructions, so we copy source even if it isn't used.
diff --git a/alpine_minirootfs b/alpine_minirootfs
index 5beb282..143aa0b 100755
--- a/alpine_minirootfs
+++ b/alpine_minirootfs
@@ -39,6 +39,9 @@ case ${arch} in
   s390x* )
     arch=s390x
     ;;
+  ppc64le* )
+    arch=ppc64le
+    ;;
   * )
     >&2 echo "Unsupported arch: ${arch}"
     exit 1;
```

Building image using [instructions](https://github.com/openzipkin/docker-alpine#release-process).

```bash
$ ./build-bin/build 3.15.3
Building image openzipkin/alpine:test
[+] Building 8.4s (13/13) FINISHED
 => [internal] load build definition from Dockerfile                                                                                   0.0s
 => => transferring dockerfile: 3.52kB                                                                                                 0.0s
 => [internal] load .dockerignore                                                                                                      0.0s
 => => transferring context: 192B                                                                                                      0.0s
 => [internal] load metadata for docker.io/library/alpine:3.12.1                                                                       1.4s
 => [install 1/5] FROM docker.io/library/alpine:3.12.1@sha256:c0e9560cda118f9ec63ddefb4a173a2b2a0347082d7dff7dc14272e7841a5b5a         0.0s
 => => resolve docker.io/library/alpine:3.12.1@sha256:c0e9560cda118f9ec63ddefb4a173a2b2a0347082d7dff7dc14272e7841a5b5a                 0.0s
 => [internal] load build context                                                                                                      0.0s
 => => transferring context: 1.54kB                                                                                                    0.0s
 => [code 1/1] COPY . /code/                                                                                                           0.1s
 => [install 2/5] WORKDIR /code                                                                                                        0.2s
 => [install 3/5] COPY --from=code /code/ .                                                                                            0.1s
 => [install 4/5] WORKDIR /install                                                                                                     0.1s
 => [install 5/5] RUN /code/alpine_minirootfs 3.15.3                                                                                   1.3s
 => [alpine 1/2] COPY --from=install /install /                                                                                        0.2s
 => [alpine 2/2] RUN   echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf &&   for repository in mai  4.5s
 => exporting to image                                                                                                                 0.1s
 => => exporting layers                                                                                                                0.1s
 => => writing image sha256:4c2146fb00a85e349c6f76362402f540a7b415cbb05da4426ad69a549c52455b                                           0.0s
 => => naming to docker.io/openzipkin/alpine:test                                                                                      0.0s

$ docker run --rm openzipkin/alpine:test -c 'cat /etc/alpine-release'
3.15.3
```

Use locally built `openzipkin/alpine:test` in `openzipkin/java` build.

## Build openzipkin/java image

- [Source Code](https://github.com/openzipkin/docker-java)
- [Container Image](https://github.com/openzipkin/docker-java/pkgs/container/java)
- Commit: `e7efda261c11a93313714be60406a3d7debe938e`

```
git clone https://github.com/openzipkin/docker-java.git
cd docker-java
```

Make code changes. 

```diff
diff --git a/Dockerfile b/Dockerfile
index 2e5f4a7..5c37394 100644
--- a/Dockerfile
+++ b/Dockerfile
@@ -6,7 +6,7 @@
 # docker_parent_image is the base layer of full and jre image
 #
 # Use latest version here: https://github.com/orgs/openzipkin/packages/container/package/alpine
-ARG docker_parent_image=ghcr.io/openzipkin/alpine:3.14.3
+ARG docker_parent_image=openzipkin/alpine:test

 # java_version is hard-coded here to allow the following to work:
 #  * `docker build https://github.com/openzipkin/docker-java.git`

diff --git a/build-bin/docker/docker_build b/build-bin/docker/docker_build
index 9ce3fdd..2f713ea 100755
--- a/build-bin/docker/docker_build
+++ b/build-bin/docker/docker_build
@@ -20,4 +20,4 @@ version=${2:-}
 docker_args=$($(dirname "$0")/docker_args ${version})

 echo "Building image ${docker_tag}"
-DOCKER_BUILDKIT=1 docker build --pull ${docker_args} --tag ${docker_tag} .
+DOCKER_BUILDKIT=1 docker build ${docker_args} --tag ${docker_tag} .
```

Build image using [instructions](https://github.com/openzipkin/docker-java#release-process).

```bash
$ ./build-bin/build 15.0.5_p3
./build-bin/build 15.0.5_p3
Building image openzipkin/java:test
[+] Building 0.4s (10/10) FINISHED
 => [internal] load build definition from Dockerfile                                                                                   0.0s
 => => transferring dockerfile: 3.95kB                                                                                                 0.0s
 => [internal] load .dockerignore                                                                                                      0.0s
 => => transferring context: 185B                                                                                                      0.0s
 => [internal] load metadata for docker.io/openzipkin/alpine:test                                                                      0.0s
 => [internal] load build context                                                                                                      0.0s
 => => transferring context: 2.85kB                                                                                                    0.0s
 => [base 1/2] FROM docker.io/openzipkin/alpine:test                                                                                   0.0s
 => [code 1/1] COPY . /code/                                                                                                           0.1s
 => CACHED [base 2/2] WORKDIR /java                                                                                                    0.0s
 => CACHED [jdk 1/2] COPY --from=code /code/install.sh .                                                                               0.0s
 => CACHED [jdk 2/2] RUN ./install.sh 15.0.5_p3 3.6.3 && rm install.sh                                                                 0.0s
 => exporting to image                                                                                                                 0.0s
 => => exporting layers                                                                                                                0.0s
 => => writing image sha256:b3f49527ad41cd503fa4de6e7149970e3e765c54530be5213f4596acf3570940                                           0.0s
 => => naming to docker.io/openzipkin/java:test                                                                                        0.0s
Building image openzipkin/java:test-jre
[+] Building 0.2s (14/14) FINISHED
 => [internal] load build definition from Dockerfile                                                                                   0.0s
 => => transferring dockerfile: 92B                                                                                                    0.0s
 => [internal] load .dockerignore                                                                                                      0.0s
 => => transferring context: 94B                                                                                                       0.0s
 => [internal] load metadata for docker.io/openzipkin/alpine:test                                                                      0.0s
 => [base 1/2] FROM docker.io/openzipkin/alpine:test                                                                                   0.0s
 => [internal] load build context                                                                                                      0.0s
 => => transferring context: 92B                                                                                                       0.0s
 => CACHED [base 2/2] WORKDIR /java                                                                                                    0.0s
 => CACHED [code 1/1] COPY . /code/                                                                                                    0.0s
 => CACHED [jdk 1/2] COPY --from=code /code/install.sh .                                                                               0.0s
 => CACHED [jdk 2/2] RUN ./install.sh 15.0.5_p3 3.6.3 && rm install.sh                                                                 0.0s
 => CACHED [install 1/2] WORKDIR /install                                                                                              0.0s
 => CACHED [install 2/2] RUN if [ -d "/usr/lib/jvm/java-15-openjdk" ] && uname -m | grep -E 'aarch64|s390x'; then strip=""; else stri  0.0s
 => CACHED [jre 1/2] COPY --from=install /install/jre/ /usr/lib/jvm/java-15-openjdk/                                                   0.0s
 => CACHED [jre 2/2] RUN java -version                                                                                                 0.0s
 => exporting to image                                                                                                                 0.0s
 => => exporting layers                                                                                                                0.0s
 => => writing image sha256:ad74cfbedd0aa9b7d1395a2961547c65c9416322cd832a3124ec88ce147784f8                                           0.0s
 => => naming to docker.io/openzipkin/java:test-jre                                                                             0.0s

$ docker run --rm openzipkin/java:test -version
openjdk version "15.0.6" 2022-01-18
OpenJDK Runtime Environment (build 15.0.6+5-alpine-r0)
OpenJDK 64-Bit Server VM (build 15.0.6+5-alpine-r0, mixed mode, sharing)

$ docker run --rm openzipkin/java:test-jre -version
openjdk version "15.0.5" 2021-10-19
OpenJDK Runtime Environment (build 15.0.5+3-alpine-r0)
OpenJDK 64-Bit Server VM (build 15.0.5+3-alpine-r0, mixed mode)
```

Use `openzipkin/java:test` & `openzipkin/java:test-jre` in image build of `openzipkin/java`.

## Build openzipkin/zipkin image

- [Container Image](https://github.com/openzipkin/zipkin/pkgs/container/zipkin)
- [Source Code](https://github.com/openzipkin/zipkin)
- Commit: `8a4f4b9c9a5a3204d9663ecef39d687785369c9a`

```bash
git clone https://github.com/openzipkin/zipkin.git
cd zipkin
```

Build jars before creating docker container. Building of jars within container fails due to `frontend-maven-plugin` which uses musl node tarball which is not available on power. Dirty hack to get around this is to build the jars beforehand and modify dockerfile to use them.

```bash
# prefer openjdk15
yum install java-11-openjdk maven -y

mvn -DskipTests package

# ensure zipkin-server/target/zipkin-server-*slim.jar & zipkin-server/target/zipkin-server-*exec.jar  jars are created
ls -l zipkin-server/target/
```

Code changes

```diff
diff --git a/build-bin/docker/docker_build b/build-bin/docker/docker_build
index bc19f6934..2d1e31a8e 100755
--- a/build-bin/docker/docker_build
+++ b/build-bin/docker/docker_build
@@ -20,4 +20,4 @@ version=${2:-}
 docker_args=$($(dirname "$0")/docker_args ${version})

 echo "Building image ${docker_tag}"
-DOCKER_BUILDKIT=1 docker build --pull ${docker_args} --tag ${docker_tag} .
+DOCKER_BUILDKIT=1 docker build ${docker_args} --tag ${docker_tag} .

diff --git a/docker/Dockerfile b/docker/Dockerfile
index d7b567038..c1faabfb8 100644
--- a/docker/Dockerfile
+++ b/docker/Dockerfile
@@ -30,7 +30,7 @@ COPY . /code/

 # This version is only used during the install process. Try to be consistent as it reduces layers,
 # which reduces downloads.
-FROM ghcr.io/openzipkin/java:${java_version} as install
+FROM openzipkin/java:test as install

 WORKDIR /code
 # Conditions aren't supported in Dockerfile instructions, so we copy source even if it isn't used.
@@ -46,13 +46,13 @@ ENV RELEASE_FROM_MAVEN_BUILD=$release_from_maven_build
 ARG version=master
 ENV VERSION=$version
 ENV MAVEN_PROJECT_BASEDIR=/code
-RUN /code/build-bin/maven/maven_build_or_unjar io.zipkin zipkin-server ${VERSION} exec && \
-    mv zipkin-server zipkin && \
-    /code/build-bin/maven/maven_build_or_unjar io.zipkin zipkin-server ${VERSION} slim && \
-    mv zipkin-server zipkin-slim
+RUN mkdir zipkin && cd zipkin && \
+    jar -xf /code/zipkin-server/target/zipkin-server-*exec.jar && cd .. && \
+    mkdir zipkin-slim && cd zipkin-slim && \
+    jar -xf /code/zipkin-server/target/zipkin-server-*slim.jar && cd ..

 # Almost everything is common between the slim and normal build
-FROM ghcr.io/openzipkin/java:${java_version}-jre as base-server
+FROM openzipkin/java:test-jre as base-server

 # All content including binaries and logs write under WORKDIR
 ARG USER=zipkin
```

Build image using [instructions](https://github.com/openzipkin/zipkin/tree/master/docker#building-images).

```bash
$ build-bin/docker/docker_build openzipkin/zipkin:test
Building image openzipkin/zipkin:test
[+] Building 2.5s (19/19) FINISHED
 => [internal] load build definition from Dockerfile                                                                                   0.0s
 => => transferring dockerfile: 3.86kB                                                                                                 0.0s
 => [internal] load .dockerignore                                                                                                      0.0s
 => => transferring context: 95B                                                                                                       0.0s
 => [internal] load metadata for docker.io/openzipkin/java:test-jre                                                                    0.0s
 => [internal] load metadata for docker.io/openzipkin/java:test                                                                        0.0s
 => [base-server 1/4] FROM docker.io/openzipkin/java:test-jre                                                                          0.0s
 => [internal] load build context                                                                                                      0.1s
 => => transferring context: 58.60kB                                                                                                   0.0s
 => [install 1/5] FROM docker.io/openzipkin/java:test                                                                                  0.0s
 => CACHED [install 2/5] WORKDIR /code                                                                                                 0.0s
 => CACHED [scratch 1/3] COPY build-bin/docker/docker-healthcheck /docker-bin/                                                         0.0s
 => CACHED [scratch 2/3] COPY docker/start-zipkin /docker-bin/                                                                         0.0s
 => CACHED [scratch 3/3] COPY . /code/                                                                                                 0.0s
 => CACHED [install 3/5] COPY --from=scratch /code/ .                                                                                  0.0s
 => CACHED [install 4/5] WORKDIR /install                                                                                              0.0s
 => [install 5/5] RUN mkdir zipkin && cd zipkin &&     jar -xf /code/zipkin-server/target/zipkin-server-*exec.jar && cd .. &&     mkd  1.8s
 => CACHED [base-server 2/4] WORKDIR /zipkin                                                                                           0.0s
 => CACHED [base-server 3/4] RUN adduser -g '' -h ${PWD} -D zipkin                                                                     0.0s
 => CACHED [base-server 4/4] COPY --from=scratch /docker-bin/* /usr/local/bin/                                                         0.0s
 => CACHED [zipkin 1/1] COPY --from=install --chown=zipkin /install/zipkin/ /zipkin/                                                   0.0s
 => exporting to image                                                                                                                 0.0s
 => => exporting layers                                                                                                                0.0s
 => => writing image sha256:5f87e47bb9bc75404959bda7c7cae39e935205e42beba27f46dd3dc4f955f9a1                                           0.0s
 => => naming to docker.io/openzipkin/zipkin:test      

$ docker run --rm openzipkin/zipkin:test

                  oo
                 oooo
                oooooo
               oooooooo
              oooooooooo
             oooooooooooo
           ooooooo  ooooooo
          oooooo     ooooooo
         oooooo       ooooooo
        oooooo   o  o   oooooo
       oooooo   oo  oo   oooooo
     ooooooo  oooo  oooo  ooooooo
    oooooo   ooooo  ooooo  ooooooo
   oooooo   oooooo  oooooo  ooooooo
  oooooooo      oo  oo      oooooooo
  ooooooooooooo oo  oo ooooooooooooo
      oooooooooooo  oooooooooooo
          oooooooo  oooooooo
              oooo  oooo

     ________ ____  _  _____ _   _
    |__  /_ _|  _ \| |/ /_ _| \ | |
      / / | || |_) | ' / | ||  \| |
     / /_ | ||  __/| . \ | || |\  |
    |____|___|_|   |_|\_\___|_| \_|

:: version 2.23.17-SNAPSHOT :: commit 8a4f4b9 ::

2022-04-11 12:49:24.549  INFO [/] 1 --- [oss-http-*:9411] c.l.a.s.Server                           : Serving HTTP at /0.0.0.0:9411 - http://127.0.0.1:9411/
```

## Tag and push image for knative tests

```bash
$ docker tag openzipkin/zipkin:test  registry.apps.a9367076.nip.io/openzipkin/zipkin:test

$ docker push registry.apps.a9367076.nip.io/openzipkin/zipkin:test
The push refers to repository [registry.apps.a9367076.nip.io/openzipkin/zipkin]
d3947bcd28de: Layer already exists
075e34a2d12d: Layer already exists
f76880394781: Layer already exists
102b01f019e1: Layer already exists
48f54eacda31: Layer already exists
08b16d415735: Layer already exists
19d1198120b7: Layer already exists
672d8d8ffe74: Layer already exists
f909a8fc650d: Layer already exists
test: digest: sha256:ac5e28556fa39de1283b68955d84a05d69cb053a11071018a8018eccf444587a size: 2200
```

Alternative, we can save & load the image as tarball 

```bash
docker save -o zipkin.tar openzipkin/zipkin:test

docker load < zipkin.tar
```
