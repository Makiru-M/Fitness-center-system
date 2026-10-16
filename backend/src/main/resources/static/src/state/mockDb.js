/**
 * FitnessClub IS - Local Relational Mock Database
 * DEPRECATED / DISABLED: The application now operates 100% via REST API.
 * This stub remains only to prevent import breakage if referenced externally.
 */

export function getDb() {
  console.warn('[FitnessClub IS] Mock database is disabled. Using REST API.');
  return {};
}

export function saveDb() {
  console.warn('[FitnessClub IS] Mock database is disabled. Using REST API.');
}

export function initMockData() {
  // Disabled
}
