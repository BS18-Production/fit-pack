/** Tamamen sentetik; kullanıcı verisinden üretilmedi. */
export function demoOverview(days = 7) {
  const end = Date.UTC(2026, 9, 29, 12);
  const values = [2, 4, 3, 6, 5, 8, 7];
  return { generated_at: new Date(end).toISOString(), window_days: days,
    coverage: { started_at: '2026-10-23T08:00:00Z', consenting_accounts: 12, observed_accounts: 9, observed_sessions: 35, missing_history: true },
    metrics: { session_starts: 35, workout_starts: 18, workout_saves: 14, workout_saved_accounts: 7 },
    daily: values.map((v, i) => ({ day: new Date(end - (6 - i) * 86400000).toISOString().slice(0, 10), sessions: v, workout_saves: Math.max(0, v - 3) })),
    errors: [{ code: 'network', screen: 'sync', count: 3 }, { code: 'storage', screen: 'workout', count: 1 }],
    sync: [{ outcome: 'success', count: 42 }, { outcome: 'unreachable', count: 3 }],
    onboarding: [{ step: 'training', count: 8, accounts: 7 }, { step: 'nutrition', count: 6, accounts: 6 }, { step: 'complete', count: 6, accounts: 6 }],
    versions: [{ version: '1.0.0', build: '2', platform: 'ios', os_major: 26, sessions: 24, accounts: 6 }, { version: '1.0.0', build: '2', platform: 'android', os_major: 16, sessions: 11, accounts: 4 }], notice: 'Sentetik örnek' };
}
export function demoSupport() {
  return { account: { id: '00000000-0000-4000-8000-000000000001', email_masked: 'd***@example.test', created_at: '2026-10-23T08:00:00Z', email_confirmed: true, onboarded: true },
    categories: [{ category: 'workouts', count: 4, latest_record_at: '2026-10-28T16:00:00Z', latest_server_change_at: '2026-10-28T16:32:00Z' }, { category: 'nutrition', count: 12, latest_record_at: '2026-10-28T08:00:00Z', latest_server_change_at: '2026-10-28T08:15:00Z' }, { category: 'body', count: 2, latest_record_at: '2026-10-25T07:00:00Z', latest_server_change_at: '2026-10-25T07:02:00Z' }], request_id: '00000000-0000-4000-8000-000000000002' };
}
