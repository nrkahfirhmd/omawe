//
//  JoinTripView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 05/07/26.
//

import SwiftUI
import SwiftData

struct JoinTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTripAction: TripAction?
    @State private var invitationCode = ""
    @State private var isJoining = false
    @State private var joinErrorMessage: String?

    private var canJoinTrip: Bool {
        invitationCode.count == 6 && !isJoining
    }

    var body: some View {
        Group {
            if selectedTripAction == .join {
                VStack {
                    DynamicBox(
                        theme: Theme.themePrimary,
                        icon: "number.square",
                        title: "Invitation Code",
                        subtitle: "Enter the code from your invite",
                        helperText: "6 characters. Letters and numbers only",
                        footerTitle: "Joining a trip"
                    ) {
                        VStack(spacing: 22) {
                            InvitationCodeField(code: $invitationCode)
                            
                            if let joinErrorMessage {
                                Text(joinErrorMessage)
                                    .font(.caption1().bold())
                                    .foregroundStyle(.red.opacity(0.95))
                                    .multilineTextAlignment(.center)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .transition(.scale(scale: 0.18, anchor: .top).combined(with: .opacity))
                    
                    Button {
                        joinTrip()
                    } label: {
                        HStack(spacing: 12) {
                            if isJoining {
                                ProgressView()
                                    .tint(canJoinTrip ? Color.black
                                          : Color.gray.opacity(0.55))
                            }

                            Text("Join Trip")
                                .font(.button())
                                .fontWidth(.expanded)
                        }
                        .foregroundStyle(canJoinTrip ? Color.black
                                         : Color.gray.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .overlay {
                            RoundedRectangle(cornerRadius: 37, style: .continuous)
                                .stroke(
                                    Color.omawePrimary.opacity(canJoinTrip ? 0.95 : 0.35),
                                    lineWidth: 1.5
                                )
                                .allowsHitTesting(false)
                        }
                    }
                    .glassEffect(.clear)
                    .padding(.horizontal, 12)
                    .buttonStyle(.plain)
                    .disabled(!canJoinTrip)
                    .animation(.spring(response: 0.34, dampingFraction: 0.88), value: canJoinTrip)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: invitationCode) { _, _ in
            joinErrorMessage = nil
        }
        .onChange(of: selectedTripAction) { _, action in
            guard action != .join else { return }
            resetJoinFlow()
        }
    }

    private func joinTrip() {
        guard canJoinTrip else { return }

        isJoining = true
        joinErrorMessage = nil

        Task {
            do {
                _ = try await TripJoinService().joinTrip(invitationCode: invitationCode, in: modelContext)
                isJoining = false

                withAnimation(.spring(response: 0.72, dampingFraction: 0.88)) {
                    selectedTripAction = nil
                }
            } catch {
                isJoining = false
                joinErrorMessage = error.localizedDescription
            }
        }
    }

    private func resetJoinFlow() {
        invitationCode = ""
        isJoining = false
        joinErrorMessage = nil
    }
}

private struct InvitationCodeField: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool

    private let characterCount = 6
    private let boxSize: CGFloat = 48

    private var activeIndex: Int {
        min(code.count, characterCount - 1)
    }

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .focused($isFocused)
                .keyboardType(.asciiCapable)
                .textContentType(.oneTimeCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { _, newValue in
                    let normalized = String(TripJoinService.normalizedCode(newValue).prefix(characterCount))
                    guard normalized != newValue else { return }
                    code = normalized
                }

            HStack(spacing: 8) {
                ForEach(0..<characterCount, id: \.self) { index in
                    codeBox(at: index)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
            }
        }
    }

    private func codeBox(at index: Int) -> some View {
        let isActive = isFocused && index == activeIndex
        let character = character(at: index)

        return ZStack {
            Image(.pedal)

            if let character {
                Text(String(character))
                    .font(.title3.weight(.bold))
                    .fontWidth(.expanded)
                    .foregroundStyle(.white)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            } else if isActive {
                CursorView()
            }

            if isActive && character != nil {
                CursorView()
                    .offset(x: 14)
            }
        }
        .frame(width: boxSize, height: 67)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: code)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isFocused)
    }

    private func character(at index: Int) -> Character? {
        guard index < code.count else { return nil }
        return Array(code)[index]
    }
}

private struct CursorView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.6)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.2)

            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(.white)
                .frame(width: 2, height: 24)
                .opacity(phase < 0.6 ? 1 : 0.18)
                .animation(.easeInOut(duration: 0.18), value: phase < 0.6)
        }
    }
}

#Preview {
    @Previewable @State var selectedTripAction: TripAction? = .join

    JoinTripView(selectedTripAction: $selectedTripAction)
        .modelContainer(
            for: [
                TripModel.self,
                TripMember.self,
                LocationUpdate.self,
                UserProfile.self
            ],
            inMemory: true
        )
}
