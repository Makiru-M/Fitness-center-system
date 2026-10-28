package com.fitness.dto.client;

public record RenewSubscriptionRequest(
        Integer itemId,
        String promoCode
) {}
