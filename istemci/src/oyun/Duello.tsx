// Canlı düello: gerçek rakip aranır, 15 sn içinde bulunamazsa açıkça "Bot" ile oynanır. Durum sunucuda tutulur;
// istemci ~1,2 sn'de bir `status` sorgular (polling), bağlantı kopsa da aynı maça dönülür.
import React, { useCallback, useEffect, useRef, useState } from "react";
import { Text, View } from "react-native";
import * as S from "../sunucu";
import { FONT } from "../tema";
import { IslemSonuc, IslemTuru, KelimeSonuc, KelimeTuru } from "../turlar";
import { Avatar, BuyukRakam, Dugme, Ekran, Metin, Radar, UstCubuk, up, useTema } from "../ui";
import { HataEkrani, Profil, TUR_ADI, Yukleniyor } from "./ortak";
import { OyunSonu, TurSonucu } from "./sonuc";

type Asama = "yukleniyor" | "profil" | "bekle" | "sayim" | "oyna" | "gonderiliyor" | "rakipBekle" | "sonuc" | "son" | "hata";

export function Duello({ onMenu }: { onMenu: () => void }) {
  const t = useTema();
  const [asama, setAsama] = useState<Asama>("yukleniyor");
  const [rakip, setRakip] = useState<{ nick: string; city?: string | null; bot?: boolean }>({ nick: "Rakip" });
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
      setRakip(g.rakip?.nick ? g.rakip : { nick: "Rakip" }); setGorunum(g);
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

  const ust = (bitenler = tur) => <UstCubuk tur={tur} bitenler={bitenler} ad={TUR_ADI(tur)} sen={toplam.ben} rakip={toplam.rakip} rakipAd={rakip.nick} />;
  if (asama === "yukleniyor") return <Yukleniyor />;
  if (asama === "hata") return <HataEkrani mesaj={hata} yeniden={yeniden.current} onMenu={onMenu} />;
  if (asama === "profil") return <Profil onTamam={giris} onMenu={onMenu} />;
  if (asama === "bekle") {
    return (
      <Ekran ortala alt={<Dugme testID="vazgec" hayalet baslik="Vazgeç" onPress={onMenu} />}>
        <View style={{ alignItems: "center", gap: 14 }}>
          <Radar />
          <Metin v="baslikBuyuk">Rakip aranıyor…</Metin>
          <Metin soluk ortala testID="bekle-bilgi">
            {bekle?.bot_icin_kalan_ms > 0 ? `${Math.ceil(bekle.bot_icin_kalan_ms / 1000)} sn içinde gerçek rakip bulunamazsa Bot ile oynarsın.` : "Bot hazırlanıyor…"}
          </Metin>
        </View>
      </Ekran>
    );
  }
  if (asama === "sayim") {
    return (
      <Ekran ust={ust()} ortala>
        <View style={{ alignItems: "center", gap: 14 }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 14, marginBottom: 6 }}>
            <Avatar ad="Sen" boyut={52} />
            <Text style={{ color: t.soluk, fontFamily: FONT.siyah, fontSize: 18 }}>VS</Text>
            <Avatar ad={rakip.nick} boyut={52} />
          </View>
          <Metin v="baslik">Tur {tur + 1} · {TUR_ADI(tur)}</Metin>
          <Metin soluk ortala>Rakip: <Text style={{ color: t.yazi, fontFamily: FONT.kalin }}>{rakip.nick}</Text>. Herkes aynı anda başlıyor.</Metin>
          <BuyukRakam n={sayim} testID="geri-sayim" />
        </View>
      </Ekran>
    );
  }
  if (asama === "gonderiliyor") return <Yukleniyor metin="Cevabın gönderiliyor…" ust={ust()} />;
  if (asama === "rakipBekle") return <Yukleniyor metin={`Cevabın alındı. ${rakip.nick} bekleniyor…`} ust={ust()} />;
  if (asama === "oyna" && veri) {
    return veri.kind === "kelime"
      ? <KelimeTuru key={tur} ust={ust()} harfler={veri.payload.letters} sureSn={veri.limit_sec} kalanSn={veri.kalanSn} onBitir={kelimeBitti} />
      : <IslemTuru key={tur} ust={ust()} sayilar={veri.payload.nums} hedef={veri.payload.target} sureSn={veri.limit_sec} kalanSn={veri.kalanSn} bonus={false} onBitir={islemBitti} />;
  }
  if (asama === "sonuc" && gorunum) {
    const s = gorunum.sonuclar[tur];
    if (!s) return <Yukleniyor metin="Sonuç alınıyor…" ust={ust()} />;
    const ileriBaslik = tur >= 3 ? "Sonucu gör" : "Sonraki tur";
    return s.kind === "kelime"
      ? <TurSonucu ust={ust(tur + 1)} tur={tur} tip="kelime" ileriBaslik={ileriBaslik} onIleri={ileri}
          sen={{ ad: "Sen", puan: s.ben.score, cevap: s.ben.answer }} rakip={{ ad: rakip.nick, puan: s.rakip.score, cevap: s.rakip.answer }}
          enIyi={{ baslik: "BU HARFLERLE EN İYİ", cevap: s.best_solution, kelime: true, ayrinti: `${up(s.best_solution)} (${s.best_score} puan)` }} />
      : <TurSonucu ust={ust(tur + 1)} tur={tur} tip="islem" ileriBaslik={ileriBaslik} onIleri={ileri}
          sen={{ ad: "Sen", puan: s.ben.score, cevap: s.ben.answer }} rakip={{ ad: rakip.nick, puan: s.rakip.score, cevap: s.rakip.answer }}
          enIyi={{ baslik: "BİLGİSAYARIN ÇÖZÜMÜ", cevap: `${s.best_solution} = ${s.target}`, ayrinti: `Hedef ${s.target}` }} />;
  }
  if (asama === "son" && gorunum) {
    const k = gorunum.kazanan as "ben" | "rakip" | "berabere";
    const baslik = k === "ben" ? "Kazandın! 🏆" : k === "rakip" ? `${rakip.nick} kazandı` : "Berabere";
    const turlar = gorunum.sonuclar.map((x: any) => ({ ben: x.ben.score, rakip: x.rakip.score }));
    const simgeler = turlar.map((x: any) => (x.ben > x.rakip ? "🟩" : x.ben < x.rakip ? "🟥" : "⬜")).join("");
    return <OyunSonu kazanan={k} baslik={baslik} sen={gorunum.toplam.ben} rakip={gorunum.toplam.rakip} rakipAd={rakip.nick} turlar={turlar}
      paylasMetni={`Hedef Düello\n${simgeler} ${gorunum.toplam.ben}–${gorunum.toplam.rakip}`} onRovans={giris} onMenu={onMenu} />;
  }
  return null;
}
