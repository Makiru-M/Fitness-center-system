package com.fitness.dto.client;

import java.time.LocalDate;

public record ClientProfileDto(
        Integer clientId,
        String fullName,
        LocalDate birthDate,
        String phone,
        String gender,
        String dbUser,
        String medicalNotes
) {}
