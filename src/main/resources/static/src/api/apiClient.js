/**
 * FitnessClub IS - Universal REST API Fetch Client
 * Pure REST API Mode with automatic network failure handling
 * Module: api/apiClient.js
 */

import { AppState } from '../state/state.js';

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

  if (AppState.authToken) {
    headers['X-Auth-Token'] = AppState.authToken;
    headers['Authorization'] = `Bearer ${AppState.authToken}`;
  } else if (AppState.currentUser && AppState.currentUser.pass) {
    headers['Authorization'] = 'Basic ' + btoa(`${AppState.currentUser.dbUser}:${AppState.currentUser.pass}`);
  }

  console.log(`%c[API Request] 🚀 ${method} ${fullUrl}`, 'color: #2563eb; font-weight: bold;', {
    headers,
    body: options.body ? (typeof options.body === 'string' ? JSON.parse(options.body) : options.body) : null
  });

  try {
    const res = await fetch(fullUrl, { ...options, headers });
    const contentType = res.headers.get('content-type') || '';
    const isJson = contentType.includes('application/json');
    const data = isJson ? await res.json() : await res.text();

    if (res.ok) {
      console.log(`%c[API Response] ✅ ${res.status} ${fullUrl}`, 'color: #16a34a; font-weight: bold;', data);
      if (!AppState.isServerOnline && typeof window.setServerOnline === 'function') {
        window.setServerOnline(true);
      }
    } else {
      console.warn(`%c[API Response] ⚠️ ${res.status} ${fullUrl}`, 'color: #dc2626; font-weight: bold;', data);
      const errorMsg = (typeof data === 'object' && (data.error || data.message))
        ? (data.error || data.message)
        : `Помилка сервера HTTP ${res.status}`;
      throw new Error(errorMsg);
    }

    return data;
  } catch (err) {
    console.error(`%c[API Error] ❌ ${method} ${fullUrl}:`, 'color: #dc2626; font-weight: bold;', err.message);

    if (isNetworkError(err) && typeof window.setServerOnline === 'function') {
      window.setServerOnline(false);
    }

    throw err;
  }
}
