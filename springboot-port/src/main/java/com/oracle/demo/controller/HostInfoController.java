package com.oracle.demo.controller;

import com.oracle.demo.model.HostInfo;
import com.oracle.demo.service.HostInfoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for host information
 * Migrated from HostInfoServlet
 */
@RestController
@RequestMapping("/api")
@Tag(name = "Host Information", description = "APIs for retrieving host and server information")
public class HostInfoController {

    @Autowired
    private HostInfoService hostInfoService;

    @GetMapping("/host-info")
    @Operation(summary = "Get host information", description = "Returns detailed information about the host, OS, Java runtime, and memory")
    public HostInfo getHostInfo() {
        return hostInfoService.getHostInfo();
    }
}
