package com.fitness.dto.coach;

import java.time.LocalDateTime;

public record CoachChangeRequest(
        Integer personalId,
        String requestType, // "Reschedule" or "Cancel"
        String reason,
        LocalDateTime newDateTime
) {}
