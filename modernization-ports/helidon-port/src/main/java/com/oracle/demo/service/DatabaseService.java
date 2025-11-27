package com.oracle.demo.service;

import com.oracle.demo.model.DatabaseInfo;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * CDI Service for database connectivity using HikariCP
 * Migrated from Oracle UCP to HikariCP for Helidon MP
 * 
 * Before (WebLogic):
 *   - Custom singleton using Oracle UCP
 *   - DatabaseConnectionManager with PoolDataSource
 * 
 * After (Helidon MP):
 *   - CDI @ApplicationScoped bean
 *   - HikariCP connection pool
 *   - MicroProfile Config injection
 */
@ApplicationScoped
public class DatabaseService {
    
    private static final Logger LOGGER = Logger.getLogger(DatabaseService.class.getName());
    
    @Inject
    @ConfigProperty(name = "app.database.mock-mode", defaultValue = "true")
    private boolean mockMode;
    
    @Inject
    @ConfigProperty(name = "app.database.url", defaultValue = "jdbc:oracle:thin:@localhost:1521/mockdb")
    private String databaseUrl;
    
    @Inject
    @ConfigProperty(name = "app.database.username", defaultValue = "ADMIN")
    private String username;
    
    @Inject
    @ConfigProperty(name = "app.database.password", defaultValue = "")
    private String password;
    
    @Inject
    @ConfigProperty(name = "app.database.service-name", defaultValue = "mock_adb_high")
    private String serviceName;
    
    @Inject
    @ConfigProperty(name = "app.database.wallet-location", defaultValue = "")
    private String walletLocation;
    
    @Inject
    @ConfigProperty(name = "app.database.pool.maximum-pool-size", defaultValue = "10")
    private int maxPoolSize;
    
    @Inject
    @ConfigProperty(name = "app.database.pool.minimum-idle", defaultValue = "2")
    private int minIdle;
    
    private HikariDataSource dataSource;
    
    @PostConstruct
    void initialize() {
        LOGGER.info("Initializing database service...");
        LOGGER.info("Mock mode: " + mockMode);
        
        if (!mockMode) {
            initializeConnectionPool();
        } else {
            LOGGER.info("Running in MOCK mode - no real database connection");
        }
    }
    
    @PreDestroy
    void cleanup() {
        if (dataSource != null && !dataSource.isClosed()) {
            LOGGER.info("Closing HikariCP connection pool...");
            dataSource.close();
        }
    }
    
    /**
     * Initialize HikariCP connection pool
     */
    private void initializeConnectionPool() {
        try {
            HikariConfig config = new HikariConfig();
            
            config.setJdbcUrl(databaseUrl);
            config.setUsername(username);
            config.setPassword(password);
            config.setDriverClassName("oracle.jdbc.OracleDriver");
            
            // Pool settings
            config.setMaximumPoolSize(maxPoolSize);
            config.setMinimumIdle(minIdle);
            config.setConnectionTimeout(30000);
            config.setIdleTimeout(600000);
            config.setMaxLifetime(1800000);
            
            // Oracle ADB specific settings
            if (walletLocation != null && !walletLocation.isEmpty()) {
                System.setProperty("oracle.net.tns_admin", walletLocation);
                System.setProperty("oracle.net.wallet_location", walletLocation);
                LOGGER.info("Wallet location set to: " + walletLocation);
            }
            
            config.addDataSourceProperty("oracle.jdbc.fanEnabled", "false");
            
            dataSource = new HikariDataSource(config);
            LOGGER.info("HikariCP connection pool initialized successfully");
            
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error initializing HikariCP pool", e);
        }
    }
    
    /**
     * Get a connection from the pool
     */
    public Connection getConnection() throws SQLException {
        if (mockMode) {
            throw new SQLException("Mock mode enabled - configure real ADB connection");
        }
        if (dataSource == null) {
            throw new SQLException("Connection pool is not initialized");
        }
        return dataSource.getConnection();
    }
    
    /**
     * Test database connectivity and return information
     */
    public DatabaseInfo getDatabaseInfo() {
        DatabaseInfo info = new DatabaseInfo();
        info.setMockMode(mockMode);
        info.setConfigured(dataSource != null || mockMode);
        info.setDatabaseUrl(databaseUrl);
        info.setUsername(username);
        info.setServiceName(serviceName);
        info.setWalletLocation(walletLocation);
        
        if (mockMode) {
            info.setStatus("MOCK MODE");
            info.setMessage("Application is running in mock mode. Configure real ADB credentials to connect.");
            return info;
        }
        
        if (dataSource == null) {
            info.setStatus("NOT CONFIGURED");
            info.setMessage("Connection pool is not initialized");
            return info;
        }
        
        try (Connection conn = dataSource.getConnection()) {
            info.setStatus("CONNECTED");
            info.setMessage("Successfully connected to Oracle Autonomous Database");
            info.setDatabaseProductName(conn.getMetaData().getDatabaseProductName());
            info.setDatabaseProductVersion(conn.getMetaData().getDatabaseProductVersion());
            info.setDriverName(conn.getMetaData().getDriverName());
            info.setDriverVersion(conn.getMetaData().getDriverVersion());
            
            // Pool statistics
            DatabaseInfo.PoolStatistics stats = new DatabaseInfo.PoolStatistics();
            stats.setActiveConnections(dataSource.getHikariPoolMXBean().getActiveConnections());
            stats.setIdleConnections(dataSource.getHikariPoolMXBean().getIdleConnections());
            stats.setTotalConnections(dataSource.getHikariPoolMXBean().getTotalConnections());
            stats.setMaxPoolSize(maxPoolSize);
            info.setPoolStatistics(stats);
            
        } catch (SQLException e) {
            info.setStatus("ERROR");
            info.setMessage("Failed to connect: " + e.getMessage());
            info.setError(e.toString());
        }
        
        return info;
    }
    
    public boolean isMockMode() {
        return mockMode;
    }
}
