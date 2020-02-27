FROM adoptopenjdk:11-jdk-openj9

RUN apt-get update && apt-get install cron git maven -y

WORKDIR /tmp

RUN git clone https://github.com/forcedotcom/dataloader.git && \
    cd dataloader && \
    git submodule init && \
    git submodule update && \
    mvn clean package -DskipTests

WORKDIR /opt/app

RUN cp /tmp/dataloader/target/dataloader-*-uber.jar ./dataloader.jar && \
    cp -r /tmp/dataloader/release/mac/configs ./config && \
    rm -r /tmp/dataloader

VOLUME ["/opt/app/config"]

COPY process.sh ./

ENTRYPOINT ["sh", "process.sh"]

# CMD [ "cron", "-f" ]