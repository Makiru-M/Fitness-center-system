/**
 * FitnessClub IS - Client View (Cl1 - Cl6)
 * Pure REST API Implementation
 * Module: views/clientView.js
 */

import { AppState, findPromo, setCurrentUser, STORAGE_KEYS } from '../state/state.js';
import { clientApi } from '../api/clientApi.js';
import { guestApi } from '../api/guestApi.js';
import { showToast } from '../components/toast.js';
import { updateHeaderUI } from '../components/navigation.js';
import { refreshCombobox } from '../components/combobox.js';

let cachedClientSubscriptions = [];
let cachedClientBookings = [];
let cachedPriceList = [];
const bookedCoachSlots = new Set();

const INITIAL_CLIENT_PHONES = [
  { id: 1, phone: '+380671111111' },
  { id: 2, phone: '+380672222222' },
  { id: 3, phone: '+380673333333' },
  { id: 4, phone: '+380674444444' },
  { id: 5, phone: '+380675555555' },
  { id: 6, phone: '+380676666666' },
  { id: 7, phone: '+380677777777' },
  { id: 8, phone: '+380678888888' },
  { id: 9, phone: '+380679999999' },
  { id: 10, phone: '+380670000000' }
];

export function switchClientTab(tabId) {
  const norm = tabId.replace('_', '-');
  document.querySelectorAll('.client-pane').forEach(el => el.classList.add('hidden'));
  document.querySelectorAll('#view-client .nav-tab-btn').forEach(b => b.classList.remove('active'));

  const pane = document.getElementById(`subtab-${norm}`) || document.getElementById(`subtab-${tabId}`);
  const btn = document.getElementById(`tab-btn-${norm}`) || document.getElementById(`tab-btn-${tabId}`);
  if (pane) pane.classList.remove('hidden');
  if (btn) btn.classList.add('active');

  if (norm === 'cl2' || tabId === 'cl2') {
    populateCl2Options();
  }
}

export function getActiveClient() {
  return AppState.currentUser;
}

export function formatExpiryDate(dateStr) {
  if (!dateStr || typeof dateStr !== 'string') return '—';
  const clean = dateStr.trim();
  if (!clean) return '—';

  if (/^\d{2}\.\d{2}\.\d{4}$/.test(clean)) return clean;

  const isoMatch = clean.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (isoMatch) {
    const [, yyyy, mm, dd] = isoMatch;
    const m = parseInt(mm, 10);
    const d = parseInt(dd, 10);
    if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
      return `${dd}.${mm}.${yyyy}`;
    }
    return '—';
  }

  const parsed = new Date(clean);
  if (isNaN(parsed.getTime())) return '—';
  const day = String(parsed.getDate()).padStart(2, '0');
  const month = String(parsed.getMonth() + 1).padStart(2, '0');
  const year = parsed.getFullYear();
  return `${day}.${month}.${year}`;
}

export function pluralizeDaysUk(count) {
  const abs = Math.abs(Math.trunc(count));
  const mod10 = abs % 10;
  const mod100 = abs % 100;

  if (mod100 >= 11 && mod100 <= 14) {
    return `${count} днів`;
  }
  if (mod10 === 1) {
    return `${count} день`;
  }
  if (mod10 >= 2 && mod10 <= 4) {
    return `${count} дні`;
  }
  return `${count} днів`;
}

export function formatFreezingDays(days) {
  if (days === null || days === undefined || days === '') return '—';
  const count = Number(days);
  if (isNaN(count)) return '—';
  if (count === 0) return 'Немає';
  return pluralizeDaysUk(count);
}

