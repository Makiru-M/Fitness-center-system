package com.fitness.security;

import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class SessionRegistry {

    private static final Duration SESSION_TTL = Duration.ofHours(4);
    private final Map<String, UserSession> sessions = new ConcurrentHashMap<>();

    public void register(UserSession session) {
        sessions.put(session.getToken(), session);
    }

    public Optional<UserSession> getSession(String token) {
        if (token == null || token.isBlank()) {
            return Optional.empty();
        }
        UserSession session = sessions.get(token);
        if (session == null) {
            return Optional.empty();
        }
        if (Duration.between(session.getLastAccessedAt(), Instant.now()).compareTo(SESSION_TTL) > 0) {
            sessions.remove(token);
            return Optional.empty();
        }
        session.touch();
        return Optional.of(session);
    }

    public void invalidate(String token) {
        if (token != null) {
            sessions.remove(token);
        }
    }

    public void invalidateUserSessions(String username) {
        if (username == null || username.isBlank()) return;
        sessions.entrySet().removeIf(entry -> username.equalsIgnoreCase(entry.getValue().getUsername()));
    }
}
