/**
 * FitnessClub IS - Application Entry Point (Bootstrap & Event Binding)
 * Pure REST API Architecture (Mock database removed)
 * Module: main.js
 */

// State
import { AppState, TEST_ACCOUNTS } from './state/state.js';

// API Services
import { apiFetch, checkHealth } from './api/apiClient.js';
import { authApi } from './api/authApi.js';
import { guestApi } from './api/guestApi.js';
import { clientApi } from './api/clientApi.js';
import { managerApi } from './api/managerApi.js';
import { hrApi } from './api/hrApi.js';
import { coachApi } from './api/coachApi.js';
import { directorApi } from './api/directorApi.js';

// Components
import { showToast } from './components/toast.js';
import {
  initCombobox,
  makeSearchable,
  refreshCombobox,
  initAllComboboxes
} from './components/combobox.js';
import {
  openApiModal,
  closeApiModal,
  toggleApiModeSelection,
  testApiConnection,
  saveApiSettings,
  openMedModal,
  closeMedModal,
  saveMedModal,
  openEditClientModal,
  closeEditClientModal,
  saveEditClientModal,
  openEditCoachModal,
  closeEditCoachModal,
  saveEditCoachModal,
  openEditStaffModal,
  closeEditStaffModal,
  saveEditStaffModal,
  openGroupBookingModal,
  closeGroupBookingModal,
  confirmGroupBooking
} from './components/modal.js';
import {
  initApp,
  setServerOnline,
  retryServerConnection,
  updateHeaderUI,
  renderRoleNav,
  triggerTabAction,
  switchRoleView,
  refreshRoleData,
  handleAuthAction,
  quickSwitchRole,
  fillAndLogin,
  handleLoginForm,
  loginAsGuest,
  navigateHome
} from './components/navigation.js';

// Views
import {
  switchGuestTab,
  renderGuestPriceList,
  renderGuestHalls,
  renderGuestCoaches,
  populateG1SubscriptionSelect,
  updateG1PriceCalculation,
  checkG1Promo,
  handleG1Registration
} from './views/guestView.js';

import {
  switchClientTab,
  getActiveClient,
  renderClientDashboard,
  handleCl1Profile,
  populateCl2Options,
  updateCl2Price,
  checkCl2Promo,
  handleCl2Renew,
  handleCl3Freeze,
  handleCl3Unfreeze,
  populateCl45Options,
  handleCl4Booking,
  handleCl4PrevWeek,
  handleCl4NextWeek,
  handleCl4TodayWeek,
  renderCl4Schedule,
  updateCl4Price,
  applyCl4Promo,
  handleCl5Booking,
  updateCl5Price,
  applyCl5Promo,
  populateCl6Options,
  handleCl6Cancel
} from './views/clientView.js';

import {
  switchManagerTab,
  populateManagerDropdowns,
  previewM4ClientStatus,
  handleM4CheckIn,
  renderM4VisitsTable,
  handleM1NewClient,
  renderM2ClientsTable,
  filterM2Clients,
  updateM3Price,
  checkM3Promo,
  handleM3Sale,
  updateM5ClientPreview,
  checkM5Promo,
  loadM5Schedule,
  handleM5PrevWeek,
  handleM5NextWeek,
  handleM5TodayWeek,
  renderM5Schedule,
  bookM5ClassForClient,
  updateM5Price,
  applyM5Promo,
  closeM5Modal,
  confirmM5GroupBooking,
  handleM5Booking,
  checkM6MedicalAlert,
  checkM6Promo,
  updateM6Price,
  applyM6Promo,
  handleM6Booking,
  previewM7Freeze,
  handleM7Freeze,
  toggleM8NewTime,
  handleM8Action,
  renderM8Requests,
  handleApproveRequest,
  handleRejectRequest
} from './views/managerView.js';

import {
  switchHrTab,
  populateHrDropdowns,
  renderHrCoachesTable,
  filterHrCoaches,
  renderHrStaffTable,
  filterHrStaff,
  handleHr1Hire,
  handleHr3Dismiss,
  quickDismissCoach,
  handleHr4Hire,
  handleHr6Dismiss,
  quickDismissStaff
} from './views/hrView.js';

import {
  switchCoachTab,
  getActiveCoach,
  renderCoachSchedule,
  populateCoachDropdowns,
  renderC2ClientList,
  quickMarkC3,
  quickMarkC4,
  handleC3Mark,
  handleC4Mark,
  handleC4StatusChange,
  toggleC5NewTime,
  handleC5Request
} from './views/coachView.js';

