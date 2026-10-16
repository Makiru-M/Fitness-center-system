/**
 * FitnessClub IS - Modal Windows Component (API Settings & Medical Notes)
 * Pure REST API Implementation (Mock mode removed)
 * Module: components/modal.js
 */

import { AppState, STORAGE_KEYS, setApiBaseUrl } from '../state/state.js';
import { checkHealth } from '../api/apiClient.js';
import { managerApi } from '../api/managerApi.js';
import { hrApi } from '../api/hrApi.js';
import { showToast } from './toast.js';
import { updateHeaderUI, refreshRoleData, setServerOnline } from './navigation.js';
import { renderM2ClientsTable, cachedClients } from '../views/managerView.js';
import { renderHrCoachesTable, renderHrStaffTable, cachedEmployees } from '../views/hrView.js';

// ==============================================================================
// 1. API SETTINGS MODAL
// ==============================================================================

export function openApiModal() {
  const modal = document.getElementById('modal-api-settings');
  if (modal) modal.classList.add('active');

  const input = document.getElementById('api-base-url-input');
  if (input) input.value = AppState.apiBaseUrl;

  const statusEl = document.getElementById('api-ping-status');
  if (statusEl) {
    if (AppState.isServerOnline) {
      statusEl.className = 'badge badge-active';
      statusEl.textContent = 'З\'єднано (Онлайн)';
    } else {
      statusEl.className = 'badge badge-expired';
      statusEl.textContent = 'Недоступний (Офлайн)';
    }
  }
}

export function closeApiModal() {
  const modal = document.getElementById('modal-api-settings');
  if (modal) modal.classList.remove('active');
}

export function toggleApiModeSelection(mode) {
  // Deprecated stub
}

export async function testApiConnection() {
  const url = document.getElementById('api-base-url-input').value.trim();
  const statusEl = document.getElementById('api-ping-status');
  if (statusEl) {
    statusEl.className = 'badge badge-scheduled';
    statusEl.textContent = 'З\'єднуємося...';
  }

  try {
    await checkHealth(url);
    if (statusEl) {
      statusEl.className = 'badge badge-active';
      statusEl.textContent = '200 OK (Активний)';
    }
    showToast('З\'єднання з REST API успішно встановлено!', 'success');
  } catch (err) {
    if (statusEl) {
      statusEl.className = 'badge badge-expired';
      statusEl.textContent = 'Бекенд недоступний (Офлайн)';
    }
    showToast('Бекенд недоступний або не запущений.', 'danger');
  }
}

export async function saveApiSettings() {
  const url = document.getElementById('api-base-url-input').value.trim();
  if (url) {
    setApiBaseUrl(url);
  }

  closeApiModal();

  try {
    await checkHealth();
    setServerOnline(true);
    showToast(`Налаштування збережено! Базовий URL: ${AppState.apiBaseUrl}`, 'success');
  } catch (err) {
    setServerOnline(false);
    showToast(`Збережено, але сервер недоступний: ${AppState.apiBaseUrl}`, 'warning');
  }

  updateHeaderUI();
  refreshRoleData(AppState.activeRole);
}

// ==============================================================================
// 2. MEDICAL NOTES MODAL (Consolidated into Edit Client Modal M2)
// ==============================================================================

/**
 * @deprecated Consolidated into openEditClientModal (M2). Forwarded for backward compatibility.
 */
export function openMedModal(clientId) {
  openEditClientModal(clientId);
}

/**
 * @deprecated Consolidated into closeEditClientModal (M2).
 */
export function closeMedModal() {
  closeEditClientModal();
}

/**
 * @deprecated Consolidated into saveEditClientModal (M2).
 */
export async function saveMedModal() {
  return saveEditClientModal();
}

// ==============================================================================
// 3. EDIT CLIENT MODAL (M2)
// ==============================================================================

export function openEditClientModal(clientId) {
  AppState.editingClientId = clientId;
  const client = (cachedClients || []).find(c => c.clientId === clientId);
  if (!client) {
    showToast('Клієнта не знайдено', 'warning');
    return;
  }

  const idEl = document.getElementById('edit-client-id');
  if (idEl) idEl.value = client.clientId;

  const nameEl = document.getElementById('edit-client-fullname');
  if (nameEl) nameEl.value = client.fullName || '';

  const phoneEl = document.getElementById('edit-client-phone');
  if (phoneEl) phoneEl.value = client.phone || '';

  const birthEl = document.getElementById('edit-client-birthdate');
  if (birthEl) birthEl.value = client.birthDate || '1995-01-01';

  const genderEl = document.getElementById('edit-client-gender');
  if (genderEl) genderEl.value = client.gender || 'Male';

  const medEl = document.getElementById('edit-client-mednotes');
  if (medEl) medEl.value = client.medicalNotes || '';

  const modal = document.getElementById('modal-edit-client');
  if (modal) modal.classList.add('active');
}

export function closeEditClientModal() {
  const modal = document.getElementById('modal-edit-client');
  if (modal) modal.classList.remove('active');
  AppState.editingClientId = null;
}

export async function saveEditClientModal() {
  if (!AppState.editingClientId) return;

  const clientId = AppState.editingClientId;
  const fullName = document.getElementById('edit-client-fullname')?.value.trim();
  const phone = document.getElementById('edit-client-phone')?.value.trim();
  const birthDate = document.getElementById('edit-client-birthdate')?.value;
  const gender = document.getElementById('edit-client-gender')?.value || 'Male';
  const medicalNotes = document.getElementById('edit-client-mednotes')?.value.trim() ?? '';

  if (!fullName || !phone) {
    showToast('Заповніть обов\'язкові поля (ПІБ та телефон)!', 'warning');
    return;
  }

  try {
    await managerApi.updateClient({
      clientId,
      fullName,
      birthDate,
      phone,
      gender,
      medicalNotes
    });

    closeEditClientModal();
    showToast(`Профіль клієнта #${clientId} успішно оновлено! (M2)`, 'success');
    await renderM2ClientsTable();
  } catch (err) {
    showToast(`Помилка оновлення клієнта: ${err.message}`, 'danger');
  }
}

