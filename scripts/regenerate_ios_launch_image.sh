#!/bin/bash
# Regenerates the iOS launch-screen image from the logo SVG: the mark on a
# transparent background at 100pt (1x/2x/3x). The background colour comes
# from the LaunchBackground colour set, which matches the app's light and
# dark scaffold colours. Needs macOS (renders the SVG with AppKit).
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ios/Runner/Assets.xcassets/LaunchImage.imageset
swift - assets/branding/timeflow-logo.svg "$D" <<'SWIFT'
import AppKit
let args = CommandLine.arguments
guard let svg = NSImage(contentsOfFile: args[1]) else { fatalError("can't load \(args[1])") }
for (scale, suffix) in [(1, ""), (2, "@2x"), (3, "@3x")] {
    let px = 100 * scale
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    svg.draw(in: NSRect(x: 0, y: 0, width: px, height: px))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: "\(args[2])/LaunchImage\(suffix).png"))
}
SWIFT
