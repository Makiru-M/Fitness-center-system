package com.fitness.service;

import com.fitness.config.DynamicDataSourceService;
import com.fitness.dto.hr.*;
import com.fitness.exception.BusinessLogicException;
import com.fitness.repository.AuthRepository;
import com.fitness.repository.HrRepository;
import com.fitness.security.SessionRegistry;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class HrService {

    private final HrRepository hrRepository;
    private final SessionRegistry sessionRegistry;
    private final DynamicDataSourceService dataSourceService;
    private final AuthRepository authRepository;

    public HrService(HrRepository hrRepository,
                     SessionRegistry sessionRegistry,
                     DynamicDataSourceService dataSourceService,
                     AuthRepository authRepository) {
        this.hrRepository = hrRepository;
        this.sessionRegistry = sessionRegistry;
        this.dataSourceService = dataSourceService;
        this.authRepository = authRepository;
    }

    /**
     * HR1: Hire coach via stored function sp_hire_coach
     */
    public Integer hireCoach(HireCoachRequest request) {
        return hrRepository.hireCoach(request);
    }

    /**
     * HR2: Update coach details
     */
    public void updateCoach(UpdateCoachRequest request) {
        hrRepository.updateCoach(request);
    }

    /**
     * HR3 & HR6: Fire employee via stored function sp_fire_employee,
     * with self-firing check, session invalidation and connection pool eviction.
     */
    public void fireEmployee(FireEmployeeRequest request) {
        if (request == null || request.staffId() == null) {
            throw new BusinessLogicException("Ідентифікатор співробітника обов'язковий.");
        }

        String dbUser = hrRepository.findDbUserByStaffId(request.staffId()).orElse(null);

        if (dbUser != null) {
            String currentSessionUser = authRepository.getCurrentSessionUser();
            if (dbUser.equalsIgnoreCase(currentSessionUser)) {
                throw new BusinessLogicException("Співробітник не може звільнити сам себе.");
            }
        }

        hrRepository.fireEmployee(request);

        if (dbUser != null) {
            sessionRegistry.invalidateUserSessions(dbUser);
            dataSourceService.evictUser(dbUser);
        }
    }

    /**
     * HR4: Hire manager via stored function sp_hire_manager
     */
    public Integer hireManager(HireManagerRequest request) {
        return hrRepository.hireManager(request);
    }

    /**
     * HR5: Update manager details
     */
    public void updateManager(UpdateManagerRequest request) {
        hrRepository.updateManager(request);
    }

    /**
     * List all staff members
     */
    public List<EmployeeDto> getAllEmployees() {
        return hrRepository.getAllStaff();
    }
}
