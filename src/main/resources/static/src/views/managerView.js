/**
 * FitnessClub IS - Manager View (M1 - M8)
 * Pure REST API Implementation
 * Module: views/managerView.js
 */

import { AppState, findPromo, TEST_ACCOUNTS } from '../state/state.js';
import { managerApi } from '../api/managerApi.js';
import { guestApi } from '../api/guestApi.js';
import { hrApi } from '../api/hrApi.js';
import { showToast } from '../components/toast.js';
import { refreshCombobox } from '../components/combobox.js';

export let cachedClients = [];
let cachedPriceList = [];
let recentVisits = [];

export function switchManagerTab(tabId) {
  document.querySelectorAll('.manager-pane').forEach(el => el.classList.add('hidden'));
  document.querySelectorAll('#view-manager .nav-tab-btn').forEach(b => b.classList.remove('active'));

  const pane = document.getElementById(`subtab-${tabId}`);
  const btn = document.getElementById(`tab-btn-${tabId}`);
  if (pane) pane.classList.remove('hidden');
  if (btn) btn.classList.add('active');

  if (tabId === 'm8') {
    renderM8Requests();
  }
}

export async function populateManagerDropdowns() {
  try {
    const [clients, halls, items, coaches, employees] = await Promise.all([
      managerApi.getClients(),
      guestApi.getHalls(),
      guestApi.getPriceList(),
      guestApi.getCoaches(),
      hrApi.getEmployees()
    ]);

    cachedClients = clients || [];
    cachedPriceList = items || [];

    // Clients selects (m4, m3, m5, m6, m7)
    const clientSelects = ['m4-client', 'm3-client', 'm5-client', 'm6-client', 'm7-client'];
    clientSelects.forEach(selId => {
      const sel = document.getElementById(selId);
      if (!sel) return;
      sel.innerHTML = '<option value="" disabled selected>-- Оберіть клієнта --</option>';
      cachedClients.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c.clientId;
        opt.textContent = `${c.fullName} (${c.phone})`;
        sel.appendChild(opt);
      });
      refreshCombobox(sel);
    });

    const m4ClientSel = document.getElementById('m4-client');
    if (m4ClientSel && !m4ClientSel.dataset.hasPreviewListener) {
      m4ClientSel.addEventListener('change', (e) => previewM4ClientStatus(e.target.value));
      m4ClientSel.dataset.hasPreviewListener = 'true';
    }
    previewM4ClientStatus();

    // Halls selects (m4, m6)
    const hallSelects = ['m4-hall', 'm6-hall'];
    hallSelects.forEach(selId => {
      const sel = document.getElementById(selId);
      if (!sel) return;
      sel.innerHTML = '';
      halls.forEach(h => {
        const opt = document.createElement('option');
        opt.value = h.hallId;
        opt.textContent = `${h.hallName} (Місткість: ${h.maxCapacity})`;
        sel.appendChild(opt);
      });
    });

    // PriceList items for M3
    const m3Item = document.getElementById('m3-item');
    if (m3Item) {
      m3Item.innerHTML = '';
      cachedPriceList.forEach(item => {
        const opt = document.createElement('option');
        opt.value = item.itemId;
        opt.textContent = `[${item.category}] ${item.itemName} — ${parseFloat(item.price).toFixed(2)} грн`;
        m3Item.appendChild(opt);
      });
      const sDate = document.getElementById('m3-startdate');
      if (sDate) sDate.value = new Date().toISOString().split('T')[0];
      updateM3Price();
    }

    // Managers for M3 (#m3-staff / #m3-manager)
    const m3StaffSelects = [document.getElementById('m3-staff'), document.getElementById('m3-manager')].filter(Boolean);
    if (m3StaffSelects.length > 0) {
      // Filter list of employees: keep ONLY Customer Managers (no Directors, no HR Managers)
      const managers = (employees || []).filter(e => {
        // Exclude coaches and inactive employees
        if (e.isCoach || !e.isActive) return false;

        // Retrieve position (accounting for TEST_ACCOUNTS role/position mapping)
        const testAcc = (TEST_ACCOUNTS && e.dbUser) ? TEST_ACCOUNTS[e.dbUser] : null;
        const pos = (testAcc ? testAcc.pos : (e.positionName || e.pos || '')).trim();
        const lowerPos = pos.toLowerCase();

        // Categorically exclude Director and HR Manager
        if (pos.includes('Директор') || pos.includes('HR') || lowerPos.includes('директор') || lowerPos.includes('hr') || lowerPos.includes('director')) {
          return false;
        }

        // Keep ONLY customer/client managers
        return pos === 'Менеджер клієнтів' || 
               pos === 'Менеджер' || 
               lowerPos.includes('клієнт') || 
               lowerPos.includes('менеджер') ||
               (!e.isCoach && !pos.includes('Директор') && !pos.includes('HR'));
      });

      m3StaffSelects.forEach(sel => {
        sel.innerHTML = '';
        managers.forEach(st => {
          const testAcc = (TEST_ACCOUNTS && st.dbUser) ? TEST_ACCOUNTS[st.dbUser] : null;
          const displayPos = testAcc ? testAcc.pos : (st.positionName || st.pos || 'Менеджер клієнтів');
          const opt = document.createElement('option');
          opt.value = st.staffId;
          opt.textContent = `${st.fullName} (${displayPos})`;
          sel.appendChild(opt);
        });

        // If current authenticated user is in the list, select them by default
        if (AppState.currentUser) {
          const currentUserId = AppState.currentUser.entityId || AppState.currentUser.staffId;
          const currentDbUser = AppState.currentUser.dbUser;
          const matchingStaff = managers.find(m => 
            (currentUserId && Number(m.staffId) === Number(currentUserId)) || 
            (currentDbUser && m.dbUser === currentDbUser)
          );
          if (matchingStaff) {
            sel.value = matchingStaff.staffId;
          }
        }
      });
    }

    // Coaches for M6
    const m6Coach = document.getElementById('m6-coach');
    if (m6Coach) {
      m6Coach.innerHTML = '<option value="" disabled selected>-- Оберіть тренера --</option>';
      coaches.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c.coachId;
        opt.textContent = `${c.fullName} (${c.specName || 'Тренер'})`;
        m6Coach.appendChild(opt);
      });
      refreshCombobox(m6Coach);
      const tmr = new Date();
      tmr.setDate(tmr.getDate() + 1);
      tmr.setHours(10, 0, 0, 0);
      const m6Dt = document.getElementById('m6-datetime');
      if (m6Dt) m6Dt.value = tmr.toISOString().substring(0, 16);
    }
  } catch (err) {
    console.warn('Error populating manager dropdowns:', err);
  }
}

