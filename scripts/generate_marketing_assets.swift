// Generates the TimeFlow marketing and press kit PNGs in marketing/ from the
// logo SVG and the app's Nunito font. macOS only (renders with AppKit).
//
//   swift scripts/generate_marketing_assets.swift
//
// Every PNG carries DPI metadata: 300 for print folders, 72 for screen ones.
import AppKit
import CoreText

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let out = root.appendingPathComponent("marketing")
let logo = NSImage(contentsOf: root.appendingPathComponent("assets/branding/timeflow-logo.svg"))!
CTFontManagerRegisterFontsForURL(
  root.appendingPathComponent("assets/fonts/Nunito.ttf") as CFURL, .process, nil)

func hex(_ v: UInt32) -> NSColor {
  NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
          blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}
let ink = hex(0x1A6FC8)       // AppColors.primaryInk: wordmark text on light
let textDark = hex(0x212121)  // body text colour on light backgrounds
let white = NSColor.white
let black = NSColor.black
let paper = hex(0xFAFAFA)     // AppColors.backgroundLight
let night = hex(0x121212)     // AppColors.backgroundDark

/// Renders a w×h canvas and writes it as PNG with the given DPI.
func render(_ path: String, _ w: Int, _ h: Int, dpi: Double = 72,
            background: NSColor? = nil, _ draw: (NSRect) -> Void) {
  let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                             isPlanar: false, colorSpaceName: .deviceRGB,
                             bytesPerRow: 0, bitsPerPixel: 0)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  NSGraphicsContext.current?.imageInterpolation = .high
  let r = NSRect(x: 0, y: 0, width: w, height: h)
  if let bg = background { bg.setFill(); r.fill() }
  draw(r)
  NSGraphicsContext.restoreGraphicsState()
  // DPI = pixels per inch; the rep's point size sets it (72 points per inch).
  rep.size = NSSize(width: Double(w) * 72 / dpi, height: Double(h) * 72 / dpi)
  let url = out.appendingPathComponent(path)
  try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                           withIntermediateDirectories: true)
  try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

/// The logo mark in full colour, or flattened to one colour for single-ink print.
func drawMark(in r: NSRect, color: NSColor? = nil) {
  guard let color else { logo.draw(in: r); return }
  let tinted = NSImage(size: r.size, flipped: false) { b in
    logo.draw(in: b); color.set(); b.fill(using: .sourceAtop); return true
  }
  // The mark is several abutting shapes; flattened to one colour, the hairline
  // gaps between them show as specks. Spreading the fill by ~0.06% closes them.
  let d = max(1, r.width * 0.0006)
  for (dx, dy) in [(0, 0), (d, 0), (-d, 0), (0, d), (0, -d), (d, d), (-d, -d), (d, -d), (-d, d)] {
    tinted.draw(in: r.offsetBy(dx: dx, dy: dy))
  }
}

func font(_ size: CGFloat, _ weight: String = "Bold") -> NSFont {
  NSFont(name: "Nunito-\(weight)", size: size)!
}

func text(_ s: String, _ f: NSFont, _ c: NSColor) -> NSAttributedString {
  NSAttributedString(string: s, attributes: [.font: f, .foregroundColor: c, .kern: f.pointSize * -0.01])
}

/// Mark + "TimeFlow" side by side, fitted inside r.
func drawWordmark(in r: NSRect, textColor: NSColor, markColor: NSColor? = nil) {
  // Proportions at a mark height of 1: text cap ≈ 0.62, gap 0.28.
  let probe = text("TimeFlow", font(100), textColor).size()
  let wPerH = 1 + 0.28 + probe.width / 100 * 0.62 / 0.72
  let h = min(r.height, r.width / wPerH)
  let x0 = r.midX - h * wPerH / 2, y0 = r.midY - h / 2
  drawMark(in: NSRect(x: x0, y: y0, width: h, height: h), color: markColor)
  let t = text("TimeFlow", font(h * 0.62 / 0.72), textColor)
  let ts = t.size()
  t.draw(at: NSPoint(x: x0 + h * 1.28, y: r.midY - ts.height / 2 + h * 0.02))
}

/// Mark above "TimeFlow" (and optionally the tagline), fitted inside r.
func drawStacked(in r: NSRect, textColor: NSColor, markColor: NSColor? = nil,
                 tagline: Bool = false, taglineColor: NSColor? = nil) {
  let s = min(r.width / 2.6, r.height / (tagline ? 1.95 : 1.62))
  let total = s * (tagline ? 1.95 : 1.62)
  var y = r.midY + total / 2 - s
  drawMark(in: NSRect(x: r.midX - s / 2, y: y, width: s, height: s), color: markColor)
  let name = text("TimeFlow", font(s * 0.46), textColor)
  y -= s * 0.12 + name.size().height
  name.draw(at: NSPoint(x: r.midX - name.size().width / 2, y: y))
  if tagline {
    let tag = text("Your day as a gentle river", font(s * 0.16, "SemiBold"), taglineColor ?? textColor)
    y -= s * 0.06 + tag.size().height
    tag.draw(at: NSPoint(x: r.midX - tag.size().width / 2, y: y))
  }
}

func inset(_ r: NSRect, _ f: CGFloat) -> NSRect { r.insetBy(dx: r.width * f, dy: r.height * f) }

