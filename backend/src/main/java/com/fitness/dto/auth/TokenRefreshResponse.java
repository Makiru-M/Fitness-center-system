package com.fitness.dto.auth;

public record TokenRefreshResponse(String accessToken, String refreshToken) {}
