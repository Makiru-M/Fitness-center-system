package com.fitness.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class ManagerDto {

    public record CreateClientRequest(
            String fullName,
            LocalDate birthDate,
            String phone,
            String gender,
            String dbUser,
            String password,
            String medicalNotes
    ) {}

    public record UpdateClientRequest(
            Integer clientId,
            String fullName,
            LocalDate birthDate,
            String phone,
            String gender,
            String medicalNotes
    ) {}

    public record SellSubscriptionRequest(
            Integer clientId,
            Integer itemId,
            LocalDate startDate,
            String promoCode,
            Integer managerId
    ) {}

    public record CheckInRequest(
            Integer clientId,
            String phone,
            Integer hallId
    ) {}

    public record CheckInResult(
            Integer visitId,
            Integer clientId,
            String clientName,
            String hallName,
            LocalDateTime checkInTime,
            String subscriptionStatus
    ) {}

    public record FreezeRequest(
            Integer clientSubId,
            LocalDate startDate,
            LocalDate endDate,
            String reason
    ) {}

    public record BookingChangeRequest(
            String bookingType, // "Personal" or "Group"
            Integer bookingId,
            String action, // "Cancel" or "Reschedule"
            LocalDateTime newDateTime,
            String reason,
            String initiator // "Client", "Coach", "Manager"
    ) {}

    public record ClientSummaryDto(
            Integer clientId,
            String fullName,
            LocalDate birthDate,
            String phone,
            String gender,
            String dbUser,
            String medicalNotes,
            String activeSubName,
            LocalDate activeSubEndDate,
            String activeSubStatus
    ) {}

    public record ScheduleChangeRequestDto(
        Integer logId,
        Integer personalId,
        String coachName,
        String clientName,
        String requestType,
        String reason,
        LocalDateTime requestTimestamp,
        LocalDateTime currentDateTime,
        LocalDateTime proposedDateTime,
        String status
    ) {}
}