export async function renderClientDashboard() {
  try {
    const profile = await clientApi.getProfile();
    const subs = await clientApi.getSubscriptions();
    const bookings = await clientApi.getBookings();

    cachedClientSubscriptions = subs || [];
    cachedClientBookings = bookings || [];

    const nameHeading = document.getElementById('client-name-heading');
    if (nameHeading) nameHeading.textContent = profile.fullName;
    const detailsSub = document.getElementById('client-details-sub');
    if (detailsSub) detailsSub.textContent = `Телефон: ${profile.phone} | ID: #${profile.clientId} | Логін: ${profile.dbUser}`;

    function isTrivialMedNotes(str) {
      if (!str) return true;
      const s = str.trim().toLowerCase();
      return s === '' || s === 'none' || s === '-' || s === 'немає' || s === 'немає обмежень' || s === 'відсутні' || s === 'обмежень немає';
    }

    const medAlertEl = document.getElementById('client-medical-alert');
    if (medAlertEl) {
      const hasMed = profile.medicalNotes && profile.medicalNotes.trim() && !isTrivialMedNotes(profile.medicalNotes);
      if (hasMed) {
        medAlertEl.innerHTML = `<i class="fa-solid fa-notes-medical text-rose-400"></i> <span class="font-medium">Медичні застереження: ${profile.medicalNotes}</span>`;
        medAlertEl.className = 'mt-2 text-xs text-rose-300 bg-rose-500/10 px-2.5 py-1 rounded-lg inline-flex items-center gap-1.5 border border-rose-500/30 font-mono';
      } else {
        medAlertEl.innerHTML = `<i class="fa-solid fa-circle-check text-slate-400"></i> <span>Медичні обмеження: Відсутні</span>`;
        medAlertEl.className = 'mt-2 text-xs text-slate-400 bg-slate-500/10 px-2.5 py-1 rounded-lg inline-flex items-center gap-1.5 border border-slate-500/20 font-mono';
      }
    }

    const activeSub = (subs && subs.length) ? subs[0] : null;
    const subBadge = document.getElementById('client-sub-badge');
    const metricExpiry = document.getElementById('client-metric-expiry');
    const metricFreezing = document.getElementById('client-metric-freezing');
    const freezingLeft = document.getElementById('cl3-freezing-days-left');

    if (metricExpiry) {
      metricExpiry.className = 'text-cyan-400 font-bold text-base mt-1';
      metricExpiry.style.setProperty('color', '#22d3ee', 'important');
    }
    if (metricFreezing) {
      metricFreezing.className = 'text-cyan-400 font-bold text-base mt-1';
      metricFreezing.style.setProperty('color', '#22d3ee', 'important');
    }

    // Remove old unfreeze button from header if present
    const oldUnfreezeBtn = document.getElementById('client-sub-unfreeze-btn');
    if (oldUnfreezeBtn) oldUnfreezeBtn.remove();

    if (activeSub) {
      if (subBadge) {
        subBadge.className = `badge badge-${(activeSub.currentStatus || 'active').toLowerCase()}`;
        if (activeSub.currentStatus === 'Frozen') {
          subBadge.textContent = 'Заморожено';
        } else if (activeSub.currentStatus === 'Active') {
          subBadge.textContent = `Активний (${activeSub.itemName})`;
        } else {
          subBadge.textContent = activeSub.currentStatus;
        }
      }

      if (metricExpiry) metricExpiry.textContent = formatExpiryDate(activeSub.endDate);
      const remDays = (activeSub.remainingFreezingDays !== undefined && activeSub.remainingFreezingDays !== null && activeSub.remainingFreezingDays !== '')
        ? Number(activeSub.remainingFreezingDays)
        : 0;
      if (metricFreezing) metricFreezing.textContent = formatFreezingDays(remDays);
      if (freezingLeft) freezingLeft.textContent = isNaN(remDays) ? 0 : remDays;
    } else {
      if (subBadge) {
        subBadge.className = 'badge badge-expired';
        subBadge.textContent = 'Немає активного абонемента';
      }
      if (metricExpiry) metricExpiry.textContent = '—';
      if (metricFreezing) metricFreezing.textContent = '—';
      if (freezingLeft) freezingLeft.textContent = '0';
    }

    // Update Quick Action Cl3 button according to subscription status
    const quickFreezeBtn = document.getElementById('client-quick-freeze-btn');
    const quickFreezeIcon = document.getElementById('client-quick-freeze-icon');
    const quickFreezeTitle = document.getElementById('client-quick-freeze-title');
    const quickFreezeDesc = document.getElementById('client-quick-freeze-desc');

    if (quickFreezeBtn) {
      if (activeSub && activeSub.currentStatus === 'Frozen') {
        if (quickFreezeIcon) {
          quickFreezeIcon.className = 'fa-solid fa-sun text-lg block mb-1 text-cyan-400 group-hover:scale-110 transition-transform';
        }
        if (quickFreezeTitle) {
          quickFreezeTitle.textContent = 'Розморозити (Cl3)';
        }
        if (quickFreezeDesc) {
          quickFreezeDesc.textContent = 'Відновити дію';
        }
        quickFreezeBtn.onclick = () => window.handleCl3Unfreeze(activeSub.clientSubId);
      } else {
        if (quickFreezeIcon) {
          quickFreezeIcon.className = 'fa-solid fa-snowflake text-lg block mb-1 text-cyan-300 group-hover:scale-110 transition-transform';
        }
        if (quickFreezeTitle) {
          quickFreezeTitle.textContent = 'Заморозка (Cl3)';
        }
        if (quickFreezeDesc) {
          quickFreezeDesc.textContent = 'Призупинити';
        }
        quickFreezeBtn.onclick = () => window.switchClientTab('cl3');
      }
    }

    renderCl3Tab(activeSub);

    const cl1Name = document.getElementById('cl1-name') || document.getElementById('cl1-fullname');
    if (cl1Name) cl1Name.value = profile.fullName || '';
    const cl1Phone = document.getElementById('cl1-phone');
    if (cl1Phone) cl1Phone.value = profile.phone || '';
    const cl1Med = document.getElementById('cl1-mednotes');
    if (cl1Med) cl1Med.value = profile.medicalNotes || '';

    const listEl = document.getElementById('client-upcoming-list');
    if (listEl) {
      listEl.innerHTML = '';
      if (!bookings || !bookings.length) {
        listEl.innerHTML = '<p class="text-xs text-slate-500 p-3 italic font-mono">Немає запланованих занять. Запишіться у розділі Cl4/Cl5!</p>';
      } else {
        bookings.forEach(b => {
          const item = document.createElement('div');
          item.className = 'flex justify-between items-center gap-3 p-3 rounded-lg border border-subtle bg-surface-elevated text-xs';
          item.style.backgroundColor = '#131a2e';
          item.style.borderColor = '#1a2236';
          item.innerHTML = `
            <div class="min-w-0 flex-1">
              <span class="font-bold text-white font-heading">[${b.activityType}] ${b.title}</span>
              <div class="text-slate-400 mt-0.5">Тренер: <b class="text-slate-200">${b.coachName || '—'}</b> | Зал: <b class="text-slate-200">${b.hallName || '—'}</b></div>
              <div class="text-[11px] text-cyan-400 font-semibold font-mono mt-1"><i class="fa-regular fa-clock mr-1"></i> ${b.trainingDateTime || '—'}</div>
            </div>
            <span class="badge badge-${(b.status || 'Active').toLowerCase()} shrink-0">${b.status}</span>
          `;
          listEl.appendChild(item);
        });
      }
    }

    await populateCl2Options();
    await populateCl45Options();
    populateCl6Options();
  } catch (err) {
    console.warn('API Client dashboard load error:', err);
  }
}

