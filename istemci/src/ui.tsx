// Tasarım sistemi: ekran iskeleti, tipografi, düğme, 3 boyutlu harf karosu, sayaçlar, animasyonlu parçalar.
import { LinearGradient } from "expo-linear-gradient";
import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  Animated, Easing, FlatList, Image, Modal, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput, TextStyle, useWindowDimensions, View, ViewStyle,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { FONT, Tema, useTema } from "./tema";

export { useTema } from "./tema";
export const up = (s: string) => s.toLocaleUpperCase("tr");
const surucu = Platform.OS !== "web";   // useNativeDriver yalnızca native'de

// ---------- tipografi ----------
type Varyant = "govde" | "kucuk" | "etiket" | "baslik" | "baslikBuyuk" | "dev";
const BOYUT: Record<Varyant, TextStyle> = {
  govde: { fontSize: 16, lineHeight: 23, fontFamily: FONT.orta },
  kucuk: { fontSize: 13, lineHeight: 18, fontFamily: FONT.orta },
  etiket: { fontSize: 12, lineHeight: 16, fontFamily: FONT.kalin, letterSpacing: 1.2 },
  baslik: { fontSize: 20, lineHeight: 26, fontFamily: FONT.kalin },
  baslikBuyuk: { fontSize: 30, lineHeight: 36, fontFamily: FONT.siyah },
  dev: { fontSize: 56, lineHeight: 64, fontFamily: FONT.siyah },
};
export function Metin({ v = "govde", soluk, renk, stil, children, testID, ortala }: { v?: Varyant; soluk?: boolean; renk?: string; stil?: TextStyle; children: React.ReactNode; testID?: string; ortala?: boolean }) {
  const t = useTema();
  return <Text testID={testID} style={[BOYUT[v], { color: renk ?? (soluk ? t.soluk : t.yazi) }, ortala && { textAlign: "center" }, stil]}>{children}</Text>;
}
export const Baslik = ({ children, boyut = "baslik", ortala }: { children: React.ReactNode; boyut?: "baslik" | "baslikBuyuk"; ortala?: boolean }) => <Metin v={boyut} ortala={ortala}>{children}</Metin>;
export const Yazi = ({ children, soluk, stil, testID, ortala }: { children: React.ReactNode; soluk?: boolean; stil?: TextStyle; testID?: string; ortala?: boolean }) =>
  <Metin soluk={soluk} stil={stil} testID={testID} ortala={ortala}>{children}</Metin>;

// ---------- animasyon yardımcıları ----------
/** Açılışta yumuşakça belirir (yukarı kayarak) */
export function Belir({ children, gecikme = 0, stil }: { children: React.ReactNode; gecikme?: number; stil?: ViewStyle }) {
  const a = useRef(new Animated.Value(0)).current;
  useEffect(() => { Animated.timing(a, { toValue: 1, duration: 380, delay: gecikme, easing: Easing.out(Easing.cubic), useNativeDriver: surucu }).start(); }, [a, gecikme]);
  return <Animated.View style={[{ opacity: a, transform: [{ translateY: a.interpolate({ inputRange: [0, 1], outputRange: [14, 0] }) }] }, stil]}>{children}</Animated.View>;
}
/** Yay ile büyüyerek belirir (karo, ödül) */
export function Pop({ children, gecikme = 0, stil }: { children: React.ReactNode; gecikme?: number; stil?: ViewStyle }) {
  const a = useRef(new Animated.Value(0)).current;
  useEffect(() => { Animated.spring(a, { toValue: 1, delay: gecikme, friction: 5, tension: 120, useNativeDriver: surucu }).start(); }, [a, gecikme]);
  return <Animated.View style={[{ opacity: a.interpolate({ inputRange: [0, 0.4], outputRange: [0, 1], extrapolate: "clamp" }), transform: [{ scale: a.interpolate({ inputRange: [0, 1], outputRange: [0.6, 1] }) }] }, stil]}>{children}</Animated.View>;
}
/** Sayıyı 0'dan değere sayarak gösterir */
export function SayiSayaci({ deger, sureMs = 750, v = "dev", renk, testID }: { deger: number; sureMs?: number; v?: Varyant; renk?: string; testID?: string }) {
  const [g, setG] = useState(0);
  useEffect(() => {
    let r = 0; const t0 = Date.now();
    const f = () => { const k = Math.min(1, (Date.now() - t0) / sureMs); setG(Math.round(deger * (1 - Math.pow(1 - k, 3)))); if (k < 1) r = requestAnimationFrame(f); };
    r = requestAnimationFrame(f);
    return () => cancelAnimationFrame(r);
  }, [deger, sureMs]);
  return <Metin v={v} renk={renk} testID={testID}>{g}</Metin>;
}

