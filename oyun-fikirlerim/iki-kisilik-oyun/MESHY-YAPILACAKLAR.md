# Meshy'de yapılacaklar (önsöz ve sonrası)

Öncelik sırasıyla. ⭐ olanlar önsözü en çok güzelleştirenler.

**Gönderirken:**
- **Animasyonlar:** Mutlaka aynı karakterin üstüne ekle (Nehir'e Nehir'in, Çınar'a Çınar'ın). Böylece iskelet aynı kalır. İndirirken GLB, "All Animations" seç; 25 MB'ı geçerse önceki gibi parçalı zip olabilir.
- **Metinden hareket:** Bu animasyonlar kodlu isimle (`_01a19…`) geliyor. Gönderirken sırayı yazman yeterli, ör. "1. uzanma, 2. kayma".
- **Komutlar:** Meshy'ye İngilizce yapıştır.

---

## 0) ŞİMDİ GEREKENLER: çark ve halat (Nehir, Text to Motion) ⭐⭐

| # | Ne için | Komut |
|---|---|---|
| A | Çarkı çevirme (yerinde, döngü) | `A girl stands facing a large vertical wheel at chest height on her side, grips its handle with both hands and turns it in big clockwise circles with effort, feet planted, leaning into each turn. Looping, in place.` |
| B | Sandalda halat çekme (yerinde, döngü) | `A girl stands in a small boat, gripping a horizontal rope at chest height in front of her, pulling it hand over hand toward her body with effort, alternating hands, feet planted. Looping, in place.` |

| C | Asansörde zincir çekme (yerinde, döngü) | `A girl stands on a wooden platform, reaches up above her head, grabs a hanging vertical chain and pulls it down hand over hand to her chest, alternating hands with effort, feet planted. Looping, in place.` |

Gönderirken hangisinin A, hangisinin B olduğunu yaz. (A ve B oyunda; C için yer hazır: gelince asansörde otomatik oynar.) Oyunda yerleri hazır: gelince çark başında ve sandalda otomatik oynar.

## 1) Nehir: animasyonlar (Text to Motion)