import {
  switchDirectorTab,
  renderD1Revenue,
  renderDirectorRevenue,
  loadRevenueReport,
  initRevenueFilterEvents,
  renderD2Attendance,
  renderD3Coaches,
  renderD5Problems,
  renderD6Audit,
  populateDirectorDropdowns,
  handleD7CreateSub,
  handleD8CreateHall,
  handleD8DecommissionHall,
  handleD8RecommissionHall,
  handleD9CreatePromo,
  handleD10CreateService,
  renderD10PriceList,
  filterD10PriceList,
  openD10EditModal,
  closeD10EditModal,
  handleD10UpdateTariff,
  confirmDeactivatePriceItem,
  openD10CreateModal,
  closeD10CreateModal,
  toggleD10CategoryFields,
  handleD10CreateTurnkey,
  handleD11CreateTemplate,
  handleD12Slot
} from './views/directorView.js';

/**
 * Global Flatpickr Datepicker Initializer with Cyan Dark Theme
 */
export function initFlatpickr(container = document) {
  if (typeof flatpickr === 'undefined') {
    return;
  }

  // 1. Date inputs
  const dateInputs = container.querySelectorAll ? container.querySelectorAll('input[type="date"]') : [];
  dateInputs.forEach(el => {
    if (el._flatpickr) {
      // If already initialized, synchronize bounds & value if needed
      if (el.getAttribute('min')) el._flatpickr.set('minDate', el.getAttribute('min'));
      if (el.getAttribute('max')) el._flatpickr.set('maxDate', el.getAttribute('max'));
      return;
    }

    flatpickr(el, {
      locale: 'uk',
      dateFormat: 'Y-m-d',
      altInput: true,
      altFormat: 'd.m.Y',
      altInputClass: el.className ? `${el.className} flatpickr-custom-alt` : 'form-control flatpickr-custom-alt',
      allowInput: true,
      minDate: el.getAttribute('min') || null,
      maxDate: el.getAttribute('max') || null,
      defaultDate: el.value || null,
      onChange: (selectedDates, dateStr) => {
        el.value = dateStr;
        el.dispatchEvent(new Event('change', { bubbles: true }));
        el.dispatchEvent(new Event('input', { bubbles: true }));
      }
    });
  });

  // 2. DateTime-local inputs
  const dateTimeInputs = container.querySelectorAll ? container.querySelectorAll('input[type="datetime-local"]') : [];
  dateTimeInputs.forEach(el => {
    if (el._flatpickr) {
      if (el.getAttribute('min')) el._flatpickr.set('minDate', el.getAttribute('min'));
      if (el.getAttribute('max')) el._flatpickr.set('maxDate', el.getAttribute('max'));
      return;
    }

    flatpickr(el, {
      locale: 'uk',
      enableTime: true,
      time_24hr: true,
      dateFormat: 'Y-m-d\\TH:i',
      altInput: true,
      altFormat: 'd.m.Y H:i',
      altInputClass: el.className ? `${el.className} flatpickr-custom-alt` : 'form-control flatpickr-custom-alt',
      allowInput: true,
      minDate: el.getAttribute('min') || null,
      maxDate: el.getAttribute('max') || null,
      defaultDate: el.value || null,
      onChange: (selectedDates, dateStr) => {
        el.value = dateStr;
        el.dispatchEvent(new Event('change', { bubbles: true }));
        el.dispatchEvent(new Event('input', { bubbles: true }));
      }
    });
  });
}

