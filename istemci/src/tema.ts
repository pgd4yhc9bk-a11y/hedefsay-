// Tasarım jetonları. Koyu tema varsayılan (oyun hissi); sistem açık temadaysa açık tema.
import { useColorScheme } from "react-native";

export const FONT = { orta: "Nunito_600SemiBold", kalin: "Nunito_800ExtraBold", siyah: "Nunito_900Black" } as const;

const koyu = {
  ad: "koyu" as "koyu" | "acik",
  zemin: ["#0A0E1F", "#151C3F"] as [string, string],
  yuzey: "#1A2145", yuzey2: "#242D5E", cizgi: "#323C75",
  yazi: "#F6F1E4", soluk: "#A6AFD6",
  vurgu: "#FFB020", vurguAlt: "#D98A00", vurguYazi: "#1D1300", vurguMetin: "#FFB020",   // vurguMetin: zemin üstünde okunur amber metin
  iyi: "#43E0A1", iyiZemin: "rgba(67,224,161,0.14)", kotu: "#FF6B6B", kotuZemin: "rgba(255,107,107,0.14)", mavi: "#7FB0FF",
  karo: "#F8EDCB", karoAlt: "#D5B86C", karoYazi: "#241A06",
  karoKul: "#2A3263", karoKulAlt: "#1C2247", karoKulYazi: "#6B75A9",
  joker: "#CDB8FF", jokerAlt: "#9576E8",
  golge: "#000000",
};
const acik: typeof koyu = {
  ad: "acik",
  zemin: ["#F7F3E9", "#EAE3D0"],
  yuzey: "#FFFFFF", yuzey2: "#F3EEDF", cizgi: "#E0D7BE",
  yazi: "#161B30", soluk: "#6A708F",
  vurgu: "#FFB020", vurguAlt: "#D98A00", vurguYazi: "#1D1300", vurguMetin: "#B35900",
  iyi: "#1E9B66", iyiZemin: "rgba(30,155,102,0.12)", kotu: "#D6453D", kotuZemin: "rgba(214,69,61,0.10)", mavi: "#3B78D8",
  karo: "#FBF1D2", karoAlt: "#D5B86C", karoYazi: "#241A06",
  karoKul: "#E4DDC6", karoKulAlt: "#CFC6AA", karoKulYazi: "#9A9276",
  joker: "#D8C8FF", jokerAlt: "#9576E8",
  golge: "#2A2410",
};
export type Tema = typeof koyu;
export const useTema = (): Tema => (useColorScheme() === "light" ? acik : koyu);
