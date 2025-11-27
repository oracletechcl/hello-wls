package com.oracle.demo.resource;

import com.oracle.demo.model.SessionInfo;
import com.oracle.demo.service.SessionService;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.media.Content;
import org.eclipse.microprofile.openapi.annotations.media.Schema;
import org.eclipse.microprofile.openapi.annotations.parameters.Parameter;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.Map;

/**
 * JAX-RS Resource for session management
 * Migrated from SessionManagerServlet to Helidon MP JAX-RS
 * 
 * Before (WebLogic Servlet):
 *   @WebServlet("/session")
 *   public class SessionManagerServlet extends HttpServlet
 *   - Used HttpSession with WebLogic in-memory replication
 * 
 * After (Helidon MP JAX-RS):
 *   @Path("/api/session-info")
 *   public class SessionResource
 *   - Uses CDI SessionService (can be backed by JWT, Redis, etc.)
 * 
 * Note: For production, consider:
 *   - JWT tokens for stateless authentication
 *   - Redis/Hazelcast for distributed session storage
 *   - Database-backed sessions for persistence
 */
@Path("/api/session-info")
@RequestScoped
@Tag(name = "Session Management", description = "APIs for session management")
public class SessionResource {

    private static final String ERROR_SESSION_NOT_FOUND = "Session not found";

    @Inject
    private SessionService sessionService;

    /**
     * Get or create a session
     * 
     * @param sessionId Optional existing session ID
     * @return SessionInfo with session details
     */
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(
        summary = "Get or create session",
        description = "Returns session information, creating a new session if needed"
    )
    @APIResponse(
        responseCode = "200",
        description = "Session information retrieved successfully",
        content = @Content(
            mediaType = MediaType.APPLICATION_JSON,
            schema = @Schema(implementation = SessionInfo.class)
        )
    )
    public SessionInfo getOrCreateSession(
            @Parameter(description = "Existing session ID", required = false)
            @QueryParam("sessionId") String sessionId) {
        return sessionService.getOrCreateSession(sessionId);
    }

    /**
     * Get session by ID
     * 
     * @param sessionId Session ID
     * @return SessionInfo or 404 if not found
     */
    @GET
    @Path("/{sessionId}")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(
        summary = "Get session by ID",
        description = "Returns session information for the specified session ID"
    )
    @APIResponse(
        responseCode = "200",
        description = "Session found",
        content = @Content(
            mediaType = MediaType.APPLICATION_JSON,
            schema = @Schema(implementation = SessionInfo.class)
        )
    )
    @APIResponse(
        responseCode = "404",
        description = "Session not found"
    )
    public Response getSession(
            @Parameter(description = "Session ID", required = true)
            @PathParam("sessionId") String sessionId) {
        SessionInfo session = sessionService.getSession(sessionId);
        if (session == null) {
            return buildSessionNotFoundResponse(sessionId);
        }
        return Response.ok(session).build();
    }

    /**
     * Set session attribute
     * 
     * @param sessionId Session ID
     * @param key Attribute key
     * @param value Attribute value
     * @return Updated SessionInfo
     */
    @PUT
    @Path("/{sessionId}/attribute")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(
        summary = "Set session attribute",
        description = "Sets a custom attribute on the session"
    )
    @APIResponse(
        responseCode = "200",
        description = "Attribute set successfully",
        content = @Content(
            mediaType = MediaType.APPLICATION_JSON,
            schema = @Schema(implementation = SessionInfo.class)
        )
    )
    public Response setAttribute(
            @Parameter(description = "Session ID", required = true)
            @PathParam("sessionId") String sessionId,
            @Parameter(description = "Attribute key", required = true)
            @QueryParam("key") String key,
            @Parameter(description = "Attribute value", required = true)
            @QueryParam("value") String value) {
        
        sessionService.setAttribute(sessionId, key, value);
        SessionInfo session = sessionService.getSession(sessionId);
        
        if (session == null) {
            return buildSessionNotFoundResponse(sessionId);
        }
        
        return Response.ok(session).build();
    }

    /**
     * Set username for session
     * 
     * @param sessionId Session ID
     * @param userName Username to set
     * @return Updated SessionInfo
     */
    @POST
    @Path("/{sessionId}/user")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(
        summary = "Set session username",
        description = "Sets the username for the session"
    )
    @APIResponse(
        responseCode = "200",
        description = "Username set successfully",
        content = @Content(
            mediaType = MediaType.APPLICATION_JSON,
            schema = @Schema(implementation = SessionInfo.class)
        )
    )
    public Response setUserName(
            @Parameter(description = "Session ID", required = true)
            @PathParam("sessionId") String sessionId,
            @Parameter(description = "Username", required = true)
            @QueryParam("userName") String userName) {
        
        sessionService.setUserName(sessionId, userName);
        SessionInfo session = sessionService.getSession(sessionId);
        
        if (session == null) {
            return buildSessionNotFoundResponse(sessionId);
        }
        
        return Response.ok(session).build();
    }

    /**
     * Invalidate session
     * 
     * @param sessionId Session ID to invalidate
     * @return Success response
     */
    @DELETE
    @Path("/{sessionId}")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(
        summary = "Invalidate session",
        description = "Invalidates and removes the session"
    )
    @APIResponse(
        responseCode = "200",
        description = "Session invalidated successfully"
    )
    public Response invalidateSession(
            @Parameter(description = "Session ID", required = true)
            @PathParam("sessionId") String sessionId) {
        
        sessionService.invalidateSession(sessionId);
        return Response.ok(Map.of(
                "message", "Session invalidated",
                "sessionId", sessionId
        )).build();
    }

    /**
     * Build a session not found error response
     * 
     * @param sessionId The session ID that was not found
     * @return Response with 404 status and error details
     */
    private Response buildSessionNotFoundResponse(String sessionId) {
        return Response.status(Response.Status.NOT_FOUND)
                .entity(Map.of("error", ERROR_SESSION_NOT_FOUND, "sessionId", sessionId))
                .build();
    }
}
