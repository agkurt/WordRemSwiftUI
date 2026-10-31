import {
  AbsoluteFill, Audio, Img, OffthreadVideo, Sequence, interpolate, random, spring, staticFile, useCurrentFrame, useVideoConfig,
} from "remotion";
import { loadFont as loadSerif } from "@remotion/google-fonts/Fraunces";
import { loadFont as loadHeavy } from "@remotion/google-fonts/Montserrat";
import { mainSeconds, outputAt, sourceAt } from "./Conversation";
import { Edit, FLAGS, FPS, HOOK_SECONDS, Line, OUTRO_SECONDS, RECAP_SECONDS, UI } from "./types";

const { fontFamily: serif } = loadSerif("normal", { weights: ["700"], subsets: ["latin", "latin-ext"] });
const { fontFamily: heavy } = loadHeavy("normal", { weights: ["700", "800", "900"], subsets: ["latin", "latin-ext"] });

// Uygulamanın renkleri + videoya özel vurgular
const C = { ink: "#1C1A17", accent: "#C2512F", accentDeep: "#9E3F22", yellow: "#FFD84D", green: "#2E9E5B", night: "#14110F" };

// Kayıt kartı: ekranı neredeyse doldurur, kenarlarda zemin görünür
const CARD_W = 700;
const CARD_TOP = 262;
const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

type Token = { w: string; t: number; target: boolean };

/** Satırdaki konuşmanın oranı (0–1) → kaynak saniye: yalnızca sesli bölümlerde ilerler, susulan aralarda durur */
const voicedAt = (l: Line, frac: number) => {
  const segs = l.segs?.length ? l.segs : [[l.start + 0.15, l.end] as [number, number]];
  const total = segs.reduce((a, [x, y]) => a + y - x, 0);
  let left = frac * total;
  for (const [x, y] of segs) {
    if (left <= y - x) return x + left;
    left -= y - x;
  }
  return segs[segs.length - 1][1];
};

