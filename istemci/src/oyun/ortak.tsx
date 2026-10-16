// Akışlar arası ortak ekranlar: tur girişi, yükleniyor, hata, oyuncu kartı.
import React, { useEffect, useState } from "react";
import { ActivityIndicator, Text, TextInput, View } from "react-native";
import * as S from "../sunucu";
import { FONT } from "../tema";
import { Dugme, Ekran, IlSecici, Karo, Kart, Logo, Metin, Pop, Bildirim, Sira, useTema } from "../ui";

export const TUR_ADI = (i: number) => (i % 2 === 0 ? "Kelime" : "İşlem");

export function Yukleniyor({ metin = "Bağlanıyor…", ust }: { metin?: string; ust?: React.ReactNode }) {
  const t = useTema();
  return (
    <Ekran ust={ust} ortala>
      <View style={{ alignItems: "center", gap: 16 }}>
        <ActivityIndicator size="large" color={t.vurgu} />
        <Text style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 17, textAlign: "center" }}>{metin}</Text>
      </View>
    </Ekran>
  );
}

export function HataEkrani({ mesaj, yeniden, onMenu }: { mesaj: string; yeniden?: () => void; onMenu: () => void }) {
  return (
    <Ekran ortala alt={<>
      {yeniden && <Dugme testID="yeniden" birincil buyuk baslik="Yeniden dene" onPress={yeniden} />}
      <Dugme testID="menu" buyuk baslik="Menü" onPress={onMenu} />
    </>}>
      <View style={{ alignItems: "center", gap: 10 }}>
        <Pop><Text style={{ fontSize: 56 }}>📡</Text></Pop>
        <Metin v="baslik">Bağlantı sorunu</Metin>
        <Metin soluk ortala>{mesaj}</Metin>
      </View>
    </Ekran>
  );
}

/** Tur girişi: ne oynanacağını söyler; "Başla" ile süre başlar */
export function TurGirisi({ ust, tip, aciklama, harfler, onBasla, baslaYazi = "Süreyi başlat" }: { ust: React.ReactNode; tip: "kelime" | "islem"; aciklama: string; harfler?: string[]; onBasla: () => void; baslaYazi?: string }) {
  return (
    <Ekran ust={ust} ortala alt={<Dugme testID="go" birincil buyuk baslik={baslaYazi} onPress={onBasla} />}>
      <View style={{ alignItems: "center", gap: 14 }}>
        <Pop><Karo boyut="b" harf={tip === "kelime" ? "A" : "#"} /></Pop>
        <Metin v="baslikBuyuk">{tip === "kelime" ? "Kelime turu" : "İşlem turu"}</Metin>
        <Metin soluk ortala>{aciklama}</Metin>
        {harfler && <Sira ortala bosluk={6}>{harfler.map((h, i) => <Karo key={i} boyut="o" harf={h} pop />)}<Karo boyut="o" joker /></Sira>}
      </View>
    </Ekran>
  );
}

/** Takma ad + il. Kaydedince onTamam çağrılır. */
export function Profil({ onTamam, onMenu }: { onTamam: () => void; onMenu: () => void }) {
  const t = useTema();
  const [nick, setNick] = useState("");
  const [il, setIl] = useState("");
  const [iller, setIller] = useState<string[]>([]);
  const [hata, setHata] = useState("");
  useEffect(() => { S.iller().then(setIller).catch(() => { /* il listesi alınamazsa il seçmeden devam */ }); }, []);
  const kaydet = () => {
    const n = nick.trim();
    if (n.length < 2 || n.length > 20) { setHata("Takma ad 2–20 karakter olmalı"); return; }
    S.oyuncuKaydet(n, il).then(onTamam).catch((e) => setHata("Kaydedilemedi: " + e.message));
  };
  return (
    <Ekran alt={<>
      <Dugme testID="kaydet" birincil buyuk baslik="Kaydet ve başla" onPress={kaydet} />
      <Dugme testID="menu" hayalet baslik="Menü" onPress={onMenu} />
    </>}>
      <View style={{ alignItems: "center", marginBottom: 20 }}><Logo boyut={0.6} /></View>
      <Metin v="baslikBuyuk">Oyuncu kartı</Metin>
      <Metin soluk stil={{ marginTop: 4, marginBottom: 20 }}>Sıralamada görünecek takma adın. İl seçersen il ligine katılırsın.</Metin>
      <Metin v="etiket" soluk stil={{ marginBottom: 6 }}>TAKMA AD</Metin>
      <TextInput testID="nick" value={nick} onChangeText={setNick} maxLength={20} placeholder="Takma ad (2–20 harf)" placeholderTextColor={t.soluk}
        style={{ height: 54, borderRadius: 16, backgroundColor: t.yuzey2, borderWidth: 1, borderColor: t.cizgi, color: t.yazi, paddingHorizontal: 16, fontSize: 18, fontFamily: FONT.kalin }} />
      <View style={{ height: 18 }} />
      <Metin v="etiket" soluk stil={{ marginBottom: 6 }}>İL</Metin>
      <IlSecici iller={iller} secili={il} onSec={setIl} />
      <Bildirim metin={hata} testID="profil-hata" />
    </Ekran>
  );
}
