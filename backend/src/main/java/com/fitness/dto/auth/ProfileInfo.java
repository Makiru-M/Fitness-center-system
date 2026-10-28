package com.fitness.dto.auth;

import java.time.LocalDate;

public record ProfileInfo(
        Integer entityId,
        String fullName,
        String phone,
        LocalDate birthDate,
        String description
) {}
