/**
 * FitnessClub IS - Guest View (G1 - G4)
 * Pure REST API Implementation
 * Module: views/guestView.js
 */

import { AppState, setCurrentUser, setActiveRole, findPromo } from '../state/state.js';
import { guestApi } from '../api/guestApi.js';
import { showToast } from '../components/toast.js';
import { updateHeaderUI, renderRoleNav, switchRoleView } from '../components/navigation.js';

let cachedPriceList = [];

export async function switchGuestTab(tabId, selectedItemId = null) {
  document.querySelectorAll('.guest-pane').forEach(el => el.classList.add('hidden'));
  document.querySelectorAll('#view-guest .nav-tab-btn').forEach(b => b.classList.remove('active'));

  const pane = document.getElementById(`subtab-${tabId}`);
  const btn = document.getElementById(`tab-btn-${tabId}`);
  if (pane) pane.classList.remove('hidden');
  if (btn) btn.classList.add('active');

  if (tabId === 'g1' && selectedItemId) {
    await populateG1SubscriptionSelect();
    const select = document.getElementById('g1-subscription') || document.getElementById('g1-item');
    if (select) {
      select.value = String(selectedItemId);
      updateG1PriceCalculation();
    }
  }
}

export async function renderGuestPriceList() {
  const container = document.getElementById('guest-pricelist-cards');
  if (!container) return;

  try {
    const data = await guestApi.getPriceList();
    cachedPriceList = data.map(item => ({
      id: item.itemId,
      name: item.itemName,
      category: item.category,
      price: item.price,
      desc: item.description,
      durationDays: item.durationDays,
      maxFreezingDays: item.maxFreezingDays
    }));

    container.innerHTML = '';
    if (!cachedPriceList.length) {
      container.innerHTML = '<div class="col-span-3 text-center text-slate-400 py-8">Прайс-лист порожній у базі даних</div>';
      return;
    }

    cachedPriceList.forEach(item => {
      const card = document.createElement('div');
      card.className = 'card p-5 flex flex-col justify-between border-slate-200 hover:border-blue-300';
      card.innerHTML = `
        <div>
          <div class="flex justify-between items-start mb-2">
            <span class="badge ${item.category === 'Membership' ? 'badge-active' : 'badge-scheduled'}">${item.category}</span>
            <span class="text-xs text-slate-400 font-mono">#${item.id}</span>
          </div>
          <h4 class="font-bold text-slate-800 text-sm mb-1">${item.name}</h4>
          <p class="text-xs text-slate-500 mb-3">${item.desc || '—'}</p>
          ${item.durationDays ? `
            <div class="text-[11px] text-slate-600 space-y-1 mb-3 bg-slate-50 p-2 rounded">
              <div><i class="fa-regular fa-clock text-blue-500 mr-1"></i> Тривалість: <b>${item.durationDays} днів</b></div>
              <div><i class="fa-regular fa-snowflake text-cyan-500 mr-1"></i> Заморозка: <b>до ${item.maxFreezingDays || 0} днів</b></div>
            </div>
          ` : ''}
        </div>
        <div class="pt-3 border-t border-slate-100 flex items-center justify-between mt-2">
          <div>
            <span class="text-lg font-bold text-blue-600">${parseFloat(item.price).toFixed(2)}</span>
            <span class="text-xs text-slate-500">грн</span>
          </div>
          <button onclick="switchGuestTab('g1', ${item.id})" class="btn btn-primary btn-sm">Купити (G1)</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (err) {
    console.warn('Failed to load guest price list:', err);
  }
}

export async function renderGuestHalls() {
  const container = document.getElementById('guest-halls-cards');
  if (!container) return;

  const hallIcons = {
    'Main Gym': 'fa-dumbbell',
    'Yoga Studio': 'fa-spa',
    'Fight Zone': 'fa-hand-fist',
    'Crossfit Box': 'fa-stopwatch',
    'Pool': 'fa-person-swimming',
    'Pilates Room': 'fa-heart-pulse',
    'Kids Zone': 'fa-child'
  };

  try {
    const data = await guestApi.getHalls();
    const halls = data.map(h => ({
      id: h.hallId,
      name: h.hallName,
      maxCapacity: h.maxCapacity,
      desc: 'Сучасне обладнання світових виробників.'
    }));

    container.innerHTML = '';
    if (!halls.length) {
      container.innerHTML = '<div class="col-span-3 text-center text-slate-400 py-8">Немає зареєстрованих залів</div>';
      return;
    }

    halls.forEach(hall => {
      const icon = hallIcons[hall.name] || 'fa-building';
      const card = document.createElement('div');
      card.className = 'card p-5 border-slate-200 hover:border-indigo-300';
      card.innerHTML = `
        <div class="flex items-center space-x-3 mb-3">
          <div class="w-10 h-10 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center text-lg">
            <i class="fa-solid ${icon}"></i>
          </div>
          <div>
            <h4 class="font-bold text-slate-800 text-sm">${hall.name}</h4>
            <span class="text-xs text-slate-500">Місткість: <b>${hall.maxCapacity}</b> осіб</span>
          </div>
        </div>
        <p class="text-xs text-slate-600 leading-relaxed">${hall.desc || 'Сучасне обладнання світових виробників.'}</p>
      `;
      container.appendChild(card);
    });
  } catch (err) {
    console.warn('Failed to load guest halls:', err);
  }
}

export async function renderGuestCoaches() {
  const container = document.getElementById('guest-coaches-cards');
  if (!container) return;

  try {
    const data = await guestApi.getCoaches();
    const coaches = data.map(c => ({
      id: c.coachId,
      fullName: c.fullName,
      specName: c.specName || 'Тренер',
      bio: c.biography,
      ptCount: c.individualClientsCount || 0,
      groupCount: c.groupClassesCount || 0
    }));

    container.innerHTML = '';
    if (!coaches.length) {
      container.innerHTML = '<div class="col-span-3 text-center text-slate-400 py-8">Немає зареєстрованих тренерів</div>';
      return;
    }

    coaches.forEach(coach => {
      const card = document.createElement('div');
      card.className = 'card p-5 border-slate-200 hover:border-blue-300';
      card.innerHTML = `
        <div class="flex items-start justify-between mb-3">
          <div class="flex items-center space-x-3">
            <div class="w-12 h-12 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-lg">
              ${coach.fullName.charAt(0)}
            </div>
            <div>
              <h4 class="font-bold text-slate-800 text-sm leading-tight">${coach.fullName}</h4>
              <span class="badge badge-active text-[10px] mt-1">${coach.specName}</span>
            </div>
          </div>
        </div>
        <p class="text-xs text-slate-600 mb-4 line-clamp-3">${coach.bio || 'Професійний інструктор з багаторічним досвідом.'}</p>
        <div class="pt-3 border-t border-slate-100 grid grid-cols-2 text-center text-xs text-slate-500">
          <div>Індивідуальних: <b class="text-slate-700">${coach.ptCount}</b></div>
          <div>Групових: <b class="text-slate-700">${coach.groupCount}</b></div>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (err) {
    console.warn('Failed to load guest coaches:', err);
  }
}

export async function populateG1SubscriptionSelect() {
  const select = document.getElementById('g1-subscription') || document.getElementById('g1-item');
  if (!select) return;

  try {
    if (!cachedPriceList.length) {
      const data = await guestApi.getPriceList();
      cachedPriceList = data.map(item => ({
        id: item.itemId,
        name: item.itemName,
        category: item.category,
        price: item.price,
        desc: item.description,
        durationDays: item.durationDays,
        maxFreezingDays: item.maxFreezingDays
      }));
    }

    const currentVal = select.value;
    select.innerHTML = '<option value="" disabled selected>-- Оберіть стартовий абонемент --</option>';
    cachedPriceList.filter(item => item.category === 'Membership').forEach(item => {
      const opt = document.createElement('option');
      opt.value = item.id;
      opt.textContent = `${item.name} — ${parseFloat(item.price).toFixed(2)} грн`;
      select.appendChild(opt);
    });
    if (currentVal) {
      select.value = currentVal;
    }
  } catch (err) {
    console.warn('Failed to populate G1 subscriptions:', err);
  }
}

export function updateG1PriceCalculation() {
  const select = document.getElementById('g1-subscription') || document.getElementById('g1-item');
  const itemId = parseInt(select?.value);
  const promoInput = document.getElementById('g1-promo')?.value.trim().toUpperCase() || '';
  const display = document.getElementById('g1-price-display');
  const promoBadge = document.getElementById('g1-promo-applied-badge');

  const item = cachedPriceList.find(p => p.id === itemId);
  if (!item) {
    if (display) display.textContent = '0.00 грн';
    if (promoBadge) promoBadge.classList.add('hidden');
    return;
  }

  let finalPrice = parseFloat(item.price);
  const now = new Date().toISOString().split('T')[0];
  const promo = findPromo(promoInput);

  if (promo) {
    if (promo.expiryDate && promo.expiryDate < now) {
      if (promoBadge) promoBadge.classList.add('hidden');
    } else {
      const discount = (finalPrice * promo.discountPercent) / 100;
      finalPrice -= discount;
      if (promoBadge) {
        promoBadge.textContent = `Знижка ${promo.discountPercent}% застосована!`;
        promoBadge.classList.remove('hidden');
      }
    }
  } else {
    if (promoBadge) promoBadge.classList.add('hidden');
  }

  if (display) display.textContent = `${finalPrice.toFixed(2)} грн`;
}

export function checkG1Promo() {
  const code = document.getElementById('g1-promo')?.value.trim().toUpperCase();
  if (!code) {
    showToast('Введіть промокод', 'warning');
    updateG1PriceCalculation();
    return;
  }

  const promo = findPromo(code);
  const now = new Date().toISOString().split('T')[0];

  if (!promo) {
    showToast('Промокод не знайдено або термін його дії вичерпано', 'warning');
    updateG1PriceCalculation();
    return;
  }

  if (promo.expiryDate && promo.expiryDate < now) {
    showToast('Термін дії промокоду вичерпано!', 'warning');
    updateG1PriceCalculation();
    return;
  }

  showToast(`Промокод ${code} на ${promo.discountPercent}% успішно застосовано!`, 'success');
  updateG1PriceCalculation();
}

export async function handleG1Registration(e) {
  e.preventDefault();

  const fullName = document.getElementById('g1-fullname').value.trim();
  const phone = document.getElementById('g1-phone').value.trim();
  const birthDate = document.getElementById('g1-birthdate').value;
  const gender = document.getElementById('g1-gender').value;
  const medNotes = document.getElementById('g1-mednotes').value.trim();
  const select = document.getElementById('g1-subscription') || document.getElementById('g1-item');
  const itemId = parseInt(select?.value);
  const promoCode = document.getElementById('g1-promo')?.value.trim().toUpperCase() || null;

  if (!itemId) {
    showToast('Будь ласка, оберіть стартовий абонемент.', 'warning');
    return;
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
    const generatedUser = 'client_' + Math.random().toString(36).substring(2, 8);
    const res = await guestApi.register({
      fullName,
      birthDate,
      phone,
      gender,
      dbUser: generatedUser,
      password: 'client_password_123',
      itemId,
      promoCode,
      medicalNotes: medNotes || null
    });

    showToast(`Реєстрація успішна! Клієнт #${res.clientId}, абонемент діє до ${res.endDate}`, 'success');
    const userObj = {
      dbUser: res.dbUsername || generatedUser,
      name: fullName,
      role: 'client',
      clientId: res.clientId,
      pos: 'Клієнт',
      pass: 'client_password_123'
    };
    setCurrentUser(userObj);
    setActiveRole('client');

    updateHeaderUI();
    renderRoleNav();
    switchRoleView('client');
  } catch (err) {
    showToast(`Помилка реєстрації через API: ${err.message}`, 'danger');
  }
}
