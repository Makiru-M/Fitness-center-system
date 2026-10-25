/**
 * FitnessClub IS - Manager View (M1 - M8)
 * Pure REST API Implementation
 * Module: views/managerView.js
 */

import { AppState, findPromo, TEST_ACCOUNTS } from '../state/state.js';
import { managerApi } from '../api/managerApi.js';
import { guestApi } from '../api/guestApi.js';
import { clientApi } from '../api/clientApi.js';
import { hrApi } from '../api/hrApi.js';
import { showToast } from '../components/toast.js';
import { refreshCombobox } from '../components/combobox.js';

export let cachedClients = [];
let cachedPriceList = [];
let recentVisits = [];
let cachedM5GroupClasses = [];
let currentM5WeekOffset = 0;

export function switchManagerTab(tabId) {
  document.querySelectorAll('.manager-pane').forEach(el => el.classList.add('hidden'));
  document.querySelectorAll('#view-manager .nav-tab-btn').forEach(b => b.classList.remove('active'));

  const pane = document.getElementById(`subtab-${tabId}`);
  const btn = document.getElementById(`tab-btn-${tabId}`);
  if (pane) pane.classList.remove('hidden');
  if (btn) btn.classList.add('active');

  if (tabId === 'm3') {
    initM3DateLimits();
  } else if (tabId === 'm5') {
    loadM5Schedule();
  } else if (tabId === 'm6') {
    initM6DateLimits();
    updateM6Price();
  } else if (tabId === 'm7') {
    initM7DateLimits();
  } else if (tabId === 'm8') {
    renderM8Requests();
  }
}

export function initM3DateLimits() {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const pad = n => String(n).padStart(2, '0');
  const todayStr = `${today.getFullYear()}-${pad(today.getMonth() + 1)}-${pad(today.getDate())}`;

  const clientEl = document.getElementById('m3-client');
  const startEl = document.getElementById('m3-startdate');
  const submitBtn = document.getElementById('m3-submit-btn');
  const noticeEl = document.getElementById('m3-restriction-notice');
  const noticeTextEl = document.getElementById('m3-restriction-text');

  const clientId = clientEl && clientEl.value ? parseInt(clientEl.value, 10) : null;
  const client = clientId ? (cachedClients || []).find(c => c.clientId === clientId) : null;

  const activeSubStatus = client?.activeSubStatus || null;
  const rawSubEndDate = client?.activeSubEndDate || null;
  const isSubActiveOrFrozen = (activeSubStatus === 'Active' || activeSubStatus === 'Frozen');

  let activeSubEndDate = null;
  if (isSubActiveOrFrozen && rawSubEndDate) {
    const m = String(rawSubEndDate).trim().match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (m) {
      activeSubEndDate = `${m[1]}-${m[2]}-${m[3]}`;
    }
  }

  const isEndDateActive = activeSubEndDate && activeSubEndDate >= todayStr;

  if (isSubActiveOrFrozen && isEndDateActive) {
    const parts = activeSubEndDate.split('-');
    const endDateObj = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));

    const diffMs = endDateObj.getTime() - today.getTime();
    const daysUntilEnd = Math.round(diffMs / (1000 * 60 * 60 * 24));

    const nextStartObj = new Date(endDateObj.getFullYear(), endDateObj.getMonth(), endDateObj.getDate() + 1);
    const nextStartDate = `${nextStartObj.getFullYear()}-${pad(nextStartObj.getMonth() + 1)}-${pad(nextStartObj.getDate())}`;

    const availFromObj = new Date(endDateObj.getFullYear(), endDateObj.getMonth(), endDateObj.getDate() - 7);
    const availDate = `${availFromObj.getFullYear()}-${pad(availFromObj.getMonth() + 1)}-${pad(availFromObj.getDate())}`;

    if (daysUntilEnd > 7) {
      if (submitBtn) submitBtn.disabled = true;
      if (noticeEl) noticeEl.classList.remove('hidden');
      if (noticeTextEl) {
        noticeTextEl.textContent = `У клієнта є діючий абонемент до ${activeSubEndDate}. Оформлення нового абонемента стане доступним з ${availDate} (не раніше ніж за 7 днів до завершення поточного).`;
      }
      if (startEl) {
        startEl.setAttribute('min', nextStartDate);
        startEl.value = nextStartDate;
        if (startEl._flatpickr) {
          startEl._flatpickr.set('minDate', nextStartDate);
          startEl._flatpickr.setDate(nextStartDate, false);
        }
      }
    } else {
      if (submitBtn) submitBtn.disabled = false;
      if (noticeEl) noticeEl.classList.add('hidden');
      if (noticeTextEl) noticeTextEl.textContent = '';
      if (startEl) {
        startEl.setAttribute('min', nextStartDate);
        if (!startEl.value || startEl.value < nextStartDate) {
          startEl.value = nextStartDate;
        }
        if (startEl._flatpickr) {
          startEl._flatpickr.set('minDate', nextStartDate);
          if (startEl.value) startEl._flatpickr.setDate(startEl.value, false);
        }
      }
    }
  } else {
    if (submitBtn) submitBtn.disabled = false;
    if (noticeEl) noticeEl.classList.add('hidden');
    if (noticeTextEl) noticeTextEl.textContent = '';
    if (startEl) {
      startEl.setAttribute('min', todayStr);
      if (!startEl.value || startEl.value < todayStr) {
        startEl.value = todayStr;
      }
      if (startEl._flatpickr) {
        startEl._flatpickr.set('minDate', todayStr);
        if (startEl.value) startEl._flatpickr.setDate(startEl.value, false);
      }
    }
  }

  if (startEl && !startEl.dataset.hasMinListener) {
    startEl.addEventListener('change', () => {
      const minVal = startEl.getAttribute('min') || todayStr;
      if (startEl.value && startEl.value < minVal) {
        startEl.value = minVal;
      }
    });
    startEl.dataset.hasMinListener = 'true';
  }
}

