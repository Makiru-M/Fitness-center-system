package com.fitness.dto.client;

public record CancelBookingRequest(
        String bookingType, // "Personal" or "Group"
        Integer bookingId,
        String reason
) {}
