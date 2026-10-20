package com.fitness.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

public class ClientDto {

    public record AvailableGroupClassDto(
            Integer instanceId,
            Integer templateId,
            String title,
            String coachName,
            String hallName,
            LocalDate classDate,
            LocalTime startTime,
            Integer durationMinutes,
            String status,
            Integer actualAttendance,
            Integer maxCapacity,
            Integer availableSpots,
            Boolean isBookedByMe
    ) {}

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

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record GroupBookingRequest(
            Integer instanceId,
            String promoCode,
            Integer saleId
    ) {
        public GroupBookingRequest(Integer instanceId, String promoCode) {
            this(instanceId, promoCode, null);
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record PersonalBookingRequest(
            Integer coachId,
            Integer hallId,
            LocalDateTime trainingDateTime,
            String promoCode,
            Integer saleId
    ) {
        public PersonalBookingRequest(Integer coachId, Integer hallId, LocalDateTime trainingDateTime, String promoCode) {
            this(coachId, hallId, trainingDateTime, promoCode, null);
        }
    }

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
            Integer instanceId,
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