// ---------- ekran iskeleti ----------
export function Ekran({ children, ust, alt, ortala, kaydir = true }: { children: React.ReactNode; ust?: React.ReactNode; alt?: React.ReactNode; ortala?: boolean; kaydir?: boolean }) {
  const t = useTema();
  const ek = useSafeAreaInsets();
  const icerik = [{ flexGrow: 1, padding: 20, paddingTop: 8, maxWidth: 520, width: "100%" as const, alignSelf: "center" as const }, ortala && { justifyContent: "center" as const }];
  return (
    <View style={{ flex: 1, backgroundColor: t.zemin[0] }}>
      <LinearGradient colors={t.zemin} style={StyleSheet.absoluteFill} />
      <View style={{ flex: 1, paddingTop: ek.top + 10, paddingBottom: ek.bottom }}>
        <View style={{ flex: 1, width: "100%", maxWidth: 520, alignSelf: "center" }}>
          {ust}
          {kaydir
            ? <ScrollView style={{ flex: 1 }} contentContainerStyle={icerik} keyboardShouldPersistTaps="handled" showsVerticalScrollIndicator={false}>{children}</ScrollView>
            : <View style={[{ flex: 1 }, ...icerik.map((x) => x || {})]}>{children}</View>}
          {alt && <View style={{ padding: 16, paddingTop: 8, gap: 8 }}>{alt}</View>}
        </View>
      </View>
    </View>
  );
}

export function Kart({ children, stil, vurgulu }: { children: React.ReactNode; stil?: ViewStyle; vurgulu?: boolean }) {
  const t = useTema();
  return (
    <View style={[{ backgroundColor: t.yuzey, borderColor: vurgulu ? t.vurgu : t.cizgi, borderWidth: vurgulu ? 2 : 1, borderRadius: 20, padding: 16, marginBottom: 14 }, stil]}>{children}</View>
  );
}
export function Sira({ children, ortala, bosluk = 8, stil }: { children: React.ReactNode; ortala?: boolean; bosluk?: number; stil?: ViewStyle }) {
  return <View style={[{ flexDirection: "row", flexWrap: "wrap", gap: bosluk, alignItems: "center", justifyContent: ortala ? "center" : "flex-start" }, stil]}>{children}</View>;
}

// ---------- düğme ----------
export function Dugme({ baslik, onPress, birincil, buyuk, pasif, hayalet, testID, esnek }: { baslik: string; onPress: () => void; birincil?: boolean; buyuk?: boolean; pasif?: boolean; hayalet?: boolean; testID?: string; esnek?: boolean }) {
  const t = useTema();
  const yukseklik = buyuk ? 58 : 46;
  const govde: ViewStyle = hayalet
    ? { backgroundColor: "transparent" }
    : birincil
      ? { backgroundColor: t.vurgu, borderBottomWidth: 4, borderBottomColor: t.vurguAlt }
      : { backgroundColor: t.yuzey2, borderWidth: 1, borderBottomWidth: 3, borderColor: t.cizgi };
  return (
    <Pressable testID={testID} accessibilityRole="button" disabled={pasif} onPress={onPress}
      style={({ pressed }) => [{ height: yukseklik, borderRadius: 16, paddingHorizontal: 18, alignItems: "center", justifyContent: "center", opacity: pasif ? 0.4 : 1 }, govde,
        esnek && { flex: 1 }, pressed && { transform: [{ scale: 0.97 }], opacity: 0.92 }]}>
      <Text style={{ color: birincil ? t.vurguYazi : hayalet ? t.soluk : t.yazi, fontFamily: birincil ? FONT.siyah : FONT.kalin, fontSize: buyuk ? 18 : 16 }}>{baslik}</Text>
    </Pressable>
  );
}

