package com.oracle.demo.service;

import jakarta.inject.Singleton;

import java.util.Date;

/**
 * Greeting service implementation
 * Migrated from GreetingServiceBean (Stateless EJB) to Micronaut @Singleton
 */
@Singleton
public class GreetingService {

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
        return "Welcome to Micronaut Application. Current time: " + new Date().toString();
    }

    /**
     * Get service information
     * 
     * @return Information about the service
     */
    public String getServiceInfo() {
        return "GreetingService v1.0 - A Micronaut service running with embedded Netty";
    }
}
