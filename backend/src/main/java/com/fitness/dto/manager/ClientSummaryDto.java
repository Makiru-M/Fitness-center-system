package com.fitness.dto.manager;

import java.time.LocalDate;

public record ClientSummaryDto(
        Integer clientId,
        String fullName,
        LocalDate birthDate,
        String phone,
        String gender,
        String dbUser,
        String medicalNotes,
        String activeSubscriptionName,
        LocalDate activeSubscriptionEndDate,
        String activeSubscriptionStatus
) {}
