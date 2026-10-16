package com.fitness.model;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

public class CoachDto {

    public record CoachScheduleItem(
            Integer activityId,
            String activityType, // "Personal" or "Group"
            String title,
            String hallName,
            LocalDate scheduleDate,
            LocalTime startTime,
            LocalDateTime startDateTime,
            Integer durationMinutes,
            String status,
            Integer attendanceOrCapacity
    ) {}

    public record ClassParticipantDto(
            Integer clientId,
            String clientName,
            String phone,
            String bookingStatus,
            String medicalNotes
    ) {}

    public record UpdatePtStatusRequest(
            String status, // "Completed", "No-show", "Cancelled"
            String comment
    ) {}

    public record UpdateGroupAttendanceRequest(
            String status, // "Completed", "Cancelled"
            Integer actualAttendance
    ) {}

    public record CoachChangeRequest(
            Integer personalId,
            String requestType, // "Reschedule" or "Cancel"
            String reason,
            LocalDateTime newDateTime
    ) {}
}
