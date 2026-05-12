import AppKit
import CoreGraphics

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let sizes: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

func renderCG(size: Int) -> CGImage? {
    let s = CGFloat(size)
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(data: nil,
                              width: size,
                              height: size,
                              bitsPerComponent: 8,
                              bytesPerRow: 0,
                              space: cs,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }

    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    let radius = s * 0.2237 // macOS Big Sur squircle approximation

    let bg = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.addPath(bg)
    ctx.clip()

    let colors = [
        CGColor(red: 0.93, green: 0.50, blue: 0.36, alpha: 1.0),
        CGColor(red: 0.84, green: 0.36, blue: 0.25, alpha: 1.0),
    ] as CFArray
    let locations: [CGFloat] = [0, 1]
    if let grad = CGGradient(colorsSpace: cs, colors: colors, locations: locations) {
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: 0, y: s),
                               end: CGPoint(x: 0, y: 0),
                               options: [])
    }

    let hcolors = [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.18),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.0),
    ] as CFArray
    if let hgrad = CGGradient(colorsSpace: cs, colors: hcolors, locations: locations) {
        ctx.drawLinearGradient(hgrad,
                               start: CGPoint(x: 0, y: s),
                               end: CGPoint(x: 0, y: s * 0.55),
                               options: [])
    }

    let glyphPoint = s * 0.58
    let pointCfg = NSImage.SymbolConfiguration(pointSize: glyphPoint, weight: .semibold)
    let whiteCfg = NSImage.SymbolConfiguration(paletteColors: [.white])
    let cfg = pointCfg.applying(whiteCfg)
    if let glyphImg = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) {
        var imgRect = CGRect(origin: .zero, size: glyphImg.size)
        if let cgGlyph = glyphImg.cgImage(forProposedRect: &imgRect, context: nil, hints: nil) {
            let gw = CGFloat(cgGlyph.width)
            let gh = CGFloat(cgGlyph.height)
            let target = s * 0.62
            let scale = target / max(gw, gh)
            let drawW = gw * scale
            let drawH = gh * scale
            let gx = (s - drawW) / 2
            let gy = (s - drawH) / 2
            ctx.draw(cgGlyph, in: CGRect(x: gx, y: gy, width: drawW, height: drawH))
        }
    }

    return ctx.makeImage()
}

func writePNG(_ cgImage: CGImage, to path: String) -> Bool {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil) else { return false }
    CGImageDestinationAddImage(dest, cgImage, nil)
    return CGImageDestinationFinalize(dest)
}

for (size, name) in sizes {
    guard let cg = renderCG(size: size) else {
        FileHandle.standardError.write("render failed: \(name)\n".data(using: .utf8)!)
        exit(1)
    }
    let ok = writePNG(cg, to: "\(outDir)/\(name)")
    if !ok {
        FileHandle.standardError.write("write failed: \(name)\n".data(using: .utf8)!)
        exit(1)
    }
}
print("wrote \(sizes.count) icon images to \(outDir)")
