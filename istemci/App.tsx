import { Nunito_600SemiBold, Nunito_800ExtraBold, Nunito_900Black, useFonts } from "@expo-google-fonts/nunito";
import { LinearGradient } from "expo-linear-gradient";
import { StatusBar } from "expo-status-bar";
import React, { useState } from "react";
import { Modal, Pressable, Text, View } from "react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import H from "./src/cekirdek";
import { Duello } from "./src/oyun/Duello";
import { Gunluk } from "./src/oyun/Gunluk";
import { Pratik } from "./src/oyun/Pratik";
import * as S from "./src/sunucu";
import { FONT } from "./src/tema";
import { Belir, Dugme, Ekran, Karo, Kart, Logo, Metin, Sira, useTema } from "./src/ui";
import { bugun } from "./src/zaman";

type Ekranlar = "menu" | "pratik" | "gunluk" | "duello";

function ModKarti({ baslik, alt, ikon, onPress, vurgulu, testID }: { baslik: string; alt: string; ikon: string; onPress: () => void; vurgulu?: boolean; testID: string }) {
  const t = useTema();
  const icerik = (
    <View style={{ flexDirection: "row", alignItems: "center", gap: 14, padding: 18 }}>
      <View style={{ width: 52, height: 52, borderRadius: 16, alignItems: "center", justifyContent: "center", backgroundColor: vurgulu ? "rgba(29,19,0,0.14)" : t.yuzey2 }}>
        <Text style={{ fontSize: 26 }}>{ikon}</Text>
      </View>
      <View style={{ flex: 1 }}>
        <Text style={{ fontFamily: FONT.siyah, fontSize: 20, color: vurgulu ? t.vurguYazi : t.yazi }}>{baslik}</Text>
        <Text style={{ fontFamily: FONT.orta, fontSize: 14, color: vurgulu ? "rgba(29,19,0,0.75)" : t.soluk, marginTop: 2 }}>{alt}</Text>
      </View>
      <Text style={{ fontFamily: FONT.siyah, fontSize: 26, color: vurgulu ? t.vurguYazi : t.soluk }}>›</Text>
    </View>
  );
  return (
    <Pressable testID={testID} accessibilityRole="button" onPress={onPress}
      style={({ pressed }) => [{ borderRadius: 22, marginBottom: 12, overflow: "hidden", borderWidth: vurgulu ? 0 : 1, borderBottomWidth: vurgulu ? 5 : 3, borderColor: vurgulu ? t.vurguAlt : t.cizgi,
        backgroundColor: vurgulu ? t.vurgu : t.yuzey }, pressed && { transform: [{ scale: 0.98 }] }]}>
      {vurgulu ? <LinearGradient colors={["#FFC857", "#FFA620"]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}>{icerik}</LinearGradient> : icerik}
    </Pressable>
  );
}

function Kurallar({ acik, kapat }: { acik: boolean; kapat: () => void }) {
  const t = useTema();
  return (
    <Modal visible={acik} animationType="slide" transparent onRequestClose={kapat}>
      <View style={{ flex: 1, justifyContent: "flex-end", backgroundColor: "rgba(0,0,0,0.55)" }}>
        <View style={{ backgroundColor: t.zemin[1], borderTopLeftRadius: 28, borderTopRightRadius: 28, padding: 22, paddingBottom: 30, maxWidth: 520, width: "100%", alignSelf: "center" }}>
          <Metin v="baslikBuyuk" stil={{ marginBottom: 14 }}>Nasıl oynanır?</Metin>
          <Sira bosluk={4} stil={{ marginBottom: 6 }}>{"KELİME".split("").map((c, i) => <Karo key={i} boyut="k" harf={c.toLocaleLowerCase("tr")} />)}</Sira>
          <Metin soluk>8 harf ve 1 joker (★) verilir. Harflere dokunup en uzun geçerli Türkçe kelimeyi kur. Jokersiz kelime +3 puan alır.</Metin>
          <View style={{ height: 16 }} />
          <Sira bosluk={4} stil={{ marginBottom: 6 }}>{["7", "3", "8", "90"].map((c, i) => <Karo key={i} boyut="k" harf={c} />)}</Sira>
          <Metin soluk>6 sayıyla dört işlemi kullanarak hedefe ulaş. Her sayı bir kez; çıkarma ve bölme sonucu pozitif tam sayı olmalı. Tam isabet 10 puan.</Metin>
          <View style={{ height: 16 }} />
          <Metin soluk>4 tur: kelime, işlem, kelime, işlem. Düelloda iki oyuncu aynı bulmacayı aynı anda çözer; rakip bulunamazsa açıkça “Bot” ile oynarsın.</Metin>
          <View style={{ height: 20 }} />
          <Dugme testID="kurallar-kapat" birincil buyuk baslik="Anladım" onPress={kapat} />
        </View>
      </View>
    </Modal>
  );
}

function Menu({ git }: { git: (e: Ekranlar) => void }) {
  const t = useTema();
  const [kurallar, setKurallar] = useState(false);
  const sunucu = S.hazir();
  return (
    <Ekran ortala>
      <Belir stil={{ alignItems: "center", marginBottom: 26 }}>
        <Logo />
        <Text style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 15, marginTop: 8 }}>Kelime ve işlem düellosu</Text>
      </Belir>
      <Belir gecikme={120}>
        {sunucu && <ModKarti testID="menu-canli" vurgulu ikon="⚔️" baslik="Canlı düello" alt="Gerçek rakiple, 4 tur" onPress={() => git("duello")} />}
        <ModKarti testID="menu-pratik" vurgulu={!sunucu} ikon="🤖" baslik={sunucu ? "Pratik" : "Oyna"} alt="Bilgisayara karşı · çevrimdışı" onPress={() => git("pratik")} />
        {sunucu && <ModKarti testID="menu-gunluk" ikon="📅" baslik="Günlük mücadele" alt={`${bugun()} · herkese aynı bulmaca`} onPress={() => git("gunluk")} />}
      </Belir>
      <Belir gecikme={240}>
        <Dugme testID="kurallar" hayalet baslik="Nasıl oynanır?" onPress={() => setKurallar(true)} />
        <Text style={{ color: t.soluk, fontFamily: FONT.orta, fontSize: 12, textAlign: "center", marginTop: 14, lineHeight: 18 }}>
          Deneme sözlüğü: {H.getDictionarySize()} kelime (geçici).{"\n"}Bu oyunun TV programıyla bağlantısı yoktur.
        </Text>
      </Belir>
      <Kurallar acik={kurallar} kapat={() => setKurallar(false)} />
    </Ekran>
  );
}

export default function App() {
  const [yuklendi] = useFonts({ Nunito_600SemiBold, Nunito_800ExtraBold, Nunito_900Black });
  const [ekran, setEkran] = useState<Ekranlar>("menu");
  const t = useTema();
  const menu = () => setEkran("menu");
  if (!yuklendi) return <View style={{ flex: 1, backgroundColor: t.zemin[0] }} />;
  return (
    <SafeAreaProvider>
      <StatusBar style={t.ad === "koyu" ? "light" : "dark"} />
      {ekran === "menu" && <Menu git={setEkran} />}
      {ekran === "pratik" && <Pratik onMenu={menu} />}
      {ekran === "gunluk" && <Gunluk onMenu={menu} />}
      {ekran === "duello" && <Duello onMenu={menu} />}
    </SafeAreaProvider>
  );
}