| # | Ne için | Komut |
|---|---|---|
| ⭐1 | Önsöz: çividen feneri alma | `A girl stands, reaches up with her left hand to a hook at head height, lifts an object off it and brings it down in front of her chest, looking at it.` |
| ⭐2 | Önsöz: kapıda endişeyle bakma | `A girl stands in a doorway, one hand resting on the door frame, leaning slightly forward, anxiously looking far into the distance, breathing nervously.` |
| ⭐3 | Önsöz: yamaçta kayıp düşme | `A girl walking carefully on a slippery snowy slope suddenly slips, loses balance, falls sideways and tumbles down, ending lying still on the ground.` |
| 4 | Oyun: fenerle temkinli yürüyüş | `A girl walks slowly and cautiously, holding a lantern forward in her right hand, looking around nervously.` |
| 5 | Oyun: feneri havaya kaldırma (ileride Çınar'ı arama) | `A girl raises a lantern high above her head with her right hand and looks around, searching.` |
| 6 | Oyun: soğuktan titreme (beklerken) | `A girl stands still shivering from cold, rubbing her arms, shoulders hunched.` |

## 2) Çınar: animasyonlar (Text to Motion)

| # | Ne için | Komut |
|---|---|---|
| ⭐1 | Önsöz: tavşanı göğsüne bastırma | `A small boy stands hugging a plush toy tightly against his chest with both arms, swaying slightly.` |
| ⭐2 | Önsöz: rüzgâr tavşanı kapınca uzanma | `A small boy is startled as something is blown out of his hands; he quickly reaches out with one arm toward it, leaning forward.` |
| ⭐3 | Önsöz: peşinden koşma | `A small boy runs forward urgently, one arm reaching out in front of him as if chasing something.` |
| 4 | Önsöz/oyun: yerden tavşanı alma | `A small boy crouches down, picks up a toy from the ground and hugs it to his chest.` |
| 5 | Oyun: korkuyla çömelme (karanlık) | `A small scared boy crouches down, covering his head with his arms, trembling.` |
| 6 | Oyun: ağlama | `A small boy stands crying, wiping his eyes with his sleeve, shoulders shaking.` |

## 3) Anne: yeni karakter ⭐

**Model (Text to 3D, sonra Rig):**
```
A woman in her late thirties from a poor mountain village in the past, slim, tired gentle face, dark hair in a low bun, long dark grey wool dress, thick knitted beige shawl over her shoulders, dark boots. Realistic stylized proportions, T-pose, full body, game character.
```
Nehir ve Çınar'la aynı tarzda olsun (onların referans görselini de verebilirsin: `flow/referans/nehir_uc_ceyrek.png`).

**Animasyonları (Text to Motion):**
| # | Ne için | Komut |
|---|---|---|
| ⭐1 | Kapıda bekleyiş | `A woman stands in a doorway, holding her shawl closed with one hand, the other hand on her chest, worried, looking into the distance.` |
| 2 | Kızının atkısını sarma | `A woman leans down and wraps a scarf around a child's neck with both hands, gently.` |
| 3 | Final: çocuklarına sarılma | `A woman kneels down and hugs two children tightly, her head bowed, crying softly.` |

## 4) Nesneler (Text to 3D, rig gerekmez)

| # | Ne | Komut |
|---|---|---|
| ⭐1 | Köy evi | `A small old wooden village cottage, dark weathered logs, steep snowy roof, one small square window, a simple wooden door on the side, a stone chimney, winter, realistic stylized, game asset.` |
| 2 | Fener | `An old black iron cage lantern with a ring handle on top, glass panes, small candle inside, worn and rusty, realistic, game asset.` |
| 3 | Baba feneri (ileride, köy yolu) | `A large old rusty iron street lantern hanging from a wooden post with a hook, broken glass pane, abandoned, realistic, game asset.` |
| 4 | Ağaç kütüğü (Çınar'ın oturduğu) | `An old cut tree stump with rough bark and visible rings on top, covered with a little snow, realistic, game asset.` |

---

**En azından şu ⭐ olanlar yeter:** Nehir 1–3, Çınar 1–3, anne modeli ve kapıda bekleyiş, köy evi. Gelince hepsini önsöze yerleştiririm; gelmeyenler için şimdiki çözümler kalır.

---

# İLERİDEKİ BÖLÜMLER İÇİN ANİMASYON LİSTESİ (Motion Prime, 3-4 sn)

**Nasıl:** Her birini doğru karaktere "Karaktere ekle". **Ad** kutusuna tablodaki kodu yaz (ör. `N2`). İstediğin kadarını yap, sonra tek GLB ("All Animations") olarak Drive'dan gönder.
"Döngü" yazanlarda komutun sonunda `Looping, in place.` var: oyunda sürekli tekrar eder.

## Nehir
| Kod | Nerede | Komut |
|---|---|---|
| N1 | Asansör (C ile aynı) | `A girl stands on a wooden platform, reaches up above her head, grabs a hanging vertical chain and pulls it down hand over hand to her chest, alternating hands with effort, feet planted. Looping, in place.` |
| N2 | Dere: buzda kayma | `A girl walking on slippery ice suddenly slides, arms flailing wide to keep her balance, knees bent, wobbles and recovers. In place.` |
| N3 | Orman: çamurda yürüme | `A girl walks slowly through deep mud, lifting each foot with effort, knees bent, leaning forward. Looping, in place.` |
| N4 | Mağara: feneri kaldırıp arama | `A girl holds a lantern high above her head with her right hand and slowly looks left and right, searching in the dark. Looping, in place.` |
| N5 | Değirmen: kaldıraç çekme | `A girl grabs a tall lever at shoulder height with both hands and pulls it down hard with her whole body weight. In place.` |
| N6 | Yamaç: halata tırmanma | `A girl climbs a vertical rope hand over hand, feet gripping the rope, with effort. Looping, in place.` |
| N7 | Yamaç: kenardan uzanıp yakalama | `A girl lies on her stomach at the edge of a cliff and reaches down with both arms to grab someone's hand, then pulls back with effort.` |
| N8 | Kardeşini sırtına alma | `A girl crouches down so a small child can climb onto her back, then stands up carrying him piggyback.` |
| N9 | Sırtında çocukla yürüme | `A girl walks slowly carrying a small child piggyback on her back, arms holding his legs. Looping, in place.` |
| N10 | El ele yürüme | `A girl walks slowly holding a small child's hand with her left hand, arm stretched down to her side, glancing at him. Looping, in place.` |
| N11 | Kurdele bağlama (kontrol noktası) | `A girl reaches up to a low tree branch and ties a ribbon around it with both hands, then steps back.` |
| N12 | Soğuktan titreme (bekleme) | `A girl stands still shivering from cold, rubbing her arms, shoulders hunched. Looping, in place.` |
| N13 | Final: ağlama | `A girl kneels down and cries, covering her face with her hands, shoulders shaking.` |

## Çınar
| Kod | Nerede | Komut |
|---|---|---|
| Ç1 | Ablasını takip: yürüme | `A small boy walks timidly behind someone, hugging a plush toy to his chest with one arm. Looping, in place.` |
| Ç2 | Karanlıkta korku | `A small scared boy crouches down, covering his head with his arms, trembling. Looping, in place.` |
| Ç3 | Ağlama | `A small boy stands crying, wiping his eyes with his sleeve, shoulders shaking. Looping, in place.` |
| Ç4 | Dar geçitte sürünme | `A small boy crawls forward on his hands and knees through a low tunnel. Looping, in place.` |
| Ç5 | El ele yürüme | `A small boy walks holding someone's hand with his right hand raised up beside him, looking up. Looping, in place.` |
| Ç6 | Düğmeye/kola basma | `A small boy pulls a small lever down with both hands, using his whole body weight.` |
| Ç7 | Sırtta taşınma (poz) | `A small boy rides piggyback, arms wrapped around someone's neck, legs to the sides, resting his head. Looping, in place.` |
| Ç8 | Tavşana uzanma (yamaç) | `A small boy lies at the edge of a cliff reaching down desperately with one arm toward something falling.` |
| Ç9 | Yorgun, nefes nefese | `A small tired boy stands bent forward, hands on his knees, breathing heavily. Looping, in place.` |
| Ç10 | Sevinçle zıplama | `A small boy jumps up and down happily, clapping his hands. Looping, in place.` |

**Öncelik:** N1 (asansör), N4, N5, N10, Ç1, Ç2, Ç5 — bunlar sonraki bölümlerde hemen kullanılır.
Hepsi Motion Prime ile yaklaşık 23 × 10 = 230 kredi.
