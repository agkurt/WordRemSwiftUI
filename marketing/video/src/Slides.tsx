import { AbsoluteFill, Img, staticFile } from "remotion";
import { loadFont as loadSerif } from "@remotion/google-fonts/Fraunces";
import { loadFont as loadHeavy } from "@remotion/google-fonts/Montserrat";

const { fontFamily: serif } = loadSerif("normal", { weights: ["700"], subsets: ["latin", "latin-ext"] });
const { fontFamily: heavy } = loadHeavy("normal", { weights: ["700", "800", "900"], subsets: ["latin", "latin-ext"] });

const C = { ink: "#1C1A17", accent: "#C2512F", accentDeep: "#9E3F22", yellow: "#FFD84D", green: "#2E9E5B", red: "#E0473A", night: "#14110F", paper: "#F6F2EA" };

/**
 * Kaydırmalı gönderinin bir slaytı (TikTok fotoğraf modu 1080×1920). Yazılar ortadaki 1080×1350 alanda kalır:
 * Instagram'da aynı slayt 4:5 kırpılınca hiçbir şey kesilmez. Üst 285 / alt 285 piksel yalnızca zemin.
 */
export type Slide =
  /** Kapak: büyük kanca, küçük alt yazı, istenirse arkada görsel */
  | { kind: "cover"; title: string; sub?: string; image?: string }
  /** Hata → doğrusu, altında kısa ipucu */
  | { kind: "fix"; n: number; wrong: string; right: string; tip?: string; label?: string }
  /** Son slayt: Lupa çağrısı */
  | { kind: "cta"; title: string; sub?: string };

export type SlideProps = Slide & { index: number; total: number };

/** *yıldızlı* kısım sarı (koyu zeminde) ya da turuncu (açık zeminde) */
const hl = (text: string, color: string) =>
  text.split(/(\*[^*]+\*)/).map((p, i) => (p.startsWith("*") ? <span key={i} style={{ color }}>{p.slice(1, -1)}</span> : p));

/** Ortadaki 1080×1350 güvenli alan; içerik dikeyde ortalanır */
const Safe: React.FC<{ children: React.ReactNode; gap?: number }> = ({ children, gap = 44 }) => (
  <div style={{ position: "absolute", top: 285, height: 1350, left: 70, right: 70, display: "flex", flexDirection: "column",
    alignItems: "center", justifyContent: "center", gap }}>{children}</div>
);

const fit = (text: string, big: number, per: number) => Math.round(Math.min(big, (big * per * 3) / Math.max(text.length, per * 3)));

export const SlideFrame: React.FC<SlideProps> = (s) => (
  <AbsoluteFill style={{ background: C.night, fontFamily: heavy, overflow: "hidden" }}>
    <div style={{ position: "absolute", width: 1200, height: 1200, borderRadius: "50%", left: -560, top: -300,
      background: "radial-gradient(circle, rgba(194,81,47,0.55), rgba(194,81,47,0) 65%)" }} />
    <div style={{ position: "absolute", width: 1000, height: 1000, borderRadius: "50%", right: -460, bottom: -200,
      background: "radial-gradient(circle, rgba(255,216,77,0.2), rgba(255,216,77,0) 65%)" }} />
    {s.kind === "cover" ? <Cover {...s} /> : s.kind === "fix" ? <Fix {...s} /> : <Cta {...s} />}
    {/* Sayfa göstergesi ve kaydırma işareti (son slayt hariç) */}
    <div style={{ position: "absolute", top: 1680, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 12 }}>
      {Array.from({ length: s.total }).map((_, i) => (
        <div key={i} style={{ width: i === s.index ? 40 : 14, height: 14, borderRadius: 7, background: i === s.index ? C.yellow : "rgba(255,255,255,0.3)" }} />
      ))}
    </div>
    {s.index < s.total - 1 ? (
      <div style={{ position: "absolute", top: 1560, right: 70, color: "rgba(255,255,255,0.75)", fontSize: 40, fontWeight: 800 }}>swipe →</div>
    ) : null}
  </AbsoluteFill>
);

