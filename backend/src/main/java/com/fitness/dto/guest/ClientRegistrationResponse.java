package com.fitness.dto.guest;

import java.math.BigDecimal;
import java.time.LocalDate;

public record ClientRegistrationResponse(
        Integer clientId,
        String dbUsername,
        Integer saleId,
        Integer subscriptionId,
        BigDecimal finalPrice,
        LocalDate endDate
) {}
