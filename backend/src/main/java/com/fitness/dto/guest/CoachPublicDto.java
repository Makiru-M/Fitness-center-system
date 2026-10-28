package com.fitness.dto.guest;

public record CoachPublicDto(
        Integer coachId,
        String fullName,
        String specName,
        String biography,
        Integer groupClassesCount,
        Double avgGroupSize,
        Integer individualClientsCount
) {}
