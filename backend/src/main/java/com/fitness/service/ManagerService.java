package com.fitness.service;

import com.fitness.dto.client.AvailableGroupClassDto;
import com.fitness.dto.manager.*;
import com.fitness.exception.BusinessLogicException;
import com.fitness.repository.ClientRepository;
import com.fitness.repository.ManagerRepository;
import com.fitness.util.ValidationUtils;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class ManagerService {

    private final ManagerRepository managerRepository;
    private final ClientRepository clientRepository;

    public ManagerService(ManagerRepository managerRepository, ClientRepository clientRepository) {
        this.managerRepository = managerRepository;
        this.clientRepository = clientRepository;
    }

    /**
     * M1: Register client as a new club member
     */
    @Transactional
    public Integer createClient(CreateClientRequest req) {
        if (req.phone() != null && !req.phone().isBlank()) {
            if (!ValidationUtils.isValidPhone(req.phone())) {
                throw new BusinessLogicException("Некоректний формат номера телефону. Очікується формат +380XXXXXXXXX.");
            }
        }

        if (req.dbUser() == null || req.dbUser().isBlank() || req.password() == null || req.password().isBlank()) {
            throw new BusinessLogicException("Логін та пароль є обов'язковими для створення клієнта.");
        }

        String dbUser = req.dbUser().trim();
        String sanitizedUser = dbUser.replaceAll("[^a-zA-Z0-9_]", "");
        if (sanitizedUser.isBlank()) {
            throw new BusinessLogicException("Логін користувача містить неприпустимі символи або є порожнім.");
        }
        String sanitizedPass = req.password().replace("'", "''");

        // Create PostgreSQL user via SECURITY DEFINER function
        try {
            managerRepository.createClientDbUser(sanitizedUser, sanitizedPass);
        } catch (DataAccessException ex) {
            Throwable root = ex.getMostSpecificCause();
            String msg = root != null ? root.getMessage() : ex.getMessage();
            if (msg != null && (msg.contains("вже існує в системі") || msg.contains("вже існує"))) {
                throw new BusinessLogicException(String.format("Користувач з логіном \"%s\" вже існує в системі.", sanitizedUser));
            }
            throw ex;
        }

        Integer clientId;
        try {
            clientId = managerRepository.insertClient(req.fullName(), req.birthDate(), req.phone(), req.gender(), sanitizedUser);
        } catch (DataAccessException ex) {
            Throwable root = ex.getMostSpecificCause();
            String msg = root != null ? root.getMessage() : ex.getMessage();
            if (msg != null && (msg.contains("Clients_db_user_key") || msg.contains("clients_db_user_key") || msg.contains("DB_User"))) {
                throw new BusinessLogicException(String.format("Користувач з логіном \"%s\" вже існує в системі.", sanitizedUser));
            }
            if (msg != null && (msg.contains("Clients_phone_key") || msg.contains("clients_phone_key") || msg.contains("Phone"))) {
                throw new BusinessLogicException(String.format("Клієнт з номером телефону \"%s\" вже зареєстрований.", req.phone()));
            }
            throw ex;
        }

        if (req.medicalNotes() != null && !req.medicalNotes().isBlank()) {
            managerRepository.insertMedicalNotes(clientId, req.medicalNotes());
        }

        return clientId;
    }

    /**
     * M2: Edit client details
     */
    @Transactional
    public void updateClient(UpdateClientRequest req) {
        if (req.phone() != null && !req.phone().isBlank()) {
            if (!ValidationUtils.isValidPhone(req.phone())) {
                throw new BusinessLogicException("Некоректний формат номера телефону. Очікується формат +380XXXXXXXXX.");
            }
        }

        managerRepository.updateClientDetails(req.clientId(), req.fullName(), req.birthDate(), req.phone(), req.gender());

        if (req.medicalNotes() != null) {
            managerRepository.upsertMedicalNotes(req.clientId(), req.medicalNotes());
        }
    }

    /**
     * Search / list clients
     */
    public List<ClientSummaryDto> searchClients(String search) {
        String cleanedSearch = ValidationUtils.cleanToNull(search);
        String searchPattern = cleanedSearch != null ? "%" + cleanedSearch + "%" : null;
        return managerRepository.searchClients(searchPattern);
    }

    /**
     * M3: Sell or extend subscription
     */
    @Transactional
    public Integer sellSubscription(SellSubscriptionRequest req) {
        if (req.startDate() != null && req.startDate().isBefore(LocalDate.now())) {
            throw new BusinessLogicException("Дата початку дії абонемента не може бути в минулому.");
        }

        LocalDate activeEnd = managerRepository.findActiveSubscriptionEndDate(req.clientId());
        if (activeEnd != null) {
            long daysUntilEnd = ChronoUnit.DAYS.between(LocalDate.now(), activeEnd);
            if (daysUntilEnd > 7) {
                throw new BusinessLogicException("Оформити новий абонемент можна не раніше ніж за 7 днів до закінчення діючого (доступно з " + activeEnd.minusDays(7) + ").");
            }
            if (req.startDate() != null && !req.startDate().isAfter(activeEnd)) {
                throw new BusinessLogicException("Дата початку нового абонемента (" + req.startDate() + ") не може перетинатися з діючим абонементом (діє до " + activeEnd + ").");
            }
        }

        Integer managerId = req.managerId();
        if (managerId == null) {
            Integer sessionStaffId = managerRepository.findSessionStaffId();
            managerId = sessionStaffId != null ? sessionStaffId : managerRepository.findDefaultClientManagerId();
        }

        // Validate manager position: only Client Managers can sell subscriptions
        String posName = managerRepository.getStaffPositionName(managerId);
        if (posName == null) {
            throw new BusinessLogicException("Співробітника для оформлення не знайдено.");
        }
        posName = posName.trim();
        String posLower = posName.toLowerCase();

        boolean isDirectorOrHr = posLower.contains("директор") || posLower.contains("hr");
        boolean isClientManager = (posLower.contains("менеджер клієнтів")
                || posLower.contains("менеджер по роботі з клієнтами")
                || posLower.contains("менеджер")) && !isDirectorOrHr;

        if (isDirectorOrHr || !isClientManager) {
            throw new BusinessLogicException("Оформлення продажу дозволено виключно менеджерам по роботі з клієнтами!");
        }

        String promo = ValidationUtils.cleanToNull(req.promoCode());

        return managerRepository.purchaseSubscription(req.clientId(), req.itemId(), promo, managerId, req.startDate());
    }

    /**
     * M4: Check-in client visit
     */
    @Transactional
    public CheckInResult checkInVisit(CheckInRequest req) {
        Integer clientId = req.clientId();
        if (clientId == null && req.phone() != null) {
            clientId = managerRepository.findClientIdByPhone(req.phone());
        }
        if (clientId == null) {
            throw new BusinessLogicException("Клієнта не знайдено.");
        }

        if (req.hallId() == null) {
            throw new BusinessLogicException("Не вказано зал для входу.");
        }

        return managerRepository.registerVisit(clientId, req.hallId());
    }

    /**
     * M5: Book client into group class
     */
    public void bookGroupClass(Integer clientId, Integer instanceId, String promoCode) {
        String promo = ValidationUtils.cleanToNull(promoCode);
        managerRepository.callBookGroupClass(instanceId, clientId, promo);
    }

    /**
     * M6: Book client into personal training
     */
    public Integer bookPersonalTraining(Integer clientId, Integer coachId, Integer hallId, LocalDateTime dateTime, String promoCode, Integer itemId) {
        if (dateTime == null || dateTime.isBefore(LocalDateTime.now())) {
            throw new BusinessLogicException("Дата та час персонального тренування не можуть бути в минулому.");
        }

        Integer managerId = managerRepository.findDefaultClientManagerId();
        String promo = ValidationUtils.cleanToNull(promoCode);

        return managerRepository.callBookPersonalTraining(clientId, coachId, hallId, dateTime, promo, managerId, itemId);
    }

    public Integer bookPersonalTraining(Integer clientId, Integer coachId, Integer hallId, LocalDateTime dateTime, String promoCode) {
        return bookPersonalTraining(clientId, coachId, hallId, dateTime, promoCode, null);
    }

    /**
     * M7: Freeze subscription
     */
    @Transactional
    public void freezeSubscription(FreezeRequest req) {
        if (req.startDate() == null || req.startDate().isBefore(LocalDate.now())) {
            throw new BusinessLogicException("Дата початку заморозки не може бути в минулому.");
        }
        if (req.endDate() == null || !req.endDate().isAfter(req.startDate())) {
            throw new BusinessLogicException("Дата закінчення заморозки повинна бути пізнішою за дату початку.");
        }

        long freezeDays = ChronoUnit.DAYS.between(req.startDate(), req.endDate());

        ManagerRepository.SubscriptionFreezeTarget target = managerRepository.findSubscriptionForFreeze(req.clientSubscriptionId());
        if (target == null) {
            throw new BusinessLogicException("У клієнта немає активного абонемента для заморозки.");
        }

        if (target.remainingFreezingDays() < freezeDays) {
            throw new BusinessLogicException("Недостатньо днів заморозки. Залишок: " + target.remainingFreezingDays() + ", запитано: " + freezeDays);
        }

        managerRepository.insertFreezingLog(target.clientSubId(), req.startDate(), req.endDate(), req.reason());
        managerRepository.applySubscriptionFreeze(target.clientSubId(), target.endDate().plusDays(freezeDays), freezeDays);
    }

    /**
     * M8: Cancel or reschedule booking
     */
    @Transactional
    public void changeBooking(BookingChangeRequest req) {
        if ("Personal".equalsIgnoreCase(req.bookingType())) {
            if ("Cancel".equalsIgnoreCase(req.action())) {
                managerRepository.cancelPersonalTraining(req.bookingId(), req.reason(), req.initiator() != null ? req.initiator() : "Manager");
            } else if ("Reschedule".equalsIgnoreCase(req.action())) {
                if (req.newDateTime() == null || req.newDateTime().isBefore(LocalDateTime.now())) {
                    throw new BusinessLogicException("Новий час тренування не може бути в минулому.");
                }

                ManagerRepository.PersonalTrainingDetails details = managerRepository.getPersonalTrainingDetails(req.bookingId());
                if (details == null) {
                    throw new BusinessLogicException("Персональне тренування не знайдено.");
                }

                boolean conflict = managerRepository.hasCoachConflict(details.coachId(), req.newDateTime(), req.bookingId());
                if (conflict) {
                    throw new BusinessLogicException("Тренер вже має заплановане тренування на новий час (" + req.newDateTime() + ").");
                }

                managerRepository.reschedulePersonalTraining(
                        req.bookingId(),
                        details.trainingDateTime(),
                        req.newDateTime(),
                        req.reason(),
                        req.initiator() != null ? req.initiator() : "Manager"
                );
            }
        } else if ("Group".equalsIgnoreCase(req.bookingType())) {
            if ("Cancel".equalsIgnoreCase(req.action())) {
                managerRepository.cancelGroupClassBooking(req.bookingId());
            } else if ("Reschedule".equalsIgnoreCase(req.action()) && req.newDateTime() != null) {
                managerRepository.rescheduleGroupClassInstance(
                        req.bookingId(),
                        req.newDateTime().toLocalDate(),
                        req.newDateTime().toLocalTime()
                );
            }
        }
    }

    /**
     * M9: Schedule a group class instance
     */
    public Integer createGroupClassInstance(Integer templateId, LocalDate classDate, LocalTime startTime) {
        LocalTime effectiveStartTime = startTime != null ? startTime : managerRepository.getTemplateStartTime(templateId);
        return managerRepository.insertGroupClassInstance(templateId, classDate, effectiveStartTime);
    }

    /**
     * Get pending and recent schedule change requests from coaches
     */
    public List<ScheduleChangeRequestDto> getScheduleRequests() {
        return managerRepository.getScheduleRequests();
    }

    /**
     * Approve a coach schedule request (Reschedule or Cancel)
     */
    @Transactional
    public void approveScheduleRequest(Integer logId) {
        ManagerRepository.PTChangeLogRecord logRow = managerRepository.findPTChangeLog(logId);
        if (logRow == null) {
            throw new BusinessLogicException("Запит на зміну розкладу з ID " + logId + " не знайдено.");
        }

        if (!"Pending".equalsIgnoreCase(logRow.status())) {
            throw new BusinessLogicException("Запит вже було оброблено (поточний статус: " + logRow.status() + ").");
        }

        if ("Reschedule".equalsIgnoreCase(logRow.requestType())) {
            LocalDateTime newDateTime = managerRepository.findProposedDateTime(logId);
            if (newDateTime == null) {
                throw new BusinessLogicException("Для запиту на перенесення не вказано новий час у PT_TimeChangeDetails.");
            }

            if (newDateTime.isBefore(LocalDateTime.now())) {
                throw new BusinessLogicException("Неможливо погодити запит: запропонований час перенесення вже минув.");
            }

            // Оновлення тренування (тригери БД перевірять зайнятість тренера та клієнта)
            managerRepository.updatePersonalTrainingDateTime(logRow.personalId(), newDateTime);
        } else if ("Cancel".equalsIgnoreCase(logRow.requestType())) {
            managerRepository.updatePersonalTrainingStatus(logRow.personalId(), "Cancelled");
        }

        managerRepository.updatePTChangeLogStatus(logId, "Approved");
    }

    /**
     * Reject a coach schedule request
     */
    @Transactional
    public void rejectScheduleRequest(Integer logId) {
        int updated = managerRepository.rejectPendingChangeLog(logId);
        if (updated == 0) {
            String currStatus = managerRepository.findPTChangeLogStatus(logId);
            if (currStatus == null) {
                throw new BusinessLogicException("Запит на зміну розкладу з ID " + logId + " не знайдено.");
            }
            throw new BusinessLogicException("Неможливо відхилити: запит вже оброблено (статус: " + currStatus + ").");
        }
    }

    /**
     * View available group classes scheduled for current and future dates
     */
    public List<AvailableGroupClassDto> getAvailableGroupClasses() {
        return clientRepository.getAvailableGroupClasses();
    }
}
