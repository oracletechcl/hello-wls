package com.oracle.demo.model;

/**
 * Data Transfer Object for greeting responses
 * Migrated from WebLogic SOAP to Helidon MP REST
 */
public class GreetingResponse {
    
    private String message;
    private String timestamp;
    private String serviceInfo;

    public GreetingResponse() {
    }

    public GreetingResponse(String message) {
        this.message = message;
        this.timestamp = java.time.Instant.now().toString();
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }

    public String getServiceInfo() {
        return serviceInfo;
    }

    public void setServiceInfo(String serviceInfo) {
        this.serviceInfo = serviceInfo;
    }
}