// ---------- harf karosu (3 boyutlu) ----------
export function Karo({ harf, kullanildi, joker, bos, onPress, testID, boyut = "b", pop, secili }: { harf?: string; kullanildi?: boolean; joker?: boolean; bos?: boolean; onPress?: () => void; testID?: string; boyut?: "b" | "o" | "k"; pop?: boolean; secili?: boolean }) {
  const t = useTema();
  const [w, h, f] = boyut === "b" ? [58, 66, 28] : boyut === "o" ? [48, 56, 24] : [40, 48, 20];
  const yuz = bos ? "transparent" : joker ? t.joker : kullanildi ? t.karoKul : t.karo;
  const alt = bos ? t.cizgi : joker ? t.jokerAlt : kullanildi ? t.karoKulAlt : t.karoAlt;
  const k = (
    <Pressable testID={testID} disabled={!onPress || kullanildi} onPress={onPress}
      style={({ pressed }) => [{ width: w, height: h, borderRadius: 12, alignItems: "center", justifyContent: "center", backgroundColor: yuz,
        borderBottomWidth: bos ? 2 : 5, borderBottomColor: alt, borderWidth: bos ? 2 : 0, borderColor: alt, borderStyle: bos ? "dashed" : "solid" },
        secili && { borderWidth: 3, borderColor: t.vurgu, backgroundColor: t.karoSecili, transform: [{ translateY: -4 }] },
        !bos && !kullanildi && { shadowColor: t.golge, shadowOpacity: 0.25, shadowRadius: 6, shadowOffset: { width: 0, height: 3 }, elevation: 3 },
        pressed && { transform: [{ translateY: 3 }], borderBottomWidth: 2 }]}>
      <Text style={{ fontFamily: FONT.siyah, fontSize: f, color: kullanildi ? t.karoKulYazi : t.karoYazi }}>{bos ? "" : joker && !harf ? "★" : up(harf ?? "")}</Text>
    </Pressable>
  );
  return pop ? <Pop>{k}</Pop> : k;
}

// ---------- bildirim, çipler ----------
export function Bildirim({ metin, iyi, testID }: { metin: string; iyi?: boolean; testID?: string }) {
  const t = useTema();
  return (
    <View style={{ minHeight: 40, alignItems: "center", justifyContent: "center" }}>
      {!!metin && (
        <View style={{ backgroundColor: iyi ? t.iyiZemin : t.kotuZemin, borderRadius: 99, paddingVertical: 6, paddingHorizontal: 14 }}>
          <Text testID={testID} style={{ color: iyi ? t.iyi : t.kotu, fontFamily: FONT.kalin, fontSize: 14, textAlign: "center" }}>{metin}</Text>
        </View>
      )}
      {!metin && <Text testID={testID} style={{ height: 0 }}>{""}</Text>}
    </View>
  );
}
export function Cip({ children, renk, testID }: { children: React.ReactNode; renk?: string; testID?: string }) {
  const t = useTema();
  return (
    <View style={{ backgroundColor: t.yuzey2, borderRadius: 99, paddingVertical: 5, paddingHorizontal: 12, borderWidth: 1, borderColor: t.cizgi }}>
      <Text testID={testID} style={{ color: renk ?? t.yazi, fontFamily: FONT.kalin, fontSize: 13 }}>{children}</Text>
    </View>
  );
}
export function Avatar({ ad, boyut = 44, renk, url, emoji }: { ad: string; boyut?: number; renk?: string; url?: string | null; emoji?: string }) {
  const t = useTema();
  const renkler = ["#FF8A5B", "#5BC0EB", "#9BC53D", "#C77DFF", "#FFC857", "#F06C9B"];
  const [hata, setHata] = useState(false);
  let h = 0; for (const c of ad) h = (h * 31 + c.charCodeAt(0)) >>> 0;
  const kap = { width: boyut, height: boyut, borderRadius: boyut / 2, borderWidth: 2, borderColor: t.cizgi, overflow: "hidden" as const };
  if (url && !hata) return <Image testID="avatar-foto" source={{ uri: url }} onError={() => setHata(true)} style={kap} />;   // fotoğraf yüklenemezse baş harfe döner
  return (
    <View style={[kap, { backgroundColor: renk ?? renkler[h % renkler.length], alignItems: "center", justifyContent: "center" }]}>
      {emoji
        ? <Text style={{ fontSize: boyut * 0.5 }}>{emoji}</Text>
        : <Text style={{ fontFamily: FONT.siyah, fontSize: boyut * 0.42, color: "#1B1B2F" }}>{up((ad || "?").trim().charAt(0) || "?")}</Text>}
    </View>
  );
}

