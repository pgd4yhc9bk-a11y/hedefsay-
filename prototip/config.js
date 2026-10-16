// Supabase bağlantısı. Bunlar GİZLİ DEĞİLDİR: proje adresi ve herkese açık (anon/publishable) anahtar istemciye girer.
// ASLA service_role anahtarını buraya koyma.
// anonKey boşsa günlük mod ve canlı düello sunucusuz kalır (günlük yerelde, sıralamasız çalışır).
window.HEDEF_AYAR = window.HEDEF_AYAR || {
  url: "https://atfeayrgapwgaegcdvfr.supabase.co",
  anonKey: "sb_publishable_Pgbtihf4_R5ANcQwMMGB3A_k4xXHw1r"   // herkese açık (publishable) anahtar; Supabase paneli → Project Settings → API
};
