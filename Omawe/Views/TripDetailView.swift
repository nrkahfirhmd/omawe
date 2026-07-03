//
//  TripDetailView.swift
//  Omawe
//
//  Created by Gleenryan on 02/07/26.
//

import SwiftUI

// MARK: - Trip Detail View
struct TripDetailView: View {
    var trip: TripData
    var members: [String]
    @State private var currentMemberPage = 0
    @State private var isEditing = false
    @State private var editableMembers: [String] = []
    
    private let membersPerPage = 6
    
    private var displayMembers: [String] {
        isEditing ? editableMembers : members
    }
    
    private var memberPages: [[String]] {
        let source = displayMembers
        guard !source.isEmpty else { return [[]] }
        return stride(from: 0, to: source.count, by: membersPerPage).map {
            Array(source[$0..<min($0 + membersPerPage, source.count)])
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Theme.graybackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                DynamicBox(
                    theme: trip.theme,
                    title: trip.title,
                    subtitle: isEditing
                        ? trip.subtitle.replacingOccurrences(of: "by @Bintang • ", with: "by @Bintang • ")
                        : "by @Bintang",
                    helperText: "Swipe to see other friends",
                    footerTitle: isEditing ? "Edit your trip" : "Trip detail"
                ) {
                    VStack(spacing: 0) {
                        // People count
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(displayMembers.count)")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .fontWidth(.expanded)
                                .foregroundStyle(trip.theme.gradientSoft)
                                .contentTransition(.numericText())
                            Text("People")
                                .font(.caption)
                                .foregroundStyle(Color(uiColor: .tertiarySystemBackground).opacity(0.7))
                        }
                        .padding(.bottom, 12)
                        
                        // Location + Date
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "location.circle.fill")
                                Text(trip.location)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text(trip.subtitle
                                    .replacingOccurrences(of: "by @Bintang • ", with: "")
                                    .replacingOccurrences(of: "by @Kahfi • ", with: "")
                                    .replacingOccurrences(of: "by @Ryan • ", with: "")
                                )
                            }
                        }
                        .font(.caption.bold())
                        .foregroundStyle(Color(uiColor: .tertiarySystemBackground).opacity(0.7))
                        .padding(.bottom, 20)
                        
                        // Paginated members list
                        PaginatedMemberList(
                            pages: memberPages,
                            currentPage: $currentMemberPage,
                            isEditing: isEditing,
                            onRemove: { name in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    editableMembers.removeAll { $0 == name }
                                    // Fix page index if current page no longer exists
                                    let maxPage = max(0, memberPages.count - 1)
                                    if currentMemberPage > maxPage {
                                        currentMemberPage = maxPage
                                    }
                                }
                            }
                        )
                        
                        // Page indicator
                        MemberPageIndicator(
                            totalPages: memberPages.count,
                            currentPage: currentMemberPage
                        )
                        .padding(.top, 14)
                        .padding(.bottom, 8)
                    }
                }
                .animation(.smooth(duration: 0.3), value: isEditing)
                
                Spacer()
                
                // Bottom buttons
                if isEditing {
                    EditBottomBar(
                        onDelete: {
                            // Delete trip action
                        },
                        onSave: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isEditing = false
                            }
                        }
                    )
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    TripDetailBottomBar(
                        onEdit: {
                            editableMembers = members
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isEditing = true
                            }
                        }
                    )
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Paginated Member List
struct PaginatedMemberList: View {
    var pages: [[String]]
    @Binding var currentPage: Int
    var isEditing: Bool
    var onRemove: ((String) -> Void)?
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(pages.indices, id: \.self) { pageIndex in
                VStack(spacing: 8) {
                    ForEach(Array(pages[pageIndex].enumerated()), id: \.offset) { _, name in
                        MemberRow(
                            name: name,
                            isEditing: isEditing,
                            onRemove: { onRemove?(name) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .tag(pageIndex)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 360)
    }
}

// MARK: - Member Page Indicator
struct MemberPageIndicator: View {
    var totalPages: Int
    var currentPage: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? .white : .white.opacity(0.3))
                    .frame(
                        width: index == currentPage ? 20 : 7,
                        height: 7
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

// MARK: - Member Row
struct MemberRow: View {
    var name: String
    var isEditing: Bool = false
    var onRemove: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.8))
                )
            
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            
            Spacer()
            
            if isEditing {
                Button {
                    onRemove?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

// MARK: - Bottom Bar (View Mode)
struct TripDetailBottomBar: View {
    var onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                // Back action
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                    Text("Back to Home")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(white: 0.08))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 55, height: 55)
                    .background(Color(white: 0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Bottom Bar (Edit Mode)
struct EditBottomBar: View {
    var onDelete: () -> Void
    var onSave: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                onDelete()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                    Text("Delete")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(white: 0.08))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Button {
                onSave()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                    Text("Save")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.25, blue: 0.24),
                            Color(red: 0.11, green: 0.35, blue: 0.32)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            Color(red: 0.4, green: 0.85, blue: 0.9),
                            lineWidth: 1.5
                        )
                        .shadow(color: Color(red: 0.4, green: 0.85, blue: 0.9).opacity(0.4), radius: 6)
                )
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    TripDetailView(
        trip: TripData(
            theme: Theme.themeSecondary,
            icon: "balloon.2",
            title: "Ex-Boyfriends\nCelebration!",
            subtitle: "by @Bintang • 27/06/2026 • 11:30",
            people: 12,
            location: "Toko Kopi Jaya, Kuta",
            footerTitle: "Trip is not starting yet"
        ),
        members: [
            "Gleen Ryan",
            "Bintang",
            "Kahfi",
            "Sunny",
            "Syed",
            "Nguyen Minh Luat",
            "Damar",
            "Rizky",
            "Aldo",
            "Fajar",
            "Dimas",
            "Putra"
        ]
    )
}
