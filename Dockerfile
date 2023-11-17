FROM amazoncorretto:17.0.7-alpine

COPY build/libs/spring-petclinic-*.jar app.jar

CMD ["java", "-jar", "app.jar"]

