package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.dto.director.*;
import com.fitness.dto.guest.ClassTypePublicDto;
import com.fitness.dto.guest.HallDto;
import com.fitness.mapper.PeriodCategoryRevenueRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Repository
@Transactional
public class DirectorRepository {

    private final DynamicDataSourceService dataSourceService;

    public DirectorRepository(DynamicDataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    private List<PeriodCategoryRevenueRecord> executePeriodicRevenueQuery(
            String dateTruncUnit,
            String intervalUnit,
            String endIntervalUnit,
            String labelSqlExpression,
            LocalDate fromDate,
            LocalDate toDate
    ) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String periodsCte = "total".equalsIgnoreCase(dateTruncUnit)
                ? """
                SELECT
                    b.StartDate AS PeriodStart,
                    b.EndDate AS PeriodEnd,
                    'Всього за період' AS PeriodLabel
                FROM Bounds b
                """
                : """
                SELECT
                    date_trunc('%1$s', d)::DATE AS PeriodStart,
                    (date_trunc('%1$s', d) + INTERVAL '%3$s')::DATE AS PeriodEnd,
                    %4$s AS PeriodLabel
                FROM Bounds b,
                     generate_series(date_trunc('%1$s', b.StartDate::TIMESTAMP), date_trunc('%1$s', b.EndDate::TIMESTAMP), INTERVAL '%2$s') d
                """.formatted(dateTruncUnit, intervalUnit, endIntervalUnit, labelSqlExpression);

        String sql = """
            WITH Bounds AS (
                SELECT
                    COALESCE(?::DATE, (SELECT MIN(SaleDate)::DATE FROM Sales), CURRENT_DATE) AS StartDate,
                    COALESCE(?::DATE, CURRENT_DATE) AS EndDate
            ),
            Periods AS (
                %s
            ),
            Categories AS (
                SELECT unnest(enum_range(NULL::service_category)) AS Category
            ),
            PeriodCategories AS (
                SELECT p.PeriodLabel, p.PeriodStart, p.PeriodEnd, c.Category
                FROM Periods p
                CROSS JOIN Categories c
            ),
            AggregatedSales AS (
                SELECT
                    pc.PeriodLabel,
                    pc.PeriodStart,
                    pc.PeriodEnd,
                    pc.Category,
                    COUNT(s.ID_Sale) AS Sales_Count,
                    COALESCE(SUM(pl.Price), 0.00) AS Full_Price_Total,
                    COALESCE(SUM(s.SalePrice), 0.00) AS Actual_Revenue,
                    COALESCE(SUM(pl.Price - s.SalePrice), 0.00) AS Total_Discounts,
                    COUNT(ap.ID_Promo) AS Promo_Code_Usage
                FROM PeriodCategories pc
                LEFT JOIN (
                    Sales s JOIN PriceList pl ON s.ID_Item = pl.ID_Item
                ) ON pc.Category = pl.Category
                 AND s.SaleDate >= pc.PeriodStart::TIMESTAMP
                 AND s.SaleDate < (pc.PeriodEnd + INTERVAL '1 day')
                 AND (?::DATE IS NULL OR s.SaleDate >= ?::TIMESTAMP)
                 AND (?::DATE IS NULL OR s.SaleDate < (?::DATE + INTERVAL '1 day'))
                LEFT JOIN AppliedPromo ap ON s.ID_Sale = ap.ID_Sale
                GROUP BY pc.PeriodLabel, pc.PeriodStart, pc.PeriodEnd, pc.Category
            ),
            ReportWithMetrics AS (
                SELECT
                    PeriodLabel,
                    PeriodStart,
                    PeriodEnd,
                    Category,
                    Sales_Count,
                    Full_Price_Total,
                    Actual_Revenue,
                    Total_Discounts,
                    Promo_Code_Usage,
                    ROUND((Actual_Revenue / NULLIF(SUM(Actual_Revenue) OVER (PARTITION BY PeriodLabel), 0)) * 100, 2) AS RevenueSharePercent,
                    SUM(Actual_Revenue) OVER (PARTITION BY PeriodLabel ORDER BY Actual_Revenue DESC, Category ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeRevenue
                FROM AggregatedSales
            )
            SELECT
                PeriodLabel,
                PeriodStart,
                PeriodEnd,
                Category,
                Sales_Count,
                Full_Price_Total,
                Actual_Revenue,
                Total_Discounts,
                Promo_Code_Usage,
                RevenueSharePercent,
                CumulativeRevenue
            FROM ReportWithMetrics
            ORDER BY PeriodStart ASC, Actual_Revenue DESC, Category ASC
            """.formatted(periodsCte);

        return jdbc.query(sql, PeriodCategoryRevenueRowMapper.INSTANCE, fromDate, toDate, fromDate, fromDate, toDate, toDate);
    }

    /**
     * D1-1: Revenue report - monthly breakdown
     */
    public List<PeriodCategoryRevenueRecord> fetchMonthlyRevenue(LocalDate fromDate, LocalDate toDate) {
        return executePeriodicRevenueQuery(
                "month",
                "1 month",
                "1 month - 1 day",
                "TO_CHAR(d, 'YYYY-MM')",
                fromDate,
                toDate
        );
    }

