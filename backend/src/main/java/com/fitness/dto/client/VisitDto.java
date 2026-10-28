package com.fitness.dto.client;

import java.time.LocalDateTime;

public record VisitDto(
        Integer visitId,
        String hallName,
        LocalDateTime checkInTime,
        String itemName
) {}
