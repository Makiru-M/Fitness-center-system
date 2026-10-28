package com.fitness.util;

/**
 * Common sanitization and validation utilities for strings, phone numbers, and input parameters.
 */
public final class ValidationUtils {

    private ValidationUtils() {
        // Utility class
    }

    /**
     * Sanitizes a string: returns null if the string is null or blank, otherwise trimmed string.
     *
     * @param value the raw string
     * @return trimmed string or null
     */
    public static String cleanToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    /**
     * Validates whether a phone number matches Ukrainian format +380XXXXXXXXX.
     *
     * @param phone the phone string
     * @return true if valid, false otherwise
     */
    public static boolean isValidPhone(String phone) {
        return phone != null && phone.trim().matches("^\\+380\\d{9}$");
    }
}
