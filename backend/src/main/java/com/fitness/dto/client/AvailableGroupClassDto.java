package com.fitness.dto.client;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

public record AvailableGroupClassDto(
        Integer instanceId,
        Integer templateId,
        String title,
        String coachName,
        String hallName,
        LocalDate classDate,
        LocalTime startTime,
        Integer durationMinutes,
        String status,
        Integer actualAttendance,
        Integer maxCapacity,
        Integer availableSpots,
        Boolean isBookedByMe,
        BigDecimal price
) {
    public AvailableGroupClassDto(Integer instanceId, Integer templateId, String title, String coachName, String hallName, LocalDate classDate, LocalTime startTime, Integer durationMinutes, String status, Integer actualAttendance, Integer maxCapacity, Integer availableSpots, Boolean isBookedByMe) {
        this(instanceId, templateId, title, coachName, hallName, classDate, startTime, durationMinutes, status, actualAttendance, maxCapacity, availableSpots, isBookedByMe, null);
    }
}
