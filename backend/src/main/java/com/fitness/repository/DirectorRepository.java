package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.dto.director.*;
import com.fitness.dto.guest.HallDto;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
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

    /**
     * D1: Revenue report - single analytical query with CTE, window share percentage and cumulative sum
     */
    public List<RevenueReportItem> getRevenueReport(LocalDate fromDate, LocalDate toDate) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        StringBuilder sql = new StringBuilder("""
            WITH Categories AS (
                SELECT unnest(ARRAY['Membership', 'Personal training', 'Group training', 'Extra']) AS Category
            ),
            CategorySales AS (
                SELECT 
                    c.Category,
                    COUNT(s.ID_Sale) AS Sales_Count,
                    COALESCE(SUM(pl.Price), 0.00) AS Full_Price_Total,
                    COALESCE(SUM(s.SalePrice), 0.00) AS Actual_Revenue,
                    COALESCE(SUM(pl.Price - s.SalePrice), 0.00) AS Total_Discounts,
                    COUNT(ap.ID_Promo) AS Promo_Code_Usage
                FROM Categories c
                LEFT JOIN (
                    Sales s 
                    JOIN PriceList pl ON s.ID_Item = pl.ID_Item
            """);

        List<Object> params = new java.util.ArrayList<>();
        if (fromDate != null && toDate != null) {
            sql.append(" AND s.SaleDate >= ?::TIMESTAMP AND s.SaleDate < (?::DATE + INTERVAL '1 day') ");
            params.add(fromDate);
            params.add(toDate);
        }

        sql.append("""
                ) ON c.Category = pl.Category
                LEFT JOIN AppliedPromo ap ON s.ID_Sale = ap.ID_Sale
                GROUP BY c.Category
            )
            SELECT 
                Category,
                Sales_Count,
                Full_Price_Total,
                Actual_Revenue,
                Total_Discounts,
                Promo_Code_Usage,
                ROUND((Actual_Revenue / NULLIF(SUM(Actual_Revenue) OVER (), 0)) * 100, 2) AS RevenueSharePercent,
                SUM(Actual_Revenue) OVER (ORDER BY Actual_Revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeRevenue
            FROM CategorySales
            ORDER BY Actual_Revenue DESC
            """);

        return jdbc.query(sql.toString(), (rs, rowNum) -> new RevenueReportItem(
                rs.getString("Category"),
                rs.getLong("Sales_Count"),
                rs.getBigDecimal("Full_Price_Total"),
                rs.getBigDecimal("Actual_Revenue"),
                rs.getBigDecimal("Total_Discounts"),
                rs.getLong("Promo_Code_Usage"),
                rs.getObject("RevenueSharePercent") != null ? rs.getDouble("RevenueSharePercent") : 0.0,
                rs.getBigDecimal("CumulativeRevenue")
        ), params.toArray());
    }

    /**
     * D2: Attendance report - single analytical query with MODE() WITHIN GROUP for peak hours
     */
    public List<AttendanceReportItem> getAttendanceReport() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT 
                h.HallName,
                h.MaxCapacity,
                COUNT(v.ID_Visit) AS TotalVisits,
                COUNT(DISTINCT s.ID_Client) AS UniqueClients,
                COALESCE(
                    LPAD(MODE() WITHIN GROUP (ORDER BY EXTRACT(HOUR FROM v.CheckInTime)::INT)::TEXT, 2, '0') || ':00 - ' || 
                    LPAD((MODE() WITHIN GROUP (ORDER BY EXTRACT(HOUR FROM v.CheckInTime)::INT) + 1)::TEXT, 2, '0') || ':00',
                    '18:00 - 20:00'
                ) AS PeakHours,
                ROUND(LEAST(100.0, (COUNT(v.ID_Visit)::NUMERIC / NULLIF(h.MaxCapacity, 0)) * 100), 1) AS OccupancyPercent
            FROM Halls h
            LEFT JOIN Visits v ON h.ID_Hall = v.ID_Hall
            LEFT JOIN Sales s ON v.ID_Sale = s.ID_Sale
            WHERE (h.IsActive IS NULL OR h.IsActive = TRUE)
            GROUP BY h.ID_Hall, h.HallName, h.MaxCapacity
            ORDER BY TotalVisits DESC, h.HallName ASC
            """;

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
     * D3: Coach popularity ranking - single analytical query with CTEs and multi-criteria DENSE_RANK window functions (Lab_4.sql)
     */
    public List<CoachPerformanceDto> getCoachPopularity() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            WITH GroupStats AS (
                SELECT 
                    gst.ID_Coach,
                    COUNT(gci.ID_Instance) AS GroupClassesCount,
                    ROUND(COALESCE(AVG(gci.ActualAttendance), 0), 2) AS AvgGroupSize
                FROM GroupScheduleTemplates gst
                JOIN GroupClassInstances gci ON gst.ID_Template = gci.ID_Template
                WHERE gci.ClassStatus IN ('Completed', 'Attended')
                GROUP BY gst.ID_Coach
            ),
            PersonalStats AS (
                SELECT 
                    pt.ID_Coach,
                    COUNT(DISTINCT sl.ID_Client) AS IndividualClientsCount,
                    COUNT(pt.ID_Personal) AS CompletedPersonalClassesCount
                FROM PersonalTrainings pt
                JOIN Sales sl ON pt.ID_Sale = sl.ID_Sale
                WHERE pt.TrainingStatus IN ('Completed', 'Attended')
                GROUP BY pt.ID_Coach
            ),
            CoachStats AS (
                SELECT 
                    c.ID_Coach AS CoachId,
                    s.FullName,
                    sp.SpecName,
                    COALESCE(gs.GroupClassesCount, 0) AS GroupClassesCount,
                    COALESCE(gs.AvgGroupSize, 0) AS AvgGroupSize,
                    COALESCE(ps.IndividualClientsCount, 0) AS IndividualClientsCount,
                    COALESCE(ps.CompletedPersonalClassesCount, 0) AS PersonalCount
                FROM Coaches c
                JOIN Staff s ON c.ID_Staff = s.ID_Staff
                JOIN Specializations sp ON c.ID_Spec = sp.ID_Spec
                LEFT JOIN GroupStats gs ON c.ID_Coach = gs.ID_Coach
                LEFT JOIN PersonalStats ps ON c.ID_Coach = ps.ID_Coach
                WHERE s.FireDate IS NULL
            )
            SELECT 
                CoachId,
                FullName,
                SpecName,
                PersonalCount,
                IndividualClientsCount,
                GroupClassesCount AS GroupCount,
                (PersonalCount + GroupClassesCount) AS TotalClasses,
                AvgGroupSize,
                DENSE_RANK() OVER (ORDER BY GroupClassesCount DESC) AS RankByGroupClasses,
                DENSE_RANK() OVER (ORDER BY AvgGroupSize DESC) AS RankByAvgGroupSize,
                DENSE_RANK() OVER (ORDER BY IndividualClientsCount DESC) AS RankByIndividualClients,
                DENSE_RANK() OVER (ORDER BY (PersonalCount * 1.5 + GroupClassesCount * AvgGroupSize) DESC) AS KpiRank,
                ROUND((PersonalCount * 1.5 + GroupClassesCount * AvgGroupSize)::NUMERIC, 1) AS Kpi
            FROM CoachStats
            ORDER BY KpiRank ASC, TotalClasses DESC
            """;

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
     * D4: Hall occupancy report - single analytical query with CTEs, traffic share percentage and DENSE_RANK
     */
    public List<HallOccupancyDto> getHallsOccupancy() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            WITH HallVisits AS (
                SELECT ID_Hall, COUNT(ID_Visit) AS VisitsCount
                FROM Visits
                GROUP BY ID_Hall
            ),
            HallGroups AS (
                SELECT gst.ID_Hall, COUNT(gci.ID_Instance) AS GroupSlotsCount
                FROM GroupScheduleTemplates gst
                JOIN GroupClassInstances gci ON gst.ID_Template = gci.ID_Template
                WHERE gci.ClassStatus <> 'Cancelled'
                GROUP BY gst.ID_Hall
            )
            SELECT 
                h.ID_Hall AS HallId,
                h.HallName,
                h.MaxCapacity,
                COALESCE(hv.VisitsCount, 0) AS VisitsCount,
                COALESCE(hg.GroupSlotsCount, 0) AS GroupSlotsCount,
                ROUND(LEAST(100.0, (COALESCE(hv.VisitsCount, 0)::NUMERIC / NULLIF(h.MaxCapacity, 0)) * 100), 1) AS OccupancyPercent,
                ROUND((COALESCE(hv.VisitsCount, 0)::NUMERIC / NULLIF(SUM(COALESCE(hv.VisitsCount, 0)) OVER (), 0)) * 100, 2) AS TrafficSharePercent,
                DENSE_RANK() OVER (ORDER BY COALESCE(hv.VisitsCount, 0) DESC) AS RankByTraffic
            FROM Halls h
            LEFT JOIN HallVisits hv ON h.ID_Hall = hv.ID_Hall
            LEFT JOIN HallGroups hg ON h.ID_Hall = hg.ID_Hall
            WHERE (h.IsActive IS NULL OR h.IsActive = TRUE)
            ORDER BY RankByTraffic ASC, h.ID_Hall ASC
            """;

        return jdbc.query(sql, (rs, rowNum) -> new HallOccupancyDto(
                rs.getInt("HallId"),
                rs.getString("HallName"),
                rs.getInt("MaxCapacity"),
                rs.getLong("VisitsCount"),
                rs.getLong("GroupSlotsCount"),
                rs.getDouble("OccupancyPercent"),
                rs.getObject("TrafficSharePercent") != null ? rs.getDouble("TrafficSharePercent") : 0.0,
                rs.getLong("RankByTraffic")
        ));
    }

    /**
     * D5: Problematic areas and risk analysis - single analytical UNION ALL query
     */
    public List<ProblemAreaDto> getIssuesAnalysis() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT 
                c.FullName AS ClientName,
                COALESCE(c.Phone, '—') AS Phone,
                'Прострочений абонемент' AS ProblemType,
                'Закінчився ' || cs.EndDate::TEXT || ' (' || (CURRENT_DATE - cs.EndDate)::TEXT || ' дн. тому)' AS Details,
                'Запропонувати продовження абонемента' AS RecommendedAction
            FROM ClientSubscriptions cs
            JOIN Sales s ON cs.ID_Sale = s.ID_Sale
            JOIN Clients c ON s.ID_Client = c.ID_Client
            WHERE cs.EndDate < CURRENT_DATE AND cs.CurrentStatus <> 'Expired'

            UNION ALL

            SELECT 
                c.FullName AS ClientName,
                COALESCE(c.Phone, '—') AS Phone,
                'Часті неявки (No-show)' AS ProblemType,
                'Кількість неявок: ' || COUNT(pt.ID_Personal)::TEXT AS Details,
                'З''ясувати причину пропусків' AS RecommendedAction
            FROM Clients c
            JOIN Sales s ON c.ID_Client = s.ID_Client
            JOIN PersonalTrainings pt ON s.ID_Sale = pt.ID_Sale
            WHERE pt.TrainingStatus = 'No-show'
            GROUP BY c.ID_Client, c.FullName, c.Phone
            HAVING COUNT(pt.ID_Personal) >= 1

            UNION ALL

            SELECT 
                cl.FullName AS ClientName,
                COALESCE(cl.Phone, '—') AS Phone,
                'Скасоване тренування' AS ProblemType,
                'Тренер: ' || st.FullName || ', причина: ' || COALESCE(pcl.Reason, 'Не вказано') AS Details,
                'Підібрати інший час заняття' AS RecommendedAction
            FROM PersonalTrainings pt
            JOIN Coaches co ON pt.ID_Coach = co.ID_Coach
            JOIN Staff st ON co.ID_Staff = st.ID_Staff
            JOIN Sales sl ON pt.ID_Sale = sl.ID_Sale
            JOIN Clients cl ON sl.ID_Client = cl.ID_Client
            LEFT JOIN PT_Changelog pcl ON pt.ID_Personal = pcl.ID_Personal
            WHERE pt.TrainingStatus = 'Cancelled'

            ORDER BY ProblemType, ClientName
            """;

        return jdbc.query(sql, (rs, rowNum) -> new ProblemAreaDto(
                rs.getString("ClientName"),
                rs.getString("Phone"),
                rs.getString("ProblemType"),
                rs.getString("Details"),
                rs.getString("RecommendedAction")
        ));
    }

    /**
     * D6: Change log audit - single analytical query joining PT_Changelog and PT_TimeChangeDetails with ROW_NUMBER and LAG
     */
    public List<PtAuditLogDto> getAuditLog() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT 
                cl.ChangeTimestamp,
                cl.ID_Personal AS PersonalId,
                cl.RequestType,
                cl.ChangeInitiator,
                cl.Reason,
                CASE 
                    WHEN cl.RequestType = 'Cancel' THEN 'Скасовано'
                    WHEN tcd.NewDateTime IS NOT NULL THEN TO_CHAR(tcd.NewDateTime, 'YYYY-MM-DD HH24:MI')
                    ELSE 'Не вказано'
                END AS NewTime,
                ROW_NUMBER() OVER (PARTITION BY cl.ID_Personal ORDER BY cl.ChangeTimestamp ASC) AS ChangeSeqNum,
                LAG(cl.ChangeTimestamp) OVER (PARTITION BY cl.ID_Personal ORDER BY cl.ChangeTimestamp ASC) AS PreviousChangeTime
            FROM PT_Changelog cl
            LEFT JOIN PT_TimeChangeDetails tcd ON cl.ID_PTLog = tcd.ID_PTLog
            ORDER BY cl.ChangeTimestamp DESC
            """;

        return jdbc.query(sql, (rs, rowNum) -> new PtAuditLogDto(
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
     * View v_GroupIndividualClientsShare from Lab_4.sql
     */
    public List<GroupIndividualShareItem> getGroupIndividualShareView() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT * FROM v_GroupIndividualClientsShare ORDER BY PersonalTrainingSharePercent DESC";

        return jdbc.query(sql, (rs, rowNum) -> new GroupIndividualShareItem(
                rs.getInt("ID_Template"),
                rs.getString("GroupType"),
                rs.getInt("DayOfWeek"),
                rs.getTime("StartTime").toLocalTime(),
                rs.getLong("TotalGroupClients"),
                rs.getLong("ClientsWithPersonalTrainings"),
                rs.getDouble("PersonalTrainingSharePercent")
        ));
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
     * D10: Create turnkey service (via sp_create_service_turnkey)
     */
    public Map<String, Object> createTurnkeyService(CreateTurnkeyServiceRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT * FROM sp_create_service_turnkey(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        return jdbc.queryForMap(sql,
                req.itemName(),
                req.category(),
                req.price(),
                req.description(),
                req.durationDays(),
                req.maxFreezingDays(),
                req.dayOfWeek(),
                req.startTime(),
                req.durationMinutes(),
                req.hallId(),
                req.coachId()
        );
    }

    /**
     * D10: Deactivate / soft delete price item (via sp_deactivate_price_item)
     */
    public Map<String, Object> deactivatePriceItem(Integer itemId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT * FROM sp_deactivate_price_item(?)";
        return jdbc.queryForMap(sql, itemId);
    }
}
