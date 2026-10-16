// Kelime ve işlem turu oynatıcıları. Süre bitince / "Bitir" ile / işlemde tam isabette onBitir bir kez çağrılır.
import React, { useCallback, useEffect, useRef, useState } from "react";
import { Platform, Text, TextInput, View } from "react-native";
import H from "./cekirdek";
import { FONT } from "./tema";
import { Bildirim, Dugme, Ekran, Halkalar, Karo, Kart, Metin, SayacCubugu, Sira, up, useGeriSayim, useTema, Yazi } from "./ui";

export interface KelimeSonuc { word: string; score: number }
export interface IslemSonuc { value: number; fark: number; puan: number; expr: string }

interface Ortak { sureSn: number; kalanSn?: number; ust?: React.ReactNode }

export function KelimeTuru({ harfler, sureSn, kalanSn, ust, onBitir }: Ortak & { harfler: string[]; onBitir: (s: KelimeSonuc | null) => void }) {
  const t = useTema();
  const [giris, setGiris] = useState<{ ch: string; joker: boolean }[]>([]);
  const [enIyi, setEnIyi] = useState<KelimeSonuc | null>(null);
  const [mesaj, setMesaj] = useState<{ m: string; iyi: boolean }>({ m: "", iyi: false });
  const [secici, setSecici] = useState(false);
  const bittiMi = useRef(false);
  const enIyiRef = useRef<KelimeSonuc | null>(null); enIyiRef.current = enIyi;

  const bitir = useCallback(() => {
    if (bittiMi.current) return;
    bittiMi.current = true;
    onBitir(enIyiRef.current);
  }, [onBitir]);
  const { kalanMs } = useGeriSayim(sureSn, kalanSn, bitir);

  // giris'in güncel değerini ref'te de tutuyoruz: olay işleyicileri ve klavye dinleyicisi eski kapanışı görmesin,
  // state güncelleyicilerinin içinde yan etki de olmasın.
  const girisRef = useRef(giris); girisRef.current = giris;
  const kullanim = (g = giris) => {
    const k = harfler.map(() => false); let joker = false;
    for (const x of g) {
      if (x.joker) { joker = true; continue; }
      const i = harfler.findIndex((h, j) => !k[j] && h === x.ch);
      if (i >= 0) k[i] = true;
    }
    return { k, joker };
  };
  const guncelle = (yeni: { ch: string; joker: boolean }[]) => { girisRef.current = yeni; setGiris(yeni); };
  const ekle = useCallback((ch: string) => {
    const g = girisRef.current;
    if (g.length >= H.HARF_SAYISI + 1) return;
    const { k, joker } = kullanim(g);
    const serbest = harfler.some((h, i) => !k[i] && h === ch);
    if (serbest) { setMesaj({ m: "", iyi: false }); guncelle([...g, { ch, joker: false }]); }
    else if (!joker) { setMesaj({ m: "", iyi: false }); guncelle([...g, { ch, joker: true }]); }
    else setMesaj({ m: "Bu harf kalmadı", iyi: false });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [harfler]);
  const sil = useCallback(() => { guncelle(girisRef.current.slice(0, -1)); setMesaj({ m: "", iyi: false }); }, []);
  const gonder = useCallback(() => {
    const kelime = girisRef.current.map((x) => x.ch).join("");
    if (!kelime) return;
    const b = H.wordInfo(kelime, harfler);
    guncelle([]);
    if (!b.valid) { setMesaj({ m: `“${up(kelime)}” — ${b.reason}`, iyi: false }); return; }
    if (!enIyiRef.current || b.score > enIyiRef.current.score) { enIyiRef.current = { word: b.word, score: b.score }; setEnIyi(enIyiRef.current); }
    setMesaj({ m: `“${up(b.word)}” geçerli: ${b.score} puan`, iyi: true });
  }, [harfler]);

  // Masaüstü tarayıcıda fiziksel klavye
  useEffect(() => {
    if (Platform.OS !== "web") return;
    const f = (e: KeyboardEvent) => {
      if (secici || e.ctrlKey || e.metaKey || e.altKey) return;
      if (e.key === "Enter") { e.preventDefault(); gonder(); }
      else if (e.key === "Backspace") sil();
      else if (e.key.length === 1) { const ch = H.trLower(e.key); if (H.ALFABE.indexOf(ch) >= 0) ekle(ch); }
    };
    document.addEventListener("keydown", f);
    return () => document.removeEventListener("keydown", f);
  }, [secici, ekle, gonder, sil]);

  const { k, joker } = kullanim();
  return (
    <Ekran ust={ust}
      alt={<>
        <Sira bosluk={10} stil={{ flexWrap: "nowrap" }}>
          <Dugme testID="sil" baslik="⌫" onPress={sil} />
          <Dugme testID="gonder" birincil buyuk esnek baslik="Gönder" onPress={gonder} />
        </Sira>
        <Dugme testID="bitir" hayalet baslik="Turu bitir" onPress={bitir} />
      </>}>
      <SayacCubugu kalanMs={kalanMs} sureSn={sureSn} />
      <View style={{ alignItems: "center", marginBottom: 10 }}>
        <Text testID="enIyi" style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 14 }}>
          {enIyi ? `En iyin: ${up(enIyi.word)} · ${enIyi.score} puan` : "Henüz geçerli kelime yok"}
        </Text>
      </View>
      <View style={{ minHeight: 64, alignItems: "center", justifyContent: "center", marginBottom: 4 }}>
        {giris.length === 0
          ? <Text style={{ color: t.soluk, fontFamily: FONT.orta, fontSize: 16 }}>Harflere dokunarak kelimeni kur</Text>
          : <Sira ortala bosluk={5}>{giris.map((g, i) => <Karo key={i} boyut="o" harf={g.ch} joker={g.joker} pop />)}</Sira>}
      </View>
      <View style={{ flex: 1, minHeight: 8 }} />
      <Bildirim metin={mesaj.m} iyi={mesaj.iyi} testID="mesaj" />
      <View style={{ height: 8 }} />
      <Sira ortala bosluk={10}>
        {harfler.map((h, i) => <Karo key={i} testID={`harf-${h}`} harf={h} kullanildi={k[i]} onPress={() => ekle(h)} />)}
        <Karo testID="joker" joker kullanildi={joker} onPress={() => setSecici(true)} />
      </Sira>
      {secici && (
        <Kart stil={{ marginTop: 18 }}>
          <Metin v="baslik" stil={{ marginBottom: 10 }}>Joker hangi harf olsun?</Metin>
          <Sira bosluk={6} ortala>
            {H.ALFABE.split("").map((c) => <Karo key={c} testID={`joker-${c}`} boyut="k" harf={c} onPress={() => { setSecici(false); guncelle([...girisRef.current, { ch: c, joker: true }]); }} />)}
          </Sira>
          <View style={{ height: 10 }} />
          <Dugme baslik="Vazgeç" onPress={() => setSecici(false)} />
        </Kart>
      )}
    </Ekran>
  );
}

