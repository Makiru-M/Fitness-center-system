/**
 * FitnessClub IS - Theme Management (Light / Dark Mode)
 * Module: components/theme.js
 */

import { STORAGE_KEYS } from '../state/state.js';

export function getPreferredTheme() {
  const saved = localStorage.getItem(STORAGE_KEYS.THEME);
  if (saved === 'light' || saved === 'dark') {
    return saved;
  }
  // Default is dark
  return 'dark';
}

export function updateThemeUI(theme) {
  const icon = document.getElementById('theme-toggle-icon');
  const btn = document.getElementById('theme-toggle-btn');

  if (theme === 'light') {
    document.documentElement.classList.remove('dark');
    document.documentElement.classList.add('light');
    if (icon) {
      icon.className = 'fa-solid fa-moon';
    }
    if (btn) {
      btn.title = 'Перемкнути на темну тему';
      btn.setAttribute('aria-label', 'Перемкнути на темну тему');
    }
  } else {
    document.documentElement.classList.remove('light');
    document.documentElement.classList.add('dark');
    if (icon) {
      icon.className = 'fa-solid fa-sun';
    }
    if (btn) {
      btn.title = 'Перемкнути на світлу тему';
      btn.setAttribute('aria-label', 'Перемкнути на світлу тему');
    }
  }
}

export function initTheme() {
  const theme = getPreferredTheme();
  updateThemeUI(theme);
}

export function toggleTheme() {
  const isLight = document.documentElement.classList.contains('light');
  const nextTheme = isLight ? 'dark' : 'light';

  try {
    localStorage.setItem(STORAGE_KEYS.THEME, nextTheme);
  } catch (e) {
    console.warn('Failed to save theme to localStorage:', e);
  }

  updateThemeUI(nextTheme);

  // Dispatch custom event in case components need to react
  window.dispatchEvent(new CustomEvent('themeChanged', { detail: { theme: nextTheme } }));
}
