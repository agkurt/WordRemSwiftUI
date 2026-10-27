// node render.mjs s01  →  out/s01.mp4 (Mac'i yormamak için tek iş parçacığı sınırıyla)
import { execFileSync } from "node:child_process";
import fs from "node:fs";
const id = process.argv[2];
const comp = process.argv[3] ?? "Reel";   // Reel (hareketli) ya da Conversation (sade)
if (!id) throw new Error("kullanım: node render.mjs <id> [Reel|Conversation]");
fs.mkdirSync("out", { recursive: true });
execFileSync("npx", ["remotion", "render", "src/index.ts", comp, `out/${id}.mp4`,
  `--props=edits/${id}.json`, "--concurrency=2", "--crf=20", "--log=error"], { stdio: "inherit" });
console.log(`out/${id}.mp4`);
