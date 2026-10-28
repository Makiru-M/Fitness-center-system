package com.fitness.dto.auth;

import java.util.List;

public record SessionResponse(
        String username,
        String role,
        List<String> permissions
) {}
