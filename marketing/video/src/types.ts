/** Kaynak videoda saniye cinsinden zamanlar (prep.mjs üretir, Claude çevirileri ve ilk saniye yazısını doldurur) */
export type Word = { w: string; t: number };
export type Line = { who: "lupa" | "you"; start: number; end: number; text: string; words: Word[]; tr?: string; orig?: string; partial?: boolean;
  /** Satırın içindeki sesli bölümler [başla, bitir] (kaynak saniye): altyazı kelimeleri bunlara dağıtılır */
  segs?: [number, number][];
  /** Öğrencinin OpenAI sesi (public/ altında) ve dosyanın başındaki sessizlik; mute: telefondaki sesin susturulduğu kaynak aralığı */
  voice?: { src: string; lead: number }; mute?: [number, number] };
export type Card = { t: number; text: string; tr?: string };
export type Keep = { from: number; to: number };

export type Edit = {
  id: string;
  /** public/ altındaki video yolu */
  video: string;
  /** Kaynak videonun boyutu (telefon çerçevesinin oranı) */
  width: number;
  height: number;
  /** İlk saniye yazısı ve kalıcı başlık */
  hook: string;
  title: string;
  keeps: Keep[];
  lines: Line[];
  cards: Card[];
  /** Kapanış: "Coming soon on the App Store" ya da "Download on the App Store" */
  cta: string;
  /** Videodaki yazıların dili (izleyicinin dili) */
  lang: "en" | "tr";
  /** Öğrenilen dil (sayaç bayrağı ve kapanış cümlesi) */
  target?: string;
};

/** Videodaki sabit yazılar */
export const UI = {
  en: { you: "You", lupa: "Lupa", meaning: "IN ENGLISH", sub: "🎙️ A real conversation with Lupa", tagline: "Learn languages by talking with Lupa",
    yourTurn: "Your turn 👇", praise: ["Nailed it! ✅", "Perfect! 🔥", "So smooth 😎", "Fluent vibes ✨"], speak: (l: string) => `Speak ${l} from day one`, real: "🎙️ Real AI conversation",
    recap: "Phrases you just learned", save: "📌 Save it for your trip" },
  tr: { you: "Sen", lupa: "Lupa", meaning: "TÜRKÇESİ", sub: "🎙️ Lupa ile gerçek konuşma", tagline: "Lupa ile konuşarak İngilizce öğren",
    yourTurn: "Sıra sende 👇", praise: ["Harika! ✅", "Mükemmel! 🔥", "Çok akıcı 😎", "Süpersin ✨"], speak: (l: string) => `İlk günden ${l} konuş`, real: "🎙️ Gerçek yapay zekâ sohbeti",
    recap: "Bu videoda öğrendiklerin", save: "📌 Kaydet, yolculukta lazım olur" },
};

export const FPS = 30;
export const HOOK_SECONDS = 2.4;
export const OUTRO_SECONDS = 2.6;
/** Kapanıştan önce öğrencinin söylediği cümlelerin özeti (kaydetmeye teşvik eder) */
export const RECAP_SECONDS = 3.4;

export const FLAGS: Record<string, string> = { en: "🇬🇧", es: "🇪🇸", fr: "🇫🇷", de: "🇩🇪", it: "🇮🇹", ru: "🇷🇺", zh: "🇨🇳", tr: "🇹🇷" };

/**
 * Instagram/TikTok arayüzünün örttüğü bölgeler (1080×1920): üst başlık, alt açıklama/ses satırı, sağdaki düğme sütunu.
 * Yazı ve kartlar bunların dışında kalır; review.mjs ve preview.mjs karelerde bu bölgeleri kırmızıyla gösterir.
 */
export const SAFE = { top: 220, bottom: 420, side: 60, right: 140, rightFrom: 900 };
