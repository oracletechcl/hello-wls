package com.oracle.demo;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Database connection manager for Oracle Autonomous Database.
 * Uses Universal Connection Pool (UCP) for efficient connection management.
 * Supports both mock mode and real ADB connections.
 */
public class DatabaseConnectionManager {
    
    private static DatabaseConnectionManager instance;
    private PoolDataSource poolDataSource;
    private boolean mockMode;
    
    private DatabaseConnectionManager() {
        try {
            this.mockMode = DatabaseConfig.isMockMode();
            initializeConnectionPool();
        } catch (SQLException e) {
            System.err.println("Error initializing database connection pool: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Get singleton instance of DatabaseConnectionManager
     */
    public static synchronized DatabaseConnectionManager getInstance() {
        if (instance == null) {
            instance = new DatabaseConnectionManager();
        }
        return instance;
    }
    
    /**
     * Initialize the Universal Connection Pool
     */
    private void initializeConnectionPool() throws SQLException {
        System.out.println("Initializing database connection pool...");
        System.out.println("Mock mode: " + mockMode);
        
        if (mockMode) {
            initializeMockPool();
        } else {
            initializeADBPool();
        }
        
        System.out.println("Connection pool initialized successfully");
    }
    
    /**
     * Initialize connection pool for mock database
     */
    private void initializeMockPool() throws SQLException {
        poolDataSource = PoolDataSourceFactory.getPoolDataSource();
        
        // Basic connection properties
        poolDataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        poolDataSource.setURL(DatabaseConfig.getDatabaseUrl());
        poolDataSource.setUser(DatabaseConfig.getUsername());
        poolDataSource.setPassword(DatabaseConfig.getPassword());
        
        // Connection pool properties
        poolDataSource.setInitialPoolSize(DatabaseConfig.getPoolInitialSize());
        poolDataSource.setMinPoolSize(DatabaseConfig.getPoolMinSize());
        poolDataSource.setMaxPoolSize(DatabaseConfig.getPoolMaxSize());
        
        System.out.println("Mock database pool configured with URL: " + DatabaseConfig.getDatabaseUrl());
    }
    
    /**
     * Initialize connection pool for Oracle Autonomous Database
     */
    private void initializeADBPool() throws SQLException {
        poolDataSource = PoolDataSourceFactory.getPoolDataSource();
        
        // Set connection factory
        poolDataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        
        // ADB connection string (using wallet)
        String adbUrl = DatabaseConfig.getDatabaseUrl();
        poolDataSource.setURL(adbUrl);
        poolDataSource.setUser(DatabaseConfig.getUsername());
        poolDataSource.setPassword(DatabaseConfig.getPassword());
        
        // Set wallet location for ADB
        String walletLocation = DatabaseConfig.getWalletLocation();
        if (walletLocation != null && !walletLocation.isEmpty()) {
            System.setProperty("oracle.net.tns_admin", walletLocation);
            System.setProperty("oracle.net.wallet_location", walletLocation);
            System.out.println("Wallet location set to: " + walletLocation);
        }
        
        // Connection pool properties
        poolDataSource.setInitialPoolSize(DatabaseConfig.getPoolInitialSize());
        poolDataSource.setMinPoolSize(DatabaseConfig.getPoolMinSize());
        poolDataSource.setMaxPoolSize(DatabaseConfig.getPoolMaxSize());
        
        // Additional properties for ADB
        Properties connProps = new Properties();
        connProps.setProperty("oracle.jdbc.fanEnabled", "false");
        poolDataSource.setConnectionProperties(connProps);
        
        System.out.println("ADB connection pool configured with service: " + DatabaseConfig.getServiceName());
    }
    
    /**
     * Get a connection from the pool
     */
    public Connection getConnection() throws SQLException {
        if (poolDataSource == null) {
            throw new SQLException("Connection pool is not initialized");
        }
        
        if (mockMode) {
            System.out.println("WARNING: Running in MOCK mode - no real database connection");
            throw new SQLException("Mock mode enabled - configure real ADB connection in database.properties");
        }
        
        return poolDataSource.getConnection();
    }
    
    /**
     * Test database connectivity
     */
    public DatabaseConnectionInfo testConnection() {
        DatabaseConnectionInfo info = new DatabaseConnectionInfo();
        info.setMockMode(mockMode);
        info.setConfigured(poolDataSource != null);
        
        if (mockMode) {
            info.setStatus("MOCK MODE");
            info.setMessage("Application is running in mock mode. Configure real ADB credentials to connect.");
            info.setDatabaseUrl(DatabaseConfig.getDatabaseUrl());
            info.setUsername(DatabaseConfig.getUsername());
            info.setServiceName(DatabaseConfig.getServiceName());
            info.setWalletLocation(DatabaseConfig.getWalletLocation());
            return info;
        }
        
        if (poolDataSource == null) {
            info.setStatus("NOT CONFIGURED");
            info.setMessage("Connection pool is not initialized");
            return info;
        }
        
        try (Connection conn = poolDataSource.getConnection()) {
            info.setStatus("CONNECTED");
            info.setMessage("Successfully connected to Oracle Autonomous Database");
            info.setDatabaseUrl(DatabaseConfig.getDatabaseUrl());
            info.setUsername(DatabaseConfig.getUsername());
            info.setServiceName(DatabaseConfig.getServiceName());
            info.setWalletLocation(DatabaseConfig.getWalletLocation());
            
            // Get database metadata
            info.setDatabaseProductName(conn.getMetaData().getDatabaseProductName());
            info.setDatabaseProductVersion(conn.getMetaData().getDatabaseProductVersion());
            info.setDriverName(conn.getMetaData().getDriverName());
            info.setDriverVersion(conn.getMetaData().getDriverVersion());
            
        } catch (SQLException e) {
            info.setStatus("ERROR");
            info.setMessage("Failed to connect: " + e.getMessage());
            info.setError(e.toString());
        }
        
        return info;
    }
    
    /**
     * Get pool statistics
     */
    public String getPoolStatistics() {
        if (poolDataSource == null) {
            return "Pool not initialized";
        }
        
        try {
            StringBuilder stats = new StringBuilder();
            stats.append("Available Connections: ").append(poolDataSource.getAvailableConnectionsCount()).append("\n");
            stats.append("Borrowed Connections: ").append(poolDataSource.getBorrowedConnectionsCount()).append("\n");
            stats.append("Total Connections: ").append(poolDataSource.getAvailableConnectionsCount() + 
                                                       poolDataSource.getBorrowedConnectionsCount());
            return stats.toString();
        } catch (SQLException e) {
            return "Error getting pool statistics: " + e.getMessage();
        }
    }
    
    /**
     * Close the connection pool
     */
    public void closePool() {
        if (poolDataSource != null) {
            try {
                // UCP doesn't have a close method, but we can help GC
                poolDataSource = null;
                System.out.println("Connection pool closed");
            } catch (Exception e) {
                System.err.println("Error closing pool: " + e.getMessage());
            }
        }
    }
    
    public boolean isMockMode() {
        return mockMode;
    }
}
