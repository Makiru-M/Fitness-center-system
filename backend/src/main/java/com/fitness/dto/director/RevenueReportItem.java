package com.fitness.dto.director;

import java.math.BigDecimal;

public record RevenueReportItem(
        String category,
        Long salesCount,
        BigDecimal fullPriceTotal,
        BigDecimal actualRevenue,
        BigDecimal totalDiscounts,
        Long promoCodeUsage,
        Double revenueSharePercent,
        BigDecimal cumulativeRevenue
) {
    public RevenueReportItem(String category, Long salesCount, BigDecimal fullPriceTotal, BigDecimal actualRevenue, BigDecimal totalDiscounts, Long promoCodeUsage) {
        this(category, salesCount, fullPriceTotal, actualRevenue, totalDiscounts, promoCodeUsage, 0.0, actualRevenue);
    }
}
