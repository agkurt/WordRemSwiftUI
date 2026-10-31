// node render.mjs s01  →  out/s01.mp4 (Mac'i yormamak için tek iş parçacığı sınırıyla)
import { execFileSync } from "node:child_process";
import fs from "node:fs";
const id = process.argv[2];
if (!id) throw new Error("kullanım: node render.mjs <id> [Reel|Conversation|Bob|Explainer]");
// Kompozisyon verilmezse kurgu dosyasından: açıklama reel'i → Explainer, Bob bölümü → Bob, diğerleri → Reel
const edit = JSON.parse(fs.readFileSync(`edits/${id}.json`));
const comp = process.argv[3] ?? (edit.kind === "explainer" ? "Explainer" : edit.series ? "Bob" : "Reel");
fs.mkdirSync("out", { recursive: true });
execFileSync("npx", ["remotion", "render", "src/index.ts", comp, `out/${id}.mp4`,
  `--props=edits/${id}.json`, "--concurrency=1", "--image-format=png", "--crf=20", "--log=error"], { stdio: "inherit" });
console.log(`out/${id}.mp4`);
