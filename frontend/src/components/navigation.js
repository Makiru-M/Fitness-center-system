/**
 * FitnessClub IS - Navigation, Authentication & Server Availability Component
 * Pure REST API Implementation (Mock mode removed)
 * Module: components/navigation.js
 */

import { AppState, TEST_ACCOUNTS, STORAGE_KEYS, setCurrentUser, setActiveRole, setAuthToken, setRefreshToken, getRefreshToken, clearRefreshToken } from '../state/state.js';
import { checkHealth } from '../api/apiClient.js';
import { authApi } from '../api/authApi.js';
import { showToast } from './toast.js';
import { initAllComboboxes } from './combobox.js';

// Imports of view functions
import {
  switchGuestTab,
  renderGuestPriceList,
  renderGuestHalls,
  renderGuestCoaches,
  populateG1SubscriptionSelect
} from '../views/guestView.js';

import {
  switchClientTab,
  renderClientDashboard
} from '../views/clientView.js';

import {
  switchManagerTab,
  populateManagerDropdowns,
  renderM4VisitsTable,
  renderM2ClientsTable,
  renderM8Requests
} from '../views/managerView.js';

import {
  switchHrTab,
  renderHrCoachesTable,
  renderHrStaffTable,
  populateHrDropdowns
} from '../views/hrView.js';

import {
  switchCoachTab,
  renderCoachSchedule,
  populateCoachDropdowns
} from '../views/coachView.js';

import {
  switchDirectorTab,
  renderD1Revenue,
  renderD2Attendance,
  renderD3Coaches,
  renderD5Problems,
  renderD6Audit,
  populateDirectorDropdowns
} from '../views/directorView.js';

export async function initApp() {
  console.log(`%c[FitnessClub IS] Ініціалізація клієнта REST API (Base URL: ${AppState.apiBaseUrl})`, 'color: #2563eb; font-weight: bold; font-size: 13px;');

  // Load saved session
  const savedUser = sessionStorage.getItem(STORAGE_KEYS.CURRENT_USER);
  if (savedUser) {
    try {
      AppState.currentUser = JSON.parse(savedUser);
      AppState.activeRole = AppState.currentUser.role || 'guest';
    } catch (e) {
      AppState.currentUser = null;
      AppState.activeRole = 'guest';
    }
  } else {
    AppState.activeRole = 'guest';
    AppState.currentUser = null;
  }

  updateHeaderUI();
  initAllComboboxes();

  // Initial connection health check
  try {
    await checkHealth();
    setServerOnline(true);

    // Validate session with backend or refresh if token expired
    if (AppState.currentUser) {
      try {
        const session = await authApi.getSession();
        if (session && session.role) {
          const role = session.role.replace(/_role$/, '').toLowerCase();
          setActiveRole(role);
        }
      } catch (sessionErr) {
        console.warn('Initial session check failed, attempting token refresh...', sessionErr);
        const rf = getRefreshToken();
        if (rf) {
          try {
            const refreshRes = await authApi.refresh(rf);
            if (refreshRes && refreshRes.accessToken && refreshRes.refreshToken) {
              setAuthToken(refreshRes.accessToken);
              setRefreshToken(refreshRes.refreshToken);
              const sessionAfterRefresh = await authApi.getSession();
              if (sessionAfterRefresh && sessionAfterRefresh.role) {
                const role = sessionAfterRefresh.role.replace(/_role$/, '').toLowerCase();
                setActiveRole(role);
              }
            } else {
              throw new Error('Refresh response invalid');
            }
          } catch (rfErr) {
            console.warn('Token refresh on startup failed, resetting to guest:', rfErr);
            setCurrentUser(null);
            setAuthToken(null);
            clearRefreshToken();
            setActiveRole('guest');
          }
        } else {
          setCurrentUser(null);
          setAuthToken(null);
          setActiveRole('guest');
        }
      }
    }

    // Guarantee hero pass price is fetched strictly from API immediately
    renderGuestPriceList().catch(e => console.warn('Hero price load error:', e));
    updateHeaderUI();
    renderRoleNav();
    switchRoleView(AppState.activeRole);
  } catch (err) {
    console.warn('Initial server check failed: backend is offline', err);
    setServerOnline(false);
  }
}