// ---------- tur göstergesi + üst çubuk ----------
/** Çizgiyle bağlı numaralı 4 adım: biten dolu mavi, şimdiki büyük mavi, gelecek gri */
export function TurAdimlari({ tur, bitenler = tur }: { tur: number; bitenler?: number }) {
  const t = useTema();
  return (
    <View style={{ flexDirection: "row", alignItems: "center", paddingHorizontal: 6 }}>
      {[0, 1, 2, 3].map((i) => {
        const bitti = i < bitenler, simdi = i === tur && !bitti;
        return (
          <React.Fragment key={i}>
            {i > 0 && <View style={{ flex: 1, height: 3, borderRadius: 2, backgroundColor: i <= bitenler ? t.vurgu : t.cizgi }} />}
            <View style={{ width: simdi ? 34 : 28, height: simdi ? 34 : 28, borderRadius: 17, alignItems: "center", justifyContent: "center",
              backgroundColor: bitti || simdi ? t.vurgu : t.karoKul, borderWidth: simdi ? 3 : 0, borderColor: "#B9C7FF" }}>
              <Text style={{ fontFamily: FONT.siyah, fontSize: simdi ? 15 : 13, color: bitti || simdi ? "#FFFFFF" : t.karoKulYazi }}>{i + 1}</Text>
            </View>
          </React.Fragment>
        );
      })}
    </View>
  );
}
/** Üst çubuk: başlık, oyuncu kartı (Sen | rakip), numaralı tur adımları, "Tur n/4 · Kelime" */
export function UstCubuk({ tur, bitenler, ad, sen, rakip, rakipAd, rakipUrl, rakipBot, baslik }: {
  tur: number; bitenler?: number; ad: string; sen: number; rakip?: number; rakipAd?: string; rakipUrl?: string | null; rakipBot?: boolean; baslik?: string;
}) {
  const t = useTema();
  const puan = (n: number, id?: string, renk?: string) => <Text testID={id} style={{ fontFamily: FONT.siyah, fontSize: 30, lineHeight: 34, color: renk ?? t.yazi }}>{n}</Text>;
  return (
    <View style={{ paddingHorizontal: 16, paddingBottom: 6 }}>
      {!!baslik && <Text style={{ textAlign: "center", fontFamily: FONT.kalin, fontSize: 17, color: t.yazi, marginBottom: 10 }}>{baslik}</Text>}
      <View style={{ flexDirection: "row", alignItems: "center", backgroundColor: t.yuzey, borderRadius: 22, paddingVertical: 10, paddingHorizontal: 12, borderWidth: 1, borderColor: t.cizgi,
        shadowColor: t.golge, shadowOpacity: 0.12, shadowRadius: 10, shadowOffset: { width: 0, height: 4 }, elevation: 2 }}>
        <Avatar ad="Sen" boyut={52} renk={t.vurgu} emoji="🙂" />
        <View style={{ marginLeft: 10, flex: 1 }}>
          <Text style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 13 }}>Sen</Text>
          {puan(sen, "ust-puan", t.vurguMetin)}
        </View>
        {rakip !== undefined && (
          <>
            <View style={{ width: 1, alignSelf: "stretch", backgroundColor: t.cizgi, marginHorizontal: 8 }} />
            <View style={{ flex: 1, alignItems: "flex-end", marginRight: 10 }}>
              <Text numberOfLines={1} style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 13 }}>{rakipAd ?? "Rakip"}</Text>
              {puan(rakip, "ust-rakip")}
            </View>
            <Avatar ad={rakipAd ?? "Rakip"} boyut={52} url={rakipUrl} renk={rakipBot ? t.mercan : undefined} emoji={rakipBot ? "🤖" : undefined} />
          </>
        )}
      </View>
      <View style={{ marginTop: 14 }}><TurAdimlari tur={tur} bitenler={bitenler} /></View>
      <Text testID="ust-tur" style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 14, marginTop: 8, textAlign: "center" }}>Tur {tur + 1}/4 · {ad}</Text>
    </View>
  );
}

