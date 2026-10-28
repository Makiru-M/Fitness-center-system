package com.fitness.dto.guest;

public record CoachPublicDto(
        Integer coachId,
        String fullName,
        String specializationName,
        String biography,
        Integer groupClassesCount,
        Double avgGroupSize,
        Integer individualClientsCount
) {}
