import {
  AbsoluteFill, Audio, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig,
} from "remotion";
import { loadFont as loadSerif } from "@remotion/google-fonts/Fraunces";
import { loadFont as loadHeavy } from "@remotion/google-fonts/Montserrat";
import { FPS } from "./types";

const { fontFamily: serif } = loadSerif("italic", { weights: ["700"], subsets: ["latin", "latin-ext"] });
loadSerif("normal", { weights: ["700"], subsets: ["latin", "latin-ext"] });
const { fontFamily: heavy } = loadHeavy("normal", { weights: ["600", "700", "800", "900"], subsets: ["latin", "latin-ext"] });

const C = { ink: "#1C1A17", muted: "#7A7168", accent: "#C2512F", accentDeep: "#9E3F22", yellow: "#FFD84D", green: "#2E9E5B",
  red: "#D2453A", paper: "#F6F2EA", card: "#FFFDF8" };
const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** Açıklama reel'inin kartları (explainers/<id>.json → beats[].card) */
export type ExplainerCard =
  /** Kanca: büyük sayı + başlık (ilk kare kapak olur) */
  | { kind: "hook"; n: string; title: string; sub?: string }
  /** Hata: ❌ yanlış → ✅ doğru (doğrusu söylendiği an belirir) */
  | { kind: "fix"; n: number; of: number; label?: string; wrong: string; right: string; tip?: string }
  /** Kapanış: ikon, çağrı */
  | { kind: "cta"; title: string; sub?: string };

/** explain.mjs'in yazdığı kurgu: zamanlar videoda saniye */
export type ExplainerEdit = {
  kind: "explainer";
  id: string;
  hook: string;
  cta: string;
  total: number;
  beats: { card: ExplainerCard; from: number; to: number }[];
  sentences: { beat: number; k: number; text: string; src: string; lead: number; at: number; dur: number;
    words: { w: string; key: boolean; t: number }[] }[];
};

// Yerleşim: üst 220 ve alt 420 piksel ile sağdaki düğme sütunu platform arayüzüne kalır (types.ts → SAFE)
const HEAD_TOP = 300;
const CARD_TOP = 740;
const CARD_W = 800;
/** Kanca kartı (kapak) yukarıda ve büyük; kancadan sonraki cümle kartın altında yazılır */
const HOOK_TOP = 430;

/** Kanca kartının ölçüleri: uzun başlık küçülür; kartın tahmini yüksekliği altındaki cümlenin yerini belirler */
const hookSize = (c: Extract<ExplainerCard, { kind: "hook" }>) => {
  const chars = c.title.replace(/\*/g, "").length;
  const title = chars <= 26 ? 88 : chars <= 36 ? 80 : 72;
  const circle = chars <= 26 ? 260 : chars <= 36 ? 240 : 220;
  const lines = (n: number, size: number) => Math.ceil((n * size * 0.62) / 690);
  const height = 56 + circle + 36 + lines(chars, title) * title * 1.06 + (c.sub ? 22 + lines(c.sub.length, 48) * 58 : 0) + 60;
  return { title, circle, height };
};

/** *yıldızlı* kısım turuncu italik serif */
const rich = (text: string, size: number) =>
  text.split(/(\*[^*]+\*)/).map((p, i) => (p.startsWith("*")
    ? <span key={i} style={{ fontFamily: serif, fontStyle: "italic", color: C.accent, fontSize: size * 1.08, letterSpacing: 0 }}>{p.slice(1, -1)}</span>
    : p));

export const Explainer: React.FC<ExplainerEdit> = (e) => {
  const frame = useCurrentFrame();
  const t = frame / FPS;
  const bi = e.beats.findIndex((b) => t >= b.from && t < b.to);
  const fixes = e.beats.filter((b) => b.card.kind === "fix").length;
  const done = e.beats.filter((b, i) => b.card.kind === "fix" && (i < bi || i === bi)).length;
  return (
    <AbsoluteFill style={{ background: C.paper, fontFamily: heavy, overflow: "hidden" }}>
      <Paper />
      <Top total={fixes} done={done} />
      <Headline e={e} t={t} />
      {e.beats.map((b, i) => (
        <Sequence key={i} from={Math.round(b.from * FPS)} durationInFrames={Math.max(1, Math.round((b.to - b.from) * FPS))} layout="none">
          <CardSlot e={e} i={i} />
        </Sequence>
      ))}
      <div style={{ position: "absolute", left: 0, bottom: 0, height: 10, width: `${Math.min(1, t / e.total) * 100}%`, background: C.accent }} />
      <Voices e={e} />
      <Sfx e={e} />
    </AbsoluteFill>
  );
};

