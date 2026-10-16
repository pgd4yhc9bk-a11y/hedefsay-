// Pratik: bilgisayara (bota) karşı 4 tur, tamamen yerel (çevrimdışı çalışır). Harfleri 1. turda sen, 3. turda bot seçer.
import React, { useEffect, useRef, useState } from "react";
import { View } from "react-native";
import H from "../cekirdek";
import { IslemSonuc, IslemTuru, KelimeSonuc, KelimeTuru } from "../turlar";
import { Dugme, Ekran, Karo, Metin, Sira, UstCubuk, up } from "../ui";
import { TUR_ADI, TurGirisi } from "./ortak";
import { OyunSonu, TurOzeti, TurSonucu } from "./sonuc";

type Asama = "harf" | "giris" | "oyna" | "sonuc" | "son";
type Veri = { tip: "kelime"; harfler: string[]; secici: "ben" | "bot" } | { tip: "islem"; nums: number[]; target: number; found: Map<number, { e: string; n: number }> };
interface TurSonuc { ben: number; bot: number; simge: string; ek: any }

function HarfSec({ rr, ust, onTamam }: { rr: () => number; ust: React.ReactNode; onTamam: (h: string[]) => void }) {
  const [tipler, setTipler] = useState<("sesli" | "sessiz")[]>([]);
  const [harfler, setHarfler] = useState<string[]>([]);
  const sesli = tipler.filter((x) => x === "sesli").length;
  const kalan = H.HARF_SAYISI - tipler.length, gerek = Math.max(0, H.MIN_SESLI - sesli);
  const sec = (tip: "sesli" | "sessiz") => {
    setTipler([...tipler, tip]);
    setHarfler(tipler.length + 1 < H.HARF_SAYISI ? [...harfler, H.drawLetter(rr, tip)] : H.completeRack(rr, harfler, tip)); // son harf: 6+ harfli çözüm garantisi
  };
  return (
    <Ekran ust={ust} alt={kalan > 0
      ? <Sira bosluk={10} stil={{ flexWrap: "nowrap" }}>
          <Dugme testID="sesli" esnek buyuk baslik="Sesli" onPress={() => sec("sesli")} />
          <Dugme testID="sessiz" esnek buyuk baslik="Sessiz" pasif={kalan <= gerek} onPress={() => sec("sessiz")} />
        </Sira>
      : <Dugme testID="devam" birincil buyuk baslik="Devam" onPress={() => onTamam(harfler)} />}>
      <Metin v="baslikBuyuk">Harfleri sen seç</Metin>
      <Metin soluk stil={{ marginTop: 6, marginBottom: 24 }}>
        {kalan === 0 ? "Harflerin hazır." : `Kalan ${kalan} harf. En az ${H.MIN_SESLI} sesli olmalı${gerek ? ` — ${gerek} sesli daha gerekli.` : "."}`}
      </Metin>
      <Sira ortala bosluk={8}>
        {Array.from({ length: H.HARF_SAYISI }, (_, i) => <Karo key={i + "-" + (harfler[i] ?? "")} boyut="o" harf={harfler[i]} bos={!harfler[i]} pop={!!harfler[i]} />)}
        <Karo boyut="o" joker />
      </Sira>
    </Ekran>
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
  const [turlar, setTurlar] = useState<TurOzeti[]>([]);

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

  const bitir = (r: TurSonuc) => {
    setToplam((t) => ({ ben: t.ben + r.ben, bot: t.bot + r.bot }));
    setTurlar((x) => [...x, { ben: r.ben, rakip: r.bot }]); setSonuc(r); setAsama("sonuc");
  };
  const kelimeBitti = (s: KelimeSonuc | null) => {
    const v = veri as Extract<Veri, { tip: "kelime" }>;
    const en = H.allWords(v.harfler)[0] ?? null;
    const bw = H.botWord(v.harfler, botRng.current);
    bitir({ ben: s?.score ?? 0, bot: bw?.score ?? 0, simge: "", ek: { en, ben: s, bot: bw } });
  };
  const islemBitti = (s: IslemSonuc | null) => {
    const v = veri as Extract<Veri, { tip: "islem" }>;
    const bn = H.botNumber(v, botRng.current);
    bitir({ ben: s?.puan ?? 0, bot: H.numberScore(v.target, bn.value), simge: "", ek: { cozum: v.found.get(v.target), ben: s, bot: bn } });
  };
  const ileri = () => { if (tur < 3) { setTur(tur + 1); turHazirla(tur + 1); } else setAsama("son"); };

  const ust = (bitenler = tur) => <UstCubuk tur={tur} bitenler={bitenler} ad={TUR_ADI(tur)} sen={toplam.ben} rakip={toplam.bot} rakipAd="🤖 Bot" />;
  if (asama === "son") {
    const kazanan = toplam.ben > toplam.bot ? "ben" : toplam.ben < toplam.bot ? "rakip" : "berabere";
    const baslik = kazanan === "ben" ? "Kazandın! 🏆" : kazanan === "rakip" ? "Bot kazandı" : "Berabere";
    const simgeler = turlar.map((x) => (x.ben > (x.rakip ?? 0) ? "🟩" : x.ben < (x.rakip ?? 0) ? "🟥" : "⬜")).join("");
    return <OyunSonu kazanan={kazanan} baslik={baslik} sen={toplam.ben} rakip={toplam.bot} rakipAd="Bot" rakipBot turlar={turlar}
      paylasMetni={`Hedef Düello\n${simgeler} ${toplam.ben}–${toplam.bot} (bot)`}
      onRovans={() => { setTur(0); setToplam({ ben: 0, bot: 0 }); setTurlar([]); turHazirla(0); }} onMenu={onMenu} />;
  }
  if (asama === "harf") return <HarfSec rr={() => rr.current()} ust={ust()} onTamam={(h) => { setVeri({ tip: "kelime", harfler: h, secici: "ben" }); setAsama("giris"); }} />;
  if (asama === "giris" && veri) {
    return veri.tip === "kelime"
      ? <TurGirisi ust={ust()} tip="kelime" harfler={veri.harfler} onBasla={() => setAsama("oyna")}
          aciklama={`${veri.secici === "ben" ? "Harfleri sen seçtin." : "Bu turun harflerini rakip seçti."} En uzun geçerli kelimeyi kur. Süre: 60 sn.`} />
      : <TurGirisi ust={ust()} tip="islem" onBasla={() => setAsama("oyna")} aciklama="Dört işlemle hedefe ulaş. Çıkarma ve bölme sonucu pozitif tam sayı olmalı; her sayı bir kez. Süre: 60 sn." />;
  }
  if (asama === "oyna" && veri) {
    return veri.tip === "kelime"
      ? <KelimeTuru key={tur} ust={ust()} harfler={veri.harfler} sureSn={60} onBitir={kelimeBitti} />
      : <IslemTuru key={tur} ust={ust()} sayilar={veri.nums} hedef={veri.target} sureSn={60} bonus={false} onBitir={islemBitti} />;
  }
  if (asama === "sonuc" && sonuc && veri) {
    const e = sonuc.ek;
    const ileriBaslik = tur < 3 ? "Sonraki tur" : "Sonucu gör";
    return veri.tip === "kelime"
      ? <TurSonucu ust={ust(tur + 1)} tur={tur} tip="kelime" ileriBaslik={ileriBaslik} onIleri={ileri}
          sen={{ ad: "Sen", puan: sonuc.ben, cevap: e.ben?.word ?? "" }} rakip={{ ad: "Bot", bot: true, puan: sonuc.bot, cevap: e.bot?.word ?? "" }}
          enIyi={{ baslik: "BU HARFLERLE EN İYİ", cevap: e.en?.word ?? "", kelime: true, ayrinti: e.en ? `${up(e.en.word)} (${e.en.score} puan${e.en.joker ? ", jokerli" : ""})` : "—" }} />
      : <TurSonucu ust={ust(tur + 1)} tur={tur} tip="islem" ileriBaslik={ileriBaslik} onIleri={ileri}
          sen={{ ad: "Sen", puan: sonuc.ben, cevap: e.ben?.expr ?? "", deger: e.ben?.value }} rakip={{ ad: "Bot", bot: true, puan: sonuc.bot, cevap: e.bot.expr, deger: e.bot.value }}
          enIyi={{ baslik: "BİLGİSAYARIN ÇÖZÜMÜ", cevap: e.cozum.e, ayrinti: `Hedef ${veri.target}` }} />;
  }
  return null;
}
