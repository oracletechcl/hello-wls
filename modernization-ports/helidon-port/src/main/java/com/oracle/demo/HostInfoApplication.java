package com.oracle.demo;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.ApplicationPath;
import jakarta.ws.rs.core.Application;
import org.eclipse.microprofile.openapi.annotations.OpenAPIDefinition;
import org.eclipse.microprofile.openapi.annotations.info.Contact;
import org.eclipse.microprofile.openapi.annotations.info.Info;
import org.eclipse.microprofile.openapi.annotations.info.License;
import org.eclipse.microprofile.openapi.annotations.servers.Server;

/**
 * JAX-RS Application class for Helidon MP
 * Migrated from WebLogic WAR to Helidon MP fat JAR
 * 
 * Before (WebLogic):
 *   - web.xml with servlet mappings
 *   - weblogic.xml with context-root
 *   - Deployed as WAR file
 * 
 * After (Helidon MP):
 *   - JAX-RS Application class with @ApplicationPath
 *   - OpenAPI annotations for documentation
 *   - Runs as executable fat JAR
 */
@ApplicationScoped
@ApplicationPath("/helidon")
@OpenAPIDefinition(
    info = @Info(
        title = "Helidon MP Host Information API",
        version = "1.0.0",
        description = "REST API migrated from WebLogic Server 12.2.1.4 to Helidon MP. " +
                      "Demonstrates migration of Servlets to JAX-RS, EJB to CDI, " +
                      "SOAP to REST, and Oracle UCP to HikariCP.",
        contact = @Contact(
            name = "Oracle Demo",
            url = "https://oracle.com"
        ),
        license = @License(
            name = "Apache 2.0",
            url = "https://www.apache.org/licenses/LICENSE-2.0.html"
        )
    ),
    servers = {
        @Server(url = "/helidon", description = "Local server")
    }
)
public class HostInfoApplication extends Application {
    // Helidon MP automatically discovers JAX-RS resources and CDI beans
    // No explicit registration needed when using bean-discovery-mode="annotated"
}
