package com.fitness.dto.manager;

import java.time.LocalDateTime;

public record CheckInResult(
        Integer visitId,
        Integer clientId,
        String clientName,
        String hallName,
        LocalDateTime checkInTime,
        String subscriptionStatus
) {}
