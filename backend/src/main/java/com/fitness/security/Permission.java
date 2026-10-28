package com.fitness.security;

public enum Permission {
    // Director
    REPORTS_VIEW,
    AUDIT_VIEW,
    CATALOG_MANAGE,
    SCHEDULE_MANAGE,
    ALL_PRIVILEGES,

    // Manager
    CLIENTS_MANAGE,
    SALES_MANAGE,
    CHECKIN_MANAGE,
    BOOKING_MANAGE,

    // HR
    STAFF_HIRE,
    STAFF_EDIT,
    STAFF_FIRE,

    // Coach
    SCHEDULE_VIEW,
    CLASS_MARK,
    CHANGE_REQUEST,

    // Client
    PROFILE_EDIT,
    BOOKING_CREATE,
    SUBSCRIPTION_MANAGE,

    // Guest
    GUEST_BROWSE
}
