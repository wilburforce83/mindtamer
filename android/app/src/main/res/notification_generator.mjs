// Node 18+
// Usage: node make_notification_icons.mjs [--ios] [--out ./dist] [--name ic_notification]
// Requires: npm i sharp

import fs from "fs";
import path from "path";
import url from "url";
import sharp from "sharp";

const __filename = url.fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ---- Configuration (flags) ----
const args = new Set(process.argv.slice(2));
const wantsIOS = args.has("--ios");
const outRoot =
  (() => {
    const ix = process.argv.indexOf("--out");
    return ix > -1 ? process.argv[ix + 1] : "./dist";
  })();
const baseName =
  (() => {
    const ix = process.argv.indexOf("--name");
    return ix > -1 ? process.argv[ix + 1] : "ic_stat_notify";
  })();

// ---- Input ----
const INPUT = path.resolve(__dirname, "./base_notification.png");
if (!fs.existsSync(INPUT)) {
  console.error(`✖ Missing ${INPUT}. Put your source PNG there (square, transparent BG).`);
  process.exit(1);
}

// ---- Targets ----
const ANDROID_SIZES = [
  { density: "mdpi",   px: 24 },
  { density: "hdpi",   px: 36 },
  { density: "xhdpi",  px: 48 },
  { density: "xxhdpi", px: 72 },
  { density: "xxxhdpi",px: 96 },
];
// Typical Android placement for notification “smallIcon”
const ANDROID_DIR = `android/app/src/main/res`;           // adjust if needed
const ANDROID_KIND = "drawable";                           // launcher icons use mipmap; notifications should use drawable

const IOS_SIZES = [
  { scale: "1x", px: 20 },
  { scale: "2x", px: 40 },
  { scale: "3x", px: 60 },
];
const IOS_DIR = `ios/NotificationIconExports`;            // export folder to drag into Xcode AppIcon.appiconset

// ---- Helpers ----
async function ensureDir(p) {
  await fs.promises.mkdir(p, { recursive: true });
}

async function makeAndroidMonochromeIcon(sizePx, outPath) {
  // 1) Resize source to target square with nearest-neighbor (pixel-art friendly), keep alpha.
  const resized = await sharp(INPUT)
    .resize(sizePx, sizePx, {
      fit: "contain",
      background: { r: 0, g: 0, b: 0, alpha: 0 },
      kernel: "nearest",
    })
    .png()
    .toBuffer();

  // 2) Create a solid white image and use the resized alpha as a mask (dest-in)
  //    -> Produces white shape with original transparency (what Android expects).
  const whiteOnTransparent = await sharp({
    create: {
      width: sizePx,
      height: sizePx,
      channels: 4,
      background: { r: 255, g: 255, b: 255, alpha: 1 },
    },
  })
    .composite([{ input: resized, blend: "dest-in" }])
    .png()
    .toBuffer();

  await sharp(whiteOnTransparent).png().toFile(outPath);
}

async function makeIOSIcon(sizePx, outPath) {
  // iOS doesn’t require monochrome for notifications (these sizes sit in the AppIcon set),
  // so export as-is (color preserved).
  await sharp(INPUT)
    .resize(sizePx, sizePx, {
      fit: "contain",
      background: { r: 0, g: 0, b: 0, alpha: 0 },
      kernel: "nearest",
    })
    .png()
    .toFile(outPath);
}

(async () => {
  try {
    // ANDROID
    for (const { density, px } of ANDROID_SIZES) {
      const dir = path.resolve(outRoot, ANDROID_DIR, `${ANDROID_KIND}-${density}`);
      await ensureDir(dir);
      const outFile = path.join(dir, `${baseName}.png`);
      await makeAndroidMonochromeIcon(px, outFile);
      console.log(`✓ Android ${density} ${px}x${px} → ${path.relative(process.cwd(), outFile)}`);
    }

    // iOS (optional)
    if (wantsIOS) {
      const dir = path.resolve(outRoot, IOS_DIR);
      await ensureDir(dir);
      for (const { scale, px } of IOS_SIZES) {
        const outFile = path.join(dir, `${baseName}_${px}x${px}@${scale}.png`);
        await makeIOSIcon(px, outFile);
        console.log(`✓ iOS ${px}x${px} (${scale}) → ${path.relative(process.cwd(), outFile)}`);
      }

      // Optionally emit a minimal Contents.json snippet for quick drop-in (you can merge into AppIcon.appiconset)
      const contents = {
        images: [
          { size: "20x20", idiom: "iphone", filename: `${baseName}_20x20@1x.png`, scale: "1x" },
          { size: "20x20", idiom: "iphone", filename: `${baseName}_40x40@2x.png`, scale: "2x" },
          { size: "20x20", idiom: "iphone", filename: `${baseName}_60x60@3x.png`, scale: "3x" },
        ],
        info: { version: 1, author: "xcode" },
      };
      await fs.promises.writeFile(
        path.join(dir, "Contents.json"),
        JSON.stringify(contents, null, 2),
        "utf8"
      );
      console.log(`ℹ︎ iOS Contents.json written (merge these into your AppIcon.appiconset).`);
    }

    console.log("\nAll done.");
  } catch (err) {
    console.error("✖ Error:", err);
    process.exit(1);
  }
})();
