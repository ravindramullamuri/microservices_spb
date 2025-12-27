# Start with base container java runtime
FROM openjdk:26-ea-17-jdk-slim


MAINTAINER gnr.com

COPY target/accounts-0.0.1-SNAPSHOT.jar accounts-0.0.1-SNAPSHOT.jar

ENTRYPOINT ["java","-jar","accounts-0.0.1-SNAPSHOT.jar"]