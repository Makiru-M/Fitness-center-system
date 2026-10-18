/**
 * FitnessClub IS - Coach View (C1 - C5)
 * Pure REST API Implementation
 * Module: views/coachView.js
 */

import { AppState } from '../state/state.js';
import { coachApi } from '../api/coachApi.js';
import { showToast } from '../components/toast.js';

let cachedCoachSchedule = [];

export function switchCoachTab(tabId) {
  document.querySelectorAll('.coach-pane').forEach(el => el.classList.add('hidden'));
  document.querySelectorAll('#view-coach .nav-tab-btn').forEach(b => b.classList.remove('active'));

  const pane = document.getElementById(`subtab-${tabId}`);
  const btn = document.getElementById(`tab-btn-${tabId}`);
  if (pane) pane.classList.remove('hidden');
  if (btn) btn.classList.add('active');
}

export function getActiveCoach() {
  return AppState.currentUser;
}

export async function renderCoachSchedule() {
  const tbody = document.getElementById('coach-schedule-tbody');
  const badgeEl = document.getElementById('coach-active-name-badge');
  if (!tbody) return;

  try {
    const items = await coachApi.getSchedule();
    cachedCoachSchedule = items || [];

    if (badgeEl && AppState.currentUser) {
      badgeEl.innerHTML = `<i class="fa-solid fa-stopwatch mr-1"></i> Тренер: ${AppState.currentUser.name || 'Активний тренер'}`;
    }

    tbody.innerHTML = '';
    if (!cachedCoachSchedule.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center text-xs text-slate-400 py-6">Немає запланованих занять у базі даних</td></tr>';
      return;
    }

    cachedCoachSchedule.forEach(it => {
      const row = document.createElement('tr');
      const isPersonal = it.activityType === 'Personal';
      const isScheduled = (it.status || '').toLowerCase() === 'scheduled';
      row.innerHTML = `
        <td class="font-mono text-xs text-cyan-400">${it.scheduleDate} ${it.startTime || ''}</td>
        <td><span class="badge ${isPersonal ? 'badge-scheduled' : 'badge-active'}">${isPersonal ? 'Персональне' : 'Групове'}</span></td>
        <td><span class="font-bold text-white font-heading">${it.title}</span></td>
        <td>${it.hallName || '—'}</td>
        <td><span class="badge badge-${(it.status || 'Active').toLowerCase()} shrink-0">${it.status}</span></td>
        <td>
          ${isScheduled ? (isPersonal ? `<button onclick="quickMarkC3(${it.activityId})" class="btn btn-primary btn-sm">Відмітити (C3)</button>` : `<button onclick="quickMarkC4(${it.activityId})" class="btn btn-secondary btn-sm">Відмітити (C4)</button>`) : '<span class="text-xs text-slate-400">Завершено</span>'}
        </td>
      `;
      tbody.appendChild(row);
    });

    populateCoachDropdowns();
  } catch (err) {
    console.warn('API Coach schedule error:', err);
  }
}

export function populateCoachDropdowns() {
  // C2 Select
  const c2Select = document.getElementById('c2-class-select');
  if (c2Select) {
    c2Select.innerHTML = '<option value="" disabled selected>-- Оберіть тренування зі списку --</option>';
    cachedCoachSchedule.forEach(it => {
      const opt = document.createElement('option');
      opt.value = `${it.activityType === 'Personal' ? 'pt' : 'gi'}_${it.activityId}`;
      opt.textContent = `[${it.activityType}] ${it.scheduleDate} ${it.startTime || ''}: ${it.title} (${it.hallName || 'Зал'})`;
      c2Select.appendChild(opt);
    });
  }

  // C3 Training (Personal only)
  const c3Train = document.getElementById('c3-training');
  if (c3Train) {
    c3Train.innerHTML = '';
    cachedCoachSchedule.filter(it => it.activityType === 'Personal' && it.status === 'Scheduled').forEach(it => {
      const opt = document.createElement('option');
      opt.value = it.activityId;
      opt.textContent = `${it.scheduleDate} ${it.startTime || ''} — ${it.title}`;
      c3Train.appendChild(opt);
    });
  }

  // C4 Instance (Group only)
  const c4Inst = document.getElementById('c4-instance');
  if (c4Inst) {
    c4Inst.innerHTML = '';
    cachedCoachSchedule.filter(it => it.activityType === 'Group' && it.status === 'Scheduled').forEach(it => {
      const opt = document.createElement('option');
      opt.value = it.activityId;
      opt.textContent = `${it.title} (${it.scheduleDate} о ${it.startTime || ''})`;
      c4Inst.appendChild(opt);
    });
  }

  // C5 Training
  const c5Train = document.getElementById('c5-training');
  if (c5Train) {
    c5Train.innerHTML = '';
    cachedCoachSchedule.filter(it => it.activityType === 'Personal' && it.status === 'Scheduled').forEach(it => {
      const opt = document.createElement('option');
      opt.value = it.activityId;
      opt.textContent = `${it.scheduleDate} ${it.startTime || ''} — ${it.title}`;
      c5Train.appendChild(opt);
    });
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 2);
    tomorrow.setHours(14, 0, 0, 0);
    const c5Dt = document.getElementById('c5-newtime');
    if (c5Dt) c5Dt.value = tomorrow.toISOString().substring(0, 16);
  }
}

