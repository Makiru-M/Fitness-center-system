package com.fitness.service;

import com.fitness.dto.client.*;
import com.fitness.exception.BusinessLogicException;
import com.fitness.repository.ClientRepository;
import com.fitness.util.ValidationUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class ClientService {

    private final ClientRepository clientRepository;

    public ClientService(ClientRepository clientRepository) {
        this.clientRepository = clientRepository;
    }

    /**
     * View client own profile and medical restrictions
     */
    public ClientProfileDto getProfile() {
        return clientRepository.getProfile()
                .orElseThrow(() -> new BusinessLogicException("Профіль клієнта не знайдено для поточного користувача."));
    }

    /**
     * Cl1: Edit own profile (FullName, Phone, Medical notes)
     */
    @Transactional
    public void updateProfile(UpdateClientProfileRequest req) {
        if (req.phone() != null && !req.phone().isBlank()) {
            if (!ValidationUtils.isValidPhone(req.phone())) {
                throw new BusinessLogicException("Некоректний формат номера телефону. Очікується формат +380XXXXXXXXX.");
            }
        }

        // Check if client profile exists
        getProfile();

        clientRepository.updateClientBasicInfo(req.fullName(), req.phone());

        if (req.medicalNotes() != null) {
            if (req.medicalNotes().isBlank()) {
                clientRepository.deleteMedicalNotes();
            } else {
                clientRepository.upsertMedicalNotes(req.medicalNotes());
            }
        }
    }

    /**
     * Cl2: Renew / purchase subscription
     */
    public ClientSubscriptionDto renewSubscription(RenewSubscriptionRequest req) {
        String promo = ValidationUtils.cleanToNull(req.promoCode());
        return clientRepository.renewSubscription(req.itemId(), promo);
    }

    /**
     * Cl3: Freeze active subscription
     */
    public void freezeSubscription(FreezeSubscriptionRequest req) {
        if (req.startDate() == null || req.endDate() == null) {
            throw new BusinessLogicException("Потрібно вказати дату початку та дату закінчення заморозки.");
        }

        if (req.startDate().isBefore(LocalDate.now())) {
            throw new BusinessLogicException("Дата початку заморозки не може бути в минулому.");
        }

        long freezeDays = ChronoUnit.DAYS.between(req.startDate(), req.endDate());
        if (freezeDays <= 0) {
            throw new BusinessLogicException("Дата закінчення заморозки повинна бути пізнішою за дату початку.");
        }

        clientRepository.freezeSubscription(req.clientSubscriptionId(), req.startDate(), req.endDate(), req.reason());
    }

    /**
     * Cl3: Unfreeze subscription
     */
    public void unfreezeSubscription(Integer clientSubscriptionId) {
        clientRepository.unfreezeSubscription(clientSubscriptionId);
    }

    /**
     * Cl4: Book a group class
     */
    public void bookGroupClass(GroupBookingRequest req) {
        if (req.instanceId() == null) {
            throw new BusinessLogicException("Не вказано ідентифікатор заняття.");
        }

        String promo = ValidationUtils.cleanToNull(req.promoCode());
        clientRepository.bookGroupClass(req.instanceId(), promo);
    }

    /**
     * Cl5: Book a personal training
     */
    public Integer bookPersonalTraining(PersonalBookingRequest req) {
        if (req.coachId() == null || req.hallId() == null || req.trainingDateTime() == null) {
            throw new BusinessLogicException("Заповніть усі обов'язкові поля для запису на тренування.");
        }

        if (req.trainingDateTime().isBefore(LocalDateTime.now())) {
            throw new BusinessLogicException("Дата та час персонального тренування не можуть бути в минулому.");
        }

        String promo = ValidationUtils.cleanToNull(req.promoCode());
        return clientRepository.bookPersonalTraining(req.coachId(), req.hallId(), req.trainingDateTime(), promo, req.itemId());
    }

    /**
     * Cl6: Cancel personal booking
     */
    @Transactional
    public void cancelPersonalBooking(CancelPersonalBookingRequest req) {
        int updated = clientRepository.cancelPersonalTraining(req.bookingId());
        if (updated == 0) {
            throw new BusinessLogicException("Запис на тренування не знайдено або він вже не є запланованим.");
        }

        clientRepository.insertPersonalTrainingCancelLog(req.bookingId(), req.reason());
    }

    /**
     * Cl6: Cancel group booking
     */
    public void cancelGroupBooking(CancelGroupBookingRequest req) {
        clientRepository.cancelGroupBooking(req.bookingId());
    }

    /**
     * View own subscriptions
     */
    public List<ClientSubscriptionDto> getMySubscriptions() {
        return clientRepository.getMySubscriptions();
    }

    /**
     * View own bookings
     */
    public List<ClientBookingDto> getMyBookings() {
        return clientRepository.getMyBookings();
    }

    /**
     * View own visit history
     */
    public List<VisitDto> getMyVisits() {
        return clientRepository.getMyVisits();
    }

    /**
     * Cl4: View available group classes scheduled for current and future dates
     */
    public List<AvailableGroupClassDto> getAvailableGroupClasses() {
        return clientRepository.getAvailableGroupClasses();
    }
}