/** Sıcak kâğıt: hafif nokta dokusu ve köşelerde yumuşak ışık */
const Paper = () => (
  <AbsoluteFill>
    <AbsoluteFill style={{ backgroundImage: "radial-gradient(rgba(28,26,23,0.09) 1.6px, transparent 1.8px)", backgroundSize: "26px 26px" }} />
    <div style={{ position: "absolute", width: 1100, height: 1100, borderRadius: "50%", left: -620, top: -520,
      background: "radial-gradient(circle, rgba(194,81,47,0.16), rgba(194,81,47,0) 65%)" }} />
    <div style={{ position: "absolute", width: 1000, height: 1000, borderRadius: "50%", right: -520, bottom: -380,
      background: "radial-gradient(circle, rgba(255,216,77,0.22), rgba(255,216,77,0) 65%)" }} />
  </AbsoluteFill>
);

/** Üstte marka etiketi ve madde sayacı */
const Top: React.FC<{ total: number; done: number }> = ({ total, done }) => (
  <div style={{ position: "absolute", top: 228, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
    <div style={{ display: "flex", alignItems: "center", gap: 18, background: C.ink, color: C.paper, padding: "12px 26px", borderRadius: 999,
      fontSize: 30, fontWeight: 800, letterSpacing: 1 }}>
      <span>🎙️ ENGLISH WITH LUPA</span>
      <div style={{ display: "flex", gap: 8 }}>
        {Array.from({ length: total }).map((_, i) => (
          <div key={i} style={{ width: 30, height: 10, borderRadius: 5, background: i < done ? C.yellow : "rgba(246,242,234,0.25)" }} />
        ))}
      </div>
    </div>
  </div>
);

/** Söylenen cümle: her kelime söylendiği an aşağıdan yumuşakça belirir; vurgulu kelime turuncu italik serif */
const Headline: React.FC<{ e: ExplainerEdit; t: number }> = ({ e, t }) => {
  const si = e.sentences.reduce((acc, s, i) => (t >= s.at - 0.05 ? i : acc), -1);
  if (si < 0) return null;
  const s = e.sentences[si];
  const next = e.sentences[si + 1];
  // Kart değişirken eski cümle hızla çekilir
  const beatEnd = e.beats[s.beat].to;
  const out = Math.min(interpolate(t, [beatEnd - 0.2, beatEnd], [1, 0], clamp), next ? 1 : interpolate(t, [e.total - 1.2, e.total - 0.9], [1, 0], clamp));
  const card = e.beats[s.beat].card;
  const hook = card.kind === "hook";
  const under = hook ? Math.min(1290, HOOK_TOP + hookSize(card).height + 40) : 0;
  const size = s.words.length > 9 ? 64 : 72;
  return (
    // Kartın altındaki cümle sağdaki düğme sütununun hizasında: iki yandan daha dar
    <div style={{ position: "absolute", top: hook ? under : HEAD_TOP + 40, left: hook ? 150 : 80, right: hook ? 150 : 80, display: "flex", flexWrap: "wrap", justifyContent: "center",
      gap: `6px ${size * 0.28}px`, opacity: out }}>
      {s.words.map((w, i) => {
        const p = interpolate(t, [w.t - 0.04, w.t + 0.16], [0, 1], clamp);
        // Vurgulu kelime söylendiği an küçük bir sıçrama yapar
        const bump = w.key ? interpolate(t, [w.t, w.t + 0.12, w.t + 0.35], [1, 1.14, 1], clamp) : 1;
        return (
          <span key={i} style={{
            fontSize: w.key ? size * 1.12 : size, fontWeight: 800, lineHeight: 1.14, color: w.key ? C.accent : C.ink,
            fontFamily: w.key ? serif : heavy, fontStyle: w.key ? "italic" : "normal",
            opacity: p, transform: `translateY(${(1 - p) * 26}px) scale(${bump})`, display: "inline-block",
          }}>{w.w}</span>
        );
      })}
    </div>
  );
};

/** Kartın girişi (yaylanarak) ve çıkışı (sonraki karta yer açar) */
const CardSlot: React.FC<{ e: ExplainerEdit; i: number }> = ({ e, i }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const b = e.beats[i];
  const len = Math.round((b.to - b.from) * FPS);
  // İlk kart ilk karede tam görünür (kapak)
  const enter = i === 0 ? 1 : spring({ frame, fps, config: { damping: 14, mass: 0.7 } });
  const exit = i === e.beats.length - 1 ? 0 : interpolate(frame, [len - 6, len], [0, 1], clamp);
  const t = b.from + frame / FPS;
  const float = Math.sin(frame / 22) * 8;
  return (
    <div style={{ position: "absolute", top: b.card.kind === "hook" ? HOOK_TOP : CARD_TOP, left: (1080 - CARD_W) / 2, width: CARD_W,
      transform: `translateY(${(1 - enter) * 120 - exit * 60 + float}px) scale(${0.9 + 0.1 * enter - 0.04 * exit}) rotate(${(1 - enter) * (i % 2 ? 3 : -3)}deg)`,
      opacity: Math.min(1, enter * 1.5) * (1 - exit) }}>
      {b.card.kind === "hook" ? <HookCard c={b.card} /> : b.card.kind === "fix" ? <FixCard c={b.card} e={e} i={i} t={t} /> : <CtaCard c={b.card} cta={e.cta} />}
    </div>
  );
};

const panel = { background: C.card, borderRadius: 44, boxShadow: "0 30px 70px rgba(60,40,20,0.16), 0 0 0 3px rgba(28,26,23,0.06)" } as const;

const HookCard: React.FC<{ c: Extract<ExplainerCard, { kind: "hook" }> }> = ({ c }) => {
  const frame = useCurrentFrame();
  const pulse = 1 + 0.03 * Math.sin(frame / 6);
  const size = hookSize(c);
  return (
    <div style={{ ...panel, padding: "56px 56px 60px", display: "flex", flexDirection: "column", alignItems: "center", textAlign: "center" }}>
      <div style={{ width: size.circle, height: size.circle, borderRadius: "50%", background: C.accent, color: "white", display: "flex", alignItems: "center",
        justifyContent: "center", fontFamily: serif, fontStyle: "normal", fontSize: size.circle * 0.75, fontWeight: 700, transform: `scale(${pulse})`,
        boxShadow: "0 20px 44px rgba(194,81,47,0.4)" }}>{c.n}</div>
      <div style={{ marginTop: 36, fontSize: size.title, fontWeight: 900, lineHeight: 1.06, color: C.ink }}>{rich(c.title, size.title)}</div>
      {c.sub ? <div style={{ marginTop: 22, fontSize: 48, fontWeight: 700, color: C.muted }}>{c.sub}</div> : null}
    </div>
  );
};

const FixCard: React.FC<{ c: Extract<ExplainerCard, { kind: "fix" }>; e: ExplainerEdit; i: number; t: number }> = ({ c, e, i, t }) => {
  const { fps } = useVideoConfig();
  // Hiçbir şey söylenmeden görünmez: yanlış satırı tırnaklı cümle başlarken, üstünü çizme ilk cümlenin vurgulu kelimesinde,
  // doğrusu son cümlenin ilk vurgulu kelimesinde
  const says = e.sentences.filter((s) => s.beat === i);
  const first = says[0], last = says.at(-1)!;
  const quoteAt = first.words.find((w) => /^["“]/.test(w.w))?.t ?? first.at;
  const strikeAt = first.words.find((w) => w.key)?.t ?? first.at + first.dur - 0.4;
  const rightAt = last.words.find((w) => w.key)?.t ?? last.at;
  const wrong = spring({ frame: Math.round((t - quoteAt) * fps), fps, config: { damping: 13, stiffness: 180 } });
  const right = spring({ frame: Math.round((t - rightAt) * fps), fps, config: { damping: 11, stiffness: 190 } });
  const strike = interpolate(t, [strikeAt, strikeAt + 0.35], [0, 1], clamp);
  return (
    <div style={{ ...panel, padding: "40px 48px 48px" }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 30 }}>
        <div style={{ background: C.ink, color: C.paper, fontSize: 38, fontWeight: 900, padding: "10px 26px", borderRadius: 999 }}>{c.n} / {c.of}</div>
        {c.label ? <div style={{ fontSize: 40, fontWeight: 800, color: C.muted }}>{c.label}</div> : null}
      </div>
      <div style={{ opacity: Math.min(1, wrong * 1.5), transform: `scale(${0.85 + 0.15 * wrong})`, transformOrigin: "left center" }}>
      <Row mark="✕" bg="#FBE3DF" color={C.red}>
        <span style={{ position: "relative", color: "#8C3B33" }}>
          {c.wrong}
          <span style={{ position: "absolute", left: -6, top: "52%", height: 7, borderRadius: 4, background: C.red, width: `calc(${strike * 100}% + 12px)` }} />
        </span>
      </Row>
      </div>
      <div style={{ height: 22 }} />
      <div style={{ opacity: Math.min(1, right * 1.5), transform: `scale(${0.85 + 0.15 * right})`, transformOrigin: "left center" }}>
        <Row mark="✓" bg="#E1F3E8" color={C.green}>{rich(c.right, 68)}</Row>
      </div>
      {c.tip ? <div style={{ marginTop: 26, fontSize: 36, fontWeight: 700, color: C.muted, opacity: right }}>{rich(c.tip, 36)}</div> : null}
    </div>
  );
};

const Row: React.FC<{ mark: string; bg: string; color: string; children: React.ReactNode }> = ({ mark, bg, color, children }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 28, background: bg, borderRadius: 32, padding: "32px 32px" }}>
    <div style={{ flex: "0 0 auto", width: 84, height: 84, borderRadius: "50%", background: color, color: "white", fontSize: 50, fontWeight: 900,
      display: "flex", alignItems: "center", justifyContent: "center" }}>{mark}</div>
    <div style={{ fontSize: 68, fontWeight: 800, lineHeight: 1.12, color: C.ink }}>{children}</div>
  </div>
);

const CtaCard: React.FC<{ c: Extract<ExplainerCard, { kind: "cta" }>; cta: string }> = ({ c, cta }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const icon = spring({ frame: frame - 4, fps, config: { damping: 10, mass: 0.7 } });
  const btn = spring({ frame: frame - 14, fps, config: { damping: 9, stiffness: 170 } });
  return (
    <div style={{ ...panel, padding: "52px 50px 56px", display: "flex", flexDirection: "column", alignItems: "center", textAlign: "center" }}>
      <Img src={staticFile("icon.png")} style={{ width: 190, height: 190, borderRadius: 46, transform: `scale(${icon})`,
        boxShadow: "0 20px 44px rgba(60,40,20,0.25)" }} />
      <div style={{ marginTop: 30, fontSize: 66, fontWeight: 900, lineHeight: 1.1, color: C.ink }}>{rich(c.title, 66)}</div>
      {c.sub ? <div style={{ marginTop: 20, fontSize: 40, fontWeight: 700, color: C.muted }}>{c.sub}</div> : null}
      <div style={{ marginTop: 34, background: C.accent, color: "white", fontSize: 38, fontWeight: 900, padding: "20px 34px", whiteSpace: "nowrap", borderRadius: 999,
        transform: `scale(${btn})`, boxShadow: "0 16px 34px rgba(194,81,47,0.4)" }}>{cta}</div>
    </div>
  );
};

/** TTS dosyaları sahne kayıtlarından ~5 dB kısık: dış ses diğer reel'lerin seviyesine çekilir (tepe yine -3 dB altında) */
const VOICE_GAIN = 1.7;

/** Dış ses: her cümle kendi dosyası, baştan sona çalar (hiç kesilmez) */
const Voices: React.FC<{ e: ExplainerEdit }> = ({ e }) => (
  <>
    {e.sentences.map((s, i) => {
      const from = Math.round((s.at - s.lead) * FPS);
      return (
        <Sequence key={i} from={Math.max(0, from)} layout="none">
          <Audio src={staticFile(s.src)} trimBefore={Math.max(0, -from)} volume={VOICE_GAIN} />
        </Sequence>
      );
    })}
  </>
);

/** Efektler ekranda görünen şeye denk gelir: kart değişince whoosh, doğrusu gelince sparkle, kapanış kartında pop */
const Sfx: React.FC<{ e: ExplainerEdit }> = ({ e }) => {
  const items: { at: number; src: string; v: number }[] = [];
  for (const [i, b] of e.beats.entries()) {
    if (i > 0) items.push({ at: b.from, src: "whoosh.wav", v: 0.22 });
    if (b.card.kind === "fix") {
      const says = e.sentences.filter((s) => s.beat === i);
      items.push({ at: says.at(-1)!.words.find((w) => w.key)?.t ?? says.at(-1)!.at, src: "sparkle.wav", v: 0.2 });
    }
    if (b.card.kind === "cta") items.push({ at: b.from + 14 / FPS, src: "pop.wav", v: 0.3 });
  }
  return (
    <>
      {items.map((x, i) => (
        <Sequence key={i} from={Math.round(x.at * FPS)} durationInFrames={FPS} layout="none">
          <Audio src={staticFile(x.src)} volume={x.v} />
        </Sequence>
      ))}
    </>
  );
};
