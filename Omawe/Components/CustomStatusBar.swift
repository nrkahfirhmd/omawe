//
//  CustomStatusBar.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 30/06/26.
//

import SwiftUI
import UIKit

struct CustomStatusBar: View {
    @State private var batteryLevel: Float = UIDevice.current.batteryLevel

    private var currentTime: String {
        Date.now.formatted(
            .dateTime
                .hour()
                .minute()
        )
    }

    private var batteryPercentage: Int {
        guard batteryLevel >= 0 else { return 0 }
        return Int((batteryLevel * 100).rounded())
    }

    private var batterySymbolName: String {
        switch batteryPercentage {
        case 0...10:
            return "battery.0percent"
        case 11...25:
            return "battery.25percent"
        case 26...50:
            return "battery.50percent"
        case 51...75:
            return "battery.75percent"
        default:
            return "battery.100percent"
        }
    }

    var body: some View {
        HStack {
            TimelineView(.periodic(from: .now, by: 60)) { _ in
                Text(currentTime)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            Spacer()

            HStack(spacing: 4) {
                Text("\(batteryPercentage)%")
                    .monospacedDigit()

                Image(systemName: batterySymbolName)
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 36)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            batteryLevel = UIDevice.current.batteryLevel
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIDevice.batteryLevelDidChangeNotification
            )
        ) { _ in
            batteryLevel = UIDevice.current.batteryLevel
        }
    }
}

#Preview {
    CustomStatusBar()
}
