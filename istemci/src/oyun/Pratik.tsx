// Pratik: bilgisayara (bota) karşı 4 tur, tamamen yerel (çevrimdışı çalışır). Harfleri 1. turda sen, 3. turda bot seçer.
import React, { useEffect, useRef, useState } from "react";
import { View } from "react-native";
import H, { Bulmaca } from "../cekirdek";
import { IslemSonuc, IslemTuru, KelimeSonuc, KelimeTuru } from "../turlar";
import { Baslik, Cizelge, Dugme, Karo, Kart, Sira, up, Yazi } from "../ui";
import { TUR_ADI, Ust } from "./ortak";

type Asama = "harf" | "giris" | "oyna" | "sonuc" | "son";
type Veri = { tip: "kelime"; harfler: string[]; secici: "ben" | "bot" } | { tip: "islem"; nums: number[]; target: number; found: Map<number, { e: string; n: number }> };
interface TurSonuc { ben: number; bot: number; ek: any; simge: string }

function HarfSec({ rr, onTamam }: { rr: () => number; onTamam: (h: string[]) => void }) {
  const [tipler, setTipler] = useState<("sesli" | "sessiz")[]>([]);
  const [harfler, setHarfler] = useState<string[]>([]);
  const sesli = tipler.filter((x) => x === "sesli").length;
  const kalan = H.HARF_SAYISI - tipler.length, gerek = Math.max(0, H.MIN_SESLI - sesli);
  const sec = (tip: "sesli" | "sessiz") => {
    setTipler([...tipler, tip]);
    setHarfler(tipler.length + 1 < H.HARF_SAYISI ? [...harfler, H.drawLetter(rr, tip)] : H.completeRack(rr, harfler, tip)); // son harf: 6+ harfli çözüm garantisi
  };
  return (
    <Kart>
      <Baslik boyut={18}>Harfleri sen seç</Baslik>
      <Yazi soluk>En az {H.MIN_SESLI} sesli olmalı. {gerek ? `${gerek} sesli daha gerekli.` : ""}</Yazi>
      <Sira ortala bosluk={6}>
        {Array.from({ length: H.HARF_SAYISI }, (_, i) => <Karo key={i} harf={harfler[i]} bos={!harfler[i]} />)}
        <Karo joker />
      </Sira>
      <View style={{ height: 10 }} />
      {kalan > 0
        ? <Sira ortala><Dugme testID="sesli" baslik="Sesli" onPress={() => sec("sesli")} /><Dugme testID="sessiz" baslik="Sessiz" pasif={kalan <= gerek} onPress={() => sec("sessiz")} /></Sira>
        : <Dugme testID="devam" birincil buyuk baslik="Devam" onPress={() => onTamam(harfler)} />}
    </Kart>
  );
}

