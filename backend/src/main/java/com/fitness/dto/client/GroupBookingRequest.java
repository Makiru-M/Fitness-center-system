package com.fitness.dto.client;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record GroupBookingRequest(
        Integer instanceId,
        String promoCode,
        Integer saleId
) {
    public GroupBookingRequest(Integer instanceId, String promoCode) {
        this(instanceId, promoCode, null);
    }
}
