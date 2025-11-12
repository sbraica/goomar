FROM eclipse-temurin:21-jdk-jammy

WORKDIR /app

ADD target/api-0.0.1-SNAPSHOT.jar /app/app.jar

ENTRYPOINT ["java", "-Dspring.profiles.active=docker", "-jar", "app.jar"]