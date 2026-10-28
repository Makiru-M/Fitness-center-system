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
    public ResponseEntity<Map<String, String>> updateProfile(@RequestBody UpdateClientProfileRequest request) {
        clientRepository.updateProfile(request);
        return ResponseEntity.ok(Map.of("message", "Профіль успішно оновлено."));
    }

    /**
     * Cl2: Renew / purchase subscription
     */
    @PostMapping("/subscriptions/renew")
    public ResponseEntity<ClientSubscriptionDto> renewSubscription(@RequestBody RenewSubscriptionRequest request) {
        ClientSubscriptionDto sub = clientRepository.renewSubscription(request);
        return ResponseEntity.ok(sub);
    }

    /**
     * Cl3: Freeze active subscription
     */
    @PostMapping("/subscriptions/freeze")
    public ResponseEntity<Map<String, String>> freezeSubscription(@RequestBody FreezeSubscriptionRequest request) {
        clientRepository.freezeSubscription(request);
        return ResponseEntity.ok(Map.of("message", "Абонемент успішно заморожено."));
    }

    /**
     * Cl3: Unfreeze subscription
     */
    @PutMapping("/subscriptions/{clientSubscriptionId}/unfreeze")
    public ResponseEntity<Map<String, Object>> unfreezeSubscription(@PathVariable Integer clientSubscriptionId) {
        clientRepository.unfreezeSubscription(clientSubscriptionId);
        return ResponseEntity.ok(Map.of(
                "clientSubscriptionId", clientSubscriptionId,
                "message", "Заморозку успішно скасовано. Абонемент активовано."
        ));
    }

    /**
     * Cl4: Book a group class
     */
    @PostMapping("/bookings/group")
    public ResponseEntity<Map<String, String>> bookGroupClass(@RequestBody GroupBookingRequest request) {
        clientRepository.bookGroupClass(request);
        return ResponseEntity.ok(Map.of("message", "Успішно записано на групове заняття."));
    }

    /**
     * Cl5: Book a personal training
     */
    @PostMapping("/bookings/personal")
    public ResponseEntity<Map<String, String>> bookPersonalTraining(@RequestBody PersonalBookingRequest request) {
        clientRepository.bookPersonalTraining(request);
        return ResponseEntity.ok(Map.of("message", "Успішно записано на персональне тренування."));
    }

    /**
     * Cl6: Cancel personal booking
     */
    @PostMapping("/bookings/personal/cancel")
    public ResponseEntity<Map<String, String>> cancelPersonalBooking(@RequestBody CancelPersonalBookingRequest request) {
        clientRepository.cancelPersonalBooking(request);
        return ResponseEntity.ok(Map.of("message", "Персональне тренування успішно скасовано."));
    }

    /**
     * Cl6: Cancel group booking
     */
    @PostMapping("/bookings/group/cancel")
    public ResponseEntity<Map<String, String>> cancelGroupBooking(@RequestBody CancelGroupBookingRequest request) {
        clientRepository.cancelGroupBooking(request);
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
