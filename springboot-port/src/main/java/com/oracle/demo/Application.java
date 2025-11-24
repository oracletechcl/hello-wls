package com.oracle.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.data.jdbc.JdbcRepositoriesAutoConfiguration;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

/**
 * Main Spring Boot application class
 * Migrated from WebLogic Server 12.2.1.4 WAR to Spring Boot 3.x JAR
 * 
 * Note: DataSource auto-configuration is excluded by default to support mock mode.
 * To enable database connectivity, set MOCK_MODE=false and provide valid database credentials.
 */
@SpringBootApplication(exclude = {DataSourceAutoConfiguration.class, JdbcRepositoriesAutoConfiguration.class})
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
