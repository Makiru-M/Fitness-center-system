package com.fitness.dto.hr;

import java.time.LocalDate;

public record HireManagerRequest(
        String fullName,
        LocalDate birthDate,
        String phone,
        String dbUser,
        String password,
        String positionName,
        LocalDate hireDate
) {}