export function setServerOnline(isOnline) {
  AppState.isServerOnline = isOnline;

  const badge = document.getElementById('mode-badge');
  const label = document.getElementById('mode-label');
  const dot = document.getElementById('mode-status-dot');
  const unavailableView = document.getElementById('view-server-unavailable');

  if (isOnline) {
    if (badge) {
      badge.className = 'hidden sm:inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 cursor-pointer shadow-sm hover:border-emerald-400 transition font-mono';
    }
    if (label) label.textContent = 'API: Онлайн';
    if (dot) dot.className = 'w-2 h-2 rounded-full bg-emerald-400 mr-2 animate-pulse';

    if (unavailableView) {
      unavailableView.classList.add('hidden');
    }
  } else {
    if (badge) {
      badge.className = 'hidden sm:inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-rose-500/10 text-rose-400 border border-rose-500/30 cursor-pointer shadow-sm hover:border-rose-400 transition font-mono';
    }
    if (label) label.textContent = 'API: Офлайн';
    if (dot) dot.className = 'w-2 h-2 rounded-full bg-rose-500 mr-2 animate-ping';

    // Hide all working role views and login form
    document.querySelectorAll('.role-view').forEach(view => view.classList.add('hidden'));
    const loginView = document.getElementById('view-login');
    if (loginView) loginView.classList.add('hidden');

    // Show fallback screen
    if (unavailableView) {
      unavailableView.classList.remove('hidden');
      const apiEp = document.getElementById('unavailable-api-endpoint');
      if (apiEp) apiEp.textContent = AppState.apiBaseUrl;
      const hlEp = document.getElementById('unavailable-health-endpoint');
      if (hlEp) hlEp.textContent = `${AppState.apiBaseUrl}/health`;
    }
  }
}

export async function retryServerConnection() {
  const btn = document.getElementById('btn-retry-connection');
  const label = document.getElementById('btn-retry-label');

  if (label) label.innerHTML = '<i class="fa-solid fa-spinner fa-spin mr-1"></i> З\'єднуємося...';
  if (btn) btn.disabled = true;

  try {
    await checkHealth();
    setServerOnline(true);
    renderGuestPriceList().catch(e => console.warn('Hero price load error:', e));
    showToast('З\'єднання з сервером успішно відновлено!', 'success');
    updateHeaderUI();
    switchRoleView(AppState.previousRole || AppState.activeRole || 'guest');
  } catch (err) {
    setServerOnline(false);
    showToast('Сервер недоступний або бекенд не запущено. Перевірте статус сервісу.', 'danger');
  } finally {
    if (label) label.textContent = 'Повторити спробу';
    if (btn) btn.disabled = false;
  }
}

export function updateHeaderUI() {
  const nameEl = document.getElementById('current-user-name');
  const roleEl = document.getElementById('current-user-role');
  const btnLabel = document.getElementById('auth-btn-label');
  const quickSelect = document.getElementById('quick-role-select');

  if (AppState.currentUser) {
    if (nameEl) nameEl.textContent = AppState.currentUser.name;
    if (roleEl) roleEl.textContent = AppState.currentUser.pos || AppState.activeRole.toUpperCase();
    if (btnLabel) btnLabel.textContent = 'Вийти';
  } else {
    if (nameEl) nameEl.textContent = 'Гість';
    if (roleEl) roleEl.textContent = 'GUEST (Неавторизований)';
    if (btnLabel) btnLabel.textContent = 'Вхід';
  }

  if (quickSelect) quickSelect.value = AppState.activeRole;
  setServerOnline(AppState.isServerOnline);
}

export function renderRoleNav() {
  // Navigation tabs are embedded into each view
}

