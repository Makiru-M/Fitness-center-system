package com.fitness.dto.director;

import java.time.LocalDateTime;

public record PersonalTrainingAuditLogDto(
        LocalDateTime changeTimestamp,
        Integer personalId,
        Integer logId,
        String requestType,
        String changeInitiator,
        String reason,
        String newTime,
        String details,
        String finalResolution,
        Long changeSeqNum,
        LocalDateTime previousChangeTime
) {
    public PersonalTrainingAuditLogDto(LocalDateTime changeTimestamp, Integer personalId, String requestType, String changeInitiator, String reason, String newTime) {
        this(changeTimestamp, personalId, personalId, requestType, changeInitiator, reason, newTime, newTime, newTime, 1L, null);
    }

    public PersonalTrainingAuditLogDto(LocalDateTime changeTimestamp, Integer personalId, String requestType, String changeInitiator, String reason, String newTime, Long changeSeqNum, LocalDateTime previousChangeTime) {
        this(changeTimestamp, personalId, personalId, requestType, changeInitiator, reason, newTime, newTime, newTime, changeSeqNum, previousChangeTime);
    }
}
