import { StatusBar } from "expo-status-bar";
import React, { useState } from "react";
import { View } from "react-native";
import H from "./src/cekirdek";
import { Duello } from "./src/oyun/Duello";
import { Gunluk } from "./src/oyun/Gunluk";
import { Pratik } from "./src/oyun/Pratik";
import * as S from "./src/sunucu";
import { Baslik, Dugme, Kart, Sayfa, Yazi } from "./src/ui";
import { bugun } from "./src/zaman";

type Ekran = "menu" | "pratik" | "gunluk" | "duello";

export default function App() {
  const [ekran, setEkran] = useState<Ekran>("menu");
  const menu = () => setEkran("menu");
  const sunucu = S.hazir();
  return (
    <Sayfa>
      <StatusBar style="auto" />
      {ekran === "menu" && (
        <View>
          <Baslik boyut={36}>Hedef</Baslik>
          <Yazi soluk>Kelime ve işlem düellosu</Yazi>
          <View style={{ height: 16 }} />
          {sunucu && <Dugme testID="menu-canli" birincil buyuk baslik="Canlı düello (gerçek rakip)" onPress={() => setEkran("duello")} />}
          <Dugme testID="menu-pratik" birincil={!sunucu} buyuk baslik={sunucu ? "Pratik — bilgisayara karşı" : "Oyna — bilgisayara karşı (düello)"} onPress={() => setEkran("pratik")} />
          {sunucu && <Dugme testID="menu-gunluk" buyuk baslik={`Günlük mücadele (${bugun()})`} onPress={() => setEkran("gunluk")} />}
          <Kart>
            <Baslik boyut={18}>Kurallar</Baslik>
            <Yazi>4 tur: kelime, işlem, kelime, işlem. Kelime turunda 8 harf + 1 joker (★) ile en uzun sözlük kelimesini kur; işlem turunda 6 sayıyla hedefe ulaş.</Yazi>
          </Kart>
          <Yazi soluk stil={{ fontSize: 12, textAlign: "center" }}>
            Deneme sözlüğü: {H.getDictionarySize()} kelime (geçici). Bu oyunun TV programıyla bağlantısı yoktur.
          </Yazi>
        </View>
      )}
      {ekran === "pratik" && <Pratik onMenu={menu} />}
      {ekran === "gunluk" && <Gunluk onMenu={menu} />}
      {ekran === "duello" && <Duello onMenu={menu} />}
    </Sayfa>
  );
}
