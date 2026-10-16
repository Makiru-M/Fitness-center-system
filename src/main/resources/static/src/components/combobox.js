/**
 * FitnessClub IS - Combobox / Autocomplete Component
 * Native, modular ES6 component with real-time fuzzy/prefix search,
 * keyboard navigation (ArrowUp, ArrowDown, Enter, Escape),
 * match highlighting, and full bidirectional two-way binding with HTML <select>.
 * Module: components/combobox.js
 */

export const COMBOBOX_TARGETS = [
  '#m3-client',
  '#m4-client',
  '#m5-client',
  '#m6-client',
  '#m7-client',
  '#cl5-coach',
  '#m6-coach',
  '#hr3-coach',
  '#d11-coach',
  '#d12-coach'
];

/**
 * Escapes characters for HTML safe rendering
 */
function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * Highlights matching search query within text safely
 */
function highlightMatch(text, query) {
  if (!query) return escapeHtml(text);
  const q = query.trim();
  if (!q) return escapeHtml(text);

  const lowerText = text.toLowerCase();
  const lowerQ = q.toLowerCase();
  const idx = lowerText.indexOf(lowerQ);

  if (idx === -1) {
    return escapeHtml(text);
  }

  const before = escapeHtml(text.slice(0, idx));
  const match = escapeHtml(text.slice(idx, idx + q.length));
  const after = highlightMatch(text.slice(idx + q.length), q);

  return `${before}<mark class="combobox-highlight">${match}</mark>${after}`;
}

/**
 * Combobox instance manager
 */
class Combobox {
  constructor(selectElement, options = {}) {
    this.select = selectElement;
    this.options = options;
    this.items = [];
    this.filteredItems = [];
    this.activeIndex = -1;
    this.isOpen = false;
    this.isInternalChange = false;

    this.initDOM();
    this.loadOptions();
    this.bindEvents();

    this.select._comboboxInstance = this;
  }

  initDOM() {
    // Hide original select (keep in DOM for form submission)
    this.select.classList.add('hidden');
    this.select.style.display = 'none';

    // If select was required, track and transfer to input for proper native UX
    if (this.select.hasAttribute('required')) {
      this.wasRequired = true;
      this.select.removeAttribute('required');
      this.select.dataset.wasRequired = 'true';
    }

    // Determine placeholder
    let placeholder = this.options.placeholder;
    if (!placeholder) {
      const selectId = this.select.id || '';
      if (selectId.includes('coach')) {
        placeholder = '🔍 Почніть вводити прізвище або спеціалізацію тренера...';
      } else if (selectId.includes('client')) {
        placeholder = '🔍 Почніть вводити прізвище або телефон...';
      } else {
        placeholder = '🔍 Почніть вводити для пошуку...';
      }
    }

    // Create wrapper
    this.wrapper = document.createElement('div');
    this.wrapper.className = 'combobox-wrapper relative w-full';

    // Input container
    this.inputContainer = document.createElement('div');
    this.inputContainer.className = 'combobox-input-container relative flex items-center w-full';

    // Search input
    this.input = document.createElement('input');
    this.input.type = 'text';
    this.input.autocomplete = 'off';
    this.input.spellcheck = false;
    this.input.placeholder = placeholder;
    this.input.className = `form-control combobox-input ${this.select.className.replace('hidden', '').replace('form-control', '').trim()}`;
    if (this.wasRequired) {
      this.input.required = true;
    }

    // Actions container (Clear button + Dropdown chevron)
    this.actionsContainer = document.createElement('div');
    this.actionsContainer.className = 'combobox-actions absolute right-2 flex items-center gap-1';

    // Clear button
    this.clearBtn = document.createElement('button');
    this.clearBtn.type = 'button';
    this.clearBtn.tabIndex = -1;
    this.clearBtn.className = 'combobox-btn combobox-clear-btn hidden';
    this.clearBtn.title = 'Очистити вибір';
    this.clearBtn.innerHTML = '<i class="fa-solid fa-xmark"></i>';

    // Dropdown toggle button
    this.toggleBtn = document.createElement('button');
    this.toggleBtn.type = 'button';
    this.toggleBtn.tabIndex = -1;
    this.toggleBtn.className = 'combobox-btn combobox-toggle-btn';
    this.toggleBtn.title = 'Показати всі варіанти';
    this.toggleBtn.innerHTML = '<i class="fa-solid fa-chevron-down text-[11px] transition-transform duration-200"></i>';

    this.actionsContainer.appendChild(this.clearBtn);
    this.actionsContainer.appendChild(this.toggleBtn);

    this.inputContainer.appendChild(this.input);
    this.inputContainer.appendChild(this.actionsContainer);

    // Dropdown list
    this.dropdown = document.createElement('ul');
    this.dropdown.className = 'combobox-dropdown absolute z-50 w-full max-h-60 overflow-y-auto bg-white border border-slate-200 rounded-lg shadow-xl hidden mt-1 py-1';
    this.dropdown.setAttribute('role', 'listbox');

    // Assemble in wrapper
    this.wrapper.appendChild(this.inputContainer);
    this.wrapper.appendChild(this.dropdown);

    // Insert into DOM right next to select
    this.select.parentNode.insertBefore(this.wrapper, this.select);
    this.wrapper.appendChild(this.select);
  }

