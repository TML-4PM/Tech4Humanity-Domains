# lovable-helper.sh
#!/usr/bin/env bash
set -euo pipefail

ROOT="${PWD}"
APP_NAME="${APP_NAME:-lovable-app}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
STRIPE_PK="${STRIPE_PK:-}"
STRIPE_SK="${STRIPE_SK:-}"

echo "Scaffold start in ${ROOT}"

mkdir -p scripts src lib api public public/icons public/og supabase/edge/log_access supabase/sql

cat > package.json <<'JSON'
{
  "name": "lovable-helper",
  "private": true,
  "scripts": {
    "audit": "node scripts/crawl.js",
    "heal": "node scripts/lovable-audit-heal.js",
    "audit:fix": "bash scripts/audit_and_fix.sh",
    "brand": "tsx scripts/brand_sync.ts",
    "seo": "tsx scripts/generate_seo.ts",
    "bootstrap": "bash scripts/bootstrap.sh",
    "security": "bash scripts/security_init.sh",
    "build": "vite build",
    "serve": "vite preview",
    "vercel:deploy": "vercel --prod",
    "lighthouse": "npx lighthouse http://localhost:4173 --quiet --chrome-flags='--headless=new' --output=json --output-path=./lighthouse.json"
  },
  "devDependencies": {
    "tailwindcss": "^3.4.13",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.41",
    "typescript": "^5.6.3",
    "vite": "^5.4.8",
    "ts-node": "^10.9.2",
    "tsx": "^4.19.2",
    "sitemap": "^7.1.2"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.46.1",
    "jsonwebtoken": "^9.0.2",
    "node-fetch": "^3.3.2"
  }
}
JSON

cat > vite.config.ts <<'TS'
import { defineConfig } from "vite"
export default defineConfig({
  server: { port: 5173 },
  build: { sourcemap: true },
  esbuild: { legalComments: "none" }
})
TS

cat > tailwind.config.js <<'JS'
module.exports = {
  content: ["./index.html","./src/**/*.{ts,tsx,js,jsx,vue,svelte}"],
  theme: {
    extend: {
      colors: { brand: { primary: "#19379B", ink: "#222222" } },
      fontFamily: { sans: ["Inter","system-ui","-apple-system","Segoe UI","Roboto","Arial","sans-serif"] },
      borderRadius: { xl: "14px" }
    }
  },
  plugins: []
}
JS

cat > postcss.config.js <<'JS'
module.exports = { plugins: { tailwindcss: {}, autoprefixer: {} } }
JS

cat > public/robots.txt <<'TXT'
User-agent: *
Allow: /
Sitemap: /sitemap.xml
TXT

cat > scripts/generate_seo.ts <<'TS'
import { writeFileSync } from "fs"
import { SitemapStream, streamToPromise } from "sitemap"
const hostname = process.env.SITE_ORIGIN || "https://example.com"
const routes = ["/","/privacy","/terms"]
async function run() {
  const smStream = new SitemapStream({ hostname })
  routes.forEach(p => smStream.write({ url: p, changefreq: "weekly", priority: 0.7 }))
  smStream.end()
  const data = await streamToPromise(smStream)
  writeFileSync("public/sitemap.xml", data.toString())
  writeFileSync("public/humans.txt", "Lovable helper generated")
  console.log("SEO artifacts ready")
}
run()
TS

cat > scripts/brand_sync.ts <<'TS'
import { readdirSync, readFileSync, writeFileSync, existsSync, mkdirSync, copyFileSync } from "fs"
import { join } from "path"

const SRC = "public/icons"
const OG = "public/og"
const FAV = "public/favicon.ico"
const DROID = process.env.BRAND_ICON || "public/icons/ahc-droid.png"
if (!existsSync(SRC)) mkdirSync(SRC, { recursive: true })
if (!existsSync(OG)) mkdirSync(OG, { recursive: true })

