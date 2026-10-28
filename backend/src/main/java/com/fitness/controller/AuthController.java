package com.fitness.controller;

import com.fitness.dto.auth.CurrentUserResponse;
import com.fitness.dto.auth.LoginRequest;
import com.fitness.dto.auth.LoginResponse;
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
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest req) {
        LoginResponse response = authRepository.authenticate(req.username(), req.password());

        // Register session in memory
        UserSession session = new UserSession(
                response.token(),
                response.username(),
                req.password(),
                response.role(),
                response.fullName(),
                response.entityId()
        );
        sessionRegistry.register(session);

        return ResponseEntity.ok(response);
    }

    /**
     * Get information about current authenticated user and permissions.
     */
    @GetMapping("/me")
    public ResponseEntity<CurrentUserResponse> me() {
        CurrentUserResponse userInfo = authRepository.getCurrentUserInfo();
        return ResponseEntity.ok(userInfo);
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
