# Kayıp Katlar — Görsel ve Model İstemleri

ChatGPT ile 2D çizim, ardından Meshy AI ile 3D model için hazır istemler. Toplam 56 istem.

## Kullanım

1. Önce **Stil denemesi** istemini ChatGPT'ye ver. Beğenene kadar yeniden üret.
2. Diğer istemlerin hepsi aynı stil cümlesiyle başlar; sırayla çizdir.
3. **Kıyafet setleri** için ChatGPT'ye önce temel karakter görselini ekle, sonra istemi yapıştır.
4. Meshy'de *Image to 3D* (mümkünse çoklu görsel) ile model çıkar; karakterler için üçgen sayısını ~5.000'e indir, otomatik rig ve `idle`, `walk`, `attack`, `cast`, `hit`, `death` animasyonlarını ekle.
5. GLB olarak dışa aktar ve repoda `katlar/modeller/` klasörüne koy. Ayrıntılar: [KATLAR_TASARIM.md §11A](KATLAR_TASARIM.md).

Not: ChatGPT ve Meshy çıktılarının ticari kullanım şartlarını kendi planın için kontrol et. İstemlere var olan oyun, karakter veya sanatçı adı ekleme.

## Stil denemesi

Önce bunu çizdir. Beğendiğin görseli sakla; sonraki tüm istemler aynı stil cümlesiyle başlıyor, böylece hepsi aynı oyundan çıkmış gibi durur.

### Stil örneği: savaşçı  
_Stil tutarsa bu görsel Savaşçı'nın temel görseli de olur._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A young warrior in a dark red cloth tunic with steel shoulder plates and a steel chest plate, brown leather belt and boots, short dark brown hair, determined face. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

## Oyuncu sınıfları

Kıyafet setleri bu temel karakterlerin üstüne giydirilecek. Kadın sürümler isteğe bağlı.

### Savaşçı (erkek)  
_Kılıç ve kalkan ayrı çizilecek._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A young male warrior in a dark red cloth tunic with steel shoulder plates and a steel chest plate, brown leather belt and boots, short dark brown hair, determined face. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

### Savaşçı (kadın)  
_İsteğe bağlı._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A young female warrior in a dark red cloth tunic with steel shoulder plates and a steel chest plate, brown leather belt and boots, dark brown hair in a short braid, determined face. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

### Okçu (erkek)  
_Yay ayrı çizilecek. Sadağı karakterin parçası olabilir._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A nimble male archer in a moss green leather jacket with a brown leather chest piece, dark green hooded cape with the hood up, leather bracers, auburn hair visible under the hood, a small quiver on the back. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

### Okçu (kadın)  
_İsteğe bağlı._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A nimble female archer in a moss green leather jacket with a brown leather chest piece, dark green hooded cape with the hood up, leather bracers, long auburn hair visible under the hood, a small quiver on the back. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

### Büyücü (erkek)  
_Asa ayrı çizilecek._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. An old male wizard in a long deep blue robe with gold trim, tall pointed dark blue hat with a wide brim, grey-white hair and a short beard, pale leather boots. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

### Büyücü (kadın)  
_İsteğe bağlı._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A young female wizard in a long deep blue robe with gold trim, tall pointed dark blue hat with a wide brim, silver-white long hair, pale leather boots. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

## Silahlar

Her sınıf için 3 kademe: seviye 1–10, 10–20, 20–30. Meshy'de ayrı model yapılır, oyunda karakterin eline takılır.

### Paslı Kılıç  
_Savaşçı, kademe 1._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A short rusty iron sword with a simple crossguard and a leather-wrapped grip. Single weapon game prop lying flat, shown from the front and from the side, handle at the bottom, plain pure white background, even lighting, no cast shadows, no hands, no text.
```

### Demir Kılıç  
_Savaşçı, kademe 2._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A clean steel longsword with a bronze crossguard and a round pommel. Single weapon game prop lying flat, shown from the front and from the side, handle at the bottom, plain pure white background, even lighting, no cast shadows, no hands, no text.
```

