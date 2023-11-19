FROM eclipse-temurin:17-jdk-alpine AS build
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle .
COPY src src
RUN ./gradlew clean build -x test

FROM eclipse-temurin:17-jre-alpine
COPY --from=build build/libs/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
