ARG BASE_FINAL_IMAGE=eclipse-temurin:17-jammy

######## Build ########
FROM maven:3.8.4-eclipse-temurin-17 AS build


WORKDIR /src
# this copy uses the .dockerignore to only copy src .m2 and pom.xml
COPY . /src/


# Maven deploy
RUN mvn -e -s .m2/settings.xml clean deploy
RUN ls -lrt /src/target/*
RUN ls -lrt /src/*

######## Dependencies ########
FROM alpine:3.16 as deps

WORKDIR /app/

# download OTLP javaagent as a dependency and we can copy it into the final image
RUN wget -O opentelemetry-javaagent.jar https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar

######## Final Image  ########
FROM ${BASE_FINAL_IMAGE}

WORKDIR /app

# update packages and install
RUN echo "===> OS Update..." \
    && DEBIAN_FRONTEND=noninteractive apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq procps ca-certificates

# userid and groupid to run as
ARG UID=1000
ARG GID=1000

# create non-priv user and group and set homedir as /tmp
RUN groupadd -g "${GID}" non-priv \
  && useradd --create-home -d /tmp --no-log-init -u "${UID}" -g "${GID}" non-priv
# create tmp-pre-boot folder to allow copying into /tmp on bootup and fix permissions
# before changing user (but user must have been created already)
RUN mkdir /tmp-pre-boot || true && chown -R non-priv:non-priv /tmp-pre-boot
USER non-priv

# Copy code binary
COPY --chown=${UID}:${GID} --from=build /src/target/demo-java-service.jar /app/demo-java-service.jar
COPY --chown=${UID}:${GID} --from=deps /app/opentelemetry-javaagent.jar /app/opentelemetry-javaagent.jar
COPY --chown=${UID}:${GID} --from=build /src/entrypoint.sh /app/entrypoint.sh

# move /tmp content into /tmp-pre-boot so entrypoint.sh can copy it back after mounting /tmp
RUN cp -R /tmp/. /tmp-pre-boot/

#Run plugin
ENTRYPOINT ["/app/entrypoint.sh"]