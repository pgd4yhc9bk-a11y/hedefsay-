// Kelime ve işlem turu oynatıcıları. Süre bitince / "Bitir" ile / işlemde tam isabette onBitir bir kez çağrılır.
import React, { useCallback, useEffect, useRef, useState } from "react";
import { Platform, Text, TextInput, View } from "react-native";
import H from "./cekirdek";
import { Baslik, Dugme, Karo, Kart, Mesaj, SayacCubugu, Sira, useGeriSayim, useTema, up, Yazi } from "./ui";

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
    <View>
      {ust}
      <Kart>
        <SayacCubugu kalanMs={kalanMs} sureSn={sureSn} />
        <Sira ortala bosluk={4}>
          {giris.map((g, i) => <Karo key={i} kucuk harf={g.ch} joker={g.joker} />)}
          {giris.length === 0 && <View style={{ height: 46 }} />}
        </Sira>
        <Mesaj metin={mesaj.m} iyi={mesaj.iyi} testID="mesaj" />
        <Sira ortala bosluk={6}>
          {harfler.map((h, i) => <Karo key={i} testID={`harf-${h}`} harf={h} kullanildi={k[i]} onPress={() => ekle(h)} />)}
          <Karo testID="joker" joker kullanildi={joker} onPress={() => setSecici(true)} />
        </Sira>
        <View style={{ height: 10 }} />
        <Sira ortala>
          <Dugme testID="sil" baslik="⌫ Sil" onPress={sil} />
          <Dugme testID="gonder" birincil baslik="Gönder" onPress={gonder} />
          <Dugme testID="bitir" baslik="Bitir" onPress={bitir} />
        </Sira>
        <Text testID="enIyi" style={{ textAlign: "center", color: t.soluk, marginTop: 8 }}>
          {enIyi ? `En iyin: ${up(enIyi.word)} (${enIyi.score} puan)` : "Henüz geçerli kelime yok"}
        </Text>
      </Kart>
      {secici && (
        <Kart>
          <Baslik boyut={18}>Joker hangi harf olsun?</Baslik>
          <Sira bosluk={6}>
            {H.ALFABE.split("").map((c) => <Karo key={c} testID={`joker-${c}`} harf={c} onPress={() => { setSecici(false); guncelle([...girisRef.current, { ch: c, joker: true }]); }} />)}
          </Sira>
          <View style={{ height: 8 }} />
          <Dugme baslik="Vazgeç" onPress={() => setSecici(false)} />
        </Kart>
      )}
    </View>
  );
}

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

  const kullanilanSayac: Record<string, number> = { ...kullan };
  return (
    <View>
      {ust}
      <Kart>
        <SayacCubugu kalanMs={kalanMs} sureSn={sureSn} />
        <Text testID="hedef" style={{ textAlign: "center", fontSize: 54, fontWeight: "800", color: t.vurgu }}>{hedef}</Text>
        <Sira ortala bosluk={6}>
          {sayilar.map((n, i) => {
            const k = String(n); const kullanildi = (kullanilanSayac[k] ?? 0) > 0;
            if (kullanildi) kullanilanSayac[k]--;
            return <Karo key={i} testID={`sayi-${n}`} harf={String(n)} kullanildi={kullanildi} onPress={() => setIfade((s) => s + n)} />;
          })}
        </Sira>
        <View style={{ height: 10 }} />
        <TextInput testID="ifade" value={ifade} onChangeText={setIfade} placeholder="örn. (7+3)×8−5" placeholderTextColor={t.soluk}
          autoCapitalize="none" autoCorrect={false} onSubmitEditing={gonder}
          style={{ color: t.yazi, borderColor: t.cizgi, borderWidth: 1, borderRadius: 10, padding: 10, fontSize: 22, textAlign: "center", backgroundColor: t.kart }} />
        <Mesaj metin={mesaj.m} iyi={mesaj.iyi} testID="mesaj" />
        <Sira ortala>
          {["+", "−", "×", "÷", "(", ")"].map((o) => <Dugme key={o} testID={`op-${o}`} baslik={o} onPress={() => setIfade((s) => s + o)} />)}
          <Dugme testID="sil" baslik="⌫" onPress={() => setIfade((s) => s.slice(0, -1))} />
        </Sira>
        <View style={{ height: 10 }} />
        <Sira ortala>
          <Dugme testID="gonder" birincil baslik="Gönder" onPress={gonder} />
          <Dugme testID="bitir" baslik="Bitir" onPress={bitir} />
        </Sira>
        <Text testID="enIyi" style={{ textAlign: "center", color: t.soluk, marginTop: 8 }}>
          {enIyi ? `En iyin: ${enIyi.value} (fark ${enIyi.fark}, ${enIyi.puan} puan)` : "Henüz sonuç yok"}
        </Text>
      </Kart>
    </View>
  );
}

export { Yazi };