function replaceMetaIn(file: string) {
  const p = join(file)
  if (!existsSync(p)) return
  let html = readFileSync(p, "utf8")
  html = html
    .replace(/<meta property="og:image" content="[^"]*">/g, `<meta property="og:image" content="/og/og.png">`)
    .replace(/<link rel="icon" [^>]*>/g, `<link rel="icon" type="image/png" href="/icons/favicon.png">`)
  writeFileSync(p, html)
}

function run() {
  try { copyFileSync(DROID, "public/icons/favicon.png") } catch {}
  try { copyFileSync(DROID, "public/og/og.png") } catch {}
  if (existsSync("index.html")) replaceMetaIn("index.html")
  console.log("Brand sync complete")
}
run()
TS

cat > scripts/crawl.js <<'JS'
import fetch from "node-fetch"
import fs from "fs"

const origin = process.env.SITE_ORIGIN || "http://localhost:4173"
const visited = new Set()
const broken = []
const ok = []

async function crawl(url) {
  if (visited.has(url)) return
  visited.add(url)
  let res
  try { res = await fetch(url, { redirect: "manual" }) } catch (e) {
    broken.push({ url, code: "FETCH_ERR", note: String(e) })
    return
  }
  if (res.status === 404) { broken.push({ url, code: 404 }); return }
  if (res.status >= 500) { broken.push({ url, code: res.status }); return }
  ok.push({ url, code: res.status })
  const html = await res.text()
  const links = [...html.matchAll(/href="(\/[^"#?]+)"/g)].map(m => new URL(m[1], origin).href)
  for (const l of links) if (l.startsWith(origin)) await crawl(l)
}

const start = async () => {
  await crawl(origin)
  const out = { ts: new Date().toISOString(), origin, ok: ok.length, broken: broken.length, broken_list: broken }
  fs.mkdirSync("out", { recursive: true })
  fs.writeFileSync("out/site_audit.json", JSON.stringify(out, null, 2))
  console.log(JSON.stringify(out, null, 2))
}
start()
JS

cat > scripts/lovable-audit-heal.js <<'JS'
import fs from "fs"
import { execSync } from "child_process"

const supabaseUrl = process.env.SUPABASE_URL || ""
const supabaseKey = process.env.SUPABASE_ANON_KEY || ""
const slack = process.env.SLACK_WEBHOOK_URL || ""

function log(msg) { console.log(`[heal] ${msg}`) }

function notifySlack(text) {
  if (!slack) return
  try {
    execSync(`curl -s -X POST -H "Content-type: application/json" --data '${JSON.stringify({ text })}' "${slack}"`)
  } catch {}
}

function main() {
  const path = "out/site_audit.json"
  if (!fs.existsSync(path)) { log("no audit file"); process.exit(0) }
  const report = JSON.parse(fs.readFileSync(path,"utf8"))
  if (report.broken === 0) { log("no fixes required"); return }
  notifySlack(`Lovable audit found ${report.broken} issues`)
  // put simple auto fixes here if you have known missing pages
  // example create stub pages for common 404 routes
  const stubs = ["privacy","terms","404"]
  stubs.forEach(s => {
    const f = `public/${s}.html`
    if (!fs.existsSync(f)) fs.writeFileSync(f, `<!doctype html><title>${s}</title><h1>${s}</h1>`)
  })
  log("stub pages ensured")
}
main()
JS

cat > scripts/audit_and_fix.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
npm run audit
npm run heal
npm run build
npm run vercel:deploy || true
SH
chmod +x scripts/audit_and_fix.sh

cat > scripts/bootstrap.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
npm i
npm run seo
npm run brand
echo "Bootstrap done"
SH
chmod +x scripts/bootstrap.sh

cat > scripts/security_init.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p public/.well-known
cat > public/.well-known/security.txt <<EOF
Contact mailto:security@example.com
Policy https://example.com/security
EOF
echo "Security seed done"
SH
chmod +x scripts/security_init.sh

cat > vercel.json <<'JSON'
{
  "cleanUrls": true,
  "trailingSlash": false,
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "Strict-Transport-Security", "value": "max-age=63072000; includeSubDomains; preload" },
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
        { "key": "Content-Security-Policy", "value": "default-src 'self'; img-src 'self' data: https:; script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self' https:;" }
      ]
    }
  ],
  "rewrites": [{ "source": "/(.*)", "destination": "/" }]
}
JSON

