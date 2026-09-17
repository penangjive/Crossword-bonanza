import UIKit

/// Thin wrapper over UIKit feedback generators.
///
/// Generators are kept alive and pre-warmed, because creating one at the moment
/// of the tap is the classic reason haptics feel late.
enum Haptics {

    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        light.prepare()
        medium.prepare()
        soft.prepare()
        notification.prepare()
    }

    /// A key going down.
    static func tap() {
        light.impactOccurred()
        light.prepare()
    }

    /// A correct letter landing in the grid.
    static func correct() {
        medium.impactOccurred(intensity: 0.7)
        medium.prepare()
    }

    /// A wrong letter bouncing off. Deliberately the softest of the three --
    /// it is a nudge, not a slap.
    static func wrong() {
        soft.impactOccurred(intensity: 0.5)
        soft.prepare()
    }

    static func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }
}
