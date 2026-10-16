// Kelime ve işlem turu oynatıcıları. Süre bitince / "Bitir" ile / işlemde tam isabette onBitir bir kez çağrılır.
import React, { useCallback, useEffect, useRef, useState } from "react";
import { Platform, Text, View } from "react-native";
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

const OPERATORLER = ["+", "−", "×", "÷"];
interface Tas { id: number; v: number; e: string }   // e: tam parantezli ifade (sunucuya gider; ekranda görünmez)

export function IslemTuru({ sayilar, hedef, sureSn, kalanSn, bonus, ust, onBitir }:
  Ortak & { sayilar: number[]; hedef: number; bonus: boolean; onBitir: (s: IslemSonuc | null) => void }) {
  const t = useTema();
  // TV'deki gibi: bir sayı + bir işlem + bir sayı seçilir; ikisi kaybolup yerine sonuç karosu gelir.
  const [taslar, setTaslar] = useState<Tas[]>(() => sayilar.map((v, i) => ({ id: i, v, e: String(v) })));
  const [adimlar, setAdimlar] = useState<string[]>([]);
  const [gecmis, setGecmis] = useState<{ taslar: Tas[]; adimlar: string[] }[]>([]);
  const [secilen, setSecilen] = useState<number | null>(null);   // ilk sayının id'si
  const [op, setOp] = useState<string | null>(null);
  const [enIyi, setEnIyi] = useState<IslemSonuc | null>(null);
  const [mesaj, setMesaj] = useState<{ m: string; iyi: boolean }>({ m: "", iyi: false });
  const sonId = useRef(sayilar.length);
  const bittiMi = useRef(false);
  const enIyiRef = useRef<IslemSonuc | null>(null); enIyiRef.current = enIyi;

  const bitir = useCallback(() => {
    if (bittiMi.current) return;
    bittiMi.current = true;
    onBitir(enIyiRef.current);
  }, [onBitir]);
  const { kalanMs, kalanSn: kalanSnFn } = useGeriSayim(sureSn, kalanSn, bitir);

  const tasaDokun = (id: number) => {
    if (secilen === null || op === null) { setSecilen(secilen === id ? null : id); setOp(null); setMesaj({ m: "", iyi: false }); return; }
    if (id === secilen) { setSecilen(null); setOp(null); return; }
    // ikinci sayı seçildi: işlemi yap
    const A = taslar.find((x) => x.id === secilen)!, B = taslar.find((x) => x.id === id)!;
    const hesapla = (x: Tas, y: Tas): number | string => {
      if (op === "+") return x.v + y.v;
      if (op === "×") return x.v * y.v;
      if (op === "−") return x.v > y.v ? x.v - y.v : "Çıkarma sonucu pozitif olmalı";
      return y.v !== 0 && x.v % y.v === 0 ? x.v / y.v : "Bölme tam sayı çıkmalı";
    };
    let x = A, y = B, r = hesapla(x, y);
    if (typeof r === "string" && (op === "−" || op === "÷")) { const ters = hesapla(B, A); if (typeof ters === "number") { x = B; y = A; r = ters; } }   // sırayı kendisi düzeltir
    if (typeof r === "string") { setMesaj({ m: r, iyi: false }); setSecilen(null); setOp(null); return; }
    const yeni: Tas = { id: sonId.current++, v: r, e: `(${x.e}${op}${y.e})` };
    const satir = H.stepText({ a: x.v, op: op, b: y.v, r });
    setGecmis((g) => [...g, { taslar, adimlar }]);
    setTaslar([...taslar.filter((k) => k.id !== A.id && k.id !== B.id), yeni]);
    setAdimlar([...adimlar, satir]); setSecilen(null); setOp(null);
    const fark = Math.abs(hedef - r);
    const b = fark === 0 && bonus ? H.timeBonus(kalanSnFn()) : 0;
    const puan = H.numberScore(hedef, r) + b;
    setMesaj({ m: fark ? "" : "Tam isabet!", iyi: true });
    if (!enIyiRef.current || fark < enIyiRef.current.fark) { enIyiRef.current = { value: r, fark, puan, expr: yeni.e }; setEnIyi(enIyiRef.current); }
    if (fark === 0) bitir();
  };
  const geriAl = () => {
    const son = gecmis[gecmis.length - 1];
    if (!son) return;
    setTaslar(son.taslar); setAdimlar(son.adimlar); setGecmis((g) => g.slice(0, -1)); setSecilen(null); setOp(null); setMesaj({ m: "", iyi: false });
  };

  const yonerge = secilen === null ? "Bir sayı seç" : op === null ? "Bir işlem seç" : "İkinci sayıyı seç";
  return (
    <Ekran ust={ust}
      alt={<Sira bosluk={10} stil={{ flexWrap: "nowrap" }}>
        <Dugme testID="geri" baslik="↶ Geri al" pasif={gecmis.length === 0} onPress={geriAl} />
        <Dugme testID="bitir" birincil buyuk esnek baslik={enIyi ? `Bitir (${enIyi.value})` : "Bitir"} onPress={bitir} />
      </Sira>}>
      <SayacCubugu kalanMs={kalanMs} sureSn={sureSn} />
      <View style={{ alignItems: "center", justifyContent: "center", height: 150 }}>
        <Halkalar boyut={150} adet={4} mutlak />
        <Text style={{ position: "absolute", top: 14, color: t.soluk, fontFamily: FONT.kalin, fontSize: 12, letterSpacing: 2 }}>HEDEF</Text>
        <Text testID="hedef" style={{ fontFamily: FONT.siyah, fontSize: 60, color: t.vurguMetin }}>{hedef}</Text>
      </View>
      <Text testID="enIyi" style={{ textAlign: "center", color: t.soluk, fontFamily: FONT.kalin, fontSize: 14, marginBottom: 6 }}>
        {enIyi ? `En yakın: ${enIyi.value} (fark ${enIyi.fark})` : "Henüz sonuç yok"}
      </Text>
      <Kart stil={{ marginBottom: 10, minHeight: 72, paddingVertical: 10 }}>
        {adimlar.length === 0
          ? <Text style={{ color: t.soluk, fontFamily: FONT.orta, fontSize: 15, textAlign: "center", marginTop: 14 }}>İşlemlerin burada görünür</Text>
          : adimlar.slice(-4).map((a, i, d) => (
            <Text key={adimlar.length - d.length + i} testID="adim" style={{ color: i === d.length - 1 ? t.yazi : t.soluk, fontFamily: i === d.length - 1 ? FONT.siyah : FONT.kalin, fontSize: i === d.length - 1 ? 22 : 16, textAlign: "center" }}>{a}</Text>
          ))}
      </Kart>
      <View style={{ flex: 1, minHeight: 6 }} />
      <Text style={{ textAlign: "center", color: t.soluk, fontFamily: FONT.kalin, fontSize: 13, marginBottom: 8 }}>{yonerge}</Text>
      <Sira ortala bosluk={8}>
        {taslar.map((k) => <Karo key={k.id} testID={`sayi-${k.v}`} boyut="o" harf={String(k.v)} secili={k.id === secilen} onPress={() => tasaDokun(k.id)} />)}
      </Sira>
      <Bildirim metin={mesaj.m} iyi={mesaj.iyi} testID="mesaj" />
      <Sira ortala bosluk={10}>
        {OPERATORLER.map((o) => (
          <View key={o} style={{ width: 70 }}><Dugme testID={`op-${o}`} buyuk birincil={op === o} pasif={secilen === null} baslik={o} onPress={() => setOp(op === o ? null : o)} /></View>
        ))}
      </Sira>
    </Ekran>
  );
}

export { Yazi };
