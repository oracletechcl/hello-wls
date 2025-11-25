# Host Info Modernization Workshop

This repository demonstrates the modernization of a legacy WebLogic Server (WLS) Java EE application into modern cloud-native architectures using three popular Java frameworks: **Spring Boot**, **Micronaut**, and **Helidon**. The project showcases how the same business logic and endpoints can be ported and deployed using different technologies, with Docker-based orchestration for local development and testing.

## Architecture Overview

The project is organized into multiple subfolders, each representing a different approach to running the Host Info application:

- **standard-wls-deployment**: The original Java EE application running on WebLogic Server.
- **springboot-port**: The application ported to Spring Boot.
- **micronaut-port**: The application ported to Micronaut.
- **helidon-port**: The application ported to Helidon.

Each port exposes the same set of REST endpoints and provides a simple static HTML UI for navigation, as well as an OpenAPI/Swagger UI for API documentation and testing.

### Directory Structure

```
WLS_WORKSHOP/
  main/
    hello-wls/
      standard-wls-deployment/   # Legacy WLS Java EE app
      springboot-port/           # Spring Boot port
      micronaut-port/            # Micronaut port
      helidon-port/              # Helidon port
```

## Deployment & Orchestration

All modernized ports (Spring Boot, Micronaut, Helidon) include:
- **Dockerfile**: For containerizing the application.
- **docker-compose.yml**: For orchestrating the app and its dependencies (e.g., database) locally.
- **build.sh**: Unified build and deployment script supporting options like `--compose-up`, `--compose-down`, and more.

### General Workflow
1. **Build and Start**: Use `./build.sh --compose-up` in the desired port directory to build and start the app with Docker Compose.
2. **Stop and Clean Up**: Use `./build.sh --compose-down` to stop and remove containers and networks.
3. **Accessing the App**: Each app exposes endpoints and a static UI, typically at `http://localhost:<port>/hostinfo/`.

## Endpoints & Features
- `/api/host-info`         — Host information
- `/api/database-info`     — Database connection info
- `/api/session-info`      — Session details
- `/api/greet`            — Greeting endpoint
- `/api/welcome`          — Welcome message
- `/api/service-info`     — Service metadata
- `/openapi`              — OpenAPI YAML/JSON
- `/swagger-ui.html` or `/swagger-ui.html` — Swagger UI web interface
- `/` or `/index.html`    — Static HTML UI for navigation

## Modernization Paths

- **Spring Boot**: [springboot-port/README.md](main/hello-wls/springboot-port/README.md)
- **Micronaut**: [micronaut-port/README.md](main/hello-wls/micronaut-port/README.md)
- **Helidon**: [helidon-port/README.md](main/hello-wls/helidon-port/README.md)
- **Legacy WLS**: [standard-wls-deployment/README.md](main/hello-wls/standard-wls-deployment/README.md)

Each subproject contains its own README with detailed instructions for building, running, and exploring the specific port.

## Additional Resources
- **docs/**: Contains migration guides, setup instructions, and summaries for each port.
- **wallet/**: (If present) Contains database wallet files for secure DB connectivity.

## Getting Started

1. Clone the repository and navigate to the desired port directory.
2. Review the specific README for prerequisites and instructions.
3. Use the provided scripts and Docker Compose files to build and run the application.

---

For more details, see the README in each subproject:
- [Spring Boot Port](main/hello-wls/springboot-port/README.md)
- [Micronaut Port](main/hello-wls/micronaut-port/README.md)
- [Helidon Port](main/hello-wls/helidon-port/README.md)
- [Standard WLS Deployment](main/hello-wls/standard-wls-deployment/README.md)
