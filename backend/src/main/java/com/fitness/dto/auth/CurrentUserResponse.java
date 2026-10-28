package com.fitness.dto.auth;

import java.time.LocalDate;
import java.util.List;

public record CurrentUserResponse(
        String username,
        String role,
        String fullName,
        Integer entityId,
        String phone,
        LocalDate birthDate,
        List<String> permissions
) {}
