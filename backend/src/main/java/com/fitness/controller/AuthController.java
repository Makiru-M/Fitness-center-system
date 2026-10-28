package com.fitness.controller;

import com.fitness.dto.auth.LoginRequest;
import com.fitness.dto.auth.LoginResponse;
import com.fitness.dto.auth.RefreshTokenRequest;
import com.fitness.dto.auth.SessionResponse;
import com.fitness.dto.auth.TokenRefreshResponse;
import com.fitness.dto.auth.UserProfileResponse;
import com.fitness.service.AuthService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /**
     * Authenticate via PostgreSQL credentials.
     * Returns session token, refresh token, role, and user profile summary.
     */
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request) {
        LoginResponse response = authService.authenticate(request);
        return ResponseEntity.ok(response);
    }

    /**
     * Refresh session access token using a valid refresh token with token rotation.
     */
    @PostMapping("/refresh")
    public ResponseEntity<TokenRefreshResponse> refresh(@RequestBody RefreshTokenRequest request) {
        TokenRefreshResponse response = authService.refreshToken(request);
        return ResponseEntity.ok(response);
    }

    /**
     * Get information about current authenticated user session and permissions.
     */
    @GetMapping("/me")
    public ResponseEntity<SessionResponse> me() {
        return ResponseEntity.ok(authService.getSessionInfo());
    }

    /**
     * Get profile information for current authenticated user.
     */
    @GetMapping("/profile")
    public ResponseEntity<UserProfileResponse> profile() {
        return ResponseEntity.ok(authService.getUserProfile());
    }

    /**
     * Invalidate user session and clear security context.
     */
    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(@RequestHeader(value = "X-Auth-Token", required = false) String token) {
        authService.logout(token);
        return ResponseEntity.ok(Map.of("message", "Сесію успішно завершено."));
    }
}
