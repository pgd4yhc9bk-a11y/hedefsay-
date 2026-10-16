// Bir önekle kaydedilmiş ekran görüntülerini tek bir panoda birleştirir. Kullanım: node pano.js <dizin> <onek> [sutun]
const { chromium } = require("playwright");
const fs = require("fs"), path = require("path");
const [dir, onek, sutunArg, genArg] = process.argv.slice(2);
const sutun = +(sutunArg || 7);
const dosyalar = fs.readdirSync(dir).filter((f) => f.startsWith(onek + "-") && f.endsWith(".png") && !f.includes("pano")).sort();
const etiket = (f) => f.replace(onek + "-", "").replace(/^\d+-/, "").replace(".png", "").replace(/-/g, " ");
const gen = +(genArg || 250);
const html = `<body style="margin:0;background:#0f1218;font-family:system-ui,sans-serif;color:#ddd">
<div style="display:grid;grid-template-columns:repeat(${sutun},${gen}px);gap:14px;padding:18px;width:max-content">
${dosyalar.map((f, i) => `<div><img style="width:${gen}px;border-radius:14px;display:block" src="data:image/png;base64,${fs.readFileSync(path.join(dir, f)).toString("base64")}"><div style="padding:6px 2px;font-size:13px">${i + 1}. ${etiket(f)}</div></div>`).join("")}
</div></body>`;
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: sutun * (gen + 14) + 40, height: 800 } });
  await p.setContent(html); await p.waitForTimeout(500);
  await p.screenshot({ path: path.join(dir, onek + "-pano.png"), fullPage: true });
  await b.close(); console.log(dosyalar.length + " ekran birleştirildi");
})();
