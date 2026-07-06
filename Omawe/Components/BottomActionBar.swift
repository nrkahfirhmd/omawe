//
//  BottomActionBar.swift
//  Omawe
//
//  Created by Nurkahfi Rahmada on 06/07/26.
//

import SwiftUI

struct BottomActionBar: View {
    var body: some View {
        VStack(spacing: 18) {
            ReportToast()

            HStack(alignment: .bottom) {
                CircleActionButton(
                    systemImage: "chevron.left"
                )

                Spacer()

                Button {
                } label: {
                    Text("Report")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(
                                    Color.cyan,
                                    lineWidth: 2
                                )
                        }
                        .clipShape(
                            Capsule()
                        )
                }

                Spacer()

                CircleActionButton(
                    systemImage: "exclamationmark.triangle.fill"
                )
            }
        }
    }
}
