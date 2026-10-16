package com.fitness.controller;

import com.fitness.config.DynamicDataSourceService;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
public class HealthController {

    private final DynamicDataSourceService dataSourceService;

    public HealthController(DynamicDataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    @GetMapping({"/health", "/api/health"})
    public ResponseEntity<Map<String, Object>> checkHealth() {
        boolean dbOk = false;
        try {
            JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
            Integer res = jdbc.queryForObject("SELECT 1", Integer.class);
            dbOk = (res != null && res == 1);
        } catch (Exception e) {
            // Database might be unreachable or cold
        }

        return ResponseEntity.ok(Map.of(
                "status", "UP",
                "database", dbOk ? "CONNECTED" : "OFFLINE",
                "timestamp", LocalDateTime.now()
        ));
    }
}
