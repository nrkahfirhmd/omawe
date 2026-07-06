//
//  TripInvitationView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 05/07/26.
//

import SwiftUI
import UIKit

struct TripInvitationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var draft: TripDraft
    let creationErrorMessage: String?
    let canConfirmTripCreation: Bool
    let isSavingTrip: Bool
    let hasCreatedTrip: Bool
    let onShareLink: () -> Void
    let onTryAgain: () -> Void
    
    @Binding var isCalendarPresented: Bool
    @Binding var isEditingInvitationDetails: Bool
    @Binding var isLocationSheetPresented: Bool
    @State private var didCopyRoomCode = false
    @State private var locationSearchQuery = ""
    @State private var isResolvingLocation = false
    @State private var isEditTitle = false
    @StateObject private var locationSearchService = LocationSearchService()
    @Namespace private var invitationNamespace
    @FocusState private var isTripNameFocused: Bool
    
    init(
        draft: Binding<TripDraft>,
        creationErrorMessage: String?,
        canConfirmTripCreation: Bool,
        isSavingTrip: Bool,
        hasCreatedTrip: Bool,
        isCalendarPresented: Binding<Bool>,
        isEditingInvitationDetails: Binding<Bool>,
        isLocationSheetPresented: Binding<Bool>,
        onShareLink: @escaping () -> Void,
        onTryAgain: @escaping () -> Void
    ) {
        self._draft = draft
        self.creationErrorMessage = creationErrorMessage
        self.canConfirmTripCreation = canConfirmTripCreation
        self.isSavingTrip = isSavingTrip
        self.hasCreatedTrip = hasCreatedTrip
        self._isCalendarPresented = isCalendarPresented
        self._isEditingInvitationDetails = isEditingInvitationDetails
        self._isLocationSheetPresented = isLocationSheetPresented
        self.onShareLink = onShareLink
        self.onTryAgain = onTryAgain
    }
    
    private var displayTripName: String {
        draft.trimmedName.isEmpty ? "Trip Name" : draft.trimmedName
    }
    
    private var displayLocationName: String {
        draft.trimmedLocationName.isEmpty ? "No location selected" : draft.trimmedLocationName
    }
    
    private var buttonTitle: String {
        if isSavingTrip { return "Saving..." }
        if didCopyRoomCode { return "Code copied" }
        if !hasCreatedTrip { return "Create Trip" }
        return "Share link"
    }
    
    var body: some View {
        ZStack {
            
            invitationStageBackground
            
            CustomDynamicIsland(
                color: .black,
                borderColor: LinearGradient(stops: [
                    .init(color: Color(hex: "03B9D6"), location: 0.0),
                    .init(color: Color(hex: "7AE8FF"), location: 0.51),
                    .init(color: Color(hex: "03B9D6"), location: 1.0),
                ], startPoint: UnitPoint.leading, endPoint: .trailing),
                fillColor: .black
            )
            .padding(.top, 8)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if !isEditingInvitationDetails {
                    header
                        .padding(.top, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                invitationTicket
                    .frame(maxWidth: isEditingInvitationDetails ? .infinity : 430)
                    .frame(maxHeight: isEditingInvitationDetails ? .infinity : nil)
                    .padding(.top, isEditingInvitationDetails ? 0 : 20)
                    .padding(.horizontal, isEditingInvitationDetails ? 0 : 24)
                    .animation(.spring(response: 0.54, dampingFraction: 0.88), value: isEditingInvitationDetails)
                    .ignoresSafeArea()
                
                Spacer(minLength: 20)
                bottomControls
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.spring(response: 0.54, dampingFraction: 0.88), value: isEditingInvitationDetails)
        .sheet(isPresented: $isLocationSheetPresented) {
            TripLocationPickerSheet(
                draft: $draft,
                locationSearchQuery: $locationSearchQuery,
                isLocationSheetPresented: $isLocationSheetPresented,
                isResolvingLocation: $isResolvingLocation,
                locationSearchService: locationSearchService
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(.ultraThinMaterial)
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
    }
    
    private var invitationStageBackground: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Theme.primaryBox],
                startPoint: .top,
                endPoint: .bottom
            )
            
            PlusPattern()
                .mask(
                    LinearGradient(
                        colors: [.clear, .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            SpotlightShape()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.26), .white.opacity(0.02), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 14)
                .padding(.horizontal, 76)
                .offset(y: 64)
        }
        .ignoresSafeArea()
    }
    
    private var header: some View {
        VStack(spacing: 7) {
            Image(systemName: "eyes")
                .font(.button())
                .foregroundStyle(.white.opacity(0.3))
            
            Text("Invitation\nPreview")
                .font(.button())
                .fontWidth(.expanded)
                .foregroundStyle(.white.opacity(0.52))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    private var invitationTicket: some View {
        ZStack {
            InvitationTicketBackground(isEditing: isEditingInvitationDetails)
            
            if isEditingInvitationDetails {
                editingTicketContent
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                previewTicketContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: isEditingInvitationDetails ? 0 : 48, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 48, style: .continuous)
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
        .shadow(color: .black.opacity(0.38), radius: 28, x: 0, y: 18)
    }
    
    private var previewTicketContent: some View {
        VStack(spacing: 0) {
            VStack {
                VStack {
                    Text(displayTripName)
                        .font(.title1().weight(.semibold))
                        .fontWidth(.expanded)
                        .foregroundStyle(Color(red: 0.0, green: 0.19, blue: 0.22))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.bottom, 4)
                        .matchedGeometryEffect(id: "tripTitle", in: invitationNamespace)
                    
                    Text("by @Bintang")
                        .font(.caption1())
                        .foregroundStyle(Theme.primaryBox.opacity(0.72))
                        .padding(.bottom, 12)
                    
                    HStack(spacing: -7) {
                        invitationAvatar(initials: "B", tint: .orange)
                        invitationAvatar(initials: "K", tint: .brown)
                        invitationAvatar(initials: "A", tint: .yellow)
                        
                        Text("+3")
                            .font(.headline())
                            .foregroundStyle(.black.opacity(0.48))
                            .padding(.leading, 18)
                    }
                }
                .padding(.bottom, 48)
                
                VStack(spacing: 18) {
                    ticketDetail(
                        label: "Event Date",
                        value: draft.arrivalDate.formatted(.dateTime.weekday(.wide).day().month(.wide))
                    )
                    
                    ticketDetail(
                        label: "Meet Time",
                        value: draft.arrivalDate.formatted(date: .omitted, time: .shortened)
                    )
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            
            Spacer(minLength: 0)
            
            VStack {
                Text("Location")
                    .font(.headline())
                    .foregroundStyle(.white.opacity(0.48))
                    .padding(.bottom, 4)
                
                VStack(spacing: 4) {
                    Text(displayLocationName)
                        .font(.title3())
                        .fontWidth(.expanded)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    if !draft.locationAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(draft.locationAddress)
                            .font(.caption2())
                            .foregroundStyle(.white.opacity(0.86))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .lineLimit(3)
                    }
                }
                .padding(.bottom, 12)
                
                TripLocationNotePill(
                    apartmentUnitFloor: draft.apartmentUnitFloor,
                    locationNickname: draft.locationNickname
                )
                .padding(.bottom, 12)
                
                HStack {
                    Text("#Code")
                        .font(.button().width(.expanded))
                        .foregroundStyle(.white.opacity(0.28))
                    
                    Spacer()
                    
                    Text(draft.invitationCode)
                        .font(.button().width(.expanded))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: 320, maxHeight: .infinity, alignment: .top)
        .padding(24)
    }
    
    private var editingTicketContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 32) {
                Spacer()
                ZStack {
                    Text(displayTripName)
                        .font(.title1().weight(.semibold))
                        .fontWidth(.expanded)
                        .foregroundStyle(Color(red: 0.0, green: 0.19, blue: 0.22))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .opacity(isEditTitle ? 0 : 1)

                    TextField("", text: $draft.name)
                        .font(.title1().weight(.semibold))
                        .fontWidth(.expanded)
                        .foregroundStyle(Color(red: 0.0, green: 0.19, blue: 0.22))
                        .multilineTextAlignment(.center)
                        .opacity(isEditTitle ? 1 : 0)
                        .focused($isTripNameFocused)
                        .disabled(!isEditTitle)
                        .onAppear {
                            if isEditTitle {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    isTripNameFocused = true
                                }
                            }
                        }
                        .onSubmit {
                            isTripNameFocused = false
                            isEditTitle = false
                        }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isEditTitle else { return }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
                        isEditTitle = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isTripNameFocused = true
                    }
                }
                .matchedGeometryEffect(id: "tripTitle", in: invitationNamespace)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.04))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isEditTitle ? Theme.primaryBox : Color.black.opacity(0.08),
                            lineWidth: isEditTitle ? 2 : 1
                        )
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.88), value: isEditTitle)
                
                TripDateTimeDraftPicker(
                    arrivalDate: $draft.arrivalDate,
                    isCalendarPresented: $isCalendarPresented,
                    color: .black
                )
                Spacer()
                VStack(spacing: 20) {
                    Text("Location")
                        .font(.headline())
                    TripDestinationDraftSection(
                        draft: $draft,
                        isLocationSheetPresented: $isLocationSheetPresented
                    )
                }
            }
        }
        .padding(24)
        
    }
    
    private func ticketDetail(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.headline())
                .foregroundStyle(.black.opacity(0.46))
            
            Text(value)
                .font(.title3())
                .fontWidth(.expanded)
                .foregroundStyle(.black.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 12) {
            if let creationErrorMessage {
                errorMessage(creationErrorMessage)
            }
            
            if !isEditingInvitationDetails {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline())
                            .padding(8)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Back")
                    
                    Button {
                        if hasCreatedTrip {
                            copyRoomCode()
                        } else {
                            onShareLink()
                        }
                        
                    } label: {
                        HStack(spacing: 14) {
                            if isSavingTrip {
                                ProgressView()
                                    .tint(.white)
                                    .frame(height: 15)
                            } else {
                                Image(systemName: didCopyRoomCode ? "checkmark.circle.fill" : "link")
                                    .font(.button())
                            }
                            
                            Text(buttonTitle)
                                .font(.button())
                                .fontWidth(.expanded)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .foregroundStyle(canConfirmTripCreation || isSavingTrip || hasCreatedTrip ? .white : .white.opacity(0.52))
                        .overlay {
                            Capsule()
                                .stroke(Theme.primary, lineWidth: 1.5)
                        }
                    }
                    .glassEffect(.clear)
                    .disabled((!canConfirmTripCreation && !hasCreatedTrip) || isSavingTrip)
                    .accessibilityLabel(buttonTitle)
                    
                    Button {
                        withAnimation(.spring(response: 0.54, dampingFraction: 0.88)) {
                            isEditingInvitationDetails = true
                        }
                    } label: {
                        Image(systemName: "pencil.line")
                            .font(.headline())
                            .padding(8)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Edit invitation details")
                }
            } else {
                HStack {
                    Button {
                        dismissEditMode()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "xmark")
                                .font(.button())
                            
                            
                            Text("Cancel")
                                .font(.button())
                                .fontWidth(.expanded)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .foregroundStyle(.white )
                        .overlay {
                            Capsule()
                                .stroke(Theme.primary, lineWidth: 1.5)
                        }
                    }
                    .glassEffect(.clear)
                    
                    Button {
                        dismissEditMode()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "checkmark")
                                .font(.button())
                            
                            
                            Text("Done")
                                .font(.button())
                                .fontWidth(.expanded)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .foregroundStyle(.white)
                        .background(Capsule().fill(Color.blue.opacity(0.32)))
                        .overlay {
                            Capsule()
                                .stroke(Theme.primary, lineWidth: 1.5)
                        }
                    }
                    .glassEffect(.clear)
                }
            }
        }
    }
    
    private func errorMessage(_ message: String) -> some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.red.opacity(0.95))
            
            Button("Try again") {
                onTryAgain()
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .disabled(!canConfirmTripCreation || isSavingTrip)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private func copyRoomCode() {
        UIPasteboard.general.string = draft.invitationCode
        
        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            didCopyRoomCode = true
        }
        
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            
            await MainActor.run {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                    didCopyRoomCode = false
                }
            }
        }
    }
    
    private func dismissEditMode() {
        withAnimation(.spring(response: 0.54, dampingFraction: 0.88)) {
            isCalendarPresented = false
            isEditingInvitationDetails = false
        }
    }
    
    private func invitationAvatar(initials: String, tint: Color) -> some View {
        Text(initials)
            .font(.bodyText())
            .foregroundStyle(.black.opacity(0.74))
            .frame(width: 25, height: 25)
            .background(tint, in: Circle())
            .overlay {
                Circle()
                    .stroke(.black.opacity(0.72), lineWidth: 1)
            }
    }
}