  loadOptions() {
    this.items = [];
    const selectOptions = Array.from(this.select.options);

    selectOptions.forEach(opt => {
      // Skip empty placeholder option if disabled
      if (opt.value === '' && opt.disabled) {
        if (!this.options.placeholder && opt.text && !opt.text.startsWith('--')) {
          this.input.placeholder = `🔍 ${opt.text}`;
        }
        return;
      }

      this.items.push({
        value: opt.value,
        text: opt.text.trim(),
        selected: opt.selected,
        disabled: opt.disabled
      });
    });

    this.syncInputWithSelect();
  }

  syncInputWithSelect() {
    const selectedVal = this.select.value;
    const selectedOpt = this.items.find(i => String(i.value) === String(selectedVal) && i.value !== '');

    if (selectedOpt) {
      this.input.value = selectedOpt.text;
      this.clearBtn.classList.remove('hidden');
      this.input.setCustomValidity('');
    } else {
      this.input.value = '';
      this.clearBtn.classList.add('hidden');
    }
  }

  bindEvents() {
    // Open on input focus / click
    this.input.addEventListener('focus', () => {
      this.openDropdown(this.input.value);
      this.input.select();
    });

    // Real-time filtering
    this.input.addEventListener('input', () => {
      this.openDropdown(this.input.value);
      if (this.input.value.trim().length > 0) {
        this.clearBtn.classList.remove('hidden');
      } else {
        this.clearBtn.classList.add('hidden');
        if (!this.wasRequired) {
          this.setSelectValue('');
        }
      }
    });

    // Keyboard navigation
    this.input.addEventListener('keydown', (e) => {
      this.handleKeydown(e);
    });

    // Clear button
    this.clearBtn.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.clear();
      this.input.focus();
    });

    // Toggle button
    this.toggleBtn.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      if (this.isOpen) {
        this.closeDropdown();
      } else {
        this.openDropdown('');
        this.input.focus();
      }
    });

    // Outside click closes dropdown
    document.addEventListener('click', (e) => {
      if (!this.wrapper.contains(e.target)) {
        this.handleBlur();
        this.closeDropdown();
      }
    });

    // Sync if select value changes externally
    this.select.addEventListener('change', () => {
      if (!this.isInternalChange) {
        this.syncInputWithSelect();
      }
    });

    // Support form reset
    if (this.select.form) {
      this.select.form.addEventListener('reset', () => {
        setTimeout(() => {
          this.syncInputWithSelect();
        }, 0);
      });
    }
  }

  handleKeydown(e) {
    if (!this.isOpen && (e.key === 'ArrowDown' || e.key === 'ArrowUp')) {
      e.preventDefault();
      this.openDropdown(this.input.value);
      return;
    }

    if (!this.isOpen) return;

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (this.filteredItems.length === 0) return;
      this.activeIndex = (this.activeIndex + 1) % this.filteredItems.length;
      this.updateActiveItem();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (this.filteredItems.length === 0) return;
      this.activeIndex = (this.activeIndex - 1 + this.filteredItems.length) % this.filteredItems.length;
      this.updateActiveItem();
    } else if (e.key === 'Enter') {
      if (this.isOpen && this.filteredItems.length > 0) {
        e.preventDefault();
        const targetIdx = this.activeIndex >= 0 ? this.activeIndex : 0;
        const item = this.filteredItems[targetIdx];
        if (item) {
          this.selectItem(item);
        }
      }
    } else if (e.key === 'Escape') {
      e.preventDefault();
      this.closeDropdown();
      this.syncInputWithSelect();
    } else if (e.key === 'Tab') {
      this.handleBlur();
      this.closeDropdown();
    }
  }

  handleBlur() {
    const text = this.input.value.trim().toLowerCase();
    if (!text) {
      this.setSelectValue('');
      return;
    }

    // If currently typed text matches exactly one item
    const exactMatch = this.items.find(i => i.text.toLowerCase() === text);
    if (exactMatch) {
      this.selectItem(exactMatch);
    } else {
      // Revert to current selected value
      this.syncInputWithSelect();
    }
  }

  openDropdown(query = '') {
    const q = (query || '').trim().toLowerCase();

    if (!q) {
      this.filteredItems = [...this.items];
    } else {
      this.filteredItems = this.items.filter(item => {
        return item.text.toLowerCase().includes(q);
      });
    }

    this.renderDropdown(q);
    this.dropdown.classList.remove('hidden');
    this.isOpen = true;
    this.toggleBtn.querySelector('i')?.classList.add('rotate-180');

    // Default active item to first or current selection
    const currentVal = this.select.value;
    const currentIdx = this.filteredItems.findIndex(i => String(i.value) === String(currentVal));
    this.activeIndex = currentIdx >= 0 ? currentIdx : (this.filteredItems.length > 0 ? 0 : -1);
    this.updateActiveItem();
  }

  closeDropdown() {
    this.dropdown.classList.add('hidden');
    this.isOpen = false;
    this.activeIndex = -1;
    this.toggleBtn.querySelector('i')?.classList.remove('rotate-180');
  }

  renderDropdown(query = '') {
    this.dropdown.innerHTML = '';

    if (this.filteredItems.length === 0) {
      const emptyLi = document.createElement('li');
      emptyLi.className = 'combobox-empty p-3 text-center text-xs text-slate-400 select-none';
      emptyLi.innerHTML = '<i class="fa-solid fa-magnifying-glass text-slate-300 mr-1.5"></i> Збігів не знайдено';
      this.dropdown.appendChild(emptyLi);
      return;
    }

    const currentVal = String(this.select.value);

    this.filteredItems.forEach((item, index) => {
      const li = document.createElement('li');
      const isSelected = String(item.value) === currentVal && item.value !== '';
      li.className = `combobox-item ${isSelected ? 'selected' : ''}`;
      li.setAttribute('role', 'option');
      li.setAttribute('data-index', index);
      li.setAttribute('data-value', item.value);

      const highlightedText = highlightMatch(item.text, query);
      li.innerHTML = `
        <span class="combobox-item-text truncate">${highlightedText}</span>
        ${isSelected ? '<i class="fa-solid fa-check text-cyan-600 text-xs ml-2 flex-shrink-0"></i>' : ''}
      `;

      li.addEventListener('mousedown', (e) => {
        e.preventDefault(); // Prevents input blur before click
      });

      li.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.selectItem(item);
      });

      li.addEventListener('mouseenter', () => {
        this.activeIndex = index;
        this.updateActiveItem(false);
      });

      this.dropdown.appendChild(li);
    });
  }

  updateActiveItem(scroll = true) {
    const listItems = this.dropdown.querySelectorAll('.combobox-item');
    listItems.forEach((li, idx) => {
      if (idx === this.activeIndex) {
        li.classList.add('active');
        if (scroll) {
          li.scrollIntoView({ block: 'nearest' });
        }
      } else {
        li.classList.remove('active');
      }
    });
  }

  selectItem(item) {
    this.setSelectValue(item.value);
    this.input.value = item.text;
    this.clearBtn.classList.remove('hidden');
    this.closeDropdown();
  }

  setSelectValue(val) {
    this.isInternalChange = true;
    this.select.value = val;

    if (this.wasRequired) {
      if (!val) {
        this.input.setCustomValidity('Будь ласка, оберіть пункт зі списку.');
      } else {
        this.input.setCustomValidity('');
      }
    }

    // Trigger standard change & input events so all attached listeners execute
    this.select.dispatchEvent(new Event('change', { bubbles: true }));
    this.select.dispatchEvent(new Event('input', { bubbles: true }));
    this.isInternalChange = false;
  }

  clear() {
    this.setSelectValue('');
    this.input.value = '';
    this.clearBtn.classList.add('hidden');
    this.openDropdown('');
  }

  refresh() {
    this.loadOptions();
    if (this.isOpen) {
      this.renderDropdown(this.input.value);
    }
  }

  destroy() {
    if (this.wasRequired) {
      this.select.setAttribute('required', 'true');
    }
    this.select.classList.remove('hidden');
    this.select.style.display = '';
    this.wrapper.parentNode.insertBefore(this.select, this.wrapper);
    this.wrapper.remove();
    delete this.select._comboboxInstance;
  }
}

/**
 * Initializes Combobox on a single select element or CSS selector.
 * If already initialized, it refreshes the component.
 */
export function initCombobox(target, options = {}) {
  const el = typeof target === 'string' ? document.querySelector(target) : target;
  if (!el || el.tagName !== 'SELECT') {
    return null;
  }

  if (el._comboboxInstance) {
    el._comboboxInstance.refresh();
    return el._comboboxInstance;
  }

  return new Combobox(el, options);
}

/**
 * Alias for initCombobox as requested by specification
 */
export function makeSearchable(target, options = {}) {
  return initCombobox(target, options);
}

/**
 * Refreshes an existing Combobox instance when select options change dynamically
 */
export function refreshCombobox(target) {
  const el = typeof target === 'string' ? document.querySelector(target) : target;
  if (!el) return null;

  if (el._comboboxInstance) {
    el._comboboxInstance.refresh();
    return el._comboboxInstance;
  } else {
    // If not initialized yet, initialize it
    return initCombobox(el);
  }
}

/**
 * Discovers and initializes all known client & coach comboboxes across the application
 */
export function initAllComboboxes() {
  COMBOBOX_TARGETS.forEach(selector => {
    const el = document.querySelector(selector);
    if (el) {
      initCombobox(el);
    }
  });
}
