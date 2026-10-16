package com.fitness.security;

import com.fitness.config.DynamicDataSourceService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
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

        // 1. Check Bearer token or X-Auth-Token
        String token = extractToken(request);
        if (token != null) {
            Optional<UserSession> sessionOpt = sessionRegistry.getSession(token);
            if (sessionOpt.isPresent()) {
                UserSession session = sessionOpt.get();
                SecurityContextHolder.setSession(session);
                SecurityContextHolder.setCredentials(new UserCredentials(session.getUsername(), session.getPassword()));
                log.debug("Authenticated via session token as user: [{}] (role: {})", session.getUsername(), session.getRole());
                return true;
            }
        }

        // 2. Check Basic Auth header
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
                    return true;
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
            return true;
        }

        // 3. Reject unauthenticated access to protected role endpoints with 401
        String uri = request.getRequestURI();
        boolean isProtected = uri.startsWith("/api/director") || uri.startsWith("/api/manager")
                || uri.startsWith("/api/hr") || uri.startsWith("/api/coach") || uri.startsWith("/api/client");

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

        // 4. Fallback to guest_user credentials for public/guest operations
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
