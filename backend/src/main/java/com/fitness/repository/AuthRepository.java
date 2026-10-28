package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.dto.auth.ProfileInfo;
import com.fitness.dto.auth.UserProfileResponse;
import com.fitness.exception.AuthenticationRequiredException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class AuthRepository {

    private static final Logger log = LoggerFactory.getLogger(AuthRepository.class);
    private final DynamicDataSourceService dataSourceService;

    public AuthRepository(DynamicDataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    /**
     * Test connection credentials against PostgreSQL.
     */
    public void testConnection(String username, String password) {
        dataSourceService.testConnection(username, password);
    }

    /**
     * Determine role for a user using their credentials.
     */
    public String determineRole(String username, String password) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplateForUser(username, password);
        return determineRole(jdbc, username);
    }

    /**
     * Determine role for the current authenticated context.
     */
    public String determineRole(String username) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        return determineRole(jdbc, username);
    }

    /**
     * Get current database session username (SESSION_USER).
     */
    public String getCurrentSessionUser() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        return jdbc.queryForObject("SELECT SESSION_USER", String.class);
    }

    /**
     * Resolve business profile details for a user using their credentials.
     */
    public ProfileInfo resolveProfile(String username, String password, String role) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplateForUser(username, password);
        return resolveProfile(jdbc, username, role);
    }

    /**
     * Resolve business profile details for current authenticated context.
     */
    public ProfileInfo resolveProfile(String username, String role) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        return resolveProfile(jdbc, username, role);
    }

    /**
     * Resolve business profile details for the authenticated user context.
     */
    public UserProfileResponse getUserProfile() {
        String username = getCurrentSessionUser();
        String role = determineRole(username);
        ProfileInfo profile = resolveProfile(username, role);
        return new UserProfileResponse(
                profile.entityId(),
                profile.fullName(),
                profile.phone(),
                profile.birthDate(),
                profile.description()
        );
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
                return fetchStaffProfile(jdbc, username);
            } else if ("coach_role".equals(role)) {
                return fetchCoachProfile(jdbc, username);
            } else if ("client_role".equals(role)) {
                return fetchClientProfile(jdbc, username);
            }
        } catch (Exception e) {
            log.warn("Could not resolve specific profile info for user [{}]: {}", username, e.getMessage());
        }

        return new ProfileInfo(null, username, null, null, role);
    }

    public ProfileInfo fetchStaffProfile(JdbcTemplate jdbc, String username) {
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
        return list.stream().findFirst().orElse(new ProfileInfo(null, username, null, null, "Співробітник"));
    }

    public ProfileInfo fetchCoachProfile(JdbcTemplate jdbc, String username) {
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
        return list.stream().findFirst().orElse(new ProfileInfo(null, username, null, null, "Тренер"));
    }

    public ProfileInfo fetchClientProfile(JdbcTemplate jdbc, String username) {
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
        return list.stream().findFirst().orElse(new ProfileInfo(null, username, null, null, "Клієнт клубу"));
    }
}
