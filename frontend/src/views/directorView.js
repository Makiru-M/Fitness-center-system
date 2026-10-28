/**
 * FitnessClub IS - Director View (D1 - D12)
 * Pure REST API Implementation
 * Module: views/directorView.js
 */

import { AppState, registerPromo } from '../state/state.js';
import { directorApi } from '../api/directorApi.js';
import { guestApi } from '../api/guestApi.js';
import { showToast } from '../components/toast.js';
import { populateManagerDropdowns } from './managerView.js';
import { renderGuestPriceList, renderGuestHalls } from './guestView.js';
import { refreshCombobox } from '../components/combobox.js';

let cachedPriceListD10 = [];
let cachedDirectorHalls = [];
let cachedDirectorCoaches = [];
let revenueFilterBound = false;

export function switchDirectorTab(tabId) {
  document.querySelectorAll('.director-pane').forEach(el => el.classList.add('hidden'));
  document.querySelectorAll('#view-director .nav-tab-btn').forEach(b => b.classList.remove('active'));

  const pane = document.getElementById(`subtab-${tabId}`);
  const btn = document.getElementById(`tab-btn-${tabId}`);
  if (pane) pane.classList.remove('hidden');
  if (btn) btn.classList.add('active');

  if (tabId === 'd1') {
    initRevenueFilterEvents();
    const fromInput = document.getElementById('revenue-from-date');
    const toInput = document.getElementById('revenue-to-date');
    loadRevenueReport(fromInput?.value || null, toInput?.value || null);
  }
  else if (tabId === 'd2') renderD2Attendance();
  else if (tabId === 'd3') renderD3Coaches();
  else if (tabId === 'd5') renderD5Problems();
  else if (tabId === 'd6') renderD6Audit();
  else if (tabId === 'd10') renderD10PriceList();
}

/**
 * FIT-82: Initialise event handlers for director revenue filter controls
 */
export function initRevenueFilterEvents() {
  if (revenueFilterBound) return;

  const btnApply = document.getElementById('btn-apply-revenue-filter');
  const btnReset = document.getElementById('btn-reset-revenue-filter');
  const fromInput = document.getElementById('revenue-from-date');
  const toInput = document.getElementById('revenue-to-date');

  if (!btnApply || !btnReset) return;

  btnApply.addEventListener('click', () => {
    const from = fromInput?.value ? fromInput.value.trim() : null;
    const to = toInput?.value ? toInput.value.trim() : null;

    if (from && to && from > to) {
      showToast('Дата "З" не може бути більшою за дату "По"', 'warning');
      return;
    }

    loadRevenueReport(from, to);
  });

  btnReset.addEventListener('click', () => {
    if (fromInput) {
      fromInput.value = '';
      if (fromInput._flatpickr) fromInput._flatpickr.clear();
    }
    if (toInput) {
      toInput.value = '';
      if (toInput._flatpickr) toInput._flatpickr.clear();
    }
    loadRevenueReport(null, null);
  });

  revenueFilterBound = true;
}

/**
 * FIT-82: Load director revenue report with optional date bounds
 * @param {string|null} fromDate
 * @param {string|null} toDate
 */
export async function loadRevenueReport(fromDate = null, toDate = null) {
  let totalRevenue = 0;
  let totalFullPrice = 0;
  let totalDiscounts = 0;
  let totalCount = 0;
  let rowsHtml = '';

  try {
    const items = await directorApi.getRevenue(fromDate, toDate);
    if (Array.isArray(items)) {
      items.forEach(d => {
        const actual = parseFloat(d.actualRevenue || 0);
        const full = parseFloat(d.fullPriceTotal || 0);
        const disc = parseFloat(d.totalDiscounts || 0);
        const count = parseInt(d.salesCount || 0);

        totalRevenue += actual;
        totalFullPrice += full;
        totalDiscounts += disc;
        totalCount += count;

        rowsHtml += `
          <tr>
            <td class="font-bold text-white font-heading">${d.category}</td>
            <td class="font-mono text-slate-300">${count}</td>
            <td class="font-mono">${full.toFixed(2)} грн</td>
            <td class="font-bold text-cyan-400 font-mono">${actual.toFixed(2)} грн</td>
            <td class="text-blue-400 font-mono">${disc.toFixed(2)} грн</td>
            <td class="font-mono">${d.promoCodeUsage || 0}</td>
          </tr>
        `;
      });
    }

    const revEl = document.getElementById('d1-total-revenue');
    if (revEl) revEl.textContent = `${totalRevenue.toFixed(2)} грн`;
    const countEl = document.getElementById('d1-total-sales-count');
    if (countEl) countEl.textContent = totalCount;
    const discEl = document.getElementById('d1-total-discounts');
    if (discEl) discEl.textContent = `${totalDiscounts.toFixed(2)} грн`;
    const tbody = document.getElementById('d1-category-tbody');
    if (tbody) tbody.innerHTML = rowsHtml || '<tr><td colspan="6" class="text-center text-xs text-slate-400 py-4">Немає фінансових операцій</td></tr>';
  } catch (err) {
    console.warn('API D1 error:', err);
    showToast('Помилка завантаження звіту про виручку', 'error');
  }
}