export async function handleCl1Profile(e) {
  e.preventDefault();
  const nameInput = document.getElementById('cl1-name') || document.getElementById('cl1-fullname');
  const fullName = nameInput ? nameInput.value.trim() : '';
  const phone = document.getElementById('cl1-phone').value.trim();
  const medNotes = document.getElementById('cl1-mednotes').value.trim();
  const currentClientId = AppState.currentUser?.clientId || 1;

  if (!fullName) {
    showToast('Будь ласка, вкажіть ПІБ!', 'warning');
    return;
  }

  // Cl1: Check phone uniqueness against other registered clients
  const isDuplicate = INITIAL_CLIENT_PHONES.some(c => c.phone === phone && c.id !== currentClientId);
  if (isDuplicate) {
    showToast('Цей номер телефону вже використовується іншим клієнтом!', 'danger');
    return;
  }

  try {
    await clientApi.updateProfile({
      fullName,
      phone,
      medicalNotes: medNotes
    });

    if (AppState.currentUser) {
      AppState.currentUser.name = fullName;
      setCurrentUser(AppState.currentUser);
      sessionStorage.setItem(STORAGE_KEYS.CURRENT_USER, JSON.stringify(AppState.currentUser));
    }
    updateHeaderUI();

    showToast('Профіль та медичні примітки успішно збережено в базі! (Cl1)', 'success');
    await renderClientDashboard();
  } catch (err) {
    if (err.message && (err.message.includes('унікальност') || err.message.includes('unique') || err.message.includes('Conflict'))) {
      showToast('Цей номер телефону вже використовується іншим клієнтом!', 'danger');
    } else {
      showToast(`Помилка оновлення профілю: ${err.message}`, 'danger');
    }
  }
}

