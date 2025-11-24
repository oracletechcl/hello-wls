package com.oracle.demo.controller;

import com.oracle.demo.service.GreetingServiceImpl;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * REST controller for greeting operations
 * Migrated from GreetingServiceBean (EJB/JAX-WS) to REST
 */
@RestController
@RequestMapping("/api")
@Tag(name = "Greeting", description = "APIs for greeting and welcome messages")
public class GreetingController {

    @Autowired
    private GreetingServiceImpl greetingService;

    @GetMapping("/greet")
    @Operation(summary = "Greet a user", description = "Returns a personalized greeting message")
    public Map<String, String> greet(@RequestParam(required = false, defaultValue = "Guest") String name) {
        Map<String, String> response = new HashMap<>();
        response.put("message", greetingService.greet(name));
        return response;
    }

    @GetMapping("/welcome")
    @Operation(summary = "Get welcome message", description = "Returns a welcome message with current timestamp")
    public Map<String, String> getWelcomeMessage() {
        Map<String, String> response = new HashMap<>();
        response.put("message", greetingService.getWelcomeMessage());
        return response;
    }

    @GetMapping("/service-info")
    @Operation(summary = "Get service information", description = "Returns information about the greeting service")
    public Map<String, String> getServiceInfo() {
        Map<String, String> response = new HashMap<>();
        response.put("info", greetingService.getServiceInfo());
        return response;
    }
}
