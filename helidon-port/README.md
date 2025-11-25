# Helidon MP Host Information Application

A modern Helidon MP application migrated from WebLogic Server 12.2.1.4, demonstrating REST APIs with JAX-RS, CDI services, and Oracle Autonomous Database connectivity with HikariCP.

## Quick Start

### Prerequisites
- Java 17 or higher
- Maven 3.8 or higher

### Build and Run

```bash
# Build the application
./build.sh --jar

# Run the application
java -jar target/hostinfo.jar
```

### Access the Application

- **Host Info API**: http://localhost:8080/api/host-info
- **Greeting API**: http://localhost:8080/api/greet?name=World
- **Database Info**: http://localhost:8080/api/database-info
- **Session API**: http://localhost:8080/api/session
- **OpenAPI**: http://localhost:8080/openapi
- **Health Check**: http://localhost:8080/health

## REST API Endpoints

### Host Information
```bash
curl http://localhost:8080/api/host-info
```

### Greeting Service
```bash
# Get greeting
curl http://localhost:8080/api/greet?name=Helidon

# Get welcome message
curl http://localhost:8080/api/greet/welcome

# Get service info
curl http://localhost:8080/api/greet/info
```

### Database Information
```bash
curl http://localhost:8080/api/database-info
```

### Session Management
```bash
# Get or create session
curl http://localhost:8080/api/session

# Get session by ID
curl http://localhost:8080/api/session/{sessionId}

# Set session username
curl -X POST "http://localhost:8080/api/session/{sessionId}/user?userName=John"

# Invalidate session
curl -X DELETE http://localhost:8080/api/session/{sessionId}
```

## Docker

### Build Image
```bash
./build.sh --docker
```

### Run Container
```bash
docker run -p 8080:8080 hostinfo-helidon:latest
```

### With Environment Variables
```bash
docker run -p 8080:8080 \
    -e DB_MOCK_MODE=false \
    -e DB_URL=jdbc:oracle:thin:@myatp_high?TNS_ADMIN=/wallet \
    -e DB_USER=ADMIN \
    -e DB_PASSWORD=secret \
    hostinfo-helidon:latest
```

## Configuration

Edit `src/main/resources/application.yaml` to configure:
- Server port
- Database connection (HikariCP)
- Logging levels

### Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `DB_MOCK_MODE` | Enable mock mode (no real DB) | `true` |
| `DB_URL` | JDBC URL for Oracle ADB | `jdbc:oracle:thin:@localhost:1521/mockdb` |
| `DB_USER` | Database username | `ADMIN` |
| `DB_PASSWORD` | Database password | (empty) |
| `DB_SERVICE_NAME` | ADB service name | `mock_adb_high` |
| `DB_WALLET_LOCATION` | Path to Oracle wallet | (empty) |
| `SESSION_TIMEOUT` | Session timeout in seconds | `1800` (30 min) |

## Migration from WebLogic

This application demonstrates the migration from WebLogic 12.2.1.4:

### Architecture Changes

| Component | WebLogic | Helidon MP |
|-----------|----------|------------|
| **Packaging** | WAR | Fat JAR |
| **Server** | WebLogic Server | Embedded Helidon |
| **REST** | Servlets | JAX-RS Resources |
| **Business Logic** | EJB @Stateless | CDI @ApplicationScoped |
| **Web Services** | JAX-WS SOAP | JAX-RS REST/JSON |
| **Connection Pool** | Oracle UCP | HikariCP |
| **Config** | web.xml, weblogic.xml | application.yaml |
| **Startup Time** | ~60 seconds | ~2 seconds |

### Migration Patterns

#### 1. Servlets → JAX-RS Resources
**Before (WebLogic):**
```java
@WebServlet("/hostinfo")
public class HostInfoServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) { ... }
}
```

**After (Helidon MP):**
```java
@Path("/api/host-info")
@RequestScoped
public class HostInfoResource {
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public HostInfo getHostInfo() { ... }
}
```

#### 2. EJB → CDI Services
**Before (WebLogic):**
```java
@Stateless
@WebService
public class GreetingServiceBean implements GreetingService { ... }
```

**After (Helidon MP):**
```java
@ApplicationScoped
public class GreetingServiceImpl {
    public String greet(String name) { ... }
}
```

#### 3. SOAP → REST JSON
**Before (WebLogic):**
- JAX-WS @WebService annotations
- SOAP XML messages
- WSDL generation

**After (Helidon MP):**
- JAX-RS @Path annotations
- JSON responses with JSON-B
- OpenAPI documentation

#### 4. Oracle UCP → HikariCP
**Before (WebLogic):**
```java
PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();
pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
```

**After (Helidon MP):**
```java
HikariConfig config = new HikariConfig();
config.setJdbcUrl(databaseUrl);
HikariDataSource dataSource = new HikariDataSource(config);
```

#### 5. Session Handling
**Before (WebLogic):**
- HttpSession with weblogic.xml session-descriptor
- In-memory replication in clusters

**After (Helidon MP):**
- CDI managed SessionService
- Options: JWT tokens, Redis, database-backed sessions

## Project Structure

```
helidon-port/
├── src/
│   ├── main/
│   │   ├── java/com/oracle/demo/
│   │   │   ├── HostInfoApplication.java    # JAX-RS Application
│   │   │   ├── model/                      # DTOs
│   │   │   │   ├── HostInfo.java
│   │   │   │   ├── DatabaseInfo.java
│   │   │   │   ├── SessionInfo.java
│   │   │   │   └── GreetingResponse.java
│   │   │   ├── resource/                   # JAX-RS Resources
│   │   │   │   ├── HostInfoResource.java
│   │   │   │   ├── GreetingResource.java
│   │   │   │   ├── DatabaseResource.java
│   │   │   │   └── SessionResource.java
│   │   │   └── service/                    # CDI Services
│   │   │       ├── HostInfoService.java
│   │   │       ├── GreetingServiceImpl.java
│   │   │       ├── DatabaseService.java
│   │   │       └── SessionService.java
│   │   └── resources/
│   │       ├── application.yaml            # Helidon config
│   │       ├── logging.properties
│   │       └── META-INF/
│   │           └── beans.xml               # CDI config
│   └── test/
│       └── java/com/oracle/demo/
│           └── HostInfoResourceTest.java
├── pom.xml                                 # Maven with Helidon BOM
├── Dockerfile
├── build.sh
└── README.md
```

## Features

✅ REST APIs with JAX-RS and JSON-B  
✅ CDI dependency injection  
✅ MicroProfile Config  
✅ MicroProfile OpenAPI (Swagger)  
✅ MicroProfile Health checks  
✅ MicroProfile Metrics  
✅ HikariCP connection pooling  
✅ Oracle JDBC driver for ADB  
✅ Fast startup (~2 seconds)  
✅ Small footprint  
✅ Docker support  

## Key Differences from WebLogic

| Aspect | WebLogic | Helidon MP |
|--------|----------|------------|
| Deployment | Deploy WAR to server | Run JAR directly |
| Startup | ~60+ seconds | ~2 seconds |
| Memory | Heavy (GB) | Light (MB) |
| Configuration | XML files | YAML + annotations |
| Standards | Java EE | MicroProfile + Jakarta EE |
| Container | Required | Optional (embedded) |

## License

Copyright (c) Oracle Corporation
