package com.fitness.security;

import com.fitness.dto.auth.TokenRefreshResponse;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
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

    public Optional<TokenRefreshResponse> rotateTokens(String oldRefreshToken) {
        if (oldRefreshToken == null || oldRefreshToken.isBlank()) {
            return Optional.empty();
        }

        // Find active session by oldRefreshToken
        UserSession matchedSession = null;
        for (UserSession s : sessions.values()) {
            if (oldRefreshToken.equals(s.getRefreshToken())) {
                matchedSession = s;
                break;
            }
        }

        if (matchedSession == null) {
            return Optional.empty();
        }

        // Check TTL expiration
        if (Duration.between(matchedSession.getLastAccessedAt(), Instant.now()).compareTo(SESSION_TTL) > 0) {
            sessions.remove(matchedSession.getToken());
            return Optional.empty();
        }

        // Invalidate old session
        sessions.remove(matchedSession.getToken());

        // Generate new token pair
        String newAccessToken = UUID.randomUUID().toString();
        String newRefreshToken = UUID.randomUUID().toString();

        UserSession newSession = new UserSession(
                newAccessToken,
                newRefreshToken,
                matchedSession.getUsername(),
                matchedSession.getPassword(),
                matchedSession.getRole(),
                matchedSession.getFullName(),
                matchedSession.getEntityId()
        );
        register(newSession);

        return Optional.of(new TokenRefreshResponse(newAccessToken, newRefreshToken));
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