### Kök Kılıcı  
_Savaşçı, kademe 3._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A fantasy sword with a blade of polished dark steel and a guard made of twisted living tree roots, faint teal glow along the edge. Single weapon game prop lying flat, shown from the front and from the side, handle at the bottom, plain pure white background, even lighting, no cast shadows, no hands, no text.
```

### Kalkan  
_Savaşçının sol kolu._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A round wooden shield with an iron rim and an iron center boss, painted dark red. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Kısa Yay  
_Okçu, kademe 1._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A simple short wooden bow with a leather grip and a plain string. Single weapon game prop lying flat, shown from the front and from the side, handle at the bottom, plain pure white background, even lighting, no cast shadows, no hands, no text.
```

### Avcı Yayı  
_Okçu, kademe 2._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A recurve hunting bow of dark wood with bone tips and a green leather grip. Single weapon game prop lying flat, shown from the front and from the side, handle at the bottom, plain pure white background, even lighting, no cast shadows, no hands, no text.
```

### Kök Yayı  
_Okçu, kademe 3._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A longbow grown from twisted living roots with small leaves, faint teal glow along the limbs. Single weapon game prop lying flat, shown from the front and from the side, handle at the bottom, plain pure white background, even lighting, no cast shadows, no hands, no text.
```

### Ok  
_Mermi modeli._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A single arrow with a steel head and white feather fletching. Single weapon game prop lying flat, shown from the front and from the side, handle at the bottom, plain pure white background, even lighting, no cast shadows, no hands, no text.
```

### Çıra Asası  
_Büyücü, kademe 1._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A gnarled wooden staff with a small glowing ember stone held in its top. Single weapon game prop lying flat, shown from the front and from the side, handle at the bottom, plain pure white background, even lighting, no cast shadows, no hands, no text.
```

### Bakır Asa  
_Büyücü, kademe 2._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A straight staff with copper bands and a copper cage on top holding a glowing blue crystal. Single weapon game prop lying flat, shown from the front and from the side, handle at the bottom, plain pure white background, even lighting, no cast shadows, no hands, no text.
```

### Kök Asası  
_Büyücü, kademe 3._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A staff made of twisted roots holding a large glowing teal orb at the top, small leaves around it. Single weapon game prop lying flat, shown from the front and from the side, handle at the bottom, plain pure white background, even lighting, no cast shadows, no hands, no text.
```

## Düşmanlar

Zindan ve açık bölge düşmanları.

### Fare  
_Dört ayaklı. Saldırısı ileri atılma._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A giant dungeon rat the size of a dog, grey-brown fur, glowing red eyes, pink tail and ears, hunched aggressive pose. Creature turnaround sheet: full body, neutral standing pose, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Muhafız  
_Kalkanı ve kılıcı modelin parçası olabilir._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A heavily armored dungeon guard, dark steel plate armor with rust patches, full helmet with a red plume and a narrow visor slit, round wooden shield with an iron rim on the left arm, short sword in the right hand. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, holding its own weapons.
```

### Okçu (düşman)  
_Yay modelin parçası olabilir._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A hooded bandit archer, olive green and dark brown ragged clothes, face hidden in shadow under the hood with two faint glowing eyes, tattered short cape, holding a short bow. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, holding its own bow.
```

### Hazine Goblini  
_Kaçan, yakalanınca çok ödül veren düşman._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A small greedy goblin with green skin and big pointy ears, wearing a golden-yellow vest, carrying a huge bulging brown sack of gold coins on its back, sneaky grin. Creature turnaround sheet: full body, neutral standing pose, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

## Bekçiler (boss)

Her bölgenin 10. ve 20. katında, açık bölgede Ejder Mağarası'nda. Göğüsteki parlayan çekirdek oyunda atıyor.

