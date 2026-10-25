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

  getAvailableGroupClasses() {
    return apiFetch('/manager/group-classes/available');
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

  bookGroupClass(clientId, instanceId, promoCode = '') {
    const p = promoCode ? `&promoCode=${encodeURIComponent(promoCode)}` : '';
    return apiFetch(`/manager/bookings/group?clientId=${clientId}&instanceId=${instanceId}${p}`, {
      method: 'POST'
    });
  },

  bookPersonalTraining(clientId, coachId, hallId, dateTime, promoCode = '', itemId = null) {
    const params = new URLSearchParams({
      clientId: String(clientId),
      coachId: String(coachId),
      hallId: String(hallId),
      dateTime: String(dateTime)
    });
    if (promoCode) params.append('promoCode', promoCode);
    if (itemId) params.append('itemId', String(itemId));
    return apiFetch(`/manager/bookings/personal?${params.toString()}`, {
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
  },

  getScheduleRequests() {
    return apiFetch('/manager/schedule-requests');
  },

  approveScheduleRequest(logId) {
    return apiFetch(`/manager/schedule-requests/${logId}/approve`, {
      method: 'POST'
    });
  },

  rejectScheduleRequest(logId) {
    return apiFetch(`/manager/schedule-requests/${logId}/reject`, {
      method: 'POST'
    });
  }
};
