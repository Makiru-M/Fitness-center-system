package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.exception.AuthenticationRequiredException;
import com.fitness.model.AuthDto.CurrentUserResponse;
import com.fitness.model.AuthDto.LoginResponse;
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
        // 0. Check if employee is fired before attempting connection
        try {
            JdbcTemplate adminJdbc = dataSourceService.getAdminJdbcTemplate();
            List<LocalDate> fireDates = adminJdbc.query(
                "SELECT FireDate FROM Staff WHERE DB_User = ?",
                (rs, rowNum) -> rs.getDate("FireDate") != null ? rs.getDate("FireDate").toLocalDate() : null,
                username
            );
            if (!fireDates.isEmpty() && fireDates.get(0) != null) {
                throw new AuthenticationRequiredException("Обліковий запис співробітника деактивовано (звільнено). Доступ заблоковано.");
            }
        } catch (AuthenticationRequiredException are) {
            throw are;
        } catch (Exception ignored) {
            // Fallback if adminJdbc fails
        }

        // 1. Verify credentials by attempting a connection
        dataSourceService.testConnection(username, password);

        // 2. Query system catalogs to determine user role and profile details
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplateForUser(username, password);

        List<LocalDate> fireDates = jdbc.query(
            "SELECT FireDate FROM Staff WHERE DB_User = ?",
            (rs, rowNum) -> rs.getDate("FireDate") != null ? rs.getDate("FireDate").toLocalDate() : null,
            username
        );
        if (!fireDates.isEmpty() && fireDates.get(0) != null) {
            throw new AuthenticationRequiredException("Обліковий запис співробітника деактивовано (звільнено). Доступ заблоковано.");
        }

        String role = determineRole(jdbc, username);
        ProfileInfo profile = resolveProfile(jdbc, username, role);

        String token = UUID.randomUUID().toString();
        return new LoginResponse(
                token,
                username,
                role,
                profile.fullName,
                profile.entityId,
                profile.description
        );
    }

    /**
     * Resolve current user details from existing connection.
     */
    public CurrentUserResponse getCurrentUserInfo() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String username = jdbc.queryForObject("SELECT SESSION_USER", String.class);
        String role = determineRole(jdbc, username);
        ProfileInfo profile = resolveProfile(jdbc, username, role);

        List<String> permissions = resolvePermissions(role);

        return new CurrentUserResponse(
                username,
                role,
                profile.fullName,
                profile.entityId,
                profile.phone,
                profile.birthDate,
                permissions
        );
    }

    private String determineRole(JdbcTemplate jdbc, String username) {
        // Check role membership via pg_has_role
        String sql = """
            SELECT r.rolname 
            FROM pg_roles r 
            WHERE pg_has_role(CURRENT_USER, r.rolname, 'member') 
              AND r.rolname IN ('director_role', 'hr_role', 'manager_role', 'coach_role', 'client_role', 'guest')
            ORDER BY 
              CASE r.rolname 
                WHEN 'director_role' THEN 1
                WHEN 'hr_role' THEN 2
                WHEN 'manager_role' THEN 3
                WHEN 'coach_role' THEN 4
                WHEN 'client_role' THEN 5
                ELSE 6
              END
            LIMIT 1
            """;
        List<String> roles = jdbc.query(sql, (rs, rowNum) -> rs.getString("rolname"));
        if (!roles.isEmpty()) {
            return roles.get(0);
        }

        // Fallback: check if username matches guest
        if (username.equalsIgnoreCase("guest_user")) {
            return "guest";
        }

        return "client_role";
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
                if (!list.isEmpty()) return list.get(0);
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
                if (!list.isEmpty()) return list.get(0);
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
                if (!list.isEmpty()) return list.get(0);
            }
        } catch (Exception e) {
            log.warn("Could not resolve specific profile info for user [{}]: {}", username, e.getMessage());
        }

        return new ProfileInfo(null, username, null, null, role);
    }

    private List<String> resolvePermissions(String role) {
        List<String> list = new ArrayList<>();
        switch (role) {
            case "director_role" -> {
                list.add("REPORTS_VIEW");
                list.add("AUDIT_VIEW");
                list.add("CATALOG_MANAGE");
                list.add("SCHEDULE_MANAGE");
                list.add("ALL_PRIVILEGES");
            }
            case "manager_role" -> {
                list.add("CLIENTS_MANAGE");
                list.add("SALES_MANAGE");
                list.add("CHECKIN_MANAGE");
                list.add("BOOKING_MANAGE");
            }
            case "hr_role" -> {
                list.add("STAFF_HIRE");
                list.add("STAFF_EDIT");
                list.add("STAFF_FIRE");
            }
            case "coach_role" -> {
                list.add("SCHEDULE_VIEW");
                list.add("CLASS_MARK");
                list.add("CHANGE_REQUEST");
            }
            case "client_role" -> {
                list.add("PROFILE_EDIT");
                list.add("BOOKING_CREATE");
                list.add("SUBSCRIPTION_MANAGE");
            }
            default -> list.add("GUEST_BROWSE");
        }
        return list;
    }

    private static class ProfileInfo {
        final Integer entityId;
        final String fullName;
        final String phone;
        final java.time.LocalDate birthDate;
        final String description;

        ProfileInfo(Integer entityId, String fullName, String phone, java.time.LocalDate birthDate, String description) {
            this.entityId = entityId;
            this.fullName = fullName;
            this.phone = phone;
            this.birthDate = birthDate;
            this.description = description;
        }
    }
}