// 1. Logo mark, transparent, screen and print sizes.
for px in [256, 512, 1024, 2048, 4096] {
  render("logo/mark/timeflow-mark-\(px).png", px, px) { drawMark(in: $0) }
}
/// Print artwork at a fixed physical size, rendered once per DPI into
/// print/<dpi>dpi/. 300 is the print-shop standard; the higher ones are for
/// enlarging or very fine printing.
let printDPIs = [300.0, 800, 1000, 1500]
func printAsset(_ name: String, inches w: Double, _ h: Double, dpis: [Double] = printDPIs,
                _ draw: @escaping (NSRect) -> Void) {
  for dpi in dpis {
    let px = (Int((w * dpi).rounded()), Int((h * dpi).rounded()))
    render("print/\(Int(dpi))dpi/\(name)-\(px.0)x\(px.1).png", px.0, px.1, dpi: dpi, draw)
  }
}

printAsset("mark-color-6x6in", inches: 6, 6) { drawMark(in: $0) }
printAsset("mark-white-6x6in", inches: 6, 6) { drawMark(in: $0, color: white) }
printAsset("mark-black-6x6in", inches: 6, 6) { drawMark(in: $0, color: black) }
printAsset("mark-blue-6x6in", inches: 6, 6) { drawMark(in: $0, color: ink) }

// 2. Horizontal wordmark: on light, on dark, one-colour.
for (w, h) in [(1200, 320), (2400, 640), (4800, 1280)] {
  render("logo/wordmark/timeflow-wordmark-light-\(w).png", w, h) { drawWordmark(in: inset($0, 0.04), textColor: ink) }
  render("logo/wordmark/timeflow-wordmark-dark-\(w).png", w, h) { drawWordmark(in: inset($0, 0.04), textColor: white) }
}
printAsset("wordmark-color-12x3.2in", inches: 12, 3.2) { drawWordmark(in: inset($0, 0.04), textColor: ink) }
printAsset("wordmark-white-12x3.2in", inches: 12, 3.2) { drawWordmark(in: inset($0, 0.04), textColor: white, markColor: white) }
printAsset("wordmark-black-12x3.2in", inches: 12, 3.2) { drawWordmark(in: inset($0, 0.04), textColor: black, markColor: black) }

// 3. Stacked lockup, with and without tagline.
for px in [1024, 2048] {
  render("logo/stacked/timeflow-stacked-light-\(px).png", px, px) { drawStacked(in: inset($0, 0.08), textColor: ink) }
  render("logo/stacked/timeflow-stacked-dark-\(px).png", px, px) { drawStacked(in: inset($0, 0.08), textColor: white) }
  render("logo/stacked/timeflow-stacked-tagline-light-\(px).png", px, px) { drawStacked(in: inset($0, 0.08), textColor: ink, tagline: true, taglineColor: textDark) }
  render("logo/stacked/timeflow-stacked-tagline-dark-\(px).png", px, px) { drawStacked(in: inset($0, 0.08), textColor: white, tagline: true) }
}

// 4. T-shirt artwork, transparent. The 15×18 in full front is 300 DPI only:
// at 1500 DPI it would be 22500×27000 px, more than print shops accept.
printAsset("tshirt-front-15x18in-for-light-shirts", inches: 15, 18, dpis: [300]) {
  drawStacked(in: inset($0, 0.1), textColor: ink, tagline: true, taglineColor: textDark)
}
printAsset("tshirt-front-15x18in-for-dark-shirts", inches: 15, 18, dpis: [300]) {
  drawStacked(in: inset($0, 0.1), textColor: white, tagline: true)
}
printAsset("tshirt-front-15x18in-one-color-white", inches: 15, 18, dpis: [300]) {
  drawStacked(in: inset($0, 0.1), textColor: white, markColor: white, tagline: true)
}
printAsset("tshirt-front-15x18in-one-color-black", inches: 15, 18, dpis: [300]) {
  drawStacked(in: inset($0, 0.1), textColor: black, markColor: black, tagline: true)
}
printAsset("tshirt-chest-4x4in-color", inches: 4, 4) { drawMark(in: inset($0, 0.05)) }
printAsset("tshirt-chest-4x4in-white", inches: 4, 4) { drawMark(in: inset($0, 0.05), color: white) }
printAsset("tshirt-back-12x3in-wordmark-for-light-shirts", inches: 12, 3) { drawWordmark(in: $0, textColor: ink) }
printAsset("tshirt-back-12x3in-wordmark-for-dark-shirts", inches: 12, 3) { drawWordmark(in: $0, textColor: white) }

// 5. App icon (mark on white at 70%, as on iOS) and press backgrounds.
for px in [512, 1024, 2048] {
  render("press/app-icon-\(px).png", px, px, background: white) { drawMark(in: inset($0, 0.15)) }
}
render("press/banner-1600x900-light.png", 1600, 900, background: paper) {
  drawStacked(in: inset($0, 0.12), textColor: ink, tagline: true, taglineColor: textDark)
}
render("press/banner-1600x900-dark.png", 1600, 900, background: night) {
  drawStacked(in: inset($0, 0.12), textColor: white, tagline: true)
}
render("press/social-1200x630.png", 1200, 630, background: paper) {
  drawWordmark(in: inset($0, 0.18), textColor: ink)
}
print("Wrote marketing assets to \(out.path)")
