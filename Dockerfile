FROM eclipse-temurin:17-jdk-alpine AS build
 
COPY gradlew .
COPY gradle gradle
COPY config config
COPY build.gradle settings.gradle .
COPY src src
RUN ./gradlew clean build -x test -x processTestAot

FROM eclipse-temurin:17-jre-alpine

ENV JMX_VERSION 0.20.0
ENV JMX_JAR jmx_prometheus_javaagent-$JMX_VERSION.jar
ENV JMX_DIR /opt/jmx_exporter

COPY --from=build build/libs/*.jar app.jar

RUN mkdir -p $JMX_DIR
RUN wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$JMX_VERSION/$JMX_JAR \
 -O $JMX_DIR/$JMX_JAR
RUN chmod +x $JMX_DIR/$JMX_JAR
COPY prometheus/config.yaml $JMX_DIR/config.yaml

CMD ["/bin/bash", "-c", "java -javaagent:$JMX_DIR/$JMX_JAR=10254:$JMX_DIR/config.yaml -jar app.jar"]
