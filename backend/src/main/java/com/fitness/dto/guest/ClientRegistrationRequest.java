package com.fitness.dto.guest;

import java.time.LocalDate;

public record ClientRegistrationRequest(
        String fullName,
        LocalDate birthDate,
        String phone,
        String gender,
        String dbUser,
        String password,
        Integer itemId,
        String promoCode,
        String medicalNotes
) {}
