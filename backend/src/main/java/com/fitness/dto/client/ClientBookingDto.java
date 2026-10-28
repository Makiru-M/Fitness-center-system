package com.fitness.dto.client;

import java.time.LocalDateTime;

public record ClientBookingDto(
        Integer bookingId,
        Integer instanceId,
        String activityType, // "Personal" or "Group"
        String title,
        String coachName,
        String hallName,
        LocalDateTime trainingDateTime,
        String status
) {}
