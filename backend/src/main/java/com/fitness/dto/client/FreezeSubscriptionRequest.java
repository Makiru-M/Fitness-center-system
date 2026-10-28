package com.fitness.dto.client;

import java.time.LocalDate;

public record FreezeSubscriptionRequest(
        Integer clientSubscriptionId,
        LocalDate startDate,
        LocalDate endDate,
        String reason
) {}