export function initM6DateLimits() {
  const nowIso = new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 16);
  const dtEl = document.getElementById('m6-datetime');
  if (dtEl) {
    dtEl.setAttribute('min', nowIso);
    if (dtEl.value && new Date(dtEl.value) < new Date()) {
      dtEl.value = nowIso;
    }
    if (dtEl._flatpickr) {
      dtEl._flatpickr.set('minDate', nowIso);
      if (dtEl.value) dtEl._flatpickr.setDate(dtEl.value, false);
    }
  }
}

export function initM7DateLimits() {
  const today = new Date().toISOString().split('T')[0];
  const startEl = document.getElementById('m7-startdate');
  const endEl = document.getElementById('m7-enddate');
  if (startEl) {
    startEl.setAttribute('min', today);
    if (startEl._flatpickr) {
      startEl._flatpickr.set('minDate', today);
    }
    if (!startEl.dataset.hasMinListener) {
      startEl.addEventListener('change', () => {
        if (endEl && startEl.value) {
          endEl.setAttribute('min', startEl.value);
          if (endEl._flatpickr) {
            endEl._flatpickr.set('minDate', startEl.value);
          }
        }
      });
      startEl.dataset.hasMinListener = 'true';
    }
  }
  if (endEl) {
    const minEnd = (startEl && startEl.value && startEl.value >= today) ? startEl.value : today;
    endEl.setAttribute('min', minEnd);
    if (endEl._flatpickr) {
      endEl._flatpickr.set('minDate', minEnd);
    }
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

    const m5ClientSel = document.getElementById('m5-client');
    if (m5ClientSel && !m5ClientSel.dataset.hasPreviewListener) {
      m5ClientSel.addEventListener('change', (e) => updateM5ClientPreview(e.target.value));
      m5ClientSel.dataset.hasPreviewListener = 'true';
    }
    updateM5ClientPreview();

    const m3ClientSel = document.getElementById('m3-client');
    if (m3ClientSel && !m3ClientSel.dataset.hasDateLimitListener) {
      m3ClientSel.addEventListener('change', () => initM3DateLimits());
      m3ClientSel.dataset.hasDateLimitListener = 'true';
    }

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

    // PriceList items for M3: Filter out training services (Personal and Group)
    const m3Item = document.getElementById('m3-item');
    if (m3Item) {
      m3Item.innerHTML = '';
      const serviceItems = cachedPriceList.filter(item => 
        item.category !== 'Personal training' && item.category !== 'Group training'
      );
      serviceItems.forEach(item => {
        const opt = document.createElement('option');
        opt.value = item.itemId;
        opt.textContent = `[${item.category}] ${item.itemName} — ${parseFloat(item.price).toFixed(2)} грн`;
        m3Item.appendChild(opt);
      });
      const sDate = document.getElementById('m3-startdate');
      initM3DateLimits();
      updateM3Price();
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
      initM6DateLimits();
      updateM6Price();
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
      const subStatus = (c.activeSubStatus || '').toLowerCase();
      let badgeClass = 'badge-expired';
      if (subStatus === 'active') {
        badgeClass = 'badge-active';
      } else if (subStatus === 'frozen') {
        badgeClass = 'badge-frozen';
      } else if (!c.activeSubStatus || subStatus === 'немає' || subStatus === 'none') {
        badgeClass = 'badge-neutral';
      }

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
          <span class="badge ${badgeClass}">${c.activeSubStatus || 'Немає'}</span>
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
  const clientId = parseInt(document.getElementById('m3-client').value, 10);
  const itemId = parseInt(document.getElementById('m3-item').value, 10);
  const startDate = document.getElementById('m3-startdate').value;
  const promoCode = document.getElementById('m3-promo').value.trim().toUpperCase() || null;

  const today = new Date().toISOString().split('T')[0];
  if (startDate < today) {
    showToast('Дата початку дії абонемента не може бути в минулому!', 'warning');
    return;
  }

  const client = (cachedClients || []).find(c => c.clientId === clientId);
  const activeSubStatus = client?.activeSubStatus || null;
  const rawSubEndDate = client?.activeSubEndDate || null;
  const isSubActiveOrFrozen = (activeSubStatus === 'Active' || activeSubStatus === 'Frozen');

  let activeSubEndDate = null;
  if (isSubActiveOrFrozen && rawSubEndDate) {
    const m = String(rawSubEndDate).trim().match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (m) {
      activeSubEndDate = `${m[1]}-${m[2]}-${m[3]}`;
    }
  }

  if (activeSubEndDate && activeSubEndDate >= today) {
    const parts = activeSubEndDate.split('-');
    const endDateObj = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
    const nowD = new Date();
    const todayObj = new Date(nowD.getFullYear(), nowD.getMonth(), nowD.getDate());
    const daysUntilEnd = Math.round((endDateObj.getTime() - todayObj.getTime()) / (1000 * 60 * 60 * 24));

    if (daysUntilEnd > 7) {
      showToast(`У клієнта є діючий абонемент до ${activeSubEndDate}. Оформлення можливе не раніше ніж за 7 днів до його завершення!`, 'warning');
      return;
    }

    if (startDate <= activeSubEndDate) {
      showToast('Дата початку нового абонемента не може перетинатися з діючим абонементом (діє до ' + activeSubEndDate + ')!', 'warning');
      return;
    }
  }

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
      managerId: null
    });

    showToast(`Абонемент успішно оформлено! Чек #${res.saleId} (M3)`, 'success');
    await populateManagerDropdowns();
    await renderM2ClientsTable();
    switchManagerTab('m2');
  } catch (err) {
    showToast(`Помилка продажу абонемента: ${err.message}`, 'danger');
  }
}