export function previewM4ClientStatus(val) {
  const clientSelect = document.getElementById('m4-client');
  const clientId = parseInt(val || clientSelect?.value || '0', 10);
  const subNameEl = document.getElementById('m4-sub-name');
  const subStatusEl = document.getElementById('m4-sub-status');
  const subEndEl = document.getElementById('m4-sub-end');
  const medAlertEl = document.getElementById('m4-med-alert');
  const frozenAlertEl = document.getElementById('m4-frozen-alert');
  const checkinBtn = document.getElementById('m4-checkin-btn') || document.querySelector('#form-m4-checkin button[type="submit"]');

  if (!clientId || isNaN(clientId)) {
    if (subNameEl) subNameEl.textContent = '—';
    if (subStatusEl) {
      subStatusEl.textContent = '—';
      subStatusEl.className = 'badge badge-expired';
    }
    if (subEndEl) subEndEl.textContent = '—';
    if (medAlertEl) {
      medAlertEl.classList.add('hidden');
      medAlertEl.innerHTML = '';
    }
    if (frozenAlertEl) {
      frozenAlertEl.classList.add('hidden');
    }
    if (checkinBtn) {
      checkinBtn.disabled = false;
      checkinBtn.title = '';
    }
    return;
  }

  const client = cachedClients.find(c => c.clientId === clientId);
  if (!client) return;

  const status = client.activeSubStatus || 'None';
  const isSubActive = status.toLowerCase() === 'active';
  const isSubFrozen = status.toLowerCase() === 'frozen';

  if (subNameEl) {
    subNameEl.textContent = client.activeSubName || 'Відсутній';
  }

  if (subStatusEl) {
    if (isSubActive) {
      subStatusEl.textContent = 'Active';
      subStatusEl.className = 'badge badge-active';
    } else if (isSubFrozen) {
      subStatusEl.textContent = 'Frozen';
      subStatusEl.className = 'badge badge-cyan';
    } else if (status === 'Expired') {
      subStatusEl.textContent = 'Expired';
      subStatusEl.className = 'badge badge-expired';
    } else {
      subStatusEl.textContent = 'Немає';
      subStatusEl.className = 'badge badge-expired';
    }
  }

  if (subEndEl) {
    subEndEl.textContent = client.activeSubEndDate || '—';
  }

  // Handle frozen warning & checkin submit button
  if (frozenAlertEl) {
    if (isSubFrozen) {
      frozenAlertEl.classList.remove('hidden');
    } else {
      frozenAlertEl.classList.add('hidden');
    }
  }

  if (checkinBtn) {
    if (isSubFrozen) {
      checkinBtn.disabled = true;
      checkinBtn.title = 'Вхід заблоковано: абонемент клієнта заморожено';
    } else {
      checkinBtn.disabled = false;
      checkinBtn.title = '';
    }
  }

  if (medAlertEl) {
    const hasMed = client.medicalNotes && !isTrivialMedNotes(client.medicalNotes);
    if (hasMed) {
      medAlertEl.classList.remove('hidden');
      medAlertEl.innerHTML = `<i class="fa-solid fa-notes-medical text-rose-400 mr-1.5"></i> <b>Застереження:</b> ${escapeHtml(client.medicalNotes)}`;
    } else {
      medAlertEl.classList.add('hidden');
      medAlertEl.innerHTML = '';
    }
  }
}

