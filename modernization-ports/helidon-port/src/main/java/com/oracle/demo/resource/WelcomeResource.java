package com.oracle.demo.resource;

import com.oracle.demo.service.GreetingServiceImpl;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.json.Json;
import jakarta.json.JsonObject;
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
 * JAX-RS Resource for welcome and service info operations
 * Additional endpoints to match other framework ports (Micronaut, Spring Boot)
 */
@Path("/api")
@RequestScoped
@Tag(name = "Welcome & Info", description = "APIs for welcome messages and service information")
public class WelcomeResource {

    @Inject
    private GreetingServiceImpl greetingService;

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
        description = "Returns a welcome message with current timestamp"
    )
    @APIResponse(
        responseCode = "200",
        description = "Welcome message retrieved successfully",
        content = @Content(
            mediaType = MediaType.APPLICATION_JSON,
            schema = @Schema(implementation = JsonObject.class)
        )
    )
    public JsonObject getWelcomeMessage() {
        return Json.createObjectBuilder()
                .add("message", greetingService.getWelcomeMessage())
                .build();
    }

    /**
     * Get service info
     * 
     * @return Service information
     */
    @GET
    @Path("/service-info")
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
            schema = @Schema(implementation = JsonObject.class)
        )
    )
    public JsonObject getServiceInfo() {
        return Json.createObjectBuilder()
                .add("info", greetingService.getServiceInfo())
                .build();
    }
}
