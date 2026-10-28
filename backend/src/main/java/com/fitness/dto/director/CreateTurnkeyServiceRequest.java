package com.fitness.dto.director;

import com.fasterxml.jackson.annotation.JsonAlias;
import java.math.BigDecimal;
import java.time.LocalTime;

public record CreateTurnkeyServiceRequest(
        @JsonAlias({"name", "item_name"}) String itemName,
        String category,
        BigDecimal price,
        String description,
        // Membership fields
        Integer durationDays,
        Integer maxFreezingDays,
        // Group training fields
        Integer dayOfWeek,
        LocalTime startTime,
        Integer durationMinutes,
        Integer hallId,
        Integer coachId
) {}
