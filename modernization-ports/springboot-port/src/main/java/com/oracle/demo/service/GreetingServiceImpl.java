package com.oracle.demo.service;

import org.springframework.stereotype.Service;

import java.util.Date;

/**
 * Greeting service implementation
 * Migrated from GreetingServiceBean (Stateless EJB) to Spring @Service
 */
@Service
public class GreetingServiceImpl {

    /**
     * Greet a user by name
     * 
     * @param name The name of the person to greet
     * @return A greeting message
     */
    public String greet(String name) {
        if (name == null || name.trim().isEmpty()) {
            return "Hello, Guest!";
        }
        return "Hello, " + name.trim() + "!";
    }

    /**
     * Get a welcome message with timestamp
     * 
     * @return A detailed welcome message
     */
    public String getWelcomeMessage() {
        return "Welcome to Spring Boot Application. Current time: " + new Date().toString();
    }

    /**
     * Get service information
     * 
     * @return Information about the service
     */
    public String getServiceInfo() {
        return "GreetingService v1.0 - A Spring Boot service running with embedded Tomcat";
    }
}