// ---------- hedef halkaları, logo ----------
export function Halkalar({ boyut = 220, renk, adet = 4, stil, mutlak }: { boyut?: number; renk?: string; adet?: number; stil?: ViewStyle; mutlak?: boolean }) {
  const t = useTema();
  return (
    <View style={[{ width: boyut, height: boyut, alignItems: "center", justifyContent: "center" }, mutlak && { position: "absolute" }, stil]} pointerEvents="none">
      {Array.from({ length: adet }, (_, i) => {
        const b = boyut * (1 - i * (0.78 / adet));
        return <View key={i} style={{ position: "absolute", width: b, height: b, borderRadius: b / 2, borderWidth: 2, borderColor: renk ?? t.vurgu, opacity: 0.1 + i * 0.1 }} />;
      })}
    </View>
  );
}
export function Logo({ boyut = 1 }: { boyut?: number }) {
  const t = useTema();
  return (
    <View style={{ alignItems: "center" }}>
      <View style={{ width: 80 * boyut, height: 80 * boyut, alignItems: "center", justifyContent: "center" }}>
        <Halkalar boyut={80 * boyut} adet={3} />
        <View style={{ position: "absolute", width: 16 * boyut, height: 16 * boyut, borderRadius: 8 * boyut, backgroundColor: t.vurgu }} />
      </View>
      <Text style={{ fontFamily: FONT.siyah, fontSize: 36 * boyut, color: t.yazi, letterSpacing: 5 * boyut, marginTop: 6 }}>KELİME</Text>
      <Text style={{ fontFamily: FONT.siyah, fontSize: 18 * boyut, color: t.vurguMetin, letterSpacing: 3 * boyut, marginVertical: -2 }}>ve</Text>
      <Text style={{ fontFamily: FONT.siyah, fontSize: 36 * boyut, color: t.yazi, letterSpacing: 5 * boyut }}>İŞLEM</Text>
    </View>
  );
}
/** Büyük geri sayım rakamı, halka içinde (yay ile her saniye vurgulanır) */
export function BuyukRakam({ n, testID }: { n: number; testID?: string }) {
  const t = useTema();
  const a = useRef(new Animated.Value(0)).current;
  useEffect(() => { a.setValue(0); Animated.spring(a, { toValue: 1, friction: 4, tension: 140, useNativeDriver: surucu }).start(); }, [n, a]);
  return (
    <View style={{ width: 240, height: 240, alignItems: "center", justifyContent: "center", alignSelf: "center" }}>
      <Halkalar boyut={240} adet={4} mutlak />
      <Animated.Text testID={testID} style={{ fontFamily: FONT.siyah, fontSize: 110, color: t.vurguMetin, transform: [{ scale: a.interpolate({ inputRange: [0, 1], outputRange: [1.5, 1] }) }] }}>{n}</Animated.Text>
    </View>
  );
}
/** Rakip aranırken yayılan halkalar */
export function Radar() {
  const t = useTema();
  const a = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    const l = Animated.loop(Animated.timing(a, { toValue: 1, duration: 2200, easing: Easing.out(Easing.quad), useNativeDriver: surucu }));
    l.start(); return () => l.stop();
  }, [a]);
  return (
    <View style={{ width: 220, height: 220, alignItems: "center", justifyContent: "center", alignSelf: "center" }}>
      {[0, 0.33, 0.66].map((faz) => {
        const k = Animated.modulo(Animated.add(a, faz), 1);
        return <Animated.View key={faz} style={{ position: "absolute", width: 220, height: 220, borderRadius: 110, borderWidth: 3, borderColor: t.vurgu,
          opacity: k.interpolate({ inputRange: [0, 1], outputRange: [0.7, 0] }), transform: [{ scale: k.interpolate({ inputRange: [0, 1], outputRange: [0.25, 1] }) }] }} />;
      })}
      <View style={{ width: 28, height: 28, borderRadius: 14, backgroundColor: t.vurgu }} />
    </View>
  );
}

