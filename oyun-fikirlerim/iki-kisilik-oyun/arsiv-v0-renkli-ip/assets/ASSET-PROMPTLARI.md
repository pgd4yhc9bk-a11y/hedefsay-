# ChatGPT Görsel Promptları

## Önce bunu yapıştırın: Stil Kılavuzu
Her sohbetin başında bir kez verin; sonraki promptlar bunu referans alır.

```
Bir 2D mobil oyun için görsel üreteceksin. Tüm görseller şu stilde olmalı:
- Sıcak, el çizimi çocuk kitabı illüstrasyonu; yumuşak kalın dış hat (koyu kahve, ~4 px), düz renkler,
  hafif gölgelendirme, minimum doku.
- Canlı ama pastel paleti: [PALET: mercan #FF7A6B, nane #6FD6B5, krem #FFF3DC, gece mavisi #2B3A55, altın #FFC857].
- Karakterler yandan görünüm, yuvarlak ve sevimli, büyük gözler.
- Her zaman SADE ve OKUNAKLI: küçük ekranda tanınmalı.
Çıktı kuralları: arka plan şeffaf PNG (bölüm arka planları hariç), nesne ortalanmış, kenarlarda boşluk bırak,
metin/logo/imza ekleme. Her istekte TEK görsel üret. Aynı karakter her zaman aynı görünmeli.
```

> Palet ve tema (karakterler) kesinleşince `[PALET]` ve `[KARAKTER]` kısımlarını güncelleyin.

## Üretim sırası ve dosya adları
Her prompt: `Stil kılavuzuna uy. <aşağıdaki açıklama>. Şeffaf arka plan, tek görsel.`

### P0: Karakterler (yanlar sağa bakar; kod ters çevirir)
Karakter A: nane yeşili (#6FD6B5) tüylü yavru yaratık, krem göğüs/yüz/kuyruk ucu, büyük mavi gözler, yuvarlak kulaklar. Çizildi.
Karakter B: aynı türün mercan renkli (#FF7A6B), iri ve tıknaz kardeşi (A'dan yaklaşık 1,6 kat büyük), kalın kollu, daha küçük gözlü.
Üretim sırası: idle -> run1 -> run2 -> jump. Hazırlık: `python3 tools_sprite.py <kaynak> assets/<ad>.png`.
| Dosya | Açıklama |
|---|---|
| `char_a_idle.png` | Küçük karakter A, ayakta bekleme, 512x512 |
| `char_a_run1.png`, `char_a_run2.png` | Aynı karakter, koşu karesi 1 ve 2 |
| `char_a_jump.png` | Aynı karakter havada, zıplama pozu |
| `char_b_idle.png` | Büyük karakter B, ayakta, A'dan belirgin biçimde iri |
| `char_b_run1.png`, `char_b_run2.png`, `char_b_jump.png` | B'nin koşu ve zıplama pozları |

İpuçları: Önce `idle` üretin, diğer pozları "bu karakterin aynısı, şu pozda" diye aynı sohbette isteyin.
Animasyonu kodla (sallanma, ezilme-gerilme) yapacağım; çok kare gerekmez.

### P0: Dünya
| Dosya | Açıklama |
|---|---|
| `tile_ground.png` | Yatay döşenebilir zemin parçası, üstü çimenli, 256x256, sağ ve sol kenarı birleşir |
| `tile_dirt.png` | Zeminin altındaki dolgu, döşenebilir |
| `platform_float.png` | Havada duran küçük platform, 384x96 |
| `crate.png` | İtilebilir ahşap kutu, 192x192 |
| `button_off.png`, `button_on.png` | Yerdeki basınç düğmesi, kapalı ve basılı |
| `door_closed.png`, `door_open.png` | Bölüm çıkış kapısı |
| `key.png` | Altın anahtar, 128x128 |
| `spikes.png` | Zararsız görünümlü ama tehlikeli dikenler, 256x96 |
| `star.png` | Toplanabilir yıldız, 128x128 |

### P0: Arka planlar (şeffaf değil)
| Dosya | Açıklama |
|---|---|
| `bg_forest.png` | Yumuşak, düşük kontrastlı yatay manzara (uzak tepeler, bulutlar), 1920x1080, ön plandaki oyun nesnelerini bastırmayacak sakinlikte |
| `bg_cave.png` | Aynı stilde mağara/gece teması |

### P1: Arayüz
| Dosya | Açıklama |
|---|---|
| `ui_btn_jump.png` | Yuvarlak büyük zıplama düğmesi, ok simgeli, 256x256 |
| `ui_btn_action.png` | Yuvarlak yetenek düğmesi, 256x256 |
| `ui_btn_left.png`, `ui_btn_right.png` | Yön okları |
| `ui_logo.png` | Oyun adı için boş yuvarlak şerit, içi boş (adı kodla yazarım) |
| `ui_heart.png`, `ui_check.png` | Küçük simgeler, 128x128 |

### P1: İp
| Dosya | Açıklama |
|---|---|
| `rope_segment.png` | Tekrarlanabilir kalın ip parçası, 64x32, uçları birleşir |

## Kalite kontrol listesi (görseli kaydetmeden önce)
- [ ] Arka plan gerçekten şeffaf (kareli görünüyor)?
- [ ] Karakter önceki pozlarla aynı mı (renk, oran, yüz)?
- [ ] Döşenebilir parçaların kenarı birbirine uyuyor mu?
- [ ] Yazı/imza yok mu?
- [ ] Küçük (64 px) görünce hâlâ okunuyor mu?

Sorun çıkarsa görseli bana gönderin, kodda düzeltebileceğim şeyi (boyut, renk tonu) ben çözerim.
