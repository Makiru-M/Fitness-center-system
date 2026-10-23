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
        String sql = "SELECT * FROM sp_purchase_subscription(NULL, ?, ?, NULL, NULL)";

        return jdbc.queryForObject(sql, (rs, rowNum) -> new ClientSubscriptionDto(
                rs.getInt("sub_id"),
                rs.getInt("sale_id"),
                rs.getString("item_name"),
                rs.getDate("start_date").toLocalDate(),
                rs.getDate("end_date").toLocalDate(),
                rs.getString("status"),
                rs.getInt("remaining_freezing_days"),
                rs.getBigDecimal("final_price")
        ), req.itemId(), (req.promoCode() != null && !req.promoCode().isBlank()) ? req.promoCode().trim() : null);
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

        jdbc.update("CALL sp_freeze_client_subscription(?, ?, ?, ?)",
                req.clientSubId(), req.startDate(), req.endDate(), req.reason());
    }

    /**
     * Cl3: Unfreeze subscription
     */
    public void unfreezeSubscription(Integer clientSubId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        jdbc.update("CALL sp_unfreeze_client_subscription(?)", clientSubId);
    }

    /**
     * Cl4: Book group class
     */
    public void bookGroupClass(GroupBookingRequest req) {
        if (req.instanceId() == null) {
            throw new BusinessLogicException("Не вказано ідентифікатор заняття.");
        }

        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String promo = (req.promoCode() != null && !req.promoCode().isBlank()) ? req.promoCode().trim() : null;
        jdbc.update("CALL sp_book_group_class(?, NULL, NULL, ?)", req.instanceId(), promo);
    }

    /**
     * Cl5: Book personal training
     */
    public void bookPersonalTraining(PersonalBookingRequest req) {
        if (req.coachId() == null || req.hallId() == null || req.trainingDateTime() == null) {
            throw new BusinessLogicException("Заповніть усі обов'язкові поля для запису на тренування.");
        }

        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String promo = (req.promoCode() != null && !req.promoCode().isBlank()) ? req.promoCode().trim() : null;
        jdbc.queryForObject(
                "SELECT * FROM sp_book_personal_training(NULL, ?, ?, ?, ?, NULL)",
                (rs, rowNum) -> rs.getInt("personal_id"),
                req.coachId(),
                req.hallId(),
                req.trainingDateTime(),
                promo
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
                    "INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp, Status) VALUES (?, 'Cancel', ?, 'Client', CURRENT_TIMESTAMP, 'Approved')",
                    req.bookingId(), req.reason()
            );
        } else if ("Group".equalsIgnoreCase(req.bookingType())) {
            jdbc.update("CALL sp_cancel_group_booking(?)", req.bookingId());
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
     * Cl4 / M5: Get scheduled group class instances available for booking (CURRENT_DATE and onwards)
     */
    public List<AvailableGroupClassDto> getAvailableGroupClasses() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT 
                gci.ID_Instance,
                gst.ID_Template,
                ct.TypeName AS Title,
                st.FullName AS CoachName,
                h.HallName,
                gci.ClassDate,
                gci.ClassStartTime AS StartTime,
                gst.DurationMinutes,
                gci.ClassStatus::TEXT AS Status,
                gci.ActualAttendance,
                h.MaxCapacity,
                GREATEST(h.MaxCapacity - gci.ActualAttendance, 0) AS AvailableSpots,
                EXISTS (
                    SELECT 1 FROM GroupClassBookings gcb
                    JOIN Sales s ON gcb.ID_Sale = s.ID_Sale
                    JOIN Clients cl ON s.ID_Client = cl.ID_Client
                    WHERE gcb.ID_Instance = gci.ID_Instance
                      AND gcb.BookingStatus = 'Scheduled'
                      AND cl.DB_User = SESSION_USER
                ) AS IsBookedByMe
            FROM GroupClassInstances gci
            JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
            JOIN ClassTypes ct ON gst.ID_ClassType = ct.ID_ClassType
            JOIN Halls h ON gst.ID_Hall = h.ID_Hall
            JOIN Coaches co ON gst.ID_Coach = co.ID_Coach
            JOIN Staff st ON co.ID_Staff = st.ID_Staff
            WHERE gci.ClassStatus = 'Scheduled'
              AND gci.ClassDate >= CURRENT_DATE
            ORDER BY gci.ClassDate ASC, gci.ClassStartTime ASC
            """;

        return jdbc.query(sql, (rs, rowNum) -> new AvailableGroupClassDto(
                rs.getInt("ID_Instance"),
                rs.getInt("ID_Template"),
                rs.getString("Title"),
                rs.getString("CoachName"),
                rs.getString("HallName"),
                rs.getDate("ClassDate").toLocalDate(),
                rs.getTime("StartTime") != null ? rs.getTime("StartTime").toLocalTime() : null,
                rs.getInt("DurationMinutes"),
                rs.getString("Status"),
                rs.getInt("ActualAttendance"),
                rs.getInt("MaxCapacity"),
                rs.getInt("AvailableSpots"),
                rs.getBoolean("IsBookedByMe")
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
                gci.ID_Instance AS InstanceId,
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
                NULL::INTEGER AS InstanceId,
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
                rs.getObject("InstanceId") != null ? rs.getInt("InstanceId") : null,
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
