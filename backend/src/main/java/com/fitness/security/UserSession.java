package com.fitness.security;

import java.time.Instant;

public class UserSession {
    private final String token;
    private final String refreshToken;
    private final String username;
    private final String password;
    private final String role;
    private final String fullName;
    private final Integer entityId; // ID_Client or ID_Staff or ID_Coach
    private final Instant createdAt;
    private Instant lastAccessedAt;

    public UserSession(String token, String refreshToken, String username, String password, String role, String fullName, Integer entityId) {
        this.token = token;
        this.refreshToken = refreshToken;
        this.username = username;
        this.password = password;
        this.role = role;
        this.fullName = fullName;
        this.entityId = entityId;
        this.createdAt = Instant.now();
        this.lastAccessedAt = Instant.now();
    }

    public String getToken() {
        return token;
    }

    public String getRefreshToken() {
        return refreshToken;
    }

    public String getUsername() {
        return username;
    }

    public String getPassword() {
        return password;
    }

    public String getRole() {
        return role;
    }

    public String getFullName() {
        return fullName;
    }

    public Integer getEntityId() {
        return entityId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getLastAccessedAt() {
        return lastAccessedAt;
    }

    public void touch() {
        this.lastAccessedAt = Instant.now();
    }
}
