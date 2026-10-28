package com.fitness.dto.director;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record RevenuePeriodReport(
    String periodLabel,
    LocalDate periodStart,
    LocalDate periodEnd,
    BigDecimal totalRevenue,
    Long totalSalesCount,
    List<RevenueReportItem> categories
) {}
