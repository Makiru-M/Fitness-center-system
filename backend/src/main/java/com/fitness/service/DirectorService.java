package com.fitness.service;

import com.fitness.dto.director.CreateTurnkeyServiceRequest;
import com.fitness.dto.director.PeriodCategoryRevenueRecord;
import com.fitness.dto.director.RevenuePeriodReport;
import com.fitness.dto.director.RevenueReportItem;
import com.fitness.dto.guest.ClassTypePublicDto;
import com.fitness.exception.BusinessLogicException;
import com.fitness.repository.DirectorRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class DirectorService {

    private final DirectorRepository directorRepository;

    public DirectorService(DirectorRepository directorRepository) {
        this.directorRepository = directorRepository;
    }

    /**
     * D1: Revenue report - periodic analytical report (TOTAL, MONTH, WEEK)
     */
    public List<RevenuePeriodReport> getRevenueReport(LocalDate fromDate, LocalDate toDate, String groupBy) {
        if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
            throw new BusinessLogicException("Початкова дата не може бути пізнішою за кінцеву дату");
        }

        String mode = groupBy != null ? groupBy.trim().toUpperCase() : "TOTAL";
        List<PeriodCategoryRevenueRecord> records = switch (mode) {
            case "MONTH" -> directorRepository.fetchMonthlyRevenue(fromDate, toDate);
            case "WEEK" -> directorRepository.fetchWeeklyRevenue(fromDate, toDate);
            default -> directorRepository.fetchTotalRevenue(fromDate, toDate);
        };

        Map<String, PeriodData> grouped = new LinkedHashMap<>();
        for (PeriodCategoryRevenueRecord record : records) {
            grouped.computeIfAbsent(record.periodLabel(), k -> new PeriodData(record.periodLabel(), record.periodStart(), record.periodEnd()))
                    .items.add(record.item());
        }

        List<RevenuePeriodReport> reports = new ArrayList<>();
        for (PeriodData data : grouped.values()) {
            BigDecimal totalRevenue = data.items.stream()
                    .map(RevenueReportItem::actualRevenue)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            long totalSalesCount = data.items.stream()
                    .mapToLong(RevenueReportItem::salesCount)
                    .sum();

            reports.add(new RevenuePeriodReport(
                    data.label,
                    data.start,
                    data.end,
                    totalRevenue,
                    totalSalesCount,
                    data.items
            ));
        }

        return reports;
    }

    /**
     * D11: Get all class types
     */
    public List<ClassTypePublicDto> getClassTypes() {
        return directorRepository.getClassTypes();
    }

    /**
     * D10: Create turnkey service routed to specialized procedures
     */
    public Map<String, Object> createTurnkeyService(CreateTurnkeyServiceRequest req) {
        String category = req.category();
        if ("Membership".equalsIgnoreCase(category) || "Subscription".equalsIgnoreCase(category)) {
            Integer itemId = directorRepository.createMembershipService(
                    req.itemName(),
                    req.price(),
                    req.durationDays(),
                    req.maxFreezingDays(),
                    req.description()
            );
            return Map.of(
                    "item_id", itemId,
                    "message", "Послугу абонемента успішно створено"
            );
        } else if ("Group training".equalsIgnoreCase(category)) {
            return directorRepository.createGroupClassService(
                    req.itemName(),
                    req.price(),
                    req.hallId(),
                    req.coachId(),
                    req.dayOfWeek(),
                    req.startTime(),
                    req.durationMinutes(),
                    req.description()
            );
        } else {
            String cat = (category != null && !category.isBlank()) ? category : "Extra";
            Integer itemId = directorRepository.createPriceItem(
                    req.itemName(),
                    cat,
                    req.price(),
                    req.description()
            );
            return Map.of(
                    "item_id", itemId,
                    "message", "Послугу успішно створено"
            );
        }
    }

    private static class PeriodData {
        final String label;
        final LocalDate start;
        final LocalDate end;
        final List<RevenueReportItem> items = new ArrayList<>();

        PeriodData(String label, LocalDate start, LocalDate end) {
            this.label = label;
            this.start = start;
            this.end = end;
        }
    }
}
