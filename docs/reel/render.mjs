// Renders reel.html frame by frame with headless Chromium and pipes the frames to ffmpeg.
//   node render.mjs video <out.mp4>
//   node render.mjs stills <t1,t2,...> <out dir>
// Needs playwright-core (set PLAYWRIGHT_CORE to its index.mjs, or install it next to this file)
// and a Playwright Chromium in ~/.cache/ms-playwright (or set CHROMIUM to the binary).
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const { chromium } = await import(process.env.PLAYWRIGHT_CORE ? pathToFileURL(process.env.PLAYWRIGHT_CORE).href : 'playwright-core');

function findChromium() {
  if (process.env.CHROMIUM) return process.env.CHROMIUM;
  const cache = path.join(process.env.HOME, '.cache/ms-playwright');
  const dir = fs.readdirSync(cache).filter(d => /^chromium-\d+$/.test(d)).sort().pop();
  return path.join(cache, dir, 'chrome-linux64/chrome');
}

const [mode, arg, out] = process.argv.slice(2);
const browser = await chromium.launch({ executablePath: findChromium(), args: ['--force-color-profile=srgb'] });
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
await page.goto(pathToFileURL(path.join(here, 'reel.html')).href);
await page.waitForFunction(() => window.ready);
await page.waitForTimeout(300);
const total = await page.evaluate(() => window.TOTAL);

if (mode === 'stills') {
  for (const t of arg.split(',').map(Number)) {
    await page.evaluate(t => render(t), t);
    await page.screenshot({ path: path.join(out, `s_${t.toFixed(2)}.png`) });
  }
} else {
  const fps = 30, n = Math.round(total * fps);
  // JPEG frames are full range; convert to standard (tv) range yuv420p so Instagram and LinkedIn show the right colours.
  const ff = spawn('ffmpeg', ['-y', '-v', 'error', '-f', 'image2pipe', '-framerate', String(fps), '-c:v', 'mjpeg', '-i', '-',
    '-vf', 'scale=in_range=full:out_range=tv,format=yuv420p', '-c:v', 'libx264', '-preset', 'slow', '-crf', '16', '-profile:v', 'high',
    '-color_range', 'tv', '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709', '-movflags', '+faststart', arg],
    { stdio: ['pipe', 'inherit', 'inherit'] });
  for (let f = 0; f < n; f++) {
    await page.evaluate(t => render(t), f / fps);
    const buf = await page.screenshot({ type: 'jpeg', quality: 95 });
    if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
    if (f % 90 === 0) console.log(`frame ${f}/${n}`);
  }
  ff.stdin.end();
  await new Promise(r => ff.on('close', r));
}
console.log('total', total);
await browser.close();
