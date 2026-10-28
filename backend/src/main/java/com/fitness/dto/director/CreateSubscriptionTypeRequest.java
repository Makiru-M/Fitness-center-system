package com.fitness.dto.director;

import com.fasterxml.jackson.annotation.JsonAlias;
import java.math.BigDecimal;

public record CreateSubscriptionTypeRequest(
        @JsonAlias({"name", "item_name"}) String itemName,
        String category,
        BigDecimal price,
        Integer durationDays,
        Integer maxFreezingDays,
        String description
) {
    public CreateSubscriptionTypeRequest {
        if (category == null || category.isBlank() || "Subscription".equalsIgnoreCase(category)) {
            category = "Membership";
        }
    }
}
