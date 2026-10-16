// Tur sonucu, oyun sonu, sıralama ve paylaşım ekranları.
import React, { useEffect, useRef, useState } from "react";
import { Platform, Share, Text, View } from "react-native";
import H from "../cekirdek";
import { FONT } from "../tema";
import { Avatar, Belir, Dugme, Ekran, Karo, Kart, Metin, Pop, SayiSayaci, Sira, up, useTema } from "../ui";

export async function paylas(metin: string): Promise<boolean> {
  try {
    if (Platform.OS === "web") {
      const n = (globalThis as any).navigator;
      if (n?.share) { await n.share({ text: metin }); return false; }
      await n?.clipboard?.writeText(metin); return true;
    }
    await Share.share({ message: metin });
  } catch { /* kullanıcı vazgeçti */ }
  return false;
}

/** İşlem cevabını parantezsiz adımlar olarak gösterir: "30 × 2 = 60" */
function Adimlar({ ifade, boyut = 15, ortala = true }: { ifade: string; boyut?: number; ortala?: boolean }) {
  const t = useTema();
  const st = H.expressionSteps(ifade);
  const satirlar = st && st.length ? st.map(H.stepText) : [ifade];
  return (
    <View style={{ alignItems: ortala ? "center" : "flex-start" }}>
      {satirlar.map((x, i) => (
        <Text key={i} style={{ color: i === satirlar.length - 1 ? t.yazi : t.soluk, fontFamily: i === satirlar.length - 1 ? FONT.siyah : FONT.kalin, fontSize: boyut }}>{x}</Text>
      ))}
    </View>
  );
}

function Cevap({ tip, cevap }: { tip: "kelime" | "islem"; cevap: string; deger?: number | null }) {
  const t = useTema();
  if (!cevap) return <Text style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 15 }}>—</Text>;
  if (tip === "kelime") return <Sira ortala bosluk={3}>{up(cevap).split("").map((c, i) => <Karo key={i} boyut="k" harf={c.toLocaleLowerCase("tr")} />)}</Sira>;
  return <Adimlar ifade={cevap} />;
}

/** Rakip adı: yapay zekâ ise her zaman açıkça etiketlenir */
export const rakipAdi = (r: { nick: string; bot?: boolean }) => (r.bot ? `🤖 ${r.nick}` : r.nick);

export interface TarafSonuc { ad: string; puan: number; cevap: string; deger?: number | null; bot?: boolean }

