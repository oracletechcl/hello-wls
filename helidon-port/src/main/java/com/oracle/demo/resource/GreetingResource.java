package com.oracle.demo.resource;

import com.oracle.demo.model.GreetingResponse;
import com.oracle.demo.service.GreetingServiceImpl;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.media.Content;
import org.eclipse.microprofile.openapi.annotations.media.Schema;
import org.eclipse.microprofile.openapi.annotations.parameters.Parameter;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

/**
 * JAX-RS Resource for greeting operations
 * Migrated from WebServiceDemoServlet and EJB @WebService to Helidon MP JAX-RS REST
 * 
 * Before (WebLogic EJB + SOAP):
 *   @Stateless
 *   @WebService(name = "GreetingService", ...)
 *   public class GreetingServiceBean
 * 
 * After (Helidon MP REST):
 *   @Path("/api/greet")
 *   public class GreetingResource with @Inject CDI service
 */
@Path("/api/greet")
@RequestScoped
@Tag(name = "Greeting Service", description = "APIs for greeting operations (migrated from SOAP to REST)")
public class GreetingResource {

    @Inject
    private GreetingServiceImpl greetingService;

    /**
     * Get a greeting message
     * 
     * @param name Optional name to greet
     * @return GreetingResponse with message
     */
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(
        summary = "Get greeting",
        description = "Returns a personalized greeting message"
    )
    @APIResponse(
        responseCode = "200",
        description = "Greeting retrieved successfully",
        content = @Content(
            mediaType = MediaType.APPLICATION_JSON,
            schema = @Schema(implementation = GreetingResponse.class)
        )
    )
    public GreetingResponse greet(
            @Parameter(description = "Name to greet", required = false)
            @QueryParam("name") String name) {
        return greetingService.getGreetingResponse(name);
    }

    /**
     * Get welcome message
     * 
     * @return Welcome message with timestamp
     */
    @GET
    @Path("/welcome")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(
        summary = "Get welcome message",
        description = "Returns a welcome message with timestamp"
    )
    @APIResponse(
        responseCode = "200",
        description = "Welcome message retrieved successfully",
        content = @Content(
            mediaType = MediaType.APPLICATION_JSON,
            schema = @Schema(implementation = GreetingResponse.class)
        )
    )
    public GreetingResponse getWelcomeMessage() {
        GreetingResponse response = new GreetingResponse(greetingService.getWelcomeMessage());
        response.setServiceInfo(greetingService.getServiceInfo());
        return response;
    }

    /**
     * Get service info
     * 
     * @return Service information
     */
    @GET
    @Path("/info")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(
        summary = "Get service information",
        description = "Returns information about the greeting service"
    )
    @APIResponse(
        responseCode = "200",
        description = "Service info retrieved successfully",
        content = @Content(
            mediaType = MediaType.APPLICATION_JSON,
            schema = @Schema(implementation = GreetingResponse.class)
        )
    )
    public GreetingResponse getServiceInfo() {
        GreetingResponse response = new GreetingResponse();
        response.setServiceInfo(greetingService.getServiceInfo());
        response.setTimestamp(java.time.Instant.now().toString());
        return response;
    }
}
