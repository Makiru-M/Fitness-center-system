/**
 * FitnessClub IS - Toast Notifications Component
 * Module: components/toast.js
 */

export function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;

  let icon = 'fa-info-circle text-blue-500';
  if (type === 'success') icon = 'fa-circle-check text-emerald-500';
  if (type === 'danger') icon = 'fa-circle-exclamation text-rose-500';
  if (type === 'warning') icon = 'fa-triangle-exclamation text-amber-500';

  toast.innerHTML = `
    <i class="fa-solid ${icon} mt-0.5 text-base"></i>
    <div class="flex-1">
      <div class="text-xs font-semibold text-slate-800">${message}</div>
    </div>
    <button onclick="this.parentElement.remove()" class="text-slate-400 hover:text-slate-600 text-xs ml-2">&times;</button>
  `;

  container.appendChild(toast);
  setTimeout(() => {
    if (toast.parentElement) toast.remove();
  }, 4000);
}
