package com.fitness.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class ClientDto {

    public record ClientProfileDto(
            Integer clientId,
            String fullName,
            LocalDate birthDate,
            String phone,
            String gender,
            String dbUser,
            String medicalNotes
    ) {}

    public record UpdateClientProfileRequest(
            String fullName,
            String phone,
            String medicalNotes
    ) {}

    public record RenewSubscriptionRequest(
            Integer itemId,
            String promoCode
    ) {}

    public record FreezeSubscriptionRequest(
            Integer clientSubId,
            LocalDate startDate,
            LocalDate endDate,
            String reason
    ) {}

    public record GroupBookingRequest(
            Integer instanceId,
            Integer saleId
    ) {}

    public record PersonalBookingRequest(
            Integer coachId,
            Integer hallId,
            LocalDateTime trainingDateTime,
            Integer saleId
    ) {}

    public record CancelBookingRequest(
            String bookingType, // "Personal" or "Group"
            Integer bookingId,
            String reason
    ) {}

    public record ClientSubscriptionDto(
            Integer clientSubId,
            Integer saleId,
            String itemName,
            LocalDate startDate,
            LocalDate endDate,
            String currentStatus,
            Integer remainingFreezingDays,
            BigDecimal salePrice
    ) {}

    public record ClientBookingDto(
            Integer bookingId,
            String activityType, // "Personal" or "Group"
            String title,
            String coachName,
            String hallName,
            LocalDateTime trainingDateTime,
            String status
    ) {}

    public record VisitDto(
            Integer visitId,
            String hallName,
            LocalDateTime checkInTime,
            String itemName
    ) {}
}
