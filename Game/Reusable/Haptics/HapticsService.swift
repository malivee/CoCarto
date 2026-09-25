// Penjelasan file: HapticsService.swift
// Menyediakan getaran sentuhan iOS untuk pemilihan, benturan, dan notifikasi.
// Menggunakan typealias ke tipe resmi UIKit pada platform iOS untuk menghindari ambiguitas overload.

import Foundation

#if canImport(UIKit)
import UIKit

public final class HapticsService {
    public static let shared = HapticsService()

    public typealias ImpactStyle = UIImpactFeedbackGenerator.FeedbackStyle
    public typealias NotificationStyle = UINotificationFeedbackGenerator.FeedbackType

    private init() {}

    public func playSelection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    public func playImpact(style: ImpactStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    public func playNotification(_ type: NotificationStyle) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
#else
public final class HapticsService {
    public static let shared = HapticsService()

    public enum ImpactStyle { case light, medium, heavy, rigid, soft }
    public enum NotificationStyle { case success, error, warning }

    private init() {}
    public func playSelection() {}
    public func playImpact(style: ImpactStyle) {}
    public func playNotification(_ type: NotificationStyle) {}
}
#endif
