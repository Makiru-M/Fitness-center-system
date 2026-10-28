package com.fitness.controller;

import com.fitness.dto.client.*;
import com.fitness.repository.ClientRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/client")
public class ClientController {

    private final ClientRepository clientRepository;

    public ClientController(ClientRepository clientRepository) {
        this.clientRepository = clientRepository;
    }

    /**
     * View client own profile and medical restrictions
     */
    @GetMapping("/profile")
    public ResponseEntity<ClientProfileDto> getProfile() {
        return ResponseEntity.ok(clientRepository.getProfile());
    }

    /**
     * Cl1: Edit own profile (FullName, Phone, Medical notes)
     */
    @PutMapping("/profile")
    public ResponseEntity<Map<String, String>> updateProfile(@RequestBody UpdateClientProfileRequest req) {
        clientRepository.updateProfile(req);
        return ResponseEntity.ok(Map.of("message", "Профіль успішно оновлено."));
    }

    /**
     * Cl2: Renew / purchase subscription
     */
    @PostMapping("/subscriptions/renew")
    public ResponseEntity<ClientSubscriptionDto> renewSubscription(@RequestBody RenewSubscriptionRequest req) {
        ClientSubscriptionDto sub = clientRepository.renewSubscription(req);
        return ResponseEntity.ok(sub);
    }

    /**
     * Cl3: Freeze active subscription
     */
    @PostMapping("/subscriptions/freeze")
    public ResponseEntity<Map<String, String>> freezeSubscription(@RequestBody FreezeSubscriptionRequest req) {
        clientRepository.freezeSubscription(req);
        return ResponseEntity.ok(Map.of("message", "Абонемент успішно заморожено."));
    }

    /**
     * Cl3: Unfreeze subscription
     */
    @PutMapping("/subscriptions/{clientSubId}/unfreeze")
    public ResponseEntity<Map<String, Object>> unfreezeSubscription(@PathVariable Integer clientSubId) {
        clientRepository.unfreezeSubscription(clientSubId);
        return ResponseEntity.ok(Map.of(
                "clientSubId", clientSubId,
                "message", "Заморозку успішно скасовано. Абонемент активовано."
        ));
    }

    /**
     * Cl4: Book a group class
     */
    @PostMapping("/bookings/group")
    public ResponseEntity<Map<String, String>> bookGroupClass(@RequestBody GroupBookingRequest req) {
        clientRepository.bookGroupClass(req);
        return ResponseEntity.ok(Map.of("message", "Успішно записано на групове заняття."));
    }

    /**
     * Cl5: Book a personal training
     */
    @PostMapping("/bookings/personal")
    public ResponseEntity<Map<String, String>> bookPersonalTraining(@RequestBody PersonalBookingRequest req) {
        clientRepository.bookPersonalTraining(req);
        return ResponseEntity.ok(Map.of("message", "Успішно записано на персональне тренування."));
    }

    /**
     * Cl6: Cancel personal booking
     */
    @PostMapping("/bookings/personal/cancel")
    public ResponseEntity<Map<String, String>> cancelPersonalBooking(@RequestBody CancelPersonalBookingRequest req) {
        clientRepository.cancelPersonalBooking(req);
        return ResponseEntity.ok(Map.of("message", "Персональне тренування успішно скасовано."));
    }

    /**
     * Cl6: Cancel group booking
     */
    @PostMapping("/bookings/group/cancel")
    public ResponseEntity<Map<String, String>> cancelGroupBooking(@RequestBody CancelGroupBookingRequest req) {
        clientRepository.cancelGroupBooking(req);
        return ResponseEntity.ok(Map.of("message", "Групове бронювання успішно скасовано."));
    }

    /**
     * View own subscriptions
     */
    @GetMapping("/subscriptions")
    public ResponseEntity<List<ClientSubscriptionDto>> getMySubscriptions() {
        return ResponseEntity.ok(clientRepository.getMySubscriptions());
    }

    /**
     * View own bookings
     */
    @GetMapping("/bookings")
    public ResponseEntity<List<ClientBookingDto>> getMyBookings() {
        return ResponseEntity.ok(clientRepository.getMyBookings());
    }

    /**
     * View own visit history
     */
    @GetMapping("/visits")
    public ResponseEntity<List<VisitDto>> getMyVisits() {
        return ResponseEntity.ok(clientRepository.getMyVisits());
    }

    /**
     * Cl4: View available group classes scheduled for current and future dates
     */
    @GetMapping("/group-classes/available")
    public ResponseEntity<List<AvailableGroupClassDto>> getAvailableGroupClasses() {
        return ResponseEntity.ok(clientRepository.getAvailableGroupClasses());
    }
}
