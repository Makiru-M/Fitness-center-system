/**
 * FitnessClub IS - Guest API Service (G1 - G4)
 * Module: api/guestApi.js
 */

import { apiFetch } from './apiClient.js';

export const guestApi = {
  getPriceList() {
    return apiFetch('/guest/price-list');
  },

  getHalls() {
    return apiFetch('/guest/halls');
  },

  getCoaches(specializationId) {
    const query = specializationId ? `?specializationId=${encodeURIComponent(specializationId)}` : '';
    return apiFetch(`/guest/coaches${query}`);
  },

  register(registrationData) {
    return apiFetch('/guest/register', {
      method: 'POST',
      body: JSON.stringify(registrationData)
    });
  }
};
