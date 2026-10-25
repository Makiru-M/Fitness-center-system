package com.fitness.model;

import java.math.BigDecimal;
import java.time.LocalDate;

public class GuestDto {

    public record ClientRegistrationRequest(
            String fullName,
            LocalDate birthDate,
            String phone,
            String gender,
            String dbUser,
            String password,
            Integer itemId,
            String promoCode,
            String medicalNotes
    ) {}

    public record ClientRegistrationResponse(
            Integer clientId,
            String dbUsername,
            Integer saleId,
            Integer subscriptionId,
            BigDecimal finalPrice,
            LocalDate endDate
    ) {}

    public record CoachPublicDto(
            Integer coachId,
            String fullName,
            String specName,
            String biography,
            Integer groupClassesCount,
            Double avgGroupSize,
            Integer individualClientsCount
    ) {}

    public record PriceListItemDto(
            Integer itemId,
            String itemName,
            String category,
            BigDecimal price,
            Integer durationDays,
            Integer maxFreezingDays,
            String description,
            LocalDate priceStartDate,
            LocalDate priceEndDate,
            Boolean isActive
    ) {
        public PriceListItemDto(
                Integer itemId,
                String itemName,
                String category,
                BigDecimal price,
                Integer durationDays,
                Integer maxFreezingDays,
                String description
        ) {
            this(itemId, itemName, category, price, durationDays, maxFreezingDays, description, null, null, true);
        }
    }

    public record HallDto(
            Integer hallId,
            String hallName,
            Integer maxCapacity
    ) {}
    public record ClassTypePublicDto(
            Integer classTypeId,
            String typeName,
            Integer itemId,
            BigDecimal price
    ) {}
}
