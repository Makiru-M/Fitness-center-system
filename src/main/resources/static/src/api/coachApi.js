/**
 * FitnessClub IS - Coach API Service (C1 - C5)
 * Module: api/coachApi.js
 */

import { apiFetch } from './apiClient.js';

export const coachApi = {
  getSchedule() {
    return apiFetch('/coach/schedule');
  },

  getGroupParticipants(instanceId) {
    return apiFetch(`/coach/classes/${instanceId}/participants`);
  },

  getPersonalClient(personalId) {
    return apiFetch(`/coach/personal/${personalId}/client`);
  },

  markPersonalTraining(personalId, data) {
    return apiFetch(`/coach/personal/${personalId}/status`, {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  markGroupClass(instanceId, data) {
    return apiFetch(`/coach/group/${instanceId}/attendance`, {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  requestScheduleChange(data) {
    return apiFetch('/coach/requests/reschedule', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }
};
