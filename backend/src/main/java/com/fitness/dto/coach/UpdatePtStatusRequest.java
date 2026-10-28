package com.fitness.dto.coach;

public record UpdatePtStatusRequest(
        String status, // "Completed", "No-show", "Cancelled"
        String comment
) {}