// ==============================================================================
// 4. EDIT COACH MODAL (HR2)
// ==============================================================================

export function openEditCoachModal(coachId) {
  AppState.editingCoachId = coachId;
  const emp = (cachedEmployees || []).find(e => (e.coachId === coachId || e.staffId === coachId));
  if (!emp) {
    showToast('Тренера не знайдено', 'warning');
    return;
  }

  const idEl = document.getElementById('edit-coach-id');
  if (idEl) idEl.value = emp.coachId || emp.staffId;

  const nameEl = document.getElementById('edit-coach-fullname');
  if (nameEl) nameEl.value = emp.fullName || '';

  const phoneEl = document.getElementById('edit-coach-phone');
  if (phoneEl) phoneEl.value = emp.phone || '';

  const birthEl = document.getElementById('edit-coach-birthdate');
  if (birthEl) birthEl.value = emp.birthDate || '1990-01-01';

  const specEl = document.getElementById('edit-coach-spec');
  if (specEl) {
    // If specName contains known keywords or map
    const specMap = {
      'Тренажерний зал': 1,
      'Йога': 2,
      'Пілатес': 3,
      'Кроссфіт': 4,
      'Бокс': 5,
      'Плавання': 6,
      'Стретчинг': 7,
      'Дитячий фітнес': 8
    };
    specEl.value = specMap[emp.specName] || 1;
  }

  const bioEl = document.getElementById('edit-coach-bio');
  if (bioEl) bioEl.value = emp.biography || '';

  const modal = document.getElementById('modal-edit-coach');
  if (modal) modal.classList.add('active');
}

export function closeEditCoachModal() {
  const modal = document.getElementById('modal-edit-coach');
  if (modal) modal.classList.remove('active');
  AppState.editingCoachId = null;
}

export async function saveEditCoachModal() {
  if (!AppState.editingCoachId) return;

  const coachId = AppState.editingCoachId;
  const fullName = document.getElementById('edit-coach-fullname')?.value.trim();
  const phone = document.getElementById('edit-coach-phone')?.value.trim();
  const birthDate = document.getElementById('edit-coach-birthdate')?.value;
  const specId = parseInt(document.getElementById('edit-coach-spec')?.value || '1');
  const biography = document.getElementById('edit-coach-bio')?.value.trim() || '';

  if (!fullName || !phone) {
    showToast('Вкажіть ПІБ та контактний телефон!', 'warning');
    return;
  }

  try {
    await hrApi.updateCoach({
      coachId,
      fullName,
      birthDate,
      phone,
      specId,
      biography
    });

    closeEditCoachModal();
    showToast(`Дані тренера успішно оновлено! (HR2)`, 'success');
    await renderHrCoachesTable();
  } catch (err) {
    showToast(`Помилка оновлення даних тренера: ${err.message}`, 'danger');
  }
}

// ==============================================================================
// 5. EDIT STAFF / MANAGER MODAL (HR5)
// ==============================================================================

export function openEditStaffModal(staffId) {
  AppState.editingStaffId = staffId;
  const emp = (cachedEmployees || []).find(e => e.staffId === staffId);
  if (!emp) {
    showToast('Співробітника не знайдено', 'warning');
    return;
  }

  const idEl = document.getElementById('edit-staff-id');
  if (idEl) idEl.value = emp.staffId;

  const nameEl = document.getElementById('edit-staff-fullname');
  if (nameEl) nameEl.value = emp.fullName || '';

  const phoneEl = document.getElementById('edit-staff-phone');
  if (phoneEl) phoneEl.value = emp.phone || '';

  const birthEl = document.getElementById('edit-staff-birthdate');
  if (birthEl) birthEl.value = emp.birthDate || '1990-01-01';

  const posEl = document.getElementById('edit-staff-position');
  if (posEl) {
    const posMap = {
      'HR Менеджер': 1,
      'Старший тренер': 2,
      'Тренер': 3,
      'Адміністратор': 4,
      'Директор': 5
    };
    posEl.value = posMap[emp.positionName] || 4;
  }

  const modal = document.getElementById('modal-edit-staff');
  if (modal) modal.classList.add('active');
}

export function closeEditStaffModal() {
  const modal = document.getElementById('modal-edit-staff');
  if (modal) modal.classList.remove('active');
  AppState.editingStaffId = null;
}

export async function saveEditStaffModal() {
  if (!AppState.editingStaffId) return;

  const staffId = AppState.editingStaffId;
  const fullName = document.getElementById('edit-staff-fullname')?.value.trim();
  const phone = document.getElementById('edit-staff-phone')?.value.trim();
  const birthDate = document.getElementById('edit-staff-birthdate')?.value;
  const positionId = parseInt(document.getElementById('edit-staff-position')?.value || '4');

  if (!fullName || !phone) {
    showToast('Вкажіть ПІБ та контактний телефон!', 'warning');
    return;
  }

  try {
    await hrApi.updateManager({
      staffId,
      fullName,
      birthDate,
      phone,
      positionId
    });

    closeEditStaffModal();
    showToast(`Дані менеджера успішно оновлено! (HR5)`, 'success');
    await renderHrStaffTable();
  } catch (err) {
    showToast(`Помилка оновлення даних менеджера: ${err.message}`, 'danger');
  }
}
