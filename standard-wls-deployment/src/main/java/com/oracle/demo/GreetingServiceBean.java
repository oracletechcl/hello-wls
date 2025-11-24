package com.oracle.demo;

import javax.ejb.Stateless;
import javax.jws.WebMethod;
import javax.jws.WebParam;
import javax.jws.WebService;

/**
 * Stateless Session Bean that exposes a web service operation.
 * Demonstrates EJB 3.x with JAX-WS web services in WebLogic Server.
 */
@Stateless
@WebService(
    name = "GreetingService",
    serviceName = "GreetingService",
    targetNamespace = "http://demo.oracle.com/",
    portName = "GreetingServicePort"
)
public class GreetingServiceBean implements GreetingService {
    
    /**
     * Web service operation that greets a user by name.
     * 
     * @param name The name of the person to greet
     * @return A greeting message in the format "Hello, {name}!"
     */
    @WebMethod(operationName = "greet")
    public String greet(@WebParam(name = "name") String name) {
        if (name == null || name.trim().isEmpty()) {
            return "Hello, Guest!";
        }
        return "Hello, " + name.trim() + "!";
    }
    
    /**
     * Additional web service operation to demonstrate multiple methods.
     * Returns a personalized welcome message with timestamp.
     * 
     * @return A detailed welcome message
     */
    @WebMethod(operationName = "getWelcomeMessage")
    public String getWelcomeMessage() {
        return "Welcome to WebLogic Server. Current time: " + 
               new java.util.Date().toString();
    }
    
    /**
     * Web service operation that returns service information.
     * 
     * @return Information about the web service
     */
    @WebMethod(operationName = "getServiceInfo")
    public String getServiceInfo() {
        return "GreetingService v1.0 - A stateless session bean web service running on WebLogic Server 12.2.1.4";
    }
}
