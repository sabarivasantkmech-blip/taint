const SUPABASE_CONFIG = (() => {
  const cfg = window.TAINT_SUPABASE_CONFIG || {};
  return {
    url    : String(cfg.url || 'YOUR_PROJECT_URL').trim().replace(/\/+$/, ''),
    anonKey: String(cfg.anonKey || 'YOUR_ANON_PUBLIC_KEY').trim()
  };
})();