package com.fitness.dto.director;

import com.fasterxml.jackson.annotation.JsonAlias;
import java.time.LocalDate;

public record CreatePromoCodeRequest(
        @JsonAlias({"code", "code_text"}) String codeText,
        Integer discountPercent,
        LocalDate expiryDate
) {}
