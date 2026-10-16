// Günlük mücadele: bulmaca ve puan sunucudan, süre sunucu damgasıyla. Yenilenince kalınan turdan devam eder.
import AsyncStorage from "@react-native-async-storage/async-storage";
import React, { useCallback, useEffect, useRef, useState } from "react";
import { View } from "react-native";
import H from "../cekirdek";
import * as S from "../sunucu";
import { IslemSonuc, IslemTuru, KelimeSonuc, KelimeTuru } from "../turlar";
import { Baslik, Cizelge, Dugme, Kart, Karo, Sira, up, Yazi } from "../ui";
import { bugun, haftaBasi } from "../zaman";
import { HataEkrani, Profil, TUR_ADI, Ust } from "./ortak";

type Asama = "yukleniyor" | "profil" | "giris" | "baslatiliyor" | "oyna" | "gonderiliyor" | "sonuc" | "son" | "hata";
const simgeAnahtar = () => "hedef-gunluk-simge-" + bugun();

export function Gunluk({ onMenu }: { onMenu: () => void }) {
  const [asama, setAsama] = useState<Asama>("yukleniyor");
  const [tur, setTur] = useState(0);
  const [toplam, setToplam] = useState(0);
  const [simgeler, setSimgeler] = useState<string[]>([]);
  const [veri, setVeri] = useState<any>(null);
  const [sonuc, setSonuc] = useState<any>(null);
  const [hata, setHata] = useState("");
  const [sira, setSira] = useState<{ gen: any[]; il: any[] } | null>(null);
  const yeniden = useRef<() => void>(() => {});
  const aktif = useRef(true);
  useEffect(() => () => { aktif.current = false; }, []);
  const ok = useCallback((f: () => void) => { if (aktif.current) f(); }, []);

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
        setTur(sk.length); setToplam(sk.reduce((t, x) => t + x.score, 0));
        setSimgeler(sk.map((_, i) => kayitli[i] ?? "🟨"));
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
        const yeni = [...simgeler, simge];
        try { await AsyncStorage.setItem(simgeAnahtar(), JSON.stringify(yeni)); } catch { /* depo yoksa kalıcı olmaz */ }
        ok(() => { setToplam((t) => t + ben); setSimgeler(yeni); setSonuc({ ...r, cevap, ...yerel }); setAsama("sonuc"); });
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

  const sag = `Puan ${toplam}`;
  if (asama === "yukleniyor") return <Kart><Yazi>Bağlanıyor…</Yazi></Kart>;
  if (asama === "hata") return <HataEkrani mesaj={hata} yeniden={yeniden.current} onMenu={onMenu} />;
  if (asama === "profil") return <Profil onTamam={yukle} onMenu={onMenu} />;
  if (asama === "baslatiliyor") return <Kart><Yazi>Tur başlatılıyor…</Yazi></Kart>;
  if (asama === "gonderiliyor") return <Kart><Yazi>Puanlanıyor…</Yazi></Kart>;
  if (asama === "giris") {
    return (
      <View>
        <Ust tur={tur} sag={sag} />
        <Kart>
          <Baslik boyut={18}>{TUR_ADI(tur)} turu</Baslik>
          <Yazi soluk>Herkese aynı bulmaca. Süreyi başlatınca {tur % 2 === 0 ? "harfler açılır" : "sayılar ve hedef açılır"} ve süre sunucuda işlemeye başlar ({H.GUNLUK_SURE} sn).</Yazi>
          <View style={{ height: 10 }} />
          <Dugme testID="go" birincil buyuk baslik="Süreyi başlat" onPress={baslat} />
        </Kart>
      </View>
    );
  }
  if (asama === "oyna" && veri) {
    const ust = <Ust tur={tur} sag={sag} />;
    return veri.kind === "kelime"
      ? <KelimeTuru key={tur} ust={ust} harfler={veri.payload.letters} sureSn={veri.limit_sec} kalanSn={veri.kalanSn} onBitir={kelimeBitti} />
      : <IslemTuru key={tur} ust={ust} sayilar={veri.payload.nums} hedef={veri.payload.target} sureSn={veri.limit_sec} kalanSn={veri.kalanSn} bonus onBitir={islemBitti} />;
  }
  if (asama === "sonuc" && sonuc && veri) {
    return (
      <View>
        <Ust tur={tur} sag={sag} />
        <Kart>
          <Baslik boyut={18}>Tur {tur + 1} sonucu</Baslik>
          <Cizelge ad="" a="Sen" />
          {veri.kind === "kelime"
            ? <><Cizelge ad="Kelime" a={sonuc.cevap ? up(sonuc.cevap) : "—"} /><Cizelge ad="Puan" a={sonuc.score} />
                <Yazi soluk testID="en-iyi">Bu harflerle en iyi: {sonuc.best_solution ? `${up(sonuc.best_solution)} (${sonuc.best_score} puan)` : "—"}</Yazi></>
            : <><Cizelge ad="Sonuç" a={sonuc.islemDeger ?? "—"} /><Cizelge ad="Puan" a={sonuc.score} />
                <Yazi soluk testID="en-iyi">Hedef {veri.payload.target} · bilgisayarın çözümü: {sonuc.best_solution ?? "—"} = {veri.payload.target}</Yazi></>}
          {!sonuc.valid && <Yazi soluk>{sonuc.detail}</Yazi>}
          <View style={{ height: 10 }} />
          <Dugme testID="ileri" birincil buyuk baslik={tur < 3 ? "Sonraki tur" : "Sonucu gör"} onPress={ileri} />
        </Kart>
      </View>
    );
  }
  if (asama === "son") {
    const paylas = `Hedef Günlük ${bugun()}\n${simgeler.join("")} ${toplam} puan`;
    return (
      <View>
        <Baslik boyut={30}>Günlük bitti</Baslik>
        <Kart>
          <Baslik>{toplam} puan</Baslik>
          <Yazi testID="paylas">{paylas}</Yazi>
          <View style={{ height: 10 }} />
          <Dugme testID="menu" baslik="Menü" onPress={onMenu} />
        </Kart>
        {!sira ? <Kart><Yazi soluk>Sıralama yükleniyor…</Yazi></Kart> : (
          <>
            <Kart>
              <Baslik boyut={18}>Bugünün sıralaması</Baslik>
              {sira.gen.length ? sira.gen.map((x) => <Cizelge key={x.rank} ad={`${x.rank}. ${x.nick}${x.city ? ` (${x.city})` : ""}`} a={x.total} />) : <Yazi soluk>Henüz kimse bitirmedi.</Yazi>}
            </Kart>
            <Kart>
              <Baslik boyut={18}>İl ligi (bu hafta)</Baslik>
              {sira.il.length ? sira.il.map((x, i) => <Cizelge key={x.city} ad={`${i + 1}. ${x.city} (${x.players} oyuncu)`} a={x.total} />) : <Yazi soluk>Henüz il verisi yok.</Yazi>}
            </Kart>
          </>
        )}
      </View>
    );
  }
  return null;
}
