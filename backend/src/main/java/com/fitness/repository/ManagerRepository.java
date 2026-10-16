package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.exception.BusinessLogicException;
import com.fitness.model.ManagerDto.*;
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

        String dbUser = req.dbUser() != null && !req.dbUser().isBlank()
                ? req.dbUser()
                : "client_" + req.phone().replaceAll("[^0-9]", "");

        // Create PostgreSQL user via SECURITY DEFINER function
        if (req.password() != null && !req.password().isBlank()) {
            String sanitizedUser = dbUser.replaceAll("[^a-zA-Z0-9_]", "");
            String sanitizedPass = req.password().replace("'", "''");
            jdbc.query("SELECT sp_create_client_user(?, ?)", (rs, rowNum) -> null, sanitizedUser, sanitizedPass);
        }

        String insertClientSql = """
            INSERT INTO Clients (FullName, BirthDate, Phone, Gender, DB_User)
            VALUES (?, ?, ?, ?, ?)
            RETURNING ID_Client
            """;

        Integer clientId = jdbc.queryForObject(
                insertClientSql, Integer.class,
                req.fullName(), req.birthDate(), req.phone(), req.gender(), dbUser
        );

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
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        // 1. Resolve price and promo
        BigDecimal basePrice = jdbc.queryForObject(
                "SELECT Price FROM PriceList WHERE ID_Item = ?", BigDecimal.class, req.itemId()
        );
        if (basePrice == null) throw new BusinessLogicException("Товар не знайдено.");

        Integer promoId = null;
        int discount = 0;
        if (req.promoCode() != null && !req.promoCode().isBlank()) {
            List<Object[]> promoList = jdbc.query(
                    "SELECT ID_Promo, DiscountPercent FROM PromoCodes WHERE CodeText = ? AND ExpiryDate >= CURRENT_DATE",
                    (rs, rowNum) -> new Object[]{rs.getInt("ID_Promo"), rs.getInt("DiscountPercent")},
                    req.promoCode()
            );
            if (!promoList.isEmpty()) {
                promoId = (Integer) promoList.get(0)[0];
                discount = (Integer) promoList.get(0)[1];
            }
        }

        BigDecimal finalPrice = discount > 0
                ? basePrice.multiply(BigDecimal.valueOf(100 - discount)).divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP)
                : basePrice;

        Integer managerId = req.managerId();
        if (managerId == null) {
            List<Integer> sessionStaff = jdbc.query(
                    "SELECT s.ID_Staff FROM Staff s WHERE s.DB_User = SESSION_USER",
                    (rs, rowNum) -> rs.getInt(1)
            );
            if (!sessionStaff.isEmpty()) {
                managerId = sessionStaff.get(0);
            } else {
                managerId = getDefaultClientManagerId(jdbc);
            }
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

        if (posList.isEmpty()) {
            throw new BusinessLogicException("Співробітника для оформлення не знайдено.");
        }

        String posName = posList.get(0).trim();
        String posLower = posName.toLowerCase();

        boolean isDirectorOrHr = posLower.contains("директор") || posLower.contains("hr");
        boolean isClientManager = (posLower.contains("менеджер клієнтів")
                || posLower.contains("менеджер по роботі з клієнтами")
                || posLower.contains("менеджер")) && !isDirectorOrHr;

        if (isDirectorOrHr || !isClientManager) {
            throw new BusinessLogicException("Оформлення продажу дозволено виключно менеджерам по роботі з клієнтами!");
        }

        // 2. Insert Sale
        Integer saleId = jdbc.queryForObject(
                "INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP) RETURNING ID_Sale",
                Integer.class, req.clientId(), req.itemId(), finalPrice, managerId
        );

        if (promoId != null) {
            jdbc.update("INSERT INTO AppliedPromo (ID_Sale, ID_Promo) VALUES (?, ?)", saleId, promoId);
        }

        // 3. Insert Subscription if applicable
        List<Object[]> subInfo = jdbc.query(
                "SELECT DurationDays, MaxFreezingDays FROM PriceListSubs WHERE ID_Item = ?",
                (rs, rowNum) -> new Object[]{rs.getInt("DurationDays"), rs.getInt("MaxFreezingDays")},
                req.itemId()
        );

        if (!subInfo.isEmpty()) {
            int duration = (int) subInfo.get(0)[0];
            int maxFreeze = (int) subInfo.get(0)[1];
            LocalDate start = req.startDate() != null ? req.startDate() : LocalDate.now();
            LocalDate end = start.plusDays(duration);

            jdbc.update(
                    "INSERT INTO ClientSubscriptions (ID_Sale, StartDate, EndDate, CurrentStatus, RemainingFreezingDays) VALUES (?, ?, ?, 'Active', ?)",
                    saleId, start, end, maxFreeze
            );
        }

        return saleId;
    }

    /**
     * M4: Check-in client visit
     */
    public CheckInResult checkInVisit(CheckInRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        // 1. Find client
        Integer clientId = req.clientId();
        if (clientId == null && req.phone() != null) {
            clientId = jdbc.queryForObject("SELECT ID_Client FROM Clients WHERE Phone = ?", Integer.class, req.phone());
        }
        if (clientId == null) {
            throw new BusinessLogicException("Клієнта не знайдено.");
        }

        // 2. Find active subscription or membership sale
        String subSql = """
            SELECT cs.ID_Sale, cs.CurrentStatus, c.FullName, h.HallName
            FROM Clients c
            JOIN Sales s ON c.ID_Client = s.ID_Client
            JOIN ClientSubscriptions cs ON s.ID_Sale = cs.ID_Sale
            JOIN Halls h ON h.ID_Hall = ?
            WHERE c.ID_Client = ? 
              AND cs.CurrentStatus = 'Active' 
              AND cs.EndDate >= CURRENT_DATE
            ORDER BY cs.EndDate DESC
            LIMIT 1
            """;

        List<Object[]> rows = jdbc.query(subSql, (rs, rowNum) -> new Object[]{
                rs.getInt("ID_Sale"),
                rs.getString("CurrentStatus"),
                rs.getString("FullName"),
                rs.getString("HallName")
        }, req.hallId(), clientId);

        if (rows.isEmpty()) {
            throw new BusinessLogicException("У клієнта немає активного дійсного абонемента для входу в зал!");
        }

        Integer saleId = (Integer) rows.get(0)[0];
        String subStatus = (String) rows.get(0)[1];
        String clientName = (String) rows.get(0)[2];
        String hallName = (String) rows.get(0)[3];

        // 3. Register visit
        Integer visitId = jdbc.queryForObject(
                "INSERT INTO Visits (ID_Hall, ID_Sale, CheckInTime) VALUES (?, ?, CURRENT_TIMESTAMP) RETURNING ID_Visit",
                Integer.class, req.hallId(), saleId
        );

        return new CheckInResult(visitId, clientId, clientName, hallName, LocalDateTime.now(), subStatus);
    }

    /**
     * M5: Book client into group class
     */
    public void bookGroupClass(Integer clientId, Integer instanceId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        // Check instance capacity
        String capacitySql = """
            SELECT gci.ActualAttendance, h.MaxCapacity, gci.ClassStatus
            FROM GroupClassInstances gci
            JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
            JOIN Halls h ON gst.ID_Hall = h.ID_Hall
            WHERE gci.ID_Instance = ?
            FOR UPDATE OF gci
            """;

        List<Object[]> inst = jdbc.query(capacitySql, (rs, rowNum) -> new Object[]{
                rs.getInt("ActualAttendance"),
                rs.getInt("MaxCapacity"),
                rs.getString("ClassStatus")
        }, instanceId);

        if (inst.isEmpty()) throw new BusinessLogicException("Заняття не знайдено.");
        int attendance = (int) inst.get(0)[0];
        int maxCapacity = (int) inst.get(0)[1];
        if (attendance >= maxCapacity) throw new BusinessLogicException("Група повністю заповнена.");

        // Find or create a group class sale
        Integer itemId = jdbc.queryForObject(
                "SELECT ID_Item FROM PriceList WHERE Category = 'Group training' LIMIT 1", Integer.class
        );
        Integer managerId = getDefaultClientManagerId(jdbc);
        BigDecimal price = jdbc.queryForObject("SELECT Price FROM PriceList WHERE ID_Item = ?", BigDecimal.class, itemId);

        Integer saleId = jdbc.queryForObject(
                "INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP) RETURNING ID_Sale",
                Integer.class, clientId, itemId, price, managerId
        );

        jdbc.update("INSERT INTO GroupClassBookings (ID_Instance, ID_Sale, BookingStatus) VALUES (?, ?, 'Scheduled')", instanceId, saleId);
        jdbc.update("UPDATE GroupClassInstances SET ActualAttendance = ActualAttendance + 1 WHERE ID_Instance = ?", instanceId);
    }

    /**
     * M6: Book client into personal training
     */
    public Integer bookPersonalTraining(Integer clientId, Integer coachId, Integer hallId, LocalDateTime dateTime) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        // Check coach slot collision
        String checkConflict = """
            SELECT COUNT(*) FROM PersonalTrainings 
            WHERE ID_Coach = ? 
              AND TrainingDateTime = ? 
              AND TrainingStatus = 'Scheduled'
            """;
        Integer conflicts = jdbc.queryForObject(checkConflict, Integer.class, coachId, dateTime);
        if (conflicts != null && conflicts > 0) {
            throw new BusinessLogicException("Тренер вже зайнятий на цей час (" + dateTime + ").");
        }

        Integer itemId = jdbc.queryForObject(
                "SELECT ID_Item FROM PriceList WHERE Category = 'Personal training' LIMIT 1", Integer.class
        );
        Integer managerId = getDefaultClientManagerId(jdbc);
        BigDecimal price = jdbc.queryForObject("SELECT Price FROM PriceList WHERE ID_Item = ?", BigDecimal.class, itemId);

        Integer saleId = jdbc.queryForObject(
                "INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP) RETURNING ID_Sale",
                Integer.class, clientId, itemId, price, managerId
        );

        Integer ptId = jdbc.queryForObject(
                "INSERT INTO PersonalTrainings (ID_Coach, ID_Hall, ID_Sale, TrainingDateTime, TrainingStatus) VALUES (?, ?, ?, ?, 'Scheduled') RETURNING ID_Personal",
                Integer.class, coachId, hallId, saleId, dateTime
        );

        return ptId;
    }

    /**
     * M7: Freeze subscription
     */
    public void freezeSubscription(FreezeRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        long freezeDays = ChronoUnit.DAYS.between(req.startDate(), req.endDate());
        if (freezeDays <= 0) throw new BusinessLogicException("Невірний діапазон дат заморозки.");

        List<Object[]> rows = jdbc.query(
                "SELECT cs.ID_ClientSub, cs.RemainingFreezingDays, cs.EndDate FROM ClientSubscriptions cs " +
                "LEFT JOIN Sales s ON cs.ID_Sale = s.ID_Sale " +
                "WHERE cs.ID_ClientSub = ? OR (s.ID_Client = ? AND cs.CurrentStatus = 'Active') " +
                "ORDER BY (cs.ID_ClientSub = ?) DESC, cs.EndDate DESC LIMIT 1 FOR UPDATE",
                (rs, rowNum) -> new Object[]{rs.getInt("ID_ClientSub"), rs.getInt("RemainingFreezingDays"), rs.getDate("EndDate").toLocalDate()},
                req.clientSubId(), req.clientSubId(), req.clientSubId()
        );

        if (rows.isEmpty()) throw new BusinessLogicException("Активний абонемент для вказаного клієнта не знайдено.");
        int targetSubId = (int) rows.get(0)[0];
        int remaining = (int) rows.get(0)[1];
        LocalDate endDate = (LocalDate) rows.get(0)[2];

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
                jdbc.update("INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp) VALUES (?, 'Cancel', ?, ?, CURRENT_TIMESTAMP)",
                        req.bookingId(), req.reason(), req.initiator() != null ? req.initiator() : "Manager");
            } else if ("Reschedule".equalsIgnoreCase(req.action())) {
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
                        "INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp) VALUES (?, 'Reschedule', ?, ?, CURRENT_TIMESTAMP) RETURNING ID_PTLog",
                        Integer.class, req.bookingId(), req.reason(), req.initiator() != null ? req.initiator() : "Manager"
                );

                jdbc.update("INSERT INTO PT_TimeChangeDetails (ID_PTLog, OldDateTime, NewDateTime) VALUES (?, ?, ?)",
                        logId, oldTime, req.newDateTime());
            }
        } else if ("Group".equalsIgnoreCase(req.bookingType())) {
            Integer instanceId = jdbc.queryForObject(
                    "SELECT ID_Instance FROM GroupClassBookings WHERE ID_Booking = ?", Integer.class, req.bookingId()
            );
            jdbc.update("UPDATE GroupClassBookings SET BookingStatus = 'Cancelled' WHERE ID_Booking = ?", req.bookingId());
            if (instanceId != null) {
                jdbc.update("UPDATE GroupClassInstances SET ActualAttendance = GREATEST(ActualAttendance - 1, 0) WHERE ID_Instance = ?", instanceId);
            }
        }
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
        if (!list.isEmpty()) {
            return list.get(0);
        }
        return jdbc.queryForObject("SELECT ID_Staff FROM Staff WHERE FireDate IS NULL LIMIT 1", Integer.class);
    }
}
