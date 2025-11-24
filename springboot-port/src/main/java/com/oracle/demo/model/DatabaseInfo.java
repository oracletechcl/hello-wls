package com.oracle.demo.model;

/**
 * Model class representing database connection information
 */
public class DatabaseInfo {
    private String status;
    private String message;
    private boolean mockMode;
    private boolean configured;
    private String databaseUrl;
    private String username;
    private String serviceName;
    private String walletLocation;
    private String databaseProductName;
    private String databaseProductVersion;
    private String driverName;
    private String driverVersion;
    private String error;
    private String poolStatistics;
    private String testQueryResult;

    // Getters and Setters
    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public boolean isMockMode() {
        return mockMode;
    }

    public void setMockMode(boolean mockMode) {
        this.mockMode = mockMode;
    }

    public boolean isConfigured() {
        return configured;
    }

    public void setConfigured(boolean configured) {
        this.configured = configured;
    }

    public String getDatabaseUrl() {
        return databaseUrl;
    }

    public void setDatabaseUrl(String databaseUrl) {
        this.databaseUrl = databaseUrl;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getServiceName() {
        return serviceName;
    }

    public void setServiceName(String serviceName) {
        this.serviceName = serviceName;
    }

    public String getWalletLocation() {
        return walletLocation;
    }

    public void setWalletLocation(String walletLocation) {
        this.walletLocation = walletLocation;
    }

    public String getDatabaseProductName() {
        return databaseProductName;
    }

    public void setDatabaseProductName(String databaseProductName) {
        this.databaseProductName = databaseProductName;
    }

    public String getDatabaseProductVersion() {
        return databaseProductVersion;
    }

    public void setDatabaseProductVersion(String databaseProductVersion) {
        this.databaseProductVersion = databaseProductVersion;
    }

    public String getDriverName() {
        return driverName;
    }

    public void setDriverName(String driverName) {
        this.driverName = driverName;
    }

    public String getDriverVersion() {
        return driverVersion;
    }

    public void setDriverVersion(String driverVersion) {
        this.driverVersion = driverVersion;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }

    public String getPoolStatistics() {
        return poolStatistics;
    }

    public void setPoolStatistics(String poolStatistics) {
        this.poolStatistics = poolStatistics;
    }

    public String getTestQueryResult() {
        return testQueryResult;
    }

    public void setTestQueryResult(String testQueryResult) {
        this.testQueryResult = testQueryResult;
    }
}
