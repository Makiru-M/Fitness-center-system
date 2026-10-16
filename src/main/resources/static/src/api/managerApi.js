/**
 * FitnessClub IS - Manager API Service (M1 - M8)
 * Module: api/managerApi.js
 */

import { apiFetch } from './apiClient.js';

export const managerApi = {
  checkIn(clientId, hallId, phone = '') {
    return apiFetch('/manager/visits/check-in', {
      method: 'POST',
      body: JSON.stringify({ clientId, hallId, phone })
    });
  },

  getClients(searchTerm = '') {
    const q = searchTerm ? `?search=${encodeURIComponent(searchTerm)}` : '';
    return apiFetch(`/manager/clients${q}`);
  },

  registerClient(data) {
    return apiFetch('/manager/clients', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  updateClient(data) {
    return apiFetch('/manager/clients', {
      method: 'PUT',
      body: JSON.stringify(data)
    });
  },

  sellSubscription(data) {
    return apiFetch('/manager/sales/subscription', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  bookGroupClass(clientId, instanceId) {
    return apiFetch(`/manager/bookings/group?clientId=${clientId}&instanceId=${instanceId}`, {
      method: 'POST'
    });
  },

  bookPersonalTraining(clientId, coachId, hallId, dateTime) {
    return apiFetch(`/manager/bookings/personal?clientId=${clientId}&coachId=${coachId}&hallId=${hallId}&dateTime=${encodeURIComponent(dateTime)}`, {
      method: 'POST'
    });
  },

  freezeSubscription(data) {
    return apiFetch('/manager/subscriptions/freeze', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  processScheduleAction(data) {
    return apiFetch('/manager/bookings/change', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }
};
