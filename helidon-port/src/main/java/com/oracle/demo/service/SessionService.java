package com.oracle.demo.service;

import com.oracle.demo.model.SessionInfo;
import jakarta.enterprise.context.ApplicationScoped;

import java.net.InetAddress;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * CDI Service for session management
 * Migrated from WebLogic HttpSession to Helidon MP
 * 
 * Note: For production use with JWT tokens or external session store (Redis/DB),
 * this simple in-memory implementation can be replaced.
 * 
 * Before (WebLogic):
 *   - HttpSession with in-memory replication
 *   - weblogic.xml session-descriptor
 * 
 * After (Helidon MP):
 *   - CDI managed session service
 *   - Consider JWT tokens for stateless architecture
 *   - Or external session store for clustering
 */
@ApplicationScoped
public class SessionService {
    
    private static final Logger LOGGER = Logger.getLogger(SessionService.class.getName());
    private static final int DEFAULT_MAX_INACTIVE_INTERVAL = 1800; // 30 minutes
    
    // Simple in-memory session store (for demo purposes)
    // In production, use Redis, database, or JWT tokens
    private final Map<String, InternalSession> sessions = new ConcurrentHashMap<>();
    
    /**
     * Get or create a session
     */
    public SessionInfo getOrCreateSession(String sessionId) {
        InternalSession internalSession;
        boolean isNew = false;
        
        if (sessionId == null || !sessions.containsKey(sessionId)) {
            sessionId = UUID.randomUUID().toString();
            internalSession = new InternalSession(sessionId);
            sessions.put(sessionId, internalSession);
            isNew = true;
            LOGGER.info("Created new session: " + sessionId);
        } else {
            internalSession = sessions.get(sessionId);
            internalSession.touch();
        }
        
        internalSession.incrementVisitCount();
        
        return buildSessionInfo(internalSession, isNew);
    }
    
    /**
     * Get session by ID
     */
    public SessionInfo getSession(String sessionId) {
        if (sessionId == null || !sessions.containsKey(sessionId)) {
            return null;
        }
        
        InternalSession internalSession = sessions.get(sessionId);
        internalSession.touch();
        
        return buildSessionInfo(internalSession, false);
    }
    
    /**
     * Set session attribute
     */
    public void setAttribute(String sessionId, String key, Object value) {
        if (sessionId != null && sessions.containsKey(sessionId)) {
            sessions.get(sessionId).setAttribute(key, value);
        }
    }
    
    /**
     * Set username for session
     */
    public void setUserName(String sessionId, String userName) {
        if (sessionId != null && sessions.containsKey(sessionId)) {
            sessions.get(sessionId).setUserName(userName);
        }
    }
    
    /**
     * Remove session attribute
     */
    public void removeAttribute(String sessionId, String key) {
        if (sessionId != null && sessions.containsKey(sessionId)) {
            sessions.get(sessionId).removeAttribute(key);
        }
    }
    
    /**
     * Invalidate session
     */
    public void invalidateSession(String sessionId) {
        if (sessionId != null) {
            sessions.remove(sessionId);
            LOGGER.info("Invalidated session: " + sessionId);
        }
    }
    
    /**
     * Build SessionInfo DTO from internal session
     */
    private SessionInfo buildSessionInfo(InternalSession internal, boolean isNew) {
        SessionInfo info = new SessionInfo();
        info.setSessionId(internal.getId());
        info.setCreationTime(internal.getCreationTime().toString());
        info.setLastAccessedTime(internal.getLastAccessedTime().toString());
        info.setMaxInactiveInterval(DEFAULT_MAX_INACTIVE_INTERVAL);
        info.setNew(isNew);
        info.setVisitCount(internal.getVisitCount());
        info.setUserName(internal.getUserName());
        info.setAttributes(internal.getAttributes());
        
        // Calculate times
        long sessionAge = ChronoUnit.SECONDS.between(internal.getCreationTime(), Instant.now());
        long idleTime = ChronoUnit.SECONDS.between(internal.getLastAccessedTime(), Instant.now());
        long remainingTime = Math.max(0, DEFAULT_MAX_INACTIVE_INTERVAL - idleTime);
        
        info.setSessionAgeSeconds(sessionAge);
        info.setIdleTimeSeconds(idleTime);
        info.setRemainingTimeSeconds(remainingTime);
        
        // Server node info
        try {
            InetAddress localhost = InetAddress.getLocalHost();
            info.setServerNode("Helidon MP (" + localhost.getHostName() + ")");
        } catch (Exception e) {
            info.setServerNode("Helidon MP Server");
        }
        
        return info;
    }
    
    /**
     * Internal session representation
     */
    private static class InternalSession {
        private final String id;
        private final Instant creationTime;
        private Instant lastAccessedTime;
        private long visitCount;
        private String userName;
        private final Map<String, Object> attributes = new ConcurrentHashMap<>();
        
        InternalSession(String id) {
            this.id = id;
            this.creationTime = Instant.now();
            this.lastAccessedTime = Instant.now();
            this.visitCount = 0;
        }
        
        void touch() {
            this.lastAccessedTime = Instant.now();
        }
        
        void incrementVisitCount() {
            this.visitCount++;
        }
        
        String getId() {
            return id;
        }
        
        Instant getCreationTime() {
            return creationTime;
        }
        
        Instant getLastAccessedTime() {
            return lastAccessedTime;
        }
        
        long getVisitCount() {
            return visitCount;
        }
        
        String getUserName() {
            return userName;
        }
        
        void setUserName(String userName) {
            this.userName = userName;
        }
        
        Map<String, Object> getAttributes() {
            return attributes;
        }
        
        void setAttribute(String key, Object value) {
            attributes.put(key, value);
        }
        
        void removeAttribute(String key) {
            attributes.remove(key);
        }
    }
}
