package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.exception.BusinessLogicException;
import com.fitness.dto.manager.*;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Repository
@Transactional
public class ManagerRepository {

    private final DynamicDataSourceService dataSourceService;

    public ManagerRepository(DynamicDataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    /**
     * M1: Register client as a new club member
     */
    public Integer createClient(CreateClientRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        if (req.dbUser() == null || req.dbUser().isBlank() || req.password() == null || req.password().isBlank()) {
            throw new BusinessLogicException("Логін та пароль є обов'язковими для створення клієнта.");
        }

        String dbUser = req.dbUser().trim();
        String sanitizedUser = dbUser.replaceAll("[^a-zA-Z0-9_]", "");
        if (sanitizedUser.isBlank()) {
            throw new BusinessLogicException("Логін користувача містить неприпустимі символи або є порожнім.");
        }
        String sanitizedPass = req.password().replace("'", "''");

        // Create PostgreSQL user via SECURITY DEFINER function
        try {
            jdbc.query("SELECT sp_create_client_user(?, ?)", (rs, rowNum) -> null, sanitizedUser, sanitizedPass);
        } catch (DataAccessException ex) {
            Throwable root = ex.getMostSpecificCause();
            String msg = root != null ? root.getMessage() : ex.getMessage();
            if (msg != null && (msg.contains("вже існує в системі") || msg.contains("вже існує"))) {
                throw new BusinessLogicException(String.format("Користувач з логіном \"%s\" вже існує в системі.", sanitizedUser));
            }
            throw ex;
        }

        String insertClientSql = """
            INSERT INTO Clients (FullName, BirthDate, Phone, Gender, DB_User)
            VALUES (?, ?, ?, ?, ?)
            RETURNING ID_Client
            """;

        Integer clientId;
        try {
            clientId = jdbc.queryForObject(
                    insertClientSql, Integer.class,
                    req.fullName(), req.birthDate(), req.phone(), req.gender(), sanitizedUser
            );
        } catch (DataAccessException ex) {
            Throwable root = ex.getMostSpecificCause();
            String msg = root != null ? root.getMessage() : ex.getMessage();
            if (msg != null && (msg.contains("Clients_db_user_key") || msg.contains("clients_db_user_key") || msg.contains("DB_User"))) {
                throw new BusinessLogicException(String.format("Користувач з логіном \"%s\" вже існує в системі.", sanitizedUser));
            }
            if (msg != null && (msg.contains("Clients_phone_key") || msg.contains("clients_phone_key") || msg.contains("Phone"))) {
                throw new BusinessLogicException(String.format("Клієнт з номером телефону \"%s\" вже зареєстрований.", req.phone()));
            }
            throw ex;
        }

        if (req.medicalNotes() != null && !req.medicalNotes().isBlank()) {
            jdbc.update("INSERT INTO MedicalNotes (ID_Client, NotesText) VALUES (?, ?)", clientId, req.medicalNotes());
        }

        return clientId;
    }

    /**
     * M2: Edit client details
     */
    public void updateClient(UpdateClientRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        String updateSql = """
            UPDATE Clients
            SET FullName = ?, BirthDate = ?, Phone = ?, Gender = ?
            WHERE ID_Client = ?
            """;
        jdbc.update(updateSql, req.fullName(), req.birthDate(), req.phone(), req.gender(), req.clientId());

        if (req.medicalNotes() != null) {
            String notesSql = """
                INSERT INTO MedicalNotes (ID_Client, NotesText)
                VALUES (?, ?)
                ON CONFLICT (ID_Client) DO UPDATE SET NotesText = EXCLUDED.NotesText
                """;
            jdbc.update(notesSql, req.clientId(), req.medicalNotes());
        }
    }

    /**
     * List / search clients with current subscription status
     */
    public List<ClientSummaryDto> searchClients(String search) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        StringBuilder sql = new StringBuilder("""
            SELECT 
                c.ID_Client,
                c.FullName,
                c.BirthDate,
                c.Phone,
                c.Gender,
                c.DB_User,
                COALESCE(mn.NotesText, 'Немає обмежень') AS NotesText,
                pl.ItemName AS ActiveSubName,
                cs.EndDate AS ActiveSubEndDate,
                COALESCE(cs.CurrentStatus, 'None') AS ActiveSubStatus
            FROM Clients c
            LEFT JOIN MedicalNotes mn ON c.ID_Client = mn.ID_Client
            LEFT JOIN LATERAL (
                SELECT cs_inner.EndDate, cs_inner.CurrentStatus, s_inner.ID_Item
                FROM ClientSubscriptions cs_inner
                JOIN Sales s_inner ON cs_inner.ID_Sale = s_inner.ID_Sale
                WHERE s_inner.ID_Client = c.ID_Client
                ORDER BY cs_inner.EndDate DESC
                LIMIT 1
            ) cs ON TRUE
            LEFT JOIN PriceList pl ON cs.ID_Item = pl.ID_Item
            """);

        List<Object> params = new java.util.ArrayList<>();
        if (search != null && !search.isBlank()) {
            String pattern = "%" + search.trim() + "%";
            sql.append(" WHERE c.FullName ILIKE ? OR c.Phone ILIKE ? ");
            params.add(pattern);
            params.add(pattern);
        }

        sql.append(" ORDER BY c.ID_Client DESC LIMIT 100");

        return jdbc.query(sql.toString(), (rs, rowNum) -> new ClientSummaryDto(
                rs.getInt("ID_Client"),
                rs.getString("FullName"),
                rs.getDate("BirthDate").toLocalDate(),
                rs.getString("Phone"),
                rs.getString("Gender"),
                rs.getString("DB_User"),
                rs.getString("NotesText"),
                rs.getString("ActiveSubName"),
                rs.getDate("ActiveSubEndDate") != null ? rs.getDate("ActiveSubEndDate").toLocalDate() : null,
                rs.getString("ActiveSubStatus")
        ), params.toArray());
    }