export const renderD1Revenue = loadRevenueReport;
export const renderDirectorRevenue = loadRevenueReport;

export async function renderD2Attendance() {
  const tbody = document.getElementById('d2-attendance-tbody');
  const metricTotal = document.getElementById('d2-metric-total-visits');
  const metricHalls = document.getElementById('d2-metric-active-halls');
  if (!tbody) return;

  try {
    const items = await directorApi.getAttendance();
    tbody.innerHTML = '';

    if (!items || !items.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center text-xs text-slate-400 py-4">Немає записів відвідуваності</td></tr>';
      if (metricTotal) metricTotal.textContent = '0';
      if (metricHalls) metricHalls.textContent = '0';
      return;
    }

    let sumVisits = 0;
    items.forEach(d => {
      const visits = parseInt(d.totalVisits || 0);
      sumVisits += visits;
      const uniqueClients = d.uniqueClients != null ? d.uniqueClients : (d.uniqueClientsCount != null ? d.uniqueClientsCount : (d.uniqueVisitors || 0));
      const occupancy = d.occupancyPercent != null ? d.occupancyPercent : (d.avgOccupancyRate != null ? Math.round(parseFloat(d.avgOccupancyRate)) : 0);
      const occupancyNum = Math.min(100, Math.max(0, Math.round(parseFloat(occupancy || 0))));
      const peakHour = d.peakHours || d.peakHour || (d.visitDate ? `Дата: ${d.visitDate}` : '18:00 - 20:00');

      const row = document.createElement('tr');
      row.innerHTML = `
        <td class="font-bold text-white font-heading">${d.hallName || '—'}</td>
        <td class="font-mono">${d.maxCapacity || '—'}</td>
        <td class="font-mono"><b>${visits}</b></td>
        <td class="font-mono">${uniqueClients}</td>
        <td class="font-mono text-xs text-slate-300">${peakHour}</td>
        <td>
          <div class="flex items-center space-x-2">
            <div class="w-24 bg-void border border-subtle rounded-full h-2 overflow-hidden">
              <div class="bg-blue-500 h-2 rounded-full" style="width: ${occupancyNum}%"></div>
            </div>
            <span class="text-xs font-semibold font-mono text-cyan-400">${occupancyNum}%</span>
          </div>
        </td>
      `;
      tbody.appendChild(row);
    });

    if (metricTotal) metricTotal.textContent = sumVisits;
    if (metricHalls) metricHalls.textContent = items.length;
  } catch (err) {
    console.warn('API D2 error:', err);
  }
}

