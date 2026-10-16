package com.fitness.model;

import java.time.LocalDate;

public class HrDto {

    public record HireCoachRequest(
            String fullName,
            LocalDate birthDate,
            String phone,
            Integer specId,
            String dbUser,
            String password,
            String biography
    ) {}

    public record UpdateCoachRequest(
            Integer coachId,
            String fullName,
            LocalDate birthDate,
            String phone,
            Integer specId,
            String biography
    ) {}

    public record HireManagerRequest(
            String fullName,
            LocalDate birthDate,
            String phone,
            String dbUser,
            String password,
            String positionName,
            LocalDate hireDate
    ) {}

    public record UpdateManagerRequest(
            Integer staffId,
            String fullName,
            LocalDate birthDate,
            String phone,
            Integer positionId
    ) {}

    public record FireEmployeeRequest(
            Integer staffId,
            LocalDate fireDate,
            String reason
    ) {}

    public record EmployeeDto(
            Integer staffId,
            Integer coachId,
            String fullName,
            LocalDate birthDate,
            String phone,
            String positionName,
            String dbUser,
            LocalDate hireDate,
            LocalDate fireDate,
            String specName,
            String biography,
            boolean isCoach,
            boolean isActive
    ) {}
}
