# Hedef — Expo istemcisi (Faz 2)

Expo SDK 58 / React Native 0.88, TypeScript. Prototipteki (`../prototip`) tüm akışlar: **pratik** (bota karşı, tamamen çevrimdışı),
**günlük mücadele** (sunucu), **canlı düello** (sunucu). Oyun çekirdeği `../prototip/oyun.js`'in kopyasıdır (`src/cekirdek`).

## Çalıştırma

```bash
cd istemci && npm install
npx expo start            # telefonda Expo Go veya `w` ile web
npx tsc --noEmit          # tip denetimi
```

Sunucu modları için herkese açık (anon/publishable) anahtar gerekir; **`service_role` ASLA**:

```bash
EXPO_PUBLIC_SUPABASE_ANON_KEY=<anon-anahtar> npx expo start
# URL'yi değiştirmek için EXPO_PUBLIC_SUPABASE_URL (varsayılan: hedef-dev projesi)
```

Anahtar yoksa menüde yalnızca pratik görünür.

## Çekirdeği güncelleme

Çekirdeğin tek kaynağı `prototip/oyun.js` ve `sozluk.js`. Değiştirdiysen kökten `scripts/senkronla.sh` çalıştır (Edge Function'lara ve buraya kopyalar). `prototip/test.js` kopyaların güncel olduğunu denetler.

## Testler

Uçtan uca (tarayıcıda, web çıktısı): [e2e/e2e.js](e2e/e2e.js) başlığındaki adımlar. Gerçek Edge Function kodu sahte veritabanıyla sunulur; pratik, günlük, iki oyunculu canlı düello, bot, yenileme sonrası devam, anahtarsız yapıda sunucu modlarının gizlenmesi denenir.

## Yapılmayanlar / bilinenler

- **Gerçek cihazda denenmedi.** Doğrulama web çıktısı üzerinde (react-native-web) yapıldı; iOS/Android'de ayrıca denenmeli (klavye, güvenli alan, kaydırma).
- Kullanılmayan: **Skia** (doküman öneriyordu; mevcut arayüz için gerekmedi), **Aslan İnteraktif açılış intro'su** (marka varlıkları gerekli), Expo Router (tek akışlı durum makinesi yeterli).
- Simge/açılış ekranı şablondaki yer tutucular; paket adları (`bundleIdentifier` / `package`) kesin ad belli olunca verilecek.
- Fiziksel klavye yalnızca web'de dinlenir; mobilde ekrandaki harf karoları kullanılır.
- Anonim oturum: uygulama verisi silinirse oyuncu kartı da kaybolur (hesap bağlama sonraki sürümde).
- Expo her sürümde API değiştirir: yeni bir Expo/RN API'sine dokunmadan önce `https://docs.expo.dev/versions/v58.0.0/` sürümlü dokümanına bak.
