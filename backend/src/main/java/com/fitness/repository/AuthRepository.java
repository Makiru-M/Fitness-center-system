package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.exception.AuthenticationRequiredException;
import com.fitness.dto.auth.CurrentUserResponse;
import com.fitness.dto.auth.LoginResponse;
import com.fitness.dto.auth.ProfileInfo;
import com.fitness.dto.auth.SessionResponse;
import com.fitness.dto.auth.UserProfileResponse;
import com.fitness.security.Permission;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Repository
public class AuthRepository {

    private static final Logger log = LoggerFactory.getLogger(AuthRepository.class);
    private final DynamicDataSourceService dataSourceService;

    public AuthRepository(DynamicDataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    /**
     * Authenticates the user credentials against PostgreSQL, inspects the role, and resolves profile details.
     */
    public LoginResponse authenticate(String username, String password) {
        // 1. Verify credentials by attempting a connection
        dataSourceService.testConnection(username, password);

        // 2. Query system catalogs to determine user role and profile details
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplateForUser(username, password);

        String role = determineRole(jdbc, username);
        ProfileInfo profile = resolveProfile(jdbc, username, role);

        String token = UUID.randomUUID().toString();
        String refreshToken = UUID.randomUUID().toString();
        return new LoginResponse(
                token,
                refreshToken,
                username,
                role,
                profile.fullName(),
                profile.entityId(),
                profile.description()
        );
    }

    /**
     * Resolve session details (username, role, permissions) without querying business tables.
     */
    public SessionResponse getSessionInfo() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String username = jdbc.queryForObject("SELECT SESSION_USER", String.class);
        String role = determineRole(jdbc, username);
        List<String> permissions = resolvePermissions(role);
        return new SessionResponse(username, role, permissions);
    }

    /**
     * Resolve business profile details for the authenticated user.
     */
    public UserProfileResponse getUserProfile() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String username = jdbc.queryForObject("SELECT SESSION_USER", String.class);
        String role = determineRole(jdbc, username);
        ProfileInfo profile = resolveProfile(jdbc, username, role);
        return new UserProfileResponse(profile.entityId(), profile.fullName(), profile.phone(), profile.birthDate(), profile.description());
    }

    private String determineRole(JdbcTemplate jdbc, String username) {
        // Fallback: check if username matches guest
        if (username.equalsIgnoreCase("guest_user")) {
            return "guest";
        }

        // Check role membership via pg_has_role
        String sql = """
            SELECT r.rolname 
            FROM pg_roles r 
            WHERE pg_has_role(CURRENT_USER, r.rolname, 'member') 
              AND r.rolname IN ('director_role', 'hr_role', 'manager_role', 'coach_role', 'client_role', 'guest')
            LIMIT 1
            """;
        List<String> roles = jdbc.query(sql, (rs, rowNum) -> rs.getString("rolname"));
        return roles.stream()
                .findFirst()
                .orElseThrow(() -> new AuthenticationRequiredException("Роль користувача не визначена або відсутні необхідні привілеї в системі."));
    }

    private ProfileInfo resolveProfile(JdbcTemplate jdbc, String username, String role) {
        try {
            if ("director_role".equals(role) || "manager_role".equals(role) || "hr_role".equals(role)) {
                String sql = """
                    SELECT s.ID_Staff, s.FullName, s.Phone, s.BirthDate, p.PositionName
                    FROM Staff s
                    JOIN Positions p ON s.ID_Position = p.ID_Position
                    WHERE s.DB_User = ? AND s.FireDate IS NULL
                    """;
                List<ProfileInfo> list = jdbc.query(sql, (rs, rowNum) -> new ProfileInfo(
                        rs.getInt("ID_Staff"),
                        rs.getString("FullName"),
                        rs.getString("Phone"),
                        rs.getDate("BirthDate") != null ? rs.getDate("BirthDate").toLocalDate() : null,
                        rs.getString("PositionName")
                ), username);
                ProfileInfo info = list.stream().findFirst().orElse(null);
                if (info != null) return info;
            } else if ("coach_role".equals(role)) {
                String sql = """
                    SELECT c.ID_Coach, s.FullName, s.Phone, s.BirthDate, sp.SpecName
                    FROM Coaches c
                    JOIN Staff s ON c.ID_Staff = s.ID_Staff
                    LEFT JOIN Specializations sp ON c.ID_Spec = sp.ID_Spec
                    WHERE s.DB_User = ? AND s.FireDate IS NULL
                    """;
                List<ProfileInfo> list = jdbc.query(sql, (rs, rowNum) -> new ProfileInfo(
                        rs.getInt("ID_Coach"),
                        rs.getString("FullName"),
                        rs.getString("Phone"),
                        rs.getDate("BirthDate") != null ? rs.getDate("BirthDate").toLocalDate() : null,
                        "Тренер (" + rs.getString("SpecName") + ")"
                ), username);
                ProfileInfo info = list.stream().findFirst().orElse(null);
                if (info != null) return info;
            } else if ("client_role".equals(role)) {
                String sql = """
                    SELECT ID_Client, FullName, Phone, BirthDate
                    FROM Clients
                    WHERE DB_User = ?
                    """;
                List<ProfileInfo> list = jdbc.query(sql, (rs, rowNum) -> new ProfileInfo(
                        rs.getInt("ID_Client"),
                        rs.getString("FullName"),
                        rs.getString("Phone"),
                        rs.getDate("BirthDate") != null ? rs.getDate("BirthDate").toLocalDate() : null,
                        "Клієнт клубу"
                ), username);
                ProfileInfo info = list.stream().findFirst().orElse(null);
                if (info != null) return info;
            }
        } catch (Exception e) {
            log.warn("Could not resolve specific profile info for user [{}]: {}", username, e.getMessage());
        }

        return new ProfileInfo(null, username, null, null, role);
    }

    private List<String> resolvePermissions(String role) {
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
