package com.fitness.dto.director;

import java.math.BigDecimal;

public record ClassTypeDto(
        Integer classTypeId,
        String typeName,
        Integer itemId,
        BigDecimal price
) {}
