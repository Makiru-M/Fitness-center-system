package com.fitness.dto.manager;

import java.time.LocalDate;

public record FreezeRequest(
        Integer clientSubId,
        LocalDate startDate,
        LocalDate endDate,
        String reason
) {}