export async function handleM4CheckIn(e) {
  e.preventDefault();
  const clientId = parseInt(document.getElementById('m4-client').value);
  const hallId = parseInt(document.getElementById('m4-hall').value);

  if (!clientId || !hallId) {
    showToast('Оберіть клієнта та зал для фіксації візиту', 'warning');
    return;
  }

  const client = cachedClients.find(c => c.clientId === clientId);
  if (client && (client.activeSubStatus || '').toLowerCase() === 'frozen') {
    showToast('Вхід заблоковано: абонемент клієнта заморожено. Для відвідування необхідно розморозити абонемент.', 'danger');
    return;
  }

  try {
    const result = await managerApi.checkIn(clientId, hallId);
    showToast(`Візит #${result.visitId} успішно зафіксовано для ${result.clientName}! (M4)`, 'success');

    recentVisits.unshift({
      id: result.visitId,
      clientName: result.clientName,
      hallName: result.hallName,
      time: new Date().toLocaleTimeString(),
      status: result.subscriptionStatus
    });

    renderM4VisitsTable();
  } catch (err) {
    showToast(`Помилка пропуску: ${err.message}`, 'danger');
  }
}

export function renderM4VisitsTable() {
  const tbody = document.getElementById('m4-visits-tbody');
  if (!tbody) return;

  if (!recentVisits.length) {
    tbody.innerHTML = '<tr><td colspan="5" class="text-center text-xs text-slate-400 py-4">Сьогодні ще не зареєстровано візитів на турнікеті</td></tr>';
    return;
  }

  tbody.innerHTML = '';
  recentVisits.forEach(v => {
    const row = document.createElement('tr');
    row.innerHTML = `
      <td class="font-mono text-xs text-slate-400">#${v.id}</td>
      <td class="font-bold text-white font-heading">${v.clientName}</td>
      <td>${v.hallName}</td>
      <td class="font-mono text-xs text-cyan-400">${v.time}</td>
      <td><span class="badge badge-active">${v.status || 'Active'}</span></td>
    `;
    tbody.appendChild(row);
  });
}

export async function handleM1NewClient(e) {
  e.preventDefault();
  const fullName = document.getElementById('m1-fullname').value.trim();
  const phone = document.getElementById('m1-phone').value.trim();
  const birthDate = document.getElementById('m1-birthdate').value;
  const gender = document.getElementById('m1-gender').value;
  const dbUser = document.getElementById('m1-dbuser')?.value.trim() || '';
  const password = document.getElementById('m1-password')?.value || '';
  const medNotes = document.getElementById('m1-mednotes').value.trim();

  const loginRegex = /^[a-zA-Z0-9_]{3,30}$/;
  if (!loginRegex.test(dbUser)) {
    showToast("Логін має містити від 3 до 30 символів (лише латинські літери, цифри та '_')", 'warning');
    return;
  }

  if (!password || password.length < 4) {
    showToast("Пароль повинен містити не менше 4 символів", 'warning');
    return;
  }

  try {
    await managerApi.registerClient({
      fullName,
      birthDate,
      phone,
      gender,
      dbUser,
      password,
      medicalNotes: medNotes || null
    });

    showToast(`Клієнта ${fullName} успішно зареєстровано (Логін: ${dbUser})! (M1)`, 'success');
    document.getElementById('form-m1-newclient')?.reset();
    await populateManagerDropdowns();
    await renderM2ClientsTable();
    switchManagerTab('m2');
  } catch (err) {
    showToast(`Помилка реєстрації клієнта: ${err.message}`, 'danger');
  }
}

function escapeHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function isTrivialMedNotes(str) {
  if (!str) return true;
  const s = str.trim().toLowerCase();
  return s === '' || s === 'none' || s === '-' || s === 'немає' || s === 'немає обмежень' || s === 'відсутні' || s === 'обмежень немає';
}

export async function renderM2ClientsTable(searchTerm = '') {
  const tbody = document.getElementById('m2-clients-tbody');
  if (!tbody) return;

  try {
    const clients = await managerApi.getClients(searchTerm);
    cachedClients = clients || [];

    tbody.innerHTML = '';
    if (!cachedClients.length) {
      tbody.innerHTML = '<tr><td colspan="7" class="text-center text-xs text-slate-400 py-6">Клієнтів не знайдено за заданим критерієм</td></tr>';
      return;
    }

    cachedClients.forEach(c => {
      const isSubActive = (c.activeSubStatus || '').toLowerCase() === 'active';
      const hasMedNotes = c.medicalNotes && c.medicalNotes.trim() && !isTrivialMedNotes(c.medicalNotes);
      const row = document.createElement('tr');
      row.innerHTML = `
        <td class="font-mono text-xs text-slate-400">#${c.clientId}</td>
        <td>
          <span class="font-bold text-white font-heading text-sm block leading-snug">${c.fullName}</span>
        </td>
        <td class="font-mono text-xs text-slate-300">${c.phone}</td>
        <td>
          ${c.activeSubName ? `
            <span class="font-semibold text-xs text-cyan-300 block">${c.activeSubName}</span>
            <span class="block text-[10px] text-slate-400 font-mono">до ${c.activeSubEndDate || '—'}</span>
          ` : '<span class="text-xs text-slate-500 font-mono">Немає</span>'}
        </td>
        <td>
          <span class="badge ${isSubActive ? 'badge-active' : 'badge-expired'}">${c.activeSubStatus || 'Немає'}</span>
        </td>
        <td>
          ${hasMedNotes ? `
            <span class="badge-medical-alert max-w-[170px] truncate" title="${c.medicalNotes}">
              <i class="fa-solid fa-notes-medical text-rose-400 mr-1 flex-shrink-0"></i>
              <span class="truncate">${c.medicalNotes}</span>
            </span>
          ` : `
            <span class="badge-medical-none">
              <i class="fa-solid fa-circle-check text-slate-400 mr-1"></i> Відсутні
            </span>
          `}
        </td>
        <td>
          <button onclick="openEditClientModal(${c.clientId})" class="btn btn-secondary btn-sm" title="Редагувати профіль клієнта">
            <i class="fa-solid fa-user-pen mr-1 text-cyan-400"></i> Редагувати
          </button>
        </td>
      `;
      tbody.appendChild(row);
    });
  } catch (err) {
    console.warn('Error loading clients table:', err);
  }
}

export function filterM2Clients(term = null) {
  let search = '';
  if (typeof term === 'string') {
    search = term;
  } else if (term && typeof term === 'object' && term.target) {
    search = term.target.value || '';
  } else {
    search = document.getElementById('m2-search-input')?.value || document.getElementById('m2-search')?.value || '';
  }
  renderM2ClientsTable(search.trim());
}

export function updateM3Price() {
  const itemId = parseInt(document.getElementById('m3-item')?.value);
  const display = document.getElementById('m3-price-display');
  const promoInput = document.getElementById('m3-promo')?.value.trim().toUpperCase() || '';
  if (!display) return;

  const item = cachedPriceList.find(p => p.itemId === itemId);
  if (!item) return;

  let price = parseFloat(item.price);
  const promo = findPromo(promoInput);
  const now = new Date().toISOString().split('T')[0];
  if (promo && !(promo.expiryDate && promo.expiryDate < now)) {
    price = (price * (100 - promo.discountPercent)) / 100;
  }
  display.textContent = `${price.toFixed(2)} грн`;
}