// Helpers for M5 Schedule & Dates
function getM5Monday(date) {
  const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const day = d.getDay();
  const diff = (day === 0 ? -6 : 1) - day;
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

function formatM5DateDisplay(d) {
  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const yyyy = d.getFullYear();
  return `${dd}.${mm}.${yyyy}`;
}

function formatM5IsoDate(d) {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

function formatM5TimeRange(startTimeStr, durationMinutes) {
  if (!startTimeStr) return '—';
  const parts = startTimeStr.split(':');
  const h = parseInt(parts[0], 10) || 0;
  const m = parseInt(parts[1], 10) || 0;
  const startH = String(h).padStart(2, '0');
  const startM = String(m).padStart(2, '0');
  const dur = parseInt(durationMinutes, 10) || 60;
  const totalM = h * 60 + m + dur;
  const endH = String(Math.floor(totalM / 60) % 24).padStart(2, '0');
  const endM = String(totalM % 60).padStart(2, '0');
  return `${startH}:${startM} – ${endH}:${endM}`;
}

function isM5ClassInPast(classDateStr, startTimeStr) {
  if (!classDateStr) return false;
  const time = startTimeStr ? (startTimeStr.length === 5 ? startTimeStr + ':00' : startTimeStr) : '00:00:00';
  const classDt = new Date(`${classDateStr.substring(0, 10)}T${time}`);
  if (isNaN(classDt.getTime())) return false;
  return classDt < new Date();
}

export function updateM5ClientPreview(val) {
  const sel = document.getElementById('m5-client');
  const clientId = parseInt(val || sel?.value || '0', 10);
  const pill = document.getElementById('m5-sub-status-pill');
  if (!pill) return;

  if (!clientId || isNaN(clientId)) {
    pill.textContent = 'Клієнта не обрано';
    pill.className = 'badge badge-neutral text-xs font-mono';
    return;
  }

  const client = cachedClients.find(c => c.clientId === clientId);
  if (!client) {
    pill.textContent = 'Не знайдено';
    pill.className = 'badge badge-expired text-xs font-mono';
    return;
  }

  const status = (client.activeSubStatus || 'None').toLowerCase();
  if (status === 'active') {
    pill.textContent = `Active (${client.activeSubName || 'Абонемент'})`;
    pill.className = 'badge badge-active text-xs font-mono';
  } else if (status === 'frozen') {
    pill.textContent = `Frozen (${client.activeSubName || 'Абонемент'})`;
    pill.className = 'badge badge-cyan text-xs font-mono';
  } else if (status === 'expired') {
    pill.textContent = 'Expired (Прострочено)';
    pill.className = 'badge badge-expired text-xs font-mono';
  } else {
    pill.textContent = 'None (Без абонемента)';
    pill.className = 'badge badge-expired text-xs font-mono';
  }
}

export function checkM5Promo() {
  const input = document.getElementById('m5-promo');
  const badge = document.getElementById('m5-promo-status-badge');
  const code = input?.value.trim().toUpperCase() || '';
  if (!code) {
    showToast('Введіть промокод для перевірки', 'warning');
    if (badge) badge.innerHTML = '';
    return;
  }

  const promo = findPromo(code);
  const now = new Date().toISOString().split('T')[0];

  if (!promo) {
    showToast('Промокод не знайдено або термін його дії закінчився', 'warning');
    if (badge) badge.innerHTML = `<span class="text-rose-400"><i class="fa-solid fa-circle-xmark mr-1"></i> Недійсний промокод</span>`;
    return;
  }

  if (promo.expiryDate && promo.expiryDate < now) {
    showToast('Термін дії промокоду вичерпано!', 'warning');
    if (badge) badge.innerHTML = `<span class="text-amber-400"><i class="fa-solid fa-clock-rotate-left mr-1"></i> Термін вичерпано</span>`;
    return;
  }

  showToast(`Промокод ${code} на ${promo.discountPercent}% успішно застосовано!`, 'success');
  if (badge) badge.innerHTML = `<span class="text-emerald-400"><i class="fa-solid fa-circle-check mr-1"></i> Знижка ${promo.discountPercent}% діє</span>`;
}

export async function loadM5Schedule() {
  try {
    const classes = await clientApi.getAvailableGroupClasses();
    cachedM5GroupClasses = classes || [];
    renderM5Schedule();
  } catch (err) {
    console.warn('Could not load group classes for M5:', err);
    cachedM5GroupClasses = [];
    renderM5Schedule();
  }
}

export function handleM5PrevWeek() {
  if (currentM5WeekOffset <= 0) return;
  currentM5WeekOffset--;
  renderM5Schedule();
}

export function handleM5NextWeek() {
  if (currentM5WeekOffset >= 1) return;
  currentM5WeekOffset++;
  renderM5Schedule();
}

export function handleM5TodayWeek() {
  currentM5WeekOffset = 0;
  renderM5Schedule();
}

export function renderM5Schedule() {
  const gridContainer = document.getElementById('m5-schedule-grid');
  const weekRangeEl = document.getElementById('m5-week-range');
  const prevBtn = document.getElementById('m5-prev-week');
  const nextBtn = document.getElementById('m5-next-week');

  const baseMonday = getM5Monday(new Date());
  const selectedMonday = new Date(baseMonday);
  selectedMonday.setDate(selectedMonday.getDate() + currentM5WeekOffset * 7);

  const selectedSunday = new Date(selectedMonday);
  selectedSunday.setDate(selectedSunday.getDate() + 6);

  if (weekRangeEl) {
    weekRangeEl.textContent = `${formatM5DateDisplay(selectedMonday)} – ${formatM5DateDisplay(selectedSunday)}`;
  }

  if (prevBtn) {
    prevBtn.disabled = currentM5WeekOffset <= 0;
    if (currentM5WeekOffset <= 0) {
      prevBtn.classList.add('opacity-50', 'cursor-not-allowed');
    } else {
      prevBtn.classList.remove('opacity-50', 'cursor-not-allowed');
    }
  }

  if (nextBtn) {
    nextBtn.disabled = currentM5WeekOffset >= 1;
    if (currentM5WeekOffset >= 1) {
      nextBtn.classList.add('opacity-50', 'cursor-not-allowed');
    } else {
      nextBtn.classList.remove('opacity-50', 'cursor-not-allowed');
    }
  }

  if (!gridContainer) return;

  const DAY_NAMES = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayIso = formatM5IsoDate(today);

  gridContainer.innerHTML = '';

  for (let i = 0; i < 7; i++) {
    const dayDate = new Date(selectedMonday);
    dayDate.setDate(dayDate.getDate() + i);
    const dayIso = formatM5IsoDate(dayDate);
    const dayShort = `${String(dayDate.getDate()).padStart(2, '0')}.${String(dayDate.getMonth() + 1).padStart(2, '0')}`;
    const isToday = dayIso === todayIso;

    // Filter classes for this day
    const dayClasses = (cachedM5GroupClasses || []).filter(c => {
      if (!c.classDate) return false;
      const cDate = typeof c.classDate === 'string' ? c.classDate.substring(0, 10) : '';
      return cDate === dayIso;
    });

    dayClasses.sort((a, b) => String(a.startTime || '').localeCompare(String(b.startTime || '')));

    let cardsHtml = '';
    if (dayClasses.length === 0) {
      cardsHtml = `
        <div class="flex-1 flex flex-col items-center justify-center py-8 text-center text-slate-500 text-xs italic">
          <i class="fa-regular fa-calendar-xmark text-slate-600 text-lg mb-1.5"></i>
          <span>Немає занять</span>
        </div>
      `;
    } else {
      cardsHtml = `<div class="space-y-2.5 flex-1">` + dayClasses.map(gc => {
        const inPast = isM5ClassInPast(gc.classDate, gc.startTime);
        const isFull = gc.availableSpots <= 0;
        const canBook = !inPast && !isFull;

        let badgeHtml = '';
        let btnHtml = '';
        let cardClasses = 'p-2.5 rounded-xl border transition flex flex-col justify-between ';

        if (isFull) {
          badgeHtml = `<span class="badge badge-expired text-[10px] px-1.5 py-0.5 whitespace-nowrap shrink-0"><i class="fa-solid fa-ban mr-1"></i> Місць немає</span>`;
          btnHtml = `<button type="button" disabled class="w-full mt-2.5 py-1.5 text-[11px] font-medium text-slate-400 bg-slate-800/40 rounded-lg border border-subtle cursor-not-allowed">Місць немає</button>`;
          cardClasses += 'border-subtle bg-void/50 opacity-75';
        } else if (inPast) {
          badgeHtml = `<span class="badge badge-neutral text-[10px] px-1.5 py-0.5 whitespace-nowrap shrink-0"><i class="fa-solid fa-clock-rotate-left mr-1"></i> Минуло</span>`;
          btnHtml = `<button type="button" disabled class="w-full mt-2.5 py-1.5 text-[11px] font-medium text-slate-500 bg-slate-800/30 rounded-lg border border-subtle cursor-not-allowed">Минуло</button>`;
          cardClasses += 'border-subtle bg-void/40 opacity-60';
        } else {
          badgeHtml = `<span class="badge badge-cyan text-[10px] font-mono px-1.5 py-0.5 whitespace-nowrap shrink-0">Вільно: ${gc.availableSpots}/${gc.maxCapacity}</span>`;
          btnHtml = `<button type="button" onclick="event.stopPropagation(); bookM5ClassForClient(${gc.instanceId})" class="btn btn-primary btn-xs w-full py-1.5 mt-2.5 font-bold text-[11px] flex items-center justify-center gap-1 font-heading"><i class="fa-solid fa-user-plus text-[10px]"></i> Записати</button>`;
          cardClasses += 'border-subtle bg-void hover:border-cyan-500/50 hover:bg-slate-800/40 cursor-pointer shadow-sm group';
        }

        const timeRange = formatM5TimeRange(gc.startTime, gc.durationMinutes);

        return `
          <div class="${cardClasses}" ${canBook ? `onclick="bookM5ClassForClient(${gc.instanceId})"` : ''}>
            <div>
              <div class="flex items-center justify-between gap-1 mb-1.5 flex-wrap">
                <span class="text-xs font-bold text-white font-mono flex items-center gap-1 whitespace-nowrap">
                  <i class="fa-regular fa-clock text-cyan-400 text-[10px]"></i> ${timeRange}
                </span>
                ${badgeHtml}
              </div>
              <h5 class="font-bold text-xs text-white group-hover:text-cyan-300 transition-colors line-clamp-2 leading-tight mb-1" title="${escapeHtml(gc.title)}">
                ${escapeHtml(gc.title)}
              </h5>
              <div class="text-[11px] text-slate-300 flex items-start gap-1.5 mt-1 leading-snug" title="Тренер: ${escapeHtml(gc.coachName)}">
                <i class="fa-solid fa-user-tie text-[10px] text-cyan-400/80 mt-0.5 shrink-0"></i>
                <span class="line-clamp-2 break-words">${escapeHtml(gc.coachName)}</span>
              </div>
              <div class="text-[11px] text-slate-400 flex items-center gap-1.5 mt-0.5" title="Зал: ${escapeHtml(gc.hallName)}">
                <i class="fa-solid fa-location-dot text-[10px] text-slate-500 shrink-0"></i>
                <span class="truncate">${escapeHtml(gc.hallName)}</span>
              </div>
            </div>
            ${btnHtml}
          </div>
        `;
      }).join('') + `</div>`;
    }

    const colEl = document.createElement('div');
    colEl.className = `flex flex-col rounded-xl border ${isToday ? 'border-cyan-500/60 bg-cyan-950/20 ring-1 ring-cyan-500/30' : 'border-subtle bg-surface/60'} p-3 min-h-[300px] min-w-[155px]`;
    colEl.innerHTML = `
      <div class="flex flex-col items-center pb-2 mb-2 border-b ${isToday ? 'border-cyan-500/30' : 'border-subtle'}">
        ${isToday ? '<span class="badge badge-cyan text-[10px] px-2 py-0.5 mb-1 shadow-sm font-sans">Сьогодні</span>' : '<span class="text-[10px] text-slate-500 mb-1 opacity-0 select-none">-</span>'}
        <div class="flex items-center gap-1.5">
          <span class="font-bold text-sm ${isToday ? 'text-cyan-400' : 'text-white'} font-heading">${DAY_NAMES[i]}</span>
          <span class="text-xs ${isToday ? 'text-cyan-300 font-semibold' : 'text-slate-400'} font-mono">${dayShort}</span>
        </div>
      </div>
      ${cardsHtml}
    `;
    gridContainer.appendChild(colEl);
  }
}

const BASE_M5_PRICE = 200.00;
const BASE_M6_PRICE = 400.00;

export function updateM5Price() {
  const display = document.getElementById('modal-m5-price-display');
  const promoInput = document.getElementById('modal-m5-promo')?.value.trim().toUpperCase() || '';
  const promoBadge = document.getElementById('modal-m5-promo-badge');
  const confirmBtn = document.getElementById('modal-m5-confirm-btn');

  let price = BASE_M5_PRICE;
  const promo = findPromo(promoInput);
  const now = new Date().toISOString().split('T')[0];
  if (promo && !(promo.expiryDate && promo.expiryDate < now)) {
    price = (BASE_M5_PRICE * (100 - promo.discountPercent)) / 100;
    if (promoBadge) {
      promoBadge.innerHTML = `<span class="badge badge-active text-xs">Знижка ${promo.discountPercent}% застосована!</span>`;
      promoBadge.classList.remove('hidden');
    }
  } else {
    if (promoBadge) {
      promoBadge.classList.add('hidden');
    }
  }
  if (display) {
    display.textContent = `${price.toFixed(2)} грн`;
  }
  if (confirmBtn) {
    confirmBtn.innerHTML = `<i class="fa-solid fa-credit-card mr-1"></i> Оплатити та записати клієнта (${price.toFixed(2)} грн)`;
  }
}

export function applyM5Promo() {
  const code = document.getElementById('modal-m5-promo')?.value.trim().toUpperCase();
  if (!code) {
    showToast('Введіть промокод', 'warning');
    updateM5Price();
    return;
  }

  const promo = findPromo(code);
  const now = new Date().toISOString().split('T')[0];

  if (!promo) {
    showToast('Промокод не знайдено або термін його дії закінчився', 'warning');
    updateM5Price();
    return;
  }

  if (promo.expiryDate && promo.expiryDate < now) {
    showToast('Термін дії промокоду вичерпано!', 'warning');
    updateM5Price();
    return;
  }

  showToast(`Промокод ${code} на ${promo.discountPercent}% успішно застосовано!`, 'success');
  updateM5Price();
}

export function closeM5Modal() {
  const modal = document.getElementById('modal-m5-booking');
  if (modal) {
    modal.classList.remove('active');
    modal.classList.add('hidden');
  }
}

export async function bookM5ClassForClient(instanceId) {
  const clientSel = document.getElementById('m5-client');
  const clientId = parseInt(clientSel?.value || '0', 10);
  const topPromo = document.getElementById('m5-promo')?.value.trim().toUpperCase() || '';

  if (!clientId || isNaN(clientId)) {
    showToast('Будь ласка, оберіть клієнта у верхньому блоці!', 'warning');
    clientSel?.focus();
    return;
  }

  const client = cachedClients.find(c => c.clientId === clientId);
  const clientName = client ? `${client.fullName} (${client.phone})` : `Клієнт ID #${clientId}`;
  const gc = (cachedM5GroupClasses || []).find(c => c.instanceId === instanceId);

  if (!gc) {
    showToast('Інформацію про заняття не знайдено', 'warning');
    return;
  }

  const modal = document.getElementById('modal-m5-booking');
  if (!modal) return;

  const instInput = document.getElementById('modal-m5-instance-id');
  if (instInput) instInput.value = gc.instanceId;

  const clientInput = document.getElementById('modal-m5-client-id');
  if (clientInput) clientInput.value = clientId;

  const clientNameEl = document.getElementById('modal-m5-client-name');
  if (clientNameEl) clientNameEl.textContent = clientName;

  const clientSubNameEl = document.getElementById('modal-m5-client-sub-name');
  if (clientSubNameEl) {
    clientSubNameEl.textContent = client?.activeSubName || 'Без активного абонемента';
  }

  const clientSubEl = document.getElementById('modal-m5-client-sub');
  if (clientSubEl) {
    const status = (client?.activeSubStatus || '').toUpperCase();
    if (status === 'ACTIVE') {
      clientSubEl.textContent = 'ACTIVE';
      clientSubEl.className = 'badge badge-active text-xs font-mono shrink-0';
    } else if (status === 'FROZEN') {
      clientSubEl.textContent = 'FROZEN';
      clientSubEl.className = 'badge badge-frozen text-xs font-mono shrink-0';
    } else {
      clientSubEl.textContent = status || 'НЕМАЄ';
      clientSubEl.className = 'badge badge-expired text-xs font-mono shrink-0';
    }
  }

  const titleEl = document.getElementById('modal-m5-title');
  if (titleEl) {
    titleEl.textContent = gc.title;
    titleEl.style.color = '#ffffff';
  }

  const actEl = document.getElementById('modal-m5-activity-type');
  if (actEl) actEl.textContent = 'Групове тренування';

  const dateEl = document.getElementById('modal-m5-date');
  if (dateEl) {
    const parts = (gc.classDate || '').substring(0, 10).split('-');
    if (parts.length === 3) {
      dateEl.textContent = `${parts[2]}.${parts[1]}.${parts[0]}`;
    } else {
      dateEl.textContent = gc.classDate;
    }
  }

  const timeEl = document.getElementById('modal-m5-time');
  if (timeEl) {
    const range = formatM5TimeRange(gc.startTime, gc.durationMinutes);
    timeEl.textContent = `${range} (${gc.durationMinutes || 60} хв)`;
  }

  const coachEl = document.getElementById('modal-m5-coach');
  if (coachEl) coachEl.textContent = `Тренер: ${gc.coachName}`;

  const hallEl = document.getElementById('modal-m5-hall');
  if (hallEl) hallEl.textContent = `Зал: ${gc.hallName}`;

  const spotsEl = document.getElementById('modal-m5-spots');
  if (spotsEl) {
    spotsEl.textContent = `Вільно: ${gc.availableSpots} / ${gc.maxCapacity}`;
    spotsEl.className = gc.availableSpots > 0 ? 'badge badge-active text-xs font-mono' : 'badge badge-expired text-xs font-mono';
  }

  // Pre-fill promo from top block if available
  const promoInput = document.getElementById('modal-m5-promo');
  if (promoInput) promoInput.value = topPromo;

  updateM5Price();

  modal.classList.remove('hidden');
  modal.classList.add('active');
}

export async function confirmM5GroupBooking() {
  const instanceId = parseInt(document.getElementById('modal-m5-instance-id')?.value || '0', 10);
  const clientId = parseInt(document.getElementById('modal-m5-client-id')?.value || '0', 10);
  const promoCode = document.getElementById('modal-m5-promo')?.value.trim().toUpperCase() || '';

  if (!clientId) {
    showToast('Клієнта не вказано!', 'warning');
    return;
  }
  if (!instanceId) {
    showToast('Будь ласка, оберіть заняття!', 'warning');
    return;
  }

  const confirmBtn = document.getElementById('modal-m5-confirm-btn');
  if (confirmBtn) confirmBtn.disabled = true;

  try {
    const res = await managerApi.bookGroupClass(clientId, instanceId, promoCode);
    showToast(res.message || 'Клієнта успішно записано на групове тренування! (M5)', 'success');
    closeM5Modal();
    await loadM5Schedule();
    await renderM2ClientsTable();
  } catch (err) {
    showToast(`Помилка запису: ${err.message}`, 'danger');
  } finally {
    if (confirmBtn) confirmBtn.disabled = false;
  }
}

export async function handleM5Booking(e) {
  if (e && e.preventDefault) e.preventDefault();
  const clientId = parseInt(document.getElementById('m5-client')?.value || '0', 10);
  const instanceId = parseInt(document.getElementById('m5-instance')?.value || '1', 10);
  const promoCode = document.getElementById('m5-promo')?.value.trim().toUpperCase() || '';

  if (!clientId) {
    showToast('Будь ласка, оберіть клієнта!', 'warning');
    return;
  }

  try {
    const res = await managerApi.bookGroupClass(clientId, instanceId, promoCode);
    showToast(res.message || 'Клієнта успішно записано на групове тренування! (M5)', 'success');
    await loadM5Schedule();
    await renderM2ClientsTable();
    switchManagerTab('m2');
  } catch (err) {
    showToast(`Помилка запису: ${err.message}`, 'danger');
  }
}

export function checkM6MedicalAlert() {
  // Deprecated/no-op per TICKET-029: m6-med-warning was removed to keep manager M6 form clean
}

export function updateM6Price() {
  const display = document.getElementById('m6-price-display');
  const promoInput = document.getElementById('m6-promo')?.value.trim().toUpperCase() || '';
  const promoBadge = document.getElementById('m6-promo-badge');
  const submitBtn = document.getElementById('m6-submit-btn');

  let price = BASE_M6_PRICE;
  const promo = findPromo(promoInput);
  const now = new Date().toISOString().split('T')[0];
  if (promo && !(promo.expiryDate && promo.expiryDate < now)) {
    price = (BASE_M6_PRICE * (100 - promo.discountPercent)) / 100;
    if (promoBadge) {
      promoBadge.innerHTML = `<span class="badge badge-active text-xs">Знижка ${promo.discountPercent}% застосована!</span>`;
      promoBadge.classList.remove('hidden');
    }
  } else {
    if (promoBadge) {
      promoBadge.classList.add('hidden');
    }
  }
  if (display) {
    display.textContent = `${price.toFixed(2)} грн`;
  }
  if (submitBtn) {
    submitBtn.innerHTML = `<i class="fa-solid fa-credit-card mr-1"></i> Оформити персональне (${price.toFixed(2)} грн)`;
  }
}

export function applyM6Promo() {
  const code = document.getElementById('m6-promo')?.value.trim().toUpperCase();
  if (!code) {
    showToast('Введіть промокод', 'warning');
    updateM6Price();
    return;
  }

  const promo = findPromo(code);
  const now = new Date().toISOString().split('T')[0];

  if (!promo) {
    showToast('Промокод не знайдено або термін його дії закінчився', 'warning');
    updateM6Price();
    return;
  }

  if (promo.expiryDate && promo.expiryDate < now) {
    showToast('Термін дії промокоду вичерпано!', 'warning');
    updateM6Price();
    return;
  }

  showToast(`Промокод ${code} на ${promo.discountPercent}% успішно застосовано!`, 'success');
  updateM6Price();
}

export function checkM6Promo() {
  applyM6Promo();
}

export async function handleM6Booking(e) {
  e.preventDefault();
  const clientId = parseInt(document.getElementById('m6-client').value, 10);
  const coachId = parseInt(document.getElementById('m6-coach').value, 10);
  const hallId = parseInt(document.getElementById('m6-hall').value, 10);
  const dateTime = document.getElementById('m6-datetime').value;
  const promoCode = document.getElementById('m6-promo')?.value.trim().toUpperCase() || '';

  if (!dateTime) {
    showToast('Вкажіть дату та час тренування!', 'warning');
    return;
  }
  if (new Date(dateTime) <= new Date()) {
    showToast('Дата та час персонального тренування не можуть бути в минулому!', 'warning');
    return;
  }

  try {
    const res = await managerApi.bookPersonalTraining(clientId, coachId, hallId, dateTime, promoCode);
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

  const today = new Date().toISOString().split('T')[0];
  if (startDate < today) {
    showToast('Дата початку заморозки не може бути в минулому!', 'warning');
    return;
  }
  if (endDate <= startDate) {
    showToast('Дата закінчення заморозки повинна бути пізнішою за дату початку!', 'warning');
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
    const nowIso = new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    const m8Input = document.getElementById('m8-newtime');
    if (m8Input) {
      m8Input.setAttribute('min', nowIso);
      if (m8Input._flatpickr) {
        m8Input._flatpickr.set('minDate', nowIso);
      }
    }
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

  if (action === 'Reschedule') {
    if (!newDateTime) {
      showToast('Вкажіть нову дату та час тренування', 'warning');
      return;
    }
    if (new Date(newDateTime) <= new Date()) {
      showToast('Новий час тренування не може бути в минулому!', 'warning');
      return;
    }
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
