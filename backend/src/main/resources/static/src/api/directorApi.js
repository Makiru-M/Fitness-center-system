/**
 * FitnessClub IS - Director API Service (D1 - D12)
 * Module: api/directorApi.js
 */

import { apiFetch } from './apiClient.js';

export const directorApi = {
  getRevenue(fromDate = null, toDate = null) {
    const params = new URLSearchParams();
    if (fromDate) params.append('fromDate', fromDate);
    if (toDate) params.append('toDate', toDate);
    const qs = params.toString() ? `?${params.toString()}` : '';
    return apiFetch(`/director/reports/revenue${qs}`);
  },

  getAttendance() {
    return apiFetch('/director/reports/attendance');
  },

  getCoachPopularity() {
    return apiFetch('/director/reports/coach-popularity');
  },

  getHallOccupancy() {
    return apiFetch('/director/reports/hall-occupancy');
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

  createPromo(data) {
    return apiFetch('/director/promos', {
      method: 'POST',
      body: JSON.stringify(data)
    });
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

  getGroupIndividualShareView() {
    return apiFetch('/director/views/group-individual-share');
  }
};