    /**
     * M3: Sell / extend subscription
     */
    public Integer sellSubscription(SellSubscriptionRequest req) {
        if (req.startDate() != null && req.startDate().isBefore(LocalDate.now())) {
            throw new BusinessLogicException("Дата початку дії абонемента не може бути в минулому.");
        }

        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        List<LocalDate> activeEnds = jdbc.query(
            """
            SELECT cs.EndDate FROM ClientSubscriptions cs
            JOIN Sales s ON cs.ID_Sale = s.ID_Sale
            WHERE s.ID_Client = ?
              AND cs.CurrentStatus IN ('Active', 'Frozen')
              AND cs.EndDate >= CURRENT_DATE
            ORDER BY cs.EndDate DESC LIMIT 1
            """,
            (rs, rowNum) -> rs.getDate("EndDate").toLocalDate(),
            req.clientId()
        );
        LocalDate activeEnd = activeEnds.stream().findFirst().orElse(null);
        if (activeEnd != null) {
            long daysUntilEnd = ChronoUnit.DAYS.between(LocalDate.now(), activeEnd);
            if (daysUntilEnd > 7) {
                throw new BusinessLogicException("Оформити новий абонемент можна не раніше ніж за 7 днів до закінчення діючого (доступно з " + activeEnd.minusDays(7) + ").");
            }
            if (req.startDate() != null && !req.startDate().isAfter(activeEnd)) {
                throw new BusinessLogicException("Дата початку нового абонемента (" + req.startDate() + ") не може перетинатися з діючим абонементом (діє до " + activeEnd + ").");
            }
        }

        Integer managerId = req.managerId();
        if (managerId == null) {
            List<Integer> sessionStaff = jdbc.query(
                    "SELECT s.ID_Staff FROM Staff s WHERE s.DB_User = SESSION_USER",
                    (rs, rowNum) -> rs.getInt(1)
            );
            managerId = sessionStaff.stream().findFirst().orElseGet(() -> getDefaultClientManagerId(jdbc));
        }

        // Validate manager position: only Client Managers can sell subscriptions
        List<String> posList = jdbc.query(
                """
                SELECT p.PositionName 
                FROM Staff s 
                JOIN Positions p ON s.ID_Position = p.ID_Position 
                WHERE s.ID_Staff = ?
                """,
                (rs, rowNum) -> rs.getString("PositionName"),
                managerId
        );

        String posName = posList.stream()
                .findFirst()
                .orElseThrow(() -> new BusinessLogicException("Співробітника для оформлення не знайдено."))
                .trim();
        String posLower = posName.toLowerCase();

        boolean isDirectorOrHr = posLower.contains("директор") || posLower.contains("hr");
        boolean isClientManager = (posLower.contains("менеджер клієнтів")
                || posLower.contains("менеджер по роботі з клієнтами")
                || posLower.contains("менеджер")) && !isDirectorOrHr;

        if (isDirectorOrHr || !isClientManager) {
            throw new BusinessLogicException("Оформлення продажу дозволено виключно менеджерам по роботі з клієнтами!");
        }

        String promo = (req.promoCode() != null && !req.promoCode().isBlank()) ? req.promoCode().trim() : null;

        return jdbc.queryForObject(
                "SELECT sale_id FROM sp_purchase_subscription(?, ?, ?, ?, ?)",
                Integer.class,
                req.clientId(),
                req.itemId(),
                promo,
                managerId,
                req.startDate()
        );
    }

