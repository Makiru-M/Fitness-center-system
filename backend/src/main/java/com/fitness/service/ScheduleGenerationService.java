package com.fitness.service;

import com.fitness.config.DynamicDataSourceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

/**
 * Service responsible for automatic weekly generation of GroupClassInstances
 * from director's GroupScheduleTemplates.
 */
@Service
public class ScheduleGenerationService {

    private static final Logger log = LoggerFactory.getLogger(ScheduleGenerationService.class);

    private final DynamicDataSourceService dataSourceService;

    public ScheduleGenerationService(DynamicDataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void onApplicationReady() {
        log.info("Application ready: generating weekly group class instances for current and next week...");
        generateWeeklyGroupInstances(1);
    }

    @Scheduled(cron = "0 0 1 * * ?")
    public void scheduledWeeklyGroupInstancesGeneration() {
        log.info("Running scheduled weekly group class instances generation...");
        generateWeeklyGroupInstances(1);
    }

    public void generateWeeklyGroupInstances(int weeksAhead) {
        try {
            dataSourceService.getAdminJdbcTemplate().update("CALL sp_generate_weekly_group_instances(?)", weeksAhead);
            log.info("Successfully executed sp_generate_weekly_group_instances({})", weeksAhead);
        } catch (Exception e) {
            log.error("Failed to execute sp_generate_weekly_group_instances({}): {}", weeksAhead, e.getMessage(), e);
        }
    }
}
