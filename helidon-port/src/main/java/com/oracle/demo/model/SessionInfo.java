package com.oracle.demo.model;

import java.util.HashMap;
import java.util.Map;

/**
 * Data Transfer Object for session information
 * Migrated from WebLogic to Helidon MP
 */
public class SessionInfo {
    
    private String sessionId;
    private String creationTime;
    private String lastAccessedTime;
    private int maxInactiveInterval;
    private boolean isNew;
    private long visitCount;
    private String userName;
    private Map<String, Object> attributes;
    private String serverNode;
    private long sessionAgeSeconds;
    private long idleTimeSeconds;
    private long remainingTimeSeconds;

    public SessionInfo() {
        this.attributes = new HashMap<>();
        this.visitCount = 0;
    }

    public String getSessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }

    public String getCreationTime() {
        return creationTime;
    }

    public void setCreationTime(String creationTime) {
        this.creationTime = creationTime;
    }

    public String getLastAccessedTime() {
        return lastAccessedTime;
    }

    public void setLastAccessedTime(String lastAccessedTime) {
        this.lastAccessedTime = lastAccessedTime;
    }

    public int getMaxInactiveInterval() {
        return maxInactiveInterval;
    }

    public void setMaxInactiveInterval(int maxInactiveInterval) {
        this.maxInactiveInterval = maxInactiveInterval;
    }

    public boolean isNew() {
        return isNew;
    }

    public void setNew(boolean isNew) {
        this.isNew = isNew;
    }

    public long getVisitCount() {
        return visitCount;
    }

    public void setVisitCount(long visitCount) {
        this.visitCount = visitCount;
    }

    public void incrementVisitCount() {
        this.visitCount++;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public Map<String, Object> getAttributes() {
        return attributes;
    }

    public void setAttributes(Map<String, Object> attributes) {
        this.attributes = attributes;
    }

    public void addAttribute(String key, Object value) {
        this.attributes.put(key, value);
    }

    public Object getAttribute(String key) {
        return this.attributes.get(key);
    }

    public String getServerNode() {
        return serverNode;
    }

    public void setServerNode(String serverNode) {
        this.serverNode = serverNode;
    }

    public long getSessionAgeSeconds() {
        return sessionAgeSeconds;
    }

    public void setSessionAgeSeconds(long sessionAgeSeconds) {
        this.sessionAgeSeconds = sessionAgeSeconds;
    }

    public long getIdleTimeSeconds() {
        return idleTimeSeconds;
    }

    public void setIdleTimeSeconds(long idleTimeSeconds) {
        this.idleTimeSeconds = idleTimeSeconds;
    }

    public long getRemainingTimeSeconds() {
        return remainingTimeSeconds;
    }

    public void setRemainingTimeSeconds(long remainingTimeSeconds) {
        this.remainingTimeSeconds = remainingTimeSeconds;
    }
}