### Kül Bekçisi  
_Kül Mahzeni._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A massive stone golem made of dark charcoal rock, glowing orange ember core in the chest and thin orange cracks across the body, small head with two bone horns, huge stone fists. Creature turnaround sheet: full body, neutral standing pose, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Pas Golemi  
_Paslı Atölye._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A massive golem made of rusted iron plates and copper pipes, gears visible at the joints, glowing amber core in the chest, small steam vents on the shoulders, huge fists. Creature turnaround sheet: full body, neutral standing pose, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Kök Devi  
_Kök Labirenti._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A massive golem made of twisted tree roots and mossy stones, glowing teal-green core in the chest, small glowing mushrooms growing on the shoulders, huge root fists. Creature turnaround sheet: full body, neutral standing pose, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Ejder Mağarası bekçisi  
_Açık bölgenin en zor odası._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A massive obsidian golem with dragon-like horns and a spiked back, glowing red-orange magma core in the chest and magma cracks across the body, huge fists. Creature turnaround sheet: full body, neutral standing pose, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

## Kıyafet setleri

Gerçek parayla satılacak görünümler. ChatGPT'ye önce temel karakter görselini ekle, sonra bu istemi yaz. Böylece gövde oranı aynı kalır ve kıyafet her karaktere uyar.

### Kraliyet Kıyafeti  
_Sadece o ayın kralı giyer._

```
Use the attached image as the base character. Keep exactly the same body proportions, face, pose and art style, and only change the clothes. Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. New outfit: royal king attire, deep crimson robe with gold embroidery, gold crown with a red gem, long red cape with white fur trim. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

### Muhafız Zırhı  
_Kraliyet Muhafızları._

```
Use the attached image as the base character. Keep exactly the same body proportions, face, pose and art style, and only change the clothes. Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. New outfit: royal guard armor, polished steel plate with a blue-grey tint, helmet with a red plume, crimson cape. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

### Kızıl Ejder Seti

```
Use the attached image as the base character. Keep exactly the same body proportions, face, pose and art style, and only change the clothes. Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. New outfit: red dragon set, crimson scale armor with dragon-horn shoulder pieces, small horns on a pointed hat, black cape. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

### Gece Pelerini

```
Use the attached image as the base character. Keep exactly the same body proportions, face, pose and art style, and only change the clothes. Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. New outfit: night cloak set, dark indigo clothes with silver star-like embroidery, long black cloak. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

### Kül Gezgini

```
Use the attached image as the base character. Keep exactly the same body proportions, face, pose and art style, and only change the clothes. Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. New outfit: ash wanderer set, worn grey and beige travelling clothes, a scarf around the neck, dusty brown cloak. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

### Orman Avcısı

```
Use the attached image as the base character. Keep exactly the same body proportions, face, pose and art style, and only change the clothes. Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. New outfit: forest hunter set, green and light green leather clothes, leaf-shaped shoulder pieces, pointed green hat. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

### Kristal Cübbe

```
Use the attached image as the base character. Keep exactly the same body proportions, face, pose and art style, and only change the clothes. Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. New outfit: crystal robe, light blue robe with ice crystal shards on the shoulders, faintly glowing blue trim. Character turnaround sheet: full body, A-pose with arms slightly away from the body, front view, side view and back view side by side at the same scale, plain pure white background, even studio lighting, no cast shadows, no text, no watermark, empty hands.
```

## Kasaba yapıları

Meydandaki yapılar. Büyük yapılarda üçgen sınırı daha esnek.

### Demirci evi

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A small medieval blacksmith workshop, timber frame with cream plaster walls, dark red tiled pyramid roof, stone chimney, open front with a stone forge glowing orange and an iron anvil. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Pazar tezgâhı  
_Kırmızı ve mavi iki renk sürümü çizdirebilirsin._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A medieval market stall with wooden posts and a red-and-cream striped awning, wooden table with apples, potion bottles and a sword on display. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Taht

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A royal throne on three stone steps, tall gold-trimmed back with crown-shaped spikes, red velvet cushion, a red gem on top. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Kral heykeli  
_Her ay kralın kıyafetine göre yenilenebilir._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A stone statue of a crowned king holding a sword raised to the sky and a round shield, standing on an octagonal stone pedestal with a gold plaque. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Sefer Kapısı

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. An ancient stone archway with runes carved on the pillars and a swirling blue-violet magic portal inside. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Klan Panosu

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A wooden notice board on two posts with a small red-tiled roof, pinned papers and two small clan banners. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Fener

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A wrought iron street lantern on a tall post with a warm yellow glowing light. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Sur duvarı parçası  
_Tekrarlanarak dizilir._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A modular castle wall segment of grey stone blocks with crenellations on top, and a hanging red banner with a gold crown emblem. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

