package com.fitness.model;

import com.fasterxml.jackson.annotation.JsonAlias;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

public class DirectorDto {

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

    public record AttendanceReportItem(
            String hallName,
            Long totalVisits,
            Long uniqueClients,
            String peakHours,
            Double occupancyPercent,
            Integer maxCapacity
    ) {
        public AttendanceReportItem(String hallName, Long totalVisits, Long uniqueClients, String peakHours, Double occupancyPercent) {
            this(hallName, totalVisits, uniqueClients, peakHours, occupancyPercent, null);
        }
    }

    public record CoachPerformanceDto(
            Integer coachId,
            String fullName,
            String coachName,
            String specName,
            Long personalCount,
            Long individualClientsCount,
            Long groupCount,
            Long groupClassesCount,
            Long totalClasses,
            Double avgGroupSize,
            Double kpi,
            Long rankByGroupClasses,
            Long rankByAvgGroupSize,
            Long rankByIndividualClients,
            Long kpiRank
    ) {
        public CoachPerformanceDto(Integer coachId, String fullName, String specName, Long personalCount, Long individualClientsCount, Long groupCount, Long totalClasses, Double avgGroupSize, Double kpi) {
            this(coachId, fullName, fullName, specName, personalCount, individualClientsCount, groupCount, groupCount, totalClasses, avgGroupSize, kpi, 1L, 1L, 1L, 1L);
        }

        public CoachPerformanceDto(Integer coachId, String fullName, String specName, Long personalCount, Long individualClientsCount, Long groupCount, Long totalClasses, Double avgGroupSize, Double kpi, Long rankByGroupClasses, Long rankByAvgGroupSize, Long rankByIndividualClients, Long kpiRank) {
            this(coachId, fullName, fullName, specName, personalCount, individualClientsCount, groupCount, groupCount, totalClasses, avgGroupSize, kpi, rankByGroupClasses, rankByAvgGroupSize, rankByIndividualClients, kpiRank);
        }
    }

    public record CoachRankingItem(
            Integer coachId,
            String fullName,
            String coachName,
            String specName,
            Long personalCount,
            Long individualClientsCount,
            Long groupCount,
            Long groupClassesCount,
            Long totalClasses,
            Double avgGroupSize,
            Double kpi,
            Long rankByGroupClasses,
            Long rankByAvgGroupSize,
            Long rankByIndividualClients,
            Long kpiRank
    ) {
        public CoachRankingItem(Integer coachId, String fullName, String specName, Long personalCount, Long individualClientsCount, Long groupCount, Long totalClasses, Double avgGroupSize, Double kpi) {
            this(coachId, fullName, fullName, specName, personalCount, individualClientsCount, groupCount, groupCount, totalClasses, avgGroupSize, kpi, 1L, 1L, 1L, 1L);
        }

        public CoachRankingItem(Integer coachId, String fullName, String specName, Long personalCount, Long individualClientsCount, Long groupCount, Long totalClasses, Double avgGroupSize, Double kpi, Long rankByGroupClasses, Long rankByAvgGroupSize, Long rankByIndividualClients, Long kpiRank) {
            this(coachId, fullName, fullName, specName, personalCount, individualClientsCount, groupCount, groupCount, totalClasses, avgGroupSize, kpi, rankByGroupClasses, rankByAvgGroupSize, rankByIndividualClients, kpiRank);
        }
    }

    public record HallOccupancyDto(
            Integer hallId,
            String hallName,
            Integer maxCapacity,
            Long visitsCount,
            Long totalVisitors,
            Long groupSlotsCount,
            Long totalTrainingsCount,
            Double occupancyPercent,
            Double trafficSharePercent,
            Long rankByTraffic
    ) {
        public HallOccupancyDto(Integer hallId, String hallName, Integer maxCapacity, Long visitsCount, Long groupSlotsCount, Double occupancyPercent) {
            this(hallId, hallName, maxCapacity, visitsCount, visitsCount, groupSlotsCount, groupSlotsCount, occupancyPercent, 0.0, 1L);
        }

        public HallOccupancyDto(Integer hallId, String hallName, Integer maxCapacity, Long visitsCount, Long groupSlotsCount, Double occupancyPercent, Double trafficSharePercent, Long rankByTraffic) {
            this(hallId, hallName, maxCapacity, visitsCount, visitsCount, groupSlotsCount, groupSlotsCount, occupancyPercent, trafficSharePercent, rankByTraffic);
        }
    }

