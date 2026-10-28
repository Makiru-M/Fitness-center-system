package com.fitness.dto.guest;

import java.math.BigDecimal;

public record ClassTypePublicDto(
        Integer classTypeId,
        String typeName,
        Integer itemId,
        BigDecimal price
) {}
