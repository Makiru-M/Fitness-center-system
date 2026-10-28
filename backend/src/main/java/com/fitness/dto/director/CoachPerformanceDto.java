package com.fitness.dto.director;

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