// Bind globals for HTML inline event handlers
Object.assign(window, {
  // State & Utilities
  AppState,
  TEST_ACCOUNTS,
  apiFetch,
  checkHealth,
  showToast,
  setServerOnline,
  retryServerConnection,
  initCombobox,
  makeSearchable,
  refreshCombobox,
  initAllComboboxes,
  initFlatpickr,

  // API Services
  authApi,
  guestApi,
  clientApi,
  managerApi,
  hrApi,
  coachApi,
  directorApi,

  // Navigation & Auth
  initApp,
  updateHeaderUI,
  renderRoleNav,
  triggerTabAction,
  switchRoleView,
  refreshRoleData,
  handleAuthAction,
  quickSwitchRole,
  fillAndLogin,
  handleLoginForm,
  loginAsGuest,
  navigateHome,

  // Modals
  openApiModal,
  closeApiModal,
  toggleApiModeSelection,
  testApiConnection,
  saveApiSettings,
  openMedModal,
  closeMedModal,
  saveMedModal,
  openEditClientModal,
  closeEditClientModal,
  saveEditClientModal,
  openEditCoachModal,
  closeEditCoachModal,
  saveEditCoachModal,
  openEditStaffModal,
  closeEditStaffModal,
  saveEditStaffModal,
  openGroupBookingModal,
  closeGroupBookingModal,
  confirmGroupBooking,

  // Guest View
  switchGuestTab,
  renderGuestPriceList,
  renderGuestHalls,
  renderGuestCoaches,
  populateG1SubscriptionSelect,
  updateG1PriceCalculation,
  checkG1Promo,
  handleG1Registration,

  // Client View
  switchClientTab,
  getActiveClient,
  renderClientDashboard,
  handleCl1Profile,
  populateCl2Options,
  updateCl2Price,
  checkCl2Promo,
  handleCl2Renew,
  handleCl3Freeze,
  handleCl3Unfreeze,
  populateCl45Options,
  handleCl4Booking,
  handleCl4PrevWeek,
  handleCl4NextWeek,
  handleCl4TodayWeek,
  renderCl4Schedule,
  updateCl4Price,
  applyCl4Promo,
  handleCl5Booking,
  updateCl5Price,
  applyCl5Promo,
  populateCl6Options,
  handleCl6Cancel,

  // Manager View
  switchManagerTab,
  populateManagerDropdowns,
  previewM4ClientStatus,
  handleM4CheckIn,
  renderM4VisitsTable,
  handleM1NewClient,
  renderM2ClientsTable,
  filterM2Clients,
  updateM3Price,
  checkM3Promo,
  handleM3Sale,
  updateM5ClientPreview,
  checkM5Promo,
  loadM5Schedule,
  handleM5PrevWeek,
  handleM5NextWeek,
  handleM5TodayWeek,
  renderM5Schedule,
  bookM5ClassForClient,
  updateM5Price,
  applyM5Promo,
  closeM5Modal,
  confirmM5GroupBooking,
  handleM5Booking,
  checkM6MedicalAlert,
  checkM6Promo,
  updateM6Price,
  applyM6Promo,
  handleM6Booking,
  previewM7Freeze,
  handleM7Freeze,
  toggleM8NewTime,
  handleM8Action,
  renderM8Requests,
  handleApproveRequest,
  handleRejectRequest,

  // HR View
  switchHrTab,
  populateHrDropdowns,
  renderHrCoachesTable,
  filterHrCoaches,
  renderHrStaffTable,
  filterHrStaff,
  handleHr1Hire,
  handleHr3Dismiss,
  quickDismissCoach,
  handleHr4Hire,
  handleHr6Dismiss,
  quickDismissStaff,

  // Coach View
  switchCoachTab,
  getActiveCoach,
  renderCoachSchedule,
  populateCoachDropdowns,
  renderC2ClientList,
  quickMarkC3,
  quickMarkC4,
  handleC3Mark,
  handleC4Mark,
  handleC4StatusChange,
  toggleC5NewTime,
  handleC5Request,

  // Director View
  switchDirectorTab,
  renderD1Revenue,
  renderDirectorRevenue,
  loadRevenueReport,
  initRevenueFilterEvents,
  renderD2Attendance,
  renderD3Coaches,
  renderD5Problems,
  renderD6Audit,
  populateDirectorDropdowns,
  handleD7CreateSub,
  handleD8CreateHall,
  handleD8DecommissionHall,
  handleD8RecommissionHall,
  handleD9CreatePromo,
  handleD10CreateService,
  renderD10PriceList,
  filterD10PriceList,
  openD10EditModal,
  closeD10EditModal,
  handleD10UpdateTariff,
  confirmDeactivatePriceItem,
  openD10CreateModal,
  closeD10CreateModal,
  toggleD10CategoryFields,
  handleD10CreateTurnkey,
  handleD11CreateTemplate,
  handleD12Slot
});

window.handleD8RecommissionHall = handleD8RecommissionHall;

// Bootstrap application when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    initApp();
    initFlatpickr();
    initRevenueFilterEvents();
  });
} else {
  initApp();
  initFlatpickr();
  initRevenueFilterEvents();
}
