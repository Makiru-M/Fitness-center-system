package com.fitness.security;

import com.fitness.config.DynamicDataSourceService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Locale;
import java.util.Optional;

@Component
public class AuthInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(AuthInterceptor.class);

    private final SessionRegistry sessionRegistry;
    private final DynamicDataSourceService dataSourceService;

    public AuthInterceptor(SessionRegistry sessionRegistry, DynamicDataSourceService dataSourceService) {
        this.sessionRegistry = sessionRegistry;
        this.dataSourceService = dataSourceService;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        // Clear any leftover thread context
        SecurityContextHolder.clear();

        String uri = request.getRequestURI();
        UserSession session = null;

        // 1. Check Bearer token or X-Auth-Token
        String token = extractToken(request);
        if (token != null) {
            Optional<UserSession> sessionOpt = sessionRegistry.getSession(token);
            if (sessionOpt.isPresent()) {
                session = sessionOpt.get();
                SecurityContextHolder.setSession(session);
                SecurityContextHolder.setCredentials(new UserCredentials(session.getUsername(), session.getPassword()));
                log.debug("Authenticated via session token as user: [{}] (role: {})", session.getUsername(), session.getRole());
            }
        }

        // 2. Check Basic Auth header if session was not found
        if (session == null) {
            String authHeader = request.getHeader("Authorization");
            if (authHeader != null && authHeader.regionMatches(true, 0, "Basic ", 0, 6)) {
                String base64Credentials = authHeader.substring(6).trim();
                try {
                    byte[] decoded = Base64.getDecoder().decode(base64Credentials);
                    String credentials = new String(decoded, StandardCharsets.UTF_8);
                    int colonIndex = credentials.indexOf(':');
                    if (colonIndex != -1) {
                        String username = credentials.substring(0, colonIndex);
                        String password = credentials.substring(colonIndex + 1);
                        SecurityContextHolder.setCredentials(new UserCredentials(username, password));
                        log.debug("Authenticated via Basic Auth as user: [{}]", username);
                    }
                } catch (Exception e) {
                    log.warn("Invalid Basic Auth header format: {}", e.getMessage());
                }
            }

            // 2b. Check X-Auth-User and X-Auth-Password headers
            String xUser = request.getHeader("X-Auth-User");
            String xPass = request.getHeader("X-Auth-Password");
            if (xUser != null && !xUser.isBlank() && xPass != null && !xPass.isBlank()) {
                SecurityContextHolder.setCredentials(new UserCredentials(xUser.trim(), xPass.trim()));
                log.debug("Authenticated via X-Auth headers as user: [{}]", xUser);
            }
        }

        // 3. Role-Based Access Control (RBAC) validation for protected role endpoints
        boolean isProtected = isProtectedEndpoint(uri);

        if (session != null) {
            if (isProtected && !isRoleAllowedForUri(session.getRole(), uri)) {
                log.warn("Access denied: user [{}] with role [{}] attempted to access [{}]",
                        session.getUsername(), session.getRole(), uri);
                return sendForbidden(response);
            }
            return true;
        }

        // 4. If request has credentials but no session, check fallback for protected routes
        if (SecurityContextHolder.getCredentials().isPresent()) {
            if (isProtected) {
                // Determine user role if possible or reject unverified access to protected routes
                String user = SecurityContextHolder.getCredentials().get().username();
                String role = inferRoleFromUsername(user);
                if (role != null) {
                    if (!isRoleAllowedForUri(role, uri)) {
                        log.warn("Access denied (credentials): user [{}] with inferred role [{}] attempted to access [{}]",
                                user, role, uri);
                        return sendForbidden(response);
                    }
                    return true;
                }
            } else {
                return true;
            }
        }

        // 5. Reject unauthenticated access to protected role endpoints with 401
        if (isProtected) {
            log.warn("Unauthenticated request to protected endpoint: [{}]", uri);
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            try {
                response.getWriter().write("{\"status\":401,\"error\":\"Unauthorized\",\"message\":\"Потрібна авторизація для доступу до цього ресурсу.\"}");
            } catch (Exception e) {
                log.error("Failed to write 401 response: {}", e.getMessage());
            }
            return false;
        }

        // 6. Fallback to guest_user credentials for public/guest operations
        SecurityContextHolder.setCredentials(new UserCredentials(
                dataSourceService.getGuestUsername(),
                dataSourceService.getGuestPassword()
        ));
        log.debug("Request scoped to guest user credentials: [{}]", dataSourceService.getGuestUsername());
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        SecurityContextHolder.clear();
    }

    private boolean isProtectedEndpoint(String uri) {
        return uri.startsWith("/api/director") || uri.startsWith("/api/manager")
                || uri.startsWith("/api/hr") || uri.startsWith("/api/coach") || uri.startsWith("/api/client");
    }

    private boolean isRoleAllowedForUri(String rawRole, String uri) {
        String role = normalizeRole(rawRole);
        if ("director_role".equals(role)) {
            // Super-role: access to director, manager, hr, coach, and client endpoints
            return true;
        }

        if (uri.startsWith("/api/director")) {
            return false;
        }
        if (uri.startsWith("/api/manager")) {
            return "manager_role".equals(role);
        }
        if (uri.startsWith("/api/hr")) {
            return "hr_role".equals(role);
        }
        if (uri.startsWith("/api/coach")) {
            return "coach_role".equals(role);
        }
        if (uri.startsWith("/api/client")) {
            if (uri.equals("/api/client/group-classes/available")) {
                return "client_role".equals(role) || "manager_role".equals(role);
            }
            return "client_role".equals(role);
        }

        return true;
    }

    private String normalizeRole(String role) {
        if (role == null || role.isBlank()) {
            return "";
        }
        String clean = role.trim().toLowerCase(Locale.ROOT);
        if (clean.equals("director") || clean.equals("director_role") || clean.equals("admin")) {
            return "director_role";
        }
        if (clean.equals("manager") || clean.equals("manager_role")) {
            return "manager_role";
        }
        if (clean.equals("hr") || clean.equals("hr_role")) {
            return "hr_role";
        }
        if (clean.equals("coach") || clean.equals("coach_role")) {
            return "coach_role";
        }
        if (clean.equals("client") || clean.equals("client_role")) {
            return "client_role";
        }
        return clean;
    }

    private String inferRoleFromUsername(String username) {
        if (username == null || username.isBlank()) return null;
        String clean = username.trim().toLowerCase(Locale.ROOT);
        if (clean.equals("boss_ivan")) return "director_role";
        if (clean.equals("manager_petro")) return "manager_role";
        if (clean.equals("admin_olena")) return "hr_role";
        if (clean.equals("coach_maksym")) return "coach_role";
        if (clean.equals("user_oleksandr")) return "client_role";
        if (clean.startsWith("user_")) return "client_role";
        return null;
    }

    private boolean sendForbidden(HttpServletResponse response) {
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType("application/json;charset=UTF-8");
        try {
            response.getWriter().write("{\"status\":403,\"error\":\"Forbidden\",\"message\":\"Недостатньо прав для виконання цієї операції.\"}");
        } catch (IOException e) {
            log.error("Failed to write 403 response: {}", e.getMessage());
        }
        return false;
    }

    private String extractToken(HttpServletRequest request) {
        String xAuthToken = request.getHeader("X-Auth-Token");
        if (xAuthToken != null && !xAuthToken.isBlank()) {
            return xAuthToken.trim();
        }

        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.regionMatches(true, 0, "Bearer ", 0, 7)) {
            return authHeader.substring(7).trim();
        }

        return null;
    }
}
