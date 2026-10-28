package com.fitness.controller;

import com.fitness.dto.coach.*;
import com.fitness.repository.CoachRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/coach")
public class CoachController {

    private final CoachRepository coachRepository;

    public CoachController(CoachRepository coachRepository) {
        this.coachRepository = coachRepository;
    }

    /**
     * C1: View own schedule (both personal trainings and group classes)
     */
    @GetMapping("/schedule")
    public ResponseEntity<List<CoachScheduleItem>> getMySchedule() {
        return ResponseEntity.ok(coachRepository.getMySchedule());
    }

    /**
     * C2: View clients enrolled in a group class instance
     */
    @GetMapping("/classes/{instanceId}/participants")
    public ResponseEntity<List<ClassParticipantDto>> getGroupClassParticipants(@PathVariable("instanceId") Integer instanceId) {
        return ResponseEntity.ok(coachRepository.getGroupClassParticipants(instanceId));
    }

    /**
     * C2: View client details for a personal training
     */
    @GetMapping("/personal/{personalId}/client")
    public ResponseEntity<List<ClassParticipantDto>> getPersonalTrainingClient(@PathVariable("personalId") Integer personalId) {
        return ResponseEntity.ok(coachRepository.getPersonalTrainingClient(personalId));
    }

    /**
     * C3: Mark personal training status (Completed, No-show)
     */
    @PostMapping("/personal/{personalId}/status")
    public ResponseEntity<Map<String, String>> updatePersonalTrainingStatus(
            @PathVariable("personalId") Integer personalId,
            @RequestBody UpdatePersonalTrainingStatusRequest request
    ) {
        coachRepository.updatePersonalTrainingStatus(personalId, request);
        return ResponseEntity.ok(Map.of("message", "Статус персонального тренування оновлено."));
    }

    /**
     * C4: Mark group class status and actual attendance
     */
    @PostMapping("/group/{instanceId}/attendance")
    public ResponseEntity<Map<String, String>> updateGroupAttendance(
            @PathVariable("instanceId") Integer instanceId,
            @RequestBody UpdateGroupAttendanceRequest request
    ) {
        coachRepository.updateGroupAttendance(instanceId, request);
        return ResponseEntity.ok(Map.of("message", "Відвідуваність групового заняття збережено."));
    }

    /**
     * C5: Submit request for reschedule or cancellation
     */
    @PostMapping("/requests/reschedule")
    public ResponseEntity<Map<String, String>> submitChangeRequest(@RequestBody CoachChangeRequest request) {
        coachRepository.submitChangeRequest(request);
        return ResponseEntity.ok(Map.of("message", "Запит на зміну тренування успішно надіслано менеджеру."));
    }
}
