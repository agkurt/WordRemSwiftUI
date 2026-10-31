import {
  AbsoluteFill, Audio, Img, OffthreadVideo, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig,
} from "remotion";
import { loadFont as loadSerif } from "@remotion/google-fonts/Fraunces";
import { loadFont as loadHeavy } from "@remotion/google-fonts/Montserrat";
import { FPS } from "./types";

const { fontFamily: serif } = loadSerif("normal", { weights: ["700"], subsets: ["latin", "latin-ext"] });
const { fontFamily: heavy } = loadHeavy("normal", { weights: ["700", "800", "900"], subsets: ["latin", "latin-ext"] });

const C = { ink: "#1C1A17", accent: "#C2512F", accentDeep: "#9E3F22", yellow: "#FFD84D", green: "#2E9E5B", red: "#E0473A", night: "#14110F" };
const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** "Böcek Bob" bölümü: AI ile üretilmiş klip + Türkçe kurgu (zamanlar kaynak videoda saniye) */
export type BobEdit = {
  video: string;
  keeps: { from: number; to: number }[];
  hook: string;
  series: string;
  lines: { who: string; icon?: string; text: string; tr?: string; words: { w: string; t: number; end: number }[] }[];
  /** Hatanın düzeltildiği an: yanlış cümle, doğrusu (*yıldızlı* kısım sarı) ve Türkçesi */
  fix: { from: number; to: number; wrong: string; right: string; tr?: string;
    /** Kartın yeri: espri ekranın altındaysa (Bob zilin arkasında) kart üste çıkar. Varsayılan alt */
    at?: "top" | "bottom" };
  /** Bob doğrusunu söyleyip başardığında çıkan çıkartma */
  win?: { from: number; to: number; text: string };
  cta: string;
  outro: string;
  /**
   * Yatay (16:9) klip: video dikey kareye büyütülüp ortaya yerleşir, alt ve üst boşluğu aynı klibin bulanık hâli doldurur.
   * pan: [kaynak saniye, odak 0–1] kamera konuşan karaktere kayar (0 sol kenar, 1 sağ kenar)
   */
  pan?: [number, number][];
  /** Kanca yazısının kalktığı an (kurgu saniyesi): esprinin tepkisi erken gelirse üstüne binmesin. Varsayılan 2,8 */
  hookEnd?: number;
};

// Yatay klipte ön plandaki videonun yüksekliği ve üst kenarı (üst/alt bantlar platform arayüzüne denk gelir)
const LAND_H = 1320;
const LAND_TOP = 300;

export const BOB_OUTRO = 2.8;
export const bobMain = (e: BobEdit) => e.keeps.reduce((a, k) => a + k.to - k.from, 0);

const sourceAt = (e: BobEdit, t: number) => {
  let acc = 0;
  for (const k of e.keeps) { if (t < acc + k.to - k.from) return k.from + t - acc; acc += k.to - k.from; }
  return e.keeps.at(-1)?.to ?? 0;
};
const outputAt = (e: BobEdit, s: number) => {
  let acc = 0;
  for (const k of e.keeps) { if (s >= k.from && s <= k.to) return acc + s - k.from; acc += k.to - k.from; }
  return null;
};

/** Kaydırma: odak noktası (kaynak genişliğinin oranı) ekranın ortasına gelir, kenarlardan taşmaz; anahtar kareler arası yumuşak geçiş */
const panLeft = (e: BobEdit, s: number) => {
  const keys = e.pan!;
  const i = keys.findIndex(([t]) => t > s);
  const [t0, x0] = keys[Math.max(0, (i < 0 ? keys.length : i) - 1)];
  const [t1, x1] = keys[i < 0 ? keys.length - 1 : i];
  const p = t1 > t0 ? Math.min(1, Math.max(0, (s - t0) / (t1 - t0))) : 1;
  const ease = p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2;
  const focus = x0 + (x1 - x0) * ease;
  const w = (LAND_H * 16) / 9;
  return -Math.min(w - 1080, Math.max(0, focus * w - 540));
};

