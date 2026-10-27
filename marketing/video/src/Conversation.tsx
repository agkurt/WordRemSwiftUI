import {
  AbsoluteFill, Audio, Img, OffthreadVideo, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig,
} from "remotion";
import { loadFont as loadSerif } from "@remotion/google-fonts/Fraunces";
import { loadFont as loadSans } from "@remotion/google-fonts/Inter";
import { Edit, FPS, HOOK_SECONDS, Line, OUTRO_SECONDS, UI } from "./types";

const { fontFamily: serif } = loadSerif("normal", { weights: ["600", "700"], subsets: ["latin", "latin-ext"] });
const { fontFamily: sans } = loadSans("normal", { weights: ["600", "700", "800"], subsets: ["latin", "latin-ext"] });

// Uygulamanın renkleri (DesignSystem.swift)
const C = { paper: "#F6F2EA", ink: "#1C1A17", inkSoft: "#4A453E", accent: "#C2512F", accentSoft: "#F3E2D8" };

// Telefon çerçevesi: TikTok/Reels güvenli alanında kalır
const PHONE_H = 1180;
const PHONE_TOP = 232;
const BEZEL = 16;

export const mainSeconds = (e: Edit) => e.keeps.reduce((a, k) => a + k.to - k.from, 0);

/** Kurgudaki saniye → kaynak videodaki saniye (kesilen boşluklar atlanır) */
export const sourceAt = (e: Edit, t: number) => {
  let acc = 0;
  for (const k of e.keeps) {
    const len = k.to - k.from;
    if (t < acc + len) return k.from + (t - acc);
    acc += len;
  }
  return e.keeps.at(-1)?.to ?? 0;
};

/** Kaynak saniye → kurgudaki saniye (kesilen yerdeyse null) */
export const outputAt = (e: Edit, s: number) => {
  let acc = 0;
  for (const k of e.keeps) {
    if (s >= k.from && s <= k.to) return acc + (s - k.from);
    acc += k.to - k.from;
  }
  return null;
};

const ramp = (s: number, a: number, b: number, d = 0.25) =>
  Math.min(interpolate(s, [a - d, a], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
    interpolate(s, [b, b + d], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }));

const currentLine = (e: Edit, s: number): Line | undefined =>
  e.lines.find((l) => s >= l.start - 0.15 && s <= l.end + 0.35) ??
  [...e.lines].reverse().find((l) => s > l.end && s - l.end < 1.2);

export const Conversation: React.FC<Edit> = (e) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const mainFrames = Math.round(mainSeconds(e) * FPS);
  const t = frame / fps;
  const s = sourceAt(e, Math.min(t, mainSeconds(e) - 0.001));

  let cursor = 0;
  const clips = e.keeps.map((k, i) => {
    const from = Math.round(cursor * FPS);
    cursor += k.to - k.from;
    const to = Math.round(cursor * FPS);
    return (
      <Sequence key={i} from={from} durationInFrames={to - from} layout="none">
        <OffthreadVideo src={staticFile(e.video)} trimBefore={Math.round(k.from * FPS)} trimAfter={Math.round(k.to * FPS)}
          style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </Sequence>
    );
  });

  const dings = e.cards.map((c, i) => {
    const at = outputAt(e, c.t);
    return at == null ? null : (
      <Sequence key={i} from={Math.round(at * FPS)} durationInFrames={FPS} layout="none">
        <Audio src={staticFile("ding.wav")} volume={0.32} />
      </Sequence>
    );
  });

  // Öğrenci konuşurken (kart okunurken) ekrana hafif yakınlaşma
  const zoom = 1 + 0.1 * Math.max(0, ...e.lines.filter((l) => l.who === "you").map((l) => ramp(s, l.start - 0.1, l.end)));
  const phoneW = Math.round((PHONE_H - BEZEL * 2) * (e.width / e.height)) + BEZEL * 2;
  const intro = spring({ frame, fps, config: { damping: 18, mass: 0.8 } });
  const progress = Math.min(1, t / mainSeconds(e));

  return (
    <AbsoluteFill style={{ background: C.paper, fontFamily: sans }}>
      <Background />
      <AbsoluteFill style={{ opacity: frame < mainFrames ? 1 : 0 }}>
        {/* Telefon */}
        <div style={{
          position: "absolute", top: PHONE_TOP, left: (1080 - phoneW) / 2, width: phoneW, height: PHONE_H,
          borderRadius: 78, background: C.ink, padding: BEZEL, boxSizing: "border-box",
          boxShadow: "0 50px 90px rgba(28,26,23,0.28), 0 8px 20px rgba(28,26,23,0.18)",
          transform: `translateY(${(1 - intro) * 160}px) scale(${0.94 + 0.06 * intro})`,
        }}>
          <div style={{ width: "100%", height: "100%", borderRadius: 64, overflow: "hidden", position: "relative", background: C.paper }}>
            <div style={{ position: "absolute", inset: 0, transform: `scale(${zoom})`, transformOrigin: "50% 46%" }}>{clips}</div>
          </div>
        </div>
        <Speaker e={e} s={s} />
        <Subtitle e={e} s={s} />
        <TitleChip text={e.title} t={t} />
        {/* İlerleme çubuğu */}
        <div style={{ position: "absolute", top: 0, left: 0, height: 12, width: `${progress * 100}%`, background: C.accent }} />
        <Hook text={e.hook} sub={UI[e.lang ?? "tr"].sub} t={t} />
      </AbsoluteFill>
      {dings}
      <Sequence from={mainFrames} durationInFrames={Math.round(OUTRO_SECONDS * FPS)}>
        <Outro cta={e.cta} tagline={UI[e.lang ?? "tr"].tagline} />
      </Sequence>
    </AbsoluteFill>
  );
};

