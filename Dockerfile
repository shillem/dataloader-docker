FROM alpine:latest as base
RUN apk --no-cache add bash openjdk11-jdk

FROM base as dataloader
RUN apk --no-cache add git maven
WORKDIR /tmp
RUN git clone https://github.com/forcedotcom/dataloader.git && \
    cd dataloader && \
    git submodule init && \
    git submodule update
WORKDIR /tmp/dataloader
COPY pom-docker.xml .
COPY pom-fix.sh .
RUN chmod +x pom-fix.sh && ./pom-fix.sh pom.xml pom-docker.xml
RUN mvn clean package -DskipTests

FROM base
WORKDIR /opt/app
RUN mkdir -p configs/release && mkdir libs
COPY --from=dataloader /tmp/dataloader/target/dataloader-*-uber.jar ./dataloader.jar
COPY --from=dataloader /tmp/dataloader/release/configs ./configs/example/configs
COPY --from=dataloader /tmp/dataloader/release/samples ./configs/example/samples

ARG JOBBER_VERSION=1.4.0
ENV USER=dataloader
ENV USER_ID=1000
RUN addgroup ${USER} && adduser -S -u "${USER_ID}" ${USER}
RUN wget -O /tmp/jobber.apk "https://github.com/dshearer/jobber/releases/download/v${JOBBER_VERSION}/jobber-${JOBBER_VERSION}-r0.apk" && \
    apk add --no-network --no-scripts --allow-untrusted /tmp/jobber.apk && \
    rm /tmp/jobber.apk && \
    mkdir -p "/var/jobber/${USER_ID}" && \
    chown -R ${USER} "/var/jobber/${USER_ID}"
COPY --chown=${USER} jobber.yaml /home/${USER}/.jobber
RUN chown -R ${USER} configs && \
    chown -R ${USER} libs && \
    chmod 0600 /home/${USER}/.jobber

COPY dataloader ./
RUN chmod +x dataloader
ENV PATH=/opt/app:${PATH}
USER ${USER}

VOLUME ["/opt/app/configs"]
VOLUME ["/opt/app/libs"]

CMD ["/usr/libexec/jobberrunner", "-u", "/var/jobber/1000/cmd.sock", "/home/dataloader/.jobber"]