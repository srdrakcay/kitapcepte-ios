import Testing
@testable import KitapCepte

struct HexColorTests {
    @Test func decodesPrimaryHexIntoComponents() {
        let components = RGBComponents(hex: 0x5B3FE8)
        #expect(components.red == Double(0x5B) / 255)
        #expect(components.green == Double(0x3F) / 255)
        #expect(components.blue == Double(0xE8) / 255)
    }

    @Test func whiteIsAllOnes() {
        #expect(RGBComponents(hex: 0xFFFFFF) == RGBComponents(hex: 0xFFFFFF))
        #expect(RGBComponents(hex: 0xFFFFFF).red == 1)
    }
}