const Background = () => (
  <AbsoluteFill>
    <div style={{ position: "absolute", width: 900, height: 900, left: -380, top: -260, borderRadius: "50%",
      background: C.accentSoft, filter: "blur(40px)", opacity: 0.9 }} />
    <div style={{ position: "absolute", width: 800, height: 800, right: -360, bottom: 120, borderRadius: "50%",
      background: C.accentSoft, filter: "blur(40px)", opacity: 0.7 }} />
  </AbsoluteFill>
);

/** Kim konuşuyor: Lupa solda, öğrenci sağda (sohbet balonu gibi) */
const Speaker: React.FC<{ e: Edit; s: number }> = ({ e, s }) => {
  const frame = useCurrentFrame();
  const line = e.lines.find((l) => s >= l.start - 0.1 && s <= l.end + 0.1);
  if (!line) return null;
  const lupa = line.who === "lupa";
  const pop = interpolate(s, [line.start - 0.1, line.start + 0.15], [0.6, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const pulse = 0.5 + 0.5 * Math.sin(frame / 4);
  return (
    <div style={{
      position: "absolute", top: 560, [lupa ? "left" : "right"]: 34, transform: `scale(${pop})`,
      transformOrigin: lupa ? "left center" : "right center",
      display: "flex", alignItems: "center", gap: 14, padding: "18px 26px", borderRadius: 999,
      background: lupa ? C.accent : C.ink, color: "white", fontSize: 34, fontWeight: 800,
      boxShadow: "0 14px 30px rgba(28,26,23,0.22)",
    }}>
      <span style={{ width: 16, height: 16, borderRadius: 8, background: "white", opacity: 0.45 + 0.55 * pulse }} />
      {lupa ? UI[e.lang ?? "tr"].lupa : UI[e.lang ?? "tr"].you}
    </div>
  );
};

/** Türkçe altyazı: o an söylenen cümlenin anlamı */
const Subtitle: React.FC<{ e: Edit; s: number }> = ({ e, s }) => {
  const line = currentLine(e, s);
  if (!line) return null;
  const lupa = line.who === "lupa";
  // Çevirisi olan satır (öğrenilen dildeki cümle) anlamıyla, olmayan (izleyicinin dilinde) kendisiyle gösterilir
  const translated = !!line.tr;
  const enter = interpolate(s, [line.start - 0.15, line.start + 0.1], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", left: 60, right: 60, top: 1370, display: "flex", justifyContent: "center" }}>
      <div style={{
        background: "white", borderRadius: 34, padding: "22px 36px 26px", maxWidth: 960,
        boxShadow: "0 18px 40px rgba(28,26,23,0.16)", opacity: enter, transform: `translateY(${(1 - enter) * 24}px) scale(${0.96 + 0.04 * enter})`,
        borderTop: `6px solid ${lupa ? C.accent : C.ink}`,
      }}>
        <div style={{ fontSize: 24, fontWeight: 800, letterSpacing: 2, color: lupa ? C.accent : C.inkSoft, marginBottom: 6, textAlign: "center" }}>
          {(lupa ? UI[e.lang ?? "tr"].lupa : UI[e.lang ?? "tr"].you).toUpperCase()}{translated ? ` · ${UI[e.lang ?? "tr"].meaning}` : ""}
        </div>
        <div style={{ fontSize: translated ? 44 : 40, fontWeight: 700, color: C.ink, lineHeight: 1.22, textAlign: "center" }}>
          {translated ? line.tr : line.text}
        </div>
      </div>
    </div>
  );
};

const TitleChip: React.FC<{ text: string; t: number }> = ({ text, t }) => {
  const o = interpolate(t, [HOOK_SECONDS - 0.3, HOOK_SECONDS + 0.1], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", top: 120, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: o }}>
      <div style={{ fontFamily: serif, fontWeight: 700, fontSize: 46, color: C.ink, background: "rgba(255,255,255,0.75)",
        padding: "14px 34px", borderRadius: 999, boxShadow: "0 8px 22px rgba(28,26,23,0.10)" }}>{text}</div>
    </div>
  );
};

/** İlk saniye: büyük soru, sahne arkada akarken */
const Hook: React.FC<{ text: string; sub: string; t: number }> = ({ text, sub, t }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (t > HOOK_SECONDS + 0.2) return null;
  const pop = spring({ frame, fps, config: { damping: 11, mass: 0.6, stiffness: 140 } });
  const out = interpolate(t, [HOOK_SECONDS - 0.35, HOOK_SECONDS], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ background: `rgba(246,242,234,${0.86 * out})`, alignItems: "center", justifyContent: "center", opacity: out }}>
      <div style={{ transform: `scale(${0.7 + 0.3 * pop}) translateY(${(1 - out) * -300}px)`, textAlign: "center", padding: "0 70px" }}>
        <div style={{ fontFamily: serif, fontWeight: 700, fontSize: 104, lineHeight: 1.08, color: C.ink }}>{text}</div>
        <div style={{ width: 180, height: 14, borderRadius: 7, background: C.accent, margin: "44px auto 30px" }} />
        <div style={{ fontSize: 42, fontWeight: 700, color: C.accent }}>{sub}</div>
      </div>
    </AbsoluteFill>
  );
};

