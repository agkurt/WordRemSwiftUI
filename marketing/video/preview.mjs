// Render'dan önce önizleme: videoyu baştan sona render etmeden ana anların karelerini çıkarır.
//   node preview.mjs ex01            →  preview/ex01/sheet.png (+ tek tek kareler)
//   node preview.mjs ex01 2.4 7.5    →  yalnızca bu saniyeler
// Kompozisyon kurgu dosyasından seçilir (explainer → Explainer, Bob bölümü → Bob, diğerleri → Reel).
// Karelerde platform arayüzünün örttüğü bölgeler kırmızıdır: yazı oraya taşmamalı. Claude bakar, düzeltir, sonra render.mjs.
import fs from "node:fs";
import path from "node:path";
import { bundle } from "@remotion/bundler";
import { renderStill, selectComposition } from "@remotion/renderer";

const id = process.argv[2];
if (!id) throw new Error("kullanım: node preview.mjs <id> [saniye]...");
const edit = JSON.parse(fs.readFileSync(`edits/${id}.json`));
const compId = edit.kind === "explainer" ? "Explainer" : edit.series ? "Bob" : "Reel";
const browserExecutable = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const dir = `preview/${id}`;
fs.rmSync(dir, { recursive: true, force: true });
fs.mkdirSync(dir, { recursive: true });

const serveUrl = await bundle({ entryPoint: path.resolve("src/index.ts") });
const comp = await selectComposition({ serveUrl, id: compId, inputProps: edit, browserExecutable });
const total = comp.durationInFrames / comp.fps;

/** Kurgu saniyesi (kaynak videoda saniye → çıkış saniyesi) */
const outAt = (s) => {
  let a = 0;
  for (const k of edit.keeps ?? []) { if (s >= k.from && s <= k.to) return a + (s - k.from); a += k.to - k.from; }
  return null;
};
/** Ana anlar: kapak, her cümlenin/satırın sonuna yakın (bütün kelimeler ekranda), kapanış */
const moments = () => {
  const asked = process.argv.slice(3).map(Number).filter((n) => !Number.isNaN(n));
  if (asked.length) return asked.map((t) => [`${t}s`, t]);
  const out = [["cover", 0]];
  if (edit.kind === "explainer") {
    for (const [i, s] of edit.sentences.entries()) out.push([`s${i + 1}`, Math.max(s.at + 0.2, s.at + s.dur - 0.15)]);
  } else {
    for (const [i, l] of edit.lines.entries()) {
      const start = l.start ?? l.words[0].t, end = l.end ?? l.words.at(-1).end;
      const t = outAt(start + (end - start) * 0.8);
      if (t != null) out.push([`line${i + 1}`, t]);
    }
  }
  out.push(["outro", total - 0.3]);
  return out.filter(([, t]) => t >= 0 && t < total);
};

const shots = [];
for (const [name, t] of moments()) {
  const frame = Math.min(comp.durationInFrames - 1, Math.round(t * comp.fps));
  const file = `${dir}/${String(shots.length + 1).padStart(2, "0")}-${name}.png`;
  await renderStill({ serveUrl, composition: comp, frame, output: file, inputProps: edit, browserExecutable, scale: 0.5 });
  shots.push({ name, t, file });
}

// Izgara: kareler paketin public/ klasörüne kopyalanır (paket public/'i paketleme anında kopyaladığı için oraya yazılır)
const pub = path.join(serveUrl, "public", "review", `preview-${id}`);
fs.mkdirSync(pub, { recursive: true });
const images = shots.map((s, i) => { fs.copyFileSync(s.file, path.join(pub, `${i}.png`)); return `review/preview-${id}/${i}.png`; });
const props = { images, labels: shots.map((s) => `${s.name} ${s.t.toFixed(2)}s`), cols: Math.min(5, shots.length), w: 270, h: 480, safe: true };
const sheet = await selectComposition({ serveUrl, id: "Sheet", inputProps: props, browserExecutable });
await renderStill({ serveUrl, composition: sheet, frame: 0, output: `${dir}/sheet.png`, inputProps: props, browserExecutable });
console.log(`${dir}/sheet.png · ${shots.length} kare · ${compId} ${total.toFixed(1)} sn`);