export function Pratik({ onMenu }: { onMenu: () => void }) {
  const tohum = useRef("oyun-" + Math.random() + "-" + Date.now()).current;
  const rr = useRef<() => number>(() => 0);
  const botRng = useRef<() => number>(() => 0);
  const [tur, setTur] = useState(0);
  const [asama, setAsama] = useState<Asama>("harf");
  const [veri, setVeri] = useState<Veri | null>(null);
  const [toplam, setToplam] = useState({ ben: 0, bot: 0 });
  const [sonuc, setSonuc] = useState<TurSonuc | null>(null);
  const [simgeler, setSimgeler] = useState<string[]>([]);

  const turHazirla = (i: number) => {
    rr.current = H.makeRng(tohum + "|" + i); botRng.current = H.makeRng(tohum + "|bot|" + i);
    setSonuc(null); setVeri(null);
    if (H.GUNLUK_TURLAR[i] === "kelime") {
      if (i === 0) { setAsama("harf"); return; }
      setVeri({ tip: "kelime", harfler: H.generateRack(rr.current, H.randomTypes(botRng.current)), secici: "bot" });
    } else {
      const r = H.generateNumberRound(rr.current);
      setVeri({ tip: "islem", nums: r.nums, target: r.target, found: r.found });
    }
    setAsama("giris");
  };
  useEffect(() => { turHazirla(0); /* eslint-disable-next-line react-hooks/exhaustive-deps */ }, []);

  const kelimeBitti = (s: KelimeSonuc | null) => {
    const v = veri as Extract<Veri, { tip: "kelime" }>;
    const en = H.allWords(v.harfler)[0] ?? null;
    const bw = H.botWord(v.harfler, botRng.current);
    const ben = s?.score ?? 0, bot = bw?.score ?? 0;
    const simge = !s ? "⬜" : !en || ben >= en.score ? "🎯" : ben >= en.score * 0.6 ? "🟨" : "⬜";
    bitir({ ben, bot, simge, ek: { en, benKelime: s, botKelime: bw } });
  };
  const islemBitti = (s: IslemSonuc | null) => {
    const v = veri as Extract<Veri, { tip: "islem" }>;
    const bn = H.botNumber(v, botRng.current);
    const ben = s?.puan ?? 0, bot = H.numberScore(v.target, bn.value);
    bitir({ ben, bot, simge: ben >= 10 ? "🎯" : ben > 0 ? "🟨" : "⬜", ek: { cozum: v.found.get(v.target), benIslem: s, botIslem: bn } });
  };
  const bitir = (r: TurSonuc) => {
    setToplam((t) => ({ ben: t.ben + r.ben, bot: t.bot + r.bot }));
    setSimgeler((x) => [...x, r.simge]); setSonuc(r); setAsama("sonuc");
  };
  const ileri = () => { if (tur < 3) { setTur(tur + 1); turHazirla(tur + 1); } else setAsama("son"); };

  const sag = `Sen ${toplam.ben} · Bot ${toplam.bot}`;
  if (asama === "son") {
    const baslik = toplam.ben > toplam.bot ? "Kazandın! 🏆" : toplam.ben < toplam.bot ? "Bot kazandı" : "Berabere";
    const paylas = `Hedef Düello\n${simgeler.join("")} ${toplam.ben} puan (bot ${toplam.bot})`;
    return (
      <View>
        <Baslik boyut={30}>{baslik}</Baslik>
        <Kart>
          <Baslik>{toplam.ben} puan — Bot {toplam.bot}</Baslik>
          <Yazi testID="paylas">{paylas}</Yazi>
          <View style={{ height: 10 }} />
          <Sira><Dugme testID="rovans" birincil baslik="Rövanş" onPress={() => { setTur(0); setToplam({ ben: 0, bot: 0 }); setSimgeler([]); turHazirla(0); }} /><Dugme testID="menu" baslik="Menü" onPress={onMenu} /></Sira>
        </Kart>
      </View>
    );
  }
  if (asama === "harf") return <View><Ust tur={tur} sag={sag} /><HarfSec rr={() => rr.current()} onTamam={(h) => { setVeri({ tip: "kelime", harfler: h, secici: "ben" }); setAsama("giris"); }} /></View>;
  if (asama === "giris" && veri) {
    return (
      <View>
        <Ust tur={tur} sag={sag} />
        <Kart>
          <Baslik boyut={18}>{TUR_ADI(tur)} turu</Baslik>
          {veri.tip === "kelime"
            ? <><Yazi soluk>{veri.secici === "ben" ? "Harfleri sen seçtin." : "Bu turun harflerini rakip seçti."} En uzun geçerli kelimeyi kur. Süre: 60 sn.</Yazi>
                <Sira ortala bosluk={6}>{veri.harfler.map((h, i) => <Karo key={i} harf={h} />)}<Karo joker /></Sira></>
            : <Yazi soluk>Dört işlemle hedefe ulaş. Çıkarma ve bölme sonucu pozitif tam sayı olmalı; her sayı bir kez. Süre: 60 sn.</Yazi>}
          <View style={{ height: 10 }} />
          <Dugme testID="go" birincil buyuk baslik="Süreyi başlat" onPress={() => setAsama("oyna")} />
        </Kart>
      </View>
    );
  }
  if (asama === "oyna" && veri) {
    return veri.tip === "kelime"
      ? <KelimeTuru key={tur} ust={<Ust tur={tur} sag={sag} />} harfler={veri.harfler} sureSn={60} onBitir={kelimeBitti} />
      : <IslemTuru key={tur} ust={<Ust tur={tur} sag={sag} />} sayilar={veri.nums} hedef={veri.target} sureSn={60} bonus={false} onBitir={islemBitti} />;
  }
  if (asama === "sonuc" && sonuc && veri) {
    const e = sonuc.ek;
    return (
      <View>
        <Ust tur={tur} sag={sag} />
        <Kart>
          <Baslik boyut={18}>Tur {tur + 1} sonucu</Baslik>
          <Cizelge ad="" a="Sen" b="Bot" />
          {veri.tip === "kelime"
            ? <>
                <Cizelge ad="Kelime" a={e.benKelime ? up(e.benKelime.word) : "—"} b={e.botKelime ? up(e.botKelime.word) : "—"} />
                <Cizelge ad="Puan" a={sonuc.ben} b={sonuc.bot} />
                <Yazi soluk testID="en-iyi">Bu harflerle en iyi: {e.en ? `${up(e.en.word)} (${e.en.score} puan${e.en.joker ? ", jokerli" : ""})` : "—"}</Yazi>
              </>
            : <>
                <Cizelge ad="Sonuç" a={e.benIslem ? e.benIslem.value : "—"} b={e.botIslem.value} />
                <Cizelge ad="Puan" a={sonuc.ben} b={sonuc.bot} />
                <Yazi soluk testID="en-iyi">Hedef {veri.target} · bilgisayarın çözümü: {e.cozum.e} = {veri.target}</Yazi>
                <Yazi soluk>Botun işlemi: {e.botIslem.expr} = {e.botIslem.value}</Yazi>
              </>}
          <View style={{ height: 10 }} />
          <Dugme testID="ileri" birincil buyuk baslik={tur < 3 ? "Sonraki tur" : "Sonucu gör"} onPress={ileri} />
        </Kart>
      </View>
    );
  }
  return null;
}

export type { Bulmaca };