export function triggerTabAction(role, tabId) {
  if (role === 'guest') switchGuestTab(tabId);
  else if (role === 'client') switchClientTab(tabId);
  else if (role === 'manager') switchManagerTab(tabId);
  else if (role === 'hr') switchHrTab(tabId);
  else if (role === 'coach') switchCoachTab(tabId);
  else if (role === 'director') switchDirectorTab(tabId);
}

export function switchRoleView(role) {
  if (!AppState.isServerOnline) {
    setServerOnline(false);
    return;
  }

  const cleanRole = (role || 'guest').replace(/_role$/, '').toLowerCase();
  setActiveRole(cleanRole);
  document.querySelectorAll('.role-view').forEach(view => view.classList.add('hidden'));
  const loginView = document.getElementById('view-login');
  if (loginView) loginView.classList.add('hidden');
  const unavailableView = document.getElementById('view-server-unavailable');
  if (unavailableView) unavailableView.classList.add('hidden');

  const targetView = document.getElementById(`view-${cleanRole}`);
  if (targetView) {
    targetView.classList.remove('hidden');
    refreshRoleData(cleanRole);

    // Default tabs per role
    if (cleanRole === 'guest') switchGuestTab('g3');
    else if (cleanRole === 'client') switchClientTab('cl-dash');
    else if (cleanRole === 'manager') switchManagerTab('m4');
    else if (cleanRole === 'hr') switchHrTab('hr_coaches');
    else if (cleanRole === 'coach') switchCoachTab('c1');
    else if (cleanRole === 'director') switchDirectorTab('d1');

    if (typeof window.initFlatpickr === 'function') {
      window.initFlatpickr(targetView);
    }
  }
}

export function refreshRoleData(role) {
  if (!AppState.isServerOnline) return;

  if (role === 'guest') {
    renderGuestPriceList();
    renderGuestHalls();
    renderGuestCoaches();
    populateG1SubscriptionSelect();
  } else if (role === 'client') {
    renderClientDashboard();
  } else if (role === 'manager') {
    populateManagerDropdowns();
    renderM4VisitsTable();
    renderM2ClientsTable();
    renderM8Requests();
  } else if (role === 'hr') {
    renderHrCoachesTable();
    renderHrStaffTable();
    populateHrDropdowns();
  } else if (role === 'coach') {
    renderCoachSchedule();
    populateCoachDropdowns();
  } else if (role === 'director') {
    renderD1Revenue();
    renderD2Attendance();
    renderD3Coaches();
    renderD5Problems();
    renderD6Audit();
    populateDirectorDropdowns();
  }
}

export async function handleAuthAction() {
  if (AppState.currentUser) {
    if (AppState.authToken) {
      try {
        await authApi.logout();
      } catch (err) {
        console.warn('API Logout error:', err);
      }
    }
    setCurrentUser(null);
    setAuthToken(null);
    clearRefreshToken();
    setActiveRole('guest');
    showToast('Ви успішно вийшли з облікового запису.', 'info');
    updateHeaderUI();
    renderRoleNav();
    switchRoleView('guest');
  } else {
    // Show login view
    document.querySelectorAll('.role-view').forEach(view => view.classList.add('hidden'));
    const loginView = document.getElementById('view-login');
    if (loginView) loginView.classList.remove('hidden');
    const unavailableView = document.getElementById('view-server-unavailable');
    if (unavailableView) unavailableView.classList.add('hidden');
  }
}

