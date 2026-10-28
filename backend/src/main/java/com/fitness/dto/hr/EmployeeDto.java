package com.fitness.dto.hr;

import java.time.LocalDate;

public record EmployeeDto(
        Integer staffId,
        Integer coachId,
        String fullName,
        LocalDate birthDate,
        String phone,
        String positionName,
        String dbUser,
        LocalDate hireDate,
        LocalDate fireDate,
        String specName,
        String biography,
        boolean isCoach,
        boolean isActive
) {}
