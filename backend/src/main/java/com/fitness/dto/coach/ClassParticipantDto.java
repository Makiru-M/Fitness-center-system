package com.fitness.dto.coach;

public record ClassParticipantDto(
        Integer clientId,
        String clientName,
        String phone,
        String bookingStatus,
        String medicalNotes
) {}
