// Akışlar arası ortak ekranlar: tur girişi, yükleniyor, hata, oyuncu kartı.
import React, { useEffect, useState } from "react";
import * as ImagePicker from "expo-image-picker";
import { ActivityIndicator, Switch, Text, TextInput, View } from "react-native";
import * as S from "../sunucu";
import { paylas } from "./sonuc";
import { OYUN_ADI } from "../marka";
import { FONT } from "../tema";
import { Avatar, Dugme, Ekran, IlSecici, Karo, Kart, Logo, Metin, Pop, Bildirim, Sira, useTema } from "../ui";

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

/** Fotoğraf seç ve yükle; herkese açık adresi döner (iptalde null) */
async function fotografSec(): Promise<string | null> {
  const r = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ["images"], allowsEditing: true, aspect: [1, 1], quality: 0.5 });
  if (r.canceled || !r.assets?.[0]) return null;
  const a = r.assets[0];
  return S.avatarYukle(a.uri, a.mimeType ?? "image/jpeg");
}

function IzinAnahtari({ deger, onDeger }: { deger: boolean; onDeger: (v: boolean) => void }) {
  const t = useTema();
  return (
    <View style={{ flexDirection: "row", alignItems: "center", gap: 12, marginTop: 6 }}>
      <View style={{ flex: 1 }}>
        <Text style={{ color: t.yazi, fontFamily: FONT.kalin, fontSize: 15 }}>Oyunlarım kayıtlı rakip olarak gösterilsin</Text>
        <Text style={{ color: t.soluk, fontFamily: FONT.orta, fontSize: 12, marginTop: 2 }}>
          Rakip bulunamayan oyunculara, adın ve fotoğrafınla geçmiş bir oyunun “kayıtlı oyun” olarak gösterilebilir. İstediğin zaman kapatabilirsin (Profilim).
        </Text>
      </View>
      <Switch testID="kayit-izni" value={deger} onValueChange={onDeger} trackColor={{ true: t.vurgu, false: t.cizgi }} />
    </View>
  );
}

function FotoAlani({ nick, url, onUrl, hata }: { nick: string; url: string | null; onUrl: (u: string) => void; hata: (m: string) => void }) {
  const [mesgul, setMesgul] = useState(false);
  return (
    <View style={{ flexDirection: "row", alignItems: "center", gap: 14 }}>
      <Avatar ad={nick || "?"} boyut={64} url={url} />
      <Dugme testID="foto-sec" baslik={mesgul ? "Yükleniyor…" : url ? "Fotoğrafı değiştir" : "Fotoğraf ekle (isteğe bağlı)"} pasif={mesgul}
        onPress={async () => {
          setMesgul(true);
          try { const u = await fotografSec(); if (u) onUrl(u); } catch (e: any) { hata("Fotoğraf yüklenemedi: " + e.message); } finally { setMesgul(false); }
        }} />
    </View>
  );
}

/** Takma ad + il + fotoğraf + kayıtlı rakip izni. Kaydedince onTamam çağrılır. */
export function Profil({ onTamam, onMenu }: { onTamam: () => void; onMenu: () => void }) {
  const t = useTema();
  const [nick, setNick] = useState("");
  const [il, setIl] = useState("");
  const [iller, setIller] = useState<string[]>([]);
  const [foto, setFoto] = useState<string | null>(null);
  const [izin, setIzin] = useState(false);
  const [hata, setHata] = useState("");
  useEffect(() => { S.iller().then(setIller).catch(() => { /* il listesi alınamazsa il seçmeden devam */ }); }, []);
  const kaydet = () => {
    const n = nick.trim();
    if (n.length < 2 || n.length > 20) { setHata("Takma ad 2–20 karakter olmalı"); return; }
    S.oyuncuKaydet(n, il, izin, foto).then(onTamam).catch((e) => setHata("Kaydedilemedi: " + e.message));
  };
  return (
    <Ekran alt={<>
      <Dugme testID="kaydet" birincil buyuk baslik="Kaydet ve başla" onPress={kaydet} />
      <Dugme testID="menu" hayalet baslik="Menü" onPress={onMenu} />
    </>}>
      <View style={{ alignItems: "center", marginBottom: 20 }}><Logo boyut={0.6} /></View>
      <Metin v="baslikBuyuk">Oyuncu kartı</Metin>
      <Metin soluk stil={{ marginTop: 4, marginBottom: 20 }}>Sıralamada görünecek takma adın. İl seçersen il ligine katılırsın.</Metin>
      <FotoAlani nick={nick} url={foto} onUrl={setFoto} hata={setHata} />
      <View style={{ height: 18 }} />
      <Metin v="etiket" soluk stil={{ marginBottom: 6 }}>TAKMA AD</Metin>
      <TextInput testID="nick" value={nick} onChangeText={setNick} maxLength={20} placeholder="Takma ad (2–20 harf)" placeholderTextColor={t.soluk}
        style={{ height: 54, borderRadius: 16, backgroundColor: t.yuzey2, borderWidth: 1, borderColor: t.cizgi, color: t.yazi, paddingHorizontal: 16, fontSize: 18, fontFamily: FONT.kalin }} />
      <View style={{ height: 18 }} />
      <Metin v="etiket" soluk stil={{ marginBottom: 6 }}>İL</Metin>
      <IlSecici iller={iller} secili={il} onSec={setIl} />
      <View style={{ height: 14 }} />
      <IzinAnahtari deger={izin} onDeger={setIzin} />
      <Bildirim metin={hata} testID="profil-hata" />
    </Ekran>
  );
}

