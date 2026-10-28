package com.fitness.dto.client;

public record CancelPersonalBookingRequest(
        Integer bookingId,
        String reason
) {}
