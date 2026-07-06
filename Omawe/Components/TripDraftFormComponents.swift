//
//  TripDraftFormComponents.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 05/07/26.
//

import SwiftUI
import MapKit

struct TripNameDraftField: View {
    @Binding var name: String
    let color: Color

    var body: some View {
        VStack(spacing: 20) {
            TextField("Trip name", text: $name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(color)
                .tint(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.white.opacity(0.42))
                        .frame(height: 1)
                }
        }
    }
}

struct TripDateTimeDraftPicker: View {
    @Binding var arrivalDate: Date
    @Binding var isCalendarPresented: Bool
    let color: Color

    private var selectedHour: Binding<Int> {
        Binding(
            get: {
                Calendar.current.component(.hour, from: arrivalDate)
            },
            set: { newHour in
                let calendar = Calendar.current
                let minute = calendar.component(.minute, from: arrivalDate)
                arrivalDate = calendar.date(
                    bySettingHour: newHour,
                    minute: minute,
                    second: 0,
                    of: arrivalDate
                ) ?? arrivalDate
            }
        )
    }

    private var selectedMinute: Binding<Int> {
        Binding(
            get: {
                Calendar.current.component(.minute, from: arrivalDate)
            },
            set: { newMinute in
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: arrivalDate)
                arrivalDate = calendar.date(
                    bySettingHour: hour,
                    minute: newMinute,
                    second: 0,
                    of: arrivalDate
                ) ?? arrivalDate
            }
        )
    }

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                VStack {
                    Text("Event Date")
                        .font(.headline().weight(.semibold))
                        .foregroundStyle(color)
                    
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                            isCalendarPresented = true
                        }
                    } label: {
                        Text(arrivalDate
                            .formatted(
                                .dateTime
                                    .locale(Locale(identifier: "en_US"))
                                    .month(.abbreviated)
                                    .day()
                                    .year()
                            )
                        )
                        .font(.bodyText())
                        .foregroundStyle(color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.18), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                

                VStack(spacing: 18) {
                    Text("Meet Time")
                        .font(.headline().weight(.semibold))
                        .foregroundStyle(color)

                    HStack(spacing: 18) {
                        CustomWheelPicker(
                            values: Array(0...23),
                            selection: selectedHour,
                            itemHeight: 42,
                            visibleRowCount: 5
                        )

                        Text(":")
                            .font(.title3())

                        CustomWheelPicker(
                            values: Array(0...59),
                            selection: selectedMinute,
                            itemHeight: 42,
                            visibleRowCount: 5
                        )
                    }
                }
            }

            if isCalendarPresented {
                VStack(spacing: 0) {
                    DatePicker(
                        "Arrival date",
                        selection: $arrivalDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(.cyan)
                    .colorScheme(.dark)
                }
                .frame(width: 300)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
                .onChange(of: arrivalDate) { _, _ in
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                        isCalendarPresented = false
                    }
                }
            }
        }
    }
}

struct TripDestinationDraftSection: View {
    @Binding var draft: TripDraft
    @Binding var isLocationSheetPresented: Bool

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                if draft.trimmedLocationName.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                            isLocationSheetPresented = true
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.title3())
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(width: 48, height: 48)
                                .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Choose a location")
                                    .font(.bodyText().bold())
                                    .foregroundStyle(.white)

                                Text("Set your meeting point")
                                    .font(.subhead())
                                    .foregroundStyle(.white.opacity(0.68))
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white.opacity(0.62))
                        }
                        .padding(12)
                        .padding(.trailing, 16)
                        .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Choose event location")
                } else {
                    VStack(spacing: 12) {
                        Button {
                            isLocationSheetPresented = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "location.square.fill")
                                    .font(.largeTitle())
                                    .foregroundStyle(.cyan)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(draft.locationName)
                                        .font(.bodyText())
                                        .foregroundStyle(.black)
                                        .lineLimit(1)

                                    Text(draft.locationAddress)
                                        .font(.subhead())
                                        .foregroundStyle(.black.opacity(0.72))
                                        .lineLimit(1)
                                }

                                Spacer(minLength: 0)

                                Image(systemName: "pencil")
                                    .font(.system(size: 19, weight: .bold))
                                    .foregroundStyle(.black.opacity(0.82))
                                    .frame(width: 42, height: 42)
                            }
                            .padding(12)
                            .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit location")

                        TripLocationNotePill(
                            apartmentUnitFloor: draft.apartmentUnitFloor,
                            locationNickname: draft.locationNickname
                        )
                    }
                }
            }
        }
    }
}

