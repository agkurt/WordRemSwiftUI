import { AbsoluteFill, Img, staticFile } from "remotion";
import { loadFont as loadSerif } from "@remotion/google-fonts/Fraunces";
import { loadFont as loadHeavy } from "@remotion/google-fonts/Montserrat";
import { FLAGS } from "./types";

const { fontFamily: serif } = loadSerif("normal", { weights: ["700"], subsets: ["latin", "latin-ext"] });
const { fontFamily: heavy } = loadHeavy("normal", { weights: ["700", "800", "900"], subsets: ["latin", "latin-ext"] });

const C = { ink: "#1C1A17", accent: "#C2512F", accentDeep: "#9E3F22", yellow: "#FFD84D", green: "#2E9E5B", night: "#14110F", paper: "#F6F2EA" };

/** Günlük hikâye karesi (stories/<tarih>.json içindeki bir kare). Üst 250 ve alt 340 piksel Instagram arayüzüne kalır. */
export type StoryFrame =
  /** Öğret: günün kalıbı, Türkçesi ve Lupa'nın kısa notu */
  | { kind: "teach"; label: string; phrase: string; meaning: string; note?: string; target?: string }
  /** Etkileşim: soru büyük, altta anket/quiz çıkartmasına boş alan (çıkartma uygulamada eklenir) */
  | { kind: "ask"; label: string; question: string; hint?: string; sticker: string }
  /** Yönlendir: reel'in kapak karesi ve çağrı */
  | { kind: "promo"; label: string; title: string; image: string; cta: string };

export const Story: React.FC<StoryFrame> = (f) => (
  <AbsoluteFill style={{ background: C.night, fontFamily: heavy, overflow: "hidden" }}>
    <Glow />
    <Header label={f.label} />
    {f.kind === "teach" ? <Teach {...f} /> : f.kind === "ask" ? <Ask {...f} /> : <Promo {...f} />}
    {/* Yönlendirme karesinde kapak ve düğme alanı kaplar */}
    {f.kind === "promo" ? null : <Footer />}
  </AbsoluteFill>
);

const Glow = () => (
  <AbsoluteFill>
    <div style={{ position: "absolute", width: 1200, height: 1200, borderRadius: "50%", left: -560, top: -380,
      background: "radial-gradient(circle, rgba(194,81,47,0.6), rgba(194,81,47,0) 65%)" }} />
    <div style={{ position: "absolute", width: 1000, height: 1000, borderRadius: "50%", right: -460, bottom: -260,
      background: "radial-gradient(circle, rgba(255,216,77,0.24), rgba(255,216,77,0) 65%)" }} />
  </AbsoluteFill>
);

