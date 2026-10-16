// Supabase bağlantısı. Bunlar GİZLİ DEĞİLDİR: proje adresi ve herkese açık (anon/publishable) anahtar istemciye girer.
// ASLA service_role anahtarını buraya koyma.
// anonKey boşsa günlük mod sunucusuz (yerel, sıralamasız) çalışır.
window.HEDEF_AYAR = window.HEDEF_AYAR || {
  url: "https://atfeayrgapwgaegcdvfr.supabase.co",
  anonKey: ""   // Supabase paneli → Project Settings → API → anon / publishable anahtar
};
