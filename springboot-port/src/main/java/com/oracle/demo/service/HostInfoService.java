package com.oracle.demo.service;

import com.oracle.demo.model.HostInfo;
import org.springframework.stereotype.Service;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

/**
 * Service for retrieving host information
 * Migrated from HostInfoServlet
 */
@Service
public class HostInfoService {

    public HostInfo getHostInfo() {
        HostInfo info = new HostInfo();
        
        try {
            // Get host information
            InetAddress localhost = InetAddress.getLocalHost();
            info.setHostname(localhost.getHostName());
            info.setHostAddress(localhost.getHostAddress());
            
            // Get network interfaces
            Map<String, String> interfaces = new HashMap<>();
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
            info.setNetworkInterfaces(interfaces);
            
            // Server information
            info.setServerName("Spring Boot Embedded Tomcat");
            info.setServerTime(new Date());
            
            // System properties
            info.setOsName(System.getProperty("os.name"));
            info.setOsVersion(System.getProperty("os.version"));
            info.setOsArch(System.getProperty("os.arch"));
            
            // Java information
            info.setJavaVersion(System.getProperty("java.version"));
            info.setJavaVendor(System.getProperty("java.vendor"));
            info.setJavaHome(System.getProperty("java.home"));
            
            // Runtime information
            Runtime runtime = Runtime.getRuntime();
            info.setMaxMemory(runtime.maxMemory() / (1024 * 1024));
            info.setTotalMemory(runtime.totalMemory() / (1024 * 1024));
            info.setFreeMemory(runtime.freeMemory() / (1024 * 1024));
            info.setUsedMemory((runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024));
            info.setProcessors(runtime.availableProcessors());
            
            // User information
            info.setUserName(System.getProperty("user.name"));
            info.setUserHome(System.getProperty("user.home"));
            info.setUserDir(System.getProperty("user.dir"));
            
        } catch (Exception e) {
            throw new RuntimeException("Error retrieving host information", e);
        }
        
        return info;
    }
}