const Header: React.FC<{ label: string }> = ({ label }) => (
  <div style={{ position: "absolute", top: 260, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
    <div style={{ background: C.accent, color: "white", fontSize: 40, fontWeight: 900, padding: "14px 32px", borderRadius: 999,
      transform: "rotate(-2deg)", boxShadow: "0 14px 34px rgba(0,0,0,0.4)" }}>{label}</div>
  </div>
);

const Footer = () => (
  <div style={{ position: "absolute", bottom: 360, left: 0, right: 0, display: "flex", justifyContent: "center", alignItems: "center", gap: 18 }}>
    <Img src={staticFile("icon.png")} style={{ width: 64, height: 64, borderRadius: 16 }} />
    <div style={{ fontFamily: serif, fontSize: 40, color: "rgba(255,255,255,0.85)" }}>WordRem AI · Lupa</div>
  </div>
);

/** Uzun metinde yazı küçülür: kare dışına taşmaz */
const fit = (text: string, big: number, perLine: number) => Math.round(Math.min(big, (big * perLine * 3) / Math.max(text.length, perLine * 3)));

const Teach: React.FC<Extract<StoryFrame, { kind: "teach" }>> = ({ phrase, meaning, note, target }) => (
  <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", padding: "0 80px" }}>
    <div style={{ fontSize: 64, marginBottom: 24 }}>{FLAGS[target ?? "en"]}</div>
    <div style={{ fontSize: fit(phrase, 108, 14), fontWeight: 900, color: "white", lineHeight: 1.08, textAlign: "center",
      WebkitTextStroke: "10px #0E0C0B", paintOrder: "stroke fill" }}>{highlight(phrase)}</div>
    <div style={{ marginTop: 48, background: "white", color: C.ink, fontSize: 50, fontWeight: 800, padding: "20px 40px", borderRadius: 999,
      boxShadow: "0 16px 40px rgba(0,0,0,0.4)", textAlign: "center" }}>= {meaning}</div>
    {note ? (
      <div style={{ marginTop: 70, display: "flex", gap: 22, alignItems: "flex-start", background: "rgba(255,255,255,0.08)",
        border: "2px solid rgba(255,255,255,0.12)", borderRadius: 30, padding: "26px 32px", maxWidth: 900 }}>
        <div style={{ background: C.accent, color: "white", fontSize: 30, fontWeight: 900, padding: "8px 18px", borderRadius: 999, flexShrink: 0 }}>LUPA</div>
        <div style={{ fontSize: 40, fontWeight: 700, color: "rgba(255,255,255,0.92)", lineHeight: 1.3 }}>{note}</div>
      </div>
    ) : null}
  </AbsoluteFill>
);

/** *yıldızlı* kısım sarı */
const highlight = (text: string) =>
  text.split(/(\*[^*]+\*)/).map((p, i) => (p.startsWith("*") ? <span key={i} style={{ color: C.yellow }}>{p.slice(1, -1)}</span> : p));

const Ask: React.FC<Extract<StoryFrame, { kind: "ask" }>> = ({ question, hint, sticker }) => (
  <AbsoluteFill style={{ alignItems: "center", padding: "470px 80px 0" }}>
    <div style={{ fontSize: fit(question, 96, 16), fontWeight: 900, color: "white", lineHeight: 1.1, textAlign: "center",
      WebkitTextStroke: "10px #0E0C0B", paintOrder: "stroke fill" }}>{highlight(question)}</div>
    {hint ? <div style={{ marginTop: 30, fontSize: 42, fontWeight: 700, color: "rgba(255,255,255,0.8)", textAlign: "center" }}>{hint}</div> : null}
    {/* Anket/quiz çıkartmasının yeri: Instagram'da buraya eklenir */}
    <div style={{ marginTop: 70, width: 760, height: 330, borderRadius: 40, border: "5px dashed rgba(255,216,77,0.55)",
      display: "flex", alignItems: "center", justifyContent: "center", color: "rgba(255,216,77,0.8)", fontSize: 40, fontWeight: 800,
      textAlign: "center", padding: "0 50px", lineHeight: 1.3 }}>
      {sticker}
    </div>
  </AbsoluteFill>
);

const Promo: React.FC<Extract<StoryFrame, { kind: "promo" }>> = ({ title, image, cta }) => (
  <AbsoluteFill style={{ alignItems: "center", padding: "400px 80px 0" }}>
    <div style={{ fontSize: fit(title, 84, 18), fontWeight: 900, color: "white", lineHeight: 1.1, textAlign: "center",
      WebkitTextStroke: "9px #0E0C0B", paintOrder: "stroke fill" }}>{highlight(title)}</div>
    <div style={{ marginTop: 50, width: 470, height: 836, borderRadius: 44, overflow: "hidden", transform: "rotate(-3deg)",
      boxShadow: "0 40px 100px rgba(0,0,0,0.6), 0 0 0 6px rgba(255,255,255,0.9)" }}>
      <Img src={staticFile(image)} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
    </div>
    <div style={{ marginTop: -40, background: C.yellow, color: C.ink, fontSize: 48, fontWeight: 900, padding: "20px 40px", borderRadius: 999,
      transform: "rotate(2deg)", boxShadow: "0 16px 40px rgba(0,0,0,0.45)" }}>{cta}</div>
  </AbsoluteFill>
);
