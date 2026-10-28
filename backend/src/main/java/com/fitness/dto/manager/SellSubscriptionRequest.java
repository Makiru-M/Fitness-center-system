package com.fitness.dto.manager;

import java.time.LocalDate;

public record SellSubscriptionRequest(
        Integer clientId,
        Integer itemId,
        LocalDate startDate,
        String promoCode,
        Integer managerId
) {}
