package com.fitness.dto.director;

import java.time.LocalTime;

public record CreateScheduleTemplateRequest(
        Integer classTypeId,
        Integer dayOfWeek,
        LocalTime startTime,
        Integer durationMinutes,
        Integer hallId,
        Integer coachId
) {}
