package com.oracle.demo.controller;

import com.oracle.demo.model.HostInfo;
import com.oracle.demo.service.HostInfoService;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.inject.Inject;

/**
 * REST controller for host information
 * Migrated from HostInfoServlet
 */
@Controller("/api")
@Tag(name = "Host Information", description = "APIs for retrieving host and server information")
public class HostInfoController {

    private final HostInfoService hostInfoService;

    @Inject
    public HostInfoController(HostInfoService hostInfoService) {
        this.hostInfoService = hostInfoService;
    }

    @Get("/host-info")
    @Operation(summary = "Get host information", description = "Returns detailed information about the host, OS, Java runtime, and memory")
    public HostInfo getHostInfo() {
        return hostInfoService.getHostInfo();
    }
}