export async function populateCl2Options() {
  const select = document.getElementById('cl2-item');
  if (!select) return;

  try {
    if (!cachedPriceList.length) {
      const data = await guestApi.getPriceList();
      cachedPriceList = data.map(item => ({
        id: item.itemId,
        name: item.itemName,
        category: item.category,
        price: item.price
      }));
    }

    select.innerHTML = '';
    cachedPriceList.filter(item => item.category === 'Membership').forEach(item => {
      const opt = document.createElement('option');
      opt.value = item.id;
      opt.textContent = `${item.name} (${parseFloat(item.price).toFixed(2)} грн)`;
      select.appendChild(opt);
    });

    if (!cachedClientSubscriptions || !cachedClientSubscriptions.length) {
      try {
        const subs = await clientApi.getSubscriptions();
        if (subs) cachedClientSubscriptions = subs;
      } catch (subErr) {
        console.warn('Could not fetch client subscriptions for Cl2:', subErr);
      }
    }

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const pad = n => String(n).padStart(2, '0');
    const todayStr = `${today.getFullYear()}-${pad(today.getMonth() + 1)}-${pad(today.getDate())}`;

    // Find the latest active/frozen subscription
    const eligibleSubs = (cachedClientSubscriptions || []).filter(s => {
      const isStatusOk = s.currentStatus === 'Active' || s.currentStatus === 'Frozen';
      const endStr = typeof s.endDate === 'string' ? s.endDate.substring(0, 10) : '';
      return isStatusOk && endStr >= todayStr;
    });
    eligibleSubs.sort((a, b) => String(b.endDate).localeCompare(String(a.endDate)));
    const activeSub = eligibleSubs[0] || null;

    const submitBtn = document.getElementById('cl2-submit-btn');
    const noticeEl = document.getElementById('cl2-restriction-notice');
    const infoEl = document.getElementById('cl2-startdate-info');

    if (activeSub) {
      const m = String(activeSub.endDate).trim().match(/^(\d{4})-(\d{2})-(\d{2})/);
      const endDateObj = m
        ? new Date(parseInt(m[1], 10), parseInt(m[2], 10) - 1, parseInt(m[3], 10))
        : new Date(activeSub.endDate);

      const diffMs = endDateObj.getTime() - today.getTime();
      const daysUntilEnd = Math.round(diffMs / (1000 * 60 * 60 * 24));

      const nextStartObj = new Date(endDateObj.getFullYear(), endDateObj.getMonth(), endDateObj.getDate() + 1);
      const nextStartDate = `${nextStartObj.getFullYear()}-${pad(nextStartObj.getMonth() + 1)}-${pad(nextStartObj.getDate())}`;

      const availFromObj = new Date(endDateObj.getFullYear(), endDateObj.getMonth(), endDateObj.getDate() - 7);
      const availableFromDate = `${availFromObj.getFullYear()}-${pad(availFromObj.getMonth() + 1)}-${pad(availFromObj.getDate())}`;

      if (daysUntilEnd > 7) {
        if (submitBtn) submitBtn.disabled = true;
        if (noticeEl) {
          noticeEl.className = 'p-3 bg-amber-500/10 border border-amber-500/30 rounded-xl text-xs text-amber-300 font-mono flex items-start gap-2.5';
          noticeEl.innerHTML = `<i class="fa-solid fa-triangle-exclamation text-amber-400 mt-0.5 shrink-0"></i> <span>Продовження абонемента стане доступним з <b>${availableFromDate}</b> (не раніше ніж за 7 днів до завершення поточного).</span>`;
          noticeEl.classList.remove('hidden');
        }
        if (infoEl) {
          infoEl.textContent = `Дата початку дії: ${nextStartDate} (автоматично після закінчення діючого).`;
        }
      } else {
        if (submitBtn) submitBtn.disabled = false;
        if (noticeEl) {
          noticeEl.innerHTML = '';
          noticeEl.classList.add('hidden');
        }
        if (infoEl) {
          infoEl.textContent = `Дата початку дії: ${nextStartDate} (автоматично наступного дня після закінчення діючого).`;
        }
      }
    } else {
      if (submitBtn) submitBtn.disabled = false;
      if (noticeEl) {
        noticeEl.innerHTML = '';
        noticeEl.classList.add('hidden');
      }
      if (infoEl) {
        infoEl.textContent = `Дата початку дії: ${todayStr} (поточний день).`;
      }
    }

    updateCl2Price();
  } catch (err) {
    console.warn('Error populating Cl2 options:', err);
  }
}

