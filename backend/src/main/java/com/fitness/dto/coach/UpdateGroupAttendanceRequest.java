package com.fitness.dto.coach;

public record UpdateGroupAttendanceRequest(
        String status, // "Completed", "Cancelled"
        Integer actualAttendance
) {}