export async function quickSwitchRole(role) {
  const targetRole = (role || 'guest').replace(/_role$/, '').toLowerCase();
  let matchedUserKey = Object.keys(TEST_ACCOUNTS).find(k => TEST_ACCOUNTS[k].role === targetRole);
  if (!matchedUserKey && targetRole === 'guest') matchedUserKey = 'guest_user';

  if (targetRole === 'guest') {
    setCurrentUser(null);
    setAuthToken(null);
    clearRefreshToken();
    setActiveRole('guest');
    showToast('Перемкнено на гостьовий режим', 'info');
  } else if (matchedUserKey) {
    const account = TEST_ACCOUNTS[matchedUserKey];
    try {
      const res = await authApi.login(matchedUserKey, account.pass);
      setAuthToken(res.token);
      if (res.refreshToken) {
        setRefreshToken(res.refreshToken);
      }
      const userObj = {
        dbUser: res.username,
        name: res.fullName,
        role: targetRole,
        pos: res.role ? res.role.toUpperCase() : account.pos,
        entityId: res.entityId
      };
      setCurrentUser(userObj);
      setActiveRole(targetRole);
      showToast(`Авторизовано через API: ${account.name} (${account.pos})`, 'success');
    } catch (err) {
      setCurrentUser(null);
      setAuthToken(null);
      clearRefreshToken();
      setActiveRole('guest');
      updateHeaderUI();
      renderRoleNav();
      switchRoleView('guest');
      showToast(err.message || 'Помилка зміни ролі: доступ заборонено', 'danger');
      return;
    }
  } else {
    setActiveRole(targetRole);
  }

  updateHeaderUI();
  renderRoleNav();
  switchRoleView(targetRole);
}

export async function fillAndLogin(dbUser, role) {
  const account = TEST_ACCOUNTS[dbUser];
  if (!account) return;
  const targetRole = (role || account.role || 'guest').replace(/_role$/, '').toLowerCase();

  try {
    const res = await authApi.login(dbUser, account.pass);
    setAuthToken(res.token);
    if (res.refreshToken) {
      setRefreshToken(res.refreshToken);
    }
    const userObj = {
      dbUser: res.username,
      name: res.fullName,
      role: targetRole,
      pos: res.role ? res.role.toUpperCase() : account.pos,
      entityId: res.entityId
    };
    setCurrentUser(userObj);
    setActiveRole(targetRole);
    showToast(`Успішний вхід через REST API: ${res.fullName} (${res.role})`, 'success');
  } catch (err) {
    setCurrentUser(null);
    setAuthToken(null);
    clearRefreshToken();
    setActiveRole('guest');
    updateHeaderUI();
    renderRoleNav();
    switchRoleView('guest');
    showToast(err.message || 'Помилка авторизації: вхід заблоковано', 'danger');
    return;
  }

  updateHeaderUI();
  renderRoleNav();
  switchRoleView(targetRole);
}

export async function handleLoginForm(e) {
  e.preventDefault();
  const dbUser = document.getElementById('login-username').value.trim();
  const pass = document.getElementById('login-password').value;

  try {
    const res = await authApi.login(dbUser, pass);
    setAuthToken(res.token);
    if (res.refreshToken) {
      setRefreshToken(res.refreshToken);
    }
    const targetRole = (res.role || 'guest').replace(/_role$/, '').toLowerCase();
    const userObj = {
      dbUser: res.username,
      name: res.fullName,
      role: targetRole,
      pos: res.role ? res.role.toUpperCase() : 'КОРИСТУВАЧ',
      entityId: res.entityId
    };
    setCurrentUser(userObj);
    setActiveRole(targetRole);
    showToast(`Успішний вхід через REST API: ${res.fullName} (${res.role})`, 'success');
    updateHeaderUI();
    renderRoleNav();
    switchRoleView(targetRole);
  } catch (err) {
    console.warn('API Login failed:', err);
    setCurrentUser(null);
    setAuthToken(null);
    clearRefreshToken();
    setActiveRole('guest');
    updateHeaderUI();
    renderRoleNav();
    showToast(`Помилка авторизації: ${err.message}`, 'danger');
  }
}

export function loginAsGuest() {
  setCurrentUser(null);
  setAuthToken(null);
  clearRefreshToken();
  setActiveRole('guest');
  updateHeaderUI();
  renderRoleNav();
  switchRoleView('guest');
  showToast('Гостьовий режим активовано', 'info');
}

export function navigateHome() {
  switchRoleView(AppState.activeRole || 'guest');
}
