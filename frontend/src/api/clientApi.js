/**
 * FitnessClub IS - Client API Service (Cl1 - Cl6)
 * Module: api/clientApi.js
 */

import { apiFetch } from './apiClient.js';

export const clientApi = {
  getProfile() {
    return apiFetch('/client/profile');
  },

  getSubscriptions() {
    return apiFetch('/client/subscriptions');
  },

  getBookings() {
    return apiFetch('/client/bookings');
  },

  updateProfile(data) {
    return apiFetch('/client/profile', {
      method: 'PUT',
      body: JSON.stringify(data)
    });
  },

  renewSubscription(data) {
    return apiFetch('/client/subscriptions/renew', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  freezeSubscription(data) {
    return apiFetch('/client/subscriptions/freeze', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  bookGroupClass(data) {
    return apiFetch('/client/bookings/group', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  bookPersonalTraining(data) {
    return apiFetch('/client/bookings/personal', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  cancelBooking(data) {
    return apiFetch('/client/bookings/cancel', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }
};
