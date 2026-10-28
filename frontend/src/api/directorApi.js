/**
 * FitnessClub IS - Director API Service (D1 - D12)
 * Module: api/directorApi.js
 */

import { apiFetch } from './apiClient.js';

export const directorApi = {
  getRevenue(fromDate = null, toDate = null, groupBy = 'TOTAL') {
    const params = new URLSearchParams();
    if (fromDate) params.append('fromDate', fromDate);
    if (toDate) params.append('toDate', toDate);
    if (groupBy) params.append('groupBy', groupBy);
    const qs = params.toString() ? `?${params.toString()}` : '';
    return apiFetch(`/director/reports/revenue${qs}`);
  },

  getAttendance() {
    return apiFetch('/director/reports/attendance');
  },

  getCoachPopularity() {
    return apiFetch('/director/reports/coach-popularity');
  },

  getIssues() {
    return apiFetch('/director/reports/issues');
  },

  getAuditLog() {
    return apiFetch('/director/reports/audit-log');
  },

  createSubscriptionType(data) {
    return apiFetch('/director/subscriptions', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  createHall(data) {
    return apiFetch('/director/halls', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  decommissionHall(hallId) {
    return apiFetch(`/director/halls/${hallId}`, {
      method: 'DELETE'
    });
  },

  getArchivedHalls() {
    return apiFetch('/director/halls/archived');
  },

  recommissionHall(hallId) {
    return apiFetch('/director/halls/' + hallId + '/recommission', { method: 'PUT' });
  },

  createPromo(data) {
    return apiFetch('/director/promos', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  getClassTypes() {
    return apiFetch('/director/class-types');
  },

  createScheduleTemplate(data) {
    return apiFetch('/director/schedule/templates', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  createService(data) {
    return apiFetch('/director/services', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  updatePriceTariff(itemId, newPrice) {
    return apiFetch(`/director/prices/${itemId}`, {
      method: 'PUT',
      body: JSON.stringify({ newPrice: parseFloat(newPrice) })
    });
  },

  createTurnkeyService(data) {
    return apiFetch('/director/services/turnkey', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  getPrices(includeArchived = false) {
    return apiFetch(`/director/prices?includeArchived=${includeArchived}`);
  },

  deactivatePriceItem(itemId) {
    return apiFetch(`/director/prices/${itemId}`, {
      method: 'DELETE'
    });
  }
};