struct TripLocationPickerSheet: View {
    @Binding var draft: TripDraft
    @Binding var locationSearchQuery: String
    @Binding var isLocationSheetPresented: Bool
    @Binding var isResolvingLocation: Bool
    @ObservedObject var locationSearchService: LocationSearchService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !locationSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            if isResolvingLocation {
                                HStack(spacing: 10) {
                                    ProgressView()
                                        .tint(.black)
                                    Text("Getting location details...")
                                        .font(.bodyText().weight(.medium))
                                        .foregroundStyle(.black.opacity(0.62))
                                }
                                .padding(.vertical, 6)
                            } else if locationSearchService.completions.isEmpty {
                                Text("No matching places yet")
                                    .font(.callout())
                                    .foregroundStyle(.black.opacity(0.55))
                                    .padding(.vertical, 6)
                            } else {
                                ForEach(locationSearchService.completions, id: \.self) { completion in
                                    Button {
                                        Task {
                                            isResolvingLocation = true
                                            defer { isResolvingLocation = false }

                                            guard let item = await locationSearchService.select(completion) else {
                                                return
                                            }

                                            draft.locationName = item.name ?? completion.title
                                            draft.locationAddress = item.placemark.title ?? completion.subtitle
                                            draft.coordinate = item.placemark.coordinate
                                            locationSearchQuery = ""
                                        }
                                    } label: {
                                        HStack(alignment: .top, spacing: 14) {
                                            Image(systemName: "mappin.and.ellipse")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundStyle(.cyan)
                                                .frame(width: 28)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(completion.title)
                                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                                    .foregroundStyle(.black)
                                                    .multilineTextAlignment(.leading)

                                                if !completion.subtitle.isEmpty {
                                                    Text(completion.subtitle)
                                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                                        .foregroundStyle(.black.opacity(0.58))
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }

                                            Spacer(minLength: 0)
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 14)
                                        .background(.black.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Selected Location")
                                .font(.headline())
                                .foregroundStyle(.black.opacity(0.62))

                            if draft.trimmedLocationName.isEmpty {
                                HStack(spacing: 14) {
                                    Image(systemName: "mappin.square.fill")
                                        .font(.largeTitle())
                                        .foregroundStyle(.black.opacity(0.55))

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("No location selected")
                                            .font(.bodyText())
                                            .foregroundStyle(.black.opacity(0.82))

                                        Text("Search a place first")
                                            .font(.subhead())
                                            .foregroundStyle(.black.opacity(0.56))
                                    }

                                    Spacer(minLength: 0)
                                }
                                .padding(12)
                                .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                            } else {
                                HStack(spacing: 14) {
                                    Image(systemName: "location.app.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(Theme.primary)

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(draft.locationName)
                                            .font(.bodyText())
                                            .foregroundStyle(.black)
                                            .lineLimit(1)

                                        Text(draft.locationAddress)
                                            .font(.subhead())
                                            .foregroundStyle(.gray.opacity(0.72))
                                            .lineLimit(1)
                                    }

                                    Spacer(minLength: 0)

                                    Button {
                                        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                            draft.locationName = ""
                                            draft.locationAddress = ""
                                            draft.apartmentUnitFloor = ""
                                            draft.locationNickname = ""
                                            draft.coordinate = nil
                                            locationSearchQuery = ""
                                            locationSearchService.search("")
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.bodyText())
                                            .foregroundStyle(.gray)
                                            .frame(width: 52, height: 16)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Remove selected location")
                                }
                                .padding(12)
                                .background(Color(uiColor: .systemGroupedBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Apartment, Unit, or Floor")
                                .font(.headline())
                                .foregroundStyle(.black.opacity(0.62))

                            TextField("Example: Apt 1A", text: $draft.apartmentUnitFloor)
                                .font(.bodyText())
                                .foregroundStyle(.black)
                                .tint(.black)
                                .padding(.horizontal, 18)
                                .frame(height: 58)
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())

                            Text("Optional")
                                .font(.caption1().bold())
                                .foregroundStyle(.black.opacity(0.48))
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Location Name")
                                .font(.headline())
                                .foregroundStyle(.black.opacity(0.62))

                            TextField("Example: Kuta Beach Apt", text: $draft.locationNickname)
                                .font(.bodyText())
                                .foregroundStyle(.black)
                                .tint(.black)
                                .padding(.horizontal, 18)
                                .frame(height: 58)
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())

                            Text("Optional")
                                .font(.caption1().bold())
                                .foregroundStyle(.black.opacity(0.48))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .safeAreaInset(edge: .top) {
                HStack(alignment: .center) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3())
                            .foregroundStyle(.black.opacity(0.82))

                        TextField("Search a place", text: $locationSearchQuery)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .font(.bodyText().weight(.medium))
                            .foregroundStyle(.black)
                            .tint(.black)
                            .onChange(of: locationSearchQuery) { _, query in
                                locationSearchService.search(query)
                            }

                        Image(systemName: "mic")
                            .font(.headline())
                            .foregroundStyle(.black.opacity(0.68))
                    }
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .glassEffect()

                    Button {
                        locationSearchQuery = ""
                        locationSearchService.search("")
                        isLocationSheetPresented = false
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.bodyText().weight(.medium))
                            .frame(height: 48)
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                    .tint(.cyan)
                    .fontWeight(.semibold)
                    .disabled(draft.trimmedLocationName.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.top, 30)
                .padding(.bottom, 8)
            }
        }
        .background {
            Image(.homeBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .preferredColorScheme(.light)
    }
}

struct TripLocationNotePill: View {
    let apartmentUnitFloor: String
    let locationNickname: String

    private var unit: String {
        apartmentUnitFloor.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nickname: String {
        locationNickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        if !nickname.isEmpty || !unit.isEmpty {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .font(.headline())
                    .foregroundStyle(.white.opacity(0.9))

                HStack {
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.subhead().bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    if !unit.isEmpty && !nickname.isEmpty {
                        Text("•")
                            .foregroundStyle(.white)
                    }

                    if !nickname.isEmpty {
                        Text(nickname)
                            .font(.subhead())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
            .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 50, style: .continuous))
        }
    }
}
