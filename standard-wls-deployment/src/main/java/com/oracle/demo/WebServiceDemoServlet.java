package com.oracle.demo;

import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.util.Date;

/**
 * Servlet that demonstrates EJB and Web Service integration.
 * Calls the stateless session bean to show EJB dependency injection.
 */
public class WebServiceDemoServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    
    /**
     * Inject the stateless session bean using @EJB annotation.
     * WebLogic Server automatically handles the dependency injection.
     */
    @EJB
    private GreetingService greetingService;
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        
        try {
            // Get parameters
            String name = request.getParameter("name");
            String action = request.getParameter("action");
            
            // Generate HTML
            generateHTML(out, name, action);
            
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
    
    private void generateHTML(PrintWriter out, String name, String action) {
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<title>WebLogic EJB & Web Service Demo</title>");
        out.println("<style>");
        out.println("body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }");
        out.println("h1 { color: #c74634; }");
        out.println("h2 { color: #333; margin-top: 30px; }");
        out.println(".container { background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }");
        out.println(".header { background-color: #c74634; color: white; padding: 20px; border-radius: 8px 8px 0 0; margin: -30px -30px 20px -30px; }");
        out.println(".info-section { margin-bottom: 30px; }");
        out.println(".result-box { background-color: #d4edda; border: 2px solid #28a745; padding: 20px; border-radius: 5px; margin: 20px 0; }");
        out.println(".result-text { font-size: 18px; font-weight: bold; color: #155724; }");
        out.println(".form-section { background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; }");
        out.println(".form-group { margin-bottom: 15px; }");
        out.println("label { display: block; margin-bottom: 5px; font-weight: bold; color: #555; }");
        out.println("input[type='text'] { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; font-size: 14px; }");
        out.println(".btn { display: inline-block; padding: 12px 24px; margin: 5px; background-color: #c74634; color: white; text-decoration: none; border-radius: 5px; border: none; cursor: pointer; font-size: 14px; }");
        out.println(".btn:hover { background-color: #a33829; }");
        out.println(".btn-secondary { background-color: #6c757d; }");
        out.println(".btn-secondary:hover { background-color: #5a6268; }");
        out.println("table { border-collapse: collapse; width: 100%; margin-top: 10px; }");
        out.println("td { padding: 10px; border-bottom: 1px solid #ddd; }");
        out.println("td:first-child { font-weight: bold; width: 200px; color: #555; }");
        out.println("td:last-child { color: #333; word-break: break-all; }");
        out.println(".code-block { background-color: #f4f4f4; padding: 15px; border-radius: 4px; font-family: monospace; font-size: 12px; overflow-x: auto; margin: 10px 0; }");
        out.println(".back-link { display: inline-block; margin-top: 20px; color: #c74634; text-decoration: none; }");
        out.println(".back-link:hover { text-decoration: underline; }");
        out.println(".footer { margin-top: 30px; text-align: center; color: #777; font-size: 12px; }");
        out.println(".highlight { background-color: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 20px 0; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body>");
        out.println("<div class='container'>");
        out.println("<div class='header'>");
        out.println("<h1>EJB & Web Service Demo</h1>");
        out.println("<p>Stateless Session Bean with JAX-WS Web Service</p>");
        out.println("<p style='font-size: 14px;'>Server Time: " + new Date() + "</p>");
        String serverName = System.getProperty("weblogic.Name", "Unknown");
        out.println("<p><strong>Managed Server: " + serverName + "</strong></p>");
        out.println("</div>");
        
        // EJB Invocation Results
        if (name != null || "info".equals(action)) {
            out.println("<div class='info-section'>");
            out.println("<h2>EJB Method Invocation Results</h2>");
            
            if (name != null && !name.trim().isEmpty()) {
                String greetingResult = greetingService.greet(name);
                String welcomeResult = greetingService.getWelcomeMessage();
                
                out.println("<div class='result-box'>");
                out.println("<h3>Greet Method:</h3>");
                out.println("<p class='result-text'>" + greetingResult + "</p>");
                out.println("</div>");
                
                out.println("<div class='result-box'>");
                out.println("<h3>Welcome Message Method:</h3>");
                out.println("<p class='result-text'>" + welcomeResult + "</p>");
                out.println("</div>");
            }
            
            if ("info".equals(action)) {
                String serviceInfo = greetingService.getServiceInfo();
                out.println("<div class='result-box'>");
                out.println("<h3>Service Information:</h3>");
                out.println("<p class='result-text'>" + serviceInfo + "</p>");
                out.println("</div>");
            }
            out.println("</div>");
        }
        
        // Interactive Form
        out.println("<div class='info-section'>");
        out.println("<h2>Test EJB Methods</h2>");
        out.println("<div class='form-section'>");
        out.println("<form method='GET' action='webservice'>");
        out.println("<div class='form-group'>");
        out.println("<label for='name'>Enter Your Name:</label>");
        out.println("<input type='text' id='name' name='name' placeholder='Enter your name' value='" + 
                    (name != null ? name : "") + "' required>");
        out.println("</div>");
        out.println("<button type='submit' class='btn'>Call greet() Method</button> ");
        out.println("<button type='submit' name='action' value='info' class='btn btn-secondary'>Get Service Info</button>");
        out.println("</form>");
        out.println("</div>");
        out.println("</div>");
        
        // EJB Information
        out.println("<div class='info-section'>");
        out.println("<h2>EJB & Web Service Details</h2>");
        out.println("<table>");
        out.println("<tr><td>EJB Type</td><td>Stateless Session Bean</td></tr>");
        out.println("<tr><td>Bean Class</td><td>com.oracle.demo.GreetingServiceBean</td></tr>");
        out.println("<tr><td>Web Service Type</td><td>JAX-WS (SOAP)</td></tr>");
        out.println("<tr><td>Service Name</td><td>GreetingService</td></tr>");
        out.println("<tr><td>Target Namespace</td><td>http://demo.oracle.com/</td></tr>");
        out.println("<tr><td>Injection Type</td><td>@EJB Annotation (Container-Managed)</td></tr>");
        
        try {
            InetAddress localhost = InetAddress.getLocalHost();
            String hostname = localhost.getHostName();
            out.println("<tr><td>Server Host</td><td>" + hostname + "</td></tr>");
        } catch (Exception e) {
            out.println("<tr><td>Server Host</td><td>Unknown</td></tr>");
        }
        
        out.println("</table>");
        out.println("</div>");
        
        // WSDL Access
        out.println("<div class='info-section'>");
        out.println("<h2>Web Service WSDL</h2>");
        out.println("<div class='highlight'>");
        out.println("<p><strong>Important:</strong> After deployment, the WSDL will be automatically generated by WebLogic Server.</p>");
        out.println("<p>Access the WSDL at:</p>");
        out.println("<div class='code-block'>");
        out.println("http://&lt;server&gt;:&lt;port&gt;/hostinfo/GreetingServiceBean?WSDL");
        out.println("</div>");
        out.println("<p>For local deployment:</p>");
        out.println("<div class='code-block'>");
        out.println("http://localhost:7001/hostinfo/GreetingServiceBean?WSDL");
        out.println("</div>");
        out.println("</div>");
        out.println("</div>");
        
        // Available Methods
        out.println("<div class='info-section'>");
        out.println("<h2>Available Web Service Operations</h2>");
        out.println("<table>");
        out.println("<tr><td><strong>greet(String name)</strong></td><td>Returns a greeting message</td></tr>");
        out.println("<tr><td><strong>getWelcomeMessage(String name)</strong></td><td>Returns a detailed welcome message with timestamp</td></tr>");
        out.println("<tr><td><strong>getServiceInfo()</strong></td><td>Returns information about the web service</td></tr>");
        out.println("</table>");
        out.println("</div>");
        
        // EJB Features
        out.println("<div class='info-section'>");
        out.println("<h2>EJB 3.x Features Demonstrated</h2>");
        out.println("<ul>");
        out.println("<li><strong>Stateless Session Beans:</strong> No conversational state maintained between method calls</li>");
        out.println("<li><strong>Annotation-Based Configuration:</strong> @Stateless and @WebService annotations instead of XML</li>");
        out.println("<li><strong>Dependency Injection:</strong> @EJB annotation for automatic bean injection</li>");
        out.println("<li><strong>JAX-WS Integration:</strong> SOAP-based web services with automatic WSDL generation</li>");
        out.println("<li><strong>Container-Managed Lifecycle:</strong> WebLogic manages bean pooling and lifecycle</li>");
        out.println("<li><strong>Transaction Management:</strong> Built-in container-managed transactions</li>");
        out.println("<li><strong>Thread Safety:</strong> Container ensures thread-safe execution</li>");
        out.println("<li><strong>Scalability:</strong> Bean pooling for optimal resource utilization</li>");
        out.println("</ul>");
        out.println("</div>");
        
        // Testing with SOAP Client
        out.println("<div class='info-section'>");
        out.println("<h2>Testing with SOAP Client</h2>");
        out.println("<p>You can test this web service using any SOAP client (SoapUI, Postman, curl, etc.):</p>");
        out.println("<div class='code-block'>");
        out.println("&lt;soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" <br>");
        out.println("&nbsp;&nbsp;xmlns:dem=\"http://demo.oracle.com/\"&gt;<br>");
        out.println("&nbsp;&nbsp;&lt;soapenv:Header/&gt;<br>");
        out.println("&nbsp;&nbsp;&lt;soapenv:Body&gt;<br>");
        out.println("&nbsp;&nbsp;&nbsp;&nbsp;&lt;dem:greet&gt;<br>");
        out.println("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;name&gt;John&lt;/name&gt;<br>");
        out.println("&nbsp;&nbsp;&nbsp;&nbsp;&lt;/dem:greet&gt;<br>");
        out.println("&nbsp;&nbsp;&lt;/soapenv:Body&gt;<br>");
        out.println("&lt;/soapenv:Envelope&gt;");
        out.println("</div>");
        out.println("</div>");
        
        out.println("<a href='index.html' class='back-link'>&larr; Back to Home</a>");
        
        out.println("<div class='footer'>");
        out.println("<p>WebLogic Server EJB 3.x & JAX-WS Web Service Demo</p>");
        out.println("<p>Stateless Session Bean with SOAP Web Service</p>");
        out.println("</div>");
        
        out.println("</div>");
        out.println("</body>");
        out.println("</html>");
    }
}
