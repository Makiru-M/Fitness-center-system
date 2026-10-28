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
let cachedGroupClasses = [];
let currentWeekOffset = 0;
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
  let norm = (tabId || '').replace('_', '-');
  if (norm === 'cl45' || tabId === 'cl45') {
    norm = 'cl4';
    tabId = 'cl4';
  }

  document.querySelectorAll('.client-pane').forEach(el => el.classList.add('hidden'));
  document.querySelectorAll('#view-client .nav-tab-btn').forEach(b => b.classList.remove('active'));

  const pane = document.getElementById(`subtab-${norm}`) || document.getElementById(`subtab-${tabId}`);
  const btn = document.getElementById(`tab-btn-${norm}`) || document.getElementById(`tab-btn-${tabId}`);
  if (pane) pane.classList.remove('hidden');
  if (btn) btn.classList.add('active');

  if (norm === 'cl2' || tabId === 'cl2') {
    populateCl2Options();
  }
  if (norm === 'cl4' || tabId === 'cl4') {
    renderCl4Schedule();
    populateCl45Options();
  }
  if (norm === 'cl5' || tabId === 'cl5') {
    populateCl45Options();
  }
  if (norm === 'cl6' || tabId === 'cl6') {
    populateCl6Options();
  }
  if (norm === 'cl3' || tabId === 'cl3') {
    initCl3DateLimits();
  }
}