const highlight = (text: string, color: string) =>
  text.split(/(\*[^*]+\*)/).map((p, i) => (p.startsWith("*") ? <span key={i} style={{ color }}>{p.slice(1, -1)}</span> : p));

export const Bob: React.FC<BobEdit> = (e) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const main = bobMain(e);
  const mainFrames = Math.round(main * FPS);
  const t = frame / fps;
  const s = sourceAt(e, Math.min(t, main - 0.001));

  const cuts: number[] = [];
  let acc = 0;
  const clips = e.keeps.map((k, i) => {
    const from = Math.round(acc * FPS);
    if (i > 0) cuts.push(acc);
    acc += k.to - k.from;
    const to = Math.round(acc * FPS);
    const trim = { trimBefore: Math.round(k.from * FPS), trimAfter: Math.round(k.to * FPS) };
    const volume = (f: number) => interpolate(f, [0, 3, to - from - 3, to - from], [0, 1, 1, 0], clamp);
    return (
      <Sequence key={i} from={from} durationInFrames={to - from} layout="none">
        {e.pan ? (
          <>
            <OffthreadVideo src={staticFile(e.video)} {...trim} muted
              style={{ width: "100%", height: "100%", objectFit: "cover", filter: "blur(36px) brightness(0.55)", transform: "scale(1.15)" }} />
            <OffthreadVideo src={staticFile(e.video)} {...trim} volume={volume}
              style={{ position: "absolute", top: LAND_TOP, height: LAND_H, width: (LAND_H * 16) / 9, left: panLeft(e, s), maxWidth: "none" }} />
          </>
        ) : (
          <OffthreadVideo src={staticFile(e.video)} {...trim} volume={volume} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
        )}
      </Sequence>
    );
  });
  // Kesimde sıçramayı gizleyen kısa yakınlaşma; düzeltme kartında görüntü hafifçe kararır
  const bump = Math.max(0, ...cuts.map((c) => interpolate(t - c, [0, 0.25], [0.05, 0], clamp)));
  const dim = interpolate(s, [e.fix.from, e.fix.from + 0.3, e.fix.to - 0.3, e.fix.to], [0, 0.3, 0.3, 0], clamp);

  return (
    <AbsoluteFill style={{ background: C.night, fontFamily: heavy, overflow: "hidden" }}>
      <AbsoluteFill style={{ opacity: frame < mainFrames ? 1 : 0 }}>
        <AbsoluteFill style={{ transform: `scale(${1 + bump})` }}>{clips}</AbsoluteFill>
        <AbsoluteFill style={{ background: `rgba(10,8,6,${dim})` }} />
        <Captions e={e} s={s} />
        <Fix e={e} s={s} />
        <Win e={e} s={s} />
        <Hook e={e} t={t} />
        <div style={{ position: "absolute", left: 0, bottom: 0, height: 10, width: `${Math.min(1, t / main) * 100}%`,
          background: `linear-gradient(90deg, ${C.yellow}, ${C.accent})` }} />
      </AbsoluteFill>
      <Sfx e={e} mainFrames={mainFrames} />
      <Sequence from={mainFrames} durationInFrames={Math.round(BOB_OUTRO * FPS)}>
        <Outro e={e} />
      </Sequence>
    </AbsoluteFill>
  );
};

/** İlk saniyeler: soru büyük, seri adı küçük; ilk kare kapak olur */
const Hook: React.FC<{ e: BobEdit; t: number }> = ({ e, t }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const end = e.hookEnd ?? 2.8;
  if (t > end + 0.1) return null;
  const out = interpolate(t, [end - 0.5, end], [1, 0], clamp);
  const pop = spring({ frame, fps, config: { damping: 10, stiffness: 190 } });
  return (
    <div style={{ position: "absolute", top: 300, left: 50, right: 50, display: "flex", flexDirection: "column", alignItems: "center", gap: 26, opacity: out,
      transform: `scale(${1.06 - 0.06 * pop})` }}>
      <div style={{ background: C.accent, color: "white", fontSize: 36, fontWeight: 900, padding: "12px 28px", borderRadius: 999, transform: "rotate(-2deg)" }}>{e.series}</div>
      <div style={{ fontSize: 100, fontWeight: 900, lineHeight: 1.06, color: "white", textAlign: "center", WebkitTextStroke: "12px #0E0C0B", paintOrder: "stroke fill" }}>
        {highlight(e.hook, C.yellow)}
      </div>
    </div>
  );
};

