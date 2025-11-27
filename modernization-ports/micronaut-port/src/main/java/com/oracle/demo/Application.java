package com.oracle.demo;

import io.micronaut.runtime.Micronaut;
import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;

/**
 * Main Micronaut application class
 * Migrated from WebLogic Server 12.2.1.4 WAR to Micronaut JAR
 * 
 * Note: Database connectivity is optional. Set app.database.mock-mode to false
 * and provide valid database credentials to enable real database connections.
 */
@OpenAPIDefinition(
    info = @Info(
        title = "Host Information API",
        version = "1.0.0",
        description = "A Micronaut application migrated from WebLogic Server"
    )
)
public class Application {

    public static void main(String[] args) {
        Micronaut.run(Application.class, args);
    }
}