const Cover: React.FC<Extract<Slide, { kind: "cover" }>> = ({ title, sub, image }) => (
  <AbsoluteFill>
    {image ? (
      <>
        <Img src={staticFile(image)} style={{ position: "absolute", width: "100%", height: "100%", objectFit: "cover" }} />
        <AbsoluteFill style={{ background: "linear-gradient(180deg, rgba(20,17,15,0.92) 0%, rgba(20,17,15,0.55) 45%, rgba(20,17,15,0.15) 70%, rgba(20,17,15,0.75) 100%)" }} />
      </>
    ) : null}
    <Safe gap={40}>
      <div style={{ fontSize: fit(title, 132, 11), fontWeight: 900, lineHeight: 1.04, color: "white", textAlign: "center",
        WebkitTextStroke: "13px #0E0C0B", paintOrder: "stroke fill" }}>{hl(title, C.yellow)}</div>
      {sub ? <div style={{ background: C.accent, color: "white", fontSize: 50, fontWeight: 900, padding: "16px 36px", borderRadius: 999,
        transform: "rotate(-2deg)", boxShadow: "0 14px 34px rgba(0,0,0,0.45)" }}>{sub}</div> : null}
    </Safe>
  </AbsoluteFill>
);

const Fix: React.FC<Extract<Slide, { kind: "fix" }>> = ({ n, wrong, right, tip, label }) => (
  <Safe gap={52}>
    <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
      <div style={{ background: C.yellow, color: C.ink, fontSize: 64, fontWeight: 900, width: 108, height: 108, borderRadius: 54,
        display: "flex", alignItems: "center", justifyContent: "center" }}>{n}</div>
      {label ? <div style={{ color: "white", fontSize: 56, fontWeight: 900 }}>{label}</div> : null}
    </div>
    <div style={{ background: "white", color: C.ink, fontSize: fit(wrong, 78, 15), fontWeight: 900, padding: "30px 44px",
      borderRadius: 32, transform: "rotate(-2deg)", textAlign: "center", boxShadow: "0 18px 44px rgba(0,0,0,0.45)" }}>
      <span style={{ textDecoration: `line-through 9px ${C.red}` }}>❌ {wrong}</span>
    </div>
    <div style={{ background: C.green, color: "white", fontSize: fit(right, 96, 13), fontWeight: 900, lineHeight: 1.08, padding: "36px 48px",
      borderRadius: 38, transform: "rotate(1.5deg)", textAlign: "center", boxShadow: "0 22px 56px rgba(0,0,0,0.5)" }}>✅ {hl(right, C.yellow)}</div>
    {tip ? <div style={{ fontSize: 54, fontWeight: 800, color: "rgba(255,255,255,0.92)", textAlign: "center", lineHeight: 1.25, maxWidth: 920 }}>{hl(tip, C.yellow)}</div> : null}
  </Safe>
);

const Cta: React.FC<Extract<Slide, { kind: "cta" }>> = ({ title, sub }) => (
  <Safe gap={48}>
    <div style={{ fontSize: fit(title, 104, 13), fontWeight: 900, color: "white", textAlign: "center", lineHeight: 1.08,
      WebkitTextStroke: "11px #0E0C0B", paintOrder: "stroke fill" }}>{hl(title, C.yellow)}</div>
    <Img src={staticFile("icon.png")} style={{ width: 260, height: 260, borderRadius: 62, boxShadow: "0 24px 60px rgba(0,0,0,0.5)" }} />
    <div style={{ fontFamily: serif, fontSize: 96, color: "white" }}>WordRem AI</div>
    {sub ? <div style={{ background: C.yellow, color: C.ink, fontSize: 52, fontWeight: 900, padding: "20px 46px", borderRadius: 999 }}>{sub}</div> : null}
  </Safe>
);