export function checkM3Promo() {
  const code = document.getElementById('m3-promo')?.value.trim().toUpperCase();
  if (!code) {
    showToast('Введіть промокод', 'warning');
    updateM3Price();
    return;
  }

  const promo = findPromo(code);
  const now = new Date().toISOString().split('T')[0];

  if (!promo) {
    showToast('Промокод не знайдено або термін його дії вичерпано', 'warning');
    updateM3Price();
    return;
  }

  if (promo.expiryDate && promo.expiryDate < now) {
    showToast('Термін дії промокоду вичерпано!', 'warning');
    updateM3Price();
    return;
  }

  showToast(`Промокод ${code} на ${promo.discountPercent}% успішно застосовано!`, 'success');
  updateM3Price();
}

export async function handleM3Sale(e) {
  e.preventDefault();
  const clientId = parseInt(document.getElementById('m3-client').value);
  const itemId = parseInt(document.getElementById('m3-item').value);
  const startDate = document.getElementById('m3-startdate').value;
  const promoCode = document.getElementById('m3-promo').value.trim().toUpperCase() || null;
  const managerId = parseInt((document.getElementById('m3-staff') || document.getElementById('m3-manager'))?.value || '1');

  if (promoCode) {
    const promo = findPromo(promoCode);
    const now = new Date().toISOString().split('T')[0];
    if (promo && promo.expiryDate && promo.expiryDate < now) {
      showToast('Термін дії промокоду вичерпано!', 'warning');
      return;
    }
  }

  try {
    const res = await managerApi.sellSubscription({
      clientId,
      itemId,
      startDate,
      promoCode,
      managerId
    });

    showToast(`Абонемент успішно оформлено! Чек #${res.saleId} (M3)`, 'success');
    await populateManagerDropdowns();
    await renderM2ClientsTable();
    switchManagerTab('m2');
  } catch (err) {
    showToast(`Помилка продажу абонемента: ${err.message}`, 'danger');
  }
}

export async function handleM5Booking(e) {
  e.preventDefault();
  const clientId = parseInt(document.getElementById('m5-client').value);
  const instanceId = parseInt(document.getElementById('m5-instance')?.value || '1');

  try {
    await managerApi.bookGroupClass(clientId, instanceId);
    showToast('Клієнта успішно записано на групове тренування! (M5)', 'success');
    switchManagerTab('m2');
  } catch (err) {
    showToast(`Помилка запису: ${err.message}`, 'danger');
  }
}

export function checkM6MedicalAlert() {
  const clientId = parseInt(document.getElementById('m6-client')?.value);
  const alertEl = document.getElementById('m6-med-alert');
  if (!alertEl || !clientId) return;

  const client = cachedClients.find(c => c.clientId === clientId);
  if (client && client.medicalNotes) {
    alertEl.classList.remove('hidden');
    alertEl.innerHTML = `<i class="fa-solid fa-triangle-exclamation mr-1"></i> Увага тренеру: ${client.medicalNotes}`;
  } else {
    alertEl.classList.add('hidden');
  }
}

export async function handleM6Booking(e) {
  e.preventDefault();
  const clientId = parseInt(document.getElementById('m6-client').value);
  const coachId = parseInt(document.getElementById('m6-coach').value);
  const hallId = parseInt(document.getElementById('m6-hall').value);
  const dateTime = document.getElementById('m6-datetime').value;

  try {
    const res = await managerApi.bookPersonalTraining(clientId, coachId, hallId, dateTime);
    showToast(`Персональне тренування #${res.personalId} успішно призначено! (M6)`, 'success');
    switchManagerTab('m2');
  } catch (err) {
    showToast(`Помилка призначення тренування: ${err.message}`, 'danger');
  }
}

export function previewM7Freeze() {
  // UI helper for freeze estimation
}

export async function handleM7Freeze(e) {
  e.preventDefault();
  const clientSubId = parseInt(document.getElementById('m7-client')?.value || document.getElementById('m7-clientsub')?.value || document.getElementById('m7-sub')?.value || '1');
  const startDate = document.getElementById('m7-startdate')?.value || document.getElementById('m7-start')?.value;
  const endDate = document.getElementById('m7-enddate')?.value || document.getElementById('m7-end')?.value;
  const reason = document.getElementById('m7-reason').value.trim();

  if (!startDate || !endDate) {
    showToast('Будь ласка, вкажіть дати початку та завершення заморозки', 'warning');
    return;
  }

  try {
    await managerApi.freezeSubscription({
      clientSubId,
      startDate,
      endDate,
      reason
    });
    showToast('Абонемент клієнта заморожено! (M7)', 'success');
    await renderM2ClientsTable();
    switchManagerTab('m2');
  } catch (err) {
    showToast(`Помилка заморозки: ${err.message}`, 'danger');
  }
}

