package com.fitness.dto.client;

import java.math.BigDecimal;
import java.time.LocalDate;

public record ClientSubscriptionDto(
        Integer clientSubId,
        Integer saleId,
        String itemName,
        LocalDate startDate,
        LocalDate endDate,
        String currentStatus,
        Integer remainingFreezingDays,
        BigDecimal salePrice
) {}
