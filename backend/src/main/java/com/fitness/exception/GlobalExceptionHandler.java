package com.fitness.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(AuthenticationRequiredException.class)
    public ResponseEntity<Map<String, Object>> handleAuthenticationRequired(AuthenticationRequiredException ex) {
        log.warn("Authentication failed: {}", ex.getMessage());
        return buildResponse(HttpStatus.UNAUTHORIZED, "Unauthorized", ex.getMessage());
    }

    @ExceptionHandler(ForbiddenOperationException.class)
    public ResponseEntity<Map<String, Object>> handleForbidden(ForbiddenOperationException ex) {
        log.warn("Forbidden operation: {}", ex.getMessage());
        return buildResponse(HttpStatus.FORBIDDEN, "Forbidden", ex.getMessage());
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFound(ResourceNotFoundException ex) {
        log.info("Not found: {}", ex.getMessage());
        return buildResponse(HttpStatus.NOT_FOUND, "Not Found", ex.getMessage());
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNoResourceFound(NoResourceFoundException ex) {
        log.debug("Resource not found: {}", ex.getResourcePath());
        return buildResponse(HttpStatus.NOT_FOUND, "Not Found", "Статичний ресурс або ендпоінт не знайдено: " + ex.getResourcePath());
    }

    @ExceptionHandler(BusinessLogicException.class)
    public ResponseEntity<Map<String, Object>> handleBusinessLogic(BusinessLogicException ex) {
        log.info("Business rule violation: {}", ex.getMessage());
        return buildResponse(HttpStatus.BAD_REQUEST, "Bad Request", ex.getMessage());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex) {
        log.info("Invalid argument / business rule violation: {}", ex.getMessage());
        return buildResponse(HttpStatus.BAD_REQUEST, "Bad Request", ex.getMessage());
    }

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<Map<String, Object>> handleDataAccessException(DataAccessException ex) {
        Throwable root = ex.getMostSpecificCause();
        String message = root.getMessage();
        log.error("Database error occurred: {}", message, ex);

        // Check for specific PostgreSQL SQLStates
        if (message.contains("password authentication failed") || message.contains("28P01")) {
            return buildResponse(HttpStatus.UNAUTHORIZED, "Unauthorized", "Невірний логін або пароль облікового запису PostgreSQL.");
        }
        if (message.contains("permission denied") || message.contains("42501")) {
            return buildResponse(HttpStatus.FORBIDDEN, "Forbidden", "Доступ заборонено: відсутні привілеї на рівні PostgreSQL для цієї операції.");
        }
        if (message.contains("unique constraint") || message.contains("23505")) {
            if (message.contains("uq_coach_active_slot")) {
                return buildResponse(HttpStatus.CONFLICT, "Conflict", "Цей тренер уже має призначене тренування на обраний час!");
            }
            return buildResponse(HttpStatus.CONFLICT, "Conflict", "Порушення унікальності даних: такий запис вже існує (" + extractConstraintDetail(message) + ").");
        }
        if (message.contains("[SCHEDULE_CONFLICT]")) {
            String cleanMsg = cleanPgMessage(message).replace("[SCHEDULE_CONFLICT]", "").trim();
            return buildResponse(HttpStatus.CONFLICT, "Schedule Conflict", cleanMsg);
        }
        if (message.contains("Конфлікт розкладу") || message.contains("конфлікт розкладу")
                || message.contains("check_coach_schedule_conflict")) {
            return buildResponse(HttpStatus.CONFLICT, "Schedule Conflict", cleanPgMessage(message));
        }
        if (message.contains("check constraint") || message.contains("23514")) {
            return buildResponse(HttpStatus.BAD_REQUEST, "Check Constraint Violation", "Порушення перевірки обмеження цілісності: " + extractConstraintDetail(message));
        }
        if (message.contains("foreign key constraint") || message.contains("23503")) {
            return buildResponse(HttpStatus.BAD_REQUEST, "Foreign Key Violation", "Пов'язаний запис не знайдено або він використовується в інших таблицях.");
        }

        // Generic DB exception (e.g. RAISE EXCEPTION from stored function)
        return buildResponse(HttpStatus.BAD_REQUEST, "Database Error", cleanPgMessage(message));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGeneralException(Exception ex) {
        log.error("Unhandled server exception: {}", ex.getMessage(), ex);
        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, "Internal Server Error", ex.getMessage());
    }

    private ResponseEntity<Map<String, Object>> buildResponse(HttpStatus status, String error, String message) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", LocalDateTime.now());
        body.put("status", status.value());
        body.put("error", error);
        body.put("message", message);
        return ResponseEntity.status(status)
                .header("Content-Type", "application/json;charset=UTF-8")
                .body(body);
    }

    private String cleanPgMessage(String raw) {
        if (raw == null) return "Невідома помилка БД";
        String msg = raw.trim();

        int errIdx = msg.indexOf("ERROR:");
        if (errIdx != -1) {
            msg = msg.substring(errIdx + 6).trim();
        }

        // Strip PostgreSQL diagnostic/context markers (Ukrainian, Russian, English)
        String[] markers = {
                "\n  Where:", "\n  Де:", "\n  Где:", "\n  CONTEXT:", "\n  Hint:", "\n  Підказка:",
                "\nWhere:", "\nДе:", "\nГде:", "\nCONTEXT:", "\nHint:", "\nПідказка:",
                "Where:", "Де:", "Где:", "CONTEXT:"
        };
        for (String marker : markers) {
            int idx = msg.indexOf(marker);
            if (idx != -1) {
                msg = msg.substring(0, idx).trim();
            }
        }

        // If there's any remaining newline before stack trace, strip it
        int nlIdx = msg.indexOf('\n');
        if (nlIdx != -1) {
            msg = msg.substring(0, nlIdx).trim();
        }

        return msg.trim();
    }

    private String extractConstraintDetail(String msg) {
        int detailIdx = msg.indexOf("Detail:");
        if (detailIdx != -1) {
            return msg.substring(detailIdx).trim();
        }
        return msg;
    }
}
