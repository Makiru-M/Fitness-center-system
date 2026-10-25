package com.fitness.controller;

import com.fitness.model.HrDto.*;
import com.fitness.repository.HrRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/hr")
public class HrController {

    private final HrRepository hrRepository;

    public HrController(HrRepository hrRepository) {
        this.hrRepository = hrRepository;
    }

    /**
     * HR1: Hire coach (calls stored function sp_hire_coach)
     */
    @PostMapping("/coaches")
    public ResponseEntity<Map<String, Object>> hireCoach(@RequestBody HireCoachRequest req) {
        if (req.dbUser() == null || req.dbUser().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "status", 400,
                    "error", "Bad Request",
                    "message", "Логін облікового запису обов'язковий!"
            ));
        }
        if (req.password() == null || req.password().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "status", 400,
                    "error", "Bad Request",
                    "message", "Пароль облікового запису обов'язковий!"
            ));
        }
        Integer coachId = hrRepository.hireCoach(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "coachId", coachId,
                "message", "Тренера успішно прийнято на роботу та створено обліковий запис у PostgreSQL."
        ));
    }

    /**
     * HR2: Update coach details
     */
    @PutMapping("/coaches")
    public ResponseEntity<Map<String, String>> updateCoach(@RequestBody UpdateCoachRequest req) {
        hrRepository.updateCoach(req);
        return ResponseEntity.ok(Map.of("message", "Дані тренера успішно оновлено."));
    }

    /**
     * HR3 & HR6: Fire employee (calls stored function sp_fire_employee)
     */
    @PostMapping("/employees/fire")
    public ResponseEntity<Map<String, String>> fireEmployee(@RequestBody FireEmployeeRequest req) {
        hrRepository.fireEmployee(req);
        return ResponseEntity.ok(Map.of("message", "Працівника успішно звільнено та заблоковано вхід до системи."));
    }

    /**
     * HR4: Hire manager (calls stored function sp_hire_manager)
     */
    @PostMapping("/managers")
    public ResponseEntity<Map<String, Object>> hireManager(@RequestBody HireManagerRequest req) {
        if (req.dbUser() == null || req.dbUser().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "status", 400,
                    "error", "Bad Request",
                    "message", "Логін облікового запису обов'язковий!"
            ));
        }
        if (req.password() == null || req.password().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "status", 400,
                    "error", "Bad Request",
                    "message", "Пароль облікового запису обов'язковий!"
            ));
        }
        Integer staffId = hrRepository.hireManager(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "staffId", staffId,
                "message", "Менеджера успішно прийнято на роботу."
        ));
    }

    /**
     * HR5: Update manager details
     */
    @PutMapping("/managers")
    public ResponseEntity<Map<String, String>> updateManager(@RequestBody UpdateManagerRequest req) {
        hrRepository.updateManager(req);
        return ResponseEntity.ok(Map.of("message", "Дані менеджера успішно оновлено."));
    }

    /**
     * List all staff members
     */
    @GetMapping("/employees")
    public ResponseEntity<List<EmployeeDto>> getAllEmployees() {
        return ResponseEntity.ok(hrRepository.getAllStaff());
    }
}
