package com.oracle.demo.service;

import com.oracle.demo.model.DatabaseInfo;
import io.micronaut.context.annotation.Property;
import io.micronaut.context.annotation.Value;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Optional;

/**
 * Service for database operations
 * Migrated from DatabaseConnectionManager and uses Micronaut's DataSource
 */
@Singleton
public class DatabaseService {

    private final Optional<DataSource> dataSource;

    @Value("${datasources.default.url:}")
    private String databaseUrl;

    @Value("${datasources.default.username:}")
    private String username;

    @Value("${app.database.mock-mode:true}")
    private boolean mockMode;

    @Value("${app.database.service-name:}")
    private String serviceName;

    @Value("${app.database.wallet-location:}")
    private String walletLocation;

    @Inject
    public DatabaseService(Optional<DataSource> dataSource) {
        this.dataSource = dataSource;
    }

    public DatabaseInfo testConnection() {
        DatabaseInfo info = new DatabaseInfo();
        info.setMockMode(mockMode);
        info.setConfigured(dataSource.isPresent());
        info.setDatabaseUrl(databaseUrl);
        info.setUsername(username);
        info.setServiceName(serviceName);
        info.setWalletLocation(walletLocation);

        if (mockMode) {
            info.setStatus("MOCK MODE");
            info.setMessage("Application is running in mock mode. Configure real ADB credentials to connect.");
            return info;
        }

        if (dataSource.isEmpty()) {
            info.setStatus("NOT CONFIGURED");
            info.setMessage("DataSource is not configured");
            return info;
        }

        try (Connection conn = dataSource.get().getConnection()) {
            info.setStatus("CONNECTED");
            info.setMessage("Successfully connected to Oracle Autonomous Database");
            
            // Get database metadata
            info.setDatabaseProductName(conn.getMetaData().getDatabaseProductName());
            info.setDatabaseProductVersion(conn.getMetaData().getDatabaseProductVersion());
            info.setDriverName(conn.getMetaData().getDriverName());
            info.setDriverVersion(conn.getMetaData().getDriverVersion());
            
            // Test query
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT SYSDATE FROM DUAL")) {
                if (rs.next()) {
                    info.setTestQueryResult(rs.getTimestamp(1).toString());
                }
            }
            
            // Pool statistics
            info.setPoolStatistics("Using HikariCP connection pool");
            
        } catch (Exception e) {
            info.setStatus("ERROR");
            info.setMessage("Failed to connect: " + e.getMessage());
            info.setError(e.toString());
        }

        return info;
    }
}
