package com.oracle.demo;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Enumeration;
import java.util.Date;

/**
 * Servlet that displays host information for WebLogic Server 12.2.1.4
 */
public class HostInfoServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        
        try {
            // Get host information
            InetAddress localhost = InetAddress.getLocalHost();
            String hostname = localhost.getHostName();
            String hostAddress = localhost.getHostAddress();
            
            // Get system properties
            String osName = System.getProperty("os.name");
            String osVersion = System.getProperty("os.version");
            String osArch = System.getProperty("os.arch");
            String javaVersion = System.getProperty("java.version");
            String javaVendor = System.getProperty("java.vendor");
            String javaHome = System.getProperty("java.home");
            String userName = System.getProperty("user.name");
            String userHome = System.getProperty("user.home");
            String userDir = System.getProperty("user.dir");
            
            // Get runtime information
            Runtime runtime = Runtime.getRuntime();
            long maxMemory = runtime.maxMemory() / (1024 * 1024);
            long totalMemory = runtime.totalMemory() / (1024 * 1024);
            long freeMemory = runtime.freeMemory() / (1024 * 1024);
            long usedMemory = (totalMemory - freeMemory);
            int processors = runtime.availableProcessors();
            
            // Generate HTML response
            out.println("<!DOCTYPE html>");
            out.println("<html>");
            out.println("<head>");
            out.println("<title>WebLogic Host Information</title>");
            out.println("<style>");
            out.println("body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }");
            out.println("h1 { color: #c74634; }");
            out.println("h2 { color: #333; margin-top: 30px; }");
            out.println(".container { background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }");
            out.println(".info-section { margin-bottom: 20px; }");
            out.println("table { border-collapse: collapse; width: 100%; margin-top: 10px; }");
            out.println("td { padding: 10px; border-bottom: 1px solid #ddd; }");
            out.println("td:first-child { font-weight: bold; width: 200px; color: #555; }");
            out.println("td:last-child { color: #333; }");
            out.println(".header { background-color: #c74634; color: white; padding: 20px; border-radius: 8px 8px 0 0; margin: -30px -30px 20px -30px; }");
            out.println(".footer { margin-top: 30px; text-align: center; color: #777; font-size: 12px; }");
            out.println(".back-link { display: inline-block; margin-top: 20px; color: #c74634; text-decoration: none; }");
            out.println(".back-link:hover { text-decoration: underline; }");
            out.println("</style>");
            out.println("</head>");
            out.println("<body>");
            out.println("<div class='container'>");
            out.println("<div class='header'>");
            out.println("<h1>Hello from WebLogic Server!</h1>");
            out.println("<p>Server Time: " + new Date() + "</p>");
            out.println("</div>");
            
            // Network Information
            out.println("<div class='info-section'>");
            out.println("<h2>Network Information</h2>");
            out.println("<table>");
            out.println("<tr><td>Hostname</td><td>" + hostname + "</td></tr>");
            out.println("<tr><td>Host IP Address</td><td>" + hostAddress + "</td></tr>");
            
            // Get all network interfaces
            StringBuilder networkInterfaces = new StringBuilder();
            Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
            while (interfaces.hasMoreElements()) {
                NetworkInterface ni = interfaces.nextElement();
                if (ni.isUp() && !ni.isLoopback()) {
                    Enumeration<InetAddress> addresses = ni.getInetAddresses();
                    while (addresses.hasMoreElements()) {
                        InetAddress addr = addresses.nextElement();
                        if (!addr.isLoopbackAddress() && addr.getHostAddress().indexOf(':') == -1) {
                            networkInterfaces.append(ni.getName()).append(": ")
                                           .append(addr.getHostAddress()).append("<br>");
                        }
                    }
                }
            }
            out.println("<tr><td>Network Interfaces</td><td>" + networkInterfaces.toString() + "</td></tr>");
            out.println("</table>");
            out.println("</div>");
            
            // Operating System Information
            out.println("<div class='info-section'>");
            out.println("<h2>Operating System Information</h2>");
            out.println("<table>");
            out.println("<tr><td>OS Name</td><td>" + osName + "</td></tr>");
            out.println("<tr><td>OS Version</td><td>" + osVersion + "</td></tr>");
            out.println("<tr><td>OS Architecture</td><td>" + osArch + "</td></tr>");
            out.println("<tr><td>Available Processors</td><td>" + processors + "</td></tr>");
            out.println("</table>");
            out.println("</div>");
            
            // Java Information
            out.println("<div class='info-section'>");
            out.println("<h2>Java Runtime Information</h2>");
            out.println("<table>");
            out.println("<tr><td>Java Version</td><td>" + javaVersion + "</td></tr>");
            out.println("<tr><td>Java Vendor</td><td>" + javaVendor + "</td></tr>");
            out.println("<tr><td>Java Home</td><td>" + javaHome + "</td></tr>");
            out.println("</table>");
            out.println("</div>");
            
            // Memory Information
            out.println("<div class='info-section'>");
            out.println("<h2>Memory Information</h2>");
            out.println("<table>");
            out.println("<tr><td>Max Memory</td><td>" + maxMemory + " MB</td></tr>");
            out.println("<tr><td>Total Memory</td><td>" + totalMemory + " MB</td></tr>");
            out.println("<tr><td>Free Memory</td><td>" + freeMemory + " MB</td></tr>");
            out.println("<tr><td>Used Memory</td><td>" + usedMemory + " MB</td></tr>");
            out.println("</table>");
            out.println("</div>");
            
            // User Information
            out.println("<div class='info-section'>");
            out.println("<h2>User & Environment Information</h2>");
            out.println("<table>");
            out.println("<tr><td>User Name</td><td>" + userName + "</td></tr>");
            out.println("<tr><td>User Home</td><td>" + userHome + "</td></tr>");
            out.println("<tr><td>Working Directory</td><td>" + userDir + "</td></tr>");
            out.println("</table>");
            out.println("</div>");
            
            out.println("<a href='index.html' class='back-link'>&larr; Back to Home</a>");
            
            out.println("<div class='footer'>");
            out.println("<p>WebLogic Server 12.2.1.4 Host Information Application</p>");
            out.println("</div>");
            
            out.println("</div>");
            out.println("</body>");
            out.println("</html>");
            
        } catch (Exception e) {
            out.println("<h2>Error retrieving host information</h2>");
            out.println("<p>" + e.getMessage() + "</p>");
            e.printStackTrace(out);
        } finally {
            out.close();
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        doGet(request, response);
    }
}
