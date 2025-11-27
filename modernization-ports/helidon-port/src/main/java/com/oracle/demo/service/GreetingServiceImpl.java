package com.oracle.demo.service;

import com.oracle.demo.model.GreetingResponse;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Date;

/**
 * CDI Service for greeting operations
 * Migrated from GreetingServiceBean (EJB @Stateless) to CDI @ApplicationScoped
 * 
 * Before (WebLogic EJB):
 *   @Stateless
 *   @WebService
 *   public class GreetingServiceBean implements GreetingService
 * 
 * After (Helidon MP CDI):
 *   @ApplicationScoped
 *   public class GreetingServiceImpl
 */
@ApplicationScoped
public class GreetingServiceImpl {

    /**
     * Returns a personalized greeting message
     * 
     * @param name The name to greet
     * @return A greeting message
     */
    public String greet(String name) {
        if (name == null || name.trim().isEmpty()) {
            return "Hello, Guest!";
        }
        return "Hello, " + name.trim() + "!";
    }

    /**
     * Returns a welcome message with timestamp
     * 
     * @return A welcome message with the current timestamp
     */
    public String getWelcomeMessage() {
        return "Welcome to Helidon MP Application. Current time: " + new Date().toString();
    }

    /**
     * Returns information about this service
     * 
     * @return Service information including name and version
     */
    public String getServiceInfo() {
        return "GreetingService v1.0 - A CDI service running on Helidon MP with embedded server";
    }

    /**
     * Returns a full greeting response with timestamp
     * 
     * @param name The name to greet
     * @return GreetingResponse containing message and metadata
     */
    public GreetingResponse getGreetingResponse(String name) {
        GreetingResponse response = new GreetingResponse(greet(name));
        response.setServiceInfo(getServiceInfo());
        return response;
    }
}