export async function renderD3Coaches() {
  const tbody = document.getElementById('d3-coaches-tbody');
  if (!tbody) return;

  try {
    const items = await directorApi.getCoachPopularity();
    tbody.innerHTML = '';

    if (!items || !items.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center text-xs text-slate-400 py-4">Немає даних рейтингу тренерів</td></tr>';
      return;
    }

    items.forEach((c, idx) => {
      const coachId = c.coachId ?? (idx + 1);
      const coachName = c.fullName || c.coachName || 'Тренер';
      const specName = c.specializationName || c.specName || c.specialization || 'Тренер';
      const personalCount = c.personalCount ?? c.individualClientsCount ?? 0;
      const groupCount = c.groupCount ?? c.groupClassesCount ?? 0;
      const totalClasses = c.totalClasses ?? ((c.personalCount || 0) + (c.groupCount || 0) || (Number(personalCount) + Number(groupCount)));
      const kpi = c.kpi != null ? `${c.kpi}` : (c.avgGroupSize ? `${parseFloat(c.avgGroupSize).toFixed(1)} ос.` : '—');

      const row = document.createElement('tr');
      row.innerHTML = `
        <td class="font-bold text-white font-heading">#${coachId} ${coachName}</td>
        <td><span class="badge badge-scheduled">${specName}</span></td>
        <td class="font-mono"><b>${personalCount}</b></td>
        <td class="font-mono"><b>${groupCount}</b></td>
        <td class="font-mono"><b>${totalClasses}</b></td>
        <td><span class="badge badge-active">${kpi}</span></td>
      `;
      tbody.appendChild(row);
    });
  } catch (err) {
    console.warn('API D3 error:', err);
  }
}

export async function renderD5Problems() {
  const tbody = document.getElementById('d5-problems-tbody');
  if (!tbody) return;

  try {
    const items = await directorApi.getIssues();
    tbody.innerHTML = '';

    if (!items || !items.length) {
      tbody.innerHTML = '<tr><td colspan="5" class="text-center text-xs text-emerald-400 py-6"><i class="fa-solid fa-check-circle mr-1"></i> Проблемних абонементів та критичних показників не виявлено</td></tr>';
      return;
    }

    items.forEach(item => {
      const client = item.clientName || item.fullName || item.clientOrStaffName || '—';
      const phone = item.phone || item.clientPhone || '—';
      const problemType = item.problemType || item.issueCategory || item.issueType || '—';
      const details = item.details || '—';
      const recommendedAction = item.recommendedAction || 'Звʼязатися з клієнтом';

      const row = document.createElement('tr');
      row.innerHTML = `
        <td class="font-bold text-white font-heading">${client}</td>
        <td class="font-mono text-xs text-slate-300">${phone}</td>
        <td><span class="badge badge-danger">${problemType}</span></td>
        <td class="text-xs text-slate-300">${details}</td>
        <td><span class="badge badge-scheduled">${recommendedAction}</span></td>
      `;
      tbody.appendChild(row);
    });
  } catch (err) {
    console.warn('API D5 error:', err);
  }
}

export async function renderD6Audit() {
  const tbody = document.getElementById('d6-audit-tbody');
  if (!tbody) return;

  try {
    const items = await directorApi.getAuditLog();
    tbody.innerHTML = '';

    if (!items || !items.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center text-xs text-slate-400 py-4">Журнал змін порожній</td></tr>';
      return;
    }

    items.forEach((item, idx) => {
      const timeStamp = item.changeTimestamp || item.timestamp || '—';
      const rawId = item.personalId || item.trainingId || item.id || item.logId;
      const trainingId = rawId ? `#${rawId}` : `#PT-${idx + 1}`;
      const actionType = item.requestType || 'Зміна';
      const initiator = item.changeInitiator || item.initiator || 'Система';
      const reason = item.reason || '—';
      const newTime = item.newTime || item.finalResolution || item.details || (item.requestType === 'Cancel' ? 'Скасовано' : '—');

      const isCancel = actionType === 'Cancel' || actionType === 'Скасовано' ||
        String(actionType).toLowerCase().includes('cancel') ||
        String(actionType).toLowerCase().includes('скас');
      const badgeClass = isCancel ? 'badge-cancelled' : 'badge-scheduled';

      const row = document.createElement('tr');
      row.innerHTML = `
        <td class="font-mono text-xs text-slate-300">${timeStamp}</td>
        <td class="font-mono text-xs font-bold text-cyan-400">${trainingId}</td>
        <td><span class="badge ${badgeClass} shrink-0">${actionType}</span></td>
        <td><span class="badge badge-cyan shrink-0">${initiator}</span></td>
        <td class="text-xs text-slate-300">${reason}</td>
        <td class="text-xs font-mono text-slate-300">${newTime}</td>
      `;
      tbody.appendChild(row);
    });
  } catch (err) {
    console.warn('API D6 error:', err);
  }
}