export function updateCl2Price() {
  const itemSelect = document.getElementById('cl2-item');
  if (!itemSelect) return;
  const itemId = parseInt(itemSelect.value);
  const display = document.getElementById('cl2-price-display');
  const promoInput = document.getElementById('cl2-promo')?.value.trim().toUpperCase() || '';

  const item = cachedPriceList.find(p => p.id === itemId);
  if (!item) return;

  let price = parseFloat(item.price);
  const promo = findPromo(promoInput);
  const now = new Date().toISOString().split('T')[0];
  if (promo && !(promo.expiryDate && promo.expiryDate < now)) {
    price = (price * (100 - promo.discountPercent)) / 100;
  }
  if (display) display.textContent = `${price.toFixed(2)} грн`;
}

export function checkCl2Promo() {
  const code = document.getElementById('cl2-promo')?.value.trim().toUpperCase();
  if (!code) {
    showToast('Введіть промокод', 'warning');
    updateCl2Price();
    return;
  }

  const promo = findPromo(code);
  const now = new Date().toISOString().split('T')[0];

  if (!promo) {
    showToast('Промокод не знайдено або термін його дії вичерпано', 'warning');
    updateCl2Price();
    return;
  }

  if (promo.expiryDate && promo.expiryDate < now) {
    showToast('Термін дії промокоду вичерпано!', 'warning');
    updateCl2Price();
    return;
  }

  showToast(`Промокод ${code} на ${promo.discountPercent}% успішно застосовано!`, 'success');
  updateCl2Price();
}

export async function handleCl2Renew(e) {
  e.preventDefault();
  const itemId = parseInt(document.getElementById('cl2-item').value);
  const promoCode = document.getElementById('cl2-promo').value.trim().toUpperCase() || null;

  if (promoCode) {
    const promo = findPromo(promoCode);
    const now = new Date().toISOString().split('T')[0];
    if (promo && promo.expiryDate && promo.expiryDate < now) {
      showToast('Термін дії промокоду вичерпано!', 'warning');
      return;
    }
  }

  try {
    const res = await clientApi.renewSubscription({ itemId, promoCode });
    showToast(`Абонемент успішно продовжено до ${res.endDate}! (Cl2)`, 'success');
    await renderClientDashboard();
    await populateCl2Options();
    switchClientTab('cl_dash');
  } catch (err) {
    showToast(err.message || 'Помилка оформлення абонемента', 'danger');
  }
}

