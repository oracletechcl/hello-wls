package com.oracle.demo;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Date;

/**
 * Servlet that displays Oracle Autonomous Database connection information
 * and demonstrates database connectivity
 */
public class DatabaseInfoServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    private DatabaseConnectionManager connectionManager;
    
    @Override
    public void init() throws ServletException {
        super.init();
        // Initialize connection manager
        connectionManager = DatabaseConnectionManager.getInstance();
        System.out.println("DatabaseInfoServlet initialized");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        
        try {
            // Test database connection
            DatabaseConnectionInfo connInfo = connectionManager.testConnection();
            
            // Generate HTML response
            out.println("<!DOCTYPE html>");
            out.println("<html>");
            out.println("<head>");
            out.println("<title>Oracle Autonomous Database - Connection Info</title>");
            out.println("<style>");
            out.println("body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }");
            out.println("h1 { color: #c74634; }");
            out.println("h2 { color: #333; margin-top: 30px; }");
            out.println(".container { background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }");
            out.println(".header { background-color: #c74634; color: white; padding: 20px; border-radius: 8px 8px 0 0; margin: -30px -30px 20px -30px; }");
            out.println(".status-box { padding: 15px; border-radius: 5px; margin: 20px 0; }");
            out.println(".status-mock { background-color: #fff3cd; border: 2px solid #ffc107; }");
            out.println(".status-connected { background-color: #d4edda; border: 2px solid #28a745; }");
            out.println(".status-error { background-color: #f8d7da; border: 2px solid #dc3545; }");
            out.println(".status-not-configured { background-color: #e2e3e5; border: 2px solid #6c757d; }");
            out.println("table { border-collapse: collapse; width: 100%; margin-top: 10px; }");
            out.println("td { padding: 10px; border-bottom: 1px solid #ddd; }");
            out.println("td:first-child { font-weight: bold; width: 250px; color: #555; }");
            out.println("td:last-child { color: #333; word-break: break-all; }");
            out.println(".info-section { margin-bottom: 20px; }");
            out.println(".warning { color: #856404; font-weight: bold; }");
            out.println(".success { color: #155724; font-weight: bold; }");
            out.println(".error { color: #721c24; font-weight: bold; }");
            out.println(".back-link { display: inline-block; margin-top: 20px; color: #c74634; text-decoration: none; }");
            out.println(".back-link:hover { text-decoration: underline; }");
            out.println(".footer { margin-top: 30px; text-align: center; color: #777; font-size: 12px; }");
            out.println(".code-block { background-color: #f4f4f4; padding: 10px; border-radius: 4px; font-family: monospace; font-size: 12px; overflow-x: auto; }");
            out.println(".badge { display: inline-block; padding: 5px 10px; border-radius: 3px; font-size: 12px; font-weight: bold; }");
            out.println(".badge-mock { background-color: #ffc107; color: #000; }");
            out.println(".badge-connected { background-color: #28a745; color: #fff; }");
            out.println(".badge-error { background-color: #dc3545; color: #fff; }");
            out.println("</style>");
            out.println("</head>");
            out.println("<body>");
            out.println("<div class='container'>");
            out.println("<div class='header'>");
            out.println("<h1>Oracle Autonomous Database</h1>");
            out.println("<p>Connection Status & Configuration</p>");
            out.println("<p style='font-size: 14px;'>Server Time: " + new Date() + "</p>");
            out.println("</div>");
            
            // Status Badge
            String statusClass = "";
            String badgeClass = "";
            if (connInfo.isMockMode()) {
                statusClass = "status-mock";
                badgeClass = "badge-mock";
            } else if ("CONNECTED".equals(connInfo.getStatus())) {
                statusClass = "status-connected";
                badgeClass = "badge-connected";
            } else if ("ERROR".equals(connInfo.getStatus())) {
                statusClass = "status-error";
                badgeClass = "badge-error";
            } else {
                statusClass = "status-not-configured";
                badgeClass = "badge-error";
            }
            
            out.println("<div class='status-box " + statusClass + "'>");
            out.println("<h2>Connection Status: <span class='badge " + badgeClass + "'>" + connInfo.getStatus() + "</span></h2>");
            out.println("<p>" + connInfo.getMessage() + "</p>");
            out.println("</div>");
            
            // Configuration Information
            out.println("<div class='info-section'>");
            out.println("<h2>Configuration Details</h2>");
            out.println("<table>");
            out.println("<tr><td>Mode</td><td>" + (connInfo.isMockMode() ? "MOCK (Development)" : "PRODUCTION (Real ADB)") + "</td></tr>");
            out.println("<tr><td>Database URL</td><td>" + (connInfo.getDatabaseUrl() != null ? connInfo.getDatabaseUrl() : "Not configured") + "</td></tr>");
            out.println("<tr><td>Username</td><td>" + (connInfo.getUsername() != null ? connInfo.getUsername() : "Not configured") + "</td></tr>");
            out.println("<tr><td>Service Name</td><td>" + (connInfo.getServiceName() != null ? connInfo.getServiceName() : "Not configured") + "</td></tr>");
            out.println("<tr><td>Wallet Location</td><td>" + (connInfo.getWalletLocation() != null ? connInfo.getWalletLocation() : "Not configured") + "</td></tr>");
            out.println("</table>");
            out.println("</div>");
            
            // Database Information (only if connected)
            if ("CONNECTED".equals(connInfo.getStatus()) && !connInfo.isMockMode()) {
                out.println("<div class='info-section'>");
                out.println("<h2>Database Information</h2>");
                out.println("<table>");
                out.println("<tr><td>Database Product</td><td>" + connInfo.getDatabaseProductName() + "</td></tr>");
                out.println("<tr><td>Database Version</td><td>" + connInfo.getDatabaseProductVersion() + "</td></tr>");
                out.println("<tr><td>JDBC Driver</td><td>" + connInfo.getDriverName() + "</td></tr>");
                out.println("<tr><td>Driver Version</td><td>" + connInfo.getDriverVersion() + "</td></tr>");
                out.println("</table>");
                out.println("</div>");
                
                // Connection Pool Statistics
                out.println("<div class='info-section'>");
                out.println("<h2>Connection Pool Statistics</h2>");
                out.println("<div class='code-block'>");
                out.println(connectionManager.getPoolStatistics().replace("\n", "<br>"));
                out.println("</div>");
                out.println("</div>");
                
                // Test Query
                out.println("<div class='info-section'>");
                out.println("<h2>Test Query Results</h2>");
                try (Connection conn = connectionManager.getConnection();
                     Statement stmt = conn.createStatement();
                     ResultSet rs = stmt.executeQuery("SELECT SYSDATE FROM DUAL")) {
                    
                    out.println("<table>");
                    out.println("<tr><td>Database Current Time</td><td>");
                    if (rs.next()) {
                        out.println(rs.getTimestamp(1));
                    }
                    out.println("</td></tr>");
                    out.println("</table>");
                    out.println("<p class='success'>✓ Query executed successfully!</p>");
                } catch (Exception e) {
                    out.println("<p class='error'>✗ Query failed: " + e.getMessage() + "</p>");
                }
                out.println("</div>");
            }
            
            // Error Details (if any)
            if (connInfo.getError() != null && !connInfo.getError().isEmpty()) {
                out.println("<div class='info-section'>");
                out.println("<h2>Error Details</h2>");
                out.println("<div class='code-block'>");
                out.println(connInfo.getError().replace("\n", "<br>"));
                out.println("</div>");
                out.println("</div>");
            }
            
            // Setup Instructions (if in mock mode)
            if (connInfo.isMockMode()) {
                out.println("<div class='info-section'>");
                out.println("<h2>How to Connect to Real Oracle Autonomous Database</h2>");
                out.println("<ol>");
                out.println("<li>Create an Oracle Autonomous Database instance in OCI</li>");
                out.println("<li>Download the database wallet (Client Credentials)</li>");
                out.println("<li>Extract the wallet to a secure location on your WebLogic server</li>");
                out.println("<li>Update <code>src/main/resources/database.properties</code>:</li>");
                out.println("<div class='code-block'>");
                out.println("db.mock.enabled=false<br>");
                out.println("db.url=jdbc:oracle:thin:@&lt;service_name&gt;_high?TNS_ADMIN=/path/to/wallet<br>");
                out.println("db.user=ADMIN<br>");
                out.println("db.password=&lt;your_password&gt;<br>");
                out.println("db.service.name=&lt;service_name&gt;_high<br>");
                out.println("db.wallet.location=/path/to/wallet");
                out.println("</div>");
                out.println("<li>Rebuild and redeploy the application</li>");
                out.println("</ol>");
                out.println("</div>");
            }
            
            // Benefits of Oracle ADB
            out.println("<div class='info-section'>");
            out.println("<h2>Oracle Autonomous Database Benefits</h2>");
            out.println("<ul>");
            out.println("<li><strong>Self-Driving:</strong> Automated database management, tuning, and patching</li>");
            out.println("<li><strong>Self-Securing:</strong> Built-in security features and automated security updates</li>");
            out.println("<li><strong>Self-Repairing:</strong> Automatic failure detection and recovery</li>");
            out.println("<li><strong>Scalability:</strong> Easily scale compute and storage resources independently</li>");
            out.println("<li><strong>Performance:</strong> Optimized for both OLTP and analytics workloads</li>");
            out.println("<li><strong>Cost-Effective:</strong> Pay only for the resources you use</li>");
            out.println("</ul>");
            out.println("</div>");
            
            out.println("<a href='index.html' class='back-link'>&larr; Back to Home</a>");
            
            out.println("<div class='footer'>");
            out.println("<p>Oracle Autonomous Database Integration Demo</p>");
            out.println("<p>WebLogic Server 12.2.1.4</p>");
            out.println("</div>");
            
            out.println("</div>");
            out.println("</body>");
            out.println("</html>");
            
        } catch (Exception e) {
            out.println("<h2>Error</h2>");
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
    
    @Override
    public void destroy() {
        super.destroy();
        System.out.println("DatabaseInfoServlet destroyed");
    }
}
