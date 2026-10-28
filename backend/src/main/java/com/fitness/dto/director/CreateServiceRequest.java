package com.fitness.dto.director;

import com.fasterxml.jackson.annotation.JsonAlias;
import java.math.BigDecimal;

public record CreateServiceRequest(
        @JsonAlias({"name", "item_name"}) String itemName,
        String category,
        BigDecimal price,
        String description
) {}
