// Akışlar arası ortak ekranlar: üst bilgi, oyuncu kartı, hata.
import React, { useEffect, useState } from "react";
import { Text, TextInput, View } from "react-native";
import * as S from "../sunucu";
import { Baslik, Dugme, Kart, Mesaj, Sira, Yazi, useTema } from "../ui";

export const TUR_ADI = (i: number) => (i % 2 === 0 ? "Kelime" : "İşlem");

export function Ust({ tur, sol, sag }: { tur: number; sol?: string; sag: string }) {
  const t = useTema();
  return (
    <View style={{ flexDirection: "row", justifyContent: "space-between", marginBottom: 10 }}>
      <Text testID="ust-tur" style={{ color: t.yazi, fontWeight: "700" }}>{sol ?? `Tur ${tur + 1}/4 · ${TUR_ADI(tur)}`}</Text>
      <Text testID="ust-puan" style={{ color: t.yazi }}>{sag}</Text>
    </View>
  );
}

export function HataEkrani({ mesaj, yeniden, onMenu }: { mesaj: string; yeniden?: () => void; onMenu: () => void }) {
  return (
    <Kart>
      <Baslik boyut={18}>Bağlantı sorunu</Baslik>
      <Yazi>{mesaj}</Yazi>
      <View style={{ height: 10 }} />
      <Sira>
        {yeniden && <Dugme testID="yeniden" birincil baslik="Yeniden dene" onPress={yeniden} />}
        <Dugme testID="menu" baslik="Menü" onPress={onMenu} />
      </Sira>
    </Kart>
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
    <Kart>
      <Baslik boyut={18}>Oyuncu kartı</Baslik>
      <Yazi soluk>Sıralamada görünecek takma ad. İl isteğe bağlı; il ligine katılırsın.</Yazi>
      <View style={{ height: 8 }} />
      <TextInput testID="nick" value={nick} onChangeText={setNick} maxLength={20} placeholder="Takma ad (2–20 harf)" placeholderTextColor={t.soluk}
        style={{ color: t.yazi, borderColor: t.cizgi, borderWidth: 1, borderRadius: 10, padding: 10, fontSize: 16, backgroundColor: t.kart }} />
      <View style={{ height: 8 }} />
      <Yazi soluk>İl (isteğe bağlı)</Yazi>
      <Sira bosluk={6}>
        <Dugme testID="il-yok" baslik={il ? "Seçimi kaldır" : "Seçilmedi"} onPress={() => setIl("")} />
        {iller.map((x) => <Dugme key={x} testID={`il-${x}`} birincil={il === x} baslik={x} onPress={() => setIl(x)} />)}
      </Sira>
      <Mesaj metin={hata} testID="profil-hata" />
      <Sira>
        <Dugme testID="kaydet" birincil baslik="Kaydet ve başla" onPress={kaydet} />
        <Dugme testID="menu" baslik="Menü" onPress={onMenu} />
      </Sira>
    </Kart>
  );
}