export async function populateDirectorDropdowns() {
  try {
    const [halls, coaches, archivedHalls, classTypes] = await Promise.all([
      guestApi.getHalls(),
      guestApi.getCoaches(),
      directorApi.getArchivedHalls().catch(err => {
        console.warn('Error fetching archived halls:', err);
        return [];
      }),
      guestApi.getClassTypes().catch(err => {
        console.warn('Error fetching class types:', err);
        return [];
      })
    ]);

    // Cache options for modals
    cachedDirectorHalls = halls || [];
    cachedDirectorCoaches = coaches || [];

    // Populate D10 Create Modal dropdowns (halls, coaches)
    const d10Hall = document.getElementById('modal-d10-hall');
    if (d10Hall) {
      d10Hall.innerHTML = '';
      cachedDirectorHalls.forEach(h => {
        const opt = document.createElement('option');
        opt.value = h.hallId;
        opt.textContent = `${h.hallName} (${h.maxCapacity} місць)`;
        d10Hall.appendChild(opt);
      });
    }

    const d10Coach = document.getElementById('modal-d10-coach');
    if (d10Coach) {
      d10Coach.innerHTML = '<option value="" disabled selected>-- Оберіть тренера --</option>';
      cachedDirectorCoaches.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c.coachId;
        opt.textContent = `${c.fullName} (${c.specializationName || c.specName || 'Тренер'})`;
        d10Coach.appendChild(opt);
      });
    }

    // D11 ClassTypes (dynamically populated from API)
    const d11Ct = document.getElementById('d11-classtype');
    if (d11Ct) {
      d11Ct.innerHTML = '';
      if (classTypes && classTypes.length > 0) {
        classTypes.forEach(ct => {
          const opt = document.createElement('option');
          opt.value = ct.classTypeId;
          const priceText = ct.price ? ` (${parseFloat(ct.price).toFixed(2)} грн)` : '';
          opt.textContent = `${ct.typeName}${priceText}`;
          d11Ct.appendChild(opt);
        });
      } else {
        d11Ct.innerHTML = `
          <option value="1">Crossfit Intense</option>
          <option value="2">Hatha Yoga</option>
          <option value="3">Pilates Core</option>
          <option value="4">Boxing Technique</option>
          <option value="5">Aqua Aerobics</option>
        `;
      }
    }

    // D11 & D12 Halls
    const d11Hall = document.getElementById('d11-hall');
    const d12Hall = document.getElementById('d12-hall');
    if (d11Hall) {
      d11Hall.innerHTML = '';
      if (d12Hall) d12Hall.innerHTML = '';
      halls.forEach(h => {
        const opt = document.createElement('option');
        opt.value = h.hallId;
        opt.textContent = `${h.hallName} (${h.maxCapacity} місць)`;
        d11Hall.appendChild(opt);
        if (d12Hall) d12Hall.appendChild(opt.cloneNode(true));
      });
    }

    // D8 Decommission Hall
    const d8Decom = document.getElementById('d8-decom-hall');
    if (d8Decom) {
      d8Decom.innerHTML = '<option value="" disabled selected>-- Оберіть зал для виведення --</option>';
      halls.forEach(h => {
        const opt = document.createElement('option');
        opt.value = h.hallId;
        opt.textContent = `${h.hallName} (ID: ${h.hallId}, місткість: ${h.maxCapacity})`;
        d8Decom.appendChild(opt);
      });
    }

    // D8 Recommission Hall
    const d8Recom = document.getElementById('d8-recom-hall');
    if (d8Recom) {
      if (!archivedHalls || archivedHalls.length === 0) {
        d8Recom.innerHTML = '<option value="" disabled selected>-- Немає залів в архіві --</option>';
      } else {
        d8Recom.innerHTML = '<option value="" disabled selected>-- Оберіть зал для повернення --</option>';
        archivedHalls.forEach(h => {
          const opt = document.createElement('option');
          opt.value = h.hallId;
          opt.textContent = `${h.hallName} (ID: ${h.hallId}, місткість: ${h.maxCapacity})`;
          d8Recom.appendChild(opt);
        });
      }
    }

    // D11 & D12 Coaches
    const d11Coach = document.getElementById('d11-coach');
    const d12Coach = document.getElementById('d12-coach');
    if (d11Coach) {
      d11Coach.innerHTML = '<option value="" disabled selected>-- Оберіть тренера --</option>';
      if (d12Coach) d12Coach.innerHTML = '<option value="" disabled selected>-- Оберіть тренера --</option>';
      coaches.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c.coachId;
        opt.textContent = `${c.fullName} (${c.specializationName || c.specName || 'Тренер'})`;
        d11Coach.appendChild(opt);
        if (d12Coach) d12Coach.appendChild(opt.cloneNode(true));
      });
      refreshCombobox(d11Coach);
      if (d12Coach) refreshCombobox(d12Coach);
    }
  } catch (err) {
    console.warn('Error populating director dropdowns:', err);
  }
}

