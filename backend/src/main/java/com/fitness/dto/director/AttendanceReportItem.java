package com.fitness.dto.director;

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
