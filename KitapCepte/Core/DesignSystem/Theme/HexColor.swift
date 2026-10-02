import SwiftUI

/// Hex değerinden renk bileşeni üretir (saf mantık, test edilebilir).
struct RGBComponents: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    init(hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255
        green = Double((hex >> 8) & 0xFF) / 255
        blue = Double(hex & 0xFF) / 255
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let components = RGBComponents(hex: hex)
        self.init(.sRGB, red: components.red, green: components.green, blue: components.blue, opacity: opacity)
    }
}
