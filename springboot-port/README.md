# Spring Boot Host Information Application

A modern Spring Boot 3.x application migrated from WebLogic Server 12.2.1.4, demonstrating REST APIs, embedded Tomcat, and Oracle Autonomous Database connectivity.

## Quick Start

### Prerequisites
- Java 17 or higher
- Maven 3.6 or higher

### Build and Run

```bash
# Build the application
./build.sh

# Run the application
java -jar target/hostinfo.jar
```

### Access the Application

- **Home Page**: http://localhost:8080/hostinfo/
- **Swagger UI**: http://localhost:8080/hostinfo/swagger-ui.html
- **Health Check**: http://localhost:8080/hostinfo/actuator/health

## REST API Endpoints

### Host Information
```bash
curl http://localhost:8080/hostinfo/api/host-info
```

### Database Information
```bash
curl http://localhost:8080/hostinfo/api/database-info
```

### Session Management
```bash
curl http://localhost:8080/hostinfo/api/session-info
```

### Greeting Service
```bash
curl http://localhost:8080/hostinfo/api/greet?name=Spring
```

## Docker

### Build Image
```bash
docker build -t hostinfo:1.0.0 .
```

### Run Container
```bash
docker run -p 8080:8080 hostinfo:1.0.0
```

## Configuration

Edit `src/main/resources/application.yml` to configure:
- Server port
- Database connection
- Session timeout
- Logging levels

### Environment Variables
- `DB_URL`: Database JDBC URL
- `DB_USER`: Database username
- `DB_PASSWORD`: Database password
- `MOCK_MODE`: Set to `false` for real database connection

## Features

✅ REST APIs with JSON responses  
✅ Spring Boot 3.x with embedded Tomcat  
✅ Oracle ADB connectivity with HikariCP  
✅ HTTP session management  
✅ Swagger/OpenAPI documentation  
✅ Spring Boot Actuator for monitoring  
✅ Fast startup (~5 seconds)  
✅ Docker support  

## Migration from WebLogic

This application demonstrates the migration from:
- **WAR** → **JAR** packaging
- **Servlets** → **REST Controllers**
- **EJB @Stateless** → **Spring @Service**
- **@EJB** → **@Autowired**
- **JAX-WS SOAP** → **REST JSON**
- **Oracle UCP** → **HikariCP**
- **60s startup** → **5s startup**

## Documentation

See [SPRINGBOOT_MIGRATION.md](../docs/SPRINGBOOT_MIGRATION.md) for comprehensive migration guide.

## License

Copyright (c) Oracle Corporation
