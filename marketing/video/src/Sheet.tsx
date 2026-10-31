import { AbsoluteFill, Img, staticFile } from "remotion";
import { SAFE } from "./types";

/** review.mjs'in kareleri: zaman etiketli ızgara (kontakt sayfası, kesim şeridi, döngü); safe: arayüzün örttüğü bölgeler kırmızı */
export type SheetProps = { images: string[]; labels: string[]; cols: number; w: number; h: number; safe?: boolean };

export const GAP = 4;

/** Platform arayüzünün örttüğü bölgeler, kare boyutuna ölçekli */
const Unsafe: React.FC<{ w: number; h: number }> = ({ w, h }) => {
  const k = w / 1080;
  const zone = { position: "absolute", background: "rgba(255,0,60,0.28)", outline: "1px solid rgba(255,0,60,0.7)" } as const;
  return (
    <>
      <div style={{ ...zone, left: 0, top: 0, width: w, height: SAFE.top * k }} />
      <div style={{ ...zone, left: 0, top: h - SAFE.bottom * k, width: w, height: SAFE.bottom * k }} />
      <div style={{ ...zone, left: 0, top: SAFE.top * k, width: SAFE.side * k, height: h - (SAFE.top + SAFE.bottom) * k }} />
      <div style={{ ...zone, left: w - SAFE.right * k, top: SAFE.rightFrom * k, width: SAFE.right * k, height: h - (SAFE.rightFrom + SAFE.bottom) * k }} />
      <div style={{ ...zone, left: w - SAFE.side * k, top: SAFE.top * k, width: SAFE.side * k, height: (SAFE.rightFrom - SAFE.top) * k }} />
    </>
  );
};

export const Sheet: React.FC<SheetProps> = ({ images, labels, cols, w, h, safe }) => (
  <AbsoluteFill style={{ background: "#000", display: "flex", flexDirection: "row", flexWrap: "wrap", gap: GAP, alignContent: "flex-start" }}>
    {images.map((src, i) => (
      <div key={i} style={{ position: "relative", width: w, height: h }}>
        <Img src={staticFile(src)} style={{ width: w, height: h, objectFit: "cover" }} />
        {safe ? <Unsafe w={w} h={h} /> : null}
        <div style={{ position: "absolute", left: 4, top: 4, background: "rgba(0,0,0,0.7)", color: "white",
          font: "700 16px Menlo, monospace", padding: "2px 6px", borderRadius: 4 }}>{labels[i]}</div>
      </div>
    ))}
    <div style={{ width: (w + GAP) * cols }} />
  </AbsoluteFill>
);
