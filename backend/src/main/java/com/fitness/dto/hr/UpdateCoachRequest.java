package com.fitness.dto.hr;

import java.time.LocalDate;

public record UpdateCoachRequest(
        Integer coachId,
        String fullName,
        LocalDate birthDate,
        String phone,
        Integer specId,
        String biography
) {}