/** Kelime kelime altyazı: konuşulan kelime turuncu kutuda, altında Türkçesi */
const Captions: React.FC<{ e: BobEdit; s: number }> = ({ e, s }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const line = e.lines.find((l) => s >= l.words[0].t - 0.15 && s <= l.words[l.words.length - 1].end + 0.5);
  if (!line || (s >= e.fix.from && s <= e.fix.to)) return null;
  const first = line.words[0].t;
  const pop = spring({ frame: frame - Math.round((s - first) * fps), fps, config: { damping: 12, mass: 0.5, stiffness: 180 } });
  const bob = line.who === "Bob";
  return (
    // Sağdaki düğme sütununa taşmasın (types.ts → SAFE)
    <div style={{ position: "absolute", left: 70, right: 150, top: 1130, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ background: bob ? C.yellow : "white", color: C.ink, fontSize: 30, fontWeight: 900, padding: "8px 22px", borderRadius: 999, marginBottom: 18,
        letterSpacing: 1.5 }}>{bob ? "🐜 BOB" : `${line.icon ?? "☕"} ${line.who.toUpperCase()}`}</div>
      <div style={{ display: "flex", flexWrap: "wrap", justifyContent: "center", gap: "4px 16px", transform: `scale(${0.85 + 0.15 * pop})` }}>
        {line.words.map((w, k) => {
          const active = s >= w.t && s < (line.words[k + 1]?.t ?? w.end + 0.3);
          const said = s >= w.t;
          return (
            <span key={k} style={{ fontSize: 76, fontWeight: 900, lineHeight: 1.1, padding: "0 12px", borderRadius: 16,
              color: "white", opacity: said ? 1 : 0.35, background: active ? C.accent : "transparent",
              WebkitTextStroke: active ? "0px" : "11px #0E0C0B", paintOrder: "stroke fill" }}>{w.w}</span>
          );
        })}
      </div>
      {line.tr ? (
        <div style={{ marginTop: 22, background: "white", color: C.ink, fontSize: 40, fontWeight: 800, padding: "12px 30px", borderRadius: 36, textAlign: "center",
          opacity: interpolate(s, [first, first + 0.3], [0, 1], clamp) }}>{line.tr}</div>
      ) : null}
    </div>
  );
};

/** Düzeltme kartı: yanlış cümle çizilir, doğrusu sarıyla düşer */
const Fix: React.FC<{ e: BobEdit; s: number }> = ({ e, s }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { from, to, wrong, right, tr, at: place = "bottom" } = e.fix;
  if (s < from || s > to) return null;
  const at = (sec: number) => frame - Math.round((s - sec) * fps);
  const a = spring({ frame: at(from), fps, config: { damping: 11, stiffness: 190 } });
  const strike = interpolate(s, [from + 0.45, from + 0.75], [0, 100], clamp);
  const b = spring({ frame: at(from + 0.9), fps, config: { damping: 9, stiffness: 200 } });
  const out = interpolate(s, [to - 0.25, to], [1, 0], clamp);
  return (
    // Kart alt yarıda: Bob'un donup kaldığı yüz (bölümün esprisi) üstte görünür kalır
    <AbsoluteFill style={{ alignItems: "center", justifyContent: place === "top" ? "flex-start" : "flex-end",
      padding: place === "top" ? "260px 140px 0" : "0 140px 470px", gap: 30, opacity: out }}>
      <div style={{ position: "relative", background: "white", color: C.ink, fontSize: 64, fontWeight: 900, padding: "22px 40px", borderRadius: 30,
        transform: `scale(${a}) rotate(-3deg)`, boxShadow: "0 20px 50px rgba(0,0,0,0.5)" }}>
        ❌ {wrong}
        <div style={{ position: "absolute", left: 90, top: "52%", height: 9, width: `calc(${strike}% - 120px)`, background: C.red, borderRadius: 5 }} />
      </div>
      <div style={{ background: C.green, color: "white", fontSize: 70, fontWeight: 900, lineHeight: 1.1, padding: "28px 44px", borderRadius: 34, textAlign: "center",
        transform: `scale(${b}) rotate(2deg)`, boxShadow: "0 24px 60px rgba(0,0,0,0.5)" }}>
        ✅ {highlight(right, C.yellow)}
        {tr ? <div style={{ fontSize: 42, fontWeight: 800, marginTop: 14, color: "rgba(255,255,255,0.92)" }}>= {tr}</div> : null}
      </div>
    </AbsoluteFill>
  );
};

