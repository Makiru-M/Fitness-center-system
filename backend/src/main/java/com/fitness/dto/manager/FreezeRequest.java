package com.fitness.dto.manager;

import java.time.LocalDate;

public record FreezeRequest(
        Integer clientSubscriptionId,
        LocalDate startDate,
        LocalDate endDate,
        String reason
) {}
