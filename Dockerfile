FROM alpine:latest

RUN apk --no-cache add bash git maven openjdk11-jdk

# DATA LOADER
WORKDIR /tmp

RUN git clone https://github.com/forcedotcom/dataloader.git && \
    cd dataloader && \
    git submodule init && \
    git submodule update && \
    mvn clean package -DskipTests

WORKDIR /opt/app

RUN mkdir configs && mkdir libs && \
    cp /tmp/dataloader/target/dataloader-*-uber.jar ./dataloader.jar && \
    cp -r /tmp/dataloader/release/mac/configs ./configs/sample && \
    rm -r /tmp/dataloader && \
    rm -r ~/.m2

# SCHEDULING
ARG JOBBER_VERSION=1.4.0
ENV USER=dataloader
ENV USER_ID=1000

RUN addgroup ${USER} && adduser -S -u "${USER_ID}" ${USER}

RUN wget -O /tmp/jobber.apk "https://github.com/dshearer/jobber/releases/download/v${JOBBER_VERSION}/jobber-${JOBBER_VERSION}-r0.apk" && \
    apk add --no-network --no-scripts --allow-untrusted /tmp/jobber.apk && \
    rm /tmp/jobber.apk && \
    mkdir -p "/var/jobber/${USER_ID}" && \
    chown -R ${USER} "/var/jobber/${USER_ID}"
    
COPY --chown=${USER} jobfile /home/${USER}/.jobber
RUN chown -R ${USER} configs && \
    chown -R ${USER} libs && \
    chmod 0600 /home/${USER}/.jobber

# WRAPPING UP
COPY dataloader ./
RUN chmod +x dataloader
ENV PATH=/opt/app:${PATH}
USER ${USER}

VOLUME ["/opt/app/configs"]
VOLUME ["/opt/app/libs"]

CMD ["/usr/libexec/jobberrunner", "-u", "/var/jobber/1000/cmd.sock", "/home/dataloader/.jobber"]