// Turns a raw device screenshot into a store-ready one.
//
// The awkward part is the red SCREENSHOTS ON banner in the top-right corner. It
// cannot simply be cropped away, because on some screens the app bar starts
// immediately below it. So instead the banner is painted over — and the paint
// colour is SAMPLED from the same rows on the left of the same image, because
// the colour behind it differs per screen (the Settings app bar is lighter than
// the page background). A fixed colour left a visible block.
const fs = require('fs');
const zlib = require('zlib');
const { execFileSync } = require('child_process');

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const DIR = process.argv[2] || './shots';
const OUT = 'C:/development/projects/ibank/Karde_Design_Package/store/screenshots';

const SRC_W = 1080, SRC_H = 2316;
// INSET was 4, to trim a screen-edge highlight -- but sampling the pixels showed
// the edges are clean background, and 1072px fell under Play's 1080px minimum for
// promotable screenshots. Keep the full width.
const INSET = 0, TOP = 98, BOTTOM = 152;
const W = SRC_W - INSET * 2;
const H = SRC_H - TOP - BOTTOM;

// --- minimal PNG reader: 8-bit RGB / RGBA, no interlace -------------------
function decodePng(file) {
  const b = fs.readFileSync(file);
  let p = 8, w = 0, h = 0, colorType = 0;
  const idat = [];
  while (p < b.length) {
    const len = b.readUInt32BE(p);
    const type = b.toString('ascii', p + 4, p + 8);
    const data = b.subarray(p + 8, p + 8 + len);
    if (type === 'IHDR') { w = data.readUInt32BE(0); h = data.readUInt32BE(4); colorType = data[9]; }
    else if (type === 'IDAT') idat.push(data);
    else if (type === 'IEND') break;
    p += 12 + len;
  }
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const ch = colorType === 6 ? 4 : 3;
  const stride = w * ch;
  const out = Buffer.alloc(h * stride);
  let q = 0;
  for (let y = 0; y < h; y++) {
    const filter = raw[q++];
    const line = raw.subarray(q, q + stride); q += stride;
    const cur = out.subarray(y * stride, (y + 1) * stride);
    const prev = y ? out.subarray((y - 1) * stride, y * stride) : Buffer.alloc(stride);
    for (let x = 0; x < stride; x++) {
      const a = x >= ch ? cur[x - ch] : 0, bb = prev[x], c = x >= ch ? prev[x - ch] : 0;
      let v = line[x];
      if (filter === 1) v += a; else if (filter === 2) v += bb; else if (filter === 3) v += (a + bb) >> 1;
      else if (filter === 4) {
        const pp = a + bb - c, pa = Math.abs(pp - a), pb = Math.abs(pp - bb), pc = Math.abs(pp - c);
        v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? bb : c);
      }
      cur[x] = v & 255;
    }
  }
  return { w, h, ch, data: out, px: (x, y) => { const i = y * stride + x * ch; return [out[i], out[i + 1], out[i + 2]]; } };
}

const isBannerRed = ([r, g, bl]) => r > 110 && r > g * 1.8 && r > bl * 1.8;

for (const name of process.argv.slice(2)) {
  const src = `${DIR}/${name}.png`;
  if (!fs.existsSync(src)) { console.log('missing', name); continue; }
  const img = decodePng(src);

  // How far down, and how far left, does the banner actually reach?
  let maxY = 0, minX = SRC_W;
  for (let y = 0; y < 300; y++)
    for (let x = 600; x < img.w; x++)
      if (isBannerRed(img.px(x, y))) { if (y > maxY) maxY = y; if (x < minX) minX = x; }

  const maskH = Math.max(0, maxY - TOP + 6);          // in cropped coordinates
  const maskW = maxY > 0 ? Math.min(W, SRC_W - minX + 16) : 0;
  // Sample the background from the same band, far left, where no banner reaches.
  const [r, g, bl] = img.px(12, Math.min(TOP + Math.max(maskH, 8) - 4, img.h - 1));
  const fill = `rgb(${r},${g},${bl})`;

  const html = `${DIR}/_crop_${name}.html`;
  const css = [
    '*{margin:0;padding:0}',
    `html,body{width:${W}px;height:${H}px;overflow:hidden;background:${fill}}`,
    `img{position:absolute;left:-${INSET}px;top:-${TOP}px;width:${SRC_W}px}`,
    `.mask{position:absolute;right:0;top:0;width:${maskW}px;height:${maskH}px;background:${fill}}`,
  ].join('');
  fs.writeFileSync(html, `<style>${css}</style><img src="file:///${src}">${maskH ? '<div class="mask"></div>' : ''}`);

  execFileSync(CHROME, ['--headless=new', '--disable-gpu', '--hide-scrollbars',
    '--force-device-scale-factor=1', `--window-size=${W},${H}`,
    `--screenshot=${OUT}/${name}.png`, `file:///${html}`], { stdio: 'ignore' });

  const o = fs.readFileSync(`${OUT}/${name}.png`);
  console.log(`${name}  ${o.readUInt32BE(16)}x${o.readUInt32BE(20)}  banner to y=${maxY}  mask ${maskW}x${maskH} ${fill}`);
  fs.unlinkSync(html);
}
