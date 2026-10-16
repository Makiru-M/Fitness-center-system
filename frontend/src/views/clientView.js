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
const registeredGroupInstances = new Set();
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
}

export function getActiveClient() {
  return AppState.currentUser;
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

    const medAlertEl = document.getElementById('client-medical-alert');
    if (medAlertEl) {
      if (profile.medicalNotes) {
        medAlertEl.innerHTML = `<i class="fa-solid fa-notes-medical text-rose-500"></i> <span class="font-medium">Медичні застереження: ${profile.medicalNotes}</span>`;
        medAlertEl.className = 'mt-2 text-xs text-rose-700 bg-rose-50 px-2.5 py-1 rounded inline-flex items-center gap-1.5 border border-rose-200';
      } else {
        medAlertEl.innerHTML = `<i class="fa-solid fa-notes-medical text-emerald-500"></i> <span>Медичні обмеження: Відсутні</span>`;
        medAlertEl.className = 'mt-2 text-xs text-slate-600 bg-slate-50 px-2.5 py-1 rounded inline-flex items-center gap-1.5 border border-slate-200';
      }
    }

    const activeSub = (subs && subs.length) ? subs[0] : null;
    const subBadge = document.getElementById('client-sub-badge');
    const metricExpiry = document.getElementById('client-metric-expiry');
    const metricFreezing = document.getElementById('client-metric-freezing');
    const freezingLeft = document.getElementById('cl3-freezing-days-left');

    if (activeSub) {
      if (subBadge) {
        subBadge.className = `badge badge-${(activeSub.currentStatus || 'active').toLowerCase()}`;
        subBadge.textContent = activeSub.currentStatus === 'Active' ? `Активний (${activeSub.itemName})` : activeSub.currentStatus;
      }
      if (metricExpiry) metricExpiry.textContent = activeSub.endDate;
      if (metricFreezing) metricFreezing.textContent = `${activeSub.remainingFreezingDays || 0} дн.`;
      if (freezingLeft) freezingLeft.textContent = activeSub.remainingFreezingDays || 0;
    } else {
      if (subBadge) {
        subBadge.className = 'badge badge-expired';
        subBadge.textContent = 'Немає активного абонемента';
      }
      if (metricExpiry) metricExpiry.textContent = '—';
      if (metricFreezing) metricFreezing.textContent = '0';
      if (freezingLeft) freezingLeft.textContent = '0';
    }

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
        listEl.innerHTML = '<p class="text-xs text-slate-400 p-2 italic">Немає запланованих занять. Запишіться у розділі Cl4/Cl5!</p>';
      } else {
        bookings.forEach(b => {
          const item = document.createElement('div');
          item.className = 'p-3 rounded-lg border border-slate-100 bg-slate-50 flex justify-between items-center text-xs';
          item.innerHTML = `
            <div>
              <span class="font-bold text-slate-800">[${b.activityType}] ${b.title}</span>
              <div class="text-slate-500 mt-0.5">Тренер: <b>${b.coachName || '—'}</b> | Зал: <b>${b.hallName || '—'}</b></div>
              <div class="text-[11px] text-blue-600 font-semibold mt-1"><i class="fa-regular fa-clock mr-1"></i> ${b.trainingDateTime || '—'}</div>
            </div>
            <span class="badge badge-${(b.status || 'Active').toLowerCase()}">${b.status}</span>
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
      medicalNotes: medNotes || null
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

    const startDateInput = document.getElementById('cl2-startdate');
    if (startDateInput) startDateInput.value = new Date().toISOString().split('T')[0];
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
    switchClientTab('cl_dash');
  } catch (err) {
    showToast(`Помилка оформлення абонемента: ${err.message}`, 'danger');
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

export async function populateCl45Options() {
  try {
    const [halls, coaches] = await Promise.all([
      guestApi.getHalls(),
      guestApi.getCoaches()
    ]);

    const cl4Instance = document.getElementById('cl4-instance');
    if (cl4Instance && (!cl4Instance.children || cl4Instance.children.length === 0)) {
      cl4Instance.innerHTML = `
        <option value="1">Hatha Yoga — Пн 09:00 (Yoga Studio)</option>
        <option value="2">Power Crossfit — Вт 18:00 (Crossfit Box)</option>
        <option value="3">Morning Stretch — Ср 08:00 (Yoga Studio)</option>
        <option value="4">Zumba — Чт 19:00 (Fight Zone)</option>
        <option value="5">Box Training — Пт 17:00 (Main Gym)</option>
        <option value="6">Pilates Basics — Сб 11:00 (Pilates Room)</option>
      `;
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
  const instanceId = parseInt(select?.value || '1');
  const selectedText = select?.options[select.selectedIndex]?.text || '';

  // Cl4: Duplicate booking check
  const alreadyBooked = (cachedClientBookings || []).some(b => 
    (b.activityType || '').toLowerCase() === 'group' &&
    (b.status || '').toLowerCase() === 'scheduled' &&
    (b.bookingId === instanceId || (selectedText && b.title && selectedText.includes(b.title)))
  ) || registeredGroupInstances.has(instanceId);

  if (alreadyBooked) {
    showToast('Ви вже записані на це тренування!', 'warning');
    return;
  }

  try {
    await clientApi.bookGroupClass({ instanceId, saleId: null });
    registeredGroupInstances.add(instanceId);
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
    await clientApi.bookPersonalTraining({
      coachId,
      hallId,
      trainingDateTime: dt,
      saleId: null
    });
    bookedCoachSlots.add(slotKey);
    showToast('Персональне тренування успішно заброньовано! (Cl5)', 'success');
    await renderClientDashboard();
    switchClientTab('cl_dash');
  } catch (err) {
    if (err.message && (err.message.includes('зайнятий') || err.message.includes('конфлікт') || err.message.includes('conflict'))) {
      showToast('Обраний тренер уже має призначене тренування на цей час. Будь ласка, оберіть інший слот', 'warning');
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
    showToast('Бронювання успішно скасовано! (Cl6)', 'success');
    await renderClientDashboard();
    switchClientTab('cl_dash');
  } catch (err) {
    showToast(`Помилка скасування: ${err.message}`, 'danger');
  }
}
