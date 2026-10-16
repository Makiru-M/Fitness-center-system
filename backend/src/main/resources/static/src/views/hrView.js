/**
 * FitnessClub IS - HR Manager View (HR1 - HR6)
 * Pure REST API Implementation
 * Module: views/hrView.js
 */

import { AppState } from '../state/state.js';
import { hrApi } from '../api/hrApi.js';
import { showToast } from '../components/toast.js';
import { refreshCombobox } from '../components/combobox.js';

export let cachedEmployees = [];

export function switchHrTab(tabId) {
  const norm = tabId.replace('_', '-');
  document.querySelectorAll('.hr-pane').forEach(el => el.classList.add('hidden'));
  document.querySelectorAll('#view-hr .nav-tab-btn').forEach(b => b.classList.remove('active'));

  const pane = document.getElementById(`subtab-${norm}`) || document.getElementById(`subtab-${tabId}`);
  const btn = document.getElementById(`tab-btn-${norm}`) || document.getElementById(`tab-btn-${tabId}`);
  if (pane) pane.classList.remove('hidden');
  if (btn) btn.classList.add('active');
}

export async function populateHrDropdowns() {
  try {
    cachedEmployees = await hrApi.getEmployees();
    const today = new Date().toISOString().split('T')[0];

    // Specializations for HR1
    const specSelect = document.getElementById('hr1-spec');
    if (specSelect) {
      specSelect.innerHTML = `
        <option value="1">Crossfit & Силові</option>
        <option value="2">Йога та Пілатес</option>
        <option value="3">Бойові мистецтва</option>
        <option value="4">Плавання & Аквааеробіка</option>
        <option value="5">Реабілітація & ЛФК</option>
      `;
      const hr1Hire = document.getElementById('hr1-hiredate');
      if (hr1Hire) hr1Hire.value = today;
    }

    // Coaches for HR3 (Dismiss)
    const hr3Coach = document.getElementById('hr3-coach');
    if (hr3Coach) {
      hr3Coach.innerHTML = '<option value="" disabled selected>-- Оберіть тренера для звільнення --</option>';
      const activeCoaches = cachedEmployees.filter(e => e.isCoach && e.isActive);
      activeCoaches.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c.staffId;
        opt.textContent = `${c.fullName} (${c.phone})`;
        hr3Coach.appendChild(opt);
      });
      refreshCombobox(hr3Coach);
    }
    const hr3Fire = document.getElementById('hr3-firedate');
    if (hr3Fire) hr3Fire.value = today;

    // Positions for HR4
    const posSelect = document.getElementById('hr4-position');
    if (posSelect) {
      posSelect.innerHTML = `
        <option value="Адміністратор">Адміністратор рецепції</option>
        <option value="Менеджер клієнтів">Менеджер клієнтів</option>
        <option value="HR Менеджер">HR Менеджер</option>
        <option value="Керуючий клубом">Керуючий клубом</option>
      `;
      const hr4Hire = document.getElementById('hr4-hiredate');
      if (hr4Hire) hr4Hire.value = today;
    }

    // Staff for HR6
    const hr6Staff = document.getElementById('hr6-staff');
    if (hr6Staff) {
      hr6Staff.innerHTML = '<option value="" disabled selected>-- Оберіть співробітника для звільнення --</option>';
      const activeStaff = cachedEmployees.filter(e => !e.isCoach && e.isActive);
      activeStaff.forEach(st => {
        const opt = document.createElement('option');
        opt.value = st.staffId;
        opt.textContent = `${st.fullName} [${st.positionName || 'Персонал'}]`;
        hr6Staff.appendChild(opt);
      });
    }
    const hr6Fire = document.getElementById('hr6-firedate');
    if (hr6Fire) hr6Fire.value = today;
  } catch (err) {
    console.warn('Error populating HR dropdowns:', err);
  }
}

