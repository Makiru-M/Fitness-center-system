package com.fitness.controller;

import com.fitness.dto.director.*;
import com.fitness.dto.guest.HallDto;
import com.fitness.dto.guest.PriceListItemDto;
import com.fitness.repository.DirectorRepository;
import com.fitness.repository.GuestRepository;
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
    private final GuestRepository guestRepository;

    public DirectorController(DirectorRepository directorRepository, GuestRepository guestRepository) {
        this.directorRepository = directorRepository;
        this.guestRepository = guestRepository;
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
     * D3: Coach popularity ranking
     */
    @GetMapping("/reports/coach-popularity")
    public ResponseEntity<List<CoachPerformanceDto>> getCoachPopularity() {
        return ResponseEntity.ok(directorRepository.getCoachPopularity());
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
    public ResponseEntity<List<PersonalTrainingAuditLogDto>> getAuditLog() {
        return ResponseEntity.ok(directorRepository.getAuditLog());
    }

    /**
     * D7: Create new subscription type
     */
    @PostMapping("/subscriptions")
    public ResponseEntity<Map<String, Object>> createSubscriptionType(@RequestBody CreateSubscriptionTypeRequest request) {
        Integer itemId = directorRepository.createSubscriptionType(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "itemId", itemId,
                "message", "Новий тип абонемента успішно додано до прайс-листа."
        ));
    }

    /**
     * D10: Create price list service (single/extra service)
     */
    @PostMapping("/services")
    public ResponseEntity<Map<String, Object>> createService(@RequestBody CreateServiceRequest request) {
        Integer itemId = directorRepository.createService(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "itemId", itemId,
                "message", "Послугу успішно додано до прайс-листа."
        ));
    }

    /**
     * D8: Commission hall into operation
     */
    @PostMapping("/halls")
    public ResponseEntity<Map<String, Object>> commissionHall(@RequestBody CommissionHallRequest request) {
        Integer hallId = directorRepository.commissionHall(request);
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
     * D8: Get archived halls
     */
    @GetMapping("/halls/archived")
    public ResponseEntity<List<HallDto>> getArchivedHalls() {
        return ResponseEntity.ok(directorRepository.getArchivedHalls());
    }

    /**
     * D8: Recommission hall into operation
     */
    @PutMapping("/halls/{hallId}/recommission")
    public ResponseEntity<Map<String, Object>> recommissionHall(@PathVariable Integer hallId) {
        directorRepository.recommissionHall(hallId);
        return ResponseEntity.ok(Map.of(
                "hallId", hallId,
                "message", "Зал успішно повернуто в експлуатацію."
        ));
    }

    /**
     * D9: Create promo code
     */
    @PostMapping("/promos")
    public ResponseEntity<Map<String, Object>> createPromoCode(@RequestBody CreatePromoCodeRequest request) {
        Integer promoId = directorRepository.createPromoCode(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "promoId", promoId,
                "message", "Промокод успішно створено та активовано."
        ));
    }

    /**
     * D11: Create group schedule template
     */
    @PostMapping("/schedule/templates")
    public ResponseEntity<Map<String, Object>> createScheduleTemplate(@RequestBody CreateScheduleTemplateRequest request) {
        Integer templateId = directorRepository.createScheduleTemplate(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "templateId", templateId,
                "message", "Шаблон щотижневого розкладу успішно створено."
        ));
    }

    /**
     * D10: Update price tariff (versioning)
     */
    @PutMapping("/prices/{id}")
    public ResponseEntity<Map<String, Object>> updatePriceTariff(
            @PathVariable("id") Integer itemId,
            @RequestBody UpdateTariffRequest request
    ) {
        Map<String, Object> result = directorRepository.updatePriceTariff(itemId, request.newPrice());
        return ResponseEntity.ok(Map.of(
                "message", "Тариф успішно оновлено зі збереженням історії версій.",
                "details", result
        ));
    }

    /**
     * D10: Create turnkey service
     */
    @PostMapping("/services/turnkey")
    public ResponseEntity<Map<String, Object>> createTurnkeyService(@RequestBody CreateTurnkeyServiceRequest request) {
        Map<String, Object> result = directorRepository.createTurnkeyService(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "message", "Послугу успішно налаштовано та введено в дію під ключ.",
                "details", result
        ));
    }

    /**
     * D10: Get price list with optional archived items
     */
    @GetMapping("/prices")
    public ResponseEntity<List<PriceListItemDto>> getPrices(
            @RequestParam(value = "includeArchived", defaultValue = "false") boolean includeArchived
    ) {
        return ResponseEntity.ok(guestRepository.getPriceList(includeArchived));
    }

    /**
     * D10: Deactivate / archive price item (Soft Delete)
     */
    @DeleteMapping("/prices/{itemId}")
    public ResponseEntity<Map<String, Object>> deactivatePriceItem(@PathVariable("itemId") Integer itemId) {
        Map<String, Object> result = directorRepository.deactivatePriceItem(itemId);
        return ResponseEntity.ok(Map.of(
                "itemId", itemId,
                "status", result.getOrDefault("status", "Archived"),
                "message", result.getOrDefault("message", "Послугу успішно вилучено з активного прайсу.")
        ));
    }
}
