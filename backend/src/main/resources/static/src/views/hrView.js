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
  let btn = document.getElementById(`tab-btn-${norm}`) || document.getElementById(`tab-btn-${tabId}`);
  if (!btn) {
    if (norm === 'hr1' || norm === 'hr3') {
      btn = document.getElementById('tab-btn-hr-coaches');
    } else if (norm === 'hr4' || norm === 'hr6') {
      btn = document.getElementById('tab-btn-hr-staff');
    }
  }
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
// hr1-hiredate removed (auto-assigned today)
    }

    // Coaches for HR3 (Dismiss)
    const hr3Coach = document.getElementById('hr3-coach');
    if (hr3Coach) {
      hr3Coach.innerHTML = '<option value="" disabled selected>-- Оберіть тренера для звільнення --</option>';
      const currentDbUser = AppState.currentUser?.dbUser || AppState.user?.username;
      const currentStaffId = AppState.currentUser?.staffId || AppState.currentUser?.entityId || AppState.user?.profile?.staffId;
      const activeCoaches = cachedEmployees.filter(e => {
        if (!e.isCoach || !e.isActive) return false;
        if (currentDbUser && e.dbUser === currentDbUser) return false;
        if (currentStaffId && e.staffId === currentStaffId) return false;
        return true;
      });
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
        <option value="Менеджер клієнтів" selected>Менеджер клієнтів</option>
        <option value="HR Менеджер">HR Менеджер</option>
        <option value="Директор">Директор клубу</option>
      `;
// hr4-hiredate removed (auto-assigned today)
    }

    // Staff for HR6
    const hr6Staff = document.getElementById('hr6-staff');
    if (hr6Staff) {
      hr6Staff.innerHTML = '<option value="" disabled selected>-- Оберіть співробітника для звільнення --</option>';
      const currentDbUser = AppState.currentUser?.dbUser || AppState.user?.username;
      const currentStaffId = AppState.currentUser?.staffId || AppState.currentUser?.entityId || AppState.user?.profile?.staffId;
      const activeStaff = cachedEmployees.filter(e => {
        if (e.isCoach || !e.isActive) return false;
        if (currentDbUser && e.dbUser === currentDbUser) return false;
        if (currentStaffId && e.staffId === currentStaffId) return false;
        return true;
      });
      activeStaff.forEach(st => {
        const opt = document.createElement('option');
        opt.value = st.staffId;
        opt.textContent = `${st.fullName} [${st.positionName || 'Персонал'}]`;
        hr6Staff.appendChild(opt);
      });
      refreshCombobox(hr6Staff);
    }
    const hr6Fire = document.getElementById('hr6-firedate');
    if (hr6Fire) hr6Fire.value = today;
  } catch (err) {
    console.warn('Error populating HR dropdowns:', err);
  }
}

export async function renderHrCoachesTable(searchTerm = '') {
  const tbody = document.getElementById('hr-coaches-tbody');
  if (!tbody) return;

  try {
    if (!cachedEmployees || !cachedEmployees.length || searchTerm === '') {
      cachedEmployees = await hrApi.getEmployees();
    }
    tbody.innerHTML = '';

    let coaches = (cachedEmployees || []).filter(e => e.isCoach);
    const term = (typeof searchTerm === 'string' ? searchTerm : '').trim().toLowerCase();
    if (term) {
      coaches = coaches.filter(c => 
        (c.fullName && c.fullName.toLowerCase().includes(term)) ||
        (c.phone && c.phone.toLowerCase().includes(term))
      );
    }

    if (!coaches.length) {
      tbody.innerHTML = term 
        ? `<tr><td colspan="7" class="text-center text-xs text-slate-400 py-6">Тренерів не знайдено за запитом "${term}"</td></tr>`
        : '<tr><td colspan="7" class="text-center text-xs text-slate-400 py-6">Немає зареєстрованих тренерів</td></tr>';
      return;
    }

    const currentDbUser = AppState.currentUser?.dbUser || AppState.user?.username;
    const currentStaffId = AppState.currentUser?.staffId || AppState.currentUser?.entityId || AppState.user?.profile?.staffId;

    coaches.forEach(c => {
      const row = document.createElement('tr');
      const isFired = !c.isActive || !!c.fireDate;
      const isSelf = Boolean(
        (currentDbUser && c.dbUser && c.dbUser === currentDbUser) ||
        (currentStaffId && c.staffId === currentStaffId)
      );
      row.innerHTML = `
        <td class="font-mono text-xs text-slate-400">#${c.coachId || c.staffId}</td>
        <td class="font-bold text-white font-heading">${c.fullName}</td>
        <td class="font-mono text-xs text-slate-300">${c.phone}</td>
        <td><span class="badge badge-scheduled shrink-0">${c.specName || 'Тренер'}</span></td>
        <td><span class="badge ${isFired ? 'badge-cancelled' : 'badge-active'} shrink-0">${isFired ? 'Звільнений' : 'Працює'}</span></td>
        <td>${c.hireDate || '—'} ${isFired ? `(до ${c.fireDate})` : ''}</td>
        <td>
          ${!isFired ? `
            <div class="flex items-center gap-1">
              <button onclick="openEditCoachModal(${c.coachId || c.staffId})" class="btn btn-secondary btn-sm" title="Редагувати тренера">
                <i class="fa-solid fa-pen-to-square"></i> Редагувати
              </button>
              ${isSelf ? `
                <button class="btn btn-secondary btn-sm opacity-50 cursor-not-allowed" disabled title="Неможливо звільнити себе">
                  <i class="fa-solid fa-ban mr-1"></i> Ви
                </button>
              ` : `
                <button onclick="quickDismissCoach(${c.staffId})" class="btn btn-secondary-cyan btn-sm" title="Звільнити тренера">
                  <i class="fa-solid fa-user-xmark"></i> Звільнити
                </button>
              `}
            </div>
          ` : '<span class="text-xs text-slate-500">—</span>'}
        </td>
      `;
      tbody.appendChild(row);
    });
  } catch (err) {
    console.warn('Error loading coaches table:', err);
  }
}

export function filterHrCoaches(term = null) {
  let search = '';
  if (typeof term === 'string') {
    search = term;
  } else if (term && typeof term === 'object' && term.target) {
    search = term.target.value || '';
  } else {
    search = document.getElementById('hr-coaches-search')?.value || '';
  }
  renderHrCoachesTable(search.trim());
}

export async function renderHrStaffTable(searchTerm = '') {
  const tbody = document.getElementById('hr-staff-tbody');
  if (!tbody) return;

  try {
    if (!cachedEmployees || !cachedEmployees.length || searchTerm === '') {
      cachedEmployees = await hrApi.getEmployees();
    }
    tbody.innerHTML = '';

    let staffMembers = (cachedEmployees || []).filter(e => !e.isCoach);
    const term = (typeof searchTerm === 'string' ? searchTerm : '').trim().toLowerCase();
    if (term) {
      staffMembers = staffMembers.filter(st => 
        (st.fullName && st.fullName.toLowerCase().includes(term)) ||
        (st.phone && st.phone.toLowerCase().includes(term))
      );
    }

    if (!staffMembers.length) {
      tbody.innerHTML = term
        ? `<tr><td colspan="7" class="text-center text-xs text-slate-400 py-6">Співробітників не знайдено за запитом "${term}"</td></tr>`
        : '<tr><td colspan="7" class="text-center text-xs text-slate-400 py-6">Немає зареєстрованого адміністративного персоналу</td></tr>';
      return;
    }

    const currentDbUser = AppState.currentUser?.dbUser || AppState.user?.username;
    const currentStaffId = AppState.currentUser?.staffId || AppState.currentUser?.entityId || AppState.user?.profile?.staffId;

    staffMembers.forEach(st => {
      const row = document.createElement('tr');
      const isFired = !st.isActive || !!st.fireDate;
      const isSelf = Boolean(
        (currentDbUser && st.dbUser && st.dbUser === currentDbUser) ||
        (currentStaffId && st.staffId === currentStaffId)
      );
      row.innerHTML = `
        <td class="font-mono text-xs text-slate-400">#${st.staffId}</td>
        <td class="font-bold text-white font-heading">${st.fullName}</td>
        <td class="font-mono text-xs text-slate-300">${st.phone}</td>
        <td><span class="badge badge-neutral shrink-0">${st.positionName || 'Менеджер'}</span></td>
        <td><span class="badge ${isFired ? 'badge-cancelled' : 'badge-active'} shrink-0">${isFired ? 'Звільнений' : 'Працює'}</span></td>
        <td>${st.hireDate || '—'} ${isFired ? `(до ${st.fireDate})` : ''}</td>
        <td>
          ${!isFired ? `
            <div class="flex items-center gap-1">
              <button onclick="openEditStaffModal(${st.staffId})" class="btn btn-secondary btn-sm" title="Редагувати менеджера">
                <i class="fa-solid fa-pen-to-square"></i> Редагувати
              </button>
              ${isSelf ? `
                <button class="btn btn-secondary btn-sm opacity-50 cursor-not-allowed" disabled title="Неможливо звільнити себе">
                  <i class="fa-solid fa-ban mr-1"></i> Ви
                </button>
              ` : `
                <button onclick="quickDismissStaff(${st.staffId})" class="btn btn-secondary-cyan btn-sm" title="Звільнити співробітника">
                  <i class="fa-solid fa-user-xmark"></i> Звільнити
                </button>
              `}
            </div>
          ` : '<span class="text-xs text-slate-500">—</span>'}
        </td>
      `;
      tbody.appendChild(row);
    });
  } catch (err) {
    console.warn('Error loading staff table:', err);
  }
}

export function filterHrStaff(term = null) {
  let search = '';
  if (typeof term === 'string') {
    search = term;
  } else if (term && typeof term === 'object' && term.target) {
    search = term.target.value || '';
  } else {
    search = document.getElementById('hr-staff-search')?.value || '';
  }
  renderHrStaffTable(search.trim());
}

export async function handleHr1Hire(e) {
  e.preventDefault();
  const fullName = document.getElementById('hr1-fullname').value.trim();
  const phone = document.getElementById('hr1-phone').value.trim();
  const birthDate = document.getElementById('hr1-birthdate').value;
  const specId = parseInt(document.getElementById('hr1-spec').value);
  const dbUser = document.getElementById('hr1-dbuser').value.trim();
  const password = document.getElementById('hr1-password').value;
  const bio = document.getElementById('hr1-bio').value.trim();
  const hireDate = new Date().toISOString().split('T')[0];

  try {
    const res = await hrApi.hireCoach({
      fullName,
      birthDate,
      phone,
      specId,
      dbUser,
      password,
      biography: bio,
      hireDate
    });

    showToast(`Тренера ${fullName} успішно прийнято на роботу! Код #${res.coachId} (HR1)`, 'success');
    const form1 = document.getElementById('form-hr1-hire');
    if (form1) form1.reset();
    const searchCoach = document.getElementById('hr-coaches-search');
    if (searchCoach) searchCoach.value = '';
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
  const password = document.getElementById('hr4-password').value;
  const hireDate = new Date().toISOString().split('T')[0];

  try {
    const res = await hrApi.hireManager({
      fullName,
      birthDate,
      phone,
      dbUser,
      password,
      positionName,
      hireDate
    });

    showToast(`Менеджера ${fullName} успішно прийнято на роботу! Код #${res.staffId} (HR4)`, 'success');
    const form4 = document.getElementById('form-hr4-hire');
    if (form4) form4.reset();
    const searchStaff = document.getElementById('hr-staff-search');
    if (searchStaff) searchStaff.value = '';
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
