package com.oracle.demo;

import com.oracle.demo.model.HostInfo;
import io.helidon.microprofile.tests.junit5.HelidonTest;
import jakarta.inject.Inject;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.junit.jupiter.api.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;

/**
 * Unit tests for Helidon MP Host Information API
 */
@HelidonTest
class HostInfoResourceTest {

    @Inject
    private WebTarget target;

    @Test
    void testHostInfoEndpoint() {
        Response response = target.path("/api/host-info")
                .request(MediaType.APPLICATION_JSON)
                .get();

        assertThat("Response status", response.getStatus(), is(200));
        
        HostInfo hostInfo = response.readEntity(HostInfo.class);
        assertThat("Hostname is not null", hostInfo.getHostname(), is(notNullValue()));
        assertThat("Server time is not null", hostInfo.getServerTime(), is(notNullValue()));
        assertThat("OS info is not null", hostInfo.getOsInfo(), is(notNullValue()));
        assertThat("Java info is not null", hostInfo.getJavaInfo(), is(notNullValue()));
        assertThat("Memory info is not null", hostInfo.getMemoryInfo(), is(notNullValue()));
    }

    @Test
    void testGreetingEndpoint() {
        Response response = target.path("/api/greet")
                .queryParam("name", "TestUser")
                .request(MediaType.APPLICATION_JSON)
                .get();

        assertThat("Response status", response.getStatus(), is(200));
        
        String body = response.readEntity(String.class);
        assertThat("Response contains greeting", body, containsString("Hello, TestUser!"));
    }

    @Test
    void testGreetingEndpointWithoutName() {
        Response response = target.path("/api/greet")
                .request(MediaType.APPLICATION_JSON)
                .get();

        assertThat("Response status", response.getStatus(), is(200));
        
        String body = response.readEntity(String.class);
        assertThat("Response contains guest greeting", body, containsString("Hello, Guest!"));
    }

    @Test
    void testWelcomeEndpoint() {
        Response response = target.path("/api/greet/welcome")
                .request(MediaType.APPLICATION_JSON)
                .get();

        assertThat("Response status", response.getStatus(), is(200));
        
        String body = response.readEntity(String.class);
        assertThat("Response contains welcome message", body, containsString("Welcome to Helidon MP"));
    }

    @Test
    void testDatabaseInfoEndpoint() {
        Response response = target.path("/api/database-info")
                .request(MediaType.APPLICATION_JSON)
                .get();

        assertThat("Response status", response.getStatus(), is(200));
        
        String body = response.readEntity(String.class);
        // In mock mode, should return mock status
        assertThat("Response contains mock mode info", body, containsString("mockMode"));
    }

    @Test
    void testSessionEndpoint() {
        Response response = target.path("/api/session")
                .request(MediaType.APPLICATION_JSON)
                .get();

        assertThat("Response status", response.getStatus(), is(200));
        
        String body = response.readEntity(String.class);
        assertThat("Response contains session ID", body, containsString("sessionId"));
        assertThat("Response contains visit count", body, containsString("visitCount"));
    }

    @Test
    void testHealthEndpoint() {
        Response response = target.path("/health")
                .request(MediaType.APPLICATION_JSON)
                .get();

        assertThat("Health check status", response.getStatus(), is(200));
    }

    @Test
    void testOpenApiEndpoint() {
        Response response = target.path("/openapi")
                .request(MediaType.APPLICATION_JSON)
                .get();

        assertThat("OpenAPI status", response.getStatus(), is(200));
    }
}
