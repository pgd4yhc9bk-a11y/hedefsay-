// Ortak arayüz parçaları: tema, kart, düğme, harf karosu, sayaç.
import React, { useEffect, useRef, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, TextStyle, useColorScheme, View, ViewStyle } from "react-native";

const acik = { bg: "#f6f3ec", kart: "#ffffff", yazi: "#1d2433", soluk: "#6b7385", cizgi: "#e2ddd0", vurgu: "#c8501e", vurguYazi: "#ffffff",
  iyi: "#2e7d4f", kotu: "#b3372e", karo: "#fff7e0", karoCizgi: "#e3c872", karoKullanildi: "#eee9da", joker: "#e9d5ff", jokerCizgi: "#a678d8" };
const koyu = { bg: "#14171f", kart: "#1d222d", yazi: "#eceff5", soluk: "#98a0b3", cizgi: "#2c3342", vurgu: "#f08a4b", vurguYazi: "#1b1005",
  iyi: "#5cc98a", kotu: "#ef7d73", karo: "#2c2a1c", karoCizgi: "#6a5a24", karoKullanildi: "#232734", joker: "#3a2b52", jokerCizgi: "#a678d8" };
export type Tema = typeof acik;
export const useTema = (): Tema => (useColorScheme() === "dark" ? koyu : acik);

export const up = (s: string) => s.toLocaleUpperCase("tr");

export function Sayfa({ children }: { children: React.ReactNode }) {
  const t = useTema();
  return (
    <ScrollView style={{ flex: 1, backgroundColor: t.bg }} contentContainerStyle={{ padding: 16, paddingTop: 40, maxWidth: 560, width: "100%", alignSelf: "center" }}
      keyboardShouldPersistTaps="handled">
      {children}
    </ScrollView>
  );
}

export function Baslik({ children, boyut = 24 }: { children: React.ReactNode; boyut?: number }) {
  const t = useTema();
  return <Text style={{ color: t.yazi, fontSize: boyut, fontWeight: "800", marginBottom: 8 }}>{children}</Text>;
}

export function Yazi({ children, soluk, stil, testID }: { children: React.ReactNode; soluk?: boolean; stil?: TextStyle; testID?: string }) {
  const t = useTema();
  return <Text testID={testID} style={[{ color: soluk ? t.soluk : t.yazi, fontSize: 16, lineHeight: 22 }, stil]}>{children}</Text>;
}

export function Kart({ children, stil }: { children: React.ReactNode; stil?: ViewStyle }) {
  const t = useTema();
  return <View style={[{ backgroundColor: t.kart, borderColor: t.cizgi, borderWidth: 1, borderRadius: 14, padding: 16, marginBottom: 14 }, stil]}>{children}</View>;
}

export function Sira({ children, ortala, bosluk = 8 }: { children: React.ReactNode; ortala?: boolean; bosluk?: number }) {
  return <View style={{ flexDirection: "row", flexWrap: "wrap", gap: bosluk, alignItems: "center", justifyContent: ortala ? "center" : "flex-start" }}>{children}</View>;
}

export function Dugme({ baslik, onPress, birincil, buyuk, pasif, testID }: { baslik: string; onPress: () => void; birincil?: boolean; buyuk?: boolean; pasif?: boolean; testID?: string }) {
  const t = useTema();
  return (
    <Pressable testID={testID} accessibilityRole="button" disabled={pasif} onPress={onPress}
      style={{ backgroundColor: birincil ? t.vurgu : t.kart, borderColor: birincil ? t.vurgu : t.cizgi, borderWidth: 1, borderRadius: 10,
        paddingVertical: buyuk ? 14 : 10, paddingHorizontal: 14, opacity: pasif ? 0.4 : 1, alignItems: "center", marginBottom: buyuk ? 10 : 0,
        alignSelf: buyuk ? "stretch" : "auto" }}>
      <Text style={{ color: birincil ? t.vurguYazi : t.yazi, fontSize: buyuk ? 17 : 16, fontWeight: birincil ? "700" : "400" }}>{baslik}</Text>
    </Pressable>
  );
}

