package com.fitness.dto.manager;

import java.time.LocalDateTime;

public record ScheduleChangeRequestDto(
        Integer logId,
        Integer personalId,
        String coachName,
        String clientName,
        String requestType,
        String reason,
        LocalDateTime requestTimestamp,
        LocalDateTime currentDateTime,
        LocalDateTime proposedDateTime,
        String status
) {}