export async function renderC2ClientList(val) {
  const tbody = document.getElementById('coach-clients-tbody');
  if (!tbody || !val) return;
  tbody.innerHTML = '<tr><td colspan="4" class="text-center text-xs text-slate-400 py-4"><i class="fa-solid fa-spinner fa-spin mr-1"></i> Завантаження списку клієнтів...</td></tr>';

  const [type, idStr] = val.split('_');
  const id = parseInt(idStr);

  try {
    let participants = [];
    if (type === 'pt') {
      participants = await coachApi.getPersonalClient(id);
    } else {
      participants = await coachApi.getGroupParticipants(id);
    }

    tbody.innerHTML = '';
    if (!participants || !participants.length) {
      tbody.innerHTML = '<tr><td colspan="4" class="text-center text-xs text-slate-400 py-4">Немає записаних клієнтів</td></tr>';
      return;
    }

function isTrivialMedNotes(str) {
  if (!str) return true;
  const s = str.trim().toLowerCase();
  return s === '' || s === 'none' || s === '-' || s === 'немає' || s === 'немає обмежень' || s === 'відсутні' || s === 'обмежень немає';
}

    participants.forEach(p => {
      const row = document.createElement('tr');
      const hasMed = p.medicalNotes && p.medicalNotes.trim() && !isTrivialMedNotes(p.medicalNotes);
      row.innerHTML = `
        <td class="font-bold text-white font-heading">${p.clientName || 'Клієнт'}</td>
        <td class="font-mono text-xs text-slate-300">${p.phone || '—'}</td>
        <td>
          ${hasMed ? `
            <span class="badge-medical-alert max-w-[170px] truncate" title="${p.medicalNotes}">
              <i class="fa-solid fa-notes-medical text-rose-400 mr-1 flex-shrink-0"></i>
              <span class="truncate">${p.medicalNotes}</span>
            </span>
          ` : `
            <span class="badge-medical-none">
              <i class="fa-solid fa-circle-check text-slate-400 mr-1"></i> Відсутні
            </span>
          `}
        </td>
        <td><span class="badge badge-${(p.bookingStatus || 'active').toLowerCase()} shrink-0">${p.bookingStatus || 'Active'}</span></td>
      `;
      tbody.appendChild(row);
    });
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="4" class="text-center text-xs text-rose-500 py-4">Помилка завантаження: ${err.message}</td></tr>`;
  }
}

export function quickMarkC3(ptId) {
  switchCoachTab('c3');
  const sel = document.getElementById('c3-training');
  if (sel) sel.value = ptId;
}

export function quickMarkC4(giId) {
  switchCoachTab('c4');
  const sel = document.getElementById('c4-instance');
  if (sel) sel.value = giId;
}

export async function handleC3Mark(e) {
  e.preventDefault();
  const ptId = parseInt(document.getElementById('c3-training').value);
  const status = document.getElementById('c3-status').value;

  if (!ptId) {
    showToast('Оберіть тренування для відмітки', 'warning');
    return;
  }

  try {
    await coachApi.markPersonalTraining(ptId, { status, comment: '' });
    showToast(`Результат індивідуального тренування зафіксовано як '${status}'! (C3)`, 'success');
    await renderCoachSchedule();
    switchCoachTab('c1');
  } catch (err) {
    showToast(`Помилка оновлення статусу: ${err.message}`, 'danger');
  }
}

export async function handleC4Mark(e) {
  e.preventDefault();
  const giId = parseInt(document.getElementById('c4-instance').value);
  const status = document.getElementById('c4-status').value;
  const attendance = parseInt(document.getElementById('c4-attendance').value || '0');

  if (!giId) {
    showToast('Оберіть групове заняття', 'warning');
    return;
  }

  try {
    await coachApi.markGroupClass(giId, { status, actualAttendance: attendance });
    showToast(`Групове заняття відмічено: ${status}, присутніх: ${attendance} (C4)`, 'success');
    await renderCoachSchedule();
    switchCoachTab('c1');
  } catch (err) {
    showToast(`Помилка оновлення заняття: ${err.message}`, 'danger');
  }
}

export function toggleC5NewTime(type) {
  const container = document.getElementById('c5-newtime-container');
  if (type === 'Reschedule') {
    if (container) container.classList.remove('hidden');
  } else {
    if (container) container.classList.add('hidden');
  }
}

export async function handleC5Request(e) {
  e.preventDefault();
  const ptId = parseInt(document.getElementById('c5-training').value);
  const type = document.getElementById('c5-type').value;
  const reason = document.getElementById('c5-reason').value.trim();

  if (!ptId) {
    showToast('Оберіть тренування для запиту', 'warning');
    return;
  }

  const newTime = type === 'Reschedule' ? document.getElementById('c5-newtime').value : null;

  try {
    await coachApi.requestScheduleChange({
      personalId: ptId,
      requestType: type,
      reason,
      newDateTime: newTime
    });
    showToast(`Запит на ${type === 'Reschedule' ? 'перенесення' : 'скасування'} надіслано менеджеру! (C5)`, 'success');
    await renderCoachSchedule();
    switchCoachTab('c1');
  } catch (err) {
    showToast(`Помилка надсилання запиту: ${err.message}`, 'danger');
  }
}
