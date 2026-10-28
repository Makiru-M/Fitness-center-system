package com.fitness.dto.manager;

import java.time.LocalDate;

public record CreateClientRequest(
        String fullName,
        LocalDate birthDate,
        String phone,
        String gender,
        String dbUser,
        String password,
        String medicalNotes
) {}
