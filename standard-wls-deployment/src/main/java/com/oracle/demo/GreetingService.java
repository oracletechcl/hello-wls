package com.oracle.demo;

import javax.ejb.Local;

/**
 * Local business interface for the Greeting Service EJB.
 * This interface defines the contract for greeting operations.
 */
@Local
public interface GreetingService {
    
    /**
     * Returns a personalized greeting message.
     * 
     * @param name The name to greet
     * @return A greeting message in the format "Hello, {name}!"
     */
    String greet(String name);
    
    /**
     * Returns a welcome message with timestamp.
     * 
     * @return A welcome message with the current timestamp
     */
    String getWelcomeMessage();
    
    /**
     * Returns information about this service.
     * 
     * @return Service information including name and version
     */
    String getServiceInfo();
}
