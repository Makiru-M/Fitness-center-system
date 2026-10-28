/**
 * FitnessClub IS - Application State Management
 * Pure REST API Mode (Mock removed)
 * Module: state/state.js
 */

export const STORAGE_KEYS = {
  API_URL: 'fc_api_url',
  AUTH_TOKEN: 'fc_auth_token',
  REFRESH_TOKEN: 'fitness_refresh_token',
  CURRENT_USER: 'fc_current_user'
};

export const TEST_ACCOUNTS = {
  'boss_ivan': { role: 'director', pass: 'boss123', name: 'Іван Іванович Іваненко', pos: 'Директор' },
  'manager_petro': { role: 'manager', pass: 'mgr123', name: 'Петро Петрович Петренко', pos: 'Менеджер клієнтів' },
  'admin_olena': { role: 'hr', pass: 'hr123', name: 'Олена Сергіївна Сидоренко', pos: 'HR Менеджер' },
  'coach_maksym': { role: 'coach', pass: 'coach123', name: 'Максим Вікторович Коваленко', pos: 'Старший тренер' },
  'user_oleksandr': { role: 'client', pass: 'client123', name: 'Олександр Віталійович Остапенко', pos: 'Клієнт' },
  'guest_user': { role: 'guest', pass: 'guest_pass_2026', name: 'Гість клубу', pos: 'Відвідувач' }
};

export const KNOWN_PROMOS = [
  { code: 'OPEN10', discountPercent: 10, expiryDate: '2026-12-31' },
  { code: 'FIT2026', discountPercent: 15, expiryDate: '2026-12-31' },
  { code: 'WELCOME20', discountPercent: 20, expiryDate: '2026-12-31' },
  { code: 'SALE30', discountPercent: 30, expiryDate: '2026-06-01' },
  { code: 'SUMMER10', discountPercent: 10, expiryDate: '2026-09-01' }
];

export function findPromo(code) {
  if (!code) return null;
  const clean = code.trim().toUpperCase();
  return KNOWN_PROMOS.find(p => p.code.toUpperCase() === clean) || null;
}

export function registerPromo(promo) {
  if (!promo || !promo.code) return;
  const existing = findPromo(promo.code);
  if (existing) {
    existing.discountPercent = promo.discountPercent;
    existing.expiryDate = promo.expiryDate;
  } else {
    KNOWN_PROMOS.push({
      code: promo.code.toUpperCase(),
      discountPercent: promo.discountPercent,
      expiryDate: promo.expiryDate
    });
  }
}

// Global reactive application state (Pure REST API mode)
export const AppState = {
  currentUser: null,      // Active user object { dbUser, name, role, pos, entityId, pass, ... } or null (guest)
  activeRole: 'guest',    // 'guest' | 'client' | 'manager' | 'hr' | 'coach' | 'director'
  previousRole: 'guest',  // Previous active role to restore after reconnection
  apiBaseUrl: localStorage.getItem(STORAGE_KEYS.API_URL) || 'http://localhost:8080/api',
  authToken: localStorage.getItem(STORAGE_KEYS.AUTH_TOKEN) || sessionStorage.getItem(STORAGE_KEYS.AUTH_TOKEN) || null,
  isServerOnline: true,   // Track backend connection status
  editingClientId: null,
  editingCoachId: null,
  editingStaffId: null
};

export function setCurrentUser(user) {
  AppState.currentUser = user;
  if (user) {
    sessionStorage.setItem(STORAGE_KEYS.CURRENT_USER, JSON.stringify(user));
  } else {
    sessionStorage.removeItem(STORAGE_KEYS.CURRENT_USER);
  }
}

export function getCurrentUser() {
  return AppState.currentUser;
}

export function setActiveRole(role) {
  if (role && role !== 'server-unavailable') {
    AppState.previousRole = role;
  }
  AppState.activeRole = role;
}

export function getActiveRole() {
  return AppState.activeRole;
}

export function setApiBaseUrl(url) {
  AppState.apiBaseUrl = url;
  localStorage.setItem(STORAGE_KEYS.API_URL, url);
}

export function setAuthToken(token) {
  AppState.authToken = token;
  if (token) {
    localStorage.setItem(STORAGE_KEYS.AUTH_TOKEN, token);
  } else {
    localStorage.removeItem(STORAGE_KEYS.AUTH_TOKEN);
    sessionStorage.removeItem(STORAGE_KEYS.AUTH_TOKEN);
  }
}

export function setRefreshToken(token) {
  if (token) {
    localStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, token);
  } else {
    localStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN);
  }
}

export function getRefreshToken() {
  return localStorage.getItem(STORAGE_KEYS.REFRESH_TOKEN);
}

export function clearRefreshToken() {
  localStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN);
}