export function toggleM8NewTime(action) {
  const container = document.getElementById('m8-newtime-container');
  if (action === 'Reschedule') {
    if (container) container.classList.remove('hidden');
  } else {
    if (container) container.classList.add('hidden');
  }
}

export async function handleM8Action(e) {
  e.preventDefault();
  const selectTraining = document.getElementById('m8-training');
  const bookingType = selectTraining?.dataset?.type || document.getElementById('m8-type')?.value || 'Personal';
  const bookingId = parseInt(selectTraining?.value || document.getElementById('m8-bookingid')?.value || '0');
  const action = document.getElementById('m8-action-type')?.value || document.getElementById('m8-action')?.value || 'Cancel';
  const newDateTime = action === 'Reschedule' ? document.getElementById('m8-newtime')?.value : null;
  const reason = document.getElementById('m8-reason')?.value?.trim() || '';

  if (!bookingId) {
    showToast('Оберіть тренування зі списку', 'warning');
    return;
  }

  try {
    await managerApi.processScheduleAction({
      bookingType,
      bookingId,
      action,
      newDateTime,
      reason,
      initiator: 'Manager'
    });
    showToast(`Дію '${action}' успішно виконано над бронюванням! (M8)`, 'success');
    await renderM8Requests();
  } catch (err) {
    showToast(`Помилка зміни статусу бронювання: ${err.message}`, 'danger');
  }
}

