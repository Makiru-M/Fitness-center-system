package com.fitness.controller;

import com.fitness.dto.guest.*;
import com.fitness.repository.GuestRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/guest")
public class GuestController {

    private final GuestRepository guestRepository;

    public GuestController(GuestRepository guestRepository) {
        this.guestRepository = guestRepository;
    }

    /**
     * G1: Register new client and buy first membership (uses stored function sp_register_client)
     */
    @PostMapping("/register")
    public ResponseEntity<ClientRegistrationResponse> registerClient(@RequestBody ClientRegistrationRequest req) {
        ClientRegistrationResponse response = guestRepository.registerClient(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * G2: View coaches with popularity and specializations
     */
    @GetMapping("/coaches")
    public ResponseEntity<List<CoachPublicDto>> getCoaches(@RequestParam(value = "specId", required = false) Integer specId) {
        List<CoachPublicDto> coaches = guestRepository.getCoaches(specId);
        return ResponseEntity.ok(coaches);
    }

    /**
     * G3: View Price List
     */
    @GetMapping("/price-list")
    public ResponseEntity<List<PriceListItemDto>> getPriceList() {
        List<PriceListItemDto> priceList = guestRepository.getPriceList();
        return ResponseEntity.ok(priceList);
    }

    /**
     * G4: View Halls
     */
    @GetMapping("/halls")
    public ResponseEntity<List<HallDto>> getHalls() {
        List<HallDto> halls = guestRepository.getHalls();
        return ResponseEntity.ok(halls);
    }
    /**
     * View Class Types with current prices
     */
    @GetMapping("/class-types")
    public ResponseEntity<List<ClassTypePublicDto>> getClassTypes() {
        List<ClassTypePublicDto> classTypes = guestRepository.getClassTypes();
        return ResponseEntity.ok(classTypes);
    }
}
