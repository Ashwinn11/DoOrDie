import UIKit

/// Centralised haptic feedback dispatcher. All call sites go through here so
/// feedback style is consistent and easy to recalibrate in one place.
enum HapticEngine {
    /// Physical impact — use for taps, selections, and confirmations.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Semantic outcome — success (.success), warning (.warning), error (.error).
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    /// Lightweight tick — use for selection changes (plan cards, tab switches).
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
