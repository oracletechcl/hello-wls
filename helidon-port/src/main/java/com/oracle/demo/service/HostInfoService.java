package com.oracle.demo.service;

import com.oracle.demo.model.HostInfo;
import jakarta.enterprise.context.ApplicationScoped;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Date;
import java.util.Enumeration;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * CDI Service for host information
 * Migrated from HostInfoServlet to Helidon MP CDI service
 */
@ApplicationScoped
public class HostInfoService {
    
    private static final Logger LOGGER = Logger.getLogger(HostInfoService.class.getName());

    /**
     * Collects and returns comprehensive host information
     * 
     * @return HostInfo containing system, network, and runtime details
     */
    public HostInfo getHostInfo() {
        HostInfo hostInfo = new HostInfo();
        
        try {
            // Get host information
            InetAddress localhost = InetAddress.getLocalHost();
            hostInfo.setHostname(localhost.getHostName());
            hostInfo.setHostAddress(localhost.getHostAddress());
            
            // Server info (Helidon instead of WebLogic)
            hostInfo.setServerName("Helidon MP Server");
            hostInfo.setServerTime(new Date().toString());
            
            // Network interfaces
            hostInfo.setNetworkInterfaces(getNetworkInterfaces());
            
            // OS Information
            hostInfo.setOsInfo(getOsInfo());
            
            // Java Information
            hostInfo.setJavaInfo(getJavaInfo());
            
            // Memory Information
            hostInfo.setMemoryInfo(getMemoryInfo());
            
            // User Information
            hostInfo.setUserInfo(getUserInfo());
            
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "Error collecting host info", e);
            hostInfo.setServerName("Helidon MP Server");
            hostInfo.setServerTime(new Date().toString());
        }
        
        return hostInfo;
    }
    
    /**
     * Get all network interfaces
     */
    private Map<String, String> getNetworkInterfaces() {
        Map<String, String> interfaces = new LinkedHashMap<>();
        
        try {
            Enumeration<NetworkInterface> networkInterfaces = NetworkInterface.getNetworkInterfaces();
            while (networkInterfaces.hasMoreElements()) {
                NetworkInterface ni = networkInterfaces.nextElement();
                if (ni.isUp() && !ni.isLoopback()) {
                    Enumeration<InetAddress> addresses = ni.getInetAddresses();
                    while (addresses.hasMoreElements()) {
                        InetAddress addr = addresses.nextElement();
                        if (!addr.isLoopbackAddress() && addr.getHostAddress().indexOf(':') == -1) {
                            interfaces.put(ni.getName(), addr.getHostAddress());
                        }
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "Error getting network interfaces", e);
        }
        
        return interfaces;
    }
    
    /**
     * Get OS information
     */
    private HostInfo.OsInfo getOsInfo() {
        HostInfo.OsInfo osInfo = new HostInfo.OsInfo();
        osInfo.setName(System.getProperty("os.name"));
        osInfo.setVersion(System.getProperty("os.version"));
        osInfo.setArchitecture(System.getProperty("os.arch"));
        osInfo.setProcessors(Runtime.getRuntime().availableProcessors());
        return osInfo;
    }
    
    /**
     * Get Java runtime information
     */
    private HostInfo.JavaInfo getJavaInfo() {
        HostInfo.JavaInfo javaInfo = new HostInfo.JavaInfo();
        javaInfo.setVersion(System.getProperty("java.version"));
        javaInfo.setVendor(System.getProperty("java.vendor"));
        javaInfo.setHome(System.getProperty("java.home"));
        return javaInfo;
    }
    
    /**
     * Get memory information
     */
    private HostInfo.MemoryInfo getMemoryInfo() {
        Runtime runtime = Runtime.getRuntime();
        HostInfo.MemoryInfo memoryInfo = new HostInfo.MemoryInfo();
        
        long maxMemory = runtime.maxMemory() / (1024 * 1024);
        long totalMemory = runtime.totalMemory() / (1024 * 1024);
        long freeMemory = runtime.freeMemory() / (1024 * 1024);
        long usedMemory = totalMemory - freeMemory;
        
        memoryInfo.setMaxMemoryMB(maxMemory);
        memoryInfo.setTotalMemoryMB(totalMemory);
        memoryInfo.setFreeMemoryMB(freeMemory);
        memoryInfo.setUsedMemoryMB(usedMemory);
        
        return memoryInfo;
    }
    
    /**
     * Get user information
     */
    private HostInfo.UserInfo getUserInfo() {
        HostInfo.UserInfo userInfo = new HostInfo.UserInfo();
        userInfo.setName(System.getProperty("user.name"));
        userInfo.setHome(System.getProperty("user.home"));
        userInfo.setWorkingDirectory(System.getProperty("user.dir"));
        return userInfo;
    }
}
