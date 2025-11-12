package com.oracle.demo;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.util.Date;
import java.util.Enumeration;

/**
 * Servlet demonstrating WebLogic Server session management capabilities.
 * Shows session creation, tracking, persistence, and clustering features.
 */
public class SessionManagerServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    private static final String VISIT_COUNT_ATTR = "visitCount";
    private static final String USER_NAME_ATTR = "userName";
    private static final String SESSION_DATA_ATTR = "sessionData";
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        
        try {
            // Get or create session
            HttpSession session = request.getSession(true);
            
            // Handle session operations based on parameters
            String action = request.getParameter("action");
            if ("invalidate".equals(action)) {
                session.invalidate();
                response.sendRedirect("session");
                return;
            } else if ("setdata".equals(action)) {
                handleSetData(request, session);
            } else if ("removedata".equals(action)) {
                String key = request.getParameter("key");
                if (key != null && !key.isEmpty()) {
                    session.removeAttribute(key);
                }
            }
            
            // Track visit count
            Long visitCount = (Long) session.getAttribute(VISIT_COUNT_ATTR);
            if (visitCount == null) {
                visitCount = 1L;
            } else {
                visitCount++;
            }
            session.setAttribute(VISIT_COUNT_ATTR, visitCount);
            
            // Collect session information
            SessionInfo sessionInfo = collectSessionInfo(session, request);
            
            // Generate HTML response
            generateHTML(out, sessionInfo, session);
            
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
    
    /**
     * Handle setting session data
     */
    private void handleSetData(HttpServletRequest request, HttpSession session) {
        String userName = request.getParameter("userName");
        if (userName != null && !userName.trim().isEmpty()) {
            session.setAttribute(USER_NAME_ATTR, userName.trim());
        }
        
        String customKey = request.getParameter("customKey");
        String customValue = request.getParameter("customValue");
        if (customKey != null && !customKey.trim().isEmpty() && 
            customValue != null && !customValue.trim().isEmpty()) {
            session.setAttribute(customKey.trim(), customValue.trim());
        }
    }
    
    /**
     * Collect session information
     */
    private SessionInfo collectSessionInfo(HttpSession session, HttpServletRequest request) {
        SessionInfo info = new SessionInfo();
        
        info.setSessionId(session.getId());
        info.setCreationTime(new Date(session.getCreationTime()));
        info.setLastAccessedTime(new Date(session.getLastAccessedTime()));
        info.setMaxInactiveInterval(session.getMaxInactiveInterval());
        info.setNew(session.isNew());
        
        Long visitCount = (Long) session.getAttribute(VISIT_COUNT_ATTR);
        info.setVisitCount(visitCount != null ? visitCount : 0);
        
        String userName = (String) session.getAttribute(USER_NAME_ATTR);
        info.setUserName(userName);
        
        // Get WebLogic Server information
        String serverName = System.getProperty("weblogic.Name", "Unknown");
        try {
            InetAddress localhost = InetAddress.getLocalHost();
            info.setPrimaryServerNode(serverName + " (" + localhost.getHostName() + ")");
        } catch (Exception e) {
            info.setPrimaryServerNode(serverName);
        }
        
        // Get secondary server from session cookie if available
        // WebLogic appends secondary server info to JSESSIONID in clustered environments
        String sessionCookie = request.getHeader("Cookie");
        String secondaryServer = "None (not clustered)";
        if (sessionCookie != null && sessionCookie.contains("JSESSIONID")) {
            // JSESSIONID format: <sessionid>!<primary>!<secondary>
            String[] parts = session.getId().split("!");
            if (parts.length > 2) {
                secondaryServer = parts[2];
            } else if (parts.length > 1) {
                secondaryServer = "Configured (cluster member: " + parts[1] + ")";
            }
        }
        info.setSecondaryServerNode(secondaryServer);
        
        // Collect all session attributes
        Enumeration<String> attributeNames = session.getAttributeNames();
        while (attributeNames.hasMoreElements()) {
            String name = attributeNames.nextElement();
            Object value = session.getAttribute(name);
            info.addAttribute(name, value);
        }
        
        // Check if session is configured for replication
        // In a clustered environment, WebLogic will handle this automatically
        info.setReplicated(session.getMaxInactiveInterval() > 0);
        
        return info;
    }
    
    /**
     * Generate HTML response
     */
    private void generateHTML(PrintWriter out, SessionInfo sessionInfo, HttpSession session) {
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<title>WebLogic Session Management</title>");
        out.println("<style>");
        out.println("body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }");
        out.println("h1 { color: #c74634; }");
        out.println("h2 { color: #333; margin-top: 30px; }");
        out.println(".container { background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }");
        out.println(".header { background-color: #c74634; color: white; padding: 20px; border-radius: 8px 8px 0 0; margin: -30px -30px 20px -30px; }");
        out.println(".info-section { margin-bottom: 30px; }");
        out.println("table { border-collapse: collapse; width: 100%; margin-top: 10px; }");
        out.println("td { padding: 10px; border-bottom: 1px solid #ddd; }");
        out.println("td:first-child { font-weight: bold; width: 250px; color: #555; }");
        out.println("td:last-child { color: #333; word-break: break-all; }");
        out.println(".badge { display: inline-block; padding: 5px 10px; border-radius: 3px; font-size: 12px; font-weight: bold; }");
        out.println(".badge-new { background-color: #28a745; color: #fff; }");
        out.println(".badge-active { background-color: #17a2b8; color: #fff; }");
        out.println(".form-section { background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; }");
        out.println(".form-group { margin-bottom: 15px; }");
        out.println("label { display: block; margin-bottom: 5px; font-weight: bold; color: #555; }");
        out.println("input[type='text'] { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; }");
        out.println(".btn { display: inline-block; padding: 10px 20px; margin: 5px; background-color: #c74634; color: white; text-decoration: none; border-radius: 5px; border: none; cursor: pointer; }");
        out.println(".btn:hover { background-color: #a33829; }");
        out.println(".btn-secondary { background-color: #6c757d; }");
        out.println(".btn-secondary:hover { background-color: #5a6268; }");
        out.println(".btn-danger { background-color: #dc3545; }");
        out.println(".btn-danger:hover { background-color: #c82333; }");
        out.println(".back-link { display: inline-block; margin-top: 20px; color: #c74634; text-decoration: none; }");
        out.println(".back-link:hover { text-decoration: underline; }");
        out.println(".footer { margin-top: 30px; text-align: center; color: #777; font-size: 12px; }");
        out.println(".highlight { background-color: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 20px 0; }");
        out.println(".stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }");
        out.println(".stat-card { background-color: #f8f9fa; padding: 15px; border-radius: 5px; text-align: center; }");
        out.println(".stat-value { font-size: 24px; font-weight: bold; color: #c74634; }");
        out.println(".stat-label { font-size: 12px; color: #666; margin-top: 5px; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body>");
        out.println("<div class='container'>");
        out.println("<div class='header'>");
        out.println("<h1>Session Management</h1>");
        out.println("<p>WebLogic Server Session Persistence & Clustering</p>");
        out.println("<p style='font-size: 14px;'>Current Time: " + new Date() + "</p>");
        out.println("</div>");
        
        // Session Status
        out.println("<div class='info-section'>");
        out.println("<h2>Session Status");
        if (sessionInfo.isNew()) {
            out.println(" <span class='badge badge-new'>NEW</span>");
        } else {
            out.println(" <span class='badge badge-active'>ACTIVE</span>");
        }
        out.println("</h2>");
        
        // Session Statistics Cards
        out.println("<div class='stats-grid'>");
        out.println("<div class='stat-card'>");
        out.println("<div class='stat-value'>" + sessionInfo.getVisitCount() + "</div>");
        out.println("<div class='stat-label'>Page Views</div>");
        out.println("</div>");
        out.println("<div class='stat-card'>");
        out.println("<div class='stat-value'>" + sessionInfo.getSessionAge() + "s</div>");
        out.println("<div class='stat-label'>Session Age</div>");
        out.println("</div>");
        out.println("<div class='stat-card'>");
        out.println("<div class='stat-value'>" + sessionInfo.getIdleTime() + "s</div>");
        out.println("<div class='stat-label'>Idle Time</div>");
        out.println("</div>");
        out.println("<div class='stat-card'>");
        out.println("<div class='stat-value'>" + sessionInfo.getRemainingTime() + "s</div>");
        out.println("<div class='stat-label'>Time Until Timeout</div>");
        out.println("</div>");
        out.println("</div>");
        out.println("</div>");
        
        // Session Information
        out.println("<div class='info-section'>");
        out.println("<h2>Session Information</h2>");
        out.println("<table>");
        out.println("<tr><td>Session ID</td><td>" + sessionInfo.getSessionId() + "</td></tr>");
        out.println("<tr><td>Creation Time</td><td>" + sessionInfo.getCreationTime() + "</td></tr>");
        out.println("<tr><td>Last Accessed Time</td><td>" + sessionInfo.getLastAccessedTime() + "</td></tr>");
        out.println("<tr><td>Max Inactive Interval</td><td>" + sessionInfo.getMaxInactiveInterval() + " seconds</td></tr>");
        out.println("<tr><td>Is New Session</td><td>" + sessionInfo.isNew() + "</td></tr>");
        out.println("<tr><td>Current User</td><td>" + (sessionInfo.getUserName() != null ? sessionInfo.getUserName() : "Anonymous") + "</td></tr>");
        out.println("</table>");
        out.println("</div>");
        
        // Server Information
        out.println("<div class='info-section'>");
        out.println("<h2>Server & Clustering Information</h2>");
        out.println("<table>");
        out.println("<tr><td>Primary Server Node</td><td>" + sessionInfo.getPrimaryServerNode() + "</td></tr>");
        out.println("<tr><td>Secondary Server Node</td><td>" + sessionInfo.getSecondaryServerNode() + "</td></tr>");
        out.println("<tr><td>Session Replication</td><td>" + (sessionInfo.isReplicated() ? "Enabled (configured)" : "Disabled") + "</td></tr>");
        out.println("<tr><td>Persistence Type</td><td>In-Memory Replication (WebLogic Cluster)</td></tr>");
        out.println("</table>");
        
        out.println("<div class='highlight'>");
        out.println("<strong>High Availability:</strong> In a WebLogic cluster, sessions are automatically replicated to secondary servers. ");
        out.println("If the primary server fails, the session state is preserved and available on other cluster members.");
        out.println("</div>");
        out.println("</div>");
        
        // Session Attributes
        out.println("<div class='info-section'>");
        out.println("<h2>Session Attributes</h2>");
        if (sessionInfo.getAttributes().isEmpty()) {
            out.println("<p>No custom attributes set</p>");
        } else {
            out.println("<table>");
            for (String key : sessionInfo.getAttributes().keySet()) {
                Object value = sessionInfo.getAttributes().get(key);
                out.println("<tr><td>" + key + "</td><td>" + value + "</td></tr>");
            }
            out.println("</table>");
        }
        out.println("</div>");
        
        // Add/Update Session Data Form
        out.println("<div class='info-section'>");
        out.println("<h2>Manage Session Data</h2>");
        out.println("<div class='form-section'>");
        out.println("<form method='POST' action='session'>");
        out.println("<input type='hidden' name='action' value='setdata'>");
        out.println("<div class='form-group'>");
        out.println("<label for='userName'>Set User Name:</label>");
        out.println("<input type='text' id='userName' name='userName' placeholder='Enter your name' value='" + 
                    (sessionInfo.getUserName() != null ? sessionInfo.getUserName() : "") + "'>");
        out.println("</div>");
        out.println("<div class='form-group'>");
        out.println("<label for='customKey'>Custom Attribute Key:</label>");
        out.println("<input type='text' id='customKey' name='customKey' placeholder='e.g., favoriteColor'>");
        out.println("</div>");
        out.println("<div class='form-group'>");
        out.println("<label for='customValue'>Custom Attribute Value:</label>");
        out.println("<input type='text' id='customValue' name='customValue' placeholder='e.g., blue'>");
        out.println("</div>");
        out.println("<button type='submit' class='btn'>Update Session Data</button>");
        out.println("</form>");
        out.println("</div>");
        out.println("</div>");
        
        // Session Actions
        out.println("<div class='info-section'>");
        out.println("<h2>Session Actions</h2>");
        out.println("<a href='session' class='btn btn-secondary'>Refresh Page</a> ");
        out.println("<a href='session?action=invalidate' class='btn btn-danger' onclick=\"return confirm('Are you sure you want to invalidate this session?');\">Invalidate Session</a>");
        out.println("</div>");
        
        // Features and Benefits
        out.println("<div class='info-section'>");
        out.println("<h2>WebLogic Session Management Features</h2>");
        out.println("<ul>");
        out.println("<li><strong>In-Memory Replication:</strong> Sessions replicated across cluster members for high availability</li>");
        out.println("<li><strong>JDBC Persistence:</strong> Optional database-backed session storage for disaster recovery</li>");
        out.println("<li><strong>File Persistence:</strong> File-based session storage for single-server deployments</li>");
        out.println("<li><strong>Cookie-Based Tracking:</strong> Automatic session tracking via JSESSIONID cookie</li>");
        out.println("<li><strong>URL Rewriting:</strong> Fallback mechanism when cookies are disabled</li>");
        out.println("<li><strong>Session Failover:</strong> Seamless session migration during server failures</li>");
        out.println("<li><strong>Session Timeout:</strong> Configurable inactive session cleanup</li>");
        out.println("<li><strong>Serializable Objects:</strong> Support for complex object storage in sessions</li>");
        out.println("</ul>");
        out.println("</div>");
        
        out.println("<a href='index.html' class='back-link'>&larr; Back to Home</a>");
        
        out.println("<div class='footer'>");
        out.println("<p>WebLogic Server Session Management Demo</p>");
        out.println("<p>Session data is automatically replicated in clustered environments</p>");
        out.println("</div>");
        
        out.println("</div>");
        out.println("</body>");
        out.println("</html>");
    }
}