const Outro: React.FC<{ cta: string; tagline: string }> = ({ cta, tagline }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const icon = spring({ frame, fps, config: { damping: 12, mass: 0.7 } });
  const text = spring({ frame: frame - 6, fps, config: { damping: 16 } });
  const btn = spring({ frame: frame - 12, fps, config: { damping: 10, stiffness: 160 } });
  return (
    <AbsoluteFill style={{ background: C.paper, alignItems: "center", justifyContent: "center", fontFamily: sans }}>
      <Background />
      <Img src={staticFile("icon.png")} style={{ width: 280, height: 280, borderRadius: 64, transform: `scale(${icon})`,
        boxShadow: "0 30px 60px rgba(28,26,23,0.25)" }} />
      <div style={{ opacity: text, transform: `translateY(${(1 - text) * 40}px)`, textAlign: "center", marginTop: 56 }}>
        <div style={{ fontFamily: serif, fontWeight: 700, fontSize: 100, color: C.ink }}>WordRem AI</div>
        <div style={{ fontSize: 46, fontWeight: 600, color: C.inkSoft, marginTop: 14 }}>{tagline}</div>
      </div>
      <div style={{ marginTop: 64, transform: `scale(${btn})`, background: C.accent, color: "white", fontSize: 46, fontWeight: 800,
        padding: "28px 56px", borderRadius: 999, boxShadow: "0 18px 36px rgba(194,81,47,0.35)" }}>{cta}</div>
    </AbsoluteFill>
  );
};
