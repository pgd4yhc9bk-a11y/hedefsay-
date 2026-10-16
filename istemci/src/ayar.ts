// Supabase bağlantısı. Bunlar GİZLİ DEĞİLDİR: proje adresi ve herkese açık (anon/publishable) anahtar.
// ASLA service_role anahtarını buraya koyma. Anahtar boşsa (EXPO_PUBLIC_SUPABASE_ANON_KEY=) günlük mod ve canlı düello kapalı, pratik açık kalır.
// Derleme zamanında EXPO_PUBLIC_SUPABASE_URL / EXPO_PUBLIC_SUPABASE_ANON_KEY ile değiştirilebilir.
export const AYAR = {
  url: process.env.EXPO_PUBLIC_SUPABASE_URL ?? "https://atfeayrgapwgaegcdvfr.supabase.co",
  anonKey: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? "sb_publishable_Pgbtihf4_R5ANcQwMMGB3A_k4xXHw1r",
};
