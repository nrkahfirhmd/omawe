//
//  TripDetailView.swift
//  Omawe
//
//  Created by Gleenryan on 02/07/26.
//

import SwiftUI
import SwiftData

struct TripDetailMember: Identifiable, Equatable {
    let id: String
    let name: String
    let isOwner: Bool
}

// MARK: - Trip Detail View
struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var trip: TripModel
    var subtitle: String
    var members: [TripDetailMember]
    @State private var currentMemberPage = 0
    @State private var isEditing = false
    @State private var editableMembers: [TripDetailMember] = []
    @State private var showDeleteConfirmation = false
    
    private let membersPerPage = 5
    
    private var displayMembers: [TripDetailMember] {
        isEditing ? editableMembers : members
    }
    
    private var memberPages: [[TripDetailMember]] {
        let source = displayMembers
        guard !source.isEmpty else { return [[]] }
        return stride(from: 0, to: source.count, by: membersPerPage).map {
            Array(source[$0..<min($0 + membersPerPage, source.count)])
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            detailStageBackground
            
            VStack() {
                
                // Top Custom Dynamic Island (Glowing Pill)
                CustomDynamicIsland(
                    color: .black,
                    borderColor: Theme.secondarySoft,
                    fillColor: .black
                )
                .padding(.top, 8)
                .padding(.bottom, 39)
                .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing:29){
                    
                    // Location Card
                    locationCard
                    //                    .padding(.top, 44)
//                        .padding(.horizontal, 16)
//                        .padding(.top, 39)
                    
                    
                    // Title, Subtitle and (optional) Trash Button
                HStack(alignment: .top) {
                    VStack(alignment: isEditing ? .leading : .center, spacing: 4) {
                        Text(trip.name.isEmpty ? "Untitled trip" : trip.name.replacingOccurrences(of: "\n", with: " "))
                            .font(.title2.weight(.bold))
                            .fontWidth(.expanded)
                            .foregroundStyle(Theme.themeSecondary.gradientSoft)
                            .multilineTextAlignment(isEditing ? .leading : .center)
                            .lineLimit(2)
                        
                        Text("You are the group creator")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    if isEditing {
                        Spacer()
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: isEditing ? .leading : .center)
                .padding(.horizontal, 24)

                    
                    VStack(spacing: 0){
                        
                        // People Count
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(displayMembers.count)")
                        .font(.system(size: 64, weight: .semibold))
                        .fontWidth(.expanded)
                        .foregroundStyle(Theme.themeSecondary.gradientSoft)
                        .contentTransition(.numericText())
                    Text("People")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 8)
                
                // Date & Time
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(subtitle
                        .replacingOccurrences(of: "by @Bintang • ", with: "")
                        .replacingOccurrences(of: "by @Kahfi • ", with: "")
                        .replacingOccurrences(of: "by @Ryan • ", with: "")
                    )
                }                  
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 24)
                        
                        // Paginated members list
                        PaginatedMemberList(
                            pages: memberPages,
                            currentPage: $currentMemberPage,
                            isEditing: isEditing,
                            onRemove: { member in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    editableMembers.removeAll { $0.id == member.id }
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
                        .padding(.top, 16)
                    }
                    
                    
                    
                }
                .padding(.horizontal, 16)
                
                
                Spacer()
                
                // Bottom buttons
                if isEditing {
                    EditBottomBar(
                        onCancel: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isEditing = false
                            }
                        },
                        onSave: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                trip.memberIdentifiers = editableMembers.map { $0.id }
                                try? modelContext.save()
                                isEditing = false
                            }
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    TripDetailBottomBar(
                        onEdit: {
                            editableMembers = members
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isEditing = true
                            }
                        },
                        onBack: {
                            dismiss()
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .alert("Delete Trip", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(trip)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this trip? This action cannot be undone.")
        }
    }
    
    // MARK: - Subviews
    private var detailStageBackground: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Theme.secondaryBox],
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
//            
            DetailSpotlightShape()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.06), .white.opacity(0.01), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 10)
                .padding(.horizontal, 76)
                .offset(y: 64)
        }
        .ignoresSafeArea()
    }
    
    private var locationTitleText: String {
        trip.locationName.isEmpty ? "Location" : trip.locationName
    }
    
    private var locationAddressText: String {
        trip.locationAddress ?? "No address available"
    }
    
    private var locationCard: some View {
        HStack(spacing: 14) {
            // Icon Box
            
            Image(systemName: "location.app.fill")
                .font(.largeTitle)
                .foregroundStyle(Theme.primary)
            
            
            VStack(alignment: .leading, spacing: 0) {
                Text(locationTitleText)
                    .font(.body)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(locationAddressText)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(red: 242/255, green: 242/255, blue: 247/255).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

    }
}

// MARK: - Paginated Member List
struct PaginatedMemberList: View {
    var pages: [[TripDetailMember]]
    @Binding var currentPage: Int
    var isEditing: Bool
    var onRemove: ((TripDetailMember) -> Void)?
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(pages.indices, id: \.self) { pageIndex in
                VStack(spacing: 12) {
                    ForEach(pages[pageIndex]) { member in
                        MemberRow(
                            member: member,
                            isEditing: isEditing,
                            onRemove: { onRemove?(member) }
                        )
                    }
                }

                .tag(pageIndex)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 300)
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
    var member: TripDetailMember
    var isEditing: Bool = false
    var onRemove: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar Placeholder
            Circle()
                .fill(Color(hex: "F2F2F7"))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(member.name.prefix(1)))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.orange.opacity(0.8))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            Text(member.name)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
            
            Spacer()
            
            if isEditing && !member.isOwner {
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
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(hex: "F2F2F7").opacity(0.1)) // Dark translucent pill
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

