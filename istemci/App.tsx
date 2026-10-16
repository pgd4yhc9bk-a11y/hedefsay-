import { Nunito_600SemiBold, Nunito_800ExtraBold, Nunito_900Black, useFonts } from "@expo-google-fonts/nunito";
import { LinearGradient } from "expo-linear-gradient";
import { StatusBar } from "expo-status-bar";
import React, { useState } from "react";
import { Modal, Pressable, Text, View } from "react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import H from "./src/cekirdek";
import { Duello } from "./src/oyun/Duello";
import { Gunluk } from "./src/oyun/Gunluk";
import { Profilim } from "./src/oyun/ortak";
import { Pratik } from "./src/oyun/Pratik";
import * as S from "./src/sunucu";
import { FONT } from "./src/tema";
import { Belir, Dugme, Ekran, Karo, Kart, Metin, Sira, useTema } from "./src/ui";
import { bugun } from "./src/zaman";

type Ekranlar = "menu" | "pratik" | "gunluk" | "duello" | "profilim";

function ModKarti({ baslik, alt, ikon, onPress, renk, dugme, testID }: { baslik: string; alt: string; ikon: string; onPress: () => void; renk: "mavi" | "sari" | "acik"; dugme: string; testID: string }) {
  const t = useTema();
  const mavi = renk === "mavi", sari = renk === "sari";
  const zemin = mavi ? t.vurgu : sari ? t.sari : t.yuzey;
  const kenar = mavi ? t.vurguAlt : sari ? t.sariAlt : t.cizgi;
  const yazi = mavi ? "#FFFFFF" : t.yazi;
  const pill = mavi ? t.mercan : t.vurgu;
  return (
    <Pressable testID={testID} accessibilityRole="button" onPress={onPress}
      style={({ pressed }) => [{ borderRadius: 26, marginBottom: 14, borderWidth: renk === "acik" ? 1 : 0, borderBottomWidth: 6, borderColor: kenar, backgroundColor: zemin,
        shadowColor: t.golge, shadowOpacity: 0.18, shadowRadius: 12, shadowOffset: { width: 0, height: 6 }, elevation: 3 }, pressed && { transform: [{ scale: 0.98 }] }]}>
      <View style={{ flexDirection: "row", alignItems: "center", gap: 14, padding: 18 }}>
        <View style={{ flex: 1 }}>
          <Text style={{ fontFamily: FONT.siyah, fontSize: 22, color: yazi }}>{baslik}</Text>
          <Text style={{ fontFamily: FONT.kalin, fontSize: 14, color: mavi ? "rgba(255,255,255,0.85)" : t.soluk, marginTop: 2, marginBottom: 12 }}>{alt}</Text>
          <View style={{ alignSelf: "flex-start", backgroundColor: pill, borderRadius: 999, paddingHorizontal: 18, paddingVertical: 8, borderBottomWidth: 3, borderColor: "rgba(0,0,0,0.18)" }}>
            <Text style={{ fontFamily: FONT.siyah, fontSize: 15, color: "#FFFFFF" }}>{dugme} ›</Text>
          </View>
        </View>
        <Text style={{ fontSize: 58 }}>{ikon}</Text>
      </View>
    </Pressable>
  );
}

function Afis() {
  const t = useTema();
  const kar = (harf: string, renk: string, ust: number, yan: Record<string, number>, aci: string) => (
    <View style={{ position: "absolute", top: ust, ...yan, transform: [{ rotate: aci }] }}>
      <View style={{ width: 40, height: 40, borderRadius: 11, backgroundColor: renk, alignItems: "center", justifyContent: "center", borderBottomWidth: 4, borderColor: "rgba(0,0,0,0.2)" }}>
        <Text style={{ fontFamily: FONT.siyah, fontSize: 21, color: renk === t.sari ? t.yazi : "#FFFFFF" }}>{harf}</Text>
      </View>
    </View>
  );
  const harfler = [["K", t.vurgu], ["E", t.mercan], ["L", t.sari], ["İ", t.vurgu], ["M", t.mercan], ["E", t.iyi]] as const;
  return (
    <View style={{ alignItems: "center", paddingVertical: 8, marginBottom: 14, alignSelf: "stretch" }}>
      {kar("A", t.mercan, 0, { left: 6 }, "-12deg")}{kar("3", t.vurgu, 34, { left: 0 }, "8deg")}
      {kar("+", t.iyi, 4, { right: 8 }, "10deg")}{kar("★", t.sari, 38, { right: 2 }, "-8deg")}
      <Sira bosluk={3} ortala>
        {harfler.map(([c, r], i) => (
          <View key={i} style={{ width: 34, height: 44, borderRadius: 9, backgroundColor: r, alignItems: "center", justifyContent: "center", borderBottomWidth: 4, borderColor: "rgba(0,0,0,0.2)" }}>
            <Text style={{ fontFamily: FONT.siyah, fontSize: 24, color: r === t.sari ? t.yazi : "#FFFFFF" }}>{c}</Text>
          </View>
        ))}
      </Sira>
      <Text style={{ fontFamily: FONT.siyah, fontSize: 22, color: t.mercan, marginVertical: 2 }}>ve</Text>
      <Sira bosluk={3} ortala>
        {"İŞLEM".split("").map((c, i) => (
          <View key={i} style={{ width: 34, height: 44, borderRadius: 9, backgroundColor: [t.sari, t.vurgu, t.mercan, t.iyi, t.vurgu][i], alignItems: "center", justifyContent: "center", borderBottomWidth: 4, borderColor: "rgba(0,0,0,0.2)" }}>
            <Text style={{ fontFamily: FONT.siyah, fontSize: 24, color: i === 0 ? t.yazi : "#FFFFFF" }}>{c}</Text>
          </View>
        ))}
      </Sira>
    </View>
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
        <Afis />
        <Text style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 15, marginTop: 2 }}>Kelimeni kur, işlemini yap, düelloyu kazan!</Text>
      </Belir>
      <Belir gecikme={120}>
        {sunucu && <ModKarti testID="menu-canli" renk="mavi" dugme="Rakip bul" ikon="⚔️" baslik="Canlı düello" alt="Gerçek rakiple, 4 tur" onPress={() => git("duello")} />}
        {sunucu && <ModKarti testID="menu-gunluk" renk="sari" dugme="Başla" ikon="📅" baslik="Günlük mücadele" alt={`${bugun()} · herkese aynı bulmaca`} onPress={() => git("gunluk")} />}
        <ModKarti testID="menu-pratik" renk={sunucu ? "acik" : "mavi"} dugme="Başla" ikon="🤖" baslik={sunucu ? "Pratik" : "Oyna"} alt="Bilgisayara karşı · çevrimdışı" onPress={() => git("pratik")} />
      </Belir>
      <Belir gecikme={240}>
        <Dugme testID="kurallar" hayalet baslik="Nasıl oynanır?" onPress={() => setKurallar(true)} />
        {sunucu && <View style={{ marginTop: 6 }}><Dugme testID="menu-profilim" buyuk baslik="👤  Profilim ve arkadaşlar" onPress={() => git("profilim")} /></View>}
        <Text style={{ color: t.soluk, fontFamily: FONT.orta, fontSize: 12, textAlign: "center", marginTop: 14, lineHeight: 18 }}>
          Sözlük: {H.getDictionarySize().toLocaleString("tr")} kelime · kaynak: VikiSözlük (CC BY-SA).{"\n"}Bu oyunun TV programıyla bağlantısı yoktur.
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
      {ekran === "profilim" && <Profilim onMenu={menu} />}
    </SafeAreaProvider>
  );
}
