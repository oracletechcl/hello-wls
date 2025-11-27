package com.oracle.demo.controller;

import com.oracle.demo.model.DatabaseInfo;
import com.oracle.demo.service.DatabaseService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for database operations
 * Migrated from DatabaseInfoServlet
 */
@RestController
@RequestMapping("/api")
@Tag(name = "Database", description = "APIs for database connection and testing")
public class DatabaseController {

    @Autowired
    private DatabaseService databaseService;

    @GetMapping("/database-info")
    @Operation(summary = "Get database information", description = "Tests database connectivity and returns connection information")
    public DatabaseInfo getDatabaseInfo() {
        return databaseService.testConnection();
    }
}
