# 빌드 단계
FROM gradle:6.8.3-jdk11 AS build
WORKDIR /app
COPY . /app
RUN gradle build --no-daemon

# 실행 단계
FROM adoptopenjdk/openjdk11:alpine-jre
WORKDIR /app
COPY --from=build /app/build/libs/*.jar /app/app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
