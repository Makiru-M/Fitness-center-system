package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.model.HrDto.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
@Transactional
public class HrRepository {

    private final DynamicDataSourceService dataSourceService;

    public HrRepository(DynamicDataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    /**
     * HR1: Hire coach via stored function sp_hire_coach
     */
    public Integer hireCoach(HireCoachRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT staff_id, coach_id FROM sp_hire_coach(?, ?, ?, ?, ?, ?, ?)";

        List<Integer> list = jdbc.query(sql, (rs, rowNum) -> rs.getInt("coach_id"),
                req.fullName(),
                req.birthDate(),
                req.phone(),
                req.specId(),
                req.dbUser(),
                req.password(),
                req.biography()
        );

        return list.isEmpty() ? null : list.get(0);
    }

    /**
     * HR2: Update coach details
     */
    public void updateCoach(UpdateCoachRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        String updateStaff = """
            UPDATE Staff
            SET FullName = ?, BirthDate = ?, Phone = ?
            WHERE ID_Staff = (SELECT ID_Staff FROM Coaches WHERE ID_Coach = ?)
            """;
        jdbc.update(updateStaff, req.fullName(), req.birthDate(), req.phone(), req.coachId());

        String updateCoach = """
            UPDATE Coaches
            SET ID_Spec = ?, Biography = ?
            WHERE ID_Coach = ?
            """;
        jdbc.update(updateCoach, req.specId(), req.biography(), req.coachId());
    }

    /**
     * HR3 & HR6: Fire employee via stored function sp_fire_employee
     */
    public void fireEmployee(FireEmployeeRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        jdbc.query("SELECT sp_fire_employee(?, ?)", (rs, rowNum) -> null, req.staffId(), req.fireDate());
    }

    /**
     * HR4: Hire manager via stored function sp_hire_manager
     */
    public Integer hireManager(HireManagerRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT staff_id FROM sp_hire_manager(?, ?, ?, ?, ?, ?, ?)";

        List<Integer> list = jdbc.query(sql, (rs, rowNum) -> rs.getInt("staff_id"),
                req.fullName(),
                req.birthDate(),
                req.phone(),
                req.dbUser(),
                req.password(),
                req.positionName() != null ? req.positionName() : "Адміністратор",
                req.hireDate()
        );

        return list.isEmpty() ? null : list.get(0);
    }

    /**
     * HR5: Update manager details
     */
    public void updateManager(UpdateManagerRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();

        String sql = """
            UPDATE Staff
            SET FullName = ?, BirthDate = ?, Phone = ?, ID_Position = ?
            WHERE ID_Staff = ?
            """;
        jdbc.update(sql, req.fullName(), req.birthDate(), req.phone(), req.positionId(), req.staffId());
    }

    /**
     * List all staff and coaches
     */
    public List<EmployeeDto> getAllStaff() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT 
                s.ID_Staff,
                c.ID_Coach,
                s.FullName,
                s.BirthDate,
                s.Phone,
                p.PositionName,
                s.DB_User,
                s.HireDate,
                s.FireDate,
                sp.SpecName,
                c.Biography,
                (c.ID_Coach IS NOT NULL) AS IsCoach,
                (s.FireDate IS NULL) AS IsActive
            FROM Staff s
            JOIN Positions p ON s.ID_Position = p.ID_Position
            LEFT JOIN Coaches c ON s.ID_Staff = c.ID_Staff
            LEFT JOIN Specializations sp ON c.ID_Spec = sp.ID_Spec
            ORDER BY s.FireDate NULLS FIRST, s.ID_Staff
            """;

        return jdbc.query(sql, (rs, rowNum) -> new EmployeeDto(
                rs.getInt("ID_Staff"),
                (Integer) rs.getObject("ID_Coach"),
                rs.getString("FullName"),
                rs.getDate("BirthDate").toLocalDate(),
                rs.getString("Phone"),
                rs.getString("PositionName"),
                rs.getString("DB_User"),
                rs.getDate("HireDate").toLocalDate(),
                rs.getDate("FireDate") != null ? rs.getDate("FireDate").toLocalDate() : null,
                rs.getString("SpecName"),
                rs.getString("Biography"),
                rs.getBoolean("IsCoach"),
                rs.getBoolean("IsActive")
        ));
    }
}