export async function renderHrCoachesTable() {
  const tbody = document.getElementById('hr-coaches-tbody');
  if (!tbody) return;

  try {
    cachedEmployees = await hrApi.getEmployees();
    tbody.innerHTML = '';

    const coaches = cachedEmployees.filter(e => e.isCoach);
    if (!coaches.length) {
      tbody.innerHTML = '<tr><td colspan="7" class="text-center text-xs text-slate-400 py-6">Немає зареєстрованих тренерів</td></tr>';
      return;
    }

    coaches.forEach(c => {
      const row = document.createElement('tr');
      const isFired = !c.isActive || !!c.fireDate;
      row.innerHTML = `
        <td class="font-mono text-xs">#${c.coachId || c.staffId}</td>
        <td class="font-bold text-slate-800">${c.fullName}</td>
        <td>${c.phone}</td>
        <td><span class="badge badge-scheduled">${c.specName || 'Тренер'}</span></td>
        <td><span class="badge ${isFired ? 'badge-cancelled' : 'badge-active'}">${isFired ? 'Звільнений' : 'Працює'}</span></td>
        <td>${c.hireDate || '—'} ${isFired ? `(до ${c.fireDate})` : ''}</td>
        <td>
          ${!isFired ? `
            <div class="flex items-center gap-1">
              <button onclick="openEditCoachModal(${c.coachId || c.staffId})" class="btn btn-secondary btn-sm" title="Редагувати тренера">
                <i class="fa-solid fa-pen-to-square"></i> Редагувати
              </button>
              <button onclick="quickDismissCoach(${c.staffId})" class="btn btn-danger btn-sm" title="Звільнити тренера">
                <i class="fa-solid fa-user-xmark"></i> Звільнити
              </button>
            </div>
          ` : '<span class="text-xs text-slate-400">Архівований</span>'}
        </td>
      `;
      tbody.appendChild(row);
    });
  } catch (err) {
    console.warn('Error loading coaches table:', err);
  }
}

export async function renderHrStaffTable() {
  const tbody = document.getElementById('hr-staff-tbody');
  if (!tbody) return;

  try {
    cachedEmployees = await hrApi.getEmployees();
    tbody.innerHTML = '';

    const staffMembers = cachedEmployees.filter(e => !e.isCoach);
    if (!staffMembers.length) {
      tbody.innerHTML = '<tr><td colspan="7" class="text-center text-xs text-slate-400 py-6">Немає зареєстрованого адміністративного персоналу</td></tr>';
      return;
    }

    staffMembers.forEach(st => {
      const row = document.createElement('tr');
      const isFired = !st.isActive || !!st.fireDate;
      row.innerHTML = `
        <td class="font-mono text-xs">#${st.staffId}</td>
        <td class="font-bold text-slate-800">${st.fullName}</td>
        <td>${st.phone}</td>
        <td><span class="badge badge-neutral">${st.positionName || 'Менеджер'}</span></td>
        <td><span class="badge ${isFired ? 'badge-cancelled' : 'badge-active'}">${isFired ? 'Звільнений' : 'Працює'}</span></td>
        <td>${st.hireDate || '—'} ${isFired ? `(до ${st.fireDate})` : ''}</td>
        <td>
          ${!isFired ? `
            <div class="flex items-center gap-1">
              <button onclick="openEditStaffModal(${st.staffId})" class="btn btn-secondary btn-sm" title="Редагувати менеджера">
                <i class="fa-solid fa-pen-to-square"></i> Редагувати
              </button>
              <button onclick="quickDismissStaff(${st.staffId})" class="btn btn-danger btn-sm" title="Звільнити співробітника">
                <i class="fa-solid fa-user-xmark"></i> Звільнити
              </button>
            </div>
          ` : '<span class="text-xs text-slate-400">Архівований</span>'}
        </td>
      `;
      tbody.appendChild(row);
    });
  } catch (err) {
    console.warn('Error loading staff table:', err);
  }
}