// ---------- süre sayacı ----------
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
    const id = setInterval(tick, 200);
    return () => clearInterval(id);
  }, []);
  return { kalanMs, kalanSn: () => Math.max(0, bitis.current - Date.now()) / 1000 };
}
export function SayacCubugu({ kalanMs, sureSn }: { kalanMs: number; sureSn: number }) {
  const t = useTema();
  const acil = kalanMs < 10000, sn = Math.ceil(kalanMs / 1000);
  const mmss = `${String(Math.floor(sn / 60)).padStart(2, "0")}:${String(sn % 60).padStart(2, "0")}`;
  return (
    <View style={{ marginBottom: 12, flexDirection: "row", alignItems: "center", gap: 12 }}>
      <Text style={{ fontSize: 22 }}>⏱</Text>
      <Text testID="sure" style={{ fontFamily: FONT.siyah, fontSize: 26, color: acil ? t.kotu : t.yazi, minWidth: 72, fontVariant: ["tabular-nums"] }}>{mmss}</Text>
      <View style={{ flex: 1, height: 12, backgroundColor: t.cizgi, borderRadius: 99, overflow: "hidden" }}>
        <View style={{ height: "100%", width: `${Math.min(100, (kalanMs / (sureSn * 1000)) * 100)}%`, backgroundColor: acil ? t.kotu : t.vurgu, borderRadius: 99 }} />
      </View>
    </View>
  );
}

// ---------- il seçici (aranabilir tam ekran liste) ----------
export function IlSecici({ iller, secili, onSec }: { iller: string[]; secili: string; onSec: (il: string) => void }) {
  const t = useTema();
  const [acik, setAcik] = useState(false);
  const [ara, setAra] = useState("");
  const filtre = useMemo(() => { const a = ara.toLocaleLowerCase("tr").trim(); return a ? iller.filter((x) => x.toLocaleLowerCase("tr").includes(a)) : iller; }, [iller, ara]);
  return (
    <View>
      <Pressable testID="il-sec" onPress={() => setAcik(true)}
        style={{ height: 54, borderRadius: 16, backgroundColor: t.yuzey2, borderWidth: 1, borderColor: secili ? t.vurgu : t.cizgi, paddingHorizontal: 16, flexDirection: "row", alignItems: "center", justifyContent: "space-between" }}>
        <Text style={{ fontFamily: FONT.kalin, fontSize: 17, color: secili ? t.yazi : t.soluk }}>{secili || "İl seç (isteğe bağlı)"}</Text>
        <Text style={{ color: t.soluk, fontSize: 18 }}>{secili ? "✎" : "▾"}</Text>
      </Pressable>
      <Modal visible={acik} animationType="slide" onRequestClose={() => setAcik(false)}>
        <View style={{ flex: 1, backgroundColor: t.zemin[0], padding: 16, paddingTop: 48 }}>
          <Text style={{ fontFamily: FONT.siyah, fontSize: 24, color: t.yazi, marginBottom: 12 }}>İl seç</Text>
          <TextInput testID="il-ara" value={ara} onChangeText={setAra} placeholder="Ara…" placeholderTextColor={t.soluk} autoCapitalize="none" autoCorrect={false}
            style={{ height: 50, borderRadius: 14, backgroundColor: t.yuzey, borderWidth: 1, borderColor: t.cizgi, color: t.yazi, paddingHorizontal: 14, fontSize: 17, fontFamily: FONT.orta, marginBottom: 10 }} />
          <FlatList data={filtre} keyExtractor={(x) => x} keyboardShouldPersistTaps="handled"
            ListHeaderComponent={<Pressable testID="il-yok" onPress={() => { onSec(""); setAcik(false); }} style={{ paddingVertical: 14 }}><Text style={{ color: t.soluk, fontFamily: FONT.kalin, fontSize: 16 }}>İl seçme</Text></Pressable>}
            renderItem={({ item }) => (
              <Pressable testID={`il-${item}`} onPress={() => { onSec(item); setAcik(false); setAra(""); }}
                style={{ paddingVertical: 14, borderTopWidth: 1, borderTopColor: t.cizgi, flexDirection: "row", justifyContent: "space-between" }}>
                <Text style={{ color: t.yazi, fontFamily: FONT.kalin, fontSize: 17 }}>{item}</Text>
                {item === secili && <Text style={{ color: t.vurguMetin, fontSize: 18 }}>✓</Text>}
              </Pressable>
            )} />
          <View style={{ height: 10 }} />
          <Dugme baslik="Kapat" onPress={() => setAcik(false)} />
        </View>
      </Modal>
    </View>
  );
}

export { Tema };
