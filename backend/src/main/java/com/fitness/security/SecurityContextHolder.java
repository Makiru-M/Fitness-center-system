package com.fitness.security;

import java.util.Optional;

public final class SecurityContextHolder {

    private static final ThreadLocal<UserCredentials> CREDENTIALS_HOLDER = new ThreadLocal<>();
    private static final ThreadLocal<UserSession> SESSION_HOLDER = new ThreadLocal<>();

    private SecurityContextHolder() {
    }

    public static void setCredentials(UserCredentials credentials) {
        CREDENTIALS_HOLDER.set(credentials);
    }

    public static Optional<UserCredentials> getCredentials() {
        return Optional.ofNullable(CREDENTIALS_HOLDER.get());
    }

    public static void setSession(UserSession session) {
        SESSION_HOLDER.set(session);
    }

    public static Optional<UserSession> getSession() {
        return Optional.ofNullable(SESSION_HOLDER.get());
    }

    public static void clear() {
        CREDENTIALS_HOLDER.remove();
        SESSION_HOLDER.remove();
    }
}
