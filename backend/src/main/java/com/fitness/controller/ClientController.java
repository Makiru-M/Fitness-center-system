package com.fitness.controller;

import com.fitness.model.ClientDto.*;
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
     * Cl6: Cancel booking (personal or group)
     */
    @PostMapping("/bookings/cancel")
    public ResponseEntity<Map<String, String>> cancelBooking(@RequestBody CancelBookingRequest req) {
        clientRepository.cancelBooking(req);
        return ResponseEntity.ok(Map.of("message", "Бронювання успішно скасовано."));
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
}