function formatM8DateTime(dtStr) {
  if (!dtStr) return '—';
  try {
    const d = new Date(dtStr);
    if (isNaN(d.getTime())) return String(dtStr).replace('T', ' ');
    const pad = n => String(n).padStart(2, '0');
    return `${pad(d.getDate())}.${pad(d.getMonth() + 1)}.${d.getFullYear()} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
  } catch {
    return String(dtStr).replace('T', ' ');
  }
}

export async function renderM8Requests() {
  const tbody = document.getElementById('m8-requests-tbody');
  const badgeEl = document.getElementById('m8-requests-count-badge');
  const tabBadgeEl = document.querySelector('#tab-btn-m8 .task-badge');

  try {
    const requests = await managerApi.getScheduleRequests();
    const list = requests || [];

    // Filter pending count
    const pendingList = list.filter(r => (r.status || 'Pending').toLowerCase() === 'pending');
    const pendingCount = pendingList.length;

    if (badgeEl) {
      badgeEl.textContent = `${pendingCount} очікують`;
      badgeEl.className = pendingCount > 0 ? 'badge badge-warning font-mono' : 'badge badge-cyan font-mono';
    }

    if (tabBadgeEl) {
      if (pendingCount > 0) {
        tabBadgeEl.textContent = `M8 (${pendingCount})`;
        tabBadgeEl.classList.add('text-amber-400');
      } else {
        tabBadgeEl.textContent = 'M8';
        tabBadgeEl.classList.remove('text-amber-400');
      }
    }

    // Populate m8-training select with active/scheduled trainings from requests if needed
    const m8TrainingSelect = document.getElementById('m8-training');
    if (m8TrainingSelect && (!m8TrainingSelect.options.length || m8TrainingSelect.options[0].value === '')) {
      m8TrainingSelect.innerHTML = '<option value="" disabled selected>-- Оберіть тренування --</option>';
      const seenIds = new Set();
      list.forEach(r => {
        if (r.personalId && !seenIds.has(r.personalId)) {
          seenIds.add(r.personalId);
          const opt = document.createElement('option');
          opt.value = r.personalId;
          opt.textContent = `№${r.personalId} — ${r.clientName} (Тренер: ${r.coachName}, ${formatM8DateTime(r.currentDateTime)})`;
          m8TrainingSelect.appendChild(opt);
        }
      });
      refreshCombobox(m8TrainingSelect);
    }

    if (!tbody) return;
    tbody.innerHTML = '';

    if (list.length === 0) {
      tbody.innerHTML = '<tr><td colspan="8" class="text-center py-6 text-slate-400 font-mono text-xs">Немає запитів на зміну розкладу від тренерів</td></tr>';
      return;
    }

    list.forEach(req => {
      const row = document.createElement('tr');
      const isPending = (req.status || 'Pending').toLowerCase() === 'pending';
      const isApproved = (req.status || '').toLowerCase() === 'approved';
      const isRejected = (req.status || '').toLowerCase() === 'rejected';

      let statusBadge = '';
      if (isPending) {
        statusBadge = '<span class="badge badge-warning">Очікує</span>';
      } else if (isApproved) {
        statusBadge = '<span class="badge badge-active">Схвалено</span>';
      } else if (isRejected) {
        statusBadge = '<span class="badge badge-danger">Відхилено</span>';
      } else {
        statusBadge = `<span class="badge badge-neutral">${escapeHtml(req.status)}</span>`;
      }

      let actionDesc = '';
      if (req.requestType === 'Cancel') {
        actionDesc = '<span class="badge badge-danger"><i class="fa-solid fa-ban mr-1"></i> Скасування</span>';
      } else if (req.requestType === 'Reschedule') {
        actionDesc = `<div class="space-y-0.5">
          <span class="badge badge-cyan"><i class="fa-solid fa-arrows-split-up-and-left mr-1"></i> Перенесення</span>
          <div class="font-mono text-xs text-cyan-400 font-semibold">${formatM8DateTime(req.proposedDateTime)}</div>
        </div>`;
      } else {
        actionDesc = `<span class="badge badge-neutral">${escapeHtml(req.requestType)}</span>`;
      }

      let actionsHtml = '';
      if (isPending) {
        actionsHtml = `
          <div class="flex items-center space-x-1.5">
            <button onclick="handleApproveRequest(${req.logId})" class="btn btn-primary btn-xs" title="Схвалити запит">
              <i class="fa-solid fa-check mr-1"></i> Схвалити
            </button>
            <button onclick="handleRejectRequest(${req.logId})" class="btn btn-danger btn-xs" title="Відхилити запит">
              <i class="fa-solid fa-xmark mr-1"></i> Відхилити
            </button>
          </div>
        `;
      } else {
        actionsHtml = '<span class="text-xs text-slate-500 font-mono">Опрацьовано</span>';
      }

      row.innerHTML = `
        <td class="font-mono text-xs text-slate-300">${formatM8DateTime(req.requestTimestamp)}</td>
        <td class="font-medium text-white text-xs">${escapeHtml(req.coachName || '—')}</td>
        <td class="text-slate-300 text-xs">${escapeHtml(req.clientName || '—')}</td>
        <td class="font-mono text-xs text-slate-400">${formatM8DateTime(req.currentDateTime)}</td>
        <td>${actionDesc}</td>
        <td class="text-xs text-slate-300 max-w-[200px] truncate" title="${escapeHtml(req.reason || '')}">${escapeHtml(req.reason || '—')}</td>
        <td>${statusBadge}</td>
        <td>${actionsHtml}</td>
      `;
      tbody.appendChild(row);
    });

  } catch (err) {
    console.error('Error rendering M8 requests:', err);
    if (tbody) {
      tbody.innerHTML = `<tr><td colspan="8" class="text-center py-4 text-rose-400 font-mono text-xs">Помилка завантаження запитів: ${escapeHtml(err.message)}</td></tr>`;
    }
  }
}

export async function handleApproveRequest(logId) {
  if (!confirm('Ви дійсно бажаєте схвалити цей запит тренера на зміну розкладу?')) {
    return;
  }
  try {
    const res = await managerApi.approveScheduleRequest(logId);
    showToast(res?.message || 'Запит успішно схвалено та зміни застосовано!', 'success');
    await renderM8Requests();
  } catch (err) {
    showToast(`Помилка схвалення запиту: ${err.message}`, 'danger');
  }
}

export async function handleRejectRequest(logId) {
  if (!confirm('Ви дійсно бажаєте відхилити цей запит тренера?')) {
    return;
  }
  try {
    const res = await managerApi.rejectScheduleRequest(logId);
    showToast(res?.message || 'Запит успішно відхилено.', 'info');
    await renderM8Requests();
  } catch (err) {
    showToast(`Помилка відхилення запиту: ${err.message}`, 'danger');
  }
}
