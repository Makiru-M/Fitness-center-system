package com.fitness.dto.director;

import java.time.LocalDate;

public record PeriodCategoryRevenueRecord(
        String periodLabel,
        LocalDate periodStart,
        LocalDate periodEnd,
        RevenueReportItem item
) {}
