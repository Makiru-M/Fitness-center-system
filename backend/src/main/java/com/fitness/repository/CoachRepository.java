package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.dto.coach.*;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class CoachRepository {

    private final DynamicDataSourceService dataSourceService;

    public CoachRepository(DynamicDataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    /**
     * C1: View own schedule (Group classes + Personal trainings)
     */
    public List<CoachScheduleItem> getMySchedule() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT 
                activity_id AS ActivityId,
                activity_type AS ActivityType,
                title AS Title,
                hall_name AS HallName,
                schedule_date AS ScheduleDate,
                start_time AS StartTime,
                start_date_time AS StartDateTime,
                duration_minutes AS DurationMinutes,
                status AS Status,
                attendance_or_capacity AS AttendanceOrCapacity
            FROM v_CoachWeeklySchedule
            WHERE db_user = SESSION_USER
            ORDER BY start_date_time ASC
            """;

        return jdbc.query(sql, (rs, rowNum) -> new CoachScheduleItem(
                rs.getInt("ActivityId"),
                rs.getString("ActivityType"),
                rs.getString("Title"),
                rs.getString("HallName"),
                rs.getDate("ScheduleDate").toLocalDate(),
                rs.getTime("StartTime") != null ? rs.getTime("StartTime").toLocalTime() : null,
                rs.getTimestamp("StartDateTime").toLocalDateTime(),
                rs.getInt("DurationMinutes"),
                rs.getString("Status"),
                rs.getInt("AttendanceOrCapacity")
        ));
    }

    /**
     * C2: Get participant clients for a group class
     */
    public List<ClassParticipantDto> getGroupClassParticipants(Integer instanceId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT c.ID_Client, c.FullName, c.Phone, gcb.BookingStatus::TEXT, COALESCE(mn.NotesText, 'Немає обмежень') AS NotesText
            FROM GroupClassBookings gcb
            JOIN Sales s ON gcb.ID_Sale = s.ID_Sale
            JOIN Clients c ON s.ID_Client = c.ID_Client
            LEFT JOIN MedicalNotes mn ON c.ID_Client = mn.ID_Client
            WHERE gcb.ID_Instance = ?
            """;

        return jdbc.query(sql, (rs, rowNum) -> new ClassParticipantDto(
                rs.getInt("ID_Client"),
                rs.getString("FullName"),
                rs.getString("Phone"),
                rs.getString("BookingStatus"),
                rs.getString("NotesText")
        ), instanceId);
    }

    /**
     * C2: Get client details for a personal training
     */
    public List<ClassParticipantDto> getPersonalTrainingClient(Integer personalId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT c.ID_Client, c.FullName, c.Phone, pt.TrainingStatus::TEXT, COALESCE(mn.NotesText, 'Немає обмежень') AS NotesText
            FROM PersonalTrainings pt
            JOIN Sales s ON pt.ID_Sale = s.ID_Sale
            JOIN Clients c ON s.ID_Client = c.ID_Client
            LEFT JOIN MedicalNotes mn ON c.ID_Client = mn.ID_Client
            WHERE pt.ID_Personal = ?
            """;

        return jdbc.query(sql, (rs, rowNum) -> new ClassParticipantDto(
                rs.getInt("ID_Client"),
                rs.getString("FullName"),
                rs.getString("Phone"),
                rs.getString("TrainingStatus"),
                rs.getString("NotesText")
        ), personalId);
    }

    /**
     * C3: Update personal training status.
     * Returns number of updated rows.
     */
    public int updatePersonalTraining(Integer personalId, String status, boolean isCompletion) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            UPDATE PersonalTrainings
            SET TrainingStatus = ?::activity_status
            WHERE ID_Personal = ?
              AND (? = false OR (TrainingDateTime + INTERVAL '60 minutes') <= CURRENT_TIMESTAMP)
            """;

        return jdbc.update(sql, status, personalId, isCompletion);
    }

    /**
     * Find personal training end time.
     */
    public Optional<LocalDateTime> findPersonalTrainingEndTime(Integer personalId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT (TrainingDateTime + INTERVAL '60 minutes') AS EndDateTime FROM PersonalTrainings WHERE ID_Personal = ?";
        try {
            LocalDateTime endTime = jdbc.queryForObject(sql, LocalDateTime.class, personalId);
            return Optional.ofNullable(endTime);
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    /**
     * C4: Update group class status and attendance.
     * Returns number of updated rows.
     */
    public int updateGroupClass(Integer instanceId, String status, int attendance, boolean isCompletion) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            UPDATE GroupClassInstances gci
            SET ClassStatus = ?::activity_status, ActualAttendance = ?
            FROM GroupScheduleTemplates gst
            WHERE gci.ID_Template = gst.ID_Template
              AND gci.ID_Instance = ?
              AND (? = false OR (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute')) <= CURRENT_TIMESTAMP)
            """;

        return jdbc.update(sql, status, attendance, instanceId, isCompletion);
    }

    /**
     * Find group class end time.
     */
    public Optional<LocalDateTime> findGroupClassEndTime(Integer instanceId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute')) AS EndDateTime
            FROM GroupClassInstances gci
            JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
            WHERE gci.ID_Instance = ?
            """;
        try {
            LocalDateTime endTime = jdbc.queryForObject(sql, LocalDateTime.class, instanceId);
            return Optional.ofNullable(endTime);
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    /**
     * C5: Insert record into PT_Changelog.
     */
    public Integer insertChangeLog(Integer personalId, String requestType, String reason) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        return jdbc.queryForObject(
                "INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp, Status) VALUES (?, ?, ?, 'Coach', CURRENT_TIMESTAMP, 'Pending') RETURNING ID_PTLog",
                Integer.class, personalId, requestType, reason
        );
    }

    /**
     * Get personal training scheduled start time.
     */
    public Optional<LocalDateTime> findPersonalTrainingStartTime(Integer personalId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        try {
            LocalDateTime startTime = jdbc.queryForObject(
                    "SELECT TrainingDateTime FROM PersonalTrainings WHERE ID_Personal = ?",
                    LocalDateTime.class, personalId
            );
            return Optional.ofNullable(startTime);
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    /**
     * Insert details into PT_TimeChangeDetails.
     */
    public void insertTimeChangeDetails(Integer logId, LocalDateTime oldDateTime, LocalDateTime newDateTime) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        jdbc.update(
                "INSERT INTO PT_TimeChangeDetails (ID_PTLog, OldDateTime, NewDateTime) VALUES (?, ?, ?)",
                logId, oldDateTime, newDateTime
        );
    }
}
