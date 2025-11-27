package com.oracle.demo.controller;

import com.oracle.demo.model.SessionInfo;
import io.micronaut.http.annotation.*;
import io.micronaut.session.Session;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import java.net.InetAddress;
import java.time.Instant;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * REST controller for session management
 * Migrated from SessionManagerServlet
 */
@Controller("/api")
@Tag(name = "Session", description = "APIs for HTTP session management")
public class SessionController {

    private static final String VISIT_COUNT_ATTR = "visitCount";
    private static final String USER_NAME_ATTR = "userName";

    @Get("/session-info")
    @Operation(summary = "Get session information", description = "Returns information about the current HTTP session")
    public SessionInfo getSessionInfo(Session session) {
        // Track visit count
        Long visitCount = session.get(VISIT_COUNT_ATTR, Long.class).orElse(0L);
        visitCount++;
        session.put(VISIT_COUNT_ATTR, visitCount);
        
        return collectSessionInfo(session);
    }

    @Post("/session-data")
    @Operation(summary = "Set session data", description = "Sets custom attributes in the session")
    public SessionInfo setSessionData(
            @QueryValue(defaultValue = "") String userName,
            @QueryValue(defaultValue = "") String customKey,
            @QueryValue(defaultValue = "") String customValue,
            Session session) {
        
        if (userName != null && !userName.trim().isEmpty()) {
            session.put(USER_NAME_ATTR, userName.trim());
        }
        
        if (customKey != null && !customKey.trim().isEmpty() &&
            customValue != null && !customValue.trim().isEmpty()) {
            session.put(customKey.trim(), customValue.trim());
        }
        
        return collectSessionInfo(session);
    }

    @Delete("/session")
    @Operation(summary = "Invalidate session", description = "Invalidates the current HTTP session")
    public Map<String, String> invalidateSession(Session session) {
        session.clear();
        
        Map<String, String> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Session invalidated");
        return response;
    }

    private SessionInfo collectSessionInfo(Session session) {
        SessionInfo info = new SessionInfo();
        
        info.setSessionId(session.getId());
        
        Instant creationTime = session.getCreationTime();
        info.setCreationTime(Date.from(creationTime));
        
        Instant lastAccessedTime = session.getLastAccessedTime();
        info.setLastAccessedTime(Date.from(lastAccessedTime));
        
        int maxInactiveSeconds = (int) session.getMaxInactiveInterval().getSeconds();
        info.setMaxInactiveInterval(maxInactiveSeconds);
        info.setNew(session.isNew());
        
        Long visitCount = session.get(VISIT_COUNT_ATTR, Long.class).orElse(0L);
        info.setVisitCount(visitCount);
        
        String userName = session.get(USER_NAME_ATTR, String.class).orElse(null);
        info.setUserName(userName);
        
        // Get server information
        try {
            InetAddress localhost = InetAddress.getLocalHost();
            info.setServerNode("Micronaut (" + localhost.getHostName() + ")");
        } catch (Exception e) {
            info.setServerNode("Micronaut");
        }
        
        // Collect all session attributes
        Map<String, Object> attributes = new HashMap<>();
        for (String key : session.names()) {
            session.get(key, Object.class).ifPresent(value -> attributes.put(key, value));
        }
        info.setAttributes(attributes);
        
        // Calculate session timing
        long now = System.currentTimeMillis();
        long creationTimeMs = creationTime.toEpochMilli();
        long lastAccessedTimeMs = lastAccessedTime.toEpochMilli();
        
        info.setSessionAge((now - creationTimeMs) / 1000);
        info.setIdleTime((now - lastAccessedTimeMs) / 1000);
        info.setRemainingTime(maxInactiveSeconds - info.getIdleTime());
        
        return info;
    }
}
