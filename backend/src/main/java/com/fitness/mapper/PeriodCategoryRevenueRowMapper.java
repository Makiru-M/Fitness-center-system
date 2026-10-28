package com.fitness.mapper;

import com.fitness.dto.director.PeriodCategoryRevenueRecord;
import com.fitness.dto.director.RevenueReportItem;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;

public class PeriodCategoryRevenueRowMapper implements RowMapper<PeriodCategoryRevenueRecord> {
    public static final PeriodCategoryRevenueRowMapper INSTANCE = new PeriodCategoryRevenueRowMapper();

    @Override
    public PeriodCategoryRevenueRecord mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new PeriodCategoryRevenueRecord(
                rs.getString("PeriodLabel"),
                rs.getDate("PeriodStart") != null ? rs.getDate("PeriodStart").toLocalDate() : null,
                rs.getDate("PeriodEnd") != null ? rs.getDate("PeriodEnd").toLocalDate() : null,
                new RevenueReportItem(
                        rs.getString("Category"),
                        rs.getLong("Sales_Count"),
                        rs.getBigDecimal("Full_Price_Total"),
                        rs.getBigDecimal("Actual_Revenue"),
                        rs.getBigDecimal("Total_Discounts"),
                        rs.getLong("Promo_Code_Usage"),
                        rs.getObject("RevenueSharePercent") != null ? rs.getDouble("RevenueSharePercent") : 0.0,
                        rs.getBigDecimal("CumulativeRevenue")
                )
        );
    }
}