export function initCl3DateLimits() {
  const today = new Date().toISOString().split('T')[0];
  const startEl = document.getElementById('cl3-start');
  const endEl = document.getElementById('cl3-end');
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

export function formatTrainingDateTime(dtStr) {
  if (!dtStr) return '—';
  const clean = String(dtStr).trim();
  if (!clean) return '—';

  // If already formatted (e.g. DD.MM.YYYY HH:mm or YYYY-MM-DD HH:mm without T)
  const isoPattern = /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::\d{2})?/;
  const match = clean.match(isoPattern);
  if (match) {
    const [, yyyy, mm, dd, hh, min] = match;
    return `${dd}.${mm}.${yyyy} ${hh}:${min}`;
  }

  const d = new Date(clean);
  if (!isNaN(d.getTime())) {
    const day = String(d.getDate()).padStart(2, '0');
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const year = d.getFullYear();
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');
    return `${day}.${month}.${year} ${hours}:${minutes}`;
  }

  return clean.replace('T', ' ');
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

    if (quickFreezeBtn) {
      if (activeSub && activeSub.currentStatus === 'Frozen') {
        if (quickFreezeIcon) {
          quickFreezeIcon.className = 'fa-solid fa-sun text-lg block mb-1 text-cyan-400 group-hover:scale-110 transition-transform';
        }
        if (quickFreezeTitle) {
          quickFreezeTitle.textContent = 'Розморозити (Cl3)';
        }
        quickFreezeBtn.onclick = () => window.handleCl3Unfreeze(activeSub.clientSubscriptionId || activeSub.clientSubId);
      } else {
        if (quickFreezeIcon) {
          quickFreezeIcon.className = 'fa-solid fa-snowflake text-lg block mb-1 text-cyan-300 group-hover:scale-110 transition-transform';
        }
        if (quickFreezeTitle) {
          quickFreezeTitle.textContent = 'Заморозка (Cl3)';
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
      const sortedBookings = [...(bookings || [])].sort((a, b) => {
        const isSchedA = (a.status || '').toLowerCase() === 'scheduled';
        const isSchedB = (b.status || '').toLowerCase() === 'scheduled';
        if (isSchedA && !isSchedB) return -1;
        if (!isSchedA && isSchedB) return 1;
        
        const timeA = new Date(a.trainingDateTime || 0).getTime();
        const timeB = new Date(b.trainingDateTime || 0).getTime();
        if (isSchedA && isSchedB) {
          return timeA - timeB; // Earliest upcoming first
        }
        return timeB - timeA; // Latest completed/cancelled first
      });

      if (!sortedBookings || !sortedBookings.length) {
        listEl.innerHTML = '<p class="text-xs text-slate-500 p-3 italic font-mono">Немає запланованих занять. Запишіться у розділі Cl4 або Cl5!</p>';
      } else {
        sortedBookings.forEach(b => {
          const item = document.createElement('div');
          item.className = 'flex justify-between items-center gap-3 p-3 rounded-lg border border-subtle bg-surface-elevated text-xs';
          item.style.backgroundColor = '#131a2e';
          item.style.borderColor = '#1a2236';
          const isPersonal = (b.activityType || '').toLowerCase() === 'personal';
          const typeLabel = isPersonal ? 'Персональне' : 'Групове';
          const formattedTime = formatTrainingDateTime(b.trainingDateTime);
          item.innerHTML = `
            <div class="min-w-0 flex-1 space-y-0.5">
              <div class="font-bold text-white font-heading">[${typeLabel}] ${b.title}</div>
              <div class="text-slate-300 text-xs">Тренер: <b class="text-white">${b.coachName || '—'}</b></div>
              <div class="text-slate-300 text-xs">Зал: <b class="text-white">${b.hallName || '—'}</b></div>
              <div class="text-cyan-400 font-semibold font-mono text-[11px] pt-0.5">
                <i class="fa-regular fa-clock mr-1"></i> ${formattedTime}
              </div>
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
    const nameHeading = document.getElementById('client-name-heading');
    if (nameHeading) {
      const loginName = AppState.currentUser?.name || AppState.currentUser?.dbUser || 'Клієнт';
      nameHeading.textContent = loginName;
    }
    const detailsSub = document.getElementById('client-details-sub');
    if (detailsSub) {
      detailsSub.textContent = 'Помилка завантаження даних або профіль не знайдено';
    }
    const subBadge = document.getElementById('client-sub-badge');
    if (subBadge) {
      subBadge.className = 'badge badge-expired';
      subBadge.textContent = '—';
    }
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

  const today = new Date().toISOString().split('T')[0];
  if (startStr < today) {
    showToast('Дата початку заморозки не може бути в минулому!', 'warning');
    return;
  }
  if (endStr <= startStr) {
    showToast('Дата закінчення заморозки повинна бути пізнішою за дату початку!', 'warning');
    return;
  }

  if (!cachedClientSubscriptions.length) {
    showToast('У вас немає активного абонемента для заморозки.', 'warning');
    return;
  }

  const activeSub = cachedClientSubscriptions[0];

  try {
    await clientApi.freezeSubscription({
      clientSubscriptionId: activeSub.clientSubscriptionId || activeSub.clientSubId,
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
      <button type="button" onclick="handleCl3Unfreeze(${activeSub.clientSubscriptionId || activeSub.clientSubId})" class="btn btn-primary w-full py-2.5 font-bold flex items-center justify-center gap-2">
        <i class="fa-solid fa-sun text-cyan-400"></i> Відновити дію абонемента (Розморозити)
      </button>
    `;
    frozenBanner.classList.remove('hidden');
  } else {
    if (form) form.classList.remove('hidden');
    if (frozenBanner) frozenBanner.classList.add('hidden');
    initCl3DateLimits();
  }
}

export async function handleCl3Unfreeze(clientSubscriptionId) {
  if (!clientSubscriptionId && cachedClientSubscriptions.length) {
    clientSubscriptionId = cachedClientSubscriptions[0].clientSubscriptionId || cachedClientSubscriptions[0].clientSubId;
  }
  if (!clientSubscriptionId) {
    showToast('Абонемент для розморожування не знайдено.', 'warning');
    return;
  }

  const confirmed = confirm('Ви впевнені, що бажаєте достроково розморозити абонемент та відновити його дію?');
  if (!confirmed) return;

  try {
    const res = await clientApi.unfreezeSubscription(clientSubscriptionId);
    showToast(res?.message || 'Заморозку успішно скасовано. Абонемент активовано.', 'success');
    await renderClientDashboard();
    switchClientTab('cl_dash');
  } catch (err) {
    showToast(`Помилка розморожування: ${err.message}`, 'danger');
  }
}

function getMonday(date) {
  const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const day = d.getDay(); // 0 is Sunday, 1 is Monday...
  const diff = (day === 0 ? -6 : 1) - day;
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

function formatDateDisplay(d) {
  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const yyyy = d.getFullYear();
  return `${dd}.${mm}.${yyyy}`;
}

function formatIsoDate(d) {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

/**
 * Returns the most relevant/latest subscription of the client:
 * Non-expired subscriptions (endDate >= today), sorted by endDate DESC, then clientSubscriptionId DESC.
 * Matches PostgreSQL trigger fn_check_booking_client_subscription() logic.
 */
export function getLatestClientSubscription(subscriptions = cachedClientSubscriptions) {
  const todayStr = formatIsoDate(new Date());
  const validSubs = (subscriptions || []).filter(s => {
    const endStr = typeof s.endDate === 'string' ? s.endDate.substring(0, 10) : '';
    return !endStr || endStr >= todayStr;
  });

  if (!validSubs.length) return null;

  validSubs.sort((a, b) => {
    const endA = typeof a.endDate === 'string' ? a.endDate.substring(0, 10) : '';
    const endB = typeof b.endDate === 'string' ? b.endDate.substring(0, 10) : '';
    if (endB !== endA) {
      return endB.localeCompare(endA);
    }
    const idA = Number(a.clientSubscriptionId || a.clientSubId || 0);
    const idB = Number(b.clientSubscriptionId || b.clientSubId || 0);
    return idB - idA;
  });

  return validSubs[0];
}

function formatTimeRange(startTimeStr, durationMinutes) {
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

function isClassInPast(classDateStr, startTimeStr) {
  if (!classDateStr) return false;
  const time = startTimeStr ? (startTimeStr.length === 5 ? startTimeStr + ':00' : startTimeStr) : '00:00:00';
  const classDt = new Date(`${classDateStr.substring(0, 10)}T${time}`);
  if (isNaN(classDt.getTime())) return false;
  return classDt < new Date();
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

export function handleCl4PrevWeek() {
  if (currentWeekOffset <= 0) return;
  currentWeekOffset--;
  renderCl4Schedule();
}

export function handleCl4NextWeek() {
  if (currentWeekOffset >= 1) return;
  currentWeekOffset++;
  renderCl4Schedule();
}

export function handleCl4TodayWeek() {
  currentWeekOffset = 0;
  renderCl4Schedule();
}

export function renderCl4Schedule() {
  const gridContainer = document.getElementById('cl4-schedule-grid');
  const weekRangeEl = document.getElementById('cl4-week-range');
  const prevBtn = document.getElementById('cl4-prev-week');
  const nextBtn = document.getElementById('cl4-next-week');

  const baseMonday = getMonday(new Date());
  const selectedMonday = new Date(baseMonday);
  selectedMonday.setDate(selectedMonday.getDate() + currentWeekOffset * 7);

  const selectedSunday = new Date(selectedMonday);
  selectedSunday.setDate(selectedSunday.getDate() + 6);

  if (weekRangeEl) {
    weekRangeEl.textContent = `${formatDateDisplay(selectedMonday)} – ${formatDateDisplay(selectedSunday)}`;
  }

  if (prevBtn) {
    prevBtn.disabled = currentWeekOffset <= 0;
    if (currentWeekOffset <= 0) {
      prevBtn.classList.add('opacity-50', 'cursor-not-allowed');
    } else {
      prevBtn.classList.remove('opacity-50', 'cursor-not-allowed');
    }
  }

  if (nextBtn) {
    nextBtn.disabled = currentWeekOffset >= 1;
    if (currentWeekOffset >= 1) {
      nextBtn.classList.add('opacity-50', 'cursor-not-allowed');
    } else {
      nextBtn.classList.remove('opacity-50', 'cursor-not-allowed');
    }
  }

  if (!gridContainer) return;

  const DAY_NAMES = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayIso = formatIsoDate(today);

  gridContainer.innerHTML = '';

  for (let i = 0; i < 7; i++) {
    const dayDate = new Date(selectedMonday);
    dayDate.setDate(dayDate.getDate() + i);
    const dayIso = formatIsoDate(dayDate);
    const dayShort = `${String(dayDate.getDate()).padStart(2, '0')}.${String(dayDate.getMonth() + 1).padStart(2, '0')}`;
    const isToday = dayIso === todayIso;

    // Filter classes for this day
    const dayClasses = (cachedGroupClasses || []).filter(c => {
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
        const isBooked = Boolean(gc.isBookedByMe);
        const inPast = isClassInPast(gc.classDate, gc.startTime);
        const isFull = !isBooked && (gc.availableSpots <= 0);
        const canBook = !inPast && !isBooked && !isFull;

        let badgeHtml = '';
        let btnHtml = '';
        let cardClasses = 'p-2.5 rounded-xl border transition flex flex-col justify-between ';

        if (isBooked) {
          badgeHtml = `<span class="badge badge-active text-[10px] px-1.5 py-0.5 whitespace-nowrap shrink-0"><i class="fa-solid fa-check mr-1"></i> Ви записані</span>`;
          btnHtml = `<button type="button" disabled class="w-full mt-2.5 py-1.5 text-[11px] font-semibold text-emerald-300 bg-emerald-500/10 rounded-lg border border-emerald-500/20 cursor-default flex items-center justify-center gap-1"><i class="fa-solid fa-circle-check"></i> Записано</button>`;
          cardClasses += 'border-emerald-500/30 bg-emerald-950/20';
        } else if (isFull) {
          badgeHtml = `<span class="badge badge-expired text-[10px] px-1.5 py-0.5 whitespace-nowrap shrink-0"><i class="fa-solid fa-ban mr-1"></i> Місць немає</span>`;
          btnHtml = `<button type="button" disabled class="w-full mt-2.5 py-1.5 text-[11px] font-medium text-slate-400 bg-slate-800/40 rounded-lg border border-subtle cursor-not-allowed">Місць немає</button>`;
          cardClasses += 'border-subtle bg-void/50 opacity-75';
        } else if (inPast) {
          badgeHtml = `<span class="badge badge-neutral text-[10px] px-1.5 py-0.5 whitespace-nowrap shrink-0"><i class="fa-solid fa-clock-rotate-left mr-1"></i> Минуло</span>`;
          btnHtml = `<button type="button" disabled class="w-full mt-2.5 py-1.5 text-[11px] font-medium text-slate-500 bg-slate-800/30 rounded-lg border border-subtle cursor-not-allowed">Минуло</button>`;
          cardClasses += 'border-subtle bg-void/40 opacity-60';
        } else {
          badgeHtml = `<span class="badge badge-cyan text-[10px] font-mono px-1.5 py-0.5 whitespace-nowrap shrink-0">Вільно: ${gc.availableSpots}/${gc.maxCapacity}</span>`;
          btnHtml = `<button type="button" onclick="event.stopPropagation(); openGroupBookingModal(${gc.instanceId})" class="btn btn-primary btn-xs w-full py-1.5 mt-2.5 font-bold text-[11px] flex items-center justify-center gap-1 font-heading"><i class="fa-solid fa-plus text-[10px]"></i> Записатися</button>`;
          cardClasses += 'border-subtle bg-void hover:border-cyan-500/50 hover:bg-slate-800/40 cursor-pointer shadow-sm group';
        }

        const timeRange = formatTimeRange(gc.startTime, gc.durationMinutes);

        return `
          <div class="${cardClasses}" ${canBook ? `onclick="openGroupBookingModal(${gc.instanceId})"` : ''}>
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

const BASE_CL4_PRICE = 200.00;
const BASE_CL5_PRICE = 400.00;

export function updateCl4Price() {
  const display = document.getElementById('modal-cl4-price-display');
  const promoInput = document.getElementById('modal-cl4-promo')?.value.trim().toUpperCase() || '';
  const promoBadge = document.getElementById('modal-cl4-promo-badge');
  const confirmBtn = document.getElementById('modal-cl4-confirm-btn');

  const instId = parseInt(document.getElementById('modal-cl4-instance-id')?.value || '0', 10);
  const gc = cachedGroupClasses.find(c => c.instanceId === instId);
  const basePrice = (gc && gc.price != null && !isNaN(parseFloat(gc.price)))
    ? parseFloat(gc.price)
    : BASE_CL4_PRICE;

  let price = basePrice;
  const promo = findPromo(promoInput);
  const now = new Date().toISOString().split('T')[0];
  if (promo && !(promo.expiryDate && promo.expiryDate < now)) {
    price = (basePrice * (100 - promo.discountPercent)) / 100;
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
    confirmBtn.innerHTML = `<i class="fa-solid fa-credit-card mr-1"></i> Оплатити та записатися (${price.toFixed(2)} грн)`;
  }
}

export function applyCl4Promo() {
  const code = document.getElementById('modal-cl4-promo')?.value.trim().toUpperCase();
  if (!code) {
    showToast('Введіть промокод', 'warning');
    updateCl4Price();
    return;
  }

  const promo = findPromo(code);
  const now = new Date().toISOString().split('T')[0];

  if (!promo) {
    showToast('Промокод не знайдено або термін його дії вичерпано', 'warning');
    updateCl4Price();
    return;
  }

  if (promo.expiryDate && promo.expiryDate < now) {
    showToast('Термін дії промокоду вичерпано!', 'warning');
    updateCl4Price();
    return;
  }

  showToast(`Промокод ${code} на ${promo.discountPercent}% успішно застосовано!`, 'success');
  updateCl4Price();
}

export function updateCl5Price() {
  const display = document.getElementById('cl5-price-display');
  const promoInput = document.getElementById('cl5-promo')?.value.trim().toUpperCase() || '';
  const promoBadge = document.getElementById('cl5-promo-badge');
  const submitBtn = document.getElementById('cl5-submit-btn');

  const itemSel = document.getElementById('cl5-item');
  const selectedOpt = itemSel ? itemSel.options[itemSel.selectedIndex] : null;
  const basePrice = (selectedOpt && selectedOpt.dataset.price)
    ? parseFloat(selectedOpt.dataset.price)
    : BASE_CL5_PRICE;

  let price = basePrice;
  const promo = findPromo(promoInput);
  const now = new Date().toISOString().split('T')[0];
  if (promo && !(promo.expiryDate && promo.expiryDate < now)) {
    price = (basePrice * (100 - promo.discountPercent)) / 100;
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
    submitBtn.innerHTML = `<i class="fa-solid fa-credit-card mr-1"></i> Оплатити та записатися (${price.toFixed(2)} грн)`;
  }
}

export function applyCl5Promo() {
  const code = document.getElementById('cl5-promo')?.value.trim().toUpperCase();
  if (!code) {
    showToast('Введіть промокод', 'warning');
    updateCl5Price();
    return;
  }

  const promo = findPromo(code);
  const now = new Date().toISOString().split('T')[0];

  if (!promo) {
    showToast('Промокод не знайдено або термін його дії вичерпано', 'warning');
    updateCl5Price();
    return;
  }

  if (promo.expiryDate && promo.expiryDate < now) {
    showToast('Термін дії промокоду вичерпано!', 'warning');
    updateCl5Price();
    return;
  }

  showToast(`Промокод ${code} на ${promo.discountPercent}% успішно застосовано!`, 'success');
  updateCl5Price();
}

export async function populateCl45Options() {
  try {
    const [halls, coaches, groupClasses, priceList] = await Promise.all([
      guestApi.getHalls(),
      guestApi.getCoaches(),
      clientApi.getAvailableGroupClasses().catch(() => []),
      guestApi.getPriceList().catch(() => [])
    ]);

    cachedGroupClasses = groupClasses || [];
    renderCl4Schedule();

    // Populate Cl5 Personal Training Items from active PriceList
    const cl5Item = document.getElementById('cl5-item');
    if (cl5Item) {
      cl5Item.innerHTML = '';
      const personalItems = (priceList || []).filter(item => item.category === 'Personal training');
      if (personalItems.length > 0) {
        personalItems.forEach(item => {
          const opt = document.createElement('option');
          opt.value = item.itemId;
          opt.dataset.price = item.price;
          opt.textContent = `${item.itemName} — ${parseFloat(item.price).toFixed(2)} грн`;
          cl5Item.appendChild(opt);
        });
      } else {
        const opt = document.createElement('option');
        opt.value = '';
        opt.dataset.price = '400.00';
        opt.textContent = 'Персональне тренування — 400.00 грн';
        cl5Item.appendChild(opt);
      }
      updateCl5Price();
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
        opt.textContent = `${c.fullName} (${c.specializationName || c.specName || 'Тренер'})`;
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
      const nowIso = new Date().toISOString().substring(0, 16);
      const valIso = tmr.toISOString().substring(0, 16);
      dtEl.value = valIso;
      dtEl.min = nowIso;
      if (dtEl._flatpickr) {
        dtEl._flatpickr.set('minDate', nowIso);
        dtEl._flatpickr.setDate(valIso, false);
      }
    }

    // Prerequisite check for Cl5: active subscription
    if (!cachedClientSubscriptions || !cachedClientSubscriptions.length) {
      try {
        const subs = await clientApi.getSubscriptions();
        if (subs) cachedClientSubscriptions = subs;
      } catch (err) {
        console.warn('Could not fetch subscriptions for Cl5:', err);
      }
    }
    const latestSub = getLatestClientSubscription(cachedClientSubscriptions);
    const hasActiveSub = latestSub && latestSub.currentStatus === 'Active';
    const isFrozen = latestSub && latestSub.currentStatus === 'Frozen';
    const cl5SubmitBtn = document.getElementById('cl5-submit-btn');
    const cl5Warning = document.getElementById('cl5-no-sub-warning');

    if (hasActiveSub) {
      if (cl5SubmitBtn) {
        cl5SubmitBtn.disabled = false;
        cl5SubmitBtn.title = '';
      }
      if (cl5Warning) cl5Warning.classList.add('hidden');
    } else if (isFrozen) {
      if (cl5SubmitBtn) {
        cl5SubmitBtn.disabled = true;
        cl5SubmitBtn.title = 'Запис неможливий: абонемент заморожено';
      }
      if (cl5Warning) {
        cl5Warning.innerHTML = '<i class="fa-solid fa-snowflake text-cyan-400"></i> Запис неможливий: ваш абонемент заморожено. Достроково скасувати заморозку можна у вкладці «Абонемент».';
        cl5Warning.className = 'mb-4 p-3 rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-300 text-xs font-medium flex items-center gap-2';
        cl5Warning.classList.remove('hidden');
      }
    } else {
      if (cl5SubmitBtn) {
        cl5SubmitBtn.disabled = true;
        cl5SubmitBtn.title = 'Потрібен діючий абонемент';
      }
      if (cl5Warning) {
        cl5Warning.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-rose-400"></i> Для запису на персональні тренування необхідно мати діючий абонемент клубу.';
        cl5Warning.className = 'mb-4 p-3 rounded-lg bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs font-medium flex items-center gap-2';
        cl5Warning.classList.remove('hidden');
      }
    }

    const cl5Promo = document.getElementById('cl5-promo');
    if (cl5Promo) cl5Promo.value = '';
    const cl5Badge = document.getElementById('cl5-promo-badge');
    if (cl5Badge) cl5Badge.classList.add('hidden');
    const cl5PriceDisplay = document.getElementById('cl5-price-display');
    if (cl5PriceDisplay) cl5PriceDisplay.textContent = '400.00 грн';

    updateCl5Price();
  } catch (err) {
    console.warn('Error populating Cl4/Cl5 options:', err);
  }
}

export async function openGroupBookingModal(instanceId) {
  const gc = cachedGroupClasses.find(c => c.instanceId === instanceId);
  if (!gc) {
    showToast('Інформацію про заняття не знайдено', 'warning');
    return;
  }

  const instInput = document.getElementById('modal-cl4-instance-id');
  if (instInput) instInput.value = gc.instanceId;

  const titleEl = document.getElementById('modal-cl4-title');
  if (titleEl) {
    titleEl.textContent = gc.title;
    titleEl.style.color = '#ffffff';
  }
  const actEl = document.getElementById('modal-cl4-activity-type');
  if (actEl) actEl.textContent = 'Групове тренування';

  const dateEl = document.getElementById('modal-cl4-date');
  if (dateEl) {
    const parts = (gc.classDate || '').substring(0, 10).split('-');
    if (parts.length === 3) {
      dateEl.textContent = `${parts[2]}.${parts[1]}.${parts[0]}`;
    } else {
      dateEl.textContent = gc.classDate;
    }
  }
  const timeEl = document.getElementById('modal-cl4-time');
  if (timeEl) {
    const range = formatTimeRange(gc.startTime, gc.durationMinutes);
    timeEl.textContent = `${range} (${gc.durationMinutes || 60} хв)`;
  }

  const coachEl = document.getElementById('modal-cl4-coach');
  if (coachEl) coachEl.textContent = `Тренер: ${gc.coachName}`;
  const hallEl = document.getElementById('modal-cl4-hall');
  if (hallEl) hallEl.textContent = `Зал: ${gc.hallName}`;

  const spotsEl = document.getElementById('modal-cl4-spots');
  if (spotsEl) {
    spotsEl.textContent = `Вільно: ${gc.availableSpots} / ${gc.maxCapacity}`;
    spotsEl.className = gc.availableSpots > 0 ? 'badge badge-active text-xs font-mono' : 'badge badge-expired text-xs font-mono';
  }

  // Reset promo code input, promo badge and reset price
  const promoInput = document.getElementById('modal-cl4-promo');
  if (promoInput) promoInput.value = '';
  const promoBadge = document.getElementById('modal-cl4-promo-badge');
  if (promoBadge) promoBadge.classList.add('hidden');
  const basePriceVal = (gc.price != null && !isNaN(parseFloat(gc.price))) ? parseFloat(gc.price).toFixed(2) : '200.00';
  const priceDisplay = document.getElementById('modal-cl4-price-display');
  if (priceDisplay) priceDisplay.textContent = `${basePriceVal} грн`;
  updateCl4Price();

  // Ensure subscriptions are loaded
  if (!cachedClientSubscriptions || !cachedClientSubscriptions.length) {
    try {
      const subs = await clientApi.getSubscriptions();
      if (subs) cachedClientSubscriptions = subs;
    } catch (err) {
      console.warn('Could not fetch subscriptions for modal:', err);
    }
  }

  const latestSub = getLatestClientSubscription(cachedClientSubscriptions);
  const hasActiveSub = latestSub && latestSub.currentStatus === 'Active';
  const isFrozen = latestSub && latestSub.currentStatus === 'Frozen';
  const saleIdInput = document.getElementById('modal-cl4-sale-id');
  if (saleIdInput) {
    saleIdInput.value = hasActiveSub ? latestSub.saleId : '';
  }

  const confirmBtn = document.getElementById('modal-cl4-confirm-btn');
  const warningEl = document.getElementById('modal-cl4-no-sub-warning');

  if (hasActiveSub) {
    if (confirmBtn) {
      confirmBtn.disabled = false;
      confirmBtn.title = '';
    }
    if (warningEl) warningEl.classList.add('hidden');
  } else if (isFrozen) {
    if (confirmBtn) {
      confirmBtn.disabled = true;
      confirmBtn.title = 'Запис неможливий: абонемент заморожено';
    }
    if (warningEl) {
      warningEl.innerHTML = '<i class="fa-solid fa-snowflake text-cyan-400"></i> Запис неможливий: ваш абонемент заморожено. Достроково скасувати заморозку можна у вкладці «Абонемент».';
      warningEl.className = 'p-3 rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-300 text-xs font-medium flex items-center gap-2';
      warningEl.classList.remove('hidden');
    }
  } else {
    if (confirmBtn) {
      confirmBtn.disabled = true;
      confirmBtn.title = 'Потрібен діючий абонемент';
    }
    if (warningEl) {
      warningEl.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-rose-400"></i> Для запису та купівлі групових занять необхідно мати діючий абонемент клубу.';
      warningEl.className = 'p-3 rounded-lg bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs font-medium flex items-center gap-2';
      warningEl.classList.remove('hidden');
    }
  }

  const modal = document.getElementById('modal-group-booking');
  if (modal) {
    modal.classList.remove('hidden');
    modal.classList.add('active');
  }
}

export function closeGroupBookingModal() {
  const modal = document.getElementById('modal-group-booking');
  if (modal) {
    modal.classList.remove('active');
    modal.classList.add('hidden');
  }
}

export async function confirmGroupBooking() {
  const instanceId = parseInt(document.getElementById('modal-cl4-instance-id')?.value || '0', 10);
  const promoCode = document.getElementById('modal-cl4-promo')?.value.trim().toUpperCase() || null;

  if (!instanceId) {
    showToast('Будь ласка, оберіть доступне заняття.', 'warning');
    return;
  }

  const latestSub = getLatestClientSubscription(cachedClientSubscriptions);
  if (!latestSub || latestSub.currentStatus !== 'Active') {
    if (latestSub && latestSub.currentStatus === 'Frozen') {
      showToast('Запис неможливий: ваш абонемент заморожено. Достроково скасувати заморозку можна у вкладці «Абонемент».', 'warning');
    } else {
      showToast('Запис неможливий: відсутній активний абонемент.', 'warning');
    }
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
    closeGroupBookingModal();
    return;
  }

  const confirmBtn = document.getElementById('modal-cl4-confirm-btn');
  if (confirmBtn) confirmBtn.disabled = true;

  try {
    const payload = { instanceId };
    if (promoCode) payload.promoCode = promoCode;
    await clientApi.bookGroupClass(payload);
    showToast('Успішно оплачено та записано на групове заняття! (Cl4)', 'success');
    closeGroupBookingModal();
    await populateCl45Options();
    await renderClientDashboard();
  } catch (err) {
    if (err.message && (err.message.includes('вже') || err.message.includes('дубл') || err.message.includes('duplicate'))) {
      showToast('Ви вже записані на це тренування!', 'warning');
    } else {
      showToast(`Помилка запису: ${err.message}`, 'danger');
    }
  } finally {
    if (confirmBtn && latestSub && latestSub.currentStatus === 'Active') confirmBtn.disabled = false;
  }
}

export async function handleCl4Booking(e) {
  if (e && e.preventDefault) e.preventDefault();
  await confirmGroupBooking();
}

export async function handleCl5Booking(e) {
  e.preventDefault();
  const coachId = parseInt(document.getElementById('cl5-coach').value);
  const hallId = parseInt(document.getElementById('cl5-hall').value);
  const dt = document.getElementById('cl5-datetime').value;
  const promoCode = document.getElementById('cl5-promo')?.value.trim().toUpperCase() || null;
  const itemVal = document.getElementById('cl5-item')?.value;
  const itemId = itemVal ? parseInt(itemVal, 10) : null;

  const latestSub = getLatestClientSubscription(cachedClientSubscriptions);
  if (!latestSub || latestSub.currentStatus !== 'Active') {
    if (latestSub && latestSub.currentStatus === 'Frozen') {
      showToast('Запис неможливий: ваш абонемент заморожено. Достроково скасувати заморозку можна у вкладці «Абонемент».', 'warning');
    } else {
      showToast('Запис неможливий: відсутній активний абонемент.', 'warning');
    }
    return;
  }

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

  const cl5SubmitBtn = document.getElementById('cl5-submit-btn');
  if (cl5SubmitBtn) cl5SubmitBtn.disabled = true;

  try {
    const payload = {
      coachId,
      hallId,
      trainingDateTime: dt
    };
    if (promoCode) payload.promoCode = promoCode;
    if (itemId) payload.itemId = itemId;
    await clientApi.bookPersonalTraining(payload);
    bookedCoachSlots.add(slotKey);
    showToast('Успішно оплачено та записано на персональне тренування! (Cl5)', 'success');
    await renderClientDashboard();
    switchClientTab('cl_dash');
  } catch (err) {
    if (err.message && (err.message.includes('зайнятий') || err.message.includes('конфлікт') || err.message.includes('conflict'))) {
      showToast(err.message, 'warning');
    } else {
      showToast(`Помилка запису: ${err.message}`, 'danger');
    }
  } finally {
    if (cl5SubmitBtn && latestSub && latestSub.currentStatus === 'Active') cl5SubmitBtn.disabled = false;
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
    const formattedTime = formatTrainingDateTime(b.trainingDateTime);
    opt.textContent = `[${isPersonal ? 'Персональне' : 'Групове'}] ${b.title} (${formattedTime})`;
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
    if (bookingType === 'Personal') {
      await clientApi.cancelPersonalBooking({
        bookingId,
        reason
      });
    } else {
      await clientApi.cancelGroupBooking({
        bookingId
      });
    }
    bookedCoachSlots.clear();
    showToast('Бронювання успішно скасовано! (Cl6)', 'success');
    await renderClientDashboard();
    switchClientTab('cl_dash');
  } catch (err) {
    showToast(`Помилка скасування: ${err.message}`, 'danger');
  }
}
