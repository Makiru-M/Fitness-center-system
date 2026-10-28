package com.fitness.dto.hr;

import java.time.LocalDate;

public record HireCoachRequest(
        String fullName,
        LocalDate birthDate,
        String phone,
        Integer specId,
        String dbUser,
        String password,
        String biography
) {}
