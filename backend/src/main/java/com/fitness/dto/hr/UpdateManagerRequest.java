package com.fitness.dto.hr;

import java.time.LocalDate;

public record UpdateManagerRequest(
        Integer staffId,
        String fullName,
        LocalDate birthDate,
        String phone,
        Integer positionId
) {}
