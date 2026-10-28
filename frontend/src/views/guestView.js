/**
 * FitnessClub IS - Guest View (G1 - G4)
 * Pure REST API Implementation
 * Module: views/guestView.js
 */

import { AppState, setCurrentUser, setActiveRole, setAuthToken, setRefreshToken, findPromo } from '../state/state.js';
import { guestApi } from '../api/guestApi.js';
import { authApi } from '../api/authApi.js';
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

  if (tabId === 'g3') {
    renderGuestPriceList();
  } else if (tabId === 'g4') {
    renderGuestHalls();
  } else if (tabId === 'g2') {
    renderGuestCoaches();
  } else if (tabId === 'g1') {
    await populateG1SubscriptionSelect();
    if (selectedItemId) {
      const select = document.getElementById('g1-subscription') || document.getElementById('g1-item');
      if (select) {
        select.value = String(selectedItemId);
        updateG1PriceCalculation();
      }
    }
  }
}

export async function renderGuestPriceList() {
  const container = document.getElementById('guest-pricelist-cards');

  try {
    const data = await guestApi.getPriceList();
    cachedPriceList = (data || []).map(item => ({
      id: item.itemId,
      name: item.itemName,
      category: item.category,
      price: item.price,
      desc: item.description,
      durationDays: item.durationDays,
      maxFreezingDays: item.maxFreezingDays
    }));

    // Dynamically bind Hero Featured Pass strictly from API
    const annualSub = cachedPriceList.find(i => (i.durationDays && i.durationDays >= 360) || (i.name && i.name.toLowerCase().includes('річн'))) 
      || cachedPriceList.find(i => i.category === 'Membership') 
      || cachedPriceList[0];

    if (annualSub) {
      const heroName = document.getElementById('hero-pass-name');
      const heroPrice = document.getElementById('hero-pass-price');
      const heroFreezing = document.getElementById('hero-pass-freezing');
      const heroDuration = document.getElementById('hero-pass-duration');
      const heroBtn = document.getElementById('hero-pass-cta-btn');

      if (heroName) heroName.textContent = annualSub.name;
      if (heroPrice) heroPrice.textContent = parseFloat(annualSub.price).toFixed(2);
      if (heroFreezing) heroFreezing.textContent = `${annualSub.maxFreezingDays || 0} днів гарантованої заморозки`;
      if (heroDuration) heroDuration.textContent = `${annualSub.durationDays || 365} днів повного доступу до всіх зон`;
      if (heroBtn) {
        heroBtn.setAttribute('onclick', `switchGuestTab('g1', ${annualSub.id})`);
      }
    }

    if (!container) return;

    container.innerHTML = '';
    if (!cachedPriceList.length) {
      container.innerHTML = '<div class="col-span-3 text-center text-slate-500 py-8 font-mono text-xs">Прайс-лист порожній у базі даних</div>';
      return;
    }

    cachedPriceList.forEach(item => {
      const card = document.createElement('div');
      card.className = 'card card-interactive p-5 flex flex-col justify-between';
      card.innerHTML = `
        <div>
          <div class="flex justify-between items-start mb-2">
            <span class="badge ${item.category === 'Membership' ? 'badge-cyan' : 'badge-scheduled'}">${item.category}</span>
            <span class="text-xs text-slate-500 font-mono">#${item.id}</span>
          </div>
          <h4 class="font-bold text-white text-base font-heading mb-1">${item.name}</h4>
          <p class="text-xs text-slate-400 mb-3 leading-relaxed">${item.desc || '—'}</p>
          ${item.durationDays ? `
            <div class="text-[11px] text-slate-300 space-y-1 mb-4 bg-void p-2.5 rounded-lg border border-subtle font-mono" style="background-color: #060913 !important; border: 1px solid #1a2236 !important;">
              <div><i class="fa-regular fa-clock text-cyan-400 mr-1.5"></i> Тривалість: <b class="text-white">${item.durationDays} днів</b></div>
              <div><i class="fa-regular fa-snowflake text-blue-400 mr-1.5"></i> Заморозка: <b class="text-white">до ${item.maxFreezingDays || 0} днів</b></div>
            </div>
          ` : ''}
        </div>
        <div class="pt-3 border-t border-subtle flex items-center justify-between mt-2">
          <div>
            <span class="text-xl font-bold font-mono text-cyan-400">${parseFloat(item.price).toFixed(2)}</span>
            <span class="text-xs text-slate-500 font-mono ml-1">грн</span>
          </div>
          <button onclick="switchGuestTab('g1', ${item.id})" class="btn btn-primary btn-sm">
            <span>Купити</span> <i class="fa-solid fa-arrow-right text-[10px]"></i>
          </button>
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
      maxCapacity: h.maxCapacity
    }));

    container.innerHTML = '';
    if (!halls.length) {
      container.innerHTML = '<div class="col-span-3 text-center text-slate-500 py-8 font-mono text-xs">Немає зареєстрованих залів</div>';
      return;
    }

    halls.forEach(hall => {
      const icon = hallIcons[hall.name] || 'fa-building';
      const card = document.createElement('div');
      card.className = 'card card-interactive p-5';
      card.innerHTML = `
        <div class="flex items-center space-x-3">
          <div class="w-11 h-11 rounded-xl bg-cyan-500/10 text-cyan-400 border border-cyan-500/25 flex items-center justify-center text-lg shadow-[0_0_15px_rgba(6,182,212,0.15)]">
            <i class="fa-solid ${icon}"></i>
          </div>
          <div>
            <h4 class="font-bold text-white text-base font-heading">${hall.name}</h4>
            <span class="text-xs text-slate-400 font-mono">Місткість: <b class="text-cyan-400">${hall.maxCapacity}</b> осіб</span>
          </div>
        </div>
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
      specializationId: c.specializationId || c.specId,
      specializationName: c.specializationName || c.specName || 'Тренер',
      bio: c.biography,
      ptCount: c.individualClientsCount || 0,
      groupCount: c.groupClassesCount || 0
    }));

    container.innerHTML = '';
    if (!coaches.length) {
      container.innerHTML = '<div class="col-span-3 text-center text-slate-500 py-8 font-mono text-xs">Немає зареєстрованих тренерів</div>';
      return;
    }

    coaches.forEach(coach => {
      const card = document.createElement('div');
      card.className = 'card card-interactive p-5';
      card.innerHTML = `
        <div class="flex items-start justify-between mb-3">
          <div class="flex items-center space-x-3">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-cyan-500/20 to-blue-600/20 text-cyan-300 border border-cyan-500/30 flex items-center justify-center font-bold text-lg font-mono shadow-[0_0_15px_rgba(6,182,212,0.15)]">
              ${coach.fullName.charAt(0)}
            </div>
            <div>
              <h4 class="font-bold text-white text-base leading-tight font-heading">${coach.fullName}</h4>
              <span class="badge badge-cyan text-[10px] mt-1">${coach.specializationName}</span>
            </div>
          </div>
        </div>
        <p class="text-xs text-slate-400 mb-4 line-clamp-3 leading-relaxed">${coach.bio || 'Професійний інструктор з багаторічним досвідом.'}</p>
        <div class="pt-3 border-t border-subtle grid grid-cols-2 text-center text-xs text-slate-400 font-mono">
          <div>Індивідуальних: <b class="text-cyan-400">${coach.ptCount}</b></div>
          <div>Групових: <b class="text-blue-400">${coach.groupCount}</b></div>
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
  const dbUser = document.getElementById('g1-dbuser')?.value.trim() || '';
  const password = document.getElementById('g1-password')?.value || '';
  const medNotes = document.getElementById('g1-mednotes').value.trim();
  const select = document.getElementById('g1-subscription') || document.getElementById('g1-item');
  const itemId = parseInt(select?.value);
  const promoCode = document.getElementById('g1-promo')?.value.trim().toUpperCase() || null;

  const loginRegex = /^[a-zA-Z0-9_]{3,30}$/;
  if (!loginRegex.test(dbUser)) {
    showToast("Логін має містити від 3 до 30 символів (лише латинські літери, цифри та '_')", 'warning');
    return;
  }

  if (!password || password.length < 4) {
    showToast("Пароль повинен містити не менше 4 символів", 'warning');
    return;
  }

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
    const res = await guestApi.register({
      fullName,
      birthDate,
      phone,
      gender,
      dbUser,
      password,
      itemId,
      promoCode,
      medicalNotes: medNotes || null
    });

    const finalDbUser = res.dbUsername || dbUser;
    
    // Automatically login newly created client to get tokens
    try {
      const loginRes = await authApi.login(finalDbUser, password);
      if (loginRes.token) {
        setAuthToken(loginRes.token);
      }
      if (loginRes.refreshToken) {
        setRefreshToken(loginRes.refreshToken);
      }
    } catch (loginErr) {
      console.warn('Auto-login after registration failed:', loginErr);
    }

    const userObj = {
      dbUser: finalDbUser,
      name: fullName,
      role: 'client',
      clientId: res.clientId,
      pos: 'Клієнт'
    };
    setCurrentUser(userObj);
    setActiveRole('client');

    updateHeaderUI();
    renderRoleNav();
    switchRoleView('client');

    showToast(`Реєстрація успішна! Ласкаво просимо, ${fullName}. Ви увійшли під логіном ${finalDbUser}`, 'success');
  } catch (err) {
    showToast(`Помилка реєстрації через API: ${err.message}`, 'danger');
  }
}

export const handleG1Register = handleG1Registration;
