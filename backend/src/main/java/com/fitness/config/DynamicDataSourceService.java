package com.fitness.config;

import com.fitness.exception.AuthenticationRequiredException;
import com.fitness.security.SecurityContextHolder;
import com.fitness.security.UserCredentials;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DelegatingDataSource;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Service providing dynamic DataSource connections based on the current user's PostgreSQL credentials.
 * Implements connection pooling via HikariCP per database role/user account.
 * When unauthenticated, falls back to guest_user credentials.
 */
@Service
public class DynamicDataSourceService {

    private static final Logger log = LoggerFactory.getLogger(DynamicDataSourceService.class);

    private final String jdbcUrl;
    private final String guestUsername;
    private final String guestPassword;
    private final String adminUsername;
    private final String adminPassword;

    private final int maxPoolSize;
    private final int minIdle;
    private final long idleTimeout;
    private final long maxLifetime;
    private final long connectionTimeout;

    // Cache of HikariDataSources keyed by "username:password"
    private final Map<String, HikariDataSource> dataSourceCache = new ConcurrentHashMap<>();

    public DynamicDataSourceService(
            @Value("${app.datasource.url}") String jdbcUrl,
            @Value("${app.datasource.guest-username:${fitness.db.guest.username:guest_user}}") String guestUsername,
            @Value("${app.datasource.guest-password:${fitness.db.guest.password:guest_pass_2026}}") String guestPassword,
            @Value("${app.datasource.admin-username:postgres}") String adminUsername,
            @Value("${app.datasource.admin-password:postgres}") String adminPassword,
            @Value("${app.datasource.hikari.maximum-pool-size:5}") int maxPoolSize,
            @Value("${app.datasource.hikari.minimum-idle:1}") int minIdle,
            @Value("${app.datasource.hikari.idle-timeout:60000}") long idleTimeout,
            @Value("${app.datasource.hikari.max-lifetime:300000}") long maxLifetime,
            @Value("${app.datasource.hikari.connection-timeout:5000}") long connectionTimeout
    ) {
        this.jdbcUrl = jdbcUrl;
        this.guestUsername = guestUsername;
        this.guestPassword = guestPassword;
        this.adminUsername = adminUsername;
        this.adminPassword = adminPassword;
        this.maxPoolSize = maxPoolSize;
        this.minIdle = minIdle;
        this.idleTimeout = idleTimeout;
        this.maxLifetime = maxLifetime;
        this.connectionTimeout = connectionTimeout;
    }

    public String getGuestUsername() {
        return guestUsername;
    }

    public String getGuestPassword() {
        return guestPassword;
    }

    @PostConstruct
    public void initGuestUserIfNeeded() {
        try {
            testConnection(guestUsername, guestPassword);
            log.info("PostgreSQL guest user [{}] connection verified successfully.", guestUsername);
        } catch (Exception e) {
            log.warn("Guest user [{}] connection test failed: {}. Attempting auto-provisioning via admin user [{}]...",
                    guestUsername, e.getMessage(), adminUsername);
            autoProvisionGuestUser();
        }
    }

    private void autoProvisionGuestUser() {
        try (Connection adminConn = DriverManager.getConnection(jdbcUrl, adminUsername, adminPassword);
             Statement stmt = adminConn.createStatement()) {

            String sql = """
                DO $$ 
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'guest') THEN
                        CREATE ROLE guest;
                    END IF;
                    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '%s') THEN
                        CREATE USER "%s" WITH PASSWORD '%s' IN ROLE guest;
                    ELSE
                        ALTER USER "%s" WITH PASSWORD '%s';
                        GRANT guest TO "%s";
                    END IF;
                    GRANT USAGE ON SCHEMA public TO guest;
                    GRANT SELECT ON ALL TABLES IN SCHEMA public TO guest;
                    GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO guest;
                END $$;
                """.formatted(guestUsername, guestUsername, guestPassword, guestUsername, guestPassword, guestUsername);

            stmt.execute(sql);
            log.info("Auto-provisioned PostgreSQL guest user [{}] successfully with configured password.", guestUsername);

            // Re-verify
            dataSourceCache.remove(guestUsername + "::" + guestPassword);
            testConnection(guestUsername, guestPassword);
            log.info("PostgreSQL guest user [{}] now operational.", guestUsername);
        } catch (Exception ex) {
            log.error("Could not auto-provision guest user via admin credentials (URL: {}): {}. "
                    + "Please ensure PostgreSQL container is running and 'fitness_schema_and_roles.sql' has been applied.",
                    jdbcUrl, ex.getMessage());
        }
    }

