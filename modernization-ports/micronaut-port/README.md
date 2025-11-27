# Micronaut Host Information Application

A modern Micronaut 4.x application migrated from WebLogic Server 12.2.1.4, demonstrating REST APIs, embedded Netty server, and Oracle Autonomous Database connectivity.

## Quick Start

### Prerequisites
- Java 17 or higher
- Maven 3.6 or higher

### Build and Run

```bash
# Build the application
./build.sh --jar

# Run the application
java -jar target/hostinfo.jar
```

### Access the Application

- **Home Page**: http://localhost:8080/hostinfo/
- **Swagger UI**: http://localhost:8080/hostinfo/swagger/views/swagger-ui/index.html
- **Health Check**: http://localhost:8080/hostinfo/health

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
# Get session info
curl http://localhost:8080/hostinfo/api/session-info

# Set session data
curl -X POST "http://localhost:8080/hostinfo/api/session-data?userName=John&customKey=myKey&customValue=myValue"

# Invalidate session
curl -X DELETE http://localhost:8080/hostinfo/api/session
```

### Greeting Service
```bash
# Get greeting
curl http://localhost:8080/hostinfo/api/greet?name=Micronaut

# Get welcome message
curl http://localhost:8080/hostinfo/api/welcome

# Get service info
curl http://localhost:8080/hostinfo/api/service-info
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
✅ Micronaut 4.x with embedded Netty  
✅ Oracle ADB connectivity with HikariCP  
✅ HTTP session management  
✅ Swagger/OpenAPI documentation  
✅ Health check endpoints  
✅ Ultra-fast startup (~1 second)  
✅ Docker support  

## Migration from WebLogic

This application demonstrates the migration from:
- **WAR** → **JAR** packaging
- **Servlets** → **REST Controllers**
- **EJB @Stateless** → **Micronaut @Singleton**
- **@EJB** → **@Inject**
- **JAX-WS SOAP** → **REST JSON**
- **Oracle UCP** → **HikariCP**
- **60s startup** → **~1s startup**

## Documentation

See [SPRINGBOOT_MIGRATION.md](../docs/SPRINGBOOT_MIGRATION.md) for comprehensive migration guide (same concepts apply to Micronaut).

## License

Copyright (c) Oracle Corporation
