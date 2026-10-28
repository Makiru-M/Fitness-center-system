package com.fitness.service;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.dto.auth.*;
import com.fitness.exception.AuthenticationRequiredException;
import com.fitness.repository.AuthRepository;
import com.fitness.security.Permission;
import com.fitness.security.SecurityContextHolder;
import com.fitness.security.SessionRegistry;
import com.fitness.security.UserSession;
import com.fitness.util.ValidationUtils;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class AuthService {

    private final AuthRepository authRepository;
    private final SessionRegistry sessionRegistry;
    private final DynamicDataSourceService dataSourceService;

    public AuthService(AuthRepository authRepository,
                       SessionRegistry sessionRegistry,
                       DynamicDataSourceService dataSourceService) {
        this.authRepository = authRepository;
        this.sessionRegistry = sessionRegistry;
        this.dataSourceService = dataSourceService;
    }

    /**
     * Authenticates user against PostgreSQL, determines role & profile, generates tokens and registers session.
     */
    public LoginResponse authenticate(LoginRequest request) {
        if (request == null) {
            throw new AuthenticationRequiredException("Необхідно передати дані для авторизації.");
        }

        String username = ValidationUtils.cleanToNull(request.username());
        String password = request.password();

        if (username == null || password == null || password.isBlank()) {
            throw new AuthenticationRequiredException("Логін та пароль є обов'язковими.");
        }

        try {
            authRepository.testConnection(username, password);
        } catch (AuthenticationRequiredException e) {
            throw e;
        } catch (Exception e) {
            throw new AuthenticationRequiredException("Невірний логін або пароль.");
        }

        String role = authRepository.determineRole(username, password);
        ProfileInfo profile = authRepository.resolveProfile(username, password, role);

        String accessToken = UUID.randomUUID().toString();
        String refreshToken = UUID.randomUUID().toString();

        UserSession session = new UserSession(
                accessToken,
                refreshToken,
                username,
                password,
                role,
                profile.fullName(),
                profile.entityId()
        );
        sessionRegistry.register(session);

        return new LoginResponse(
                accessToken,
                refreshToken,
                username,
                role,
                profile.fullName(),
                profile.entityId(),
                profile.description()
        );
    }

    /**
     * Rotates access and refresh tokens.
     */
    public TokenRefreshResponse refreshToken(RefreshTokenRequest request) {
        if (request == null || request.refreshToken() == null || request.refreshToken().isBlank()) {
            throw new AuthenticationRequiredException("Refresh Token є обов'язковим.");
        }

        return sessionRegistry.rotateTokens(request.refreshToken())
                .orElseThrow(() -> new AuthenticationRequiredException("Недійсний або прострочений Refresh Token. Потрібна повторна авторизація."));
    }

    /**
     * Returns session info and resolved permissions for the current authenticated user.
     */
    public SessionResponse getSessionInfo() {
        String username = authRepository.getCurrentSessionUser();
        String role = authRepository.determineRole(username);
        List<String> permissions = resolvePermissions(role);
        return new SessionResponse(username, role, permissions);
    }

    /**
     * Returns full user profile for the current user.
     */
    public UserProfileResponse getUserProfile() {
        return authRepository.getUserProfile();
    }

    /**
     * Invalidates the session and clears security context.
     */
    public void logout(String token) {
        if (token != null && !token.isBlank()) {
            sessionRegistry.invalidate(token);
        }
        SecurityContextHolder.clear();
    }

    /**
     * Maps user role to application permissions.
     */
    public List<String> resolvePermissions(String role) {
        List<Permission> list = switch (role) {
            case "director_role" -> List.of(
                    Permission.REPORTS_VIEW,
                    Permission.AUDIT_VIEW,
                    Permission.CATALOG_MANAGE,
                    Permission.SCHEDULE_MANAGE,
                    Permission.ALL_PRIVILEGES
            );
            case "manager_role" -> List.of(
                    Permission.CLIENTS_MANAGE,
                    Permission.SALES_MANAGE,
                    Permission.CHECKIN_MANAGE,
                    Permission.BOOKING_MANAGE
            );
            case "hr_role" -> List.of(
                    Permission.STAFF_HIRE,
                    Permission.STAFF_EDIT,
                    Permission.STAFF_FIRE
            );
            case "coach_role" -> List.of(
                    Permission.SCHEDULE_VIEW,
                    Permission.CLASS_MARK,
                    Permission.CHANGE_REQUEST
            );
            case "client_role" -> List.of(
                    Permission.PROFILE_EDIT,
                    Permission.BOOKING_CREATE,
                    Permission.SUBSCRIPTION_MANAGE
            );
            default -> List.of(Permission.GUEST_BROWSE);
        };
        return list.stream().map(Enum::name).toList();
    }
}
