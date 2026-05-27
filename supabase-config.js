// Front-end Supabase connection settings for TAINT.
// Replace these two values with Supabase Dashboard -> Project Settings -> API.
// The anon/public key is designed to be used in browser apps. Do not put the
// service_role key here.
window.TAINT_SUPABASE_CONFIG = {
  url: 'https://pywjwsrjzgkvgplkxdry.supabase.co',
  anonKey: 'sb_publishable_Jn4aL5TQIzd6mPm5JayQeA_M7dzGBn9',
  auth: {
    // Recovery and confirmation emails should return to a real deployed page,
    // not file:// or a local test URL.
    siteUrl: 'https://sabarivasantkmech-blip.github.io/taint/index.html',
    validateResetEmail: true,
    resetEmailCooldownMs: 60000,
    // Keep social buttons hidden until the matching providers are enabled in
    // Supabase Dashboard -> Authentication -> Providers.
    oauthProviders: [],
    enterpriseSso: false
  }
};
