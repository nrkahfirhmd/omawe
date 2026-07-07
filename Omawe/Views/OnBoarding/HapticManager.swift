//
//  HapticManager.swift
//  Omawe
//
//  Created by Nguyen Minh Luat on 7/7/26.
//


import CoreHaptics

class HapticManager {
    static let shared = HapticManager()
    private var engine: CHHapticEngine?

    init() {
        prepareEngine()
    }

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
        } catch {
            print("Haptic engine error: \(error)")
        }
    }

    func tickTickTick() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events: [CHHapticEvent] = []
        let count = 6
        let interval = 0.12

        for i in 0..<count {
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: Double(i) * interval
            ))
        }
        play(events)
    }

    private func play(_ events: [CHHapticEvent]) {
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Haptic play error: \(error)")
        }
    }
}