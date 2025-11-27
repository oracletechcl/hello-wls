package com.oracle.demo.controller;

import com.oracle.demo.model.SessionInfo;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.web.bind.annotation.*;

import java.net.InetAddress;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

/**
 * REST controller for session management
 * Migrated from SessionManagerServlet
 */
@RestController
@RequestMapping("/api")
@Tag(name = "Session", description = "APIs for HTTP session management")
public class SessionController {

    private static final String VISIT_COUNT_ATTR = "visitCount";
    private static final String USER_NAME_ATTR = "userName";

    @GetMapping("/session-info")
    @Operation(summary = "Get session information", description = "Returns information about the current HTTP session")
    public SessionInfo getSessionInfo(HttpServletRequest request) {
        HttpSession session = request.getSession(true);
        
        // Track visit count
        Long visitCount = (Long) session.getAttribute(VISIT_COUNT_ATTR);
        if (visitCount == null) {
            visitCount = 1L;
        } else {
            visitCount++;
        }
        session.setAttribute(VISIT_COUNT_ATTR, visitCount);
        
        return collectSessionInfo(session, request);
    }

    @PostMapping("/session-data")
    @Operation(summary = "Set session data", description = "Sets custom attributes in the session")
    public SessionInfo setSessionData(
            @RequestParam(required = false) String userName,
            @RequestParam(required = false) String customKey,
            @RequestParam(required = false) String customValue,
            HttpServletRequest request) {
        
        HttpSession session = request.getSession(true);
        
        if (userName != null && !userName.trim().isEmpty()) {
            session.setAttribute(USER_NAME_ATTR, userName.trim());
        }
        
        if (customKey != null && !customKey.trim().isEmpty() &&
            customValue != null && !customValue.trim().isEmpty()) {
            session.setAttribute(customKey.trim(), customValue.trim());
        }
        
        return collectSessionInfo(session, request);
    }

    @DeleteMapping("/session")
    @Operation(summary = "Invalidate session", description = "Invalidates the current HTTP session")
    public Map<String, String> invalidateSession(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        
        Map<String, String> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Session invalidated");
        return response;
    }

    private SessionInfo collectSessionInfo(HttpSession session, HttpServletRequest request) {
        SessionInfo info = new SessionInfo();
        
        info.setSessionId(session.getId());
        info.setCreationTime(new Date(session.getCreationTime()));
        info.setLastAccessedTime(new Date(session.getLastAccessedTime()));
        info.setMaxInactiveInterval(session.getMaxInactiveInterval());
        info.setNew(session.isNew());
        
        Long visitCount = (Long) session.getAttribute(VISIT_COUNT_ATTR);
        info.setVisitCount(visitCount != null ? visitCount : 0);
        
        String userName = (String) session.getAttribute(USER_NAME_ATTR);
        info.setUserName(userName);
        
        // Get server information
        try {
            InetAddress localhost = InetAddress.getLocalHost();
            info.setServerNode("Spring Boot (" + localhost.getHostName() + ")");
        } catch (Exception e) {
            info.setServerNode("Spring Boot");
        }
        
        // Collect all session attributes
        Map<String, Object> attributes = new HashMap<>();
        Enumeration<String> attributeNames = session.getAttributeNames();
        while (attributeNames.hasMoreElements()) {
            String name = attributeNames.nextElement();
            Object value = session.getAttribute(name);
            attributes.put(name, value);
        }
        info.setAttributes(attributes);
        
        // Calculate session timing
        long now = System.currentTimeMillis();
        info.setSessionAge((now - session.getCreationTime()) / 1000);
        info.setIdleTime((now - session.getLastAccessedTime()) / 1000);
        info.setRemainingTime(session.getMaxInactiveInterval() - info.getIdleTime());
        
        return info;
    }
}
