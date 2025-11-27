package com.oracle.demo.model;

import java.util.Map;

/**
 * Data Transfer Object for host information
 * Migrated from WebLogic to Helidon MP
 */
public class HostInfo {
    
    private String hostname;
    private String hostAddress;
    private String serverName;
    private String serverTime;
    private Map<String, String> networkInterfaces;
    private OsInfo osInfo;
    private JavaInfo javaInfo;
    private MemoryInfo memoryInfo;
    private UserInfo userInfo;

    public HostInfo() {
    }

    public String getHostname() {
        return hostname;
    }

    public void setHostname(String hostname) {
        this.hostname = hostname;
    }

    public String getHostAddress() {
        return hostAddress;
    }

    public void setHostAddress(String hostAddress) {
        this.hostAddress = hostAddress;
    }

    public String getServerName() {
        return serverName;
    }

    public void setServerName(String serverName) {
        this.serverName = serverName;
    }

    public String getServerTime() {
        return serverTime;
    }

    public void setServerTime(String serverTime) {
        this.serverTime = serverTime;
    }

    public Map<String, String> getNetworkInterfaces() {
        return networkInterfaces;
    }

    public void setNetworkInterfaces(Map<String, String> networkInterfaces) {
        this.networkInterfaces = networkInterfaces;
    }

    public OsInfo getOsInfo() {
        return osInfo;
    }

    public void setOsInfo(OsInfo osInfo) {
        this.osInfo = osInfo;
    }

    public JavaInfo getJavaInfo() {
        return javaInfo;
    }

    public void setJavaInfo(JavaInfo javaInfo) {
        this.javaInfo = javaInfo;
    }

    public MemoryInfo getMemoryInfo() {
        return memoryInfo;
    }

    public void setMemoryInfo(MemoryInfo memoryInfo) {
        this.memoryInfo = memoryInfo;
    }

    public UserInfo getUserInfo() {
        return userInfo;
    }

    public void setUserInfo(UserInfo userInfo) {
        this.userInfo = userInfo;
    }

    /**
     * Operating System information
     */
    public static class OsInfo {
        private String name;
        private String version;
        private String architecture;
        private int processors;

        public OsInfo() {
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getVersion() {
            return version;
        }

        public void setVersion(String version) {
            this.version = version;
        }

        public String getArchitecture() {
            return architecture;
        }

        public void setArchitecture(String architecture) {
            this.architecture = architecture;
        }

        public int getProcessors() {
            return processors;
        }

        public void setProcessors(int processors) {
            this.processors = processors;
        }
    }

    /**
     * Java runtime information
     */
    public static class JavaInfo {
        private String version;
        private String vendor;
        private String home;

        public JavaInfo() {
        }

        public String getVersion() {
            return version;
        }

        public void setVersion(String version) {
            this.version = version;
        }

        public String getVendor() {
            return vendor;
        }

        public void setVendor(String vendor) {
            this.vendor = vendor;
        }

        public String getHome() {
            return home;
        }

        public void setHome(String home) {
            this.home = home;
        }
    }

    /**
     * Memory information
     */
    public static class MemoryInfo {
        private long maxMemoryMB;
        private long totalMemoryMB;
        private long freeMemoryMB;
        private long usedMemoryMB;

        public MemoryInfo() {
        }

        public long getMaxMemoryMB() {
            return maxMemoryMB;
        }

        public void setMaxMemoryMB(long maxMemoryMB) {
            this.maxMemoryMB = maxMemoryMB;
        }

        public long getTotalMemoryMB() {
            return totalMemoryMB;
        }

        public void setTotalMemoryMB(long totalMemoryMB) {
            this.totalMemoryMB = totalMemoryMB;
        }

        public long getFreeMemoryMB() {
            return freeMemoryMB;
        }

        public void setFreeMemoryMB(long freeMemoryMB) {
            this.freeMemoryMB = freeMemoryMB;
        }

        public long getUsedMemoryMB() {
            return usedMemoryMB;
        }

        public void setUsedMemoryMB(long usedMemoryMB) {
            this.usedMemoryMB = usedMemoryMB;
        }
    }

    /**
     * User information
     */
    public static class UserInfo {
        private String name;
        private String home;
        private String workingDirectory;

        public UserInfo() {
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getHome() {
            return home;
        }

        public void setHome(String home) {
            this.home = home;
        }

        public String getWorkingDirectory() {
            return workingDirectory;
        }

        public void setWorkingDirectory(String workingDirectory) {
            this.workingDirectory = workingDirectory;
        }
    }
}