/** Satırı kelimelere böler: tırnak içi öğrenilen dil (sarı), zamanlar öğrencide gerçek, Lupa'da sesli bölümlere harf sayısına göre */
const tokens = (l: Line): Token[] => {
  if (l.who === "you" && l.words.length) return l.words.map((w) => ({ w: w.w, t: w.t, target: true }));
  const you = l.who === "you";
  const raw = l.text.split(/\s+/).filter(Boolean);
  const total = raw.reduce((a, w) => a + w.length + 1, 0);
  // Öğrenilen dil *yıldız* içinde işaretliyse o, değilse tırnak içi
  const marked = l.text.includes("*");
  const open = marked ? /^\*/ : /^["“]/;
  const close = marked ? /\*[,.!?)]*$/ : /["”][,.!?)]*$/;
  let acc = 0;
  let quoted = false;
  return raw.map((w) => {
    const opens = open.test(w);
    const closes = close.test(w);
    if (opens) quoted = true;
    const tok = { w: w.replace(/["“”*]/g, ""), t: voicedAt(l, acc / total), target: you || (quoted && l.who === "lupa") };
    if (closes) quoted = false;
    acc += w.length + 1;
    return tok;
  });
};

/** Altyazı parçaları: en fazla 4 kelime, cümle sonunda yeni parça */
const chunks = (toks: Token[]) => {
  const out: Token[][] = [];
  let cur: Token[] = [];
  for (const tk of toks) {
    cur.push(tk);
    if (cur.length >= 4 || /[.!?:]$/.test(tk.w)) { out.push(cur); cur = []; }
  }
  if (cur.length) out.push(cur);
  return out;
};

const muted = (e: Edit, s: number) => e.lines.some((l) => l.mute && s >= l.mute[0] && s <= l.mute[1]);

/** Öğrencinin OpenAI sesi: konuşma satırın başladığı anda başlar */
const Voices: React.FC<{ e: Edit }> = ({ e }) => (
  <>
    {e.lines.filter((l) => l.voice).map((l, i) => {
      const at = outputAt(e, l.start);
      if (at == null) return null;
      const from = Math.round((at - l.voice!.lead) * FPS);
      return (
        <Sequence key={i} from={Math.max(0, from)} layout="none">
          <Audio src={staticFile(l.voice!.src)} trimBefore={Math.max(0, -from)} />
        </Sequence>
      );
    })}
  </>
);

const lineAt = (e: Edit, s: number) => e.lines.findIndex((l) => s >= l.start - 0.15 && s <= l.end + 0.4);
const lastStarted = (e: Edit, s: number) => e.lines.reduce((acc, l, i) => (s >= l.start - 0.15 ? i : acc), -1);

export const Reel: React.FC<Edit> = (e) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const main = mainSeconds(e);
  const mainFrames = Math.round(main * FPS);
  const t = frame / fps;
  const s = sourceAt(e, Math.min(t, main - 0.001));
  const ui = UI[e.lang ?? "en"];

  // Kesim noktaları (kurgu saniyesi): sıçramayı gizleyen kısa yakınlaşma
  const cuts: number[] = [];
  let acc = 0;
  const clips = e.keeps.map((k, i) => {
    const from = Math.round(acc * FPS);
    if (i > 0) cuts.push(acc);
    acc += k.to - k.from;
    const to = Math.round(acc * FPS);
    return (
      <Sequence key={i} from={from} durationInFrames={to - from} layout="none">
        <OffthreadVideo src={staticFile(e.video)} trimBefore={Math.round(k.from * FPS)} trimAfter={Math.round(k.to * FPS)}
          // Kesimlerde çıt sesi olmasın: her parçanın sesi 2 karede açılıp kapanır; öğrencinin telefondaki sesi yerine OpenAI sesi çalar
          volume={(f) => muted(e, k.from + f / FPS) ? 0 : interpolate(f, [0, 2, to - from - 2, to - from], [0, 1, 1, 0], clamp)}
          style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </Sequence>
    );
  });

  // Kamera: her yeni satırda yumuşak yakınlaşma ve hafif dönme; öğrencinin sırasında karta daha çok yaklaşır
  const li = lastStarted(e, s);
  const target = (i: number) => (i < 0 ? 1 : e.lines[i].who === "you" ? 1.1 : 1.03 + 0.02 * (i % 2));
  const p = li < 0 ? 1 : interpolate(s, [e.lines[li].start - 0.15, e.lines[li].start + 0.35], [0, 1], clamp);
  const ease = 1 - Math.pow(1 - p, 3);
  const cutBump = Math.max(0, ...cuts.map((c) => interpolate(t - c, [0, 0.22], [0.035, 0], clamp)));
  const zoom = (target(li - 1) + (target(li) - target(li - 1)) * ease) * (1 + cutBump);
  const rot = li < 0 ? 0 : (li % 2 ? 0.6 : -0.6) * ease;
  const cardH = Math.round(CARD_W * (e.height / e.width));
  const enter = spring({ frame, fps, config: { damping: 16, mass: 0.7 } });

  return (
    <AbsoluteFill style={{ background: C.night, fontFamily: heavy, overflow: "hidden" }}>
      <Glow t={t} />
      <AbsoluteFill style={{ opacity: frame < mainFrames ? 1 : 0 }}>
        <div style={{
          position: "absolute", left: (1080 - CARD_W) / 2, top: CARD_TOP, width: CARD_W, height: cardH,
          borderRadius: 54, overflow: "hidden", background: "#F6F2EA",
          boxShadow: "0 40px 120px rgba(0,0,0,0.55), 0 0 0 3px rgba(255,255,255,0.06)",
          transform: `scale(${zoom * (0.92 + 0.08 * enter)}) rotate(${rot}deg)`, transformOrigin: "50% 46%",
        }}>
          {clips}
        </div>
        <CardMoments e={e} s={s} t={t} />
        <Phrase e={e} s={s} />
        <Counter e={e} s={s} t={t} />
        <Hook text={e.hook} sub={ui.real} t={t} />
        {/* Altyazı ilk saniye yazısının da üstünde: video doğrudan öğretilen cümleyle başlar */}
        <Captions e={e} s={s} />
        <Progress p={t / main} />
      </AbsoluteFill>
      <Voices e={e} />
      <Sfx e={e} mainFrames={mainFrames} />
      <Sequence from={mainFrames} durationInFrames={Math.round(RECAP_SECONDS * FPS)}>
        <Recap e={e} />
      </Sequence>
      <Sequence from={mainFrames + Math.round(RECAP_SECONDS * FPS)} durationInFrames={Math.round(OUTRO_SECONDS * FPS)}>
        <Outro e={e} />
      </Sequence>
    </AbsoluteFill>
  );
};

/** Koyu zeminde yavaşça dolaşan sıcak ışıklar */
const Glow: React.FC<{ t: number }> = ({ t }) => (
  <AbsoluteFill>
    <div style={{ position: "absolute", width: 1100, height: 1100, borderRadius: "50%", left: -500 + 120 * Math.sin(t / 2.2), top: -300,
      background: "radial-gradient(circle, rgba(194,81,47,0.55), rgba(194,81,47,0) 65%)" }} />
    <div style={{ position: "absolute", width: 1000, height: 1000, borderRadius: "50%", right: -480 + 100 * Math.cos(t / 2.7), bottom: -200,
      background: "radial-gradient(circle, rgba(255,216,77,0.22), rgba(255,216,77,0) 65%)" }} />
  </AbsoluteFill>
);

/** Kelime kelime altyazı: konuşulan kelime turuncu kutuda, öğrenilen dil sarı */
const Captions: React.FC<{ e: Edit; s: number }> = ({ e, s }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const i = lineAt(e, s);
  if (i < 0) return null;
  const line = e.lines[i];
  const toks = tokens(line);
  const parts = chunks(toks);
  const ci = parts.reduce((acc, c, k) => (s >= c[0].t ? k : acc), 0);
  const chunk = parts[ci];
  const startFrame = frame - Math.round((s - chunk[0].t) * fps);
  const pop = spring({ frame: frame - startFrame, fps, config: { damping: 12, mass: 0.5, stiffness: 180 } });
  const lupa = line.who === "lupa";
  const ui = UI[e.lang ?? "en"];
  return (
    <div style={{ position: "absolute", left: 50, right: 50, top: 1190, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{
        display: "flex", alignItems: "center", gap: 12, padding: "10px 24px", borderRadius: 999, marginBottom: 22,
        background: lupa ? C.accent : "white", color: lupa ? "white" : C.ink, fontSize: 32, fontWeight: 900, letterSpacing: 1.5,
        boxShadow: "0 10px 30px rgba(0,0,0,0.35)",
      }}>
        <Bars on={s <= line.end} light={lupa} />
        {(lupa ? ui.lupa : ui.you).toUpperCase()}
      </div>
      <div style={{ display: "flex", flexWrap: "wrap", justifyContent: "center", gap: "6px 18px",
        transform: `scale(${0.82 + 0.18 * pop}) translateY(${(1 - pop) * 30}px)`, opacity: Math.min(1, pop * 1.4) }}>
        {chunk.map((tk, k) => {
          const next = chunk[k + 1]?.t ?? (parts[ci + 1]?.[0].t ?? line.end + 0.3);
          const active = s >= tk.t && s < next;
          return (
            <span key={k} style={{
              fontSize: 84, fontWeight: 900, lineHeight: 1.12, padding: "0 14px", borderRadius: 18,
              color: active ? "white" : tk.target ? C.yellow : "white",
              background: active ? C.accent : "transparent",
              WebkitTextStroke: active ? "0px" : "11px #0E0C0B", paintOrder: "stroke fill",
              transform: `scale(${active ? 1.08 : 1}) rotate(${active ? (k % 2 ? 1.5 : -1.5) : 0}deg)`,
              boxShadow: active ? "0 10px 26px rgba(194,81,47,0.55)" : "none",
            }}>{tk.w}</span>
          );
        })}
      </div>
      {line.tr ? (
        <div style={{ marginTop: 26, background: "white", color: C.ink, fontSize: 42, fontWeight: 800, padding: "14px 30px",
          borderRadius: 999, boxShadow: "0 12px 30px rgba(0,0,0,0.35)", opacity: interpolate(s, [line.start, line.start + 0.3], [0, 1], clamp) }}>
          = {line.tr}
        </div>
      ) : null}
    </div>
  );
};

/** Konuşma çubukları (uygulamanın logosundaki gibi) */
const Bars: React.FC<{ on: boolean; light: boolean }> = ({ on, light }) => {
  const frame = useCurrentFrame();
  return (
    <div style={{ display: "flex", gap: 5, alignItems: "center", height: 30 }}>
      {[0, 1, 2, 3].map((i) => (
        <div key={i} style={{ width: 7, borderRadius: 4, background: light ? "white" : C.accent,
          height: on ? 10 + 18 * (0.5 + 0.5 * Math.sin(frame / 3 + i * 1.3)) : 10 }} />
      ))}
    </div>
  );
};

/** Kart anı: flaş + "Sıra sende"; öğrenci söyleyince övgü + konfeti */
const CardMoments: React.FC<{ e: Edit; s: number; t: number }> = ({ e, s }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const ui = UI[e.lang ?? "en"];
  const you = e.lines.filter((l) => l.who === "you");
  const card = [...e.cards].reverse().find((c) => s >= c.t);
  const nextYou = card ? you.find((l) => l.start >= card.t - 0.2) : undefined;
  const flash = card ? interpolate(s - card.t, [0, 0.18], [0.45, 0], clamp) : 0;
  const showTurn = card && nextYou && s < nextYou.start;
  const turnPop = card ? spring({ frame: frame - Math.round((s - card.t) * fps), fps, config: { damping: 9, stiffness: 200 } }) : 0;
  const done = you.findIndex((l) => s >= l.end && s < l.end + 1.2);
  const doneLine = done >= 0 ? you[done] : undefined;
  const praisePop = doneLine ? spring({ frame: frame - Math.round((s - doneLine.end) * fps), fps, config: { damping: 8, stiffness: 220 } }) : 0;
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      <AbsoluteFill style={{ background: "white", opacity: flash }} />
      {showTurn ? (
        <Sticker text={ui.yourTurn} bg="white" color={C.ink} rot={-5} pop={turnPop} />
      ) : null}
      {doneLine ? (
        <>
          <Sticker text={ui.praise[done % ui.praise.length]} bg={C.green} color="white" rot={4} pop={praisePop} />
          <Confetti seed={done} since={s - doneLine.end} />
        </>
      ) : null}
    </AbsoluteFill>
  );
};

const Sticker: React.FC<{ text: string; bg: string; color: string; rot: number; pop: number }> = ({ text, bg, color, rot, pop }) => (
  <div style={{ position: "absolute", top: 540, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
    <div style={{ background: bg, color, fontSize: 60, fontWeight: 900, padding: "18px 40px", borderRadius: 26,
      transform: `rotate(${rot}deg) scale(${pop})`, boxShadow: "0 18px 40px rgba(0,0,0,0.4)" }}>{text}</div>
  </div>
);

const Confetti: React.FC<{ seed: number; since: number }> = ({ seed, since }) => {
  const colors = [C.accent, C.yellow, C.green, "white", "#F3E2D8"];
  return (
    <AbsoluteFill>
      {Array.from({ length: 34 }).map((_, i) => {
        const a = random(`a${seed}-${i}`) * Math.PI * 2;
        const v = 700 + random(`v${seed}-${i}`) * 900;
        const x = 540 + Math.cos(a) * v * since;
        const y = 590 + Math.sin(a) * v * since * 0.8 + 1400 * since * since;
        return <div key={i} style={{ position: "absolute", left: x, top: y, width: 16, height: 26, borderRadius: 4,
          background: colors[i % colors.length], opacity: interpolate(since, [0.7, 1.1], [1, 0], clamp),
          transform: `rotate(${since * 720 * (i % 2 ? 1 : -1) + i * 20}deg)` }} />;
      })}
    </AbsoluteFill>
  );
};

/** Üstte dil ve tur sayacı */
const Counter: React.FC<{ e: Edit; s: number; t: number }> = ({ e, s, t }) => {
  const you = e.lines.filter((l) => l.who === "you");
  const n = you.filter((l) => s >= l.start - 0.15).length;
  const name = new Intl.DisplayNames([e.lang ?? "en"], { type: "language" }).of(e.target ?? "en") ?? "";
  const o = interpolate(t, [HOOK_SECONDS - 0.2, HOOK_SECONDS + 0.2], [0, 1], clamp);
  return (
    <div style={{ position: "absolute", top: 160, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: o }}>
      <div style={{ display: "flex", alignItems: "center", gap: 16, background: "rgba(20,17,15,0.75)", color: "white",
        padding: "14px 28px", borderRadius: 999, fontSize: 36, fontWeight: 800, border: "2px solid rgba(255,255,255,0.12)" }}>
        <span>{FLAGS[e.target ?? "en"]} {name.charAt(0).toUpperCase() + name.slice(1)}</span>
        <div style={{ display: "flex", gap: 8 }}>
          {you.map((_, i) => <div key={i} style={{ width: 34, height: 12, borderRadius: 6, background: i < n ? C.yellow : "rgba(255,255,255,0.25)" }} />)}
        </div>
      </div>
    </div>
  );
};

/** İlk saniye: kelimeler tek tek çakılır, ekran hafifçe sarsılır */
const Hook: React.FC<{ text: string; sub: string; t: number }> = ({ text, sub, t }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (t > HOOK_SECONDS + 0.25) return null;
  const words = text.split(" ");
  const out = interpolate(t, [HOOK_SECONDS - 0.25, HOOK_SECONDS + 0.1], [1, 0], clamp);
  const shake = interpolate(t, [0, 0.35], [1, 0], clamp);
  return (
    <AbsoluteFill style={{ background: `linear-gradient(180deg, rgba(20,17,15,${0.88 * out}) 0%, rgba(20,17,15,${0.6 * out}) 60%, rgba(20,17,15,0) 100%)` }}>
      <div style={{ position: "absolute", top: 330, left: 60, right: 60, display: "flex", flexWrap: "wrap", justifyContent: "center", gap: "4px 22px",
        // İlk kare kapak olur: yazı baştan tam görünür, blok hafif büyükten yerine oturur
        opacity: out, transform: `translate(${shake * 8 * Math.sin(frame * 2.3)}px, ${shake * 6 * Math.cos(frame * 1.7)}px) scale(${1.08 - 0.08 * spring({ frame, fps, config: { damping: 9, stiffness: 200 } })})` }}>
        {words.map((w, i) => {
          const last = i === words.length - 1 || i === words.length - 2;
          return <span key={i} style={{ fontSize: 108, fontWeight: 900, lineHeight: 1.08, color: last ? C.yellow : "white",
            WebkitTextStroke: "12px #0E0C0B", paintOrder: "stroke fill", display: "inline-block" }}>{w}</span>;
        })}
        <div style={{ width: "100%", display: "flex", justifyContent: "center", marginTop: 34 }}>
          <div style={{ background: C.accent, color: "white", fontSize: 40, fontWeight: 800, padding: "14px 30px", borderRadius: 999,
            transform: `scale(${0.9 + 0.1 * spring({ frame, fps, config: { damping: 12 } })})` }}>{sub}</div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

/** Ses efektleri: açılış ve kapanışta whoosh, kart gelince pop, doğru cevapta sparkle */
const Sfx: React.FC<{ e: Edit; mainFrames: number }> = ({ e, mainFrames }) => {
  const at = (sec: number | null) => (sec == null ? null : Math.round(sec * FPS));
  const items: { f: number | null; src: string; v: number }[] = [
    { f: 0, src: "whoosh.wav", v: 0.5 },
    { f: mainFrames - 6, src: "whoosh.wav", v: 0.5 },
    { f: mainFrames + Math.round(RECAP_SECONDS * FPS) - 6, src: "whoosh.wav", v: 0.45 },
    { f: mainFrames + Math.round(RECAP_SECONDS * FPS) + 4, src: "sparkle.wav", v: 0.35 },
    ...e.lines.filter((l) => l.who === "you").map((_, i) => ({ f: mainFrames + 8 + i * 7, src: "pop.wav", v: 0.4 })),
    ...e.cards.map((c) => ({ f: at(outputAt(e, c.t)), src: "pop.wav", v: 0.55 })),
    ...e.lines.filter((l) => l.who === "you").map((l) => ({ f: at(outputAt(e, l.end)), src: "sparkle.wav", v: 0.3 })),
  ];
  return (
    <>
      {items.filter((x) => x.f != null && x.f >= 0).map((x, i) => (
        <Sequence key={i} from={x.f!} durationInFrames={FPS} layout="none">
          <Audio src={staticFile(x.src)} volume={x.v} />
        </Sequence>
      ))}
    </>
  );
};

const Outro: React.FC<{ e: Edit }> = ({ e }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const ui = UI[e.lang ?? "en"];
  const name = new Intl.DisplayNames([e.lang ?? "en"], { type: "language" }).of(e.target ?? "en") ?? "";
  const icon = spring({ frame, fps, config: { damping: 11, mass: 0.7 } });
  const text = spring({ frame: frame - 6, fps, config: { damping: 15 } });
  const btn = spring({ frame: frame - 12, fps, config: { damping: 9, stiffness: 170 } });
  const pulse = 1 + 0.04 * Math.sin(frame / 4);
  return (
    <AbsoluteFill style={{ background: `linear-gradient(160deg, ${C.accent} 0%, ${C.accentDeep} 100%)`, alignItems: "center", justifyContent: "center", fontFamily: heavy }}>
      <Img src={staticFile("icon.png")} style={{ width: 300, height: 300, borderRadius: 70,
        transform: `scale(${icon}) rotate(${(1 - icon) * -25}deg)`, boxShadow: "0 30px 70px rgba(0,0,0,0.35)" }} />
      <div style={{ opacity: text, transform: `translateY(${(1 - text) * 40}px)`, textAlign: "center", marginTop: 60 }}>
        <div style={{ fontFamily: serif, fontWeight: 700, fontSize: 112, color: "white" }}>WordRem AI</div>
        <div style={{ fontSize: 50, fontWeight: 800, color: "rgba(255,255,255,0.88)", marginTop: 12 }}>
          {ui.speak(name.charAt(0).toUpperCase() + name.slice(1))}
        </div>
      </div>
      <div style={{ marginTop: 70, transform: `scale(${btn * pulse})`, background: "white", color: C.accent, fontSize: 48, fontWeight: 900,
        padding: "30px 60px", borderRadius: 999, boxShadow: "0 20px 44px rgba(0,0,0,0.3)" }}>{e.cta}</div>
    </AbsoluteFill>
  );
};

/** Alttaki ince ilerleme çizgisi: izleyici videonun ne kadar kaldığını görür, sonuna kadar kalır */
const Progress: React.FC<{ p: number }> = ({ p }) => (
  <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 10, background: "rgba(255,255,255,0.12)" }}>
    <div style={{ width: `${Math.min(1, p) * 100}%`, height: "100%", background: `linear-gradient(90deg, ${C.yellow}, ${C.accent})` }} />
  </div>
);

/** Kapanıştan önce özet: öğrencinin söylediği cümleler ve anlamları sırayla düşer ("kaydet" çağrısıyla) */
const Recap: React.FC<{ e: Edit }> = ({ e }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const ui = UI[e.lang ?? "en"];
  const you = e.lines.filter((l) => l.who === "you");
  const head = spring({ frame, fps, config: { damping: 14 } });
  const save = spring({ frame: frame - 8 - you.length * 7, fps, config: { damping: 9, stiffness: 180 } });
  return (
    <AbsoluteFill style={{ background: C.night, fontFamily: heavy, alignItems: "center", justifyContent: "center", padding: "0 70px" }}>
      <Glow t={frame / fps} />
      <div style={{ fontSize: 60, fontWeight: 900, color: C.yellow, letterSpacing: 1, opacity: head, transform: `translateY(${(1 - head) * -30}px)`,
        marginBottom: 46, textAlign: "center" }}>{ui.recap} {FLAGS[e.target ?? "en"]}</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 30, width: "100%" }}>
        {you.map((l, i) => {
          const p = spring({ frame: frame - 8 - i * 7, fps, config: { damping: 13, stiffness: 170 } });
          return (
            <div key={i} style={{ background: "white", borderRadius: 30, padding: "26px 34px", boxShadow: "0 16px 40px rgba(0,0,0,0.4)",
              opacity: p, transform: `translateX(${(1 - p) * (i % 2 ? 160 : -160)}px) rotate(${(i % 2 ? 1 : -1) * (1 - p) * 4}deg)` }}>
              <div style={{ fontSize: 64, fontWeight: 900, color: C.ink, lineHeight: 1.12 }}>{l.text}</div>
              {l.tr ? <div style={{ fontSize: 44, fontWeight: 800, color: C.accent, marginTop: 10 }}>= {l.tr}</div> : null}
            </div>
          );
        })}
      </div>
      <div style={{ marginTop: 60, background: C.accent, color: "white", fontSize: 48, fontWeight: 900, padding: "18px 36px", borderRadius: 999,
        transform: `scale(${save}) rotate(-2deg)` }}>{ui.save}</div>
    </AbsoluteFill>
  );
};

/** Lupa öğrenilen dilde bir cümle söylerken o cümle üstte büyük bir kart olarak düşer (uzun satırlarda yeni görsel ödül) */
const Phrase: React.FC<{ e: Edit; s: number }> = ({ e, s }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const i = lineAt(e, s);
  const line = e.lines[i];
  if (!line || line.who !== "lupa" || s > line.end + 0.2) return null;
  // Ardışık öğrenilen dil kelimeleri bir ifade
  const phrases: { t: number; text: string }[] = [];
  let prev = false;
  for (const tk of tokens(line)) {
    if (tk.target && !prev) phrases.push({ t: tk.t, text: tk.w });
    else if (tk.target) phrases[phrases.length - 1].text += ` ${tk.w}`;
    prev = tk.target;
  }
  const cur = [...phrases].reverse().find((p) => s >= p.t - 0.1);
  if (!cur) return null;
  const pop = spring({ frame: frame - Math.round((s - cur.t) * fps), fps, config: { damping: 11, stiffness: 190 } });
  const out = interpolate(s, [line.end, line.end + 0.2], [1, 0], clamp);
  return (
    <div style={{ position: "absolute", top: 470, left: 60, right: 60, display: "flex", justifyContent: "center", opacity: out }}>
      <div style={{ background: C.yellow, color: C.ink, fontSize: 56, fontWeight: 900, lineHeight: 1.12, padding: "22px 36px", borderRadius: 28,
        textAlign: "center", boxShadow: "0 18px 44px rgba(0,0,0,0.45)", transform: `scale(${pop}) rotate(${-2 + 2 * (phrases.indexOf(cur) % 2) * 2}deg)` }}>
        {FLAGS[e.target ?? "en"]} {cur.text}
      </div>
    </div>
  );
};