cat > api/checkout.ts <<'TS'
import type { VercelRequest, VercelResponse } from "@vercel/node"

export default async function handler(req: VercelRequest, res: VercelResponse) {
  try {
    const key = process.env.STRIPE_SK
    if (!key) return res.status(200).json({ ok: true, mock: true })
    const stripe = require("stripe")(key)
    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: [{ price: process.env.STRIPE_PRICE_ID || "", quantity: 1 }],
      success_url: `${process.env.SITE_ORIGIN || "http://localhost:5173"}/success`,
      cancel_url: `${process.env.SITE_ORIGIN || "http://localhost:5173"}/cancel`
    })
    res.status(200).json({ id: session.id, url: session.url })
  } catch (e) {
    res.status(500).json({ error: String(e) })
  }
}
TS

cat > supabase/sql/schema.sql <<'SQL'
create table if not exists public.site_audit_log (
  id bigserial primary key,
  ts timestamptz default now(),
  origin text not null,
  ok_count int default 0,
  broken_count int default 0,
  payload jsonb
);

create table if not exists public.app_audits (
  id bigserial primary key,
  ts timestamptz default now(),
  type text not null,
  message text,
  data jsonb
);

create table if not exists public.deploy_history (
  id bigserial primary key,
  ts timestamptz default now(),
  commit_sha text,
  url text,
  notes text
);
SQL

cat > supabase/edge/log_access/index.ts <<'TS'
import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.46.1"

serve(async (req) => {
  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!)
    const body = await req.json()
    await supabase.from("app_audits").insert({
      type: "access",
      data: body
    })
    return new Response(JSON.stringify({ ok: true }), { headers: { "content-type": "application/json" } })
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), { status: 500 })
  }
})
TS

cat > src/global-controller.ts <<'TS'
export function policyInit() {
  const meta = document.createElement("meta")
  meta.httpEquiv = "Content-Security-Policy"
  meta.content = "default-src 'self'; img-src 'self' data: https:; connect-src 'self' https:;"
  document.head.appendChild(meta)
}
TS

cat > .env.local.example <<'ENV'
SITE_ORIGIN=http://localhost:5173
SLACK_WEBHOOK_URL=
SUPABASE_URL=
SUPABASE_ANON_KEY=
STRIPE_PK=
STRIPE_SK=
STRIPE_PRICE_ID=
ENV

cat > index.html <<'HTML'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta property="og:image" content="/og/og.png" />
    <link rel="icon" type="image/png" href="/icons/favicon.png" />
    <title>Lovable Site</title>
  </head>
  <body>
    <div id="app">
      <h1>Lovable baseline</h1>
      <p>Glass UI ready</p>
    </div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
HTML

cat > src/main.ts <<'TS'
import "./style.css"
import { policyInit } from "./global-controller"
policyInit()
console.log("Lovable helper online")
TS

cat > src/style.css <<'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root { --brand: #19379B; --ink: #222222 }
body { font-family: Inter, system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; color: var(--ink) }
.card { backdrop-filter: blur(10px); background: rgba(255,255,255,0.6); border-radius: 14px; border: 1px solid rgba(255,255,255,0.4); padding: 16px }
CSS

# Ensure a secrets file exists for this app
if [ ! -f ~/secrets-vault/$APP_NAME.yml ]; then
  echo "⚠️  No secrets file found for $APP_NAME."
  echo "Run: cd ~/secrets-vault && ./new-secret.sh"
else
  echo "Secrets file found: ~/secrets-vault/$APP_NAME.yml"
fi

echo "Done"

