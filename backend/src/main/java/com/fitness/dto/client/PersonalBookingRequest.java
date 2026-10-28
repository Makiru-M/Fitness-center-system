package com.fitness.dto.client;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.LocalDateTime;

@JsonIgnoreProperties(ignoreUnknown = true)
public record PersonalBookingRequest(
        Integer coachId,
        Integer hallId,
        LocalDateTime trainingDateTime,
        String promoCode,
        Integer saleId,
        Integer itemId
) {
    public PersonalBookingRequest(Integer coachId, Integer hallId, LocalDateTime trainingDateTime, String promoCode) {
        this(coachId, hallId, trainingDateTime, promoCode, null, null);
    }
    public PersonalBookingRequest(Integer coachId, Integer hallId, LocalDateTime trainingDateTime, String promoCode, Integer saleId) {
        this(coachId, hallId, trainingDateTime, promoCode, saleId, null);
    }
}
