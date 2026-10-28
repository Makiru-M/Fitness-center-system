package com.fitness.dto.coach;

public record UpdatePersonalTrainingStatusRequest(
        String status, // "Completed", "No-show", "Cancelled"
        String comment
) {}