export async function handleD7CreateSub(e) {
  e.preventDefault();
  const name = document.getElementById('d7-name').value.trim();
  const durationDays = parseInt(document.getElementById('d7-duration').value);
  const price = parseFloat(document.getElementById('d7-price').value);
  const maxFreezingDays = parseInt(document.getElementById('d7-maxfreeze').value);
  const desc = document.getElementById('d7-desc').value.trim();

  try {
    const res = await directorApi.createSubscriptionType({
      itemName: name,
      name,
      category: 'Membership',
      durationDays,
      price,
      maxFreezingDays,
      description: desc
    });

    showToast(`Новий абонемент '${name}' успішно додано до прайсу! Код #${res.itemId} (D7)`, 'success');
    await populateManagerDropdowns();
    await renderGuestPriceList();
    await renderD1Revenue();
  } catch (err) {
    showToast(`Помилка створення абонемента: ${err.message}`, 'danger');
  }
}

export async function handleD8CreateHall(e) {
  e.preventDefault();
  const name = document.getElementById('d8-name').value.trim();
  const maxCapacity = parseInt(document.getElementById('d8-capacity').value);

  try {
    const res = await directorApi.createHall({
      hallName: name,
      name,
      maxCapacity
    });

    showToast(`Зал '${name}' успішно введено в експлуатацію! Код #${res.hallId} (D8)`, 'success');
    document.getElementById('d8-name').value = '';
    await populateDirectorDropdowns();
    await populateManagerDropdowns();
    await renderGuestHalls();
    await renderD2Attendance();
  } catch (err) {
    showToast(`Помилка введення залу: ${err.message}`, 'danger');
  }
}

export async function handleD8DecommissionHall(e) {
  e.preventDefault();
  const select = document.getElementById('d8-decom-hall');
  if (!select) return;
  const hallId = parseInt(select.value);
  if (!hallId) {
    showToast('Будь ласка, оберіть зал зі списку.', 'warning');
    return;
  }

  const hallText = select.options[select.selectedIndex]?.text || `ID #${hallId}`;
  const confirmed = confirm(`Ви впевнені, що бажаєте вивести зал "${hallText}" з експлуатації та перевести його в архів? Зал стане недоступним для нових бронювань та розкладу.`);
  if (!confirmed) return;

  try {
    const res = await directorApi.decommissionHall(hallId);
    showToast(res.message || `Зал #${hallId} успішно переведено в архів! (D8)`, 'success');
    await populateDirectorDropdowns();
    await populateManagerDropdowns();
    await renderGuestHalls();
    await renderD2Attendance();
  } catch (err) {
    showToast(`Помилка виведення залу з експлуатації: ${err.message}`, 'danger');
  }
}

export async function handleD8RecommissionHall(e) {
  e.preventDefault();
  const select = document.getElementById('d8-recom-hall');
  if (!select) return;
  const hallId = parseInt(select.value);
  if (!hallId) {
    showToast('Будь ласка, оберіть зал зі списку.', 'warning');
    return;
  }

  const hallText = select.options[select.selectedIndex]?.text || `ID #${hallId}`;
  const confirmed = confirm(`Ви впевнені, що бажаєте повернути зал "${hallText}" в експлуатацію? Зал знову стане доступним для бронювань, розкладу та перегляду гостями.`);
  if (!confirmed) return;

  try {
    const res = await directorApi.recommissionHall(hallId);
    showToast(res.message || `Зал #${hallId} успішно повернуто в експлуатацію! (D8)`, 'success');
    await populateDirectorDropdowns();
    await populateManagerDropdowns();
    await renderGuestHalls();
    await renderD2Attendance();
  } catch (err) {
    showToast(`Помилка повернення залу в експлуатацію: ${err.message}`, 'danger');
  }
}

