# Dockerfile for Micronaut Host Information Application
# Build JAR first with: ./build.sh --jar

FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Copy the pre-built JAR file
COPY target/*.jar app.jar

# Expose the application port
EXPOSE 8080

# Set JVM options for containerized environment
ENV JAVA_OPTS="-Xmx512m -Xms256m"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
