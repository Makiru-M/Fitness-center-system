package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.exception.BusinessLogicException;
import com.fitness.model.CoachDto.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Repository
@Transactional
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
                gci.ID_Instance AS ActivityId,
                'Group' AS ActivityType,
                ct.TypeName AS Title,
                h.HallName,
                gci.ClassDate AS ScheduleDate,
                gci.ClassStartTime AS StartTime,
                (gci.ClassDate + gci.ClassStartTime)::TIMESTAMP AS StartDateTime,
                gst.DurationMinutes,
                gci.ClassStatus::TEXT AS Status,
                gci.ActualAttendance AS AttendanceOrCapacity
            FROM GroupClassInstances gci
            JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
            JOIN ClassTypes ct ON gst.ID_ClassType = ct.ID_ClassType
            JOIN Halls h ON gst.ID_Hall = h.ID_Hall
            JOIN Coaches c ON gst.ID_Coach = c.ID_Coach
            JOIN Staff s ON c.ID_Staff = s.ID_Staff
            WHERE s.DB_User = SESSION_USER

            UNION ALL

            SELECT 
                pt.ID_Personal AS ActivityId,
                'Personal' AS ActivityType,
                'Персональне: ' || cl.FullName AS Title,
                h.HallName,
                pt.TrainingDateTime::DATE AS ScheduleDate,
                pt.TrainingDateTime::TIME AS StartTime,
                pt.TrainingDateTime AS StartDateTime,
                60 AS DurationMinutes,
                pt.TrainingStatus::TEXT AS Status,
                1 AS AttendanceOrCapacity
            FROM PersonalTrainings pt
            JOIN Halls h ON pt.ID_Hall = h.ID_Hall
            JOIN Coaches c ON pt.ID_Coach = c.ID_Coach
            JOIN Staff s ON c.ID_Staff = s.ID_Staff
            JOIN Sales sl ON pt.ID_Sale = sl.ID_Sale
            JOIN Clients cl ON sl.ID_Client = cl.ID_Client
            WHERE s.DB_User = SESSION_USER
            ORDER BY StartDateTime
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
     * C2: Get participant clients for a group class or personal training
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
     * C3: Mark personal training status (Completed / No-show / Cancelled)
     */
    public void updatePtStatus(Integer personalId, UpdatePtStatusRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String status = req.status();
        boolean isCompletion = "Completed".equalsIgnoreCase(status) || "No-show".equalsIgnoreCase(status);

        String sql = """
            UPDATE PersonalTrainings
            SET TrainingStatus = ?::activity_status
            WHERE ID_Personal = ?
              AND (? = false OR (TrainingDateTime + INTERVAL '60 minutes') <= CURRENT_TIMESTAMP)
            """;

        int rows = jdbc.update(sql, status, personalId, isCompletion);
        if (rows == 0) {
            var items = jdbc.query(
                    "SELECT TrainingDateTime, (TrainingDateTime + INTERVAL '60 minutes') AS EndDateTime FROM PersonalTrainings WHERE ID_Personal = ?",
                    (rs, rowNum) -> rs.getTimestamp("EndDateTime").toLocalDateTime(),
                    personalId
            );
            if (items.isEmpty()) {
                throw new IllegalArgumentException("Персональне тренування з ID " + personalId + " не знайдено.");
            }
            LocalDateTime endTime = items.get(0);
            throw new IllegalArgumentException("Неможливо відмітити тренування як проведене: заняття ще не завершилося (час закінчення: " + endTime + ").");
        }
    }

    /**
     * C4: Mark group class status and actual attendance
     */
    public void updateGroupAttendance(Integer instanceId, UpdateGroupAttendanceRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String status = req.status();
        int attendance = (req.actualAttendance() != null && req.actualAttendance() >= 0) ? req.actualAttendance() : 0;
        boolean isCompletion = "Completed".equalsIgnoreCase(status) || "No-show".equalsIgnoreCase(status);

        String sql = """
            UPDATE GroupClassInstances gci
            SET ClassStatus = ?::activity_status, ActualAttendance = ?
            FROM GroupScheduleTemplates gst
            WHERE gci.ID_Template = gst.ID_Template
              AND gci.ID_Instance = ?
              AND (? = false OR (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute')) <= CURRENT_TIMESTAMP)
            """;

        int rows = jdbc.update(sql, status, attendance, instanceId, isCompletion);
        if (rows == 0) {
            var items = jdbc.query("""
                SELECT (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute')) AS EndDateTime
                FROM GroupClassInstances gci
                JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
                WHERE gci.ID_Instance = ?
                """,
                    (rs, rowNum) -> rs.getTimestamp("EndDateTime").toLocalDateTime(),
                    instanceId
            );
            if (items.isEmpty()) {
                throw new IllegalArgumentException("Групове заняття з ID " + instanceId + " не знайдено.");
            }
            LocalDateTime endTime = items.get(0);
            throw new IllegalArgumentException("Неможливо відмітити групове заняття як проведене: воно ще не завершилося (час закінчення: " + endTime + ").");
        }
    }

    /**
     * C5: Submit request for reschedule or cancellation
     */
    public void submitChangeRequest(CoachChangeRequest req) {
        if ("Reschedule".equalsIgnoreCase(req.requestType())) {
            if (req.newDateTime() == null || req.newDateTime().isBefore(LocalDateTime.now())) {
                throw new BusinessLogicException("Запропонований час перенесення не може бути в минулому.");
            }
        }

        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        Integer logId = jdbc.queryForObject(
                "INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp, Status) VALUES (?, ?, ?, 'Coach', CURRENT_TIMESTAMP, 'Pending') RETURNING ID_PTLog",
                Integer.class, req.personalId(), req.requestType(), req.reason()
        );

        if ("Reschedule".equalsIgnoreCase(req.requestType()) && req.newDateTime() != null) {
            LocalDateTime oldTime = jdbc.queryForObject(
                    "SELECT TrainingDateTime FROM PersonalTrainings WHERE ID_Personal = ?",
                    LocalDateTime.class, req.personalId()
            );

            jdbc.update(
                    "INSERT INTO PT_TimeChangeDetails (ID_PTLog, OldDateTime, NewDateTime) VALUES (?, ?, ?)",
                    logId, oldTime, req.newDateTime()
            );
        }
    }
}
