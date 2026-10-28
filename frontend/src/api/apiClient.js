/**
 * FitnessClub IS - Universal REST API Fetch Client
 * Pure REST API Mode with automatic network failure handling
 * Module: api/apiClient.js
 */

import { AppState, setAuthToken, setRefreshToken, getRefreshToken, clearRefreshToken, setCurrentUser, setActiveRole } from '../state/state.js';

/**
 * Perform a health ping against the Spring Boot backend
 */
export async function checkHealth(customUrl = null) {
  const baseUrl = customUrl || AppState.apiBaseUrl;
  const healthUrl = baseUrl.endsWith('/api')
    ? `${baseUrl}/health`
    : `${baseUrl.replace(/\/$/, '')}/health`;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 4000);

  try {
    const res = await fetch(healthUrl, {
      method: 'GET',
      headers: { 'Accept': 'application/json' },
      signal: controller.signal
    });
    clearTimeout(timeoutId);
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }
    const data = await res.json().catch(() => ({ status: 'UP' }));
    return data;
  } catch (err) {
    clearTimeout(timeoutId);
    throw err;
  }
}

/**
 * Determine if an error is a network outage / server unavailable failure
 */
export function isNetworkError(err) {
  if (!err) return false;
  if (err.name === 'AbortError') return true;
  if (err instanceof TypeError) return true;
  const msg = (err.message || '').toLowerCase();
  return msg.includes('failed to fetch') ||
         msg.includes('networkerror') ||
         msg.includes('network request failed') ||
         msg.includes('load failed') ||
         msg.includes('refused');
}

/**
 * Centralized fetch client for all API endpoints
 */
export async function apiFetch(endpoint, options = {}) {
  const cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/' + endpoint;
  const fullUrl = `${AppState.apiBaseUrl}${cleanEndpoint}`;
  const method = options.method || 'GET';

  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {})
  };

  const activeToken = AppState.authToken || localStorage.getItem('fc_auth_token') || sessionStorage.getItem('fc_auth_token');
  let activeUser = AppState.currentUser;
  if (!activeUser) {
    try {
      const saved = sessionStorage.getItem('fc_current_user');
      if (saved) activeUser = JSON.parse(saved);
    } catch (e) {}
  }

  if (activeToken) {
    headers['X-Auth-Token'] = activeToken;
    headers['Authorization'] = `Bearer ${activeToken}`;
  }

  console.log(`%c[API Request] 🚀 ${method} ${fullUrl}`, 'color: #2563eb; font-weight: bold;', {
    headers,
    body: options.body ? (typeof options.body === 'string' ? JSON.parse(options.body) : options.body) : null
  });

  try {
    const res = await fetch(fullUrl, { ...options, headers });
    const contentType = res.headers.get('content-type') || '';
    const isJson = contentType.includes('application/json');
    const data = isJson ? await res.json().catch(() => ({})) : await res.text();

    if (res.ok) {
      console.log(`%c[API Response] ✅ ${res.status} ${fullUrl}`, 'color: #16a34a; font-weight: bold;', data);
      if (!AppState.isServerOnline && typeof window.setServerOnline === 'function') {
        window.setServerOnline(true);
      }
      return data;
    }

    // Refresh Token Rotation on 401
    const isAuthEndpoint = cleanEndpoint === '/auth/login' || cleanEndpoint === '/auth/refresh';
    if (res.status === 401 && !isAuthEndpoint && !options._isRetry) {
      const currentRefreshToken = getRefreshToken();
      if (currentRefreshToken) {
        console.warn(`[API Auth] 🔄 Token expired (401). Attempting Refresh Token rotation...`);
        try {
          const refreshRes = await fetch(`${AppState.apiBaseUrl}/auth/refresh`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ refreshToken: currentRefreshToken })
          });

          if (refreshRes.ok) {
            const refreshData = await refreshRes.json();
            if (refreshData.accessToken && refreshData.refreshToken) {
              setAuthToken(refreshData.accessToken);
              setRefreshToken(refreshData.refreshToken);
              console.log(`[API Auth] ✅ Token rotation successful. Retrying original request...`);
              return apiFetch(endpoint, { ...options, _isRetry: true });
            }
          }
          console.warn('[API Auth] ❌ Token rotation response not ok or missing tokens.');
        } catch (refreshErr) {
          console.warn('[API Auth] ❌ Token rotation failed with error:', refreshErr);
        }
      }

      // If rotation failed or no refresh token available, reset session to guest
      console.warn('[API Auth] 🚪 Session expired and refresh failed. Clearing tokens and resetting to guest...');
      setAuthToken(null);
      clearRefreshToken();
      setCurrentUser(null);
      setActiveRole('guest');
      if (typeof window.updateHeaderUI === 'function') window.updateHeaderUI();
      if (typeof window.renderRoleNav === 'function') window.renderRoleNav();
      if (typeof window.switchRoleView === 'function') window.switchRoleView('guest');
    }

    console.warn(`%c[API Response] ⚠️ ${res.status} ${fullUrl}`, 'color: #dc2626; font-weight: bold;', data);
    const errorMsg = (typeof data === 'object' && (data.message || data.error))
      ? (data.message || data.error)
      : `Помилка сервера HTTP ${res.status}`;
    throw new Error(errorMsg);
  } catch (err) {
    console.error(`%c[API Error] ❌ ${method} ${fullUrl}:`, 'color: #dc2626; font-weight: bold;', err.message);

    if (isNetworkError(err) && typeof window.setServerOnline === 'function') {
      window.setServerOnline(false);
    }

    throw err;
  }
}
