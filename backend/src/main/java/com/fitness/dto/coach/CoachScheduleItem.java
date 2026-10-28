package com.fitness.dto.coach;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

public record CoachScheduleItem(
        Integer activityId,
        String activityType, // "Personal" or "Group"
        String title,
        String hallName,
        LocalDate scheduleDate,
        LocalTime startTime,
        LocalDateTime startDateTime,
        Integer durationMinutes,
        String status,
        Integer attendanceOrCapacity
) {}
