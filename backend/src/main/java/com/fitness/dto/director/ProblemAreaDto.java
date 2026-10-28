package com.fitness.dto.director;

public record ProblemAreaDto(
        String clientName,
        String clientOrStaffName,
        String phone,
        String problemType,
        String issueType,
        String issueCategory,
        String details,
        String recommendedAction,
        String severity
) {
    public ProblemAreaDto(String clientName, String phone, String problemType, String details, String recommendedAction) {
        this(clientName, clientName, phone, problemType, problemType, problemType, details, recommendedAction, "Medium");
    }
}