export async function handleCl3Freeze(e) {
  e.preventDefault();
  const startStr = document.getElementById('cl3-start').value;
  const endStr = document.getElementById('cl3-end').value;
  const reason = document.getElementById('cl3-reason').value.trim();

  if (!cachedClientSubscriptions.length) {
    showToast('У вас немає активного абонемента для заморозки.', 'warning');
    return;
  }

  const activeSub = cachedClientSubscriptions[0];

  try {
    await clientApi.freezeSubscription({
      clientSubId: activeSub.clientSubId,
      startDate: startStr,
      endDate: endStr,
      reason
    });
    showToast('Абонемент успішно заморожено! (Cl3)', 'success');
    await renderClientDashboard();
    switchClientTab('cl_dash');
  } catch (err) {
    showToast(`Помилка заморозки: ${err.message}`, 'danger');
  }
}

export function renderCl3Tab(activeSub) {
  const form = document.getElementById('form-cl3-freeze');
  const card = form?.parentElement;
  if (!card) return;

  let frozenBanner = document.getElementById('cl3-frozen-banner');

  if (activeSub && activeSub.currentStatus === 'Frozen') {
    if (form) form.classList.add('hidden');
    if (!frozenBanner) {
      frozenBanner = document.createElement('div');
      frozenBanner.id = 'cl3-frozen-banner';
      card.appendChild(frozenBanner);
    }
    frozenBanner.className = 'space-y-4 text-center py-4';
    frozenBanner.innerHTML = `
      <div class="p-4 bg-cyan-500/10 border border-cyan-500/30 rounded-xl">
        <div class="w-12 h-12 mx-auto rounded-full bg-cyan-500/20 text-cyan-400 flex items-center justify-center text-xl mb-3">
          <i class="fa-solid fa-snowflake"></i>
        </div>
        <h4 class="font-bold text-white text-base font-heading">Абонемент наразі заморожено</h4>
        <p class="text-xs text-slate-300 mt-2">
          Дія абонемента тимчасово призупинена. Розрахункова дата завершення дії: <b class="text-cyan-400 font-mono">${formatExpiryDate(activeSub.endDate)}</b>.
        </p>
        <p class="text-xs text-slate-400 mt-1">
          Доступний залишок днів заморозки: <b class="text-white font-mono">${formatFreezingDays(activeSub.remainingFreezingDays)}</b>.
        </p>
      </div>
      <button type="button" onclick="handleCl3Unfreeze(${activeSub.clientSubId})" class="btn btn-primary w-full py-2.5 font-bold flex items-center justify-center gap-2">
        <i class="fa-solid fa-sun text-cyan-400"></i> Відновити дію абонемента (Розморозити)
      </button>
    `;
    frozenBanner.classList.remove('hidden');
  } else {
    if (form) form.classList.remove('hidden');
    if (frozenBanner) frozenBanner.classList.add('hidden');
  }
}

export async function handleCl3Unfreeze(clientSubId) {
  if (!clientSubId && cachedClientSubscriptions.length) {
    clientSubId = cachedClientSubscriptions[0].clientSubId;
  }
  if (!clientSubId) {
    showToast('Абонемент для розморожування не знайдено.', 'warning');
    return;
  }

  const confirmed = confirm('Ви впевнені, що бажаєте достроково розморозити абонемент та відновити його дію?');
  if (!confirmed) return;

  try {
    const res = await clientApi.unfreezeSubscription(clientSubId);
    showToast(res?.message || 'Заморозку успішно скасовано. Абонемент активовано.', 'success');
    await renderClientDashboard();
    switchClientTab('cl_dash');
  } catch (err) {
    showToast(`Помилка розморожування: ${err.message}`, 'danger');
  }
}

