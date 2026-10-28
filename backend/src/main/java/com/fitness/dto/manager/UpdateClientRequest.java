package com.fitness.dto.manager;

import java.time.LocalDate;

public record UpdateClientRequest(
        Integer clientId,
        String fullName,
        LocalDate birthDate,
        String phone,
        String gender,
        String medicalNotes
) {}
