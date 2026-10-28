package com.fitness.dto.auth;

import java.time.LocalDate;

public record UserProfileResponse(
        Integer entityId,
        String fullName,
        String phone,
        LocalDate birthDate,
        String description
) {}
