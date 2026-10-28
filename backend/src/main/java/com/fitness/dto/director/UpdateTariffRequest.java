package com.fitness.dto.director;

import com.fasterxml.jackson.annotation.JsonAlias;
import java.math.BigDecimal;

public record UpdateTariffRequest(
        @JsonAlias({"new_price", "price"}) BigDecimal newPrice
) {}
