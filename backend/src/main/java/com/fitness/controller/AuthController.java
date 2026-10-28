package com.fitness.controller;

import com.fitness.dto.auth.LoginRequest;
import com.fitness.dto.auth.LoginResponse;
import com.fitness.dto.auth.RefreshTokenRequest;
import com.fitness.dto.auth.SessionResponse;
import com.fitness.dto.auth.TokenRefreshResponse;
import com.fitness.dto.auth.UserProfileResponse;
import com.fitness.exception.AuthenticationRequiredException;
import com.fitness.repository.AuthRepository;
import com.fitness.security.SecurityContextHolder;
import com.fitness.security.SessionRegistry;
import com.fitness.security.UserSession;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthRepository authRepository;
    private final SessionRegistry sessionRegistry;

    public AuthController(AuthRepository authRepository, SessionRegistry sessionRegistry) {
        this.authRepository = authRepository;
        this.sessionRegistry = sessionRegistry;
    }

    /**
     * Authenticate via PostgreSQL credentials.
     * Returns session token and resolved user role.
     */
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request) {
        LoginResponse response = authRepository.authenticate(request.username(), request.password());

        // Register session in memory
        UserSession session = new UserSession(
                response.token(),
                response.refreshToken(),
                response.username(),
                request.password(),
                response.role(),
                response.fullName(),
                response.entityId()
        );
        sessionRegistry.register(session);

        return ResponseEntity.ok(response);
    }

    /**
     * Refresh session access token using a valid refresh token with token rotation.
     */
    @PostMapping("/refresh")
    public ResponseEntity<TokenRefreshResponse> refresh(@RequestBody RefreshTokenRequest request) {
        return sessionRegistry.rotateTokens(request.refreshToken())
                .map(ResponseEntity::ok)
                .orElseThrow(() -> new AuthenticationRequiredException("Недійсний або прострочений Refresh Token. Потрібна повторна авторизація."));
    }

    /**
     * Get information about current authenticated user session and permissions.
     */
    @GetMapping("/me")
    public ResponseEntity<SessionResponse> me() {
        return ResponseEntity.ok(authRepository.getSessionInfo());
    }

    /**
     * Get profile information for current authenticated user.
     */
    @GetMapping("/profile")
    public ResponseEntity<UserProfileResponse> profile() {
        return ResponseEntity.ok(authRepository.getUserProfile());
    }

    /**
     * Invalidate user session.
     */
    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(@RequestHeader(value = "X-Auth-Token", required = false) String token) {
        if (token != null) {
            sessionRegistry.invalidate(token);
        }
        SecurityContextHolder.clear();
        return ResponseEntity.ok(Map.of("message", "Сесію успішно завершено."));
    }
}
