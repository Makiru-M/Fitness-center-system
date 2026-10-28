package com.fitness.dto.hr;

import java.time.LocalDate;

public record FireEmployeeRequest(
        Integer staffId,
        LocalDate fireDate,
        String reason
) {}