    /**
     * M4: Check-in client visit
     */
    public CheckInResult checkInVisit(CheckInRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        // 1. Find client ID
        Integer clientId = req.clientId();
        if (clientId == null && req.phone() != null) {
            List<Integer> ids = jdbc.query("SELECT ID_Client FROM Clients WHERE Phone = ?",
                    (rs, rowNum) -> rs.getInt("ID_Client"), req.phone());
            clientId = ids.stream().findFirst().orElse(null);
        }
        if (clientId == null) {
            throw new BusinessLogicException("Клієнта не знайдено.");
        }

        if (req.hallId() == null) {
            throw new BusinessLogicException("Не вказано зал для входу.");
        }

        // 2. Register visit via Database-First stored function
        String sql = "SELECT out_visit_id, out_client_id, out_client_name, out_hall_name, out_sub_status " +
                     "FROM sp_register_visit(?, ?)";

        return jdbc.queryForObject(sql, (rs, rowNum) -> new CheckInResult(
                rs.getInt("out_visit_id"),
                rs.getInt("out_client_id"),
                rs.getString("out_client_name"),
                rs.getString("out_hall_name"),
                LocalDateTime.now(),
                rs.getString("out_sub_status")
        ), clientId, req.hallId());
    }

    /**
     * M5: Book client into group class
     */
    public void bookGroupClass(Integer clientId, Integer instanceId, String promoCode) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String promo = (promoCode != null && !promoCode.isBlank()) ? promoCode.trim() : null;
        jdbc.update("CALL sp_book_group_class(?, NULL, ?, ?)", instanceId, clientId, promo);
    }

    /**
     * M6: Book client into personal training
     */
    public Integer bookPersonalTraining(Integer clientId, Integer coachId, Integer hallId, LocalDateTime dateTime, String promoCode, Integer itemId) {
        if (dateTime == null || dateTime.isBefore(LocalDateTime.now())) {
            throw new BusinessLogicException("Дата та час персонального тренування не можуть бути в минулому.");
        }

        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        Integer managerId = getDefaultClientManagerId(jdbc);
        String promo = (promoCode != null && !promoCode.isBlank()) ? promoCode.trim() : null;

        return jdbc.queryForObject(
                "SELECT personal_id FROM sp_book_personal_training(?, ?, ?, ?, ?, ?, ?)",
                Integer.class,
                clientId,
                coachId,
                hallId,
                dateTime,
                promo,
                managerId,
                itemId
        );
    }

    public Integer bookPersonalTraining(Integer clientId, Integer coachId, Integer hallId, LocalDateTime dateTime, String promoCode) {
        return bookPersonalTraining(clientId, coachId, hallId, dateTime, promoCode, null);
    }

    /**
     * M7: Freeze subscription
     */
    public void freezeSubscription(FreezeRequest req) {
        if (req.startDate() == null || req.startDate().isBefore(LocalDate.now())) {
            throw new BusinessLogicException("Дата початку заморозки не може бути в минулому.");
        }
        if (req.endDate() == null || !req.endDate().isAfter(req.startDate())) {
            throw new BusinessLogicException("Дата закінчення заморозки повинна бути пізнішою за дату початку.");
        }

        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        long freezeDays = ChronoUnit.DAYS.between(req.startDate(), req.endDate());

        List<Object[]> rows = jdbc.query(
                "SELECT cs.ID_ClientSub, cs.RemainingFreezingDays, cs.EndDate FROM ClientSubscriptions cs " +
                "JOIN Sales s ON cs.ID_Sale = s.ID_Sale " +
                "WHERE cs.ID_ClientSub = ? OR (s.ID_Client = ? AND cs.CurrentStatus = 'Active') " +
                "ORDER BY (cs.ID_ClientSub = ?) DESC, cs.EndDate DESC LIMIT 1 FOR UPDATE OF cs",
                (rs, rowNum) -> new Object[]{rs.getInt("ID_ClientSub"), rs.getInt("RemainingFreezingDays"), rs.getDate("EndDate").toLocalDate()},
                req.clientSubId(), req.clientSubId(), req.clientSubId()
        );

        Object[] targetRow = rows.stream()
                .findFirst()
                .orElseThrow(() -> new BusinessLogicException("У клієнта немає активного абонемента для заморозки."));
        int targetSubId = (int) targetRow[0];
        int remaining = (int) targetRow[1];
        LocalDate endDate = (LocalDate) targetRow[2];

        if (remaining < freezeDays) {
            throw new BusinessLogicException("Недостатньо днів заморозки. Залишок: " + remaining + ", запитано: " + freezeDays);
        }

        jdbc.update("INSERT INTO FreezingLogs (ID_ClientSub, FreezeStartDate, FreezeEndDate, Reason) VALUES (?, ?, ?, ?)",
                targetSubId, req.startDate(), req.endDate(), req.reason());

        jdbc.update("UPDATE ClientSubscriptions SET EndDate = ?, RemainingFreezingDays = RemainingFreezingDays - ?, CurrentStatus = 'Frozen' WHERE ID_ClientSub = ?",
                endDate.plusDays(freezeDays), freezeDays, targetSubId);
    }

    /**
     * M8: Cancel or reschedule booking
     */
    public void changeBooking(BookingChangeRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        if ("Personal".equalsIgnoreCase(req.bookingType())) {
            if ("Cancel".equalsIgnoreCase(req.action())) {
                jdbc.update("UPDATE PersonalTrainings SET TrainingStatus = 'Cancelled' WHERE ID_Personal = ?", req.bookingId());
                jdbc.update("INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp, Status) VALUES (?, 'Cancel', ?, ?, CURRENT_TIMESTAMP, 'Approved')",
                        req.bookingId(), req.reason(), req.initiator() != null ? req.initiator() : "Manager");
            } else if ("Reschedule".equalsIgnoreCase(req.action())) {
                if (req.newDateTime() == null || req.newDateTime().isBefore(LocalDateTime.now())) {
                    throw new BusinessLogicException("Новий час тренування не може бути в минулому.");
                }

                LocalDateTime oldTime = jdbc.queryForObject(
                        "SELECT TrainingDateTime FROM PersonalTrainings WHERE ID_Personal = ?", LocalDateTime.class, req.bookingId()
                );
                Integer coachId = jdbc.queryForObject(
                        "SELECT ID_Coach FROM PersonalTrainings WHERE ID_Personal = ?", Integer.class, req.bookingId()
                );

                String checkConflict = """
                    SELECT COUNT(*) FROM PersonalTrainings 
                    WHERE ID_Coach = ? 
                      AND TrainingDateTime = ? 
                      AND TrainingStatus = 'Scheduled'
                      AND ID_Personal != ?
                    """;
                Integer conflicts = jdbc.queryForObject(checkConflict, Integer.class, coachId, req.newDateTime(), req.bookingId());
                if (conflicts != null && conflicts > 0) {
                    throw new BusinessLogicException("Тренер вже має заплановане тренування на новий час (" + req.newDateTime() + ").");
                }

                jdbc.update("UPDATE PersonalTrainings SET TrainingDateTime = ? WHERE ID_Personal = ?", req.newDateTime(), req.bookingId());

                Integer logId = jdbc.queryForObject(
                        "INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp, Status) VALUES (?, 'Reschedule', ?, ?, CURRENT_TIMESTAMP, 'Approved') RETURNING ID_PTLog",
                        Integer.class, req.bookingId(), req.reason(), req.initiator() != null ? req.initiator() : "Manager"
                );

                jdbc.update("INSERT INTO PT_TimeChangeDetails (ID_PTLog, OldDateTime, NewDateTime) VALUES (?, ?, ?)",
                        logId, oldTime, req.newDateTime());
            }
        } else if ("Group".equalsIgnoreCase(req.bookingType())) {
            if ("Cancel".equalsIgnoreCase(req.action())) {
                Integer instanceId = jdbc.queryForObject(
                        "SELECT ID_Instance FROM GroupClassBookings WHERE ID_Booking = ?", Integer.class, req.bookingId()
                );
                jdbc.update("UPDATE GroupClassBookings SET BookingStatus = 'Cancelled' WHERE ID_Booking = ?", req.bookingId());
                if (instanceId != null) {
                    jdbc.update("UPDATE GroupClassInstances SET ActualAttendance = GREATEST(ActualAttendance - 1, 0) WHERE ID_Instance = ?", instanceId);
                }
            } else if ("Reschedule".equalsIgnoreCase(req.action()) && req.newDateTime() != null) {
                List<Integer> instanceIds = jdbc.query(
                        "SELECT ID_Instance FROM GroupClassBookings WHERE ID_Booking = ?",
                        (rs, rowNum) -> rs.getInt(1), req.bookingId()
                );
                Integer targetInstanceId = instanceIds.stream().findFirst().orElse(req.bookingId());

                jdbc.update(
                        "UPDATE GroupClassInstances SET ClassDate = ?, ClassStartTime = ? WHERE ID_Instance = ?",
                        req.newDateTime().toLocalDate(), req.newDateTime().toLocalTime(), targetInstanceId
                );
            }
        }
    }

    /**
     * Create / schedule a group class instance
     */
    public Integer createGroupClassInstance(Integer templateId, LocalDate classDate, java.time.LocalTime startTime) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        if (startTime == null) {
            startTime = jdbc.queryForObject(
                    "SELECT StartTime FROM GroupScheduleTemplates WHERE ID_Template = ?",
                    java.time.LocalTime.class, templateId
            );
        }
        return jdbc.queryForObject(
                "INSERT INTO GroupClassInstances (ID_Template, ClassDate, ClassStatus, ActualAttendance, ClassStartTime) VALUES (?, ?, 'Scheduled', 0, ?) RETURNING ID_Instance",
                Integer.class, templateId, classDate, startTime
        );
    }

    private Integer getDefaultClientManagerId(JdbcTemplate jdbc) {
        List<Integer> list = jdbc.query(
                """
                SELECT s.ID_Staff 
                FROM Staff s 
                JOIN Positions p ON s.ID_Position = p.ID_Position 
                WHERE (p.PositionName ILIKE '%менеджер клієнтів%' OR p.PositionName ILIKE '%менеджер по роботі з клієнтами%' OR (p.PositionName ILIKE '%менеджер%' AND p.PositionName NOT ILIKE '%hr%'))
                  AND s.FireDate IS NULL 
                ORDER BY s.ID_Staff LIMIT 1
                """,
                (rs, rowNum) -> rs.getInt(1)
        );
        Integer staffId = list.stream().findFirst().orElse(null);
        if (staffId != null) {
            return staffId;
        }
        return jdbc.queryForObject("SELECT ID_Staff FROM Staff WHERE FireDate IS NULL LIMIT 1", Integer.class);
    }

    /**
     * Get pending and recent schedule change requests from coaches
     */
    public List<ScheduleChangeRequestDto> getScheduleRequests() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT cl.ID_PTLog, cl.ID_Personal, s_coach.FullName AS CoachName, c.FullName AS ClientName,
                   cl.RequestType, cl.Reason, cl.ChangeTimestamp, pt.TrainingDateTime AS CurrentDateTime,
                   tcd.NewDateTime AS ProposedDateTime, cl.Status
            FROM PT_Changelog cl
            JOIN PersonalTrainings pt ON cl.ID_Personal = pt.ID_Personal
            JOIN Coaches coach ON pt.ID_Coach = coach.ID_Coach
            JOIN Staff s_coach ON coach.ID_Staff = s_coach.ID_Staff
            JOIN Sales sale ON pt.ID_Sale = sale.ID_Sale
            JOIN Clients c ON sale.ID_Client = c.ID_Client
            LEFT JOIN PT_TimeChangeDetails tcd ON cl.ID_PTLog = tcd.ID_PTLog
            WHERE cl.ChangeInitiator = 'Coach'
            ORDER BY CASE WHEN cl.Status = 'Pending' THEN 0 ELSE 1 END, cl.ChangeTimestamp DESC
            """;

        return jdbc.query(sql, (rs, rowNum) -> new ScheduleChangeRequestDto(
                rs.getInt("ID_PTLog"),
                rs.getInt("ID_Personal"),
                rs.getString("CoachName"),
                rs.getString("ClientName"),
                rs.getString("RequestType"),
                rs.getString("Reason"),
                rs.getTimestamp("ChangeTimestamp").toLocalDateTime(),
                rs.getTimestamp("CurrentDateTime").toLocalDateTime(),
                rs.getTimestamp("ProposedDateTime") != null ? rs.getTimestamp("ProposedDateTime").toLocalDateTime() : null,
                rs.getString("Status")
        ));
    }

    /**
     * Approve a coach schedule request (Reschedule or Cancel)
     */
    public void approveScheduleRequest(Integer logId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        var rows = jdbc.query(
                "SELECT ID_PTLog, ID_Personal, RequestType, Status FROM PT_Changelog WHERE ID_PTLog = ?",
                (rs, rowNum) -> new Object[] {
                        rs.getInt("ID_PTLog"),
                        rs.getInt("ID_Personal"),
                        rs.getString("RequestType"),
                        rs.getString("Status")
                },
                logId
        );

        Object[] logRow = rows.stream()
                .findFirst()
                .orElseThrow(() -> new BusinessLogicException("Запит на зміну розкладу з ID " + logId + " не знайдено."));
        Integer personalId = (Integer) logRow[1];
        String requestType = (String) logRow[2];
        String status = (String) logRow[3];

        if (!"Pending".equalsIgnoreCase(status)) {
            throw new BusinessLogicException("Запит вже було оброблено (поточний статус: " + status + ").");
        }

        if ("Reschedule".equalsIgnoreCase(requestType)) {
            var timeRows = jdbc.query(
                    "SELECT NewDateTime FROM PT_TimeChangeDetails WHERE ID_PTLog = ?",
                    (rs, rowNum) -> rs.getTimestamp("NewDateTime").toLocalDateTime(),
                    logId
            );
            LocalDateTime newDateTime = timeRows.stream()
                    .filter(java.util.Objects::nonNull)
                    .findFirst()
                    .orElseThrow(() -> new BusinessLogicException("Для запиту на перенесення не вказано новий час у PT_TimeChangeDetails."));

            if (newDateTime.isBefore(LocalDateTime.now())) {
                throw new BusinessLogicException("Неможливо погодити запит: запропонований час перенесення вже минув.");
            }

            // Оновлення тренування (тригери БД перевірять зайнятість тренера та клієнта)
            jdbc.update("UPDATE PersonalTrainings SET TrainingDateTime = ? WHERE ID_Personal = ?", newDateTime, personalId);
        } else if ("Cancel".equalsIgnoreCase(requestType)) {
            jdbc.update("UPDATE PersonalTrainings SET TrainingStatus = 'Cancelled' WHERE ID_Personal = ?", personalId);
        }

        jdbc.update("UPDATE PT_Changelog SET Status = 'Approved' WHERE ID_PTLog = ?", logId);
    }

    /**
     * Reject a coach schedule request
     */
    public void rejectScheduleRequest(Integer logId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        int updated = jdbc.update("UPDATE PT_Changelog SET Status = 'Rejected' WHERE ID_PTLog = ? AND Status = 'Pending'", logId);
        if (updated == 0) {
            var exists = jdbc.query("SELECT Status FROM PT_Changelog WHERE ID_PTLog = ?", (rs, rowNum) -> rs.getString("Status"), logId);
            String currStatus = exists.stream()
                    .findFirst()
                    .orElseThrow(() -> new BusinessLogicException("Запит на зміну розкладу з ID " + logId + " не знайдено."));
            throw new BusinessLogicException("Неможливо відхилити: запит вже оброблено (статус: " + currStatus + ").");
        }
    }
}