export function TurSonucu({ ust, tur, tip, sen, rakip, enIyi, onIleri, ileriBaslik, ek, otomatikSn }: {
  ust: React.ReactNode; tur: number; tip: "kelime" | "islem"; sen: TarafSonuc; rakip?: TarafSonuc;
  enIyi: { baslik: string; cevap: string; ayrinti: string; kelime?: boolean }; onIleri: () => void; ileriBaslik: string; ek?: React.ReactNode;
  otomatikSn?: number;   // verilirse bu süre sonunda kendiliğinden ilerler (düello: tur arası beklemeyi kısaltır)
}) {
  const t = useTema();
  const [kalan, setKalan] = useState(otomatikSn ?? 0);
  const ilerledi = useRef(false);
  const ileri = () => { if (ilerledi.current) return; ilerledi.current = true; onIleri(); };
  useEffect(() => {
    if (!otomatikSn) return;
    const id = setInterval(() => setKalan((k) => k - 1), 1000);
    return () => clearInterval(id);
  }, [otomatikSn]);
  useEffect(() => { if (otomatikSn && kalan <= 0) ileri(); /* eslint-disable-next-line react-hooks/exhaustive-deps */ }, [kalan]);
  const kazanSen = rakip ? sen.puan > rakip.puan : false, kazanRakip = rakip ? rakip.puan > sen.puan : false;
  const taraf = (x: TarafSonuc, kazandi: boolean, benMi: boolean) => (
    <View style={{ flex: 1, alignItems: "center", paddingVertical: 14, paddingHorizontal: 8, borderRadius: 18, borderWidth: kazandi ? 2 : 1, borderColor: kazandi ? t.vurgu : t.cizgi, backgroundColor: kazandi ? t.iyiZemin : "transparent" }}>
      <Avatar ad={benMi ? "Sen" : x.ad} boyut={40} />
      <Text numberOfLines={1} style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 13, marginTop: 6 }}>{benMi ? "Sen" : rakipAdi({ nick: x.ad, bot: x.bot })}</Text>
      {!benMi && x.bot && <Text style={{ color: t.soluk, fontFamily: FONT.orta, fontSize: 11 }}>Yapay zekâ</Text>}
      <SayiSayaci deger={x.puan} v="dev" renk={kazandi ? t.iyi : t.yazi} />
      <View style={{ minHeight: 56, justifyContent: "center" }}><Cevap tip={tip} cevap={x.cevap} deger={x.deger} /></View>
    </View>
  );
  return (
    <Ekran ust={ust} alt={<Dugme testID="ileri" birincil buyuk baslik={otomatikSn && kalan > 0 ? `${ileriBaslik} (${kalan})` : ileriBaslik} onPress={ileri} />}>
      <Belir>
        <Metin v="baslik" ortala stil={{ marginBottom: 14 }}>Tur {tur + 1} sonucu</Metin>
        {rakip
          ? <Sira bosluk={10} stil={{ flexWrap: "nowrap", alignItems: "stretch" }}>{taraf(sen, kazanSen, true)}{taraf(rakip, kazanRakip, false)}</Sira>
          : <View style={{ alignItems: "center", paddingVertical: 10 }}><SayiSayaci deger={sen.puan} renk={t.vurguMetin} /><Metin v="etiket" soluk>PUAN</Metin><View style={{ height: 14 }} /><Cevap tip={tip} cevap={sen.cevap} deger={sen.deger} /></View>}
      </Belir>
      <Belir gecikme={150}>
        <Kart stil={{ marginTop: 16 }}>
          <View testID="en-iyi">
            <Metin v="etiket" soluk stil={{ marginBottom: 8 }}>{enIyi.baslik}</Metin>
            {enIyi.kelime
              ? <Sira bosluk={4}>{up(enIyi.cevap).split("").map((c, i) => <Karo key={i} boyut="k" harf={c.toLocaleLowerCase("tr")} />)}</Sira>
              : <Adimlar ifade={enIyi.cevap} boyut={17} ortala={false} />}
            <Text style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 14, marginTop: 8 }}>{enIyi.ayrinti}</Text>
          </View>
        </Kart>
        {ek}
      </Belir>
    </Ekran>
  );
}

export function Siralama({ gen, il }: { gen: { rank: number; nick: string; city: string | null; total: number }[]; il: { city: string; total: number; players: number }[] }) {
  const t = useTema();
  const madalya = (r: number) => (r === 1 ? "🥇" : r === 2 ? "🥈" : r === 3 ? "🥉" : String(r));
  const satir = (anahtar: string | number, sol: React.ReactNode, puan: number, vurgu?: boolean) => (
    <View key={anahtar} style={{ flexDirection: "row", alignItems: "center", paddingVertical: 10, borderTopWidth: 1, borderTopColor: t.cizgi, gap: 10 }}>
      {sol}<Text style={{ color: vurgu ? t.vurguMetin : t.yazi, fontFamily: FONT.siyah, fontSize: 18 }}>{puan}</Text>
    </View>
  );
  return (
    <>
      <Kart>
        <Metin v="baslik" stil={{ marginBottom: 6 }}>Bugünün sıralaması</Metin>
        {gen.length ? gen.map((x) => satir(x.rank, <Text style={{ flex: 1, color: t.yazi, fontFamily: FONT.kalin, fontSize: 16 }}>{x.rank}. {x.nick}{x.city ? <Text style={{ color: t.soluk }}> ({x.city})</Text> : null}</Text>, x.total, x.rank === 1))
          : <Metin soluk>Henüz kimse bitirmedi.</Metin>}
      </Kart>
      <Kart>
        <Metin v="baslik" stil={{ marginBottom: 6 }}>İl ligi (bu hafta)</Metin>
        {il.length ? il.map((x, i) => satir(x.city, <Text style={{ flex: 1, color: t.yazi, fontFamily: FONT.kalin, fontSize: 16 }}>{i + 1}. {x.city} <Text style={{ color: t.soluk }}>({x.players} oyuncu)</Text></Text>, x.total, i === 0))
          : <Metin soluk>Henüz il verisi yok.</Metin>}
      </Kart>
    </>
  );
}

