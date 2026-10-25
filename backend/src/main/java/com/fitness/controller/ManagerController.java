package com.fitness.controller;

import com.fitness.model.ClientDto.AvailableGroupClassDto;
import com.fitness.model.ManagerDto.*;
import com.fitness.repository.ClientRepository;
import com.fitness.repository.ManagerRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/manager")
public class ManagerController {

    private final ManagerRepository managerRepository;
    private final ClientRepository clientRepository;

    public ManagerController(ManagerRepository managerRepository, ClientRepository clientRepository) {
        this.managerRepository = managerRepository;
        this.clientRepository = clientRepository;
    }

    /**
     * M1: Register client as a new club member
     */
    @PostMapping("/clients")
    public ResponseEntity<Map<String, Object>> createClient(@RequestBody CreateClientRequest req) {
        Integer clientId = managerRepository.createClient(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "clientId", clientId,
                "message", "Клієнта успішно зареєстровано."
        ));
    }

    /**
     * M2: Edit client details
     */
    @PutMapping("/clients")
    public ResponseEntity<Map<String, String>> updateClient(@RequestBody UpdateClientRequest req) {
        managerRepository.updateClient(req);
        return ResponseEntity.ok(Map.of("message", "Дані клієнта успішно оновлено."));
    }

    /**
     * Search / list clients
     */
    @GetMapping("/clients")
    public ResponseEntity<List<ClientSummaryDto>> getClients(@RequestParam(value = "search", required = false) String search) {
        List<ClientSummaryDto> clients = managerRepository.searchClients(search);
        return ResponseEntity.ok(clients);
    }

    /**
     * M3: Sell or extend subscription
     */
    @PostMapping("/sales/subscription")
    public ResponseEntity<Map<String, Object>> sellSubscription(@RequestBody SellSubscriptionRequest req) {
        Integer saleId = managerRepository.sellSubscription(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "saleId", saleId,
                "message", "Абонемент успішно оформлено та активовано."
        ));
    }

    /**
     * M4: Check-in client visit
     */
    @PostMapping("/visits/check-in")
    public ResponseEntity<CheckInResult> checkIn(@RequestBody CheckInRequest req) {
        CheckInResult result = managerRepository.checkInVisit(req);
        return ResponseEntity.ok(result);
    }

    /**
     * M5: Book client into group class
     */
    @PostMapping("/bookings/group")
    public ResponseEntity<Map<String, String>> bookGroupClass(
            @RequestParam("clientId") Integer clientId,
            @RequestParam("instanceId") Integer instanceId,
            @RequestParam(value = "promoCode", required = false) String promoCode
    ) {
        managerRepository.bookGroupClass(clientId, instanceId, promoCode);
        return ResponseEntity.ok(Map.of("message", "Клієнта успішно записано на групове заняття."));
    }

    /**
     * M6: Book client into personal training
     */
    @PostMapping("/bookings/personal")
    public ResponseEntity<Map<String, Object>> bookPersonalTraining(
            @RequestParam("clientId") Integer clientId,
            @RequestParam("coachId") Integer coachId,
            @RequestParam("hallId") Integer hallId,
            @RequestParam("dateTime") LocalDateTime dateTime,
            @RequestParam(value = "promoCode", required = false) String promoCode
    ) {
        Integer ptId = managerRepository.bookPersonalTraining(clientId, coachId, hallId, dateTime, promoCode);
        return ResponseEntity.ok(Map.of(
                "personalId", ptId,
                "message", "Персональне тренування успішно призначено."
        ));
    }

    /**
     * M7: Freeze subscription
     */
    @PostMapping("/subscriptions/freeze")
    public ResponseEntity<Map<String, String>> freezeSubscription(@RequestBody FreezeRequest req) {
        managerRepository.freezeSubscription(req);
        return ResponseEntity.ok(Map.of("message", "Абонемент успішно заморожено."));
    }

    /**
     * M8: Cancel or reschedule booking
     */
    @PostMapping("/bookings/change")
    public ResponseEntity<Map<String, String>> changeBooking(@RequestBody BookingChangeRequest req) {
        managerRepository.changeBooking(req);
        return ResponseEntity.ok(Map.of("message", "Статус бронювання успішно змінено."));
    }

    /**
     * M9: Schedule a group class instance
     */
    @PostMapping("/schedule/group-class")
    public ResponseEntity<Map<String, Object>> scheduleGroupClass(
            @RequestParam("templateId") Integer templateId,
            @RequestParam("classDate") java.time.LocalDate classDate,
            @RequestParam(value = "startTime", required = false) java.time.LocalTime startTime
    ) {
        Integer instanceId = managerRepository.createGroupClassInstance(templateId, classDate, startTime);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "instanceId", instanceId,
                "message", "Групове заняття успішно додано до розкладу."
        ));
    }

    /**
     * M8: Get schedule change requests from coaches
     */
    @GetMapping("/schedule-requests")
    public ResponseEntity<List<ScheduleChangeRequestDto>> getScheduleRequests() {
        return ResponseEntity.ok(managerRepository.getScheduleRequests());
    }

    /**
     * M8: Approve a coach's schedule change request
     */
    @PostMapping("/schedule-requests/{logId}/approve")
    public ResponseEntity<Map<String, String>> approveScheduleRequest(@PathVariable("logId") Integer logId) {
        managerRepository.approveScheduleRequest(logId);
        return ResponseEntity.ok(Map.of("message", "Запит успішно схвалено та зміни застосовано до розкладу."));
    }

    /**
     * Cl4 / M5: View available group classes scheduled for current and future dates
     */
    @GetMapping("/group-classes/available")
    public ResponseEntity<List<AvailableGroupClassDto>> getAvailableGroupClasses() {
        return ResponseEntity.ok(clientRepository.getAvailableGroupClasses());
    }

    /**
     * M8: Reject a coach's schedule change request
     */
    @PostMapping("/schedule-requests/{logId}/reject")
    public ResponseEntity<Map<String, String>> rejectScheduleRequest(@PathVariable("logId") Integer logId) {
        managerRepository.rejectScheduleRequest(logId);
        return ResponseEntity.ok(Map.of("message", "Запит успішно відхилено."));
    }
}