    /**
     * Get or create a pooled DataSource for the specified database user.
     */
    public DataSource getDataSource(String username, String password) {
        String cacheKey = username + "::" + password;
        return dataSourceCache.computeIfAbsent(cacheKey, key -> createHikariDataSource(username, password));
    }

    /**
     * Get the DataSource for the user currently executing the HTTP request.
     */
    public DataSource getCurrentUserDataSource() {
        return SecurityContextHolder.getCredentials()
                .map(creds -> getDataSource(creds.username(), creds.password()))
                .orElseGet(() -> getDataSource(guestUsername, guestPassword));
    }

    // Dynamic routing DataSource delegating to current user's HikariDataSource
    private final DataSource dynamicRoutingDataSource = new DelegatingDataSource() {
        @Override
        public DataSource getTargetDataSource() {
            return getCurrentUserDataSource();
        }

        @Override
        protected DataSource obtainTargetDataSource() {
            return getCurrentUserDataSource();
        }

        @Override
        public Connection getConnection() throws SQLException {
            return getCurrentUserDataSource().getConnection();
        }

        @Override
        public Connection getConnection(String username, String password) throws SQLException {
            return getCurrentUserDataSource().getConnection(username, password);
        }
    };

    private final JdbcTemplate dynamicJdbcTemplate = new JdbcTemplate(dynamicRoutingDataSource);

    public DataSource getDynamicRoutingDataSource() {
        return dynamicRoutingDataSource;
    }

    /**
     * Obtain a JdbcTemplate bound to the dynamic routing DataSource (supports @Transactional).
     */
    public JdbcTemplate getJdbcTemplate() {
        return dynamicJdbcTemplate;
    }

    /**
     * Obtain a JdbcTemplate for a specific user (e.g. during authentication check).
     */
    public JdbcTemplate getJdbcTemplateForUser(String username, String password) {
        return new JdbcTemplate(getDataSource(username, password));
    }

    /**
     * Test connection credentials against PostgreSQL.
     * Throws AuthenticationRequiredException if authentication is rejected.
     */
    public void testConnection(String username, String password) {
        DataSource ds = getDataSource(username, password);
        try (Connection conn = ds.getConnection()) {
            if (!conn.isValid(3)) {
                throw new SQLException("Connection isValid check returned false");
            }
        } catch (SQLException e) {
            log.warn("PostgreSQL connection test failed for user [{}]: {}", username, e.getMessage());
            // Evict broken datasource from cache
            dataSourceCache.remove(username + "::" + password);
            throw new AuthenticationRequiredException("PostgreSQL authentication failed: " + e.getMessage());
        }
    }

    private HikariDataSource createHikariDataSource(String username, String password) {
        log.info("Creating dynamic HikariDataSource pool for PostgreSQL user [{}] at [{}]", username, jdbcUrl);
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(jdbcUrl);
        config.setUsername(username);
        config.setPassword(password);
        config.setDriverClassName("org.postgresql.Driver");
        config.setMaximumPoolSize(maxPoolSize);
        config.setMinimumIdle(minIdle);
        config.setIdleTimeout(idleTimeout);
        config.setMaxLifetime(maxLifetime);
        config.setConnectionTimeout(connectionTimeout);
        config.setPoolName("HikariPool-" + username);

        // PostgreSQL optimization settings
        config.addDataSourceProperty("reWriteBatchedInserts", "true");
        config.addDataSourceProperty("ApplicationName", "FitnessClub-IS-" + username);

        try {
            return new HikariDataSource(config);
        } catch (Exception e) {
            log.error("Failed to initialize HikariDataSource for user [{}]: {}", username, e.getMessage());
            throw new AuthenticationRequiredException("Failed to connect to PostgreSQL as '" + username + "': " + e.getMessage());
        }
    }

    @PreDestroy
    public void closeAll() {
        log.info("Closing all dynamic Hikari connection pools...");
        dataSourceCache.values().forEach(ds -> {
            try {
                if (!ds.isClosed()) {
                    ds.close();
                }
            } catch (Exception e) {
                log.warn("Error closing DataSource pool: {}", e.getMessage());
            }
        });
        dataSourceCache.clear();
    }
}