    public record HallOccupancyItem(
            Integer hallId,
            String hallName,
            Integer maxCapacity,
            Long visitsCount,
            Long totalVisitors,
            Long groupSlotsCount,
            Long totalTrainingsCount,
            Double occupancyPercent,
            Double trafficSharePercent,
            Long rankByTraffic
    ) {
        public HallOccupancyItem(Integer hallId, String hallName, Integer maxCapacity, Long visitsCount, Long groupSlotsCount, Double occupancyPercent) {
            this(hallId, hallName, maxCapacity, visitsCount, visitsCount, groupSlotsCount, groupSlotsCount, occupancyPercent, 0.0, 1L);
        }

        public HallOccupancyItem(Integer hallId, String hallName, Integer maxCapacity, Long visitsCount, Long groupSlotsCount, Double occupancyPercent, Double trafficSharePercent, Long rankByTraffic) {
            this(hallId, hallName, maxCapacity, visitsCount, visitsCount, groupSlotsCount, groupSlotsCount, occupancyPercent, trafficSharePercent, rankByTraffic);
        }
    }

    public record ProblemAreaDto(
            String clientName,
            String clientOrStaffName,
            String phone,
            String problemType,
            String issueType,
            String issueCategory,
            String details,
            String recommendedAction,
            String severity
    ) {
        public ProblemAreaDto(String clientName, String phone, String problemType, String details, String recommendedAction) {
            this(clientName, clientName, phone, problemType, problemType, problemType, details, recommendedAction, "Medium");
        }
    }

    public record IssueAnalysisItem(
            String clientName,
            String clientOrStaffName,
            String phone,
            String problemType,
            String issueType,
            String issueCategory,
            String details,
            String recommendedAction,
            String severity
    ) {
        public IssueAnalysisItem(String clientName, String phone, String problemType, String details, String recommendedAction) {
            this(clientName, clientName, phone, problemType, problemType, problemType, details, recommendedAction, "Medium");
        }
    }

    public record PtAuditLogDto(
            LocalDateTime changeTimestamp,
            Integer personalId,
            Integer logId,
            String requestType,
            String changeInitiator,
            String reason,
            String newTime,
            String details,
            String finalResolution,
            Long changeSeqNum,
            LocalDateTime previousChangeTime
    ) {
        public PtAuditLogDto(LocalDateTime changeTimestamp, Integer personalId, String requestType, String changeInitiator, String reason, String newTime) {
            this(changeTimestamp, personalId, personalId, requestType, changeInitiator, reason, newTime, newTime, newTime, 1L, null);
        }

        public PtAuditLogDto(LocalDateTime changeTimestamp, Integer personalId, String requestType, String changeInitiator, String reason, String newTime, Long changeSeqNum, LocalDateTime previousChangeTime) {
            this(changeTimestamp, personalId, personalId, requestType, changeInitiator, reason, newTime, newTime, newTime, changeSeqNum, previousChangeTime);
        }
    }

    public record AuditLogItem(
            LocalDateTime changeTimestamp,
            Integer personalId,
            Integer logId,
            String requestType,
            String changeInitiator,
            String reason,
            String newTime,
            String details,
            String finalResolution,
            Long changeSeqNum,
            LocalDateTime previousChangeTime
    ) {
        public AuditLogItem(LocalDateTime changeTimestamp, Integer personalId, String requestType, String changeInitiator, String reason, String newTime) {
            this(changeTimestamp, personalId, personalId, requestType, changeInitiator, reason, newTime, newTime, newTime, 1L, null);
        }

        public AuditLogItem(LocalDateTime changeTimestamp, Integer personalId, String requestType, String changeInitiator, String reason, String newTime, Long changeSeqNum, LocalDateTime previousChangeTime) {
            this(changeTimestamp, personalId, personalId, requestType, changeInitiator, reason, newTime, newTime, newTime, changeSeqNum, previousChangeTime);
        }
    }

    public record CreateSubscriptionTypeRequest(
            @JsonAlias({"name", "item_name"}) String itemName,
            String category,
            BigDecimal price,
            Integer durationDays,
            Integer maxFreezingDays,
            String description
    ) {
        public CreateSubscriptionTypeRequest {
            if (category == null || category.isBlank() || "Subscription".equalsIgnoreCase(category)) {
                category = "Membership";
            }
        }
    }

    public record CreateServiceRequest(
            @JsonAlias({"name", "item_name"}) String itemName,
            String category,
            BigDecimal price,
            String description
    ) {}

    public record CommissionHallRequest(
            @JsonAlias({"name", "hall_name"}) String hallName,
            Integer maxCapacity
    ) {}

    public record CreatePromoCodeRequest(
            @JsonAlias({"code", "code_text"}) String codeText,
            Integer discountPercent,
            LocalDate expiryDate
    ) {}

    public record CreateScheduleTemplateRequest(
            Integer classTypeId,
            Integer dayOfWeek,
            LocalTime startTime,
            Integer durationMinutes,
            Integer hallId,
            Integer coachId
    ) {}

    public record GroupIndividualShareItem(
            Integer templateId,
            String groupType,
            Integer dayOfWeek,
            LocalTime startTime,
            Long totalGroupClients,
            Long clientsWithPersonalTrainings,
            Double personalTrainingSharePercent
    ) {}
}
