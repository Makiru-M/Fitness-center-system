/**
 * FitnessClub IS - HR Manager API Service (HR1 - HR6)
 * Module: api/hrApi.js
 */

import { apiFetch } from './apiClient.js';

export const hrApi = {
  getEmployees() {
    return apiFetch('/hr/employees');
  },

  hireCoach(data) {
    return apiFetch('/hr/coaches', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  updateCoach(data) {
    return apiFetch('/hr/coaches', {
      method: 'PUT',
      body: JSON.stringify(data)
    });
  },

  fireEmployee(data) {
    return apiFetch('/hr/employees/fire', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  hireManager(data) {
    return apiFetch('/hr/managers', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  updateManager(data) {
    return apiFetch('/hr/managers', {
      method: 'PUT',
      body: JSON.stringify(data)
    });
  }
};