private struct SpotlightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - 65, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + 65, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX + 700, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX - 700, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct InvitationTicketBackground: View {
    var isEditing: Bool = false
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Image(.moire)
                    .resizable()
                    .scaledToFill()
                
                ZStack {
                    LinearGradient(
                        colors: [
                            .black,
                            Theme.primaryBox,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    PlusPattern()
                        .mask(
                            LinearGradient(
                                colors: [.clear, .white],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .clipShape(BottomWave())
                .frame(height: isEditing ? geo.size.height * 0.3:  geo.size.height * 0.48)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 48))
    }
}

private struct BottomWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let amplitude: CGFloat = 10
        let wavelength: CGFloat = 42
        
        path.move(to: .zero)
        
        var x: CGFloat = 0
        
        while x <= rect.width {
            path.addQuadCurve(
                to: CGPoint(x: x + wavelength / 2, y: amplitude),
                control: CGPoint(x: x + wavelength / 4, y: 0)
            )
            
            path.addQuadCurve(
                to: CGPoint(x: x + wavelength, y: 10),
                control: CGPoint(x: x + wavelength * 0.75, y: amplitude * 2)
            )
            
            x += wavelength
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    @Previewable @State var draft = TripDraft(
        name: "Ex-Boyfriends Celebration",
        arrivalDate: .now,
        locationName: "Toko Kopi Jaya, Kuta",
        locationAddress: "Jl. Dewi Sri No. 99X, Legian, Kec. Kuta, Kabupaten Badung, Bali 80361",
        apartmentUnitFloor: "Room 222",
        locationNickname: "Luat's House"
    )
    @Previewable @State var isCalendarPresented = false
    @Previewable @State var isEditingInvitationDetails = false
    @Previewable @State var isLocationSheetPresented = false
    
    TripInvitationView(
        draft: $draft,
        creationErrorMessage: nil,
        canConfirmTripCreation: true,
        isSavingTrip: false,
        hasCreatedTrip: false,
        isCalendarPresented: $isCalendarPresented,
        isEditingInvitationDetails: $isEditingInvitationDetails,
        isLocationSheetPresented: $isLocationSheetPresented,
        onShareLink: {},
        onTryAgain: {}
    )
}
