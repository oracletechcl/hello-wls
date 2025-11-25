# Dockerfile for Helidon MP Host Information Application
# Build JAR first with: ./build.sh --jar

# Multi-stage build for smaller image size
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Copy the application JAR and dependencies
COPY target/hostinfo.jar app.jar
COPY target/libs libs/

# Expose the application port
EXPOSE 8080

# Set JVM options for containerized environment
ENV JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

# Run the Helidon application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
