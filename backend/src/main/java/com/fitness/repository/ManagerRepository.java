package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.dto.manager.*;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Repository
public class ManagerRepository {

    private final DynamicDataSourceService dataSourceService;

    public ManagerRepository(DynamicDataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    private JdbcTemplate getJdbcTemplate() {
        return dataSourceService.getJdbcTemplate();
    }

    /**
     * Call stored function sp_create_client_user to create DB user.
     */
    public void createClientDbUser(String username, String password) {
        getJdbcTemplate().query("SELECT sp_create_client_user(?, ?)", (rs, rowNum) -> null, username, password);
    }

    /**
     * Insert record into Clients table.
     */
    public Integer insertClient(String fullName, LocalDate birthDate, String phone, String gender, String dbUser) {
        String sql = """
            INSERT INTO Clients (FullName, BirthDate, Phone, Gender, DB_User)
            VALUES (?, ?, ?, ?, ?)
            RETURNING ID_Client
            """;
        return getJdbcTemplate().queryForObject(sql, Integer.class, fullName, birthDate, phone, gender, dbUser);
    }

    /**
     * Insert record into MedicalNotes.
     */
    public void insertMedicalNotes(Integer clientId, String notesText) {
        getJdbcTemplate().update("INSERT INTO MedicalNotes (ID_Client, NotesText) VALUES (?, ?)", clientId, notesText);
    }

    /**
     * Upsert record into MedicalNotes.
     */
    public void upsertMedicalNotes(Integer clientId, String notesText) {
        String sql = """
            INSERT INTO MedicalNotes (ID_Client, NotesText)
            VALUES (?, ?)
            ON CONFLICT (ID_Client) DO UPDATE SET NotesText = EXCLUDED.NotesText
            """;
        getJdbcTemplate().update(sql, clientId, notesText);
    }

    /**
     * Update client details in Clients table.
     */
    public void updateClientDetails(Integer clientId, String fullName, LocalDate birthDate, String phone, String gender) {
        String sql = """
            UPDATE Clients
            SET FullName = ?, BirthDate = ?, Phone = ?, Gender = ?
            WHERE ID_Client = ?
            """;
        getJdbcTemplate().update(sql, fullName, birthDate, phone, gender, clientId);
    }

    /**
     * Search clients with current subscription status.
     */
    public List<ClientSummaryDto> searchClients(String searchPattern) {
        StringBuilder sql = new StringBuilder("""
            SELECT 
                c.ID_Client,
                c.FullName,
                c.BirthDate,
                c.Phone,
                c.Gender,
                c.DB_User,
                COALESCE(mn.NotesText, 'Немає обмежень') AS NotesText,
                pl.ItemName AS ActiveSubscriptionName,
                cs.EndDate AS ActiveSubscriptionEndDate,
                COALESCE(cs.CurrentStatus, 'None') AS ActiveSubscriptionStatus
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
        if (searchPattern != null) {
            sql.append(" WHERE c.FullName ILIKE ? OR c.Phone ILIKE ? ");
            params.add(searchPattern);
            params.add(searchPattern);
        }

        sql.append(" ORDER BY c.ID_Client DESC LIMIT 100");

        return getJdbcTemplate().query(sql.toString(), (rs, rowNum) -> new ClientSummaryDto(
                rs.getInt("ID_Client"),
                rs.getString("FullName"),
                rs.getDate("BirthDate").toLocalDate(),
                rs.getString("Phone"),
                rs.getString("Gender"),
                rs.getString("DB_User"),
                rs.getString("NotesText"),
                rs.getString("ActiveSubscriptionName"),
                rs.getDate("ActiveSubscriptionEndDate") != null ? rs.getDate("ActiveSubscriptionEndDate").toLocalDate() : null,
                rs.getString("ActiveSubscriptionStatus")
        ), params.toArray());
    }

    /**
     * Find latest active or frozen subscription end date for a client.
     */
    public LocalDate findActiveSubscriptionEndDate(Integer clientId) {
        List<LocalDate> activeEnds = getJdbcTemplate().query(
                """
                SELECT cs.EndDate FROM ClientSubscriptions cs
                JOIN Sales s ON cs.ID_Sale = s.ID_Sale
                WHERE s.ID_Client = ?
                  AND cs.CurrentStatus IN ('Active', 'Frozen')
                  AND cs.EndDate >= CURRENT_DATE
                ORDER BY cs.EndDate DESC LIMIT 1
                """,
                (rs, rowNum) -> rs.getDate("EndDate").toLocalDate(),
                clientId
        );
        return activeEnds.stream().findFirst().orElse(null);
    }

    /**
     * Find current session staff ID if connected under staff account.
     */
    public Integer findSessionStaffId() {
        List<Integer> sessionStaff = getJdbcTemplate().query(
                "SELECT s.ID_Staff FROM Staff s WHERE s.DB_User = SESSION_USER",
                (rs, rowNum) -> rs.getInt(1)
        );
        return sessionStaff.stream().findFirst().orElse(null);
    }

    /**
     * Find default active client manager staff ID.
     */
    public Integer findDefaultClientManagerId() {
        List<Integer> list = getJdbcTemplate().query(
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
        return getJdbcTemplate().queryForObject("SELECT ID_Staff FROM Staff WHERE FireDate IS NULL LIMIT 1", Integer.class);
    }

    /**
     * Get staff position name by staff ID.
     */
    public String getStaffPositionName(Integer staffId) {
        List<String> posList = getJdbcTemplate().query(
                """
                SELECT p.PositionName 
                FROM Staff s 
                JOIN Positions p ON s.ID_Position = p.ID_Position 
                WHERE s.ID_Staff = ?
                """,
                (rs, rowNum) -> rs.getString("PositionName"),
                staffId
        );
        return posList.stream().findFirst().orElse(null);
    }

    /**
     * Call stored function sp_purchase_subscription.
     */
    public Integer purchaseSubscription(Integer clientId, Integer itemId, String promoCode, Integer managerId, LocalDate startDate) {
        return getJdbcTemplate().queryForObject(
                "SELECT sale_id FROM sp_purchase_subscription(?, ?, ?, ?, ?)",
                Integer.class,
                clientId,
                itemId,
                promoCode,
                managerId,
                startDate
        );
    }

    /**
     * Find client ID by phone.
     */
    public Integer findClientIdByPhone(String phone) {
        List<Integer> ids = getJdbcTemplate().query(
                "SELECT ID_Client FROM Clients WHERE Phone = ?",
                (rs, rowNum) -> rs.getInt("ID_Client"),
                phone
        );
        return ids.stream().findFirst().orElse(null);
    }

    /**
     * Register visit via sp_register_visit.
     */
    public CheckInResult registerVisit(Integer clientId, Integer hallId) {
        String sql = "SELECT out_visit_id, out_client_id, out_client_name, out_hall_name, out_sub_status " +
                     "FROM sp_register_visit(?, ?)";

        return getJdbcTemplate().queryForObject(sql, (rs, rowNum) -> new CheckInResult(
                rs.getInt("out_visit_id"),
                rs.getInt("out_client_id"),
                rs.getString("out_client_name"),
                rs.getString("out_hall_name"),
                LocalDateTime.now(),
                rs.getString("out_sub_status")
        ), clientId, hallId);
    }

    /**
     * Book group class via sp_book_group_class.
     */
    public void callBookGroupClass(Integer instanceId, Integer clientId, String promoCode) {
        getJdbcTemplate().update("CALL sp_book_group_class(?, NULL, ?, ?)", instanceId, clientId, promoCode);
    }

    /**
     * Book personal training via sp_book_personal_training.
     */
    public Integer callBookPersonalTraining(Integer clientId, Integer coachId, Integer hallId, LocalDateTime dateTime, String promoCode, Integer managerId, Integer itemId) {
        return getJdbcTemplate().queryForObject(
                "SELECT personal_id FROM sp_book_personal_training(?, ?, ?, ?, ?, ?, ?)",
                Integer.class,
                clientId,
                coachId,
                hallId,
                dateTime,
                promoCode,
                managerId,
                itemId
        );
    }

    public record SubscriptionFreezeTarget(int clientSubId, int remainingFreezingDays, LocalDate endDate) {}

    /**
     * Find active subscription for freezing by sub ID or client ID.
     */
    public SubscriptionFreezeTarget findSubscriptionForFreeze(Integer clientSubId) {
        List<SubscriptionFreezeTarget> rows = getJdbcTemplate().query(
                "SELECT cs.ID_ClientSub, cs.RemainingFreezingDays, cs.EndDate FROM ClientSubscriptions cs " +
                "JOIN Sales s ON cs.ID_Sale = s.ID_Sale " +
                "WHERE cs.ID_ClientSub = ? OR (s.ID_Client = ? AND cs.CurrentStatus = 'Active') " +
                "ORDER BY (cs.ID_ClientSub = ?) DESC, cs.EndDate DESC LIMIT 1 FOR UPDATE OF cs",
                (rs, rowNum) -> new SubscriptionFreezeTarget(
                        rs.getInt("ID_ClientSub"),
                        rs.getInt("RemainingFreezingDays"),
                        rs.getDate("EndDate").toLocalDate()
                ),
                clientSubId, clientSubId, clientSubId
        );
        return rows.stream().findFirst().orElse(null);
    }

    /**
     * Log subscription freezing into FreezingLogs.
     */
    public void insertFreezingLog(Integer clientSubId, LocalDate startDate, LocalDate endDate, String reason) {
        getJdbcTemplate().update(
                "INSERT INTO FreezingLogs (ID_ClientSub, FreezeStartDate, FreezeEndDate, Reason) VALUES (?, ?, ?, ?)",
                clientSubId, startDate, endDate, reason
        );
    }

    /**
     * Update ClientSubscriptions with extended end date and deducted freezing days.
     */
    public void applySubscriptionFreeze(Integer clientSubId, LocalDate newEndDate, long freezeDays) {
        getJdbcTemplate().update(
                "UPDATE ClientSubscriptions SET EndDate = ?, RemainingFreezingDays = RemainingFreezingDays - ?, CurrentStatus = 'Frozen' WHERE ID_ClientSub = ?",
                newEndDate, freezeDays, clientSubId
        );
    }

    /**
     * Cancel personal training.
     */
    public void cancelPersonalTraining(Integer bookingId, String reason, String initiator) {
        getJdbcTemplate().update("UPDATE PersonalTrainings SET TrainingStatus = 'Cancelled' WHERE ID_Personal = ?", bookingId);
        getJdbcTemplate().update(
                "INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp, Status) VALUES (?, 'Cancel', ?, ?, CURRENT_TIMESTAMP, 'Approved')",
                bookingId, reason, initiator
        );
    }

    /**
     * Get coach ID and training time for personal training.
     */
    public record PersonalTrainingDetails(Integer coachId, LocalDateTime trainingDateTime) {}

    public PersonalTrainingDetails getPersonalTrainingDetails(Integer personalId) {
        List<PersonalTrainingDetails> list = getJdbcTemplate().query(
                "SELECT ID_Coach, TrainingDateTime FROM PersonalTrainings WHERE ID_Personal = ?",
                (rs, rowNum) -> new PersonalTrainingDetails(
                        rs.getInt("ID_Coach"),
                        rs.getTimestamp("TrainingDateTime").toLocalDateTime()
                ),
                personalId
        );
        return list.stream().findFirst().orElse(null);
    }

    /**
     * Check if coach has conflicting scheduled personal training.
     */
    public boolean hasCoachConflict(Integer coachId, LocalDateTime dateTime, Integer excludePersonalId) {
        String sql = """
            SELECT COUNT(*) FROM PersonalTrainings 
            WHERE ID_Coach = ? 
              AND TrainingDateTime = ? 
              AND TrainingStatus = 'Scheduled'
              AND ID_Personal != ?
            """;
        Integer conflicts = getJdbcTemplate().queryForObject(sql, Integer.class, coachId, dateTime, excludePersonalId);
        return conflicts != null && conflicts > 0;
    }

    /**
     * Reschedule personal training with audit changelog.
     */
    public void reschedulePersonalTraining(Integer bookingId, LocalDateTime oldTime, LocalDateTime newDateTime, String reason, String initiator) {
        getJdbcTemplate().update("UPDATE PersonalTrainings SET TrainingDateTime = ? WHERE ID_Personal = ?", newDateTime, bookingId);

        Integer logId = getJdbcTemplate().queryForObject(
                "INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp, Status) VALUES (?, 'Reschedule', ?, ?, CURRENT_TIMESTAMP, 'Approved') RETURNING ID_PTLog",
                Integer.class, bookingId, reason, initiator
        );

        getJdbcTemplate().update(
                "INSERT INTO PT_TimeChangeDetails (ID_PTLog, OldDateTime, NewDateTime) VALUES (?, ?, ?)",
                logId, oldTime, newDateTime
        );
    }

    /**
     * Cancel group class booking and adjust actual attendance.
     */
    public void cancelGroupClassBooking(Integer bookingId) {
        List<Integer> instanceIds = getJdbcTemplate().query(
                "SELECT ID_Instance FROM GroupClassBookings WHERE ID_Booking = ?",
                (rs, rowNum) -> rs.getInt("ID_Instance"),
                bookingId
        );
        Integer instanceId = instanceIds.stream().findFirst().orElse(null);

        getJdbcTemplate().update("UPDATE GroupClassBookings SET BookingStatus = 'Cancelled' WHERE ID_Booking = ?", bookingId);
        if (instanceId != null) {
            getJdbcTemplate().update("UPDATE GroupClassInstances SET ActualAttendance = GREATEST(ActualAttendance - 1, 0) WHERE ID_Instance = ?", instanceId);
        }
    }

    /**
     * Reschedule group class instance linked to booking or directly.
     */
    public void rescheduleGroupClassInstance(Integer bookingId, LocalDate newDate, LocalTime newTime) {
        List<Integer> instanceIds = getJdbcTemplate().query(
                "SELECT ID_Instance FROM GroupClassBookings WHERE ID_Booking = ?",
                (rs, rowNum) -> rs.getInt(1),
                bookingId
        );
        Integer targetInstanceId = instanceIds.stream().findFirst().orElse(bookingId);

        getJdbcTemplate().update(
                "UPDATE GroupClassInstances SET ClassDate = ?, ClassStartTime = ? WHERE ID_Instance = ?",
                newDate, newTime, targetInstanceId
        );
    }

    /**
     * Get start time from template.
     */
    public LocalTime getTemplateStartTime(Integer templateId) {
        return getJdbcTemplate().queryForObject(
                "SELECT StartTime FROM GroupScheduleTemplates WHERE ID_Template = ?",
                LocalTime.class,
                templateId
        );
    }

    /**
     * Insert scheduled group class instance.
     */
    public Integer insertGroupClassInstance(Integer templateId, LocalDate classDate, LocalTime startTime) {
        return getJdbcTemplate().queryForObject(
                "INSERT INTO GroupClassInstances (ID_Template, ClassDate, ClassStatus, ActualAttendance, ClassStartTime) VALUES (?, ?, 'Scheduled', 0, ?) RETURNING ID_Instance",
                Integer.class,
                templateId,
                classDate,
                startTime
        );
    }

    /**
     * Get pending and recent schedule change requests from coaches.
     */
    public List<ScheduleChangeRequestDto> getScheduleRequests() {
        String sql = "SELECT * FROM v_ScheduleChangeRequests ORDER BY ChangeTimestamp DESC";

        return getJdbcTemplate().query(sql, (rs, rowNum) -> new ScheduleChangeRequestDto(
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

    public record PTChangeLogRecord(Integer logId, Integer personalId, String requestType, String status) {}

    /**
     * Find changelog record by log ID.
     */
    public PTChangeLogRecord findPTChangeLog(Integer logId) {
        List<PTChangeLogRecord> rows = getJdbcTemplate().query(
                "SELECT ID_PTLog, ID_Personal, RequestType, Status FROM PT_Changelog WHERE ID_PTLog = ?",
                (rs, rowNum) -> new PTChangeLogRecord(
                        rs.getInt("ID_PTLog"),
                        rs.getInt("ID_Personal"),
                        rs.getString("RequestType"),
                        rs.getString("Status")
                ),
                logId
        );
        return rows.stream().findFirst().orElse(null);
    }

    /**
     * Find proposed new date time for change log.
     */
    public LocalDateTime findProposedDateTime(Integer logId) {
        List<LocalDateTime> timeRows = getJdbcTemplate().query(
                "SELECT NewDateTime FROM PT_TimeChangeDetails WHERE ID_PTLog = ?",
                (rs, rowNum) -> rs.getTimestamp("NewDateTime") != null ? rs.getTimestamp("NewDateTime").toLocalDateTime() : null,
                logId
        );
        return timeRows.stream().filter(java.util.Objects::nonNull).findFirst().orElse(null);
    }

    /**
     * Update personal training date time.
     */
    public void updatePersonalTrainingDateTime(Integer personalId, LocalDateTime dateTime) {
        getJdbcTemplate().update("UPDATE PersonalTrainings SET TrainingDateTime = ? WHERE ID_Personal = ?", dateTime, personalId);
    }

    /**
     * Update personal training status.
     */
    public void updatePersonalTrainingStatus(Integer personalId, String status) {
        getJdbcTemplate().update("UPDATE PersonalTrainings SET TrainingStatus = ? WHERE ID_Personal = ?", status, personalId);
    }

    /**
     * Update changelog status.
     */
    public void updatePTChangeLogStatus(Integer logId, String status) {
        getJdbcTemplate().update("UPDATE PT_Changelog SET Status = ? WHERE ID_PTLog = ?", status, logId);
    }

    /**
     * Reject pending changelog request.
     * Returns number of updated rows.
     */
    public int rejectPendingChangeLog(Integer logId) {
        return getJdbcTemplate().update("UPDATE PT_Changelog SET Status = 'Rejected' WHERE ID_PTLog = ? AND Status = 'Pending'", logId);
    }

    /**
     * Find changelog status by log ID.
     */
    public String findPTChangeLogStatus(Integer logId) {
        List<String> exists = getJdbcTemplate().query("SELECT Status FROM PT_Changelog WHERE ID_PTLog = ?", (rs, rowNum) -> rs.getString("Status"), logId);
        return exists.stream().findFirst().orElse(null);
    }
}
