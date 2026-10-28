package com.fitness.dto.manager;

import java.time.LocalDateTime;

public record BookingChangeRequest(
        String bookingType, // "Personal" or "Group"
        Integer bookingId,
        String action, // "Cancel" or "Reschedule"
        LocalDateTime newDateTime,
        String reason,
        String initiator // "Client", "Coach", "Manager"
) {}
