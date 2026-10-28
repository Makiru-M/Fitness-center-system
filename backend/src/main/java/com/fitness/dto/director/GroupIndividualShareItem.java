package com.fitness.dto.director;

import java.time.LocalTime;

public record GroupIndividualShareItem(
        Integer templateId,
        String groupType,
        Integer dayOfWeek,
        LocalTime startTime,
        Long totalGroupClients,
        Long clientsWithPersonalTrainings,
        Double personalTrainingSharePercent
) {}
