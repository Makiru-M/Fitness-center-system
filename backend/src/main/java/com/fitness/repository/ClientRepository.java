package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.exception.BusinessLogicException;
import com.fitness.model.ClientDto.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Repository
@Transactional
public class ClientRepository {

    private final DynamicDataSourceService dataSourceService;

    public ClientRepository(DynamicDataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    /**
     * Get current client profile (enforced by RLS)
     */
    public ClientProfileDto getProfile() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT c.ID_Client, c.FullName, c.BirthDate, c.Phone, c.Gender, c.DB_User, mn.NotesText
            FROM Clients c
            LEFT JOIN MedicalNotes mn ON c.ID_Client = mn.ID_Client
            WHERE c.DB_User = SESSION_USER
            """;

        List<ClientProfileDto> list = jdbc.query(sql, (rs, rowNum) -> new ClientProfileDto(
                rs.getInt("ID_Client"),
                rs.getString("FullName"),
                rs.getDate("BirthDate").toLocalDate(),
                rs.getString("Phone"),
                rs.getString("Gender"),
                rs.getString("DB_User"),
                rs.getString("NotesText")
        ));

        if (list.isEmpty()) {
            throw new BusinessLogicException("Профіль клієнта не знайдено для поточного користувача.");
        }
        return list.get(0);
    }

    /**
     * Cl1: Update client own profile (FullName, Phone, Medical notes)
     */
    public void updateProfile(UpdateClientProfileRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        if (req.fullName() != null && !req.fullName().isBlank() && req.phone() != null && !req.phone().isBlank()) {
            jdbc.update("UPDATE Clients SET FullName = ?, Phone = ? WHERE DB_User = SESSION_USER", req.fullName().trim(), req.phone().trim());
        } else if (req.fullName() != null && !req.fullName().isBlank()) {
            jdbc.update("UPDATE Clients SET FullName = ? WHERE DB_User = SESSION_USER", req.fullName().trim());
        } else if (req.phone() != null && !req.phone().isBlank()) {
            jdbc.update("UPDATE Clients SET Phone = ? WHERE DB_User = SESSION_USER", req.phone().trim());
        }

        if (req.medicalNotes() != null) {
            String upsertNotes = """
                INSERT INTO MedicalNotes (ID_Client, NotesText)
                VALUES ((SELECT ID_Client FROM Clients WHERE DB_User = SESSION_USER), ?)
                ON CONFLICT (ID_Client) DO UPDATE SET NotesText = EXCLUDED.NotesText
                """;
            jdbc.update(upsertNotes, req.medicalNotes());
        }
    }

    /**
     * Cl2: Renew / buy subscription
     */
    public ClientSubscriptionDto renewSubscription(RenewSubscriptionRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        // 1. Get client ID
        Integer clientId = jdbc.queryForObject(
                "SELECT ID_Client FROM Clients WHERE DB_User = SESSION_USER", Integer.class
        );

        // 2. Resolve price and promo discount
        BigDecimal basePrice = jdbc.queryForObject(
                "SELECT Price FROM PriceList WHERE ID_Item = ?", BigDecimal.class, req.itemId()
        );
        if (basePrice == null) {
            throw new BusinessLogicException("Послугу не знайдено в прайс-листі.");
        }

        Integer promoId = null;
        int discount = 0;
        if (req.promoCode() != null && !req.promoCode().isBlank()) {
            String promoSql = "SELECT ID_Promo, DiscountPercent FROM PromoCodes WHERE CodeText = ? AND ExpiryDate >= CURRENT_DATE";
            List<Object[]> promos = jdbc.query(promoSql, (rs, rowNum) -> new Object[]{rs.getInt("ID_Promo"), rs.getInt("DiscountPercent")}, req.promoCode());
            if (!promos.isEmpty()) {
                promoId = (Integer) promos.get(0)[0];
                discount = (Integer) promos.get(0)[1];
            }
        }

        BigDecimal finalPrice = discount > 0
                ? basePrice.multiply(BigDecimal.valueOf(100 - discount)).divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP)
                : basePrice;

        // 3. Find a manager ID for recording the sale
        Integer managerId = jdbc.queryForObject(
                "SELECT ID_Staff FROM Staff WHERE FireDate IS NULL LIMIT 1", Integer.class
        );

        // 4. Insert Sale
        Integer saleId = jdbc.queryForObject(
                "INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP) RETURNING ID_Sale",
                Integer.class, clientId, req.itemId(), finalPrice, managerId
        );

        if (promoId != null) {
            jdbc.update("INSERT INTO AppliedPromo (ID_Sale, ID_Promo) VALUES (?, ?)", saleId, promoId);
        }

        // 5. Insert ClientSubscription if subscription
        List<Object[]> subInfo = jdbc.query(
                "SELECT DurationDays, MaxFreezingDays FROM PriceListSubs WHERE ID_Item = ?",
                (rs, rowNum) -> new Object[]{rs.getInt("DurationDays"), rs.getInt("MaxFreezingDays")},
                req.itemId()
        );

        if (subInfo.isEmpty()) {
            throw new BusinessLogicException("Обраний пункт прайсу не є абонементом.");
        }

        int duration = (int) subInfo.get(0)[0];
        int maxFreeze = (int) subInfo.get(0)[1];
        LocalDate startDate = LocalDate.now();
        LocalDate endDate = startDate.plusDays(duration);

        Integer subId = jdbc.queryForObject(
                "INSERT INTO ClientSubscriptions (ID_Sale, StartDate, EndDate, CurrentStatus, RemainingFreezingDays) VALUES (?, ?, ?, 'Active', ?) RETURNING ID_ClientSub",
                Integer.class, saleId, startDate, endDate, maxFreeze
        );

        String itemName = jdbc.queryForObject("SELECT ItemName FROM PriceList WHERE ID_Item = ?", String.class, req.itemId());

        return new ClientSubscriptionDto(subId, saleId, itemName, startDate, endDate, "Active", maxFreeze, finalPrice);
    }

    /**
     * Cl3: Freeze subscription
     */
    public void freezeSubscription(FreezeSubscriptionRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        long freezeDays = ChronoUnit.DAYS.between(req.startDate(), req.endDate());
        if (freezeDays <= 0) {
            throw new BusinessLogicException("Дата закінчення заморозки повинна бути пізнішою за дату початку.");
        }

        // Check subscription remaining days
        String checkSql = """
            SELECT cs.RemainingFreezingDays, cs.EndDate, cs.CurrentStatus
            FROM ClientSubscriptions cs
            JOIN Sales s ON cs.ID_Sale = s.ID_Sale
            JOIN Clients c ON s.ID_Client = c.ID_Client
            WHERE cs.ID_ClientSub = ? AND c.DB_User = SESSION_USER
            FOR UPDATE
            """;

        List<Object[]> rows = jdbc.query(checkSql, (rs, rowNum) -> new Object[]{
                rs.getInt("RemainingFreezingDays"),
                rs.getDate("EndDate").toLocalDate(),
                rs.getString("CurrentStatus")
        }, req.clientSubId());

        if (rows.isEmpty()) {
            throw new BusinessLogicException("Абонемент не знайдено або він не належить вам.");
        }

        int remainingDays = (int) rows.get(0)[0];
        LocalDate oldEndDate = (LocalDate) rows.get(0)[1];
        String status = (String) rows.get(0)[2];

        if (!"Active".equalsIgnoreCase(status)) {
            throw new BusinessLogicException("Заморозити можна лише активний абонемент. Поточний статус: " + status);
        }

        if (remainingDays < freezeDays) {
            throw new BusinessLogicException("Недостатньо доступних днів заморозки. Залишок: " + remainingDays + ", запитано: " + freezeDays);
        }

        // Record freezing log
        jdbc.update(
                "INSERT INTO FreezingLogs (ID_ClientSub, FreezeStartDate, FreezeEndDate, Reason) VALUES (?, ?, ?, ?)",
                req.clientSubId(), req.startDate(), req.endDate(), req.reason()
        );

        // Update subscription
        LocalDate newEndDate = oldEndDate.plusDays(freezeDays);
        jdbc.update(
                "UPDATE ClientSubscriptions SET EndDate = ?, RemainingFreezingDays = RemainingFreezingDays - ?, CurrentStatus = 'Frozen' WHERE ID_ClientSub = ?",
                newEndDate, freezeDays, req.clientSubId()
        );
    }

    /**
     * Cl4: Book group class
     */
    public void bookGroupClass(GroupBookingRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        // 1. Check capacity
        String capacitySql = """
            SELECT gci.ActualAttendance, h.MaxCapacity, gci.ClassStatus
            FROM GroupClassInstances gci
            JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
            JOIN Halls h ON gst.ID_Hall = h.ID_Hall
            WHERE gci.ID_Instance = ?
            FOR UPDATE
            """;
        List<Object[]> instList = jdbc.query(capacitySql, (rs, rowNum) -> new Object[]{
                rs.getInt("ActualAttendance"),
                rs.getInt("MaxCapacity"),
                rs.getString("ClassStatus")
        }, req.instanceId());

        if (instList.isEmpty()) {
            throw new BusinessLogicException("Екземпляр групового заняття не знайдено.");
        }

        int attendance = (int) instList.get(0)[0];
        int maxCapacity = (int) instList.get(0)[1];
        String classStatus = (String) instList.get(0)[2];

        if (!"Scheduled".equalsIgnoreCase(classStatus)) {
            throw new BusinessLogicException("Запис неможливий: статус заняття '" + classStatus + "'.");
        }
        if (attendance >= maxCapacity) {
            throw new BusinessLogicException("Вільних місць у залі немає (місткість: " + maxCapacity + ").");
        }

        // 2. Create booking
        jdbc.update(
                "INSERT INTO GroupClassBookings (ID_Instance, ID_Sale, BookingStatus) VALUES (?, ?, 'Scheduled')",
                req.instanceId(), req.saleId()
        );

        // 3. Increment attendance count
        jdbc.update("UPDATE GroupClassInstances SET ActualAttendance = ActualAttendance + 1 WHERE ID_Instance = ?", req.instanceId());
    }

    /**
     * Cl5: Book personal training
     */
    public void bookPersonalTraining(PersonalBookingRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        // Validate coach existence
        List<Integer> coachExists = jdbc.query(
                "SELECT ID_Coach FROM Coaches WHERE ID_Coach = ?",
                (rs, rowNum) -> rs.getInt(1),
                req.coachId()
        );
        if (coachExists.isEmpty()) {
            throw new BusinessLogicException("Тренера не знайдено.");
        }

        // Check if coach has conflicting training at this time
        String checkConflict = """
            SELECT COUNT(*) FROM PersonalTrainings 
            WHERE ID_Coach = ? 
              AND TrainingDateTime = ? 
              AND TrainingStatus = 'Scheduled'
            """;
        Integer conflicts = jdbc.queryForObject(checkConflict, Integer.class, req.coachId(), req.trainingDateTime());
        if (conflicts != null && conflicts > 0) {
            throw new BusinessLogicException("Тренер вже зайнятий на цей час.");
        }

        jdbc.update(
                "INSERT INTO PersonalTrainings (ID_Coach, ID_Hall, ID_Sale, TrainingDateTime, TrainingStatus) VALUES (?, ?, ?, ?, 'Scheduled')",
                req.coachId(), req.hallId(), req.saleId(), req.trainingDateTime()
        );
    }

    /**
     * Cl6: Cancel booking (personal or group)
     */
    public void cancelBooking(CancelBookingRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        if ("Personal".equalsIgnoreCase(req.bookingType())) {
            // Update personal training status
            int updated = jdbc.update(
                    "UPDATE PersonalTrainings SET TrainingStatus = 'Cancelled' WHERE ID_Personal = ? AND TrainingStatus = 'Scheduled'",
                    req.bookingId()
            );
            if (updated == 0) {
                throw new BusinessLogicException("Запис на тренування не знайдено або він вже не є запланованим.");
            }

            // Log cancellation
            jdbc.update(
                    "INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp) VALUES (?, 'Cancel', ?, 'Client', CURRENT_TIMESTAMP)",
                    req.bookingId(), req.reason()
            );
        } else if ("Group".equalsIgnoreCase(req.bookingType())) {
            // Get instance ID to decrement attendance
            Integer instanceId = jdbc.queryForObject(
                    "SELECT ID_Instance FROM GroupClassBookings WHERE ID_Booking = ? AND BookingStatus = 'Scheduled'",
                    Integer.class, req.bookingId()
            );
            if (instanceId == null) {
                throw new BusinessLogicException("Запис на групове заняття не знайдено.");
            }

            jdbc.update("UPDATE GroupClassBookings SET BookingStatus = 'Cancelled' WHERE ID_Booking = ?", req.bookingId());
            jdbc.update("UPDATE GroupClassInstances SET ActualAttendance = GREATEST(ActualAttendance - 1, 0) WHERE ID_Instance = ?", instanceId);
        } else {
            throw new BusinessLogicException("Невідомий тип бронювання: " + req.bookingType());
        }
    }

    /**
     * Get client's active and past subscriptions
     */
    public List<ClientSubscriptionDto> getMySubscriptions() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT cs.ID_ClientSub, cs.ID_Sale, pl.ItemName, cs.StartDate, cs.EndDate, cs.CurrentStatus, cs.RemainingFreezingDays, s.SalePrice
            FROM ClientSubscriptions cs
            JOIN Sales s ON cs.ID_Sale = s.ID_Sale
            JOIN PriceList pl ON s.ID_Item = pl.ID_Item
            JOIN Clients c ON s.ID_Client = c.ID_Client
            WHERE c.DB_User = SESSION_USER
            ORDER BY cs.EndDate DESC
            """;

        return jdbc.query(sql, (rs, rowNum) -> new ClientSubscriptionDto(
                rs.getInt("ID_ClientSub"),
                rs.getInt("ID_Sale"),
                rs.getString("ItemName"),
                rs.getDate("StartDate").toLocalDate(),
                rs.getDate("EndDate").toLocalDate(),
                rs.getString("CurrentStatus"),
                rs.getInt("RemainingFreezingDays"),
                rs.getBigDecimal("SalePrice")
        ));
    }