export async function populateCl45Options() {
  try {
    const [halls, coaches, groupClasses] = await Promise.all([
      guestApi.getHalls(),
      guestApi.getCoaches(),
      clientApi.getAvailableGroupClasses().catch(() => [])
    ]);

    const cl4Instance = document.getElementById('cl4-instance');
    if (cl4Instance) {
      cl4Instance.innerHTML = '';
      if (groupClasses && groupClasses.length > 0) {
        groupClasses.forEach(gc => {
          const opt = document.createElement('option');
          opt.value = gc.instanceId;
          const timeStr = gc.startTime ? gc.startTime.substring(0, 5) : '';
          const dateObj = new Date(gc.classDate + 'T' + (gc.startTime || '00:00:00'));
          const dayNames = ['Нд', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
          const dayUa = isNaN(dateObj.getDay()) ? '' : dayNames[dateObj.getDay()] + ' ';
          const bookedTag = gc.isBookedByMe ? ' [Ви вже записані]' : '';
          const spotsTag = gc.availableSpots > 0 ? `вільно місць: ${gc.availableSpots}/${gc.maxCapacity}` : 'місць немає';
          opt.textContent = `${gc.title} — ${dayUa}${gc.classDate} ${timeStr} (${gc.hallName}, тренер: ${gc.coachName}) [${spotsTag}]${bookedTag}`;
          if (gc.availableSpots <= 0 || gc.isBookedByMe) {
            opt.disabled = true;
          }
          cl4Instance.appendChild(opt);
        });
      } else {
        cl4Instance.innerHTML = '<option value="" disabled selected>Немає запланованих групових занять</option>';
      }
    }

    const cl5Hall = document.getElementById('cl5-hall');
    if (cl5Hall) {
      cl5Hall.innerHTML = '';
      halls.forEach(h => {
        const opt = document.createElement('option');
        opt.value = h.hallId;
        opt.textContent = `${h.hallName} (Місткість: ${h.maxCapacity})`;
        cl5Hall.appendChild(opt);
      });
    }

    const cl5Coach = document.getElementById('cl5-coach');
    if (cl5Coach) {
      cl5Coach.innerHTML = '<option value="" disabled selected>-- Оберіть тренера --</option>';
      coaches.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c.coachId;
        opt.textContent = `${c.fullName} (${c.specName || 'Тренер'})`;
        cl5Coach.appendChild(opt);
      });
      refreshCombobox(cl5Coach);
    }

    // Default datetime + 1 day
    const tmr = new Date();
    tmr.setDate(tmr.getDate() + 1);
    tmr.setHours(12, 0, 0, 0);
    const dtEl = document.getElementById('cl5-datetime');
    if (dtEl) {
      dtEl.value = tmr.toISOString().substring(0, 16);
      dtEl.min = new Date().toISOString().substring(0, 16);
    }
  } catch (err) {
    console.warn('Error populating Cl4/Cl5 options:', err);
  }
}

export async function handleCl4Booking(e) {
  e.preventDefault();
  const select = document.getElementById('cl4-instance');
  const instanceId = parseInt(select?.value || '0');
  if (!instanceId) {
    showToast('Будь ласка, оберіть доступне заняття.', 'warning');
    return;
  }

  // Duplicate check: strictly by instanceId
  const alreadyBooked = (cachedClientBookings || []).some(b => 
    (b.activityType || '').toLowerCase() === 'group' &&
    (b.status || '').toLowerCase() === 'scheduled' &&
    b.instanceId === instanceId
  );

  if (alreadyBooked) {
    showToast('Ви вже записані на це тренування!', 'warning');
    return;
  }

  try {
    const activeSub = cachedClientSubscriptions.find(s => s.currentStatus === 'Active' && new Date(s.endDate) >= new Date()) || cachedClientSubscriptions[0];
    const saleId = activeSub ? activeSub.saleId : null;
    await clientApi.bookGroupClass({ instanceId, saleId });
    showToast('Успішно записано на групове заняття! (Cl4)', 'success');
    await renderClientDashboard();
    switchClientTab('cl_dash');
  } catch (err) {
    if (err.message && (err.message.includes('вже') || err.message.includes('дубл') || err.message.includes('duplicate'))) {
      showToast('Ви вже записані на це тренування!', 'warning');
    } else {
      showToast(`Помилка запису: ${err.message}`, 'danger');
    }
  }
}

