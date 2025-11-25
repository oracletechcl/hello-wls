package com.oracle.demo.resource;

import com.oracle.demo.model.HostInfo;
import com.oracle.demo.service.HostInfoService;
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
 * JAX-RS Resource for host information
 * Migrated from HostInfoServlet to Helidon MP JAX-RS
 * 
 * Before (WebLogic Servlet):
 *   @WebServlet("/hostinfo")
 *   public class HostInfoServlet extends HttpServlet
 * 
 * After (Helidon MP JAX-RS):
 *   @Path("/api/host-info")
 *   public class HostInfoResource
 */
@Path("/api/host-info")
@RequestScoped
@Tag(name = "Host Information", description = "APIs for retrieving host and server information")
public class HostInfoResource {

    @Inject
    private HostInfoService hostInfoService;

    /**
     * Get comprehensive host information
     * 
     * @return HostInfo containing system, network, and runtime details
     */
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(
        summary = "Get host information",
        description = "Returns detailed information about the host, OS, Java runtime, and memory"
    )
    @APIResponse(
        responseCode = "200",
        description = "Host information retrieved successfully",
        content = @Content(
            mediaType = MediaType.APPLICATION_JSON,
            schema = @Schema(implementation = HostInfo.class)
        )
    )
    public HostInfo getHostInfo() {
        return hostInfoService.getHostInfo();
    }
}
