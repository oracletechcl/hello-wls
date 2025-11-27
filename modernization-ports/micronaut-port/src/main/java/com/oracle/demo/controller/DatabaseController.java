package com.oracle.demo.controller;

import com.oracle.demo.model.DatabaseInfo;
import com.oracle.demo.service.DatabaseService;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.inject.Inject;

/**
 * REST controller for database operations
 * Migrated from DatabaseInfoServlet
 */
@Controller("/api")
@Tag(name = "Database", description = "APIs for database connection and testing")
public class DatabaseController {

    private final DatabaseService databaseService;

    @Inject
    public DatabaseController(DatabaseService databaseService) {
        this.databaseService = databaseService;
    }

    @Get("/database-info")
    @Operation(summary = "Get database information", description = "Tests database connectivity and returns connection information")
    public DatabaseInfo getDatabaseInfo() {
        return databaseService.testConnection();
    }
}