// MARK: - Bottom Bar (View Mode)
struct TripDetailBottomBar: View {
    var onEdit: () -> Void
    var onBack: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Back Button
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.black)
                    .frame(width: 55, height: 55)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }
            
            // See Invitation Button
            Button {
            } label: {
                HStack(spacing: 10) {
                    
                    Image(systemName:  "eyes")
                        .font(.button())
                }
                
                Text("See Invitation")
                    .font(.button())
                    .fontWidth(.expanded)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .foregroundStyle(.white )
            .overlay {
                Capsule()
                    .stroke(Theme.secondary, lineWidth: 1.5)
            }
        
            .glassEffect(.clear)
            
            // Edit Button
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.line")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(width: 55, height: 55)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Bottom Bar (Edit Mode)
struct EditBottomBar: View {
    var onCancel: () -> Void
    var onSave: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Cancel Button
            Button {
                onCancel()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.headline)
                    Text("Cancel")
                        .font(.headline.weight(.bold))
                        .fontWidth(.expanded)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .foregroundStyle(.white )
                .overlay {
                    Capsule()
                        .stroke(Theme.secondary, lineWidth: 1.5)
                }
            
                .glassEffect(.clear)
            }
            
            // Save/Done Button
            Button {
                onSave()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.headline)
                    Text("Done")
                        .font(.headline.weight(.bold))
                        .fontWidth(.expanded)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .foregroundStyle(.white )
                .background(Color(hex: "007A94"))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(Theme.secondary, lineWidth: 1.5)
                }
            
                .glassEffect(.clear)
                
                
            }
        }
    }
}

// MARK: - Spotlight Shape
fileprivate struct DetailSpotlightShape: Shape {
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

// MARK: - Preview
#Preview {
    TripDetailView(
        trip: TripModel(
            name: "Ex-Boyfriends\nCelebration!",
            startDate: Date(),
            meetTime: Date(),
            locationName: "Fore Kopi",
            locationAddress: "Jl. Dewi Sri No.69, Legian, Kec...",
            ownerUserID: "user_owner_id"
        ),
        subtitle: "by @Bintang • 27/06/2026 • 11:30",
        members: [
            TripDetailMember(id: "1", name: "Gleen Ryan", isOwner: true),
            TripDetailMember(id: "2", name: "Bintang", isOwner: false),
            TripDetailMember(id: "3", name: "Kahfi", isOwner: false),
            TripDetailMember(id: "4", name: "Syed", isOwner: false),
            TripDetailMember(id: "5", name: "Nguyen Minh Luat", isOwner: false),
            TripDetailMember(id: "6", name: "Damar", isOwner: false)
        ]
    )
}
