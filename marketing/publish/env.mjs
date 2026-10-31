// marketing/.env ve publish/tokens.json (TikTok oturumu) okuma/yazma
import fs from "node:fs";

const root = new URL("../", import.meta.url);
const envFile = new URL(".env", root);
const tokenFile = new URL("tokens.json", import.meta.url);

export function env() {
  const out = {};
  if (!fs.existsSync(envFile)) return out;
  for (const line of fs.readFileSync(envFile, "utf8").split("\n")) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m && m[2]) out[m[1]] = m[2].replace(/^["']|["']$/g, "");
  }
  return out;
}

export const tokens = {
  read: () => (fs.existsSync(tokenFile) ? JSON.parse(fs.readFileSync(tokenFile, "utf8")) : {}),
  write: (t) => fs.writeFileSync(tokenFile, JSON.stringify(t, null, 2)),
};