export async function handleHr1Hire(e) {
  e.preventDefault();
  const fullName = document.getElementById('hr1-fullname').value.trim();
  const phone = document.getElementById('hr1-phone').value.trim();
  const birthDate = document.getElementById('hr1-birthdate').value;
  const specId = parseInt(document.getElementById('hr1-spec').value);
  const dbUser = document.getElementById('hr1-dbuser').value.trim();
  const bio = document.getElementById('hr1-bio').value.trim();

  try {
    const res = await hrApi.hireCoach({
      fullName,
      birthDate,
      phone,
      specId,
      dbUser,
      password: 'coach_pass_123',
      biography: bio
    });

    showToast(`Тренера ${fullName} успішно прийнято на роботу! Код #${res.coachId} (HR1)`, 'success');
    await populateHrDropdowns();
    await renderHrCoachesTable();
    switchHrTab('hr_coaches');
  } catch (err) {
    showToast(`Помилка оформлення тренера: ${err.message}`, 'danger');
  }
}

export async function handleHr3Dismiss(e) {
  e.preventDefault();
  const coachSelect = document.getElementById('hr3-coach');
  const staffId = coachSelect ? parseInt(coachSelect.value) : NaN;
  const fireInput = document.getElementById('hr3-firedate');
  const today = new Date().toISOString().split('T')[0];
  const fireDate = (fireInput && fireInput.value) ? fireInput.value : today;

  try {
    await hrApi.fireEmployee({ staffId, fireDate });
    showToast('Тренера успішно звільнено з клубу (HR3)', 'success');
    await populateHrDropdowns();
    await renderHrCoachesTable();
    switchHrTab('hr_coaches');
  } catch (err) {
    showToast(`Помилка звільнення тренера: ${err.message}`, 'danger');
  }
}

export async function quickDismissCoach(staffId) {
  if (confirm('Підтвердити звільнення тренера? Його обліковий запис у PostgreSQL буде заблоковано.')) {
    try {
      await hrApi.fireEmployee({
        staffId,
        fireDate: new Date().toISOString().split('T')[0]
      });
      showToast('Тренера звільнено! (HR3)', 'success');
      await populateHrDropdowns();
      await renderHrCoachesTable();
    } catch (err) {
      showToast(`Помилка звільнення: ${err.message}`, 'danger');
    }
  }
}

export async function handleHr4Hire(e) {
  e.preventDefault();
  const fullName = document.getElementById('hr4-fullname').value.trim();
  const phone = document.getElementById('hr4-phone').value.trim();
  const birthDate = document.getElementById('hr4-birthdate').value;
  const positionName = document.getElementById('hr4-position').value;
  const dbUser = document.getElementById('hr4-dbuser').value.trim();
  const hireDate = document.getElementById('hr4-hiredate').value;

  try {
    const res = await hrApi.hireManager({
      fullName,
      birthDate,
      phone,
      dbUser,
      password: 'manager_pass_123',
      positionName,
      hireDate
    });

    showToast(`Менеджера ${fullName} успішно прийнято на роботу! Код #${res.staffId} (HR4)`, 'success');
    await populateHrDropdowns();
    await renderHrStaffTable();
    switchHrTab('hr_staff');
  } catch (err) {
    showToast(`Помилка оформлення менеджера: ${err.message}`, 'danger');
  }
}

export async function handleHr6Dismiss(e) {
  e.preventDefault();
  const staffSelect = document.getElementById('hr6-staff');
  const staffId = staffSelect ? parseInt(staffSelect.value) : NaN;
  const fireInput = document.getElementById('hr6-firedate');
  const today = new Date().toISOString().split('T')[0];
  const fireDate = (fireInput && fireInput.value) ? fireInput.value : today;

  try {
    await hrApi.fireEmployee({ staffId, fireDate });
    showToast('Співробітника успішно звільнено (HR6)', 'success');
    await populateHrDropdowns();
    await renderHrStaffTable();
    switchHrTab('hr_staff');
  } catch (err) {
    showToast(`Помилка звільнення співробітника: ${err.message}`, 'danger');
  }
}

export async function quickDismissStaff(staffId) {
  if (confirm('Підтвердити звільнення співробітника?')) {
    try {
      await hrApi.fireEmployee({
        staffId,
        fireDate: new Date().toISOString().split('T')[0]
      });
      showToast('Співробітника звільнено! (HR6)', 'success');
      await populateHrDropdowns();
      await renderHrStaffTable();
    } catch (err) {
      showToast(`Помилка звільнення: ${err.message}`, 'danger');
    }
  }
}
