package com.fitness.repository;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.dto.guest.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class GuestRepository {

    private final DynamicDataSourceService dataSourceService;

    public GuestRepository(DynamicDataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    /**
     * G1: Register client via PL/pgSQL function sp_register_client
     */
    public ClientRegistrationResponse registerClient(ClientRegistrationRequest req) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = """
            SELECT * FROM sp_register_client(
                ?, ?, ?, ?, ?, ?, ?, ?, ?
            )
            """;

        return jdbc.queryForObject(sql, (rs, rowNum) -> new ClientRegistrationResponse(
                rs.getInt("client_id"),
                rs.getString("db_username"),
                rs.getInt("sale_id"),
                (Integer) rs.getObject("subscription_id"),
                rs.getBigDecimal("final_price"),
                rs.getDate("end_date") != null ? rs.getDate("end_date").toLocalDate() : null
        ),
                req.fullName(),
                req.birthDate(),
                req.phone(),
                req.gender(),
                req.dbUser(),
                req.password(),
                req.itemId(),
                req.promoCode(),
                req.medicalNotes()
        );
    }

    /**
     * G2: View coaches with popularity and specializations
     */
    public List<CoachPublicDto> getCoaches(Integer specializationId) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        StringBuilder sql = new StringBuilder("SELECT * FROM v_PublicCoaches WHERE 1=1 ");
        List<Object> params = new java.util.ArrayList<>();
        if (specializationId != null) {
            sql.append(" AND ID_Spec = ? ");
            params.add(specializationId);
        }
        sql.append(" ORDER BY FullName ASC");
        return jdbc.query(sql.toString(), (rs, rowNum) -> new CoachPublicDto(
                rs.getInt("ID_Coach"),
                rs.getString("FullName"),
                rs.getString("SpecName"),
                rs.getString("Biography"),
                rs.getInt("GroupClassesCount"),
                rs.getDouble("AvgGroupSize"),
                rs.getInt("IndividualClientsCount")
        ), params.toArray());
    }
    /**
     * G3: View Price List (Active items only for public guests)
     */
    public List<PriceListItemDto> getPriceList() {
        return getPriceList(false);
    }

    /**
     * G3 / D10: View Price List with optional archived items
     */
    public List<PriceListItemDto> getPriceList(boolean includeArchived) {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        StringBuilder sql = new StringBuilder("""
            SELECT 
                pl.ID_Item,
                pl.ItemName,
                pl.Category,
                pl.Price,
                pls.DurationDays,
                pls.MaxFreezingDays,
                pl.Description,
                pl.PriceStartDate,
                pl.PriceEndDate
            FROM PriceList pl
            LEFT JOIN PriceListSubs pls ON pl.ID_Item = pls.ID_Item
            """);

        if (!includeArchived) {
            sql.append(" WHERE pl.PriceEndDate IS NULL ");
            sql.append(" ORDER BY pl.Category, pl.Price");
        } else {
            sql.append(" ORDER BY pl.PriceEndDate NULLS FIRST, pl.Category, pl.Price");
        }

        return jdbc.query(sql.toString(), (rs, rowNum) -> {
            java.sql.Date startDate = rs.getDate("PriceStartDate");
            java.sql.Date endDate = rs.getDate("PriceEndDate");
            return new PriceListItemDto(
                    rs.getInt("ID_Item"),
                    rs.getString("ItemName"),
                    rs.getString("Category"),
                    rs.getBigDecimal("Price"),
                    (Integer) rs.getObject("DurationDays"),
                    (Integer) rs.getObject("MaxFreezingDays"),
                    rs.getString("Description"),
                    startDate != null ? startDate.toLocalDate() : null,
                    endDate != null ? endDate.toLocalDate() : null,
                    endDate == null
            );
        });
    }

    /**
     * G4: View Halls
     */
    public List<HallDto> getHalls() {
        JdbcTemplate jdbc = dataSourceService.getJdbcTemplate();
        String sql = "SELECT ID_Hall, HallName, MaxCapacity FROM Halls WHERE IsActive IS NULL OR IsActive = TRUE ORDER BY MaxCapacity DESC";

        return jdbc.query(sql, (rs, rowNum) -> new HallDto(
                rs.getInt("ID_Hall"),
                rs.getString("HallName"),
                rs.getInt("MaxCapacity")
        ));
    }
}
