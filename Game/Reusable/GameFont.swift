import UIKit

/// The single typeface used by all player-facing game UI.
public enum GameFont {
    public static let name = "IndieFlower"

    @discardableResult
    static func register() -> Bool {
        let isAvailable = UIFont(name: name, size: 16) != nil
        assert(isAvailable, "The bundled \(name) font was not registered by UIAppFonts.")
        return isAvailable
    }

    static func uiFont(size: CGFloat) -> UIFont {
        register()
        return UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
    }
}
