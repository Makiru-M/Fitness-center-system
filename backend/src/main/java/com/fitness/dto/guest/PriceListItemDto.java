package com.fitness.dto.guest;

import java.math.BigDecimal;
import java.time.LocalDate;

public record PriceListItemDto(
        Integer itemId,
        String itemName,
        String category,
        BigDecimal price,
        Integer durationDays,
        Integer maxFreezingDays,
        String description,
        LocalDate priceStartDate,
        LocalDate priceEndDate,
        Boolean isActive
) {
    public PriceListItemDto(
            Integer itemId,
            String itemName,
            String category,
            BigDecimal price,
            Integer durationDays,
            Integer maxFreezingDays,
            String description
    ) {
        this(itemId, itemName, category, price, durationDays, maxFreezingDays, description, null, null, true);
    }
}
