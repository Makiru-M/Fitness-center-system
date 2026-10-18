package com.fitness.controller;

import com.fitness.model.DirectorDto.*;
import com.fitness.repository.DirectorRepository;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/director")
public class DirectorController {

    private final DirectorRepository directorRepository;

    public DirectorController(DirectorRepository directorRepository) {
        this.directorRepository = directorRepository;
    }

    /**
     * D1: Revenue report
     */
    @GetMapping("/reports/revenue")
    public ResponseEntity<List<RevenueReportItem>> getRevenueReport(
            @RequestParam(value = "fromDate", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fromDate,
            @RequestParam(value = "toDate", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate toDate
    ) {
        return ResponseEntity.ok(directorRepository.getRevenueReport(fromDate, toDate));
    }

    /**
     * D2: Attendance report
     */
    @GetMapping("/reports/attendance")
    public ResponseEntity<List<AttendanceReportItem>> getAttendanceReport() {
        return ResponseEntity.ok(directorRepository.getAttendanceReport());
    }

    /**
     * D3: Coach popularity ranking (from Lab_4.sql)
     */
    @GetMapping("/reports/coach-popularity")
    public ResponseEntity<List<CoachPerformanceDto>> getCoachPopularity() {
        return ResponseEntity.ok(directorRepository.getCoachPopularity());
    }

    /**
     * D4: Hall occupancy report
     */
    @GetMapping("/reports/hall-occupancy")
    public ResponseEntity<List<HallOccupancyDto>> getHallOccupancy() {
        return ResponseEntity.ok(directorRepository.getHallsOccupancy());
    }

    /**
     * D5: Analysis of problematic areas (expired subscriptions, high no-shows)
     */
    @GetMapping("/reports/issues")
    public ResponseEntity<List<ProblemAreaDto>> getIssuesReport() {
        return ResponseEntity.ok(directorRepository.getIssuesAnalysis());
    }

    /**
     * D6: Audit log of changes (PT_Changelog)
     */
    @GetMapping("/reports/audit-log")
    public ResponseEntity<List<PtAuditLogDto>> getAuditLog() {
        return ResponseEntity.ok(directorRepository.getAuditLog());
    }

    /**
     * D7: Create new subscription type
     */
    @PostMapping("/subscriptions")
    public ResponseEntity<Map<String, Object>> createSubscriptionType(@RequestBody CreateSubscriptionTypeRequest req) {
        Integer itemId = directorRepository.createSubscriptionType(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "itemId", itemId,
                "message", "Новий тип абонемента успішно додано до прайс-листа."
        ));
    }

    /**
     * D10: Create price list service (single/extra service)
     */
    @PostMapping("/services")
    public ResponseEntity<Map<String, Object>> createService(@RequestBody CreateServiceRequest req) {
        Integer itemId = directorRepository.createService(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "itemId", itemId,
                "message", "Послугу успішно додано до прайс-листа."
        ));
    }

    /**
     * D8: Commission hall into operation
     */
    @PostMapping("/halls")
    public ResponseEntity<Map<String, Object>> commissionHall(@RequestBody CommissionHallRequest req) {
        Integer hallId = directorRepository.commissionHall(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "hallId", hallId,
                "message", "Спортивний зал успішно введено в експлуатацію."
        ));
    }

    /**
     * D8: Decommission hall from operation (archive)
     */
    @DeleteMapping("/halls/{hallId}")
    public ResponseEntity<Map<String, Object>> decommissionHall(@PathVariable Integer hallId) {
        directorRepository.decommissionHall(hallId);
        return ResponseEntity.ok(Map.of(
                "hallId", hallId,
                "message", "Зал успішно виведено з експлуатації та переведено в архів."
        ));
    }

    /**
     * D9: Create promo code
     */
    @PostMapping("/promos")
    public ResponseEntity<Map<String, Object>> createPromoCode(@RequestBody CreatePromoCodeRequest req) {
        Integer promoId = directorRepository.createPromoCode(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "promoId", promoId,
                "message", "Промокод успішно створено та активовано."
        ));
    }

    /**
     * D11: Create group schedule template
     */
    @PostMapping("/schedule/templates")
    public ResponseEntity<Map<String, Object>> createScheduleTemplate(@RequestBody CreateScheduleTemplateRequest req) {
        Integer templateId = directorRepository.createScheduleTemplate(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "templateId", templateId,
                "message", "Шаблон щотижневого розкладу успішно створено."
        ));
    }

    /**
     * Lab_4 View: Share of group class clients taking individual trainings
     */
    @GetMapping("/views/group-individual-share")
    public ResponseEntity<List<GroupIndividualShareItem>> getGroupIndividualShareView() {
        return ResponseEntity.ok(directorRepository.getGroupIndividualShareView());
    }
}
