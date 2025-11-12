package com.oracle.demo;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Configuration class for Oracle Autonomous Database connection settings.
 * Supports both mock mode (for development) and real ADB connection (for production).
 */
public class DatabaseConfig {
    
    private static final String CONFIG_FILE = "database.properties";
    private static Properties properties;
    
    // Configuration keys
    public static final String MOCK_MODE = "db.mock.enabled";
    public static final String DB_URL = "db.url";
    public static final String DB_USER = "db.user";
    public static final String DB_PASSWORD = "db.password";
    public static final String DB_WALLET_LOCATION = "db.wallet.location";
    public static final String DB_SERVICE_NAME = "db.service.name";
    public static final String DB_TNS_ADMIN = "oracle.net.tns_admin";
    
    // Connection pool settings
    public static final String POOL_INITIAL_SIZE = "db.pool.initialSize";
    public static final String POOL_MIN_SIZE = "db.pool.minSize";
    public static final String POOL_MAX_SIZE = "db.pool.maxSize";
    
    static {
        loadProperties();
    }
    
    /**
     * Load database properties from configuration file
     */
    private static void loadProperties() {
        properties = new Properties();
        
        // Set default values
        setDefaults();
        
        // Try to load from properties file
        try (InputStream input = DatabaseConfig.class.getClassLoader()
                .getResourceAsStream(CONFIG_FILE)) {
            if (input != null) {
                properties.load(input);
                System.out.println("Database configuration loaded from " + CONFIG_FILE);
            } else {
                System.out.println("Database configuration file not found, using defaults (MOCK mode)");
            }
        } catch (IOException e) {
            System.err.println("Error loading database configuration: " + e.getMessage());
            System.out.println("Using default configuration (MOCK mode)");
        }
    }
    
    /**
     * Set default configuration values (MOCK mode)
     */
    private static void setDefaults() {
        properties.setProperty(MOCK_MODE, "true");
        properties.setProperty(DB_URL, "jdbc:oracle:thin:@localhost:1521/XEPDB1");
        properties.setProperty(DB_USER, "ADMIN");
        properties.setProperty(DB_PASSWORD, "");
        properties.setProperty(DB_SERVICE_NAME, "mock_adb_high");
        properties.setProperty(DB_WALLET_LOCATION, "/path/to/wallet");
        
        // Connection pool defaults
        properties.setProperty(POOL_INITIAL_SIZE, "5");
        properties.setProperty(POOL_MIN_SIZE, "2");
        properties.setProperty(POOL_MAX_SIZE, "20");
    }
    
    /**
     * Get a configuration property
     */
    public static String getProperty(String key) {
        return properties.getProperty(key);
    }
    
    /**
     * Get a configuration property with a default value
     */
    public static String getProperty(String key, String defaultValue) {
        return properties.getProperty(key, defaultValue);
    }
    
    /**
     * Check if mock mode is enabled
     */
    public static boolean isMockMode() {
        return Boolean.parseBoolean(getProperty(MOCK_MODE, "true"));
    }
    
    /**
     * Get the database URL
     */
    public static String getDatabaseUrl() {
        return getProperty(DB_URL);
    }
    
    /**
     * Get the database username
     */
    public static String getUsername() {
        return getProperty(DB_USER);
    }
    
    /**
     * Get the database password
     */
    public static String getPassword() {
        return getProperty(DB_PASSWORD);
    }
    
    /**
     * Get the service name
     */
    public static String getServiceName() {
        return getProperty(DB_SERVICE_NAME);
    }
    
    /**
     * Get the wallet location
     */
    public static String getWalletLocation() {
        return getProperty(DB_WALLET_LOCATION);
    }
    
    /**
     * Get connection pool initial size
     */
    public static int getPoolInitialSize() {
        return Integer.parseInt(getProperty(POOL_INITIAL_SIZE, "5"));
    }
    
    /**
     * Get connection pool minimum size
     */
    public static int getPoolMinSize() {
        return Integer.parseInt(getProperty(POOL_MIN_SIZE, "2"));
    }
    
    /**
     * Get connection pool maximum size
     */
    public static int getPoolMaxSize() {
        return Integer.parseInt(getProperty(POOL_MAX_SIZE, "20"));
    }
}
