/**
 * FitnessClub IS - Authentication API Service
 * Module: api/authApi.js
 */

import { apiFetch } from './apiClient.js';

export const authApi = {
  getSession() {
    return apiFetch('/auth/me');
  },

  getProfile() {
    return apiFetch('/auth/profile');
  },

  login(username, password) {
    return apiFetch('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password })
    });
  },

  logout() {
    return apiFetch('/auth/logout', {
      method: 'POST'
    });
  },

  checkHealth(baseUrl) {
    return fetch(`${baseUrl}/health`, { method: 'GET' });
  }
};
