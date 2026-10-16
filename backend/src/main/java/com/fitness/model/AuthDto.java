package com.fitness.model;

import java.time.LocalDate;
import java.util.List;

public class AuthDto {

    public record LoginRequest(String username, String password) {}

    public record LoginResponse(
            String token,
            String username,
            String role,
            String fullName,
            Integer entityId,
            String positionOrType
    ) {}

    public record CurrentUserResponse(
            String username,
            String role,
            String fullName,
            Integer entityId,
            String phone,
            LocalDate birthDate,
            List<String> permissions
    ) {}
}
