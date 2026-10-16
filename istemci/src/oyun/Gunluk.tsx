// Günlük mücadele: bulmaca ve puan sunucudan, süre sunucu damgasıyla. Yenilenince kalınan turdan devam eder.
import AsyncStorage from "@react-native-async-storage/async-storage";
import React, { useCallback, useEffect, useRef, useState } from "react";
import H from "../cekirdek";
import * as S from "../sunucu";
import { IslemSonuc, IslemTuru, KelimeSonuc, KelimeTuru } from "../turlar";
import { Bildirim, UstCubuk, up } from "../ui";
import { bugun, haftaBasi } from "../zaman";
import { HataEkrani, Profil, TUR_ADI, TurGirisi, Yukleniyor } from "./ortak";
import { OyunSonu, Siralama, TurOzeti, TurSonucu } from "./sonuc";

type Asama = "yukleniyor" | "profil" | "giris" | "baslatiliyor" | "oyna" | "gonderiliyor" | "sonuc" | "son" | "hata";
const simgeAnahtar = () => "hedef-gunluk-simge-" + bugun();

export function Gunluk({ onMenu }: { onMenu: () => void }) {
  const [asama, setAsama] = useState<Asama>("yukleniyor");
  const [tur, setTur] = useState(0);
  const [turlar, setTurlar] = useState<TurOzeti[]>([]);
  const [veri, setVeri] = useState<any>(null);
  const [sonuc, setSonuc] = useState<any>(null);
  const [hata, setHata] = useState("");
  const [sira, setSira] = useState<{ gen: any[]; il: any[] } | null>(null);
  const yeniden = useRef<() => void>(() => {});
  const aktif = useRef(true);
  useEffect(() => () => { aktif.current = false; }, []);
  const ok = useCallback((f: () => void) => { if (aktif.current) f(); }, []);
  const toplam = turlar.reduce((t, x) => t + x.ben, 0);

  const hataGoster = useCallback((m: string, tekrar?: () => void) => { yeniden.current = tekrar ?? (() => {}); ok(() => { setHata(m); setAsama("hata"); }); }, [ok]);

  const yukle = useCallback(async () => {
    ok(() => setAsama("yukleniyor"));
    try {
      const o = await S.oyuncu();
      if (!o) return ok(() => setAsama("profil"));
      const sk = await S.skorlar(bugun());
      let kayitli: string[] = [];
      try { kayitli = JSON.parse((await AsyncStorage.getItem(simgeAnahtar())) || "[]"); } catch { /* yok */ }
      ok(() => {
        setTur(sk.length); setTurlar(sk.map((x, i) => ({ ben: x.score, simge: kayitli[i] ?? "🟨" })));
        setAsama(sk.length >= 4 ? "son" : "giris");
      });
    } catch (e: any) { hataGoster(e.message, yukle); }
  }, [ok, hataGoster]);
  useEffect(() => { yukle(); }, [yukle]);

  const baslat = async () => {
    setAsama("baslatiliyor");
    try {
      const r = await S.gunlukTur("start", tur + 1);
      r.kalanSn = r.limit_sec - (Date.parse(r.server_now) - Date.parse(r.started_at)) / 1000;
      ok(() => { setVeri(r); setAsama("oyna"); });
    } catch (e: any) { if (e.status === 409) yukle(); else hataGoster(e.message, baslat); }
  };

  const gonder = async (cevap: string, yerel: { islemDeger?: number }) => {
    ok(() => setAsama("gonderiliyor"));
    const dene = async () => {
      try {
        const r = await S.gunlukTur("submit", tur + 1, cevap);
        const ben = r.score, en = r.best_score;
        const simge = veri.kind === "kelime" ? (ben >= en ? "🎯" : ben >= en * 0.6 ? "🟨" : "⬜") : (ben >= 10 ? "🎯" : ben > 0 ? "🟨" : "⬜");
        const yeni = [...turlar, { ben, simge }];
        try { await AsyncStorage.setItem(simgeAnahtar(), JSON.stringify(yeni.map((x) => x.simge))); } catch { /* depo yoksa kalıcı olmaz */ }
        ok(() => { setTurlar(yeni); setSonuc({ ...r, cevap, ...yerel }); setAsama("sonuc"); });
      } catch (e: any) { if (e.status === 409) yukle(); else hataGoster(e.message, dene); }
    };
    dene();
  };
  const kelimeBitti = (s: KelimeSonuc | null) => gonder(s?.word ?? "", {});
  const islemBitti = (s: IslemSonuc | null) => gonder(s?.expr ?? "", { islemDeger: s?.value });
  const ileri = () => { if (tur < 3) { setTur(tur + 1); setAsama("giris"); } else setAsama("son"); };

  useEffect(() => {
    if (asama !== "son") return;
    Promise.all([S.siralama(bugun()), S.ilLigi(haftaBasi())]).then(([gen, il]) => ok(() => setSira({ gen, il }))).catch(() => ok(() => setSira({ gen: [], il: [] })));
  }, [asama, ok]);

  const ust = (bitenler = tur) => <UstCubuk tur={tur} bitenler={bitenler} ad={TUR_ADI(tur)} sen={toplam} />;
  if (asama === "yukleniyor") return <Yukleniyor />;
  if (asama === "hata") return <HataEkrani mesaj={hata} yeniden={yeniden.current} onMenu={onMenu} />;
  if (asama === "profil") return <Profil onTamam={yukle} onMenu={onMenu} />;
  if (asama === "baslatiliyor") return <Yukleniyor metin="Tur başlatılıyor…" ust={ust()} />;
  if (asama === "gonderiliyor") return <Yukleniyor metin="Puanlanıyor…" ust={ust()} />;
  if (asama === "giris") {
    return <TurGirisi ust={ust()} tip={tur % 2 === 0 ? "kelime" : "islem"} onBasla={baslat}
      aciklama={`Herkese aynı bulmaca. Süreyi başlatınca ${tur % 2 === 0 ? "harfler açılır" : "sayılar ve hedef açılır"} ve süre sunucuda işlemeye başlar (${H.GUNLUK_SURE} sn).`} />;
  }
  if (asama === "oyna" && veri) {
    return veri.kind === "kelime"
      ? <KelimeTuru key={tur} ust={ust()} harfler={veri.payload.letters} sureSn={veri.limit_sec} kalanSn={veri.kalanSn} onBitir={kelimeBitti} />
      : <IslemTuru key={tur} ust={ust()} sayilar={veri.payload.nums} hedef={veri.payload.target} sureSn={veri.limit_sec} kalanSn={veri.kalanSn} bonus onBitir={islemBitti} />;
  }
  if (asama === "sonuc" && sonuc && veri) {
    const ileriBaslik = tur < 3 ? "Sonraki tur" : "Sonucu gör";
    return veri.kind === "kelime"
      ? <TurSonucu ust={ust(tur + 1)} tur={tur} tip="kelime" ileriBaslik={ileriBaslik} onIleri={ileri} sen={{ ad: "Sen", puan: sonuc.score, cevap: sonuc.cevap }}
          enIyi={{ baslik: "BU HARFLERLE EN İYİ", cevap: sonuc.best_solution ?? "", kelime: true, ayrinti: sonuc.best_solution ? `${up(sonuc.best_solution)} (${sonuc.best_score} puan)` : "—" }}
          ek={!sonuc.valid ? <Hata metin={sonuc.detail} /> : undefined} />
      : <TurSonucu ust={ust(tur + 1)} tur={tur} tip="islem" ileriBaslik={ileriBaslik} onIleri={ileri} sen={{ ad: "Sen", puan: sonuc.score, cevap: sonuc.cevap, deger: sonuc.islemDeger }}
          enIyi={{ baslik: "BİLGİSAYARIN ÇÖZÜMÜ", cevap: `${sonuc.best_solution ?? "—"} = ${veri.payload.target}`, ayrinti: `Hedef ${veri.payload.target}` }}
          ek={!sonuc.valid ? <Hata metin={sonuc.detail} /> : undefined} />;
  }
  if (asama === "son") {
    const paylasMetni = `Hedef Günlük ${bugun()}\n${turlar.map((x) => x.simge).join("")} ${toplam} puan`;
    return <OyunSonu kazanan="gunluk" baslik="Günlük bitti" sen={toplam} turlar={turlar} paylasMetni={paylasMetni} onMenu={onMenu}
      ek={sira ? <Siralama gen={sira.gen} il={sira.il} /> : undefined} />;
  }
  return null;
}

const Hata = ({ metin }: { metin: string }) => <Bildirim metin={metin} />;
