package com.fitness.dto.client;

public record UpdateClientProfileRequest(
        String fullName,
        String phone,
        String medicalNotes
) {}
