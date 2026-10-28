package com.fitness.dto.director;

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
