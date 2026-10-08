import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL?.trim();
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY?.trim();
const appMode = (import.meta.env.VITE_APP_MODE || "china").trim().toLowerCase();

if (appMode !== "china") {
  throw new Error(
    `[CargoBridge China] Invalid VITE_APP_MODE="${appMode}". This deployment is China-only.`,
  );
}

if (!supabaseUrl || !supabaseAnonKey) {
  // Keep the error explicit instead of silently falling back to local/UI-only mode.
  throw new Error(
    "[CargoBridge China] Missing Supabase environment variables. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in .env.",
  );
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});

export const createSupabaseAuthProbe = () =>
  createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  });

export const SUPABASE_CONFIG = Object.freeze({
  url: supabaseUrl,
  appMode,
});
