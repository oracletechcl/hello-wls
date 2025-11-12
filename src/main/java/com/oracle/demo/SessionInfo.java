package com.oracle.demo;

import java.io.Serializable;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * Session information class that holds session data and metadata.
 * Implements Serializable for session replication in clustered environments.
 */
public class SessionInfo implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    private String sessionId;
    private Date creationTime;
    private Date lastAccessedTime;
    private int maxInactiveInterval;
    private boolean isNew;
    private long visitCount;
    private String userName;
    private Map<String, Object> attributes;
    
    // Session statistics
    private String primaryServerNode;
    private String secondaryServerNode;
    private boolean isReplicated;
    
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
    
    public Date getCreationTime() {
        return creationTime;
    }
    
    public void setCreationTime(Date creationTime) {
        this.creationTime = creationTime;
    }
    
    public Date getLastAccessedTime() {
        return lastAccessedTime;
    }
    
    public void setLastAccessedTime(Date lastAccessedTime) {
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
    
    public String getPrimaryServerNode() {
        return primaryServerNode;
    }
    
    public void setPrimaryServerNode(String primaryServerNode) {
        this.primaryServerNode = primaryServerNode;
    }
    
    public String getSecondaryServerNode() {
        return secondaryServerNode;
    }
    
    public void setSecondaryServerNode(String secondaryServerNode) {
        this.secondaryServerNode = secondaryServerNode;
    }
    
    public boolean isReplicated() {
        return isReplicated;
    }
    
    public void setReplicated(boolean isReplicated) {
        this.isReplicated = isReplicated;
    }
    
    /**
     * Calculate session age in seconds
     */
    public long getSessionAge() {
        if (creationTime == null) {
            return 0;
        }
        return (System.currentTimeMillis() - creationTime.getTime()) / 1000;
    }
    
    /**
     * Calculate idle time in seconds
     */
    public long getIdleTime() {
        if (lastAccessedTime == null) {
            return 0;
        }
        return (System.currentTimeMillis() - lastAccessedTime.getTime()) / 1000;
    }
    
    /**
     * Calculate remaining time before session timeout
     */
    public long getRemainingTime() {
        long idleTime = getIdleTime();
        long maxIdle = maxInactiveInterval;
        return Math.max(0, maxIdle - idleTime);
    }
}