const Sfx: React.FC<{ e: BobEdit; mainFrames: number }> = ({ e, mainFrames }) => {
  const at = (sec: number) => { const o = outputAt(e, sec); return o == null ? null : Math.round(o * FPS); };
  const items = [
    { f: 0, src: "whoosh.wav", v: 0.45 },
    { f: at(e.fix.from), src: "pop.wav", v: 0.6 },
    { f: at(e.fix.from + 0.9), src: "ding.wav", v: 0.5 },
    { f: e.win ? at(e.win.from) : null, src: "sparkle.wav", v: 0.45 },
    { f: mainFrames - 6, src: "whoosh.wav", v: 0.45 },
    { f: mainFrames + 6, src: "sparkle.wav", v: 0.35 },
  ];
  return <>{items.filter((x) => x.f != null && x.f >= 0).map((x, i) => (
    <Sequence key={i} from={x.f!} durationInFrames={FPS} layout="none"><Audio src={staticFile(x.src)} volume={x.v} /></Sequence>
  ))}</>;
};

const Outro: React.FC<{ e: BobEdit }> = ({ e }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const icon = spring({ frame, fps, config: { damping: 11, mass: 0.7 } });
  const text = spring({ frame: frame - 6, fps, config: { damping: 15 } });
  const btn = spring({ frame: frame - 12, fps, config: { damping: 9, stiffness: 170 } });
  return (
    <AbsoluteFill style={{ background: `linear-gradient(160deg, ${C.accent} 0%, ${C.accentDeep} 100%)`, alignItems: "center", justifyContent: "center",
      fontFamily: heavy, padding: "0 70px" }}>
      <div style={{ fontSize: 62, fontWeight: 900, color: "white", textAlign: "center", lineHeight: 1.15, marginBottom: 60, opacity: text,
        transform: `translateY(${(1 - text) * -30}px)` }}>{highlight(e.outro, C.yellow)}</div>
      <Img src={staticFile("icon.png")} style={{ width: 240, height: 240, borderRadius: 56, transform: `scale(${icon})`, boxShadow: "0 30px 70px rgba(0,0,0,0.35)" }} />
      <div style={{ fontFamily: serif, fontWeight: 700, fontSize: 96, color: "white", marginTop: 40, opacity: text }}>WordRem AI</div>
      <div style={{ marginTop: 50, transform: `scale(${btn * (1 + 0.04 * Math.sin(frame / 4))})`, background: "white", color: C.accent, fontSize: 40,
        fontWeight: 900, padding: "24px 44px", borderRadius: 999, whiteSpace: "nowrap" }}>{e.cta}</div>
    </AbsoluteFill>
  );
};

const Win: React.FC<{ e: BobEdit; s: number }> = ({ e, s }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (!e.win || s < e.win.from || s > e.win.to) return null;
  const pop = spring({ frame: frame - Math.round((s - e.win.from) * fps), fps, config: { damping: 8, stiffness: 210 } });
  return (
    <div style={{ position: "absolute", top: 420, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
      <div style={{ background: C.green, color: "white", fontSize: 66, fontWeight: 900, padding: "20px 44px", borderRadius: 30,
        transform: `scale(${pop}) rotate(${-4 + 2 * Math.sin(frame / 5)}deg)`, boxShadow: "0 20px 50px rgba(0,0,0,0.45)" }}>{e.win.text}</div>
    </div>
  );
};
