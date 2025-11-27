package com.oracle.demo.resource;

import com.oracle.demo.model.DatabaseInfo;
import com.oracle.demo.service.DatabaseService;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.media.Content;
import org.eclipse.microprofile.openapi.annotations.media.Schema;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

/**
 * JAX-RS Resource for database information
 * Migrated from DatabaseInfoServlet to Helidon MP JAX-RS
 * 
 * Before (WebLogic Servlet):
 *   @WebServlet("/database")
 *   public class DatabaseInfoServlet extends HttpServlet
 *   - Used Oracle UCP for connection pooling
 * 
 * After (Helidon MP JAX-RS):
 *   @Path("/api/database-info")
 *   public class DatabaseResource
 *   - Uses HikariCP for connection pooling
 */
@Path("/api/database-info")
@RequestScoped
@Tag(name = "Database Information", description = "APIs for database connectivity and information")
public class DatabaseResource {

    @Inject
    private DatabaseService databaseService;

    /**
     * Get database connection information
     * 
     * @return DatabaseInfo containing connection status and details
     */
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(
        summary = "Get database information",
        description = "Returns database connection status, configuration, and pool statistics"
    )
    @APIResponse(
        responseCode = "200",
        description = "Database information retrieved successfully",
        content = @Content(
            mediaType = MediaType.APPLICATION_JSON,
            schema = @Schema(implementation = DatabaseInfo.class)
        )
    )
    public DatabaseInfo getDatabaseInfo() {
        return databaseService.getDatabaseInfo();
    }

    /**
     * Test database connectivity
     * 
     * @return Connection test result
     */
    @GET
    @Path("/test")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(
        summary = "Test database connection",
        description = "Tests the database connection and returns the result"
    )
    @APIResponse(
        responseCode = "200",
        description = "Connection test completed",
        content = @Content(
            mediaType = MediaType.APPLICATION_JSON,
            schema = @Schema(implementation = DatabaseInfo.class)
        )
    )
    public DatabaseInfo testConnection() {
        return databaseService.getDatabaseInfo();
    }
}
