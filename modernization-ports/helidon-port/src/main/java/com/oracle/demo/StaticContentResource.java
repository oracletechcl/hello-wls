package com.oracle.demo;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.io.InputStream;

/**
 * JAX-RS resource to serve static content from classpath.
 * Serves index.html and swagger-ui.html from /static directory.
 */
@Path("/")
public class StaticContentResource {

    @GET
    @Produces(MediaType.TEXT_HTML)
    public Response getIndex() {
        return serveStaticFile("index.html");
    }

    @GET
    @Path("swagger-ui.html")
    @Produces(MediaType.TEXT_HTML)
    public Response getSwaggerUI() {
        return serveStaticFile("swagger-ui.html");
    }

    private Response serveStaticFile(String filename) {
        try {
            InputStream is = getClass().getClassLoader().getResourceAsStream("static/" + filename);
            if (is == null) {
                return Response.status(Response.Status.NOT_FOUND)
                        .entity("File not found: " + filename)
                        .build();
            }
            
            String contentType = filename.endsWith(".html") ? MediaType.TEXT_HTML : MediaType.TEXT_PLAIN;
            return Response.ok(is)
                    .type(contentType)
                    .build();
                    
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("Error loading file: " + e.getMessage())
                    .build();
        }
    }
}
