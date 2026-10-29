//
//  ClayTheme.swift
//  Tiny Dragon Academy
//
//  Toy Clay design tokens: the colours every screen draws from and the
//  Baloo 2 display font, bundled and registered at launch.
//

import SwiftUI
import CoreText

/// Toy Clay colour tokens. Text on white uses `ink` or `inkSoft` only.
enum ClayColor {
    static let ink = Color(red: 0.29, green: 0.21, blue: 0.34)          // #4A3557
    static let inkSoft = Color(red: 0.54, green: 0.45, blue: 0.60)      // #8A7299
    static let surface = Color.white
    static let accent = Color(red: 0.54, green: 0.42, blue: 1.0)        // #8A6CFF
    static let accentShade = Color(red: 0.42, green: 0.31, blue: 0.88)  // #6B4FE0
    static let sun = Color(red: 1.0, green: 0.79, blue: 0.24)           // #FFC93C
    static let sunShade = Color(red: 0.94, green: 0.64, blue: 0.10)
    static let coral = Color(red: 1.0, green: 0.54, blue: 0.36)         // #FF8A5C
    static let coralShade = Color(red: 0.90, green: 0.38, blue: 0.24)
    static let mint = Color(red: 0.37, green: 0.82, blue: 0.54)         // #5FD08A
    static let mintShade = Color(red: 0.25, green: 0.66, blue: 0.40)
    static let sky = Color(red: 0.29, green: 0.72, blue: 1.0)           // #4AB8FF
    static let skyShade = Color(red: 0.16, green: 0.55, blue: 0.86)
    static let rose = Color(red: 1.0, green: 0.44, blue: 0.63)          // #FF6FA0
    static let backdropTop = Color(red: 1.0, green: 0.85, blue: 0.89)   // #FFD9E4
    static let backdropBottom = Color(red: 0.84, green: 0.93, blue: 1.0) // #D7ECFF
    static let blobPink = Color(red: 1.0, green: 0.76, blue: 0.83)      // #FFC2D3
    static let blobSky = Color(red: 0.78, green: 0.91, blue: 1.0)       // #C8E9FF
    static let shadow = Color(red: 0.42, green: 0.22, blue: 0.40).opacity(0.16)
    static let innerShade = Color.black.opacity(0.06)
}

enum FontRegistry {
    static let displayFamily = "Baloo 2"
    static let displayFamilyPostScript = "Baloo2-Regular"

    /// True once Baloo 2 is available to UIKit and SwiftUI.
    private(set) static var isDisplayFontAvailable = false

    /// Registers the bundled fonts for this process. Safe to call more than once.
    @discardableResult
    static func registerBundledFonts() -> Bool {
        if UIFont(name: displayFamilyPostScript, size: 12) != nil {
            isDisplayFontAvailable = true
            return true
        }
        guard let url = Bundle.main.url(forResource: "Baloo2", withExtension: "ttf") else { return false }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        isDisplayFontAvailable = UIFont(name: displayFamilyPostScript, size: 12) != nil
        return isDisplayFontAvailable
    }
}

extension Font {
    /// The game's display face: Baloo 2 at a fixed size, or SF Rounded if it couldn't load.
    static func clay(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        guard FontRegistry.isDisplayFontAvailable else {
            return .system(size: size, weight: weight, design: .rounded)
        }
        return .custom(FontRegistry.displayFamily, fixedSize: size).weight(weight)
    }
}
