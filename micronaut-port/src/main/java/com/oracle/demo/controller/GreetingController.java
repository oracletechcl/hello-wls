package com.oracle.demo.controller;

import com.oracle.demo.service.GreetingService;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.QueryValue;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.inject.Inject;

import java.util.HashMap;
import java.util.Map;

/**
 * REST controller for greeting operations
 * Migrated from GreetingServiceBean (EJB/JAX-WS) to REST
 */
@Controller("/api")
@Tag(name = "Greeting", description = "APIs for greeting and welcome messages")
public class GreetingController {

    private final GreetingService greetingService;

    @Inject
    public GreetingController(GreetingService greetingService) {
        this.greetingService = greetingService;
    }

    @Get("/greet")
    @Operation(summary = "Greet a user", description = "Returns a personalized greeting message")
    public Map<String, String> greet(@QueryValue(defaultValue = "Guest") String name) {
        Map<String, String> response = new HashMap<>();
        response.put("message", greetingService.greet(name));
        return response;
    }

    @Get("/welcome")
    @Operation(summary = "Get welcome message", description = "Returns a welcome message with current timestamp")
    public Map<String, String> getWelcomeMessage() {
        Map<String, String> response = new HashMap<>();
        response.put("message", greetingService.getWelcomeMessage());
        return response;
    }

    @Get("/service-info")
    @Operation(summary = "Get service information", description = "Returns information about the greeting service")
    public Map<String, String> getServiceInfo() {
        Map<String, String> response = new HashMap<>();
        response.put("info", greetingService.getServiceInfo());
        return response;
    }
}