export async function handleCl5Booking(e) {
  e.preventDefault();
  const coachId = parseInt(document.getElementById('cl5-coach').value);
  const hallId = parseInt(document.getElementById('cl5-hall').value);
  const dt = document.getElementById('cl5-datetime').value;

  // Cl5: Date cannot be in the past
  const selectedTime = new Date(dt);
  const now = new Date();
  if (isNaN(selectedTime.getTime()) || selectedTime < now) {
    showToast('Дата й час тренування не можуть бути в минулому!', 'warning');
    return;
  }

  // Cl5: Double-booking collision check
  const slotKey = `${coachId}_${dt}`;
  if (bookedCoachSlots.has(slotKey)) {
    showToast('Обраний тренер уже має призначене тренування на цей час. Будь ласка, оберіть інший слот', 'warning');
    return;
  }

  try {
    const activeSub = cachedClientSubscriptions.find(s => s.currentStatus === 'Active' && new Date(s.endDate) >= new Date()) || cachedClientSubscriptions[0];
    const saleId = activeSub ? activeSub.saleId : null;
    await clientApi.bookPersonalTraining({
      coachId,
      hallId,
      trainingDateTime: dt,
      saleId
    });
    bookedCoachSlots.add(slotKey);
    showToast('Персональне тренування успішно заброньовано! (Cl5)', 'success');
    await renderClientDashboard();
    switchClientTab('cl_dash');
  } catch (err) {
    if (err.message && (err.message.includes('зайнятий') || err.message.includes('конфлікт') || err.message.includes('conflict'))) {
      showToast(err.message, 'warning');
    } else {
      showToast(`Помилка запису: ${err.message}`, 'danger');
    }
  }
}

export function populateCl6Options() {
  const sel = document.getElementById('cl6-booking');
  if (!sel) return;

  sel.innerHTML = '';
  const activeBookings = (cachedClientBookings || []).filter(b => 
    !b.status || b.status.toLowerCase() === 'scheduled' || b.status.toLowerCase() === 'active'
  );

  if (!activeBookings.length) {
    sel.innerHTML = '<option value="" disabled selected>Немає активних бронювань для скасування</option>';
    return;
  }

  sel.innerHTML = '<option value="" disabled selected>-- Оберіть заняття для скасування --</option>';
  activeBookings.forEach(b => {
    const isPersonal = (b.activityType || '').toLowerCase() === 'personal';
    const prefix = isPersonal ? 'pt_' : 'grp_';
    const opt = document.createElement('option');
    opt.value = `${prefix}${b.bookingId}`;
    opt.textContent = `[${isPersonal ? 'Персональне' : 'Групове'}] ${b.title} (${b.trainingDateTime || '—'})`;
    sel.appendChild(opt);
  });
}

export async function handleCl6Cancel(e) {
  e.preventDefault();
  const val = document.getElementById('cl6-booking').value;
  const reason = document.getElementById('cl6-reason').value.trim() || 'Скасовано клієнтом';

  if (!val) {
    showToast('Оберіть заняття!', 'warning');
    return;
  }

  let bookingType = 'Personal';
  let bookingId = null;

  if (val.startsWith('pt_')) {
    bookingType = 'Personal';
    bookingId = parseInt(val.replace('pt_', ''));
  } else if (val.startsWith('grp_')) {
    bookingType = 'Group';
    bookingId = parseInt(val.replace('grp_', ''));
  } else if (val.includes('_')) {
    const [type, idStr] = val.split('_');
    bookingType = type.toLowerCase() === 'group' ? 'Group' : 'Personal';
    bookingId = parseInt(idStr);
  } else {
    bookingId = parseInt(val);
  }

  try {
    await clientApi.cancelBooking({
      bookingType,
      bookingId,
      reason
    });
    bookedCoachSlots.clear();
    showToast('Бронювання успішно скасовано! (Cl6)', 'success');
    await renderClientDashboard();
    switchClientTab('cl_dash');
  } catch (err) {
    showToast(`Помилка скасування: ${err.message}`, 'danger');
  }
}
