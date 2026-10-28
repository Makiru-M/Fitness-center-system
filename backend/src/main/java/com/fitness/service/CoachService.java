package com.fitness.service;

import com.fitness.dto.coach.*;
import com.fitness.exception.BusinessLogicException;
import com.fitness.repository.CoachRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class CoachService {

    private final CoachRepository coachRepository;

    public CoachService(CoachRepository coachRepository) {
        this.coachRepository = coachRepository;
    }

    /**
     * C1: View own schedule (Group classes + Personal trainings)
     */
    public List<CoachScheduleItem> getMySchedule() {
        return coachRepository.getMySchedule();
    }

    /**
     * C2: Get participant clients for a group class
     */
    public List<ClassParticipantDto> getGroupClassParticipants(Integer instanceId) {
        return coachRepository.getGroupClassParticipants(instanceId);
    }

    /**
     * C2: Get client details for a personal training
     */
    public List<ClassParticipantDto> getPersonalTrainingClient(Integer personalId) {
        return coachRepository.getPersonalTrainingClient(personalId);
    }

    /**
     * C3: Mark personal training status (Completed, No-show, Cancelled, etc.)
     */
    @Transactional
    public void updatePersonalTrainingStatus(Integer personalId, UpdatePersonalTrainingStatusRequest request) {
        if (request == null || request.status() == null || request.status().isBlank()) {
            throw new IllegalArgumentException("Статус персонального тренування не може бути пустим.");
        }

        String status = request.status();
        boolean isCompletion = "Completed".equalsIgnoreCase(status) || "No-show".equalsIgnoreCase(status);

        int rows = coachRepository.updatePersonalTraining(personalId, status, isCompletion);
        if (rows == 0) {
            LocalDateTime endTime = coachRepository.findPersonalTrainingEndTime(personalId)
                    .orElseThrow(() -> new IllegalArgumentException("Персональне тренування з ID " + personalId + " не знайдено."));
            throw new IllegalArgumentException("Неможливо відмітити тренування як проведене: заняття ще не завершилося (час закінчення: " + endTime + ").");
        }
    }

    /**
     * C4: Mark group class status and actual attendance
     */
    @Transactional
    public void updateGroupAttendance(Integer instanceId, UpdateGroupAttendanceRequest request) {
        if (request == null || request.status() == null || request.status().isBlank()) {
            throw new IllegalArgumentException("Статус групового заняття не може бути пустим.");
        }

        String status = request.status();
        int attendance = (request.actualAttendance() != null && request.actualAttendance() >= 0) ? request.actualAttendance() : 0;
        boolean isCompletion = "Completed".equalsIgnoreCase(status) || "No-show".equalsIgnoreCase(status);

        int rows = coachRepository.updateGroupClass(instanceId, status, attendance, isCompletion);
        if (rows == 0) {
            LocalDateTime endTime = coachRepository.findGroupClassEndTime(instanceId)
                    .orElseThrow(() -> new IllegalArgumentException("Групове заняття з ID " + instanceId + " не знайдено."));
            throw new IllegalArgumentException("Неможливо відмітити групове заняття як проведене: воно ще не завершилося (час закінчення: " + endTime + ").");
        }
    }

    /**
     * C5: Submit request for reschedule or cancellation
     */
    @Transactional
    public void submitChangeRequest(CoachChangeRequest request) {
        if (request == null || request.personalId() == null) {
            throw new BusinessLogicException("Ідентифікатор тренування обов'язковий.");
        }

        if ("Reschedule".equalsIgnoreCase(request.requestType())) {
            if (request.newDateTime() == null || request.newDateTime().isBefore(LocalDateTime.now())) {
                throw new BusinessLogicException("Запропонований час перенесення не може бути в минулому.");
            }
        }

        Integer logId = coachRepository.insertChangeLog(request.personalId(), request.requestType(), request.reason());

        if ("Reschedule".equalsIgnoreCase(request.requestType()) && request.newDateTime() != null) {
            LocalDateTime oldTime = coachRepository.findPersonalTrainingStartTime(request.personalId())
                    .orElseThrow(() -> new BusinessLogicException("Персональне тренування з ID " + request.personalId() + " не знайдено."));

            coachRepository.insertTimeChangeDetails(logId, oldTime, request.newDateTime());
        }
    }
}
