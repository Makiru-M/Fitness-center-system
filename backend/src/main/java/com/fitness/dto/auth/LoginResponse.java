package com.fitness.dto.auth;

public record LoginResponse(
        String token,
        String username,
        String role,
        String fullName,
        Integer entityId,
        String positionOrType
) {}