    /**
     * Get client's bookings (group + personal combined)
     */
    public List<ClientBookingDto> getMyBookings() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT 
                gcb.ID_Booking AS BookingId,
                'Group' AS ActivityType,
                ct.TypeName AS Title,
                st.FullName AS CoachName,
                h.HallName,
                (gci.ClassDate + gci.ClassStartTime)::TIMESTAMP AS TrainingDateTime,
                gcb.BookingStatus::TEXT AS Status
            FROM GroupClassBookings gcb
            JOIN GroupClassInstances gci ON gcb.ID_Instance = gci.ID_Instance
            JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
            JOIN ClassTypes ct ON gst.ID_ClassType = ct.ID_ClassType
            JOIN Coaches co ON gst.ID_Coach = co.ID_Coach
            JOIN Staff st ON co.ID_Staff = st.ID_Staff
            JOIN Halls h ON gst.ID_Hall = h.ID_Hall
            JOIN Sales s ON gcb.ID_Sale = s.ID_Sale
            JOIN Clients c ON s.ID_Client = c.ID_Client
            WHERE c.DB_User = SESSION_USER

            UNION ALL

            SELECT 
                pt.ID_Personal AS BookingId,
                'Personal' AS ActivityType,
                'Персональне тренування' AS Title,
                st.FullName AS CoachName,
                h.HallName,
                pt.TrainingDateTime,
                pt.TrainingStatus::TEXT AS Status
            FROM PersonalTrainings pt
            JOIN Coaches co ON pt.ID_Coach = co.ID_Coach
            JOIN Staff st ON co.ID_Staff = st.ID_Staff
            JOIN Halls h ON pt.ID_Hall = h.ID_Hall
            JOIN Sales s ON pt.ID_Sale = s.ID_Sale
            JOIN Clients c ON s.ID_Client = c.ID_Client
            WHERE c.DB_User = SESSION_USER
            ORDER BY TrainingDateTime DESC
            """;

        return jdbc.query(sql, (rs, rowNum) -> new ClientBookingDto(
                rs.getInt("BookingId"),
                rs.getString("ActivityType"),
                rs.getString("Title"),
                rs.getString("CoachName"),
                rs.getString("HallName"),
                rs.getTimestamp("TrainingDateTime").toLocalDateTime(),
                rs.getString("Status")
        ));
    }

    /**
     * Get client's visit history
     */
    public List<VisitDto> getMyVisits() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT v.ID_Visit, h.HallName, v.CheckInTime, pl.ItemName
            FROM Visits v
            JOIN Halls h ON v.ID_Hall = h.ID_Hall
            JOIN Sales s ON v.ID_Sale = s.ID_Sale
            JOIN PriceList pl ON s.ID_Item = pl.ID_Item
            JOIN Clients c ON s.ID_Client = c.ID_Client
            WHERE c.DB_User = SESSION_USER
            ORDER BY v.CheckInTime DESC
            """;

        return jdbc.query(sql, (rs, rowNum) -> new VisitDto(
                rs.getInt("ID_Visit"),
                rs.getString("HallName"),
                rs.getTimestamp("CheckInTime").toLocalDateTime(),
                rs.getString("ItemName")
        ));
    }
}