/** Profilim: fotoğrafı ve kayıtlı rakip iznini sonradan değiştir (izin her zaman geri alınabilir) */
function Arkadaslar() {
  const t = useTema();
  const [v, setV] = useState<{ kod: string; liste: S.Arkadas[] } | null>(null);
  const [kod, setKod] = useState("");
  const [mesaj, setMesaj] = useState<{ m: string; iyi?: boolean }>({ m: "" });
  const [kopya, setKopya] = useState(false);
  const yukle = () => S.arkadaslar().then(setV).catch((e) => setMesaj({ m: e.message }));
  useEffect(() => { yukle(); }, []);
  const islem = (f: () => Promise<unknown>, ok?: string) => f().then(() => { if (ok) setMesaj({ m: ok, iyi: true }); return yukle(); }).catch((e) => setMesaj({ m: e.message }));
  const ekle = () => {
    const k = kod.trim();
    if (k.length < 4) return setMesaj({ m: "Arkadaşının kodunu yaz" });
    S.arkadasEkle(k).then((r) => { setKod(""); setMesaj({ m: r.durum === "arkadas" ? "Artık arkadaşsınız!" : "İstek gönderildi", iyi: true }); return yukle(); }).catch((e) => setMesaj({ m: e.message }));
  };
  const liste = v?.liste ?? [];
  const gelen = liste.filter((a) => a.durum === "gelen"), dost = liste.filter((a) => a.durum === "arkadas"), giden = liste.filter((a) => a.durum === "giden");
  const Satir = ({ a, sag }: { a: S.Arkadas; sag: React.ReactNode }) => (
    <View testID={`arkadas-${a.nick}`} style={{ flexDirection: "row", alignItems: "center", gap: 12, paddingVertical: 8 }}>
      <Avatar ad={a.nick} boyut={44} url={a.avatar_url} />
      <View style={{ flex: 1 }}>
        <Text numberOfLines={1} style={{ color: t.yazi, fontFamily: FONT.siyah, fontSize: 16 }}>{a.nick}</Text>
        <Text style={{ color: t.soluk, fontFamily: FONT.orta, fontSize: 12 }}>{a.city ?? "—"}</Text>
      </View>
      {sag}
    </View>
  );
  const mini = (baslik: string, onPress: () => void, id: string, birincil?: boolean) => <View style={{ minWidth: 76 }}><Dugme testID={id} baslik={baslik} birincil={birincil} onPress={onPress} /></View>;
  return (
    <View style={{ marginTop: 22 }}>
      <Metin v="baslik" stil={{ marginBottom: 10 }}>Arkadaşlar</Metin>
      <Kart vurgulu>
        <Metin v="etiket" soluk>ARKADAŞ KODUN</Metin>
        <View style={{ flexDirection: "row", alignItems: "center", gap: 10, marginTop: 6 }}>
          <Text testID="arkadas-kodum" selectable style={{ flex: 1, color: t.vurguMetin, fontFamily: FONT.siyah, fontSize: 30, letterSpacing: 4 }}>{v?.kod ?? "······"}</Text>
          <View style={{ minWidth: 110 }}>
            <Dugme testID="kod-paylas" baslik={kopya ? "Kopyalandı ✓" : "Paylaş"} onPress={async () => { if (v && (await paylas(`${OYUN_ADI}'nde arkadaş kodum: ${v.kod}`))) { setKopya(true); setTimeout(() => setKopya(false), 1800); } }} />
          </View>
        </View>
        <Text style={{ color: t.soluk, fontFamily: FONT.orta, fontSize: 12, marginTop: 6 }}>Kodunu yalnızca eklemek istediğin kişilerle paylaş.</Text>
      </Kart>
      <Kart>
        <Metin v="etiket" soluk stil={{ marginBottom: 6 }}>KODLA ARKADAŞ EKLE</Metin>
        <View style={{ flexDirection: "row", gap: 10 }}>
          <TextInput testID="kod-gir" value={kod} onChangeText={(x) => setKod(x.toUpperCase())} maxLength={6} autoCapitalize="characters" autoCorrect={false} placeholder="6 haneli kod" placeholderTextColor={t.soluk}
            onSubmitEditing={ekle}
            style={{ flex: 1, minWidth: 0, height: 50, borderRadius: 16, backgroundColor: t.yuzey2, borderWidth: 1, borderColor: t.cizgi, color: t.yazi, paddingHorizontal: 16, fontSize: 18, fontFamily: FONT.kalin, letterSpacing: 2 }} />
          <View style={{ width: 84 }}><Dugme testID="kod-ekle" birincil baslik="Ekle" onPress={ekle} /></View>
        </View>
        <Bildirim metin={mesaj.m} iyi={mesaj.iyi} testID="arkadas-mesaj" />
      </Kart>
      {gelen.length > 0 && (
        <Kart>
          <Metin v="etiket" soluk>GELEN İSTEKLER ({gelen.length})</Metin>
          {gelen.map((a) => <Satir key={a.id} a={a} sag={<View style={{ flexDirection: "row", gap: 8 }}>
            {mini("Kabul", () => islem(() => S.arkadasYanit(a.id, true)), `kabul-${a.nick}`, true)}
            {mini("Reddet", () => islem(() => S.arkadasYanit(a.id, false)), `reddet-${a.nick}`)}
          </View>} />)}
        </Kart>
      )}
      <Kart>
        <Metin v="etiket" soluk>ARKADAŞLARIM ({dost.length})</Metin>
        {dost.length === 0 && <Text style={{ color: t.soluk, fontFamily: FONT.orta, fontSize: 14, marginTop: 6 }}>Henüz arkadaşın yok. Kodunu paylaş ya da arkadaşının kodunu gir.</Text>}
        {dost.map((a) => <Satir key={a.id} a={a} sag={mini("Sil", () => islem(() => S.arkadasSil(a.id)), `sil-${a.nick}`)} />)}
      </Kart>
      {giden.length > 0 && (
        <Kart>
          <Metin v="etiket" soluk>GÖNDERİLEN İSTEKLER</Metin>
          {giden.map((a) => <Satir key={a.id} a={a} sag={mini("Geri çek", () => islem(() => S.arkadasSil(a.id)), `geri-${a.nick}`)} />)}
        </Kart>
      )}
    </View>
  );
}