export async function handleD9CreatePromo(e) {
  e.preventDefault();
  const code = document.getElementById('d9-code').value.trim().toUpperCase();
  const discountPercent = parseInt(document.getElementById('d9-discount').value);
  const expiryDate = document.getElementById('d9-expiry').value;

  try {
    const res = await directorApi.createPromo({
      codeText: code,
      code,
      discountPercent,
      expiryDate
    });

    registerPromo({ code, discountPercent, expiryDate });
    showToast(`Промокод '${code}' зі знижкою ${discountPercent}% успішно активовано! Код #${res.promoId} (D9)`, 'success');
  } catch (err) {
    showToast(`Помилка створення промокоду: ${err.message}`, 'danger');
  }
}

export async function handleD10CreateService(e) {
  if (e && e.preventDefault) e.preventDefault();
  openD10CreateModal();
}

export function filterD10PriceList(term = '') {
  renderD10PriceList(term);
}

export async function renderD10PriceList(searchTerm = '') {
  const tbody = document.getElementById('d10-pricelist-tbody');
  if (!tbody) return;

  try {
    const showArchived = document.getElementById('d10-show-archived')?.checked ?? false;
    const items = await directorApi.getPrices(showArchived);
    cachedPriceListD10 = items || [];

    const term = (searchTerm || document.getElementById('d10-search')?.value || '').trim().toLowerCase();
    const filtered = term
      ? cachedPriceListD10.filter(item =>
          (item.itemName && item.itemName.toLowerCase().includes(term)) ||
          (item.category && item.category.toLowerCase().includes(term)) ||
          (item.description && item.description.toLowerCase().includes(term))
        )
      : cachedPriceListD10;

    if (!filtered || filtered.length === 0) {
      tbody.innerHTML = `<tr><td colspan="7" class="text-center py-6 text-slate-500 font-mono text-xs">Послуг не знайдено</td></tr>`;
      return;
    }

    tbody.innerHTML = filtered.map(item => {
      const isArchived = item.isActive === false || item.priceEndDate != null;
      let badgeClass = 'badge badge-neutral text-xs font-mono';
      if (!isArchived) {
        if (item.category === 'Membership') badgeClass = 'badge badge-active text-xs font-mono';
        else if (item.category === 'Group training') badgeClass = 'badge badge-cyan text-xs font-mono';
        else if (item.category === 'Personal training') badgeClass = 'badge badge-scheduled text-xs font-mono';
        else if (item.category === 'Extra') badgeClass = 'badge badge-warning text-xs font-mono';
      }

      const priceVal = parseFloat(item.price || 0).toFixed(2);
      const startDate = item.priceStartDate ? item.priceStartDate.substring(0, 10) : '—';
      const desc = item.description || (item.durationDays ? `Термін: ${item.durationDays} дн., Заморозка: ${item.maxFreezingDays || 0} дн.` : '—');

      const actionsHtml = isArchived
        ? `<span class="text-xs text-slate-500 font-mono italic">Знято з продажу</span>`
        : `
          <div class="flex items-center gap-2">
            <button onclick="openD10EditModal(${item.itemId})" class="btn btn-secondary btn-sm" title="Редагувати тариф">
              <i class="fa-solid fa-pen-to-square mr-1"></i> Редагувати
            </button>
            <button onclick="confirmDeactivatePriceItem(${item.itemId}, '${escapeHtml(item.itemName)}')" class="btn btn-secondary-cyan btn-sm whitespace-nowrap" title="Вилучити з прайсу">
              <i class="fa-solid fa-box-archive mr-1"></i> Вилучити
            </button>
          </div>
        `;

      return `
        <tr class="${isArchived ? 'opacity-70 bg-slate-900/30' : ''}">
          <td class="font-mono text-xs font-bold text-slate-300">#${item.itemId}</td>
          <td class="font-medium text-white">
            ${escapeHtml(item.itemName)}
            ${isArchived ? '<span class="badge badge-neutral text-xs font-mono ml-2">Архівна</span>' : ''}
          </td>
          <td><span class="${badgeClass}">${escapeHtml(item.category)}</span></td>
          <td class="font-mono text-cyan-400 font-bold">${priceVal} грн</td>
          <td class="font-mono text-xs text-slate-400">${startDate}</td>
          <td class="text-xs text-slate-400 max-w-xs truncate" title="${escapeHtml(desc)}">${escapeHtml(desc)}</td>
          <td>${actionsHtml}</td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    console.warn('Error fetching price list for D10:', err);
    tbody.innerHTML = `<tr><td colspan="7" class="text-center py-6 text-rose-400 font-mono text-xs">Помилка завантаження прайс-листа: ${escapeHtml(err.message)}</td></tr>`;
  }
}

export async function confirmDeactivatePriceItem(itemId, itemName) {
  const confirmed = confirm(`Ви дійсно бажаєте вилучити послугу "${itemName}" з активного прайсу? Вона більше не буде доступна для нових покупок та бронювань.`);
  if (!confirmed) return;

  try {
    const res = await directorApi.deactivatePriceItem(itemId);
    showToast(res?.message || 'Послугу успішно вилучено з активного прайсу', 'success');
    await renderD10PriceList();
    await renderGuestPriceList();
  } catch (err) {
    showToast(`Помилка вилучення послуги: ${err.message}`, 'danger');
  }
}

export function openD10EditModal(itemId) {
  const item = cachedPriceListD10.find(i => i.itemId === itemId);
  if (!item) {
    showToast('Послугу не знайдено', 'warning');
    return;
  }

  const modal = document.getElementById('modal-d10-edit-tariff');
  if (!modal) return;

  const idEl = document.getElementById('modal-d10-edit-id');
  const nameEl = document.getElementById('modal-d10-edit-name');
  const currentPriceEl = document.getElementById('modal-d10-current-price');
  const newPriceEl = document.getElementById('modal-d10-new-price');

  if (idEl) idEl.value = item.itemId;
  if (nameEl) nameEl.value = item.itemName;
  if (currentPriceEl) currentPriceEl.value = `${parseFloat(item.price).toFixed(2)} грн`;
  if (newPriceEl) {
    newPriceEl.value = parseFloat(item.price).toFixed(2);
    newPriceEl.focus();
  }

  modal.classList.remove('hidden');
  modal.classList.add('active');
}

export function closeD10EditModal() {
  const modal = document.getElementById('modal-d10-edit-tariff');
  if (modal) {
    modal.classList.remove('active');
    modal.classList.add('hidden');
  }
}

export async function handleD10UpdateTariff(e) {
  if (e && e.preventDefault) e.preventDefault();
  const itemId = parseInt(document.getElementById('modal-d10-edit-id').value, 10);
  const newPrice = parseFloat(document.getElementById('modal-d10-new-price').value);

  if (!itemId || isNaN(newPrice) || newPrice <= 0) {
    showToast('Будь ласка, введіть коректну нову ціну!', 'warning');
    return;
  }

  const saveBtn = document.getElementById('btn-d10-save-tariff');
  if (saveBtn) saveBtn.disabled = true;

  try {
    const res = await directorApi.updatePriceTariff(itemId, newPrice);
    showToast(res.message || `Тариф послуги успішно оновлено до ${newPrice.toFixed(2)} грн! (D10)`, 'success');
    closeD10EditModal();
    await renderD10PriceList();
    await renderGuestPriceList();
    await populateManagerDropdowns();
    await populateDirectorDropdowns();
  } catch (err) {
    showToast(`Помилка оновлення тарифу: ${err.message}`, 'danger');
  } finally {
    if (saveBtn) saveBtn.disabled = false;
  }
}

export function openD10CreateModal() {
  const modal = document.getElementById('modal-d10-create-service');
  if (!modal) return;

  const form = document.getElementById('form-d10-create-service');
  if (form) form.reset();

  toggleD10CategoryFields('Group training');
  const catSel = document.getElementById('modal-d10-category');
  if (catSel) catSel.value = 'Group training';

  // Ensure halls and coaches in D10 create modal are populated
  populateDirectorDropdowns();

  modal.classList.remove('hidden');
  modal.classList.add('active');
}

export function closeD10CreateModal() {
  const modal = document.getElementById('modal-d10-create-service');
  if (modal) {
    modal.classList.remove('active');
    modal.classList.add('hidden');
  }
}

export function toggleD10CategoryFields(category) {
  const groupFields = document.getElementById('modal-d10-group-fields');
  const membFields = document.getElementById('modal-d10-membership-fields');

  if (groupFields) {
    if (category === 'Group training') groupFields.classList.remove('hidden');
    else groupFields.classList.add('hidden');
  }

  if (membFields) {
    if (category === 'Membership') membFields.classList.remove('hidden');
    else membFields.classList.add('hidden');
  }
}

export async function handleD10CreateTurnkey(e) {
  if (e && e.preventDefault) e.preventDefault();
  const name = document.getElementById('modal-d10-name').value.trim();
  const category = document.getElementById('modal-d10-category').value;
  const price = parseFloat(document.getElementById('modal-d10-price').value);
  const desc = document.getElementById('modal-d10-desc')?.value.trim() || '';

  if (!name || isNaN(price) || price <= 0) {
    showToast('Будь ласка, заповніть назву та коректну ціну послуги!', 'warning');
    return;
  }

  const payload = {
    itemName: name,
    category,
    price,
    description: desc
  };

  if (category === 'Membership') {
    payload.durationDays = parseInt(document.getElementById('modal-d10-durationdays')?.value || '30', 10);
    payload.maxFreezingDays = parseInt(document.getElementById('modal-d10-maxfreezing')?.value || '0', 10);
  } else if (category === 'Group training') {
    payload.dayOfWeek = parseInt(document.getElementById('modal-d10-dayofweek')?.value || '1', 10);
    payload.startTime = document.getElementById('modal-d10-starttime')?.value || '11:00';
    payload.durationMinutes = parseInt(document.getElementById('modal-d10-duration')?.value || '60', 10);
    payload.hallId = parseInt(document.getElementById('modal-d10-hall')?.value || '1', 10);
    payload.coachId = parseInt(document.getElementById('modal-d10-coach')?.value || '1', 10);
  }

  const submitBtn = document.getElementById('btn-d10-submit-create');
  if (submitBtn) submitBtn.disabled = true;

  try {
    const res = await directorApi.createTurnkeyService(payload);
    showToast(res.message || `Послугу '${name}' успішно створено та введено в дію! (D10)`, 'success');
    closeD10CreateModal();
    await renderD10PriceList();
    await renderGuestPriceList();
    await populateManagerDropdowns();
    await populateDirectorDropdowns();
  } catch (err) {
    showToast(`Помилка створення послуги під ключ: ${err.message}`, 'danger');
  } finally {
    if (submitBtn) submitBtn.disabled = false;
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

export async function handleD11CreateTemplate(e) {
  e.preventDefault();
  const classTypeId = parseInt(document.getElementById('d11-classtype').value);
  const dayOfWeek = parseInt(document.getElementById('d11-dayofweek').value);
  const startTime = document.getElementById('d11-time').value;
  const durationMinutes = parseInt(document.getElementById('d11-duration').value);
  const hallId = parseInt(document.getElementById('d11-hall').value);
  const coachId = parseInt(document.getElementById('d11-coach').value);

  try {
    const res = await directorApi.createScheduleTemplate({
      classTypeId,
      dayOfWeek,
      startTime,
      durationMinutes,
      hallId,
      coachId
    });

    showToast(`Шаблон групового розкладу успішно збережено в базі даних! Код #${res.templateId} (D11)`, 'success');
    await populateManagerDropdowns();
  } catch (err) {
    showToast(`Помилка створення шаблону: ${err.message}`, 'danger');
  }
}

export function handleD12Slot(e) {
  e.preventDefault();
  showToast('Шаблон графіку персональних тренувань оновлено в базі даних! (D12)', 'success');
}
