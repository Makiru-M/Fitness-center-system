package com.fitness.dto.director;

import java.math.BigDecimal;

public record ManagerPerformanceDto(
    Integer managerId,
    String fullName,
    String phone,
    Long salesCount,
    BigDecimal totalRevenue,
    BigDecimal totalDiscounts,
    Double revenueSharePercent,
    Long revenueRank
) {}
