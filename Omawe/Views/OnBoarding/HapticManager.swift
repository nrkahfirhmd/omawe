//
//  HapticManager.swift
//  Omawe
//
//  Created by Nguyen Minh Luat on 7/7/26.
//


import CoreHaptics
import UIKit

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
            debugLog("Haptic engine error: \(error)")
        }
    }

    func tickTickTick() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events: [CHHapticEvent] = []
        var curves: [CHHapticParameterCurve] = []

        // 1) "BUP" — chồng 3 lớp: sắc + trầm + đuôi ngắn -> nặng & đầy
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ],
            relativeTime: 0
        ))
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)   // cực trầm
            ],
            relativeTime: 0.006
        ))
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            ],
            relativeTime: 0.01,
            duration: 0.07                                                          // thân ngắn -> "bụp!"
        ))

        // --- NGHỈ một khoảng ---
        let restAfterBup = 0.35

        // 2) "COLLECT ENERGY" — charge phồng dần, max intensity
        let chargeStart = restAfterBup
        let chargeDur   = 0.4
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ],
            relativeTime: chargeStart,
            duration: chargeDur
        ))
        curves.append(CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0,             value: 0.3),    // bắt đầu đã có lực
                .init(relativeTime: chargeDur * 0.7, value: 0.8),
                .init(relativeTime: chargeDur,       value: 1.0)     // đạt đỉnh
            ],
            relativeTime: chargeStart
        ))

        // 3) "TICK TICK TICK" — phóng ra, nhanh + mạnh dần, mỗi tick chồng đôi cho nặng
        let tickStart = chargeStart + chargeDur + 0
        let intervals: [Double] = [0.14, 0.15, 0.15, 0.15, 0.15, 0.045, 0.04, 0.05]
        var t = tickStart
        for i in 0..<intervals.count {
            let progress = Float(i) / Float(intervals.count - 1)
            let intensity = 0.8 + progress * 0.2   // 0.8 -> 1.0 (đã mạnh sẵn)
            let sharpness = 0.7 + progress * 0.3
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: t
            ))
            // lớp trầm chồng lên -> nặng hơn
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: t + 0.004
            ))
            t += intervals[i]
        }

        play(events, curves: curves)
    }

    private func play(_ events: [CHHapticEvent], curves: [CHHapticParameterCurve] = []) {
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            debugLog("Haptic play error: \(error)")
        }
    }


    // Rung tích năng lượng khi đang GIỮ — phồng dần, max intensity
    func chargeStart() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let dur = 1.4
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            ],
            relativeTime: 0,
            duration: dur
        )
        let curve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0,       value: 0.25),   // bắt đầu đã có lực
                .init(relativeTime: dur * 0.6, value: 0.7),
                .init(relativeTime: dur,       value: 1.0)     // phồng to dần tới trần
            ],
            relativeTime: 0
        )
        play([event], curves: [curve])
    }

    // "BÙM" khi THẢ — chồng 3 lớp: sắc + trầm + thân tắt dần
    func boom() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events: [CHHapticEvent] = []

        // lớp sắc
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ],
            relativeTime: 0
        ))
        // lớp trầm chồng lên -> cú nổ nặng
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)
            ],
            relativeTime: 0.008
        ))
        // thân continuous tắt dần -> "bùmmm..."
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ],
            relativeTime: 0.01,
            duration: 0.25
        ))
        let curve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0,  value: 1.0),
                .init(relativeTime: 0.25, value: 0.0)   // tắt dần
            ],
            relativeTime: 0.01
        )
        play(events, curves: [curve])
    }

    func envelopeJiggle() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events: [CHHapticEvent] = []
        
        // Two quick, subtle ticks to simulate a left-right jiggle/shake
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.40),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
            ],
            relativeTime: 0
        ))
        
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.40),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
            ],
            relativeTime: 0.10
        ))
        
        play(events)
    }

    func envelopeOpen() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events: [CHHapticEvent] = []
        var curves: [CHHapticParameterCurve] = []
        
        // 1) Flap opens (satisfying tick)
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.55)
            ],
            relativeTime: 0
        ))
        
        // 2) Card rising out (continuous hum rising in intensity)
        let slideStart = 0.2
        let slideDur = 1.2
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
            ],
            relativeTime: slideStart,
            duration: slideDur
        ))
        
        curves.append(CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0,             value: 0.15),
                .init(relativeTime: slideDur * 0.5,  value: 0.55),
                .init(relativeTime: slideDur,        value: 0.95)
            ],
            relativeTime: slideStart
        ))
        
        // 3) Card snaps/settles (final pop)
        let snapStart = slideStart + slideDur
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            ],
            relativeTime: snapStart
        ))
        
        play(events, curves: curves)
    }

    func success() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func selectionChanged() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func stopAll() {
        engine?.stop(completionHandler: nil)
        do {
            try engine?.start()
        } catch {
            debugLog("Haptic restart error: \(error)")
        }
    }
}
