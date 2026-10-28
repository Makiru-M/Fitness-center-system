package com.fitness.dto.director;

import com.fasterxml.jackson.annotation.JsonAlias;

public record CommissionHallRequest(
        @JsonAlias({"name", "hall_name"}) String hallName,
        Integer maxCapacity
) {}