## Zindan ve açık bölge dekorları

Küçük ve çok tekrar eden parçalar; üçgen sayısını düşük tut.

### Meşale

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A wall torch with an iron holder and a burning flame. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Fıçı ve sandık

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A wooden barrel with iron bands and a wooden crate with dark straps, side by side. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Kemik yığını  
_Kül Mahzeni._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A small pile of old bones with a skull on top. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Dişli ve borular  
_Paslı Atölye._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A large rusty iron gear mounted on a wall bracket with copper pipes running beside it. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Parlayan mantarlar  
_Kök Labirenti._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A cluster of three mushrooms with pale stems and glowing teal caps. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

### Kamp ateşi ve çadır  
_Açık bölgedeki Kamp._

```
Stylized low-poly fantasy game asset for a mobile 2.5D action RPG, chunky slightly heroic proportions (head about one fifth of body height), hand-painted flat colors with soft gradients, clean readable silhouette, warm ember and ash color palette. A campfire with logs and a ring of stones, next to a small canvas tent. Single game prop, three-quarter view and front view side by side, plain pure white background, even studio lighting, no cast shadows, no text, no watermark.
```

## Eşya simgeleri (2D)

Envanter ve demirci ekranı için. Bunlar 3D değil, doğrudan oyunda kullanılır.

### Kılıç simgesi

```
Square game inventory icon, single object centered with a little padding, stylized hand-painted, bold readable shape, subtle rim light, plain dark charcoal background, no text, no border. A steel longsword with a bronze crossguard.
```

### Yay simgesi

```
Square game inventory icon, single object centered with a little padding, stylized hand-painted, bold readable shape, subtle rim light, plain dark charcoal background, no text, no border. A recurve bow of dark wood with a green grip.
```

### Asa simgesi

```
Square game inventory icon, single object centered with a little padding, stylized hand-painted, bold readable shape, subtle rim light, plain dark charcoal background, no text, no border. A wooden staff with a glowing blue crystal on top.
```

### Zırh simgesi

```
Square game inventory icon, single object centered with a little padding, stylized hand-painted, bold readable shape, subtle rim light, plain dark charcoal background, no text, no border. A steel chest plate with leather straps.
```

### Yüzük simgesi

```
Square game inventory icon, single object centered with a little padding, stylized hand-painted, bold readable shape, subtle rim light, plain dark charcoal background, no text, no border. A gold ring with a red gemstone.
```

### Kolye simgesi

```
Square game inventory icon, single object centered with a little padding, stylized hand-painted, bold readable shape, subtle rim light, plain dark charcoal background, no text, no border. A silver necklace with a teardrop blue gem pendant.
```

### Basma Taşı simgesi

```
Square game inventory icon, single object centered with a little padding, stylized hand-painted, bold readable shape, subtle rim light, plain dark charcoal background, no text, no border. A rough grey whetstone with faint glowing runes.
```

### Kor Tozu simgesi

```
Square game inventory icon, single object centered with a little padding, stylized hand-painted, bold readable shape, subtle rim light, plain dark charcoal background, no text, no border. A small leather pouch spilling glowing orange ember dust.
```

### Altın simgesi

```
Square game inventory icon, single object centered with a little padding, stylized hand-painted, bold readable shape, subtle rim light, plain dark charcoal background, no text, no border. A small stack of gold coins.
```