export function Karo({ harf, kullanildi, joker, bos, onPress, testID, kucuk }: { harf?: string; kullanildi?: boolean; joker?: boolean; bos?: boolean; onPress?: () => void; testID?: string; kucuk?: boolean }) {
  const t = useTema();
  const boy = kucuk ? { width: 38, height: 46 } : { width: 44, height: 52 };
  return (
    <Pressable testID={testID} disabled={!onPress || kullanildi} onPress={onPress}
      style={{ ...boy, borderRadius: 9, borderWidth: 2, alignItems: "center", justifyContent: "center",
        backgroundColor: bos ? "transparent" : joker ? t.joker : kullanildi ? t.karoKullanildi : t.karo,
        borderColor: bos ? t.cizgi : joker ? t.jokerCizgi : kullanildi ? t.cizgi : t.karoCizgi, borderStyle: bos ? "dashed" : "solid" }}>
      <Text style={{ fontSize: kucuk ? 20 : 24, fontWeight: "700", color: kullanildi ? t.soluk : t.yazi }}>{bos ? "" : joker && !harf ? "★" : up(harf ?? "")}</Text>
    </Pressable>
  );
}

export function Mesaj({ metin, iyi, testID }: { metin: string; iyi?: boolean; testID?: string }) {
  const t = useTema();
  return <Text testID={testID} style={{ minHeight: 24, textAlign: "center", marginVertical: 4, color: iyi ? t.iyi : t.kotu }}>{metin}</Text>;
}

/** Satır: ad | sen | rakip (rakip verilmezse iki sütun) */
export function Cizelge({ ad, a, b }: { ad: string; a: React.ReactNode; b?: React.ReactNode }) {
  const t = useTema();
  return (
    <View style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 3, gap: 12 }}>
      <Text style={{ color: t.yazi, flex: 1 }}>{ad}</Text>
      <Text style={{ color: t.yazi, fontWeight: "700", minWidth: 70, textAlign: "right" }}>{a}</Text>
      {b !== undefined && <Text style={{ color: t.yazi, fontWeight: "700", minWidth: 70, textAlign: "right" }}>{b}</Text>}
    </View>
  );
}

/** Geri sayım: bitiş anı mount'ta sabitlenir (sunucudan gelen kalan süre dahil); süre bitince onBitti bir kez çağrılır. */
export function useGeriSayim(sureSn: number, kalanSn: number | undefined, onBitti: () => void) {
  const bitis = useRef(Date.now() + (kalanSn ?? sureSn) * 1000);
  const [kalanMs, setKalanMs] = useState(() => Math.max(0, bitis.current - Date.now()));
  const bitti = useRef(onBitti); bitti.current = onBitti;
  const tetiklendi = useRef(false);
  useEffect(() => {
    const tick = () => {
      const k = Math.max(0, bitis.current - Date.now());
      setKalanMs(k);
      if (k <= 0 && !tetiklendi.current) { tetiklendi.current = true; bitti.current(); }
    };
    tick();
    const id = setInterval(tick, 250);
    return () => clearInterval(id);
  }, []);
  return { kalanMs, kalanSn: () => Math.max(0, bitis.current - Date.now()) / 1000 };
}

export function SayacCubugu({ kalanMs, sureSn }: { kalanMs: number; sureSn: number }) {
  const t = useTema();
  return (
    <View>
      <View style={{ height: 8, backgroundColor: t.cizgi, borderRadius: 99, overflow: "hidden", marginBottom: 4 }}>
        <View style={{ height: "100%", width: `${Math.min(100, (kalanMs / (sureSn * 1000)) * 100)}%`, backgroundColor: kalanMs < 10000 ? t.kotu : t.vurgu }} />
      </View>
      <Text testID="sure" style={{ textAlign: "right", color: t.soluk, fontSize: 14 }}>{Math.ceil(kalanMs / 1000)} sn</Text>
    </View>
  );
}

export const stil = StyleSheet.create({ ortala: { alignItems: "center", justifyContent: "center" } });