    /**
     * D1-2: Revenue report - weekly breakdown
     */
    public List<PeriodCategoryRevenueRecord> fetchWeeklyRevenue(LocalDate fromDate, LocalDate toDate) {
        return executePeriodicRevenueQuery(
                "week",
                "1 week",
                "6 days",
                "TO_CHAR(date_trunc('week', d)::DATE, 'DD.MM.YYYY') || ' – ' || TO_CHAR((date_trunc('week', d) + INTERVAL '6 days')::DATE, 'DD.MM.YYYY') || ' (Тиждень ' || TO_CHAR(d, 'IW') || ')'",
                fromDate,
                toDate
        );
    }

    /**
     * D1-3: Revenue report - total aggregate breakdown
     */
    public List<PeriodCategoryRevenueRecord> fetchTotalRevenue(LocalDate fromDate, LocalDate toDate) {
        return executePeriodicRevenueQuery("total", null, null, null, fromDate, toDate);
    }

    /**
     * D2: Attendance report - analytical view v_AttendanceReport
     */
    public List<AttendanceReportItem> getAttendanceReport() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT * FROM v_AttendanceReport";

        return jdbc.query(sql, (rs, rowNum) -> new AttendanceReportItem(
                rs.getString("HallName"),
                rs.getLong("TotalVisits"),
                rs.getLong("UniqueClients"),
                rs.getString("PeakHours"),
                rs.getDouble("OccupancyPercent"),
                rs.getObject("MaxCapacity") != null ? rs.getInt("MaxCapacity") : null
        ));
    }

    /**
     * D3: Coach popularity ranking - analytical view v_CoachPerformance
     */
    public List<CoachPerformanceDto> getCoachPopularity() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT * FROM v_CoachPerformance";

        return jdbc.query(sql, (rs, rowNum) -> new CoachPerformanceDto(
                rs.getInt("CoachId"),
                rs.getString("FullName"),
                rs.getString("SpecName"),
                rs.getLong("PersonalCount"),
                rs.getLong("IndividualClientsCount"),
                rs.getLong("GroupCount"),
                rs.getLong("TotalClasses"),
                rs.getDouble("AvgGroupSize"),
                rs.getDouble("Kpi"),
                rs.getLong("RankByGroupClasses"),
                rs.getLong("RankByAvgGroupSize"),
                rs.getLong("RankByIndividualClients"),
                rs.getLong("KpiRank")
        ));
    }

    /**
     * D5: Problematic areas and risk analysis - analytical view v_ProblemSituations
     */
    public List<ProblemAreaDto> getIssuesAnalysis() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT * FROM v_ProblemSituations";

        return jdbc.query(sql, (rs, rowNum) -> new ProblemAreaDto(
                rs.getString("ClientName"),
                rs.getString("Phone"),
                rs.getString("ProblemType"),
                rs.getString("Details")
        ));
    }

    /**
     * D6: Change log audit - analytical view v_PersonalTrainingsAudit
     */
    public List<PersonalTrainingAuditLogDto> getAuditLog() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT * FROM v_PersonalTrainingsAudit";

        return jdbc.query(sql, (rs, rowNum) -> new PersonalTrainingAuditLogDto(
                rs.getTimestamp("ChangeTimestamp").toLocalDateTime(),
                rs.getInt("PersonalId"),
                rs.getString("RequestType"),
                rs.getString("ChangeInitiator"),
                rs.getString("Reason"),
                rs.getString("NewTime"),
                rs.getLong("ChangeSeqNum"),
                rs.getTimestamp("PreviousChangeTime") != null ? rs.getTimestamp("PreviousChangeTime").toLocalDateTime() : null
        ));
    }

    /**
     * D7: Create new subscription type
     */
    public Integer createSubscriptionType(CreateSubscriptionTypeRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        String category = req.category();
        if (category == null || category.isBlank() || "Subscription".equalsIgnoreCase(category)) {
            category = "Membership";
        }
        Integer itemId = jdbc.queryForObject(
                "INSERT INTO PriceList (ItemName, Category, Price, PriceStartDate, Description) VALUES (?, ?, ?, CURRENT_DATE, ?) RETURNING ID_Item",
                Integer.class, req.itemName(), category, req.price(), req.description()
        );

        if (req.durationDays() != null && req.durationDays() > 0) {
            jdbc.update(
                    "INSERT INTO PriceListSubs (ID_Item, DurationDays, MaxFreezingDays) VALUES (?, ?, ?)",
                    itemId, req.durationDays(), req.maxFreezingDays() != null ? req.maxFreezingDays() : 0
            );
        }

        return itemId;
    }

    /**
     * D10: Create single/extra price list service
     */
    public Integer createService(CreateServiceRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String category = (req.category() != null && !req.category().isBlank()) ? req.category() : "Extra";
        return jdbc.queryForObject(
                "INSERT INTO PriceList (ItemName, Category, Price, PriceStartDate, Description) VALUES (?, ?, ?, CURRENT_DATE, ?) RETURNING ID_Item",
                Integer.class, req.itemName(), category, req.price(), req.description()
        );
    }

    /**
     * D8: Commission hall into operation
     */
    public Integer commissionHall(CommissionHallRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        return jdbc.queryForObject(
                "INSERT INTO Halls (HallName, MaxCapacity, IsActive) VALUES (?, ?, TRUE) RETURNING ID_Hall",
                Integer.class, req.hallName(), req.maxCapacity()
        );
    }

    /**
     * D8: Decommission hall (archive hall / set IsActive = FALSE)
     */
    public void decommissionHall(Integer hallId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        jdbc.update("UPDATE Halls SET IsActive = FALSE WHERE ID_Hall = ?", hallId);
    }

    /**
     * D8: Get archived halls (IsActive = FALSE)
     */
    public List<HallDto> getArchivedHalls() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT ID_Hall, HallName, MaxCapacity FROM Halls WHERE IsActive = FALSE ORDER BY HallName ASC";
        return jdbc.query(sql, (rs, rowNum) -> new HallDto(
                rs.getInt("ID_Hall"),
                rs.getString("HallName"),
                rs.getInt("MaxCapacity")
        ));
    }

    /**
     * D8: Recommission hall (set IsActive = TRUE)
     */
    public void recommissionHall(Integer hallId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        jdbc.update("UPDATE Halls SET IsActive = TRUE WHERE ID_Hall = ?", hallId);
    }

    /**
     * D9: Create promo code
     */
    public Integer createPromoCode(CreatePromoCodeRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        return jdbc.queryForObject(
                "INSERT INTO PromoCodes (CodeText, DiscountPercent, ExpiryDate) VALUES (?, ?, ?) RETURNING ID_Promo",
                Integer.class, req.codeText(), req.discountPercent(), req.expiryDate()
        );
    }

    /**
     * D11: Create group schedule template
     */
    public Integer createScheduleTemplate(CreateScheduleTemplateRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        Integer templateId = jdbc.queryForObject(
                "INSERT INTO GroupScheduleTemplates (ID_ClassType, DayOfWeek, StartTime, DurationMinutes, ID_Hall, ID_Coach) VALUES (?, ?, ?, ?, ?, ?) RETURNING ID_Template",
                Integer.class, req.classTypeId(), req.dayOfWeek(), req.startTime(), req.durationMinutes(), req.hallId(), req.coachId()
        );
        jdbc.execute("CALL sp_generate_weekly_group_instances(1)");
        return templateId;
    }

    /**
     * D10: Update price tariff (versioning via sp_update_price_tariff)
     */
    public Map<String, Object> updatePriceTariff(Integer itemId, BigDecimal newPrice) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT * FROM sp_update_price_tariff(?, ?)";
        return jdbc.queryForMap(sql, itemId, newPrice);
    }

    /**
     * D10: Create membership service in price list (via sp_create_membership_service)
     */
    public Integer createMembershipService(String itemName, BigDecimal price, Integer durationDays, Integer maxFreezingDays, String description) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT sp_create_membership_service(?, ?, ?, ?, ?)";
        return jdbc.queryForObject(sql, Integer.class, itemName, price, durationDays, maxFreezingDays, description);
    }

    /**
     * D10: Create group class service in price list (via sp_create_group_class_service)
     */
    public Map<String, Object> createGroupClassService(String itemName, BigDecimal price, Integer hallId, Integer coachId, Integer dayOfWeek, LocalTime startTime, Integer durationMinutes, String description) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT * FROM sp_create_group_class_service(?, ?, ?, ?, ?, ?, ?, ?)";
        return jdbc.queryForMap(sql, itemName, price, hallId, coachId, dayOfWeek, startTime, durationMinutes, description);
    }

    /**
     * D10: Create price item in price list (via sp_create_price_item)
     */
    public Integer createPriceItem(String itemName, String category, BigDecimal price, String description) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT sp_create_price_item(?, ?::service_category, ?, ?)";
        return jdbc.queryForObject(sql, Integer.class, itemName, category, price, description);
    }

    /**
     * D10: Deactivate / soft delete price item (via sp_deactivate_price_item)
     */
    public Map<String, Object> deactivatePriceItem(Integer itemId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT * FROM sp_deactivate_price_item(?)";
        return jdbc.queryForMap(sql, itemId);
    }

    /**
     * Get all class types with current tariff prices
     */
    public List<ClassTypePublicDto> getClassTypes() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT 
                ct.ID_ClassType,
                ct.TypeName,
                ct.ID_Item,
                pl.Price
            FROM ClassTypes ct
            LEFT JOIN PriceList pl ON ct.ID_Item = pl.ID_Item
            ORDER BY ct.TypeName ASC
            """;

        return jdbc.query(sql, (rs, rowNum) -> new ClassTypePublicDto(
                rs.getInt("ID_ClassType"),
                rs.getString("TypeName"),
                (Integer) rs.getObject("ID_Item"),
                rs.getBigDecimal("Price")
        ));
    }
}
