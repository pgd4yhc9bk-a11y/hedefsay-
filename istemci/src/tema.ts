// Tasarım jetonları. Tek tema: açık ve renkli (mavi birincil, mercan ve sarı vurgu). Koyu tema şimdilik yok.
import { useColorScheme } from "react-native";

export const FONT = { orta: "Nunito_600SemiBold", kalin: "Nunito_800ExtraBold", siyah: "Nunito_900Black" } as const;

const renkli = {
  ad: "acik" as "koyu" | "acik",
  zemin: ["#F1F6FF", "#DEE9FF"] as [string, string],
  yuzey: "#FFFFFF", yuzey2: "#EAF0FC", cizgi: "#D5DFF4",
  yazi: "#14204A", soluk: "#6877A6",
  // birincil eylem: mavi
  vurgu: "#3558F2", vurguAlt: "#2340C6", vurguYazi: "#FFFFFF", vurguMetin: "#2B4BE0",
  // ikincil vurgular
  mercan: "#FF6A4D", mercanAlt: "#E04A2D", mercanZemin: "#FFE7DF",
  sari: "#FFC83D", sariAlt: "#E2A514", sariZemin: "#FFF1CC",
  iyi: "#14A56E", iyiZemin: "rgba(20,165,110,0.13)", kotu: "#E5484D", kotuZemin: "rgba(229,72,77,0.12)", mavi: "#3558F2",
  // harf karosu: beyaz yüz, gri-mavi alt kenar
  karo: "#FFFFFF", karoAlt: "#C3CFEA", karoYazi: "#17224D",
  karoKul: "#CBD4EA", karoKulAlt: "#B4C0DE", karoKulYazi: "#8794BB",
  karoSecili: "#DCE5FF",
  joker: "#FFD54A", jokerAlt: "#E2AD1F",
  golge: "#2C4486",
};
export type Tema = typeof renkli;
export const useTema = (): Tema => { useColorScheme(); return renkli; };
