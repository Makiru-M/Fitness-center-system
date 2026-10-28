package com.fitness.dto.manager;

public record CheckInRequest(
        Integer clientId,
        String phone,
        Integer hallId
) {}
