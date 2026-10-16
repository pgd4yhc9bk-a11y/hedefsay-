// Canlı düello: gerçek rakip aranır, 15 sn içinde bulunamazsa açıkça "Bot" ile oynanır. Durum sunucuda tutulur;
// istemci ~1,2 sn'de bir `status` sorgular (polling), bağlantı kopsa da aynı maça dönülür.
import React, { useCallback, useEffect, useRef, useState } from "react";
import { View } from "react-native";
import H from "../cekirdek";
import * as S from "../sunucu";
import { IslemSonuc, IslemTuru, KelimeSonuc, KelimeTuru } from "../turlar";
import { Baslik, Cizelge, Dugme, Kart, Sira, up, Yazi } from "../ui";
import { HataEkrani, Profil, TUR_ADI, Ust } from "./ortak";

type Asama = "yukleniyor" | "profil" | "bekle" | "sayim" | "oyna" | "gonderiliyor" | "rakipBekle" | "sonuc" | "son" | "hata";

export function Duello({ onMenu }: { onMenu: () => void }) {
  const [asama, setAsama] = useState<Asama>("yukleniyor");
  const [rakip, setRakip] = useState("Rakip");
  const [tur, setTur] = useState(0);                 // 0..3
  const [toplam, setToplam] = useState({ ben: 0, rakip: 0 });
  const [veri, setVeri] = useState<any>(null);       // start yanıtı (bulmaca)
  const [sayim, setSayim] = useState(0);
  const [bekle, setBekle] = useState<any>(null);     // bekleyen maç görünümü
  const [gorunum, setGorunum] = useState<any>(null); // son sunucu görünümü (sonuçlar)
  const [hata, setHata] = useState("");
  const macId = useRef("");
  const yeniden = useRef<() => void>(() => {});
  const aktif = useRef(true);
  const kosu = useRef(0);   // iptal edilebilir döngüler için nesil sayacı
  useEffect(() => () => { aktif.current = false; kosu.current++; }, []);
  const ok = useCallback((f: () => void) => { if (aktif.current) f(); }, []);
  const hataGoster = useCallback((m: string, tekrar?: () => void) => { yeniden.current = tekrar ?? (() => {}); ok(() => { setHata(m); setAsama("hata"); }); }, [ok]);

  const baslat = useCallback(async (r: number) => {
    const nesil = ++kosu.current;
    const dene = async (): Promise<void> => {
      if (nesil !== kosu.current) return;
      try {
        const res = await S.duello("start", { match_id: macId.current, round: r });
        if (nesil !== kosu.current) return;
        if (res.durum === "sayim") {
          ok(() => { setSayim(Math.max(1, Math.ceil(res.bekle_ms / 1000))); setAsama("sayim"); });
          setTimeout(dene, Math.min(Math.max(res.bekle_ms, 50), 400));
          return;
        }
        res.kalanSn = res.limit_sec - (Date.parse(res.server_now) - Date.parse(res.started_at)) / 1000;
        ok(() => { setVeri(res); setAsama("oyna"); });
      } catch (e: any) {
        if (e.status === 409) { try { goster(await S.duello("status", { match_id: macId.current })); } catch { setTimeout(dene, 1000); } }
        else hataGoster(e.message, () => baslat(r));
      }
    };
    dene();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ok, hataGoster]);

  // Sunucunun maç görünümüne göre doğru ekranı seçer (yeniden bağlanma da buradan geçer)
  const goster = useCallback((g: any) => {
    macId.current = g.match_id;
    ok(() => {
      setRakip(g.rakip?.nick ?? "Rakip"); setGorunum(g);
      if (g.terk) return hataGoster("Maç iptal oldu (bekleme süresi doldu).", giris);
      if (g.state === "waiting") { setBekle(g); setAsama("bekle"); return; }
      if (g.bitti) { setToplam({ ben: g.toplam.ben, rakip: g.toplam.rakip }); setAsama("son"); return; }
      setToplam({ ben: g.toplam.ben, rakip: g.toplam.rakip }); setTur(g.tur - 1);
      if (g.ben_gonderdim) { setAsama("rakipBekle"); return; }
      setAsama("sayim"); baslat(g.tur);
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ok, hataGoster, baslat]);

  const giris = useCallback(async () => {
    kosu.current++;
    ok(() => setAsama("yukleniyor"));
    try {
      const o = await S.oyuncu();
      if (!o) return ok(() => setAsama("profil"));
      goster(await S.duello("queue"));
    } catch (e: any) { hataGoster(e.message, giris); }
  }, [ok, goster, hataGoster]);
  useEffect(() => { giris(); }, [giris]);

  // Bekleyen maç: durum sorgula; süre dolunca bot iste
  const botIstendi = useRef(false);
  useEffect(() => {
    if (asama !== "bekle") return;
    botIstendi.current = false;
    let calisiyor = false;
    const id = setInterval(async () => {
      if (calisiyor) return; calisiyor = true;
      try {
        const v = await S.duello("status", { match_id: macId.current });
        macId.current = v.match_id;
        if (v.state !== "waiting") return goster(v);
        ok(() => setBekle(v));
        if (v.bot_icin_kalan_ms <= 0 && !botIstendi.current) {
          botIstendi.current = true;
          try { goster(await S.duello("bot", { match_id: v.match_id })); } catch { botIstendi.current = false; }
        }
      } catch { /* bağlantı kopması: sessizce yeniden dener */ } finally { calisiyor = false; }
    }, 1200);
    return () => clearInterval(id);
  }, [asama, goster, ok]);

  // Cevabım gitti, rakip bekleniyor: tur bitene kadar sorgula
  useEffect(() => {
    if (asama !== "rakipBekle") return;
    let calisiyor = false;
    const id = setInterval(async () => {
      if (calisiyor) return; calisiyor = true;
      try {
        const v = await S.duello("status", { match_id: macId.current });
        if (v.bitti || v.sonuclar.length >= tur + 1) ok(() => { setGorunum(v); setToplam({ ben: v.toplam.ben, rakip: v.toplam.rakip }); setAsama("sonuc"); });
      } catch { /* yeniden dener */ } finally { calisiyor = false; }
    }, 1200);
    return () => clearInterval(id);
  }, [asama, tur, ok]);

  const gonder = async (cevap: string) => {
    ok(() => setAsama("gonderiliyor"));
    const dene = async (): Promise<void> => {
      try {
        const v = await S.duello("submit", { match_id: macId.current, round: tur + 1, answer: cevap });
        ok(() => {
          setGorunum(v); setToplam({ ben: v.toplam.ben, rakip: v.toplam.rakip });
          setAsama(v.sonuclar.length >= tur + 1 ? "sonuc" : "rakipBekle");
        });
      } catch (e: any) {
        if (e.status === 409) { try { goster(await S.duello("status", { match_id: macId.current })); } catch { hataGoster(e.message, dene); } }
        else hataGoster(e.message, dene);
      }
    };
    dene();
  };
  const kelimeBitti = (s: KelimeSonuc | null) => gonder(s?.word ?? "");
  const islemBitti = (s: IslemSonuc | null) => gonder(s?.expr ?? "");

  const ileri = async () => { try { goster(await S.duello("status", { match_id: macId.current })); } catch (e: any) { hataGoster(e.message, ileri); } };

  const sag = `Sen ${toplam.ben} · ${rakip} ${toplam.rakip}`;
  if (asama === "yukleniyor") return <Kart><Yazi>Bağlanıyor…</Yazi></Kart>;
  if (asama === "hata") return <HataEkrani mesaj={hata} yeniden={yeniden.current} onMenu={onMenu} />;
  if (asama === "profil") return <Profil onTamam={giris} onMenu={onMenu} />;
  if (asama === "bekle") {
    return (
      <Kart>
        <Baslik boyut={18}>Rakip aranıyor…</Baslik>
        <Yazi soluk testID="bekle-bilgi">
          {bekle?.bot_icin_kalan_ms > 0 ? `${Math.ceil(bekle.bot_icin_kalan_ms / 1000)} sn içinde gerçek rakip bulunamazsa Bot ile oynarsın.` : "Bot hazırlanıyor…"}
        </Yazi>
        <View style={{ height: 10 }} />
        <Dugme testID="vazgec" baslik="Vazgeç" onPress={onMenu} />
      </Kart>
    );
  }
  if (asama === "sayim") {
    return (
      <View>
        <Ust tur={tur} sag={sag} />
        <Kart>
          <Baslik boyut={18}>Tur {tur + 1} · {TUR_ADI(tur)}</Baslik>
          <Yazi soluk>Rakip: <Yazi>{rakip}</Yazi>. Herkes aynı anda başlıyor.</Yazi>
          <Baslik boyut={54}>{sayim}</Baslik>
        </Kart>
      </View>
    );
  }
  if (asama === "gonderiliyor") return <Kart><Yazi>Cevabın gönderiliyor…</Yazi></Kart>;
  if (asama === "rakipBekle") {
    return <View><Ust tur={tur} sag={sag} /><Kart><Baslik boyut={18}>Cevabın alındı</Baslik><Yazi soluk>{rakip} bekleniyor… (en fazla tur süresi kadar)</Yazi></Kart></View>;
  }
  if (asama === "oyna" && veri) {
    const ust = <Ust tur={tur} sag={sag} />;
    return veri.kind === "kelime"
      ? <KelimeTuru key={tur} ust={ust} harfler={veri.payload.letters} sureSn={veri.limit_sec} kalanSn={veri.kalanSn} onBitir={kelimeBitti} />
      : <IslemTuru key={tur} ust={ust} sayilar={veri.payload.nums} hedef={veri.payload.target} sureSn={veri.limit_sec} kalanSn={veri.kalanSn} bonus={false} onBitir={islemBitti} />;
  }
  if (asama === "sonuc" && gorunum) {
    const s = gorunum.sonuclar[tur];
    if (!s) return <Kart><Yazi>Sonuç alınıyor…</Yazi></Kart>;
    const goster_ = (x: string) => (x ? (s.kind === "kelime" ? up(x) : x) : "—");
    return (
      <View>
        <Ust tur={tur} sag={sag} />
        <Kart>
          <Baslik boyut={18}>Tur {tur + 1} sonucu</Baslik>
          <Cizelge ad="" a="Sen" b={rakip} />
          <Cizelge ad={s.kind === "kelime" ? "Kelime" : "İşlem"} a={goster_(s.ben.answer)} b={goster_(s.rakip.answer)} />
          <Cizelge ad="Puan" a={s.ben.score} b={s.rakip.score} />
          <Yazi soluk testID="en-iyi">
            {s.kind === "kelime" ? `Bu harflerle en iyi: ${up(s.best_solution)} (${s.best_score} puan)` : `Hedef ${s.target} · bilgisayarın çözümü: ${s.best_solution} = ${s.target}`}
          </Yazi>
          <View style={{ height: 10 }} />
          <Dugme testID="ileri" birincil buyuk baslik={tur >= 3 ? "Sonucu gör" : "Sonraki tur"} onPress={ileri} />
        </Kart>
      </View>
    );
  }
  if (asama === "son" && gorunum) {
    const k = gorunum.kazanan;
    const baslik = k === "ben" ? "Kazandın! 🏆" : k === "rakip" ? `${rakip} kazandı` : "Berabere";
    const simgeler = gorunum.sonuclar.map((x: any) => (x.ben.score > x.rakip.score ? "🟩" : x.ben.score < x.rakip.score ? "🟥" : "⬜")).join("");
    const paylas = `Hedef Düello\n${simgeler} ${gorunum.toplam.ben}–${gorunum.toplam.rakip}`;
    return (
      <View>
        <Baslik boyut={30}>{baslik}</Baslik>
        <Kart>
          <Baslik>{gorunum.toplam.ben} puan — {rakip} {gorunum.toplam.rakip}</Baslik>
          <Yazi testID="paylas">{paylas}</Yazi>
          <View style={{ height: 10 }} />
          <Sira><Dugme testID="rovans" birincil baslik="Rövanş" onPress={giris} /><Dugme testID="menu" baslik="Menü" onPress={onMenu} /></Sira>
        </Kart>
      </View>
    );
  }
  return null;
}