export interface TurOzeti { ben: number; rakip?: number; simge?: string }

export function OyunSonu({ kazanan, baslik, sen, rakip, rakipAd, rakipBot, turlar, paylasMetni, onRovans, onMenu, ek }: {
  kazanan: "ben" | "rakip" | "berabere" | "gunluk"; baslik: string; sen: number; rakip?: number; rakipAd?: string; rakipBot?: boolean; turlar: TurOzeti[];
  paylasMetni: string; onRovans?: () => void; onMenu: () => void; ek?: React.ReactNode;
}) {
  const t = useTema();
  const [kopyalandi, setKopyalandi] = useState(false);
  const emoji = kazanan === "ben" ? "🏆" : kazanan === "rakip" ? "💪" : kazanan === "berabere" ? "🤝" : "🎯";
  const renk = kazanan === "ben" || kazanan === "gunluk" ? t.vurguMetin : t.yazi;
  return (
    <Ekran alt={<>
      {onRovans && <Dugme testID="rovans" birincil buyuk baslik="Rövanş" onPress={onRovans} />}
      <Dugme testID="menu" buyuk birincil={!onRovans} baslik="Menü" onPress={onMenu} />
    </>}>
      <View style={{ alignItems: "center", paddingTop: 8 }}>
        <Pop><Text style={{ fontSize: 76 }}>{emoji}</Text></Pop>
        <Belir gecikme={120}><Text style={{ fontFamily: FONT.siyah, fontSize: 32, color: renk, textAlign: "center", marginTop: 4 }}>{baslik}</Text></Belir>
        <View style={{ flexDirection: "row", alignItems: "baseline", gap: 12, marginTop: 6 }}>
          <SayiSayaci deger={sen} renk={renk} />
          {rakip !== undefined && <><Text style={{ color: t.soluk, fontFamily: FONT.siyah, fontSize: 32 }}>–</Text><SayiSayaci deger={rakip} renk={t.soluk} /></>}
        </View>
        <Metin v="etiket" soluk>{rakip !== undefined ? `SEN · ${rakipBot ? "🤖 " : ""}${(rakipAd ?? "RAKİP").toLocaleUpperCase("tr")}${rakipBot ? " (YAPAY ZEKÂ)" : ""}` : "PUAN"}</Metin>
      </View>
      <Belir gecikme={250} stil={{ marginTop: 18 }}>
        <Sira ortala bosluk={8}>
          {turlar.map((x, i) => {
            const galip = x.rakip === undefined ? null : x.ben > x.rakip ? "ben" : x.ben < x.rakip ? "rakip" : "es";
            const zemin = galip === "ben" ? t.iyiZemin : galip === "rakip" ? t.kotuZemin : t.yuzey2;
            const yazi = galip === "ben" ? t.iyi : galip === "rakip" ? t.kotu : t.yazi;
            return (
              <View key={i} style={{ width: 74, paddingVertical: 10, borderRadius: 14, alignItems: "center", backgroundColor: zemin, borderWidth: 1, borderColor: t.cizgi }}>
                <Text style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 11 }}>TUR {i + 1}</Text>
                <Text style={{ color: yazi, fontFamily: FONT.siyah, fontSize: 18 }}>{x.rakip !== undefined ? `${x.ben}–${x.rakip}` : `${x.simge ?? ""} ${x.ben}`}</Text>
              </View>
            );
          })}
        </Sira>
      </Belir>
      <Belir gecikme={350} stil={{ marginTop: 18 }}>
        <Kart>
          <Text testID="paylas" style={{ color: t.yazi, fontFamily: FONT.kalin, fontSize: 16, lineHeight: 24 }}>{paylasMetni}</Text>
          <View style={{ height: 10 }} />
          <Dugme testID="paylas-dugme" baslik={kopyalandi ? "Kopyalandı ✓" : "Sonucu paylaş"} onPress={async () => { if (await paylas(paylasMetni)) setKopyalandi(true); }} />
        </Kart>
        {ek}
      </Belir>
    </Ekran>
  );
}
