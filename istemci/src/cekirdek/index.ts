// Oyun çekirdeği (prototip/oyun.js'in kopyası; scripts/senkronla.sh ile güncellenir). Burada yalnızca tipler.
import "./sozluk.js";

/* eslint-disable @typescript-eslint/no-explicit-any */
export type Tur = "kelime" | "islem";
export interface Bulmaca { kind: Tur; payload: any; best: { score: number; solution: string }; found?: Map<number, { e: string; n: number }> }
export interface KelimeBilgi { valid: boolean; reason?: string; word: string; score: number; joker: boolean }
export interface Degerlendirme { ok: boolean; error?: string; value?: number; used?: number[] }

export interface Cekirdek {
  ALFABE: string; HARF_SAYISI: number; MIN_SESLI: number; GUNLUK_SURE: number; GUNLUK_TURLAR: Tur[];
  trLower(s: string): string;
  makeRng(seed: string): () => number;
  setDictionary(words: string[]): void;
  getDictionarySize(): number;
  drawLetter(rng: () => number, type: "sesli" | "sessiz"): string;
  completeRack(rng: () => number, ilk: string[], type: "sesli" | "sessiz"): string[];
  generateRack(rng: () => number, types: ("sesli" | "sessiz")[]): string[];
  randomTypes(rng: () => number): ("sesli" | "sessiz")[];
  wordInfo(word: string, letters: string[]): KelimeBilgi;
  allWords(letters: string[]): { word: string; score: number; joker: boolean }[];
  generateNumberRound(rng: () => number): { nums: number[]; target: number; found: Map<number, { e: string; n: number }> };
  evaluate(text: string, pool: number[]): Degerlendirme;
  numberScore(target: number, value: number): number;
  expressionSteps(text: string): { a: number; op: string; b: number; r: number }[] | null;
  stepText(st: { a: number; op: string; b: number; r: number }): string;
  botPersona(seed: string): { nick: string; city: string; skill: number; bot: true };
  botWord(letters: string[], rng: () => number): { word: string; score: number } | null;
  botNumber(round: { target: number; found: Map<number, { e: string; n: number }> }, rng: () => number): { value: number; expr: string };
  timeBonus(kalanSn: number): number;
  dailyRound(date: string, i: number, salt?: string): Bulmaca;
  solve(nums: number[]): Map<number, { e: string; n: number }>;
}

// Metro CommonJS: oyun.js module.exports ile dışa verir.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const H: Cekirdek = require("./oyun.js");
H.setDictionary((globalThis as any).HEDEF_SOZLUK);
export default H;