export function Profilim({ onMenu }: { onMenu: () => void }) {
  const [o, setO] = useState<S.Oyuncu | null | undefined>(undefined);
  const [hata, setHata] = useState("");
  useEffect(() => { S.oyuncu().then(setO).catch((e) => { setHata(e.message); setO(null); }); }, []);
  if (o === undefined) return <Yukleniyor />;
  if (o === null) return <Profil onTamam={() => S.oyuncu().then(setO)} onMenu={onMenu} />;
  const yama = (y: Parameters<typeof S.oyuncuGuncelle>[0]) => S.oyuncuGuncelle(y).then(() => setO({ ...o, ...y })).catch((e) => setHata("Kaydedilemedi: " + e.message));
  return (
    <Ekran alt={<Dugme testID="menu" buyuk birincil baslik="Menü" onPress={onMenu} />}>
      <Metin v="baslikBuyuk" stil={{ marginBottom: 18 }}>Profilim</Metin>
      <FotoAlani nick={o.nick} url={o.avatar_url ?? null} hata={setHata} onUrl={(u) => yama({ avatar_url: u })} />
      <Metin v="baslik" stil={{ marginTop: 16 }}>{o.nick}</Metin>
      <Metin soluk>{o.city ?? "İl seçilmedi"}</Metin>
      <View style={{ height: 14 }} />
      <IzinAnahtari deger={!!o.kayit_izni} onDeger={(v) => yama({ kayit_izni: v })} />
      <Bildirim metin={hata} testID="profil-hata" />
      <Arkadaslar />
    </Ekran>
  );
}
