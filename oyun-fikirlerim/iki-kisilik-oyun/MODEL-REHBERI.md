# 3D Karakter Rehberi (deneme)

Amaç: Nehir'i 3D modelle, **tek bir deneme bölümünde** ("3D Deneme") oyuna sokup neyin eksik, neyin yanlış olduğunu birlikte görmek.
Oyun yine 2D; karakter yandan ortografik kamerayla düz siyah siluet olarak çizilir. Yalnızca atkı (kırmızı), fener alevi (turuncu) ve bez tavşan (krem) renkli kalır.

## 1) Model (Nehir)
1. ChatGPT'ye "3D için karakter sayfası" promptunu verin (ön, yan, arka, A-poz).
2. Görselden-3D aracına yükleyin (Meshy, Tripo, Hunyuan3D vb.). Çıktıyı **FBX** ya da **OBJ** (+doku) alın. Mixamo yalnızca FBX, OBJ ya da ZIP kabul eder (GLB kabul etmez).
3. Gerekirse Blender'da temizleyin: tek parça (giysi, saç, vücut ayrı yüzer parça olmasın), T-poz, yüz öne, ayaklar zeminde, makul poligon (en fazla 30-50 bin üçgen).

## 2) İskelet ve hareketler (Mixamo, ücretsiz, Adobe hesabı gerekir)
1. mixamo.com → **Upload Character** → modeli yükleyin → işaretçileri (çene, bilekler, dirsekler, dizler, kasık) yerleştirin → otomatik iskelet.
2. **Aynı karakteri** seçili tutarak her hareketi indirin: Format **FBX Binary**, **Without Skin** (karakterin kendisi ilk indirmede **With Skin**), **30 FPS**, yürüme/koşma/düşme için **"In Place"** kutusunu işaretleyin.
3. Dosyaları aşağıdaki **adlarla** kaydedin (uzantı .fbx). Öncelik sırası:

| Dosya adı | Mixamo'da aranacak hareket | Öncelik |
|---|---|---|
| `idle` | Idle / Breathing Idle | 1 |
| `walk` | Walking | 1 |
| `run` | Running | 1 |
| `jump` | Jump / Standing Jump | 1 |
| `fall` | Falling Idle | 1 |
| `land` | Landing / Hard Landing | 1 |
| `roll` | Rolling / Falling To Roll | 2 |
| `push` | Pushing | 2 |
| `pull` | Pulling / Dragging (varsa) | 2 |
| `crawl` | Crouch Walk / Crawling | 3 |
| `climb` | Climbing | 3 |
| `slip` | (buz için denge arayan bir hareket, varsa) | 3 |
| `wade` | (çamur için ağır yürüyüş, varsa) | 3 |
| `cry` | Crying | 3 |

Mixamo'da bu adlarla birebir hareket olmayabilir, benzerini seçin. Hepsini yapmanız gerekmez: ilk altısıyla başlayalım. Eksik olanlar için oyun en yakın olanı kullanır (örn. `run` yoksa `walk`).

## 3) Dosyaları nereye koymalı
```
oyun-fikirlerim/iki-kisilik-oyun/godot/assets/3d/nehir/model.fbx        (With Skin, karakter)
oyun-fikirlerim/iki-kisilik-oyun/godot/assets/3d/nehir/anim/idle.fbx    (Without Skin)
oyun-fikirlerim/iki-kisilik-oyun/godot/assets/3d/nehir/anim/walk.fbx
...
```
Bana buradan göndermeniz de olur (sohbete ekleyin). Depoya kendiniz koymak isterseniz GitHub'da dal `claude/intelligent-edison-7fygf8` → klasör → **Add file → Upload files**.
`.glb` de olur (aynı adlarla).

## 4) Oyunda nasıl görürsünüz
Menüden **Deneme bölümleri → 3D Deneme**. Bölümde: düz zemin, basamak, çukur, çamur, buz, itilecek kutu. **F3** model raporunu gösterir
(model bulundu mu, kaç kemik, ham boy, hangi animasyonlar var, hangileri eksik, uyuşmayan kemik sayısı).

## 5) Birlikte bakacağımız kontrol listesi
- [ ] Model doğru yöne mi bakıyor? (Ters ise `facing_yaw` ayarlanır.)
- [ ] Ölçek ve oran: boy, kafa/gövde oranı, Çınar ile fark.
- [ ] Siluet okunuyor mu? (Saç, atkı, palto siyah zeminde birbirine karışıyor mu?)
- [ ] Hareketler iskelete oturuyor mu? (Kemik adı uyuşmazlığı, bozuk eklem, kol/bacak uzaması)
- [ ] Ayak kayması: yürürken ayak zeminde kayıyor mu?
- [ ] Geçişler: yürüme → zıplama → düşme → iniş akıcı mı?
- [ ] Atkı, örgü, fener: sallanmıyorsa fizik gerekir (ayrı iş).
- [ ] Çocuk oranı: yetişkin hareketi çocuğa uyuyor mu?
- [ ] Performans: telefonda akıcı mı? (3D render ek yük)
- [ ] İki karakterli sahneler (sarılma, taşıma): 3D'de yapılamaz, ayrı çizim kalır.

Sonuçtan sonra karar veririz: 3D'ye geçmek mi, 2D'de kalıp ışık/zemin/ses iyileştirmeleri mi.
