//
//  CustomWheelPicker.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 04/07/26.
//


import SwiftUI
import UIKit
import AudioToolbox

struct CustomWheelPicker: View {
    
    let values: [Int]
    @Binding var selection: Int
    @State private var scrollSelection: Int?
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    var itemHeight: CGFloat = 56
    var visibleRowCount: Int = 5   // <-- how many rows are visible in the picker
    
    private var containerHeight: CGFloat { itemHeight * CGFloat(visibleRowCount) }
    
    var body: some View {
        GeometryReader { geometry in
            let pickerCenter = geometry.size.height / 2

            ZStack {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(values, id: \.self) { value in
                            WheelItem(
                                value: value,
                                itemHeight: itemHeight,
                                pickerCenter: pickerCenter
                            )
                            .id(value)
                        }
                    }
                    .scrollTargetLayout()
                }
                .coordinateSpace(name: "picker")
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrollSelection, anchor: .center)
                .contentMargins(
                    .vertical,
                    max(0, geometry.size.height / 2 - itemHeight / 2),
                    for: .scrollContent
                )
                .onAppear {
                    scrollSelection = selection
                    selectionFeedback.prepare()
                }
                .onChange(of: scrollSelection) { oldValue, newValue in
                    guard let newValue else { return }

                    if oldValue != nil && oldValue != newValue {
                        selectionFeedback.selectionChanged()
                        AudioServicesPlaySystemSound(1157)
                        selectionFeedback.prepare()
                    }

                    selection = newValue
                }
                .onChange(of: selection) { _, newValue in
                    scrollSelection = newValue
                }
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.16))
                    .frame(height: itemHeight)
                    .allowsHitTesting(false)
                    .padding(6)
            }
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.black.opacity(0.59))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color(hex: "#1C1C1C"), location: 0),
                                        .init(color: Color(hex: "#3F3F3F"), location: 0.51),
                                        .init(color: Color(hex: "#1C1C1C"), location: 1),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
            }
        }
        .frame(width: 90, height: containerHeight - 30)
    }
}

private struct WheelItem: View {

    let value: Int
    let itemHeight: CGFloat
    let pickerCenter: CGFloat

    var body: some View {
        Text(String(format: "%02d", value))
            .font(.largeTitle)
            .fontWidth(.expanded)
            .foregroundStyle(.white)
            .frame(height: itemHeight)
            .frame(maxWidth: .infinity)
            .shadow(
                color: .black.opacity(0.25), radius: 0, x: 0, y: 1
            )
            .visualEffect { content, proxy in

                let frame = proxy.frame(in: .named("picker"))
                let distance = abs(frame.midY - pickerCenter)
                let progress = min(distance / pickerCenter, 1)

                let scale = 1 - progress * 0.45
                let opacity = 1 - progress * 0.8
                let blur = progress * 4
                let rotation = progress * 55

                return content
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .blur(radius: blur)
                    .rotation3DEffect(
                        .degrees(frame.midY < pickerCenter ? rotation : -rotation),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.8
                    )
            }
    }
}

#Preview {
    @Previewable @State var selectedHour = 12

    ZStack {
        Color.black
            .ignoresSafeArea()

        CustomWheelPicker(
            values: Array(0...23),
            selection: $selectedHour,
            itemHeight: 42,
            visibleRowCount: 5
        )
    }
}
