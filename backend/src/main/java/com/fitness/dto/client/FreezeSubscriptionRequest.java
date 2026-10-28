package com.fitness.dto.client;

import java.time.LocalDate;

public record FreezeSubscriptionRequest(
        Integer clientSubId,
        LocalDate startDate,
        LocalDate endDate,
        String reason
) {}
