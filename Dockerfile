ARG EMSDK_VERSION=3.1.74
ARG OPENJDK_VERSION=18
FROM alpine/git AS patch-server
WORKDIR /openrsc
ADD https://github.com/Open-RSC/Core-Framework.git#develop /openrsc/
COPY ./server/patch/*.patch /openrsc/patch/
RUN git apply --allow-empty patch/*.patch
FROM openjdk:${OPENJDK_VERSION}-jdk-slim AS build-server
ADD --checksum=sha256:71334d7e5d98cfe53d6c429a648a5021137a967378667306c5f613dff5180506 https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.15-bin.tar.gz ant.tar.gz
RUN mkdir /opt/ant && tar -xvzf ant.tar.gz --strip-components=1 -C /opt/ant && ln -s /opt/ant/bin/ant /usr/bin/ant
COPY --from=patch-server /openrsc /openrsc
RUN ant -f openrsc/server/build.xml compile_core
RUN ant -f openrsc/server/build.xml compile_plugins
FROM openjdk:${OPENJDK_VERSION}-slim AS server
WORKDIR /server
COPY --from=build-server /openrsc/server /server
COPY --from=build-server /opt/ant /opt/ant
COPY ./server/keys/*.pem /server/
RUN ln -s /opt/ant/bin/ant /usr/bin/ant
EXPOSE 43594 43494
CMD ["ant", "runserverzgc", "-DconfFile=local"]
FROM emscripten/emsdk:${EMSDK_VERSION} AS build-client
WORKDIR  /rsc-c
ADD https://github.com/2003scape/rsc-c.git#master /rsc-c
COPY ./client/shell.html /rsc-c/web/shell.html
COPY ./client/worlds.cfg /rsc-c/options/
COPY ./client/Makefile.emscripten /rsc-c/
RUN make -f Makefile.emscripten 
FROM caddy:2-alpine AS client
WORKDIR /client
COPY --from=build-client /rsc-c/mudclient.* /rsc-c/web/manifest.json /rsc-c/web/icon.png /client/
COPY ./client/index.html /client/
CMD ["caddy", "file-server", "--listen", ":80"]
FROM mariadb:latest AS mariadb
COPY --from=build-server /openrsc/server/inc/my.cnf /etc/mysql/my.cnf
COPY --from=build-server /openrsc/server/inc/innodb.cnf /etc/mysql/conf.d/innodb.cnf
COPY --from=build-server /openrsc/server/database/mysql/core.sql /docker-entrypoint-initdb.d/init.sql