const OPERATORLER = ["+", "−", "×", "÷", "(", ")"];

export function IslemTuru({ sayilar, hedef, sureSn, kalanSn, bonus, ust, onBitir }:
  Ortak & { sayilar: number[]; hedef: number; bonus: boolean; onBitir: (s: IslemSonuc | null) => void }) {
  const t = useTema();
  const [ifade, setIfade] = useState("");
  const [enIyi, setEnIyi] = useState<IslemSonuc | null>(null);
  const [mesaj, setMesaj] = useState<{ m: string; iyi: boolean }>({ m: "", iyi: false });
  const bittiMi = useRef(false);
  const enIyiRef = useRef<IslemSonuc | null>(null); enIyiRef.current = enIyi;

  const bitir = useCallback(() => {
    if (bittiMi.current) return;
    bittiMi.current = true;
    onBitir(enIyiRef.current);
  }, [onBitir]);
  const { kalanMs, kalanSn: kalanSnFn } = useGeriSayim(sureSn, kalanSn, bitir);

  const kullan: Record<string, number> = {};
  (ifade.match(/\d+/g) ?? []).forEach((x) => { kullan[x] = (kullan[x] ?? 0) + 1; });

  const gonder = () => {
    const r = H.evaluate(ifade, sayilar);
    if (!r.ok) { setMesaj({ m: r.error ?? "Geçersiz", iyi: false }); return; }
    const value = r.value as number, fark = Math.abs(hedef - value);
    const b = fark === 0 && bonus ? H.timeBonus(kalanSnFn()) : 0;
    const puan = H.numberScore(hedef, value) + b;
    setMesaj({ m: `= ${value}${fark ? ` (fark ${fark})` : " — tam isabet!"} · ${puan} puan${b ? ` (süre bonusu +${b})` : ""}`, iyi: puan > 0 });
    const yeni = { value, fark, puan, expr: ifade };
    if (!enIyiRef.current || fark < enIyiRef.current.fark || (fark === enIyiRef.current.fark && puan > enIyiRef.current.puan)) { enIyiRef.current = yeni; setEnIyi(yeni); }
    if (fark === 0) bitir();
  };

  const gonderRef = useRef(gonder); gonderRef.current = gonder;
  useEffect(() => {
    if (Platform.OS !== "web") return;
    const f = (e: KeyboardEvent) => { if (e.key === "Enter") { e.preventDefault(); gonderRef.current(); } };
    document.addEventListener("keydown", f);
    return () => document.removeEventListener("keydown", f);
  }, []);

  const kalanSayac: Record<string, number> = { ...kullan };
  return (
    <Ekran ust={ust}
      alt={<>
        <Sira bosluk={10} stil={{ flexWrap: "nowrap" }}>
          <Dugme testID="sil" baslik="⌫" onPress={() => setIfade((s) => s.slice(0, -1))} />
          <Dugme testID="gonder" birincil buyuk esnek baslik="Gönder" onPress={gonder} />
        </Sira>
        <Dugme testID="bitir" hayalet baslik="Turu bitir" onPress={bitir} />
      </>}>
      <SayacCubugu kalanMs={kalanMs} sureSn={sureSn} />
      <View style={{ alignItems: "center", justifyContent: "center", height: 170 }}>
        <Halkalar boyut={170} adet={4} mutlak />
        <Text style={{ position: "absolute", top: 18, color: t.soluk, fontFamily: FONT.kalin, fontSize: 12, letterSpacing: 2 }}>HEDEF</Text>
        <Text testID="hedef" style={{ fontFamily: FONT.siyah, fontSize: 68, color: t.vurguMetin }}>{hedef}</Text>
      </View>
      <View style={{ flex: 1, minHeight: 10 }} />
      <Sira ortala bosluk={6}>
        {sayilar.map((n, i) => {
          const kk = String(n); const kullanildi = (kalanSayac[kk] ?? 0) > 0;
          if (kullanildi) kalanSayac[kk]--;
          return <Karo key={i} testID={`sayi-${n}`} boyut="o" harf={String(n)} kullanildi={kullanildi} onPress={() => setIfade((s) => s + n)} />;
        })}
      </Sira>
      <View style={{ height: 14 }} />
      <TextInput testID="ifade" value={ifade} onChangeText={setIfade} placeholder="(7+3)×8−5" placeholderTextColor={t.soluk}
        autoCapitalize="none" autoCorrect={false} onSubmitEditing={gonder} inputMode="none" showSoftInputOnFocus={false}
        style={{ color: t.yazi, backgroundColor: t.yuzey2, borderColor: t.cizgi, borderWidth: 1, borderRadius: 16, height: 62, fontSize: 28, textAlign: "center", fontFamily: FONT.kalin }} />
      <Bildirim metin={mesaj.m} iyi={mesaj.iyi} testID="mesaj" />
      <Sira ortala bosluk={8}>
        {OPERATORLER.map((o) => (
          <View key={o} style={{ width: 48 }}><Dugme testID={`op-${o}`} baslik={o} onPress={() => setIfade((s) => s + o)} /></View>
        ))}
      </Sira>
      <Text testID="enIyi" style={{ textAlign: "center", color: t.soluk, fontFamily: FONT.kalin, fontSize: 14, marginTop: 12 }}>
        {enIyi ? `En iyin: ${enIyi.value} (fark ${enIyi.fark}, ${enIyi.puan} puan)` : "Henüz sonuç yok"}
      </Text>
    </Ekran>
  );
}

export { Yazi };